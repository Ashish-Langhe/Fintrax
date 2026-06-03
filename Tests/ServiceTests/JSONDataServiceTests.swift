//
//  JSONDataServiceTests.swift
//  Fintrax
//
//  Fintrax documentation: Documents tests that verify model and service behavior.
//

import XCTest
@testable import ExpenseTracker

class JSONDataServiceTests: XCTestCase {
    var dataService: JSONDataService!
    var mockDocumentsDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ExpenseTrackerTests")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let configuration = JSONDataService.Configuration(
            documentsDirectory: tempDir,
            enableBackups: false // Disable backups for testing
        )
        
        dataService = JSONDataService(configuration: configuration)
        mockDocumentsDirectory = tempDir
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        // Clean up test directory
        try? FileManager.default.removeItem(at: mockDocumentsDirectory)
    }
    
    // MARK: - Expense Tests
    
    func testSaveAndLoadExpenses() async throws {
        // Given
        let expense = Expense(
            title: "Test Expense",
            amount: Decimal(100.50),
            date: Date(),
            categoryID: UUID()
        )
        
        // When
        try await dataService.saveExpense(expense)
        let loadedExpenses = try await dataService.loadExpenses()
        
        // Then
        XCTAssertEqual(loadedExpenses.count, 1)
        XCTAssertEqual(loadedExpenses.first?.title, "Test Expense")
        XCTAssertEqual(loadedExpenses.first?.amount, Decimal(100.50))
    }
    
    func testUpdateExpense() async throws {
        // Given
        let expense = Expense(
            title: "Original Title",
            amount: Decimal(50),
            date: Date(),
            categoryID: UUID()
        )
        try await dataService.saveExpense(expense)
        
        // When
        var updatedExpense = expense
        try updatedExpense.update(title: "Updated Title", amount: Decimal(75))
        try await dataService.updateExpense(updatedExpense)
        let loadedExpenses = try await dataService.loadExpenses()
        
        // Then
        XCTAssertEqual(loadedExpenses.count, 1)
        XCTAssertEqual(loadedExpenses.first?.title, "Updated Title")
        XCTAssertEqual(loadedExpenses.first?.amount, Decimal(75))
    }
    
    func testDeleteExpense() async throws {
        // Given
        let expense = Expense(
            title: "To Delete",
            amount: Decimal(25),
            date: Date(),
            categoryID: UUID()
        )
        try await dataService.saveExpense(expense)
        XCTAssertEqual(try await dataService.loadExpenses().count, 1)
        
        // When
        try await dataService.deleteExpense(id: expense.id)
        
        // Then
        let loadedExpenses = try await dataService.loadExpenses()
        XCTAssertEqual(loadedExpenses.count, 0)
    }
    
    func testDeleteNonExistentExpense() async throws {
        // Given
        let nonExistentID = UUID()
        
        // When/Then
        do {
            try await dataService.deleteExpense(id: nonExistentID)
            XCTFail("Should throw not found error")
        } catch DataServiceError.notFound {
            // Expected
        }
    }
    
    // MARK: - Category Tests
    
    func testSaveAndLoadCategories() async throws {
        // Given
        let category = Category(name: "Test Category", isDefault: false)
        
        // When
        try await dataService.saveCategory(category)
        let loadedCategories = try await dataService.loadCategories()
        
        // Then
        XCTAssertEqual(loadedCategories.count, 1)
        XCTAssertEqual(loadedCategories.first?.name, "Test Category")
        XCTAssertFalse(loadedCategories.first?.isDefault ?? true)
    }
    
    func testUpdateCategory() async throws {
        // Given
        var category = Category(name: "Original Name", isDefault: false)
        try await dataService.saveCategory(category)
        
        // When
        try category.updateName("New Name")
        try await dataService.updateCategory(category)
        let loadedCategories = try await dataService.loadCategories()
        
        // Then
        XCTAssertEqual(loadedCategories.count, 1)
        XCTAssertEqual(loadedCategories.first?.name, "New Name")
    }
    
    func testCannotUpdateDefaultCategoryName() async throws {
        // Given
        let defaultCategory = Category(name: "Food", isDefault: true)
        try await dataService.saveCategory(defaultCategory)
        
        // When/Then
        do {
            try defaultCategory.updateName("New Name")
            XCTFail("Should throw cannotRenameDefault error")
        } catch CategoryValidationError.cannotRenameDefault {
            // Expected
        }
    }
    
    func testCannotDeleteCategoryWithExpenses() async throws {
        // Given
        let category = Category(name: "Test Category", isDefault: false)
        try await dataService.saveCategory(category)
        
        let expense = Expense(
            title: "Test Expense",
            amount: Decimal(100),
            date: Date(),
            categoryID: category.id
        )
        try await dataService.saveExpense(expense)
        
        // When/Then
        do {
            try await dataService.deleteCategory(id: category.id)
            XCTFail("Should throw constraint violation error")
        } catch DataServiceError.constraintViolation {
            // Expected
        }
    }
    
    func testCannotDeleteDefaultCategory() async throws {
        // Given
        let defaultCategory = Category(name: "Food", isDefault: true)
        try await dataService.saveCategory(defaultCategory)
        
        // When/Then
        do {
            try await dataService.deleteCategory(id: defaultCategory.id)
            XCTFail("Should throw constraint violation error")
        } catch DataServiceError.constraintViolation {
            // Expected
        }
    }
    
    // MARK: - Budget Tests
    
    func testSaveAndLoadBudgets() async throws {
        // Given
        let budget = Budget(categoryID: UUID(), monthlyLimit: Decimal(1000))
        
        // When
        try await dataService.saveBudget(budget)
        let loadedBudgets = try await dataService.loadBudgets()
        
        // Then
        XCTAssertEqual(loadedBudgets.count, 1)
        XCTAssertEqual(loadedBudgets.first?.monthlyLimit, Decimal(1000))
    }
    
    func testCannotCreateDuplicateBudgetForCategory() async throws {
        // Given
        let categoryID = UUID()
        let budget1 = Budget(categoryID: categoryID, monthlyLimit: Decimal(500))
        let budget2 = Budget(categoryID: categoryID, monthlyLimit: Decimal(750))
        try await dataService.saveBudget(budget1)
        
        // When/Then
        do {
            try await dataService.saveBudget(budget2)
            XCTFail("Should throw constraint violation error")
        } catch DataServiceError.constraintViolation {
            // Expected
        }
    }
    
    func testUpdateBudget() async throws {
        // Given
        let budget = Budget(categoryID: UUID(), monthlyLimit: Decimal(500))
        try await dataService.saveBudget(budget)
        
        // When
        var updatedBudget = budget
        try updatedBudget.updateMonthlyLimit(Decimal(1000))
        try await dataService.updateBudget(updatedBudget)
        let loadedBudgets = try await dataService.loadBudgets()
        
        // Then
        XCTAssertEqual(loadedBudgets.count, 1)
        XCTAssertEqual(loadedBudgets.first?.monthlyLimit, Decimal(1000))
    }
    
    // MARK: - Settings Tests
    
    func testSaveAndLoadSettings() async throws {
        // Given
        let settings = AppSettings(
            theme: .dark,
            securityEnabled: true,
            securityType: .biometrics
        )
        
        // When
        try await dataService.saveSettings(settings)
        let loadedSettings = try await dataService.loadSettings()
        
        // Then
        XCTAssertEqual(loadedSettings.theme, .dark)
        XCTAssertTrue(loadedSettings.securityEnabled)
        XCTAssertEqual(loadedSettings.securityType, .biometrics)
    }
    
    func testDefaultSettingsOnFirstLoad() async throws {
        // When/Then - Settings should have default values on first load
        let settings = try await dataService.loadSettings()
        
        XCTAssertEqual(settings.theme, .system)
        XCTAssertFalse(settings.securityEnabled)
        XCTAssertEqual(settings.securityType, .none)
    }
    
    // MARK: - File System Tests
    
    func testAtomicWritePreventsCorruption() async throws {
        // Given
        let expense = Expense(
            title: "Critical Data",
            amount: Decimal(999999),
            date: Date(),
            categoryID: UUID()
        )
        
        // When - Save expense multiple times rapidly
        try await dataService.saveExpense(expense)
        try await dataService.saveExpense(expense)
        try await dataService.saveExpense(expense)
        
        // Then - Data should remain consistent
        let loadedExpenses = try await dataService.loadExpenses()
        XCTAssertEqual(loadedExpenses.count, 1, "Data should not be corrupted by rapid saves")
        XCTAssertEqual(loadedExpenses.first?.title, "Critical Data")
    }
}

// MARK: - Test Helper Extensions
extension Category {
    convenience init(id: UUID = UUID(), name: String, isDefault: Bool = false) {
        self.init()
    }
}

extension Budget {
    convenience init(id: UUID = UUID(), categoryID: UUID, monthlyLimit: Decimal) {
        self.init()
    }
}