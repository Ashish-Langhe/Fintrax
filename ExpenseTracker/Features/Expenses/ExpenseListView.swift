//
//  ExpenseListView.swift
//  Fintrax
//
//  Fintrax documentation: Builds expense list, filtering, searching, add/edit, validation, and row presentation flows.
//

import SwiftUI
import Foundation

/// Main expense list view
struct ExpenseListView: View {
    @StateObject private var viewModel = ExpenseListViewModel()
    @State private var showingAddExpense = false
    @State private var expenseToEdit: Expense?
    @State private var showingFilterSheet = false
    
    let categories: [Category]
    let budgets: [Budget]
    
    init(categories: [Category] = [], budgets: [Budget] = []) {
        self.categories = categories
        self.budgets = budgets
    }
    
    private var displayCategories: [Category] {
        categories.isEmpty ? viewModel.categories : categories
    }

    private var deleteExpenseMessage: String {
        guard let expense = viewModel.expenseToDelete else {
            return "This expense will be removed from your history."
        }
        return "This removes '\(expense.title)' from your expense history and dashboard totals."
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ExpenseTexturedBackground()

                if viewModel.loadingState.isLoading && viewModel.expenses.isEmpty {
                    ProgressView("Loading expenses...")
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 0) {
                        // Filter and search bar
                        FilterAndSearchBar(
                            selectedCategory: $viewModel.selectedCategory,
                            selectedDateRange: $viewModel.selectedDateRange,
                            searchText: $viewModel.searchText,
                            categories: displayCategories,
                            showingFilterSheet: $showingFilterSheet
                        )
                        
                        // Expense list or empty state
                        if viewModel.filteredExpenses.isEmpty {
                            EmptyExpenseState(
                                hasActiveFilters: viewModel.hasActiveFilters(),
                                onResetFilters: {
                                    viewModel.resetFilters()
                                }
                            )
                        } else {
                            expenseList
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        ToolbarIconLabel(systemImage: "plus", tint: .blue)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await viewModel.refreshData()
                        }
                    } label: {
                        ToolbarIconLabel(
                            systemImage: viewModel.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise",
                            tint: .teal,
                            isAnimating: viewModel.isRefreshing
                        )
                    }
                    .disabled(viewModel.isRefreshing)
                    
                    if viewModel.hasActiveFilters() {
                        Button {
                            viewModel.resetFilters()
                        } label: {
                            ToolbarIconLabel(systemImage: "xmark.circle.fill", tint: .red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                NavigationStack {
                    AddEditExpenseView(categories: viewModel.categories)
                }
            }
            .sheet(item: $expenseToEdit) { expense in
                NavigationStack {
                    AddEditExpenseView(expense: expense, categories: viewModel.categories)
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(
                    selectedCategory: $viewModel.selectedCategory,
                    selectedDateRange: $viewModel.selectedDateRange,
                    sortOption: $viewModel.sortOption,
                    categories: displayCategories
                )
            }
            .fintraxModal(
                isPresented: viewModel.showingDeleteAlert,
                title: "Delete Expense?",
                message: deleteExpenseMessage,
                icon: "trash.fill",
                tint: AppDesignSystem.Colors.error,
                primaryAction: FintraxModalAction(title: "Delete Expense", icon: "trash.fill", tint: AppDesignSystem.Colors.error, isDestructive: true) {
                    Task {
                        await viewModel.confirmDelete()
                    }
                },
                secondaryAction: FintraxModalAction(title: "Keep Expense", icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
                    viewModel.cancelDelete()
                }
            )
            .task {
                await viewModel.loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .categoryDidChange)) { _ in
                Task { await viewModel.refreshData() }
            }
            .onChange(of: showingAddExpense) { _, isPresented in
                if !isPresented {
                    Task { await viewModel.refreshData() }
                }
            }
            .onChange(of: expenseToEdit) { _, expense in
                if expense == nil {
                    Task { await viewModel.refreshData() }
                }
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.selectedDateRange) { _, _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.sortOption) { _, _ in
                viewModel.applyFilters()
            }
        }
    }
    
    private var expenseList: some View {
        List {
            Section {
                ExpenseListSummaryCard(
                    total: viewModel.totalFilteredAmount().formattedAmount(),
                    count: viewModel.filteredCount(),
                    average: averageFilteredAmount.formattedAmount(),
                    period: expenseListPeriod,
                    hasFilters: viewModel.hasActiveFilters()
                )
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            // Expense items
            ForEach(viewModel.filteredExpenses) { expense in
                ExpenseRow(
                    expense: expense,
                    category: viewModel.category(for: expense.categoryID),
                    onTap: {
                        expenseToEdit = expense
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteExpense(expense)
                        }
                    }
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.refreshData()
        }
    }

    private var averageFilteredAmount: Decimal {
        let count = viewModel.filteredCount()
        guard count > 0 else { return .zero }

        return NSDecimalNumber(decimal: viewModel.totalFilteredAmount())
            .dividing(by: NSDecimalNumber(value: count))
            .decimalValue
    }

    private var expenseListPeriod: String {
        viewModel.selectedDateRange == .allTime ? "All time" : viewModel.selectedDateRange.rawValue
    }
}

private struct ExpenseListSummaryCard: View {
    let total: String
    let count: Int
    let average: String
    let period: String
    let hasFilters: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle.fill" : "creditcard.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(
                            colors: hasFilters ? [.orange, .pink] : [.blue, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(hasFilters ? "Filtered spend" : "Expense activity")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(total)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("\(count)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground).opacity(0.72), in: Capsule())
            }

            HStack(spacing: 10) {
                SummaryMetricPill(title: "Average", value: average, icon: "chart.line.uptrend.xyaxis")
                SummaryMetricPill(title: "Entries", value: count == 1 ? "1 item" : "\(count) items", icon: "list.bullet.rectangle")
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.92))

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color.blue.opacity(0.08),
                        Color.teal.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
    }
}

private struct SummaryMetricPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground).opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Filter and search bar
struct FilterAndSearchBar: View {
    @Binding var selectedCategory: UUID?
    @Binding var selectedDateRange: DateRangeOption
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    
    let categories: [Category]
    @Binding var showingFilterSheet: Bool

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDateRange != .allTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSearchFocused ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        (isSearchFocused ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.info)
                            .opacity(isSearchFocused ? 0.14 : 0.10),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Search")
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)

                    TextField("Food, rent, note, category", text: $searchText)
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                }

