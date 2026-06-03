//
//  MonthlyBudget.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

/// Represents a simple monthly budget (not category-specific)
struct MonthlyBudget: Codable, Sendable {
    var amount: Decimal
    var setAt: Date
    
    /// Initialize a new monthly budget
    /// - Parameter amount: The monthly budget amount
    init(amount: Decimal) {
        self.amount = amount
        self.setAt = Date()
    }
    
    /// Validate the budget amount
    /// - Returns: Validation result with error message if invalid
    func validate() -> ValidationResult {
        if amount <= 0 {
            return ValidationResult(isValid: false, error: "Budget amount must be greater than 0")
        }
        
        if amount > 99999999.99 {
            return ValidationResult(isValid: false, error: "Budget amount cannot exceed ₹99,999,999.99")
        }
        
        return ValidationResult(isValid: true)
    }
    
    /// Update the budget amount
    /// - Parameter newAmount: The new budget amount
    mutating func updateAmount(_ newAmount: Decimal) throws {
        // Create temporary budget for validation
        var tempBudget = self
        tempBudget.amount = newAmount
        
        let validation = tempBudget.validate()
        guard validation.isValid else {
            throw MonthlyBudgetValidationError.invalidAmount(validation.error ?? "Invalid amount")
        }
        
        self.amount = newAmount
        self.setAt = Date()
    }
    
    /// Calculate remaining budget
    /// - Parameter totalExpenses: Total expenses for the current month
    /// - Returns: Remaining budget amount (can be negative if over budget)
    func remainingBudget(totalExpenses: Decimal) -> Decimal {
        return amount - totalExpenses
    }
    
    /// Check if user is over budget
    /// - Parameter totalExpenses: Total expenses for the current month
    /// - Returns: Whether the budget is exceeded
    func isOverBudget(totalExpenses: Decimal) -> Bool {
        return totalExpenses > amount
    }
    
    /// Calculate budget usage percentage
    /// - Parameter totalExpenses: Total expenses for the current month
    /// - Returns: Usage percentage (0-1+)
    func usagePercentage(totalExpenses: Decimal) -> Double {
        if amount == 0 {
            return 0.0
        }
        return Double(truncating: (totalExpenses / amount) as NSNumber)
    }
}

/// Monthly budget-specific errors
enum MonthlyBudgetValidationError: LocalizedError, Sendable {
    case invalidAmount(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount(let message):
            return message
        }
    }
}

// Sample data for testing/preview
extension MonthlyBudget {
    /// Creates a sample monthly budget for testing and previews
    static let sample = MonthlyBudget(amount: 50000)
}