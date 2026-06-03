//
//  CategoryService.swift
//  Fintrax
//
//  Fintrax documentation: Implements reusable data, export, budget, category, and configuration services for the app.
//

import Foundation

/// Service for managing expense categories
@MainActor
class CategoryService: ObservableObject, Sendable {
    private let dataService: JSONDataService
    
    /// Shared instance for the category service
    static let shared = CategoryService(dataService: JSONDataService.shared)
    
    /// Initialize category service
    /// - Parameter dataService: JSON data service instance
    init(dataService: JSONDataService) {
        self.dataService = dataService
    }
    
    /// Create default categories if they don't exist
    /// - Throws: DataServiceError if creation fails
    func createDefaultCategoriesIfNeeded() async throws {
        do {
            let existingCategories = try await dataService.loadCategories()
            let hasDefaultCategories = DefaultCategories.allSatisfy { defaultName in
                existingCategories.contains { $0.name == defaultName && $0.isDefault }
            }
            
            if !hasDefaultCategories {
                for definition in DefaultCategoryDefinitions {
                    let category = Category(
                        name: definition.name,
                        iconName: definition.iconName,
                        colorName: definition.colorName,
                        isDefault: true
                    )
                    let existingCategory = existingCategories.first { $0.name.lowercased() == definition.name.lowercased() }
                    
                    if let existing = existingCategory {
                        // Update existing to be default if it matches default category name
                        var updatedCategory = existing
                        updatedCategory.isDefault = true
                        updatedCategory.iconName = definition.iconName
                        updatedCategory.colorName = definition.colorName
                        try await dataService.updateCategory(updatedCategory)
                    } else {
                        // Create new default category
                        try await dataService.saveCategory(category)
                    }
                }
            }
        } catch {
            throw DataServiceError.backupError("Failed to create default categories: \(error.localizedDescription)")
        }
    }
    
    /// Get budget status for a specific category
    /// - Parameters:
    ///   - categoryID: ID of the category
    ///   - expenses: Array of all expenses
    ///   - budget: Optional budget for the category
    /// - Returns: Budget status with percentage
    func getBudgetStatus(for categoryID: UUID, expenses: [Expense], budget: Budget?) -> BudgetStatus {
        guard let budget = budget else {
            return .withinLimit(percentage: 0.0)
        }
        
        // Calculate total spending for this category in the current month
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components) else {
            return .withinLimit(percentage: 0.0)
        }
        
        let monthlyExpenses = expenses.filter { expense in
            expense.categoryID == categoryID && expense.date >= startOfMonth && expense.date < now
        }
        
        let totalSpent = monthlyExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        return budget.calculateStatus(spent: totalSpent)
    }
    
    /// Validate category name uniqueness
    /// - Parameters:
    ///   - name: Category name to validate
    ///   - excludeID: Optional category ID to exclude from uniqueness check (for updates)
    /// - Returns: True if name is unique
    func isCategoryNameUnique(_ name: String, excludeID: UUID? = nil) async throws -> Bool {
        let existingCategories = try await dataService.loadCategories()
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return !existingCategories.contains { category in
            category.name.lowercased() == normalizedName && category.id != excludeID
        }
    }
    
    /// Get all categories with their budget statuses
    /// - Parameters:
    ///   - expenses: Array of all expenses
    ///   - budgets: Array of all budgets
    /// - Returns: Array of tuples with category and budget status
    func getCategoriesWithBudgetStatus(_ expenses: [Expense], _ budgets: [Budget]) async throws -> [(Category, BudgetStatus)] {
        let categories = try await dataService.loadCategories()
        
        return categories.map { category in
            let budget = budgets.first { $0.categoryID == category.id }
            let status = getBudgetStatus(for: category.id, expenses: expenses, budget: budget)
            return (category, status)
        }
    }
    
    /// Get total spending by category for the current month
    /// - Parameters:
    ///   - expenses: Array of all expenses
    ///   - categories: Array of all categories
    /// - Returns: Dictionary mapping category ID to total amount spent
    func getMonthlySpendingByCategory(_ expenses: [Expense], _ categories: [Category]) -> [UUID: Decimal] {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components) else {
            return [:]
        }
        
        let monthlyExpenses = expenses.filter { expense in
            expense.date >= startOfMonth && expense.date < now
        }
        
        var spendingByCategory: [UUID: Decimal] = [:]
        
        for expense in monthlyExpenses {
            let currentSpent = spendingByCategory[expense.categoryID] ?? Decimal(0)
            spendingByCategory[expense.categoryID] = currentSpent + expense.amount
        }
        
        return spendingByCategory
    }
    
    /// Delete a category with all associated data
    /// - Parameter categoryID: ID of the category to delete
    /// - Throws: DataServiceError if deletion fails
    func deleteCategoryWithValidation(_ categoryID: UUID) async throws {
        // Load associated data
        let expenses = try await dataService.loadExpenses()
        let budgets = try await dataService.loadBudgets()
        
        // Check for associated expenses
        let associatedExpenses = expenses.filter { $0.categoryID == categoryID }
        if !associatedExpenses.isEmpty {
            throw DataServiceError.constraintViolation("Cannot delete category with \(associatedExpenses.count) associated expenses")
        }
        
        // Check for associated budget and delete it
        if let budget = budgets.first(where: { $0.categoryID == categoryID }) {
            try await dataService.deleteBudget(id: budget.id)
        }
        
        // Delete the category
        try await dataService.deleteCategory(id: categoryID)
    }
    
    /// Get expense statistics for a category
    /// - Parameters:
    ///   - categoryID: ID of the category
    ///   - expenses: Array of all expenses
    ///   - dateRange: Optional date range filter
    /// - Returns: Category statistics
    func getCategoryStatistics(_ categoryID: UUID, _ expenses: [Expense], dateRange: DateRangeOption? = nil) -> CategoryStatistics {
        let filteredExpenses = dateRange?.filterExpenses(expenses) ?? expenses
        let categoryExpenses = filteredExpenses.filter { $0.categoryID == categoryID }
        
        let totalAmount = categoryExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let averageAmount = categoryExpenses.isEmpty ? Decimal(0) : totalAmount / Decimal(categoryExpenses.count)
        let maxAmount = categoryExpenses.map(\.amount).max() ?? Decimal(0)
        let minAmount = categoryExpenses.map(\.amount).min() ?? Decimal(0)
        
        return CategoryStatistics(
            count: categoryExpenses.count,
            totalAmount: totalAmount,
            averageAmount: averageAmount,
            maxAmount: maxAmount,
            minAmount: minAmount
        )
    }
}

/// Statistics for a category
struct CategoryStatistics: Sendable {
    let count: Int
    let totalAmount: Decimal
    let averageAmount: Decimal
    let maxAmount: Decimal
    let minAmount: Decimal
}