                if !searchText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.72), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.92),
                        AppDesignSystem.Colors.surfaceVariant.opacity(0.48)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSearchFocused ? AppDesignSystem.Colors.primary.opacity(0.34) : Color.white.opacity(0.16),
                        lineWidth: isSearchFocused ? 1.1 : 0.8
                    )
            }
            .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 12)
            .shadow(color: AppDesignSystem.Colors.primary.opacity(isSearchFocused ? 0.16 : 0.08), radius: isSearchFocused ? 14 : 10, x: 0, y: 7)

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: selectedCategory.flatMap { categoryName(for: $0) } ?? "All Categories",
                            icon: "folder.fill",
                        isActive: selectedCategory != nil,
                        onTap: {
                            showingFilterSheet = true
                        }
                    )

                        FilterChip(
                            title: selectedDateRange.rawValue,
                            icon: "calendar",
                            isActive: selectedDateRange != .allTime,
                            onTap: {
                                showingFilterSheet = true
                            }
                        )

                        if !searchText.isEmpty {
                            SearchStatusChip(searchText: searchText) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    searchText = ""
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease.circle")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(hasActiveFilters ? .white : AppDesignSystem.Colors.primary)
                        .frame(width: 38, height: 38)
                        .background(
                            hasActiveFilters ? AppDesignSystem.Gradients.primary : LinearGradient(colors: [
                                AppDesignSystem.Colors.elevatedSurface.opacity(0.82),
                                AppDesignSystem.Colors.surfaceVariant.opacity(0.52)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open filters")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.58),
                    AppDesignSystem.Colors.surfaceVariant.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1)
        }
    }
    
    private func categoryName(for categoryId: UUID?) -> String? {
        guard let categoryId = categoryId else { return nil }
        return categories.first { $0.id == categoryId }?.name
    }
}

private struct SearchStatusChip: View {
    let searchText: String
    let onClear: () -> Void

    var body: some View {
        Button(action: onClear) {
            HStack(spacing: 6) {
                Image(systemName: "text.magnifyingglass")
                    .font(.caption.weight(.bold))
                Text(searchText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2.weight(.bold))
            }
            .font(AppDesignSystem.Typography.caption.weight(.bold))
            .foregroundStyle(AppDesignSystem.Colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 180)
            .background(AppDesignSystem.Colors.primary.opacity(0.11), in: Capsule())
            .overlay(Capsule().stroke(AppDesignSystem.Colors.primary.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear search text")
    }
}

/// Filter chip component
struct FilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: isActive ? "checkmark.circle.fill" : icon)
                    .font(.caption.weight(.bold))
                if isActive {
                    Image(systemName: icon)
                        .font(.caption2.weight(.bold))
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isActive ?
                LinearGradient(colors: [Color.blue, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [Color(.systemBackground).opacity(0.74), Color(.systemBackground).opacity(0.54)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : Color.white.opacity(0.26), lineWidth: 1)
            )
            .foregroundColor(isActive ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ToolbarIconLabel: View {
    let systemImage: String
    let tint: Color
    var isAnimating = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(Color(.systemBackground).opacity(0.68), in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.30), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(isAnimating ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isAnimating)
    }
}

/// Empty expense state
struct EmptyExpenseState: View {
    let hasActiveFilters: Bool
    let onResetFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 98, height: 98)

                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "tray")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text(hasActiveFilters ? "No Matching Expenses" : "No Expenses Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasActiveFilters 
                     ? "Try adjusting your filters or search terms"
                     : "Start by adding your first expense")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if hasActiveFilters {
                Button("Reset Filters") {
                    onResetFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Expense row
struct ExpenseRow: View {
    let expense: Expense
    let category: Category?
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [categoryColor, categoryColor.opacity(0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: category?.iconName ?? "tag.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(expense.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 7) {
                    if let category {
                        ExpenseInfoChip(title: category.name, icon: category.iconName, color: categoryColor)
                    }

                    ExpenseInfoChip(title: formattedDate, icon: "calendar", color: .secondary)
                }

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text(expense.formattedAmount())
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.red.opacity(0.10), in: Capsule())
                    .foregroundStyle(.red)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.90))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 7)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var categoryColor: Color {
        if let category {
            return category.displayColor
        }

        // Generate a consistent color based on category ID
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .mint]
        let hash = abs(expense.categoryID.hashValue)
        let index = hash % colors.count
        return colors[index]
    }

    private var formattedDate: String {
        expense.date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct ExpenseInfoChip: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(title)
                .lineLimit(1)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.10), in: Capsule())
    }
}

