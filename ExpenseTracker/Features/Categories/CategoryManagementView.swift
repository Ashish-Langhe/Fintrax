//
//  CategoryManagementView.swift
//  Fintrax
//
//  Fintrax documentation: Builds category management, editing, icon, color, and category persistence UI.
//

import SwiftUI

struct CategoryManagementView: View {
    @StateObject private var viewModel = CategoryManagementViewModel()
    @State private var editorMode: CategoryEditorMode?
    @State private var categoryToDelete: Category?

    var body: some View {
        ZStack {
            CategoryManagementBackground()

            ScrollView {
                LazyVStack(spacing: 18) {
                    summaryCard

                    ForEach(viewModel.categories) { category in
                        CategoryManagementRow(
                            category: category,
                            expenseCount: viewModel.expenseCount(for: category.id),
                            onEdit: {
                                editorMode = .edit(category)
                            },
                            onDelete: {
                                categoryToDelete = category
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle(LocalizedStringKey("Categories"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editorMode = .create
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(Color(.systemBackground).opacity(0.68), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.30), lineWidth: 1))
                }
            }
        }
        .sheet(item: $editorMode) { mode in
            CategoryEditorSheet(mode: mode) { category in
                switch mode {
                case .create:
                    return await viewModel.addCategory(category)
                case .edit:
                    return await viewModel.updateCategory(category)
                }
            }
        }
        .fintraxModal(
            isPresented: viewModel.showAlert,
            title: L10n.string("Category"),
            message: viewModel.alertMessage,
            icon: "tag.fill",
            tint: AppDesignSystem.Colors.warning,
            primaryAction: FintraxModalAction(title: L10n.string("Got It"), icon: "checkmark", tint: AppDesignSystem.Colors.primary) {
                viewModel.showAlert = false
            }
        )
        .fintraxModal(
            isPresented: categoryToDelete != nil,
            title: L10n.string("Delete Category?"),
            message: deleteConfirmationMessage,
            icon: "trash.fill",
            tint: AppDesignSystem.Colors.error,
            primaryAction: FintraxModalAction(title: L10n.string("Delete Category"), icon: "trash.fill", tint: AppDesignSystem.Colors.error, isDestructive: true) {
                guard let categoryToDelete else { return }
                Task {
                    await viewModel.deleteCategory(categoryToDelete)
                    self.categoryToDelete = nil
                }
            },
            secondaryAction: FintraxModalAction(title: L10n.string("Keep Category"), icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
                categoryToDelete = nil
            }
        )
        .task {
            await viewModel.loadData()
        }
    }

    private var deleteConfirmationMessage: String {
        guard let category = categoryToDelete else { return "" }
        let count = viewModel.expenseCount(for: category.id)
        if count == 0 {
            return L10n.format("categories.delete.empty", category.name)
        }
        return L10n.format("categories.delete.withExpenses", category.name, count)
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "tag.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("Category Library")
                    .font(.headline)
                Text(L10n.format("categories.summary.counts", viewModel.categories.count, viewModel.customCategoryCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .categoryCard()
    }
}

@MainActor
final class CategoryManagementViewModel: ObservableObject {
    @Published private(set) var categories: [Category] = []
    @Published private(set) var expenses: [Expense] = []
    @Published var showAlert = false
    @Published var alertMessage = ""

    private let repository = FinanceDataRepository.shared

    var customCategoryCount: Int {
        categories.filter { !$0.isDefault }.count
    }

    func loadData() async {
        do {
            async let categoriesTask = repository.loadCategories()
            async let expensesTask = repository.loadExpenses()
            let (loadedCategories, loadedExpenses) = try await (categoriesTask, expensesTask)
            categories = loadedCategories
            expenses = loadedExpenses
        } catch {
            present(error)
        }
    }

    func addCategory(_ category: Category) async -> Bool {
        do {
            try await repository.saveCategory(category)
            await loadData()
            return true
        } catch {
            present(error)
            return false
        }
    }

    func updateCategory(_ category: Category) async -> Bool {
        do {
            try await repository.updateCategory(category)
            await loadData()
            return true
        } catch {
            present(error)
            return false
        }
    }

    func deleteCategory(_ category: Category) async {
        do {
            try await repository.deleteCategory(id: category.id)
            await loadData()
        } catch {
            present(error)
        }
    }

    func expenseCount(for categoryID: UUID) -> Int {
        expenses.filter { $0.categoryID == categoryID }.count
    }

    private func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}

enum CategoryEditorMode: Identifiable {
    case create
    case edit(Category)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let category):
            return category.id.uuidString
        }
    }

    var category: Category? {
        if case .edit(let category) = self {
            return category
        }
        return nil
    }
}

private struct CategoryManagementRow: View {
    let category: Category
    let expenseCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(category.displayColor, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if category.isDefault {
                        Text(LocalizedStringKey("Default"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground).opacity(0.62), in: Capsule())
                    }
                }

                Text(L10n.format("categories.expenseCount", expenseCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(width: 34, height: 34)
                        .background(Color.red.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .padding(14)
        .categoryCard(cornerRadius: 20)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label(LocalizedStringKey("Delete"), systemImage: "trash")
            }
        }
    }
}

private struct CategoryEditorSheet: View {
    let mode: CategoryEditorMode
    let onSave: (Category) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var iconName: String
    @State private var colorName: String
    @State private var isSaving = false
    @State private var showIconPicker = false
    @FocusState private var isNameFocused: Bool

    init(mode: CategoryEditorMode, onSave: @escaping (Category) async -> Bool) {
        self.mode = mode
        self.onSave = onSave

        let category = mode.category
        _name = State(initialValue: category?.name ?? "")
        _iconName = State(initialValue: category?.iconName ?? "tag.fill")
        _colorName = State(initialValue: category?.colorName ?? "blue")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CategoryManagementBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        previewCard
                        nameCard
                        colorCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle(LocalizedStringKey(mode.category == nil ? "Add Category" : "Edit Category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                SymbolPicker(selectedSymbol: $iconName)
            }
        }
        .onAppear {
            isNameFocused = mode.category == nil
        }
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 86, height: 86)
                .background(Color.categoryColor(named: colorName), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 5) {
                Text(name.isEmpty ? L10n.string("Category Name") : name)
                    .font(.title3.weight(.bold))
                Text(LocalizedStringKey("Icon and color will appear across Expenses and Dashboard"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showIconPicker = true
            } label: {
                Label(LocalizedStringKey("Choose Apple Icon"), systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .categoryCard()
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CategorySectionHeader(title: "Category Name", icon: "text.cursor", tint: .blue)

            TextField(LocalizedStringKey("Enter category name"), text: $name)
                .focused($isNameFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
        }
        .padding(18)
        .categoryCard()
    }

    private var colorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CategorySectionHeader(title: "Accent Color", icon: "paintpalette.fill", tint: Color.categoryColor(named: colorName))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 42, maximum: 48), spacing: 12)], spacing: 12) {
                ForEach(CategoryColorOption.all, id: \.name) { option in
                    Button {
                        colorName = option.name
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle()
                                    .stroke(colorName == option.name ? Color.primary : Color.white.opacity(0.35), lineWidth: colorName == option.name ? 3 : 1)
                            )
                            .overlay {
                                if colorName == option.name {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(option.checkmarkColor)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.name.capitalized)
                    .accessibilityAddTraits(colorName == option.name ? .isSelected : [])
                }
            }
        }
        .padding(18)
        .categoryCard()
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        var category = mode.category ?? Category(name: name, iconName: iconName, colorName: colorName)
        do {
            try category.updateDetails(name: name, iconName: iconName, colorName: colorName)
            if await onSave(category) {
                dismiss()
            }
        } catch {
            // Validation is mirrored by the disabled save state. Persistence errors are surfaced by the parent view model.
        }
    }
}

