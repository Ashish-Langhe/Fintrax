//
//  FormValidationState.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import Foundation
import SwiftUI

/// Form validation state manager
class FormValidationState: ObservableObject {
    @Published var errors: [String: String] = [:]
    @Published var isValid: Bool = true
    
    /// Set or clear error for a specific field
    func setError(for field: String, message: String?) {
        if let message = message {
            errors[field] = message
        } else {
            errors.removeValue(forKey: field)
        }
        updateValidity()
    }
    
    /// Clear all errors
    func clearAllErrors() {
        errors.removeAll()
        isValid = true
    }
    
    /// Validate a specific field and set error if needed
    @discardableResult
    func validateField<T>(_ field: String, value: T, validator: (T) -> ValidationResult) -> Bool {
        let result = validator(value)
        setError(for: field, message: result.isValid ? nil : result.error)
        return result.isValid
    }
    
    /// Multiple field validator
    @discardableResult
    func validateFields(_ validations: [(String, Any, (Any) -> ValidationResult)]) -> Bool {
        var allValid = true
        
        for (field, value, validator) in validations {
            if !validateField(field, value: value, validator: validator) {
                allValid = false
            }
        }
        
        return allValid
    }
    
    /// Check if a specific field has an error
    func errorForField(_ field: String) -> String? {
        errors[field]
    }
    
    /// Get error message for display
    func getErrorMessage(for field: String) -> String? {
        errors[field]
    }
    
    private func updateValidity() {
        isValid = errors.isEmpty
    }
}

/// Convenience validation result
struct ValidationResult {
    let isValid: Bool
    let error: String?
    
    init(isValid: Bool, error: String? = nil) {
        self.isValid = isValid
        self.error = error
    }
}

// MARK: - Common Validators
struct FieldValidators {
    /// Validate a non-empty string
    static func nonEmpty(fieldName: String, minLength: Int = 1, maxLength: Int = 100) -> (String) -> ValidationResult {
        { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                return ValidationResult(isValid: false, error: "\(fieldName) cannot be empty")
            }
            
            if trimmed.count < minLength {
                return ValidationResult(isValid: false, error: "\(fieldName) must be at least \(minLength) characters")
            }
            
            if trimmed.count > maxLength {
                return ValidationResult(isValid: false, error: "\(fieldName) cannot exceed \(maxLength) characters")
            }
            
            return ValidationResult(isValid: true)
        }
    }
    
    /// Validate a positive decimal amount
    static func positiveAmount(max: Decimal = 99999999.99) -> (Decimal) -> ValidationResult {
        { value in
            if value <= 0 {
                return ValidationResult(isValid: false, error: "Amount must be greater than 0")
            }
            
            if value > max {
                return ValidationResult(isValid: false, error: "Amount cannot exceed ₹\(max.formattedAmount())")
            }
            
            return ValidationResult(isValid: true)
        }
    }
    
    /// Validate date is not in the distant future
    static func reasonableDate(maxYearsInFuture: Int = 10) -> (Date) -> ValidationResult {
        { date in
            let now = Date()
            let calendar = Calendar.current
            guard let maxDate = calendar.date(byAdding: .year, value: maxYearsInFuture, to: now) else {
                return ValidationResult(isValid: true)
            }
            
            if date > maxDate {
                return ValidationResult(
                    isValid: false,
                    error: "Date cannot be more than \(maxYearsInFuture) years in the future"
                )
            }
            
            return ValidationResult(isValid: true)
        }
    }
    
    /// Validate category selection
    static func categorySelected() -> (UUID?) -> ValidationResult {
        { categoryID in
            if categoryID == nil {
                return ValidationResult(isValid: false, error: "Please select a category")
            }
            return ValidationResult(isValid: true)
        }
    }
    
    /// Validate PIN code
    static func pinCode(length: Int = 4) -> (String) -> ValidationResult {
        { pin in
            let trimmed = pin.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                return ValidationResult(isValid: false, error: "PIN cannot be empty")
            }
            
            if trimmed.count != length {
                return ValidationResult(isValid: false, error: "PIN must be exactly \(length) digits")
            }
            
            if !trimmed.allSatisfy({ $0.isNumber }) {
                return ValidationResult(isValid: false, error: "PIN must contain only digits")
            }
            
            return ValidationResult(isValid: true)
        }
    }
    
    /// Validate email format
    static func email() -> (String) -> ValidationResult {
        { email in
            let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                return ValidationResult(isValid: false, error: "Email cannot be empty")
            }
            
            let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            
            if !emailPredicate.evaluate(with: trimmed) {
                return ValidationResult(isValid: false, error: "Please enter a valid email address")
            }
            
            return ValidationResult(isValid: true)
        }
    }
}

// MARK: - Decimal Formatting Extension
extension Decimal {
    func formattedAmount() -> String {
        CurrencyFormatter.format(self, maximumFractionDigits: 2, minimumFractionDigits: 2)
    }
}