private struct ExpenseTexturedBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 18

                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.42, y: size.height))
                }

                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)

                let dotColor = Color.primary.opacity(0.06)
                for row in stride(from: CGFloat(32), through: size.height, by: 76) {
                    for column in stride(from: CGFloat(18), through: size.width, by: 86) {
                        let rect = CGRect(x: column, y: row, width: 3, height: 3)
                        context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Filter sheet
struct FilterSheet: View {
    @Binding var selectedCategory: UUID?
    @Binding var selectedDateRange: DateRangeOption
    @Binding var sortOption: SortOption
    
    let categories: [Category]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                ExpenseTexturedBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        filterHero
                        categorySection
                        dateRangeSection
                        sortSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Filter Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedCategory = nil
                        selectedDateRange = .allTime
                        sortOption = .dateDescending
                    }
                    .disabled(!hasActiveFilters)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private var filterHero: some View {
        HStack(spacing: 14) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Refine your expenses")
                    .font(.headline)
                Text(activeSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(18)
        .filterSheetCard()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: "Category", icon: "folder.fill", tint: .blue)

            LazyVStack(spacing: 10) {
                FilterSelectionRow(
                    title: "All Categories",
                    subtitle: "Show every expense",
                    icon: "square.grid.2x2.fill",
                    tint: .blue,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories) { category in
                    FilterSelectionRow(
                        title: category.name,
                        subtitle: "Filter by \(category.name)",
                        icon: "tag.fill",
                        tint: category.displayColor,
                        isSelected: selectedCategory == category.id
                    ) {
                        selectedCategory = category.id
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: "Date Range", icon: "calendar", tint: .teal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(DateRangeOption.allCases) { option in
                    FilterOptionChip(
                        title: option.rawValue,
                        icon: option == .allTime ? "clock.arrow.circlepath" : "calendar.badge.clock",
                        tint: .teal,
                        isSelected: selectedDateRange == option
                    ) {
                        selectedDateRange = option
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: "Sort By", icon: "arrow.up.arrow.down", tint: .orange)

            LazyVStack(spacing: 10) {
                ForEach(SortOption.allCases) { option in
                    FilterSelectionRow(
                        title: option.rawValue,
                        subtitle: sortSubtitle(for: option),
                        icon: sortIcon(for: option),
                        tint: .orange,
                        isSelected: sortOption == option
                    ) {
                        sortOption = option
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDateRange != .allTime || sortOption != .dateDescending
    }

    private var activeSummary: String {
        var parts: [String] = []
        parts.append(selectedCategoryName)
        parts.append(selectedDateRange.rawValue)
        parts.append(sortOption.rawValue)
        return parts.joined(separator: " • ")
    }

    private var selectedCategoryName: String {
        guard let selectedCategory else { return "All Categories" }
        return categories.first { $0.id == selectedCategory }?.name ?? "Selected Category"
    }

    private func sortIcon(for option: SortOption) -> String {
        switch option {
        case .dateDescending, .dateAscending:
            return "calendar"
        case .amountDescending, .amountAscending:
            return "indianrupeesign.circle.fill"
        case .titleAscending, .titleDescending:
            return "textformat"
        }
    }

    private func sortSubtitle(for option: SortOption) -> String {
        switch option {
        case .dateDescending:
            return "Newest expenses first"
        case .dateAscending:
            return "Oldest expenses first"
        case .amountDescending:
            return "Highest amount first"
        case .amountAscending:
            return "Lowest amount first"
        case .titleAscending:
            return "A to Z"
        case .titleDescending:
            return "Z to A"
        }
    }
}

private struct FilterSheetSectionHeader: View {
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

            Text(title)
                .font(.headline)

            Spacer()
        }
    }
}

private struct FilterSelectionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : tint)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? tint : .secondary.opacity(0.45))
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(isSelected ? 0.78 : 0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.42) : Color.white.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FilterOptionChip: View {
    let title: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : tint)
                        .frame(width: 32, height: 32)
                        .background(isSelected ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tint)
                    }
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground).opacity(isSelected ? 0.78 : 0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.42) : Color.white.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func filterSheetCard(cornerRadius: CGFloat = 22) -> some View {
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
    ExpenseListView()
}