private struct SymbolPicker: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let symbols = [
        "fork.knife", "cup.and.saucer.fill", "cart.fill", "bag.fill",
        "car.fill", "bus.fill", "tram.fill", "fuelpump.fill",
        "house.fill", "bolt.fill", "wifi", "drop.fill",
        "heart.fill", "cross.case.fill", "pills.fill", "figure.walk",
        "tv.fill", "gamecontroller.fill", "music.note", "theatermasks.fill",
        "airplane", "bed.double.fill", "book.fill", "graduationcap.fill",
        "gift.fill", "pawprint.fill", "phone.fill", "laptopcomputer",
        "banknote.fill", "creditcard.fill", "briefcase.fill", "ellipsis.circle.fill"
    ]

    private var filteredSymbols: [String] {
        guard !searchText.isEmpty else { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CategoryManagementBackground()

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            Button {
                                selectedSymbol = symbol
                                dismiss()
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(selectedSymbol == symbol ? .white : .blue)
                                    .frame(height: 64)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        selectedSymbol == symbol ? Color.blue : Color(.systemBackground).opacity(0.62),
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.white.opacity(0.26), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(LocalizedStringKey("Choose Icon"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Text("Search SF Symbols"))
        }
    }
}

private struct CategorySectionHeader: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(LocalizedStringKey(title))
                .font(.headline)

            Spacer()
        }
    }
}

