//
//  BudgetValidation.swift
//  Fintrax
//
//  Fintrax documentation: Provides shared calculation and validation helpers for finance workflows.
//

import Foundation

/// Utility functions for budget validation and formatting
struct BudgetValidation {
    
    /// Validate budget amount input
    /// - Parameter amount: The amount to validate
    /// - Returns: ValidationResult indicating if the amount is valid
    static func validateBudgetAmount(_ amount: Decimal) -> ValidationResult {
        if amount <= 0 {
            return ValidationResult(isValid: false, error: "Budget amount must be greater than 0")
        }
        
        if amount > 99999999.99 {
            return ValidationResult(isValid: false, error: "Budget amount cannot exceed ₹99,999,999.99")
        }
        
        return ValidationResult(isValid: true)
    }
    
    /// Validate and format budget input string
    /// - Parameter input: String input from user
    /// - Returns: Result with formatted Decimal or error
    static func validateAndParseBudgetInput(_ input: String) -> Result<Decimal, MonthlyBudgetValidationError> {
        // Remove common formatting characters
        let cleanInput = input
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanInput.isEmpty else {
            return .failure(MonthlyBudgetValidationError.invalidAmount("Please enter a budget amount"))
        }
        
        guard let amount = Decimal(string: cleanInput) else {
            return .failure(MonthlyBudgetValidationError.invalidAmount("Please enter a valid number"))
        }
        
        let validation = validateBudgetAmount(amount)
        guard validation.isValid else {
            return .failure(MonthlyBudgetValidationError.invalidAmount(validation.error ?? "Invalid amount"))
        }
        
        return .success(amount)
    }
    
    /// Format budget amount for display (with INR currency)
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted currency string
    static func formatBudgetAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0.00"
    }
    
    /// Format budget amount for input field (without currency symbol for editing)
    /// - Parameter amount: The amount to format
    /// - Returns: Plain number string
    static func formatBudgetAmountForInput(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
    }
}

