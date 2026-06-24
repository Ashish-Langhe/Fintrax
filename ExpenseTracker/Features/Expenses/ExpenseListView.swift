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
    @ObservedObject private var intentRouter = AppIntentNavigationRouter.shared
    @Environment(\.locale) private var locale
    @State private var showingAddExpense = false
    @State private var expenseToEdit: Expense?
    @State private var showingFilterSheet = false
    @State private var displayMode: ExpenseDisplayMode = .list
    @State private var calendarMonth = Date()
    
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
            return L10n.string("expenses.delete.genericMessage")
        }
        return L10n.format(L10n.Expenses.deleteSpecificMessage, expense.title)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FintraxTabBackground(style: .expenses)

                if viewModel.loadingState.isLoading && viewModel.expenses.isEmpty {
                    ProgressView(L10n.Expenses.loading)
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 0) {
                        // Filter and search bar
                        FilterAndSearchBar(
                            selectedCategory: $viewModel.selectedCategory,
                            selectedDateRange: $viewModel.selectedDateRange,
                            searchText: $viewModel.searchText,
                            smartSearchSummary: viewModel.smartSearchSummary,
                            categories: displayCategories,
                            showingFilterSheet: $showingFilterSheet
                        )

                        ExpenseDisplayModePicker(selection: $displayMode)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        
                        // Expense list or empty state
                        if viewModel.filteredExpenses.isEmpty {
                            EmptyExpenseState(
                                hasActiveFilters: viewModel.hasActiveFilters(),
                                onResetFilters: {
                                    viewModel.resetFilters()
                                }
                            )
                        } else {
                            switch displayMode {
                            case .list:
                                expenseList
                            case .calendar:
                                ExpenseCalendarInsightView(
                                    expenses: viewModel.filteredExpenses,
                                    categories: viewModel.categories,
                                    selectedMonth: $calendarMonth
                                )
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(L10n.Expenses.title)
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
                title: L10n.string("expenses.delete.question"),
                message: deleteExpenseMessage,
                icon: "trash.fill",
                tint: AppDesignSystem.Colors.error,
                primaryAction: FintraxModalAction(title: L10n.string("expenses.delete.action"), icon: "trash.fill", tint: AppDesignSystem.Colors.error, isDestructive: true) {
                    Task {
                        await viewModel.confirmDelete()
                    }
                },
                secondaryAction: FintraxModalAction(title: L10n.string("expenses.delete.keep"), icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
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
            .onChange(of: locale.identifier) { _, _ in
                viewModel.applyFilters()
            }
            .onAppear {
                presentPendingIntentDestinationIfNeeded()
            }
            .onChange(of: intentRouter.pendingDestination) { _, _ in
                presentPendingIntentDestinationIfNeeded()
            }
        }
    }

    private func presentPendingIntentDestinationIfNeeded() {
        guard intentRouter.consumePendingDestination() == .addExpense else { return }
        showingAddExpense = true
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
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            Section {
                ExpenseFeedHeader(
                    count: viewModel.filteredCount(),
                    period: expenseListPeriod
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

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
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
        viewModel.selectedDateRange == .allTime ? L10n.string("expenses.period.allTime") : viewModel.selectedDateRange.localizedString
    }

}

#Preview {
    ExpenseListView()
}
