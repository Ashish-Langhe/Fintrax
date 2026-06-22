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
    @Published private(set) var smartSearchSummary: String?
    @Published var loadingState: LoadingState<Void> = .idle
    @Published var sortOption: SortOption = .dateDescending
    @Published var showingDeleteAlert = false
    @Published var expenseToDelete: Expense?
    @Published var isRefreshing = false
    
    // MARK: - Private Properties
    private let categoryService: CategoryService
    private let repository: any ExpenseListDataProviding
    private(set) var categories: [Category] = []
    private(set) var hasMorePages = true
    private var pageSize = 50
    private var currentPage = 0
    
    // MARK: - Initialization
    init(repository: (any ExpenseListDataProviding)? = nil) {
        // Initialize services without circular dependency
        self.repository = repository ?? FinanceDataRepository.shared
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
        let smartQuery = SmartExpenseSearchQuery.parse(searchText, categories: categories)
        smartSearchSummary = smartQuery.summary
        
        // Apply category filter
        if let selectedCategoryId = selectedCategory {
            filtered = filtered.filter { $0.categoryID == selectedCategoryId }
        }
        
        // Apply date range filter
        filtered = selectedDateRange.filterExpenses(filtered)

        if let dateRange = smartQuery.dateRange {
            let bounds = dateRange
            filtered = filtered.filter { $0.date >= bounds.start && $0.date <= bounds.end }
        }

        if let categoryID = smartQuery.categoryID {
            filtered = filtered.filter { $0.categoryID == categoryID }
        }

        if let minimumAmount = smartQuery.minimumAmount {
            filtered = filtered.filter { $0.amount >= minimumAmount }
        }

        if let maximumAmount = smartQuery.maximumAmount {
            filtered = filtered.filter { $0.amount <= maximumAmount }
        }
        
        // Apply search filter
        if !smartQuery.keywords.isEmpty {
            filtered = filtered.filter { expense in
                let searchableText = [
                    expense.title,
                    expense.note ?? "",
                    categoryName(for: expense.categoryID) ?? ""
                ]
                .joined(separator: " ")
                .lowercased()

                return smartQuery.keywords.allSatisfy { searchableText.contains($0) }
            }
        } else if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !smartQuery.hasStructuredFilters {
            let query = searchText.lowercased()
            filtered = filtered.filter { expense in
                expense.title.lowercased().contains(query) ||
                expense.note?.lowercased().contains(query) == true ||
                categoryName(for: expense.categoryID)?.lowercased().contains(query) == true
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

private struct SmartExpenseSearchQuery {
    let keywords: [String]
    let categoryID: UUID?
    let minimumAmount: Decimal?
    let maximumAmount: Decimal?
    let dateRange: (start: Date, end: Date)?
    let summary: String?

    var hasStructuredFilters: Bool {
        categoryID != nil || minimumAmount != nil || maximumAmount != nil || dateRange != nil
    }

    static func parse(_ rawText: String, categories: [Category]) -> SmartExpenseSearchQuery {
        let normalized = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalized.isEmpty else {
            return SmartExpenseSearchQuery(keywords: [], categoryID: nil, minimumAmount: nil, maximumAmount: nil, dateRange: nil, summary: nil)
        }

        let category = categories.first { category in
            normalized.contains(category.name.lowercased())
        }

        let amountFilter = parseAmountFilter(normalized)
        let dateRange = parseDateRange(normalized)
        let keywords = parseKeywords(normalized, categories: categories)

        var chips: [String] = []
        if let category {
            chips.append(category.name)
        }
        if let minimum = amountFilter.minimum {
            chips.append(">= \(CurrencyFormatter.format(minimum))")
        }
        if let maximum = amountFilter.maximum {
            chips.append("<= \(CurrencyFormatter.format(maximum))")
        }
        if let label = dateRange.label {
            chips.append(label)
        }
        if !keywords.isEmpty {
            chips.append(keywords.joined(separator: " "))
        }

        return SmartExpenseSearchQuery(
            keywords: keywords,
            categoryID: category?.id,
            minimumAmount: amountFilter.minimum,
            maximumAmount: amountFilter.maximum,
            dateRange: dateRange.range,
            summary: chips.isEmpty ? nil : L10n.format(L10n.Expenses.smartSearchSummary, chips.joined(separator: " • "))
        )
    }

    private static func parseAmountFilter(_ text: String) -> (minimum: Decimal?, maximum: Decimal?) {
        if let amount = firstAmount(after: ["above", "over", "more than", "greater than", "minimum", "at least"], in: text) {
            return (amount, nil)
        }
        if let amount = firstAmount(after: ["below", "under", "less than", "maximum", "at most"], in: text) {
            return (nil, amount)
        }
        return (nil, nil)
    }

    private static func firstAmount(after phrases: [String], in text: String) -> Decimal? {
        for phrase in phrases where text.contains(phrase) {
            let pattern = "\(NSRegularExpression.escapedPattern(for: phrase))\\s*(?:₹|rs\\.?|inr)?\\s*([0-9]+(?:,[0-9]{2,3})*(?:\\.[0-9]+)?|[0-9]+)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: text) else { continue }

            let value = text[valueRange].replacingOccurrences(of: ",", with: "")
            if let doubleValue = Double(value) {
                return Decimal(doubleValue)
            }
        }
        return nil
    }

    private static func parseDateRange(_ text: String) -> (range: (start: Date, end: Date)?, label: String?) {
        let calendar = Calendar.current
        let now = Date()

        if text.contains("last month"),
           let thisMonth = calendar.dateInterval(of: .month, for: now),
           let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonth.start),
           let previousMonth = calendar.dateInterval(of: .month, for: previousMonthStart) {
            return ((previousMonth.start, previousMonth.end), L10n.string(L10n.Expenses.lastMonth))
        }

        if text.contains("this month") {
            let range = DateRangeOption.thisMonth.getDateRange()
            return (range, L10n.string(L10n.Expenses.thisMonth))
        }

        if text.contains("last 30") {
            let range = DateRangeOption.last30Days.getDateRange()
            return (range, L10n.string(L10n.Expenses.last30Days))
        }

        if text.contains("last 7") || text.contains("this week") {
            let range = DateRangeOption.last7Days.getDateRange()
            return (range, L10n.string(L10n.Expenses.recent))
        }

        if text.contains("this year") {
            let range = DateRangeOption.thisYear.getDateRange()
            return (range, L10n.string(L10n.Expenses.thisYear))
        }

        return (nil, nil)
    }

    private static func parseKeywords(_ text: String, categories: [Category]) -> [String] {
        var cleaned = text
        let removablePhrases = [
            "show", "expenses", "expense", "payments", "payment", "entries", "entry",
            "how much", "did i", "i spend", "spent", "spend", "on", "for", "to",
            "last month", "this month", "last 30 days", "last 30", "last 7 days",
            "last 7", "this week", "this year", "above", "over", "more than",
            "greater than", "below", "under", "less than", "minimum", "maximum",
            "at least", "at most", "rs", "inr"
        ]

        for category in categories {
            cleaned = cleaned.replacingOccurrences(of: category.name.lowercased(), with: " ")
        }

        for phrase in removablePhrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: " ")
        }

        cleaned = cleaned.replacingOccurrences(of: "₹", with: " ")
        cleaned = cleaned.replacingOccurrences(of: ".", with: " ")
        cleaned = cleaned.replacingOccurrences(of: ",", with: " ")

        return cleaned
            .split(separator: " ")
            .map(String.init)
            .filter { token in
                token.count > 1 && Double(token) == nil
            }
    }
}

#Preview {
    ExpenseListView()
}
