//
//  Budget.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

/// Represents a monthly budget for a specific category
struct Budget: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let categoryID: UUID
    var monthlyLimit: Decimal
    var createdAt: Date
    var updatedAt: Date
    
    /// Initialize a new budget
    /// - Parameters:
    ///   - categoryID: The ID of the category this budget applies to
    ///   - monthlyLimit: The monthly spending limit
    init(id: UUID = UUID(), categoryID: UUID, monthlyLimit: Decimal) {
        self.id = id
        self.categoryID = categoryID
        self.monthlyLimit = monthlyLimit
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    /// Validate the budget data
    /// - Returns: Validation result with error message if invalid
    func validate() -> ValidationResult {
        // Monthly limit validation
        if monthlyLimit <= 0 {
            return ValidationResult(isValid: false, error: "Monthly limit must be greater than 0")
        }
        
        if monthlyLimit > 99999999.99 {
            return ValidationResult(isValid: false, error: "Monthly limit cannot exceed ₹99,999,999.99")
        }
        
        return ValidationResult(isValid: true)
    }
    
    /// Update the monthly limit
    /// - Parameter newLimit: The new monthly limit
    mutating func updateMonthlyLimit(_ newLimit: Decimal) throws {
        // Create temporary budget for validation
        var tempBudget = self
        tempBudget.monthlyLimit = newLimit
        
        let validation = tempBudget.validate()
        guard validation.isValid else {
            throw BudgetValidationError.invalidLimit(validation.error ?? "Invalid limit")
        }
        
        self.monthlyLimit = newLimit
        self.updatedAt = Date()
    }
    
    /// Calculate the budget status based on current spending
    /// - Parameter spent: The amount spent so far this month
    /// - Returns: The budget status
    func calculateStatus(spent: Decimal) -> BudgetStatus {
        if monthlyLimit == 0 {
            return .exceededLimit(percentage: 1.0)
        }
        
        let percentage = NSDecimalNumber(decimal: spent / monthlyLimit).doubleValue
        
        if percentage < 0.8 {
            return .withinLimit(percentage: percentage)
        } else if percentage < 1.0 {
            return .approachingLimit(percentage: percentage)
        } else {
            return .exceededLimit(percentage: percentage)
        }
    }
    
    /// Calculate remaining budget amount
    /// - Parameter spent: The amount spent so far this month
    /// - Returns: The remaining amount (can be negative if over budget)
    func remainingBudget(spent: Decimal) -> Decimal {
        return monthlyLimit - spent
    }
    
    /// Check if the budget is exceeded
    /// - Parameter spent: The amount spent so far this month
    /// - Returns: Whether the budget is exceeded
    func isExceeded(spent: Decimal) -> Bool {
        let result = calculateStatus(spent: spent)
        if case .exceededLimit = result {
            return true
        }
        return false
    }
    
    /// Check if the user is approaching budget limit (80%+)
    /// - Parameter spent: The amount spent so far this month
    /// - Returns: Whether the user is approaching the limit
    func isApproachingLimit(spent: Decimal) -> Bool {
        let result = calculateStatus(spent: spent)
        if case .approachingLimit = result {
            return true
        }
        return false
    }
}

/// Budget-specific errors
enum BudgetValidationError: LocalizedError, Sendable {
    case invalidLimit(String)
    case duplicateBudgetForCategory
    
    var errorDescription: String? {
        switch self {
        case .invalidLimit(let message):
            return message
        case .duplicateBudgetForCategory:
            return L10n.string("A budget already exists for this category")
        }
    }
}

// MARK: - Sample Data for Testing
extension Budget {
    /// Creates sample budgets for testing and previews
    static func sampleBudgets() -> [Budget] {
        let categoryIDs = DefaultCategories.enumerated().map { _ in UUID() }
        
        return categoryIDs.enumerated().map { index, categoryID in
            let limits: [Decimal] = [1000, 500, 300, 200, 400, 800, 150]
            return Budget(
                categoryID: categoryID,
                monthlyLimit: limits[safe: index] ?? 200
            )
        }
    }
}
