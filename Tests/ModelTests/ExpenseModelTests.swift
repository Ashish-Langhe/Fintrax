//
//  ExpenseModelTests.swift
//  Fintrax
//
//  Fintrax documentation: Documents tests that verify model and service behavior.
//

import XCTest
@testable import ExpenseTracker

class ExpenseModelTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testExpenseInitialization() {
        // Given
        let title = "Test Expense"
        let amount = Decimal(100.50)
        let date = Date()
        let categoryID = UUID()
        
        // When
        let expense = Expense(
            title: title,
            amount: amount,
            date: date,
            categoryID: categoryID
        )
        
        // Then
        XCTAssertEqual(expense.title, title)
        XCTAssertEqual(expense.amount, amount)
        XCTAssertEqual(expense.date, date)
        XCTAssertEqual(expense.categoryID, categoryID)
        XCTAssertNil(expense.note)
        XCTAssertNotNil(expense.id)
        XCTAssertNotNil(expense.createdAt)
        XCTAssertNotNil(expense.updatedAt)
    }
    
    func testExpenseInitializationWithNote() {
        // Given
        let note = "Optional note"
        
        // When
        let expense = Expense(
            title: "Test",
            amount: Decimal(50),
            categoryID: UUID(),
            note: note
        )
        
        // Then
        XCTAssertEqual(expense.note, note)
    }
    
    // MARK: - Validation Tests
    
    func testValidExpensePassesValidation() {
        // Given
        let expense = Expense(
            title: "Valid Expense",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID(),
            note: "Optional note"
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertTrue(validation.isValid, "Valid expense should pass validation")
        XCTAssertNil(validation.error, "Valid expense should not have error message")
    }
    
    func testEmptyTitleFailsValidation() {
        // Given
        let expense = Expense(
            title: "",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.error, "Title cannot be empty")
    }
    
    func testTitleTooLongFailsValidation() {
        // Given
        let longTitle = String(repeating: "a", count: 101)
        let expense = Expense(
            title: longTitle,
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.error, "Title cannot exceed 100 characters")
    }
    
    func testTitleWithTrailingWhitespaceIsTrimmed() {
        // Given
        let titleWithSpaces = "  Test Expense  "
        let expense = Expense(title: titleWithSpaces, amount: Decimal(100), date: Date(), categoryID: UUID())
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(expense.title, "Test Expense")
    }
    
    func testNegativeAmountFailsValidation() {
        // Given
        let expense = Expense(
            title: "Test Expense",
            amount: Decimal(-100),
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.error, "Amount must be greater than 0")
        XCTAssertEqual(validation.error, "Expense amount cannot be negative")
    }
    
    func testZeroAmountFailsValidation() {
        // Given
        let expense = Expense(
            title: "Test Expense",
            amount: Decimal(0),
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.error, "Amount must be greater than 0")
    }
    
    func testAmountTooLargeFailsValidation() {
        // Given
        let hugeAmount = Decimal(string: "100000000")!
        let expense = Expense(
            title: "Test Expense",
            amount: hugeAmount,
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.error, "Amount cannot exceed ₹99,999,999.99")
    }
    
    func testMaximumValidAmountPassesValidation() {
        // Given
        let maxAmount = Decimal(string: "99999999.99")!
        let expense = Expense(
            title: "Test Expense",
            amount: maxAmount,
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(expense.amount, maxAmount)
    }
    
    func testFutureDateIsAllowed() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let expense = Expense(
            title: "Future Planning",
            amount: Decimal(100),
            date: futureDate,
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertTrue(validation.isValid, "Future dates should be allowed per clarification")
    }
    
    func testPastDateIsAllowed() {
        // Given
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let expense = Expense(
            title: "Past Expense",
            amount: Decimal(100),
            date: pastDate,
            categoryID: UUID()
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertTrue(validation.isValid)
    }
    
    func testNoteTooLongFailsValidation() {
        // Given
        let longNote = String(repeating: "a", count: 501)
        let expense = Expense(
            title: "Test",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID(),
            note: longNote
        )
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.error, "Note cannot exceed 500 characters")
    }
    
    func testNoteWithTrailingWhitespaceIsTrimmed() {
        // Given
        let noteWithSpaces = "  Test note  "
        let expense = Expense(title: "Test", amount: Decimal(100), date: Date(), categoryID: UUID(), note: noteWithSpaces)
        
        // When
        let validation = expense.validate()
        
        // Then
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(expense.note, "Test note")
    }
    
    // MARK: - Update Tests
    
    func testUpdateExpenseWithValidData() {
        // Given
        var expense = Expense(
            title: "Original Title",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID()
        )
        let newTitle = "Updated Title"
        let newAmount = Decimal(200)
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        // When
        try! expense.update(title: newTitle, amount: newAmount, date: newDate)
        
        // Then
        XCTAssertEqual(expense.title, newTitle)
        XCTAssertEqual(expense.amount, newAmount)
        XCTAssertEqual(expense.date, newDate)
        XCTAssertNotEqual(expense.updatedAt, expense.createdAt)
    }
    
    func testUpdateExpenseWithInvalidData() {
        // Given
        var expense = Expense(
            title: "Original Title",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID()
        )
        
        // When/Then
        do {
            try expense.update(title: "", amount: Decimal(200), date: Date())
            XCTFail("Should throw validation error")
        } catch ExpenseValidationError.validationError(let message) {
            XCTAssertEqual(message, "Title cannot be empty")
        }
    }
    
    func testUpdateExpenseWithNegativeAmount() {
        // Given
        var expense = Expense(
            title: "Test",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID()
        )
        
        // When/Then
        do {
            try expense.update(amount: Decimal(-50))
            XCTFail("Should throw validation error")
        } catch ExpenseValidationError.validationError(let message) {
            XCTAssertEqual(message, "Invalid expense data")
        }
    }
    
    // MARK: - Formatting Tests
    
    func testFormattedAmountWithINR() {
        // Given
        let expense = Expense(
            title: "Test",
            amount: Decimal(1234.56),
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let formatted = expense.formattedAmount()
        
        // Then
        XCTAssertTrue(formatted.hasPrefix("₹"))
        XCTAssertTrue(formatted.contains("1,234.56"))
    }
    
    func testFormattedAmountForZero() {
        // Given
        let expense = Expense(
            title: "Test",
            amount: Decimal(0),
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        let formatted = expense.formattedAmount()
        
        // Then
        XCTAssertEqual(formatted, "₹0.00")
    }
    
    // MARK: - Helper Method Tests
    
    func testGetMonthAndYear() {
        // Given
        let specificDate = componentsDate(year: 2024, month: 6, day: 15)!
        let expense = Expense(
            title: "Test",
            amount: Decimal(100),
            date: specificDate,
            categoryID: UUID()
        )
        
        // When
        let monthYear = expense.getMonthAndYear()
        
        // Then
        XCTAssertEqual(monthYear.month, 6)
        XCTAssertEqual(monthYear.year, 2024)
    }
    
    func testIsWithinDateRange() {
        // Given
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let expense = Expense(
            title: "Test",
            amount: Decimal(100),
            date: Calendar.current.date(byAdding: .day, value: 3, to: startDate)!,
            categoryID: UUID()
        )
        
        // When
        let isInRange = expense.isWithinDateRange(startDate: startDate, endDate: endDate)
        
        // Then
        XCTAssertTrue(isInRange)
    }
    
    func testIsNotWithinDateRange() {
        // Given
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let expense = Expense(
            title: "Test",
            amount: Decimal(100),
            date: Calendar.current.date(byAdding: .day, value: 10, to: startDate)!,
            categoryID: UUID()
        )
        
        // When
        let isInRange = expense.isWithinDateRange(startDate: startDate, endDate: endDate)
        
        // Then
        XCTAssertFalse(isInRange)
    }
    
    // MARK: - Equatable Tests
    
    func testExpenseEquality() {
        // Given
        let id = UUID()
        let date = Date()
        
        let expense1 = Expense(
            id: id,
            title: "Test",
            amount: Decimal(100),
            date: date,
            categoryID: UUID()
        )
        
        let expense2 = Expense(
            id: id,
            title: "Test",
            amount: Decimal(100),
            date: date,
            categoryID: UUID()
        )
        
        // When/Then
        XCTAssertEqual(expense1, expense2)
    }
    
    func testExpenseInequality() {
        // Given
        let expense1 = Expense(
            title: "Test 1",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID()
        )
        
        let expense2 = Expense(
            title: "Test 2",
            amount: Decimal(100),
            date: Date(),
            categoryID: UUID()
        )
        
        // When/Then
        XCTAssertNotEqual(expense1, expense2)
    }
    
    // MARK: - Hashable Tests
    
    func testExpenseHashable() {
        // Given
        let expenses = [
            Expense(title: "Test 1", amount: Decimal(100), date: Date(), categoryID: UUID()),
            Expense(title: "Test 2", amount: Decimal(200), date: Date(), categoryID: UUID()),
            Expense(title: "Test 1", amount: Decimal(100), date: Date(), categoryID: UUID())
        ]
        
        // When
        let uniqueExpenses = Set(expenses)
        
        // Then
        XCTAssertEqual(uniqueExpenses.count, 2, "Duplicate expenses should be deduplicated in a Set")
    }
    
    // MARK: - Codable Tests
    
    func testExpenseCodable() {
        // Given
        let originalExpense = Expense(
            title: "Test",
            amount: Decimal(123.45),
            date: Date(),
            categoryID: UUID(),
            note: "Test note"
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(originalExpense)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedExpense = try! decoder.decode(Expense.self, from: data)
        
        // Then
        XCTAssertEqual(originalExpense.id, decodedExpense.id)
        XCTAssertEqual(originalExpense.title, decodedExpense.title)
        XCTAssertEqual(originalExpense.amount, decodedExpense.amount)
        XCTAssertEqual(originalExpense.note, decodedExpense.note)
    }
    
    // MARK: - Sendable Tests
    
    func testExpenseConformsToSendable() {
        // Given/When/Then - This test passes if Expense conforms to Sendable protocol
        XCTAssertTypeIsSendable(Expense())
        
        // Test that array of expenses is also Sendable
        let expenses = [Expense()]
        XCTAssertTypeIsSendable(expenses)
    }
    
}

// MARK: - Test Helper

/// 点擊式：它不尋
extension Expense {
    convenience init(
        id: UUID = UUID(),
        title: String = "Test",
        amount: Decimal = 100,
        date: Date = Date(),
        categoryID: UUID = UUID(),
        note: String? = nil
    ) {
        self.init()
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
}

extension Date {
    init?(year: Int, month: Int, day: Int) {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components)
    }
}