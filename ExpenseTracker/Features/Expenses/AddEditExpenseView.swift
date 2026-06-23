//
//  AddEditExpenseView.swift
//  Fintrax
//
//  Fintrax documentation: Builds expense list, filtering, searching, add/edit, validation, and row presentation flows.
//

import SwiftUI

/// Add/Edit expense form view
struct AddEditExpenseView: View {
    @StateObject private var viewModel: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @FocusState private var focusedField: Field?
    
    @State private var categories: [Category] = []
    @State private var isLoadingCategories = false
    @State private var categoryLoadError: String?
    @State private var smartCategorySuggestion: SmartCategorySuggestion?
    @State private var smartCategoryTask: Task<Void, Never>?
    @State private var userSelectedCategoryManually = false
    @State private var lastSmartSelectedCategoryID: UUID?
    
    private let seedCategories: [Category]
    private let repository = FinanceDataRepository.shared
    private let smartCategoryService = SmartCategoryService()
    
    /// Initialize for creating a new expense
    init(categories: [Category] = []) {
        self.seedCategories = categories
        self._viewModel = StateObject(wrappedValue: ExpenseViewModel())
        self._categories = State(initialValue: categories)
    }
    
    /// Initialize for editing an existing expense
    init(expense: Expense, categories: [Category] = []) {
        self.seedCategories = categories
        self._viewModel = StateObject(wrappedValue: ExpenseViewModel(expense: expense))
        self._categories = State(initialValue: categories)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                amountHero
                detailsCard
                noteCard
                formStatusCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(ExpenseFormBackground())
        .navigationTitle(viewModel.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text(L10n.Expenses.cancel)
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.saveButtonText) {
                    Task {
                        await viewModel.save()
                        if case .success = viewModel.loadingState {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isLoading || isLoadingCategories)
            }
        }
        .disabled(viewModel.isLoading)
        .fintraxModal(
            isPresented: viewModel.showAlert,
            title: L10n.string("expenses.form.couldNotSave"),
            message: viewModel.alertMessage,
            icon: "exclamationmark.triangle.fill",
            tint: AppDesignSystem.Colors.error,
            primaryAction: FintraxModalAction(title: L10n.string("expenses.form.reviewDetails"), icon: "checkmark", tint: AppDesignSystem.Colors.primary) {
                viewModel.showAlert = false
            }
        )
        .task {
            await loadCategories()
        }
        .onChange(of: viewModel.title) { _, _ in
            scheduleSmartCategorySuggestion()
        }
        .onDisappear {
            smartCategoryTask?.cancel()
        }
        .onChange(of: locale.identifier) { _, _ in
            viewModel.validateForm()
            if categoryLoadError != nil {
                categoryLoadError = L10n.string(L10n.Expenses.categoryLoadFailed)
            }
        }
    }

