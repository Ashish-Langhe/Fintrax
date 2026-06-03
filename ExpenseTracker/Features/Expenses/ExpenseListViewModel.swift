//
//  ExpenseListViewModel.swift
//  Fintrax
//
//  Fintrax documentation: Builds expense list, filtering, searching, add/edit, validation, and row presentation flows.
//

import Foundation
import SwiftUI

/// ViewModel for managing the expense list
@MainActor
class ExpenseListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var expenses: [Expense] = []
    @Published var filteredExpenses: [Expense] = []
    @Published var isLoading = false
    @Published var selectedCategory: UUID?
    @Published var selectedDateRange: DateRangeOption = .allTime
    @Published var searchText = ""
    @Published var loadingState: LoadingState<Void> = .idle
    @Published var sortOption: SortOption = .dateDescending
    @Published var showingDeleteAlert = false
    @Published var expenseToDelete: Expense?
    @Published var isRefreshing = false
    
    // MARK: - Private Properties
    private let categoryService: CategoryService
    private let repository: FinanceDataRepository
    private(set) var categories: [Category] = []
    private(set) var hasMorePages = true
    private var pageSize = 50
    private var currentPage = 0
    
    // MARK: - Initialization
    init() {
        // Initialize services without circular dependency
        self.repository = .shared
        self.categoryService = CategoryService.shared
    }
    
    // MARK: - Public Methods
    
    /// Load all expenses and categories
    func loadData() async {
        let isInitialLoad = expenses.isEmpty
        if isInitialLoad {
            loadingState = .loading
        }
        
        do {
            async let expensesTask = loadExpenses()
            async let categoriesTask = loadCategories()
            
            let (loadedExpenses, loadedCategories) = try await (expensesTask, categoriesTask)
            
            expenses = loadedExpenses
            categories = loadedCategories
            currentPage = 0
            hasMorePages = loadedExpenses.count > pageSize
            
            applyFilters()
            
            if isInitialLoad {
                loadingState = .success(())
            }
        } catch {
            if isInitialLoad {
                loadingState = .failure(error)
            }
        }
    }
    
    /// Load expenses with pagination
    func loadExpenses() async throws -> [Expense] {
        try await repository.loadExpenses()
    }
    
    /// Load categories
    func loadCategories() async throws -> [Category] {
        try await repository.loadCategories()
    }
    
    /// Look up an expense by ID
    func expense(with id: UUID) -> Expense? {
        expenses.first { $0.id == id }
    }
    
    /// Load more expenses for pagination
    func loadMoreExpenses() async {
        guard !isLoading && hasMorePages else { return }
        
        isLoading = true
        
        do {
            let newExpenses = try await repository.loadExpenses()
            let startIndex = (currentPage + 1) * pageSize
            let endIndex = min(startIndex + pageSize, newExpenses.count)
            
            if startIndex >= newExpenses.count {
                hasMorePages = false
            } else {
                let newPage = Array(newExpenses[startIndex..<endIndex])
                expenses.append(contentsOf: newPage)
                currentPage += 1
                applyFilters()
            }
        } catch {
            print("Error loading more expenses: \(error)")
        }
        
        isLoading = false
    }
    
    /// Delete an expense
    func deleteExpense(_ expense: Expense) async {
        expenseToDelete = expense
        showingDeleteAlert = true
    }
    
    /// Confirm deletion of expense
    func confirmDelete() async {
        guard let expense = expenseToDelete else { return }
        
        do {
            try await repository.deleteExpense(id: expense.id)
            expenses.removeAll { $0.id == expense.id }
            applyFilters()
        } catch {
            print("Error deleting expense: \(error)")
        }
        
        showingDeleteAlert = false
        expenseToDelete = nil
    }
    
    /// Cancel deletion
    func cancelDelete() {
        showingDeleteAlert = false
        expenseToDelete = nil
    }
    
    /// Apply current filters to expenses
    @discardableResult
    func applyFilters() -> [Expense] {
        var filtered = expenses
        
        // Apply category filter
        if let selectedCategoryId = selectedCategory {
            filtered = filtered.filter { $0.categoryID == selectedCategoryId }
        }
        
        // Apply date range filter
        filtered = selectedDateRange.filterExpenses(filtered)
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.note?.localizedCaseInsensitiveContains(searchText) == true ||
                categoryName(for: expense.categoryID)?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply sort order
        switch sortOption {
        case .dateDescending:
            filtered.sort { $0.date > $1.date }
        case .dateAscending:
            filtered.sort { $0.date < $1.date }
        case .amountDescending:
            filtered.sort { $0.amount > $1.amount }
        case .amountAscending:
            filtered.sort { $0.amount < $1.amount }
        case .titleAscending:
            filtered.sort { $0.title < $1.title }
        case .titleDescending:
            filtered.sort { $0.title > $1.title }
        }
        
        filteredExpenses = filtered
        return filtered
    }
    
    /// Get category name for ID
    func categoryName(for categoryId: UUID) -> String? {
        return categories.first { $0.id == categoryId }?.name
    }
    
    /// Get category for ID
    func category(for categoryId: UUID) -> Category? {
        return categories.first { $0.id == categoryId }
    }
    
    /// Refresh data from disk (e.g. after adding or editing an expense)
    func refreshData() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await loadData()
    }
    
    /// Reset filters
    func resetFilters() {
        selectedCategory = nil
        selectedDateRange = .allTime
        searchText = ""
        sortOption = .dateDescending
        applyFilters()
    }
    
    /// Get total amount for filtered expenses
    func totalFilteredAmount() -> Decimal {
        return filteredExpenses.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    /// Get count of filtered expenses
    func filteredCount() -> Int {
        return filteredExpenses.count
    }
    
    /// Check if any filters are applied
    func hasActiveFilters() -> Bool {
        return selectedCategory != nil || 
               selectedDateRange != .allTime || 
               !searchText.isEmpty ||
               sortOption != .dateDescending
    }
}

#Preview {
    ExpenseListView()
}
