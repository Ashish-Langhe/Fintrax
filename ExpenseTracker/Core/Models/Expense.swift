//
//  Expense.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

/// Represents a single expense transaction
struct Expense: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var amount: Decimal
    var date: Date
    var categoryID: UUID
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    
    /// Initialize a new expense
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - title: Expense title/description
    ///   - amount: Expense amount in INR
    ///   - date: Date of the expense
    ///   - categoryID: ID of the expense category
    ///   - note: Optional note about the expense
    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date = Date(),
        categoryID: UUID,
        note: String? = nil
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amount = amount
        self.date = date
        self.categoryID = categoryID
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
    
    /// Validate the expense data
    /// - Returns: Validation result with error message if invalid
    func validate() -> ValidationResult {
        // Title validation
        if title.isEmpty {
            return ValidationResult(isValid: false, error: "Title cannot be empty")
        }
        
        if title.count > 100 {
            return ValidationResult(isValid: false, error: "Title cannot exceed 100 characters")
        }
        
        // Amount validation
        if amount <= 0 {
            return ValidationResult(isValid: false, error: "Amount must be greater than 0")
        }
        
        if amount > 99999999.99 {
            return ValidationResult(isValid: false, error: "Amount cannot exceed ₹99,999,999.99")
        }
        
        // Date validation (any date allowed - past, present, or future)
        // No date restrictions based on clarifications
        
        // Note validation
        if let note = note {
            if note.count > 500 {
                return ValidationResult(isValid: false, error: "Note cannot exceed 500 characters")
            }
        }
        
        return ValidationResult(isValid: true)
    }
    
    /// Update expense fields
    /// - Parameters:
    ///   - title: New title
    ///   - amount: New amount
    ///   - date: New date
    ///   - categoryID: New category ID
    ///   - note: New optional note
    mutating func update(
        title: String? = nil,
        amount: Decimal? = nil,
        date: Date? = nil,
        categoryID: UUID? = nil,
        note: String? = nil
    ) throws {
        // Create temporary expense for validation
        var tempExpense = self
        
        if let title = title {
            tempExpense.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let amount = amount {
            tempExpense.amount = amount
        }
        if let date = date {
            tempExpense.date = date
        }
        if let categoryID = categoryID {
            tempExpense.categoryID = categoryID
        }
        if let note = note {
            tempExpense.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            tempExpense.note = nil
        }
        
        // Validate updated expense
        let validation = tempExpense.validate()
        guard validation.isValid else {
            throw ExpenseValidationError.validationError(validation.error ?? "Invalid expense data")
        }
        
        // Apply updates if valid
        if let title = title {
            self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let amount = amount {
            self.amount = amount
        }
        if let date = date {
            self.date = date
        }
        if let categoryID = categoryID {
            self.categoryID = categoryID
        }
        if let note = note {
            self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if note == nil {
            self.note = nil
        }
        
        self.updatedAt = Date()
    }
    
    /// Format the amount for display with INR symbol
    /// - Returns: Formatted amount string
    func formattedAmount() -> String {
        CurrencyFormatter.format(amount, maximumFractionDigits: 2, minimumFractionDigits: 2)
    }
    
    /// Get month and year for filtering
    /// - Returns: Tuple containing month and year
    func getMonthAndYear() -> (month: Int, year: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: date)
        return (month: components.month ?? 1, year: components.year ?? 2024)
    }
    
    /// Check if expense is within a specific date range
    /// - Parameters:
    ///   - startDate: Start date of range
    ///   - endDate: End date of range
    /// - Returns: Whether expense falls within the range
    func isWithinDateRange(startDate: Date, endDate: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
}

/// Expense-specific errors
enum ExpenseValidationError: LocalizedError, Sendable {
    case validationError(String)
    case negativeAmount
    case invalidCategory
    
    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return message
        case .negativeAmount:
            return L10n.string("Expense amount cannot be negative")
        case .invalidCategory:
            return L10n.string("Invalid expense category")
        }
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safely access element at index, returns nil if out of bounds
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

// MARK: - Sample Data for Testing
extension Expense {
    /// Creates sample expenses for testing and previews
    static func sampleExpenses(categoryIDs: [UUID]) -> [Expense] {
        let today = Date()
        
        var expenses: [Expense] = []
        
        // Sample expense data
        let sampleData: [(String, Int)] = [
            ("Coffee at Starbucks", 150),
            ("Metro Card Recharge", 500),
            ("Monthly Grocery Shopping", 2500),
            ("Movie Tickets", 400),
            ("Electricity Bill", 800),
            ("Doctor Visit", 1200),
            ("New Shoes", 2500),
            ("Lunch with colleagues", 350)
        ]
        
        for (index, data) in sampleData.enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: -index, to: today) ?? today
            let categoryIndex = index % categoryIDs.count
            
            expenses.append(Expense(
                title: data.0,
                amount: Decimal(data.1),
                date: date,
                categoryID: categoryIDs[safe: categoryIndex] ?? UUID(),
                note: "Sample expense \(index + 1)"
            ))
        }
        
        return expenses.sorted { $0.date > $1.date }
    }
    
    /// Creates a future-dated expense for testing planned expenses
    static func futureExpense(categoryID: UUID) -> Expense {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return Expense(
            title: "Planned Restaurant Visit",
            amount: 1200,
            date: futureDate,
            categoryID: categoryID,
            note: "Dinner with friends next weekend"
        )
    }
}