    private var amountHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Expenses.amount)
                        .font(.headline)
                    Text(selectedCategoryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(viewModel.isEditing ? L10n.Expenses.update : L10n.Expenses.new)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppDesignSystem.Colors.controlFill, in: Capsule())
            }

            CurrencyInputField(value: $viewModel.amount, placeholder: "0.00")
                .focused($focusedField, equals: .amount)
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
                .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(viewModel.hasError(for: "amount") ? Color.red.opacity(0.55) : Color.white.opacity(0.26), lineWidth: 1)
                )

            quickAmountRow

            validationText(for: "amount")
        }
        .padding(18)
        .expenseFormCard()
    }

    private var quickAmountRow: some View {
        HStack(spacing: 8) {
            ForEach([100, 250, 500, 1000], id: \.self) { amount in
                Button {
                    viewModel.amount = Decimal(amount)
                    viewModel.validateForm()
                } label: {
                    Text("₹\(amount)")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [AppDesignSystem.Colors.controlFill, Color.blue.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke(AppDesignSystem.Colors.cardStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardSectionHeader(title: L10n.Expenses.details, icon: "doc.text.fill", tint: .blue)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "text.cursor")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)

                    TextField(L10n.Expenses.titlePlaceholder, text: $viewModel.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(viewModel.hasError(for: "title") ? Color.red.opacity(0.55) : AppDesignSystem.Colors.cardStroke, lineWidth: 1)
                )

                validationText(for: "title")

                if let smartCategorySuggestion {
                    SmartCategorySuggestionChip(suggestion: smartCategorySuggestion)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.96).combined(with: .opacity)
                        ))
                }
            }

            DatePicker(selection: $viewModel.date, in: ...Date()) {
                Text(L10n.Expenses.date)
            }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppDesignSystem.Colors.cardStroke, lineWidth: 1)
                )

            categoryPicker
        }
        .padding(18)
        .expenseFormCard()
    }

    @ViewBuilder
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isLoadingCategories {
                HStack {
                    Label(L10n.Expenses.category, systemImage: "tag.fill")
                    Spacer()
                    ProgressView()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if categories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(L10n.Expenses.category, systemImage: "tag.fill")
                    Text(categoryLoadError ?? L10n.string("expenses.form.noCategories"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button {
                        Task { await loadCategories() }
                    } label: {
                        Text(L10n.Expenses.retry)
                    }
                    .font(.caption)
                }
                .padding()
                .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                NavigationLink {
                    CategorySelectorView(
                        selectedCategoryID: categorySelectionBinding,
                        categories: categories,
                        allowCustomCategories: false,
                        includeAllCategoriesOption: false
                    )
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedCategory?.iconName ?? "tag.fill")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(selectedCategory?.displayColor ?? Color.blue, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Text(L10n.Expenses.category)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(selectedCategoryText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(viewModel.hasError(for: "category") ? Color.red.opacity(0.55) : AppDesignSystem.Colors.cardStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            validationText(for: "category")
        }
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardSectionHeader(title: L10n.Expenses.note, icon: "note.text", tint: .teal)

            TextField(L10n.Expenses.optionalNote, text: $viewModel.note, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(viewModel.hasError(for: "note") ? Color.red.opacity(0.55) : AppDesignSystem.Colors.cardStroke, lineWidth: 1)
                )

            validationText(for: "note")
        }
        .padding(18)
        .expenseFormCard()
    }

    private var formStatusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(viewModel.isValid ? .green : .orange)
                .frame(width: 42, height: 42)
                .background((viewModel.isValid ? Color.green : Color.orange).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.isValid ? L10n.Expenses.readyToSave : L10n.Expenses.needsAttention)
                    .font(.subheadline.weight(.semibold))
                Text(viewModel.isValid ? viewModel.formattedAmount() : L10n.string("expenses.form.completeRequiredFields"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
        .expenseFormCard(cornerRadius: 18)
    }

    @ViewBuilder
    private func validationText(for field: String) -> some View {
        if let error = viewModel.errorMessage(for: field) {
            Label(error, systemImage: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)
        }
    }
    
    @MainActor
    private func loadCategories() async {
        if !seedCategories.isEmpty {
            categories = seedCategories
            selectDefaultCategoryIfNeeded()
            viewModel.validateForm()
            scheduleSmartCategorySuggestion()
            return
        }
        
        guard categories.isEmpty else {
            selectDefaultCategoryIfNeeded()
            viewModel.validateForm()
            scheduleSmartCategorySuggestion()
            return
        }
        
        isLoadingCategories = true
        categoryLoadError = nil
        defer { isLoadingCategories = false }
        
        do {
            categories = try await repository.loadCategories()
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            categoryLoadError = L10n.string("expenses.form.categoryLoadFailed")
            categories = Category.sampleCategories()
        }
        
        selectDefaultCategoryIfNeeded()
        viewModel.validateForm()
        scheduleSmartCategorySuggestion()
    }
    
    private func selectDefaultCategoryIfNeeded() {
        guard viewModel.isEditing, viewModel.selectedCategoryID == nil else { return }
        viewModel.selectedCategoryID = categories.first?.id
    }
    
    private var selectedCategoryText: String {
        guard let categoryID = viewModel.selectedCategoryID else {
            return L10n.string(L10n.Expenses.selectCategory)
        }
        return categories.first { $0.id == categoryID }?.name ?? L10n.string(L10n.Expenses.unknown)
    }

    private var selectedCategoryLabel: LocalizedStringKey {
        viewModel.selectedCategoryID == nil ? L10n.Expenses.chooseCategoryDetails : LocalizedStringKey(selectedCategoryText)
    }

    private var selectedCategory: Category? {
        guard let categoryID = viewModel.selectedCategoryID else { return nil }
        return categories.first { $0.id == categoryID }
    }

    private var categorySelectionBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedCategoryID },
            set: { newValue in
                userSelectedCategoryManually = true
                lastSmartSelectedCategoryID = nil
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    smartCategorySuggestion = nil
                }
                viewModel.selectedCategoryID = newValue
            }
        )
    }

    private func scheduleSmartCategorySuggestion() {
        smartCategoryTask?.cancel()

        guard !viewModel.isEditing, !userSelectedCategoryManually else { return }

        let title = viewModel.title
        smartCategoryTask = Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                applySmartCategorySuggestion(for: title)
            }
        }
    }

    @MainActor
    private func applySmartCategorySuggestion(for title: String) {
        guard !userSelectedCategoryManually else { return }

        guard title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
            clearSmartCategorySuggestion(resetAutoSelection: true)
            return
        }

        guard let suggestion = smartCategoryService.suggestCategory(for: title, categories: categories) else {
            clearSmartCategorySuggestion(resetAutoSelection: true)
            return
        }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            viewModel.selectedCategoryID = suggestion.category.id
            smartCategorySuggestion = suggestion
            lastSmartSelectedCategoryID = suggestion.category.id
        }
    }

    @MainActor
    private func clearSmartCategorySuggestion(resetAutoSelection: Bool) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            smartCategorySuggestion = nil

            if resetAutoSelection, viewModel.selectedCategoryID == lastSmartSelectedCategoryID {
                viewModel.selectedCategoryID = nil
            }

            lastSmartSelectedCategoryID = nil
        }
    }
    
    enum Field: Hashable {
        case title
        case amount
    }
}