private struct CategoryManagementBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                for x in stride(from: CGFloat.zero, through: size.width, by: 20) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.34, y: size.height))
                }
                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}

struct CategoryColorOption {
    let name: String
    let color: Color
    let checkmarkColor: Color

    static let all = [
        CategoryColorOption(name: "blue", color: .blue),
        CategoryColorOption(name: "sky", color: Color(red: 0.20, green: 0.62, blue: 0.95)),
        CategoryColorOption(name: "azure", color: Color(red: 0.05, green: 0.45, blue: 0.95)),
        CategoryColorOption(name: "teal", color: .teal),
        CategoryColorOption(name: "aqua", color: Color(red: 0.00, green: 0.72, blue: 0.78)),
        CategoryColorOption(name: "lagoon", color: Color(red: 0.02, green: 0.55, blue: 0.62)),
        CategoryColorOption(name: "green", color: .green),
        CategoryColorOption(name: "emerald", color: Color(red: 0.08, green: 0.64, blue: 0.36)),
        CategoryColorOption(name: "mint", color: .mint),
        CategoryColorOption(name: "lime", color: Color(red: 0.58, green: 0.82, blue: 0.18), checkmarkColor: Color.black.opacity(0.78)),
        CategoryColorOption(name: "orange", color: .orange),
        CategoryColorOption(name: "amber", color: Color(red: 0.96, green: 0.58, blue: 0.12)),
        CategoryColorOption(name: "gold", color: Color(red: 0.88, green: 0.68, blue: 0.10), checkmarkColor: Color.black.opacity(0.78)),
        CategoryColorOption(name: "yellow", color: .yellow, checkmarkColor: Color.black.opacity(0.78)),
        CategoryColorOption(name: "red", color: .red),
        CategoryColorOption(name: "coral", color: Color(red: 0.98, green: 0.38, blue: 0.34)),
        CategoryColorOption(name: "apricot", color: Color(red: 0.96, green: 0.50, blue: 0.28)),
        CategoryColorOption(name: "rose", color: Color(red: 0.94, green: 0.25, blue: 0.45)),
        CategoryColorOption(name: "pink", color: .pink),
        CategoryColorOption(name: "fuchsia", color: Color(red: 0.80, green: 0.18, blue: 0.72)),
        CategoryColorOption(name: "purple", color: .purple),
        CategoryColorOption(name: "violet", color: Color(red: 0.47, green: 0.30, blue: 0.92)),
        CategoryColorOption(name: "plum", color: Color(red: 0.56, green: 0.24, blue: 0.58)),
        CategoryColorOption(name: "orchid", color: Color(red: 0.66, green: 0.32, blue: 0.76)),
        CategoryColorOption(name: "cyan", color: .cyan),
        CategoryColorOption(name: "indigo", color: .indigo),
        CategoryColorOption(name: "navy", color: Color(red: 0.12, green: 0.24, blue: 0.52)),
        CategoryColorOption(name: "slate", color: Color(red: 0.34, green: 0.42, blue: 0.52)),
        CategoryColorOption(name: "steel", color: Color(red: 0.26, green: 0.35, blue: 0.45)),
        CategoryColorOption(name: "brown", color: .brown),
        CategoryColorOption(name: "coffee", color: Color(red: 0.48, green: 0.33, blue: 0.22)),
        CategoryColorOption(name: "copper", color: Color(red: 0.70, green: 0.38, blue: 0.20)),
        CategoryColorOption(name: "charcoal", color: Color(red: 0.20, green: 0.22, blue: 0.26)),
        CategoryColorOption(name: "gray", color: .gray)
    ]

    init(name: String, color: Color, checkmarkColor: Color = .white) {
        self.name = name
        self.color = color
        self.checkmarkColor = checkmarkColor
    }
}

extension Category {
    var displayColor: Color {
        Color.categoryColor(named: colorName)
    }

    var color: Color {
        displayColor
    }
}

extension Color {
    static func categoryColor(named name: String) -> Color {
        CategoryColorOption.all.first { $0.name == name }?.color ?? Color(name)
    }
}

private extension View {
    func categoryCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemBackground).opacity(0.90))

                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.blue.opacity(0.07), Color.teal.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.09), radius: 16, x: 0, y: 9)
    }
}

#Preview {
    NavigationStack {
        CategoryManagementView()
    }
}