private struct SmartCategorySuggestionChip: View {
    let suggestion: SmartCategorySuggestion
    @State private var glow = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(
                    LinearGradient(
                        colors: [AppDesignSystem.Colors.primary, suggestion.category.displayColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .scaleEffect(glow ? 1.04 : 0.96)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Expenses.smartCategory)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text(suggestion.category.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(suggestion.confidenceLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(suggestion.category.displayColor)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: suggestion.category.iconName)
                .font(.caption.weight(.bold))
                .foregroundStyle(suggestion.category.displayColor)
                .frame(width: 28, height: 28)
                .background(suggestion.category.displayColor.opacity(0.14), in: Circle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    suggestion.category.displayColor.opacity(0.14),
                    AppDesignSystem.Colors.primary.opacity(0.08)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(suggestion.category.displayColor.opacity(glow ? 0.34 : 0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.format(L10n.Expenses.smartCategoryAccessibility, suggestion.category.name))
        .task(id: suggestion.category.id) {
            glow = false
            withAnimation(.easeInOut(duration: 0.9).repeatCount(2, autoreverses: true)) {
                glow = true
            }
        }
    }
}

private struct CardSectionHeader: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.headline)

            Spacer()
        }
    }
}

private struct ExpenseFormBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 20

                for y in stride(from: CGFloat.zero, through: size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y + size.width * 0.12))
                }

                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)

                let markColor = Color.primary.opacity(0.055)
                for row in stride(from: CGFloat(42), through: size.height, by: 92) {
                    for column in stride(from: CGFloat(28), through: size.width, by: 118) {
                        let rect = CGRect(x: column, y: row, width: 8, height: 8)
                        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(markColor))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func expenseFormCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .fintraxSurface(cornerRadius: cornerRadius, accent: AppDesignSystem.Colors.primary)
    }
}

#Preview {
    NavigationStack {
        AddEditExpenseView(categories: Category.sampleCategories())
    }
}
