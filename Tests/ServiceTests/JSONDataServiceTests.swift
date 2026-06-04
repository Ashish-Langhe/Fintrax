//
//  JSONDataServiceTests.swift
//  Fintrax
//
//  Fintrax documentation: Documents tests that verify model and service behavior.
//

import XCTest
@testable import ExpenseTracker

@MainActor
class JSONDataServiceTests: XCTestCase {
    var dataService: JSONDataService!
    var mockDocumentsDirectory: URL!
    private var createdExpenseIDs: [UUID] = []
    private var createdCategoryIDs: [UUID] = []
    
    override func setUp() async throws {
        try await super.setUp()
        
        createdExpenseIDs = []
        createdCategoryIDs = []

        // Create a unique temporary directory for JSON-backed test data.
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExpenseTrackerTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let configuration = JSONDataService.Configuration(
            documentsDirectory: tempDir,
            enableBackups: false // Disable backups for testing
        )
        
        dataService = JSONDataService(configuration: configuration)
        mockDocumentsDirectory = tempDir
    }
    
    override func tearDown() async throws {
        for expenseID in createdExpenseIDs {
            try? await dataService.deleteExpense(id: expenseID)
        }

        for categoryID in createdCategoryIDs {
            try? await dataService.deleteCategory(id: categoryID)
        }

        try? FileManager.default.removeItem(at: mockDocumentsDirectory)

        try await super.tearDown()
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
        createdExpenseIDs.append(expense.id)
        let loadedExpenses = try await dataService.loadExpenses()
        let savedExpense = loadedExpenses.first { $0.id == expense.id }
        
        // Then
        XCTAssertNotNil(savedExpense)
        XCTAssertEqual(savedExpense?.title, "Test Expense")
        XCTAssertEqual(savedExpense?.amount, Decimal(100.50))
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
        createdExpenseIDs.append(expense.id)
        
        // When
        var updatedExpense = expense
        try updatedExpense.update(title: "Updated Title", amount: Decimal(75))
        try await dataService.updateExpense(updatedExpense)
        let loadedExpenses = try await dataService.loadExpenses()
        let savedExpense = loadedExpenses.first { $0.id == expense.id }
        
        // Then
        XCTAssertNotNil(savedExpense)
        XCTAssertEqual(savedExpense?.title, "Updated Title")
        XCTAssertEqual(savedExpense?.amount, Decimal(75))
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
        createdExpenseIDs.append(expense.id)
        let savedExpenses = try await dataService.loadExpenses()
        XCTAssertTrue(savedExpenses.contains { $0.id == expense.id })
        
        // When
        try await dataService.deleteExpense(id: expense.id)
        createdExpenseIDs.removeAll { $0 == expense.id }
        
        // Then
        let loadedExpenses = try await dataService.loadExpenses()
        XCTAssertFalse(loadedExpenses.contains { $0.id == expense.id })
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
        let category = Category(name: uniqueName("Test Category"), isDefault: false)
        
        // When
        try await dataService.saveCategory(category)
        createdCategoryIDs.append(category.id)
        let loadedCategories = try await dataService.loadCategories()
        let savedCategory = loadedCategories.first { $0.id == category.id }
        
        // Then
        XCTAssertNotNil(savedCategory)
        XCTAssertEqual(savedCategory?.name, category.name)
        XCTAssertFalse(savedCategory?.isDefault ?? true)
    }
    
    func testUpdateCategory() async throws {
        // Given
        var category = Category(name: uniqueName("Original Name"), isDefault: false)
        try await dataService.saveCategory(category)
        createdCategoryIDs.append(category.id)
        
        // When
        let newName = uniqueName("New Name")
        try category.updateName(newName)
        try await dataService.updateCategory(category)
        let loadedCategories = try await dataService.loadCategories()
        let savedCategory = loadedCategories.first { $0.id == category.id }
        
        // Then
        XCTAssertNotNil(savedCategory)
        XCTAssertEqual(savedCategory?.name, newName)
    }
    
    func testCannotUpdateDefaultCategoryName() async throws {
        // Given
        guard var defaultCategory = try await dataService.loadCategories().first(where: { $0.name == "Food" }) else {
            XCTFail("Expected seeded default Food category")
            return
        }
        
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
        let category = Category(name: uniqueName("Test Category"), isDefault: false)
        try await dataService.saveCategory(category)
        createdCategoryIDs.append(category.id)
        
        let expense = Expense(
            title: "Test Expense",
            amount: Decimal(100),
            date: Date(),
            categoryID: category.id
        )
        try await dataService.saveExpense(expense)
        createdExpenseIDs.append(expense.id)
        
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
        guard let defaultCategory = try await dataService.loadCategories().first(where: { $0.name == "Food" }) else {
            XCTFail("Expected seeded default Food category")
            return
        }
        
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
        
        // When - Duplicate saves should not corrupt existing data.
        try await dataService.saveExpense(expense)
        createdExpenseIDs.append(expense.id)

        for _ in 0..<2 {
            do {
                try await dataService.saveExpense(expense)
                XCTFail("Should throw duplicate expense constraint violation")
            } catch DataServiceError.constraintViolation {
                // Expected
            }
        }
        
        // Then - Data should remain consistent
        let loadedExpenses = try await dataService.loadExpenses()
        let matchingExpenses = loadedExpenses.filter { $0.id == expense.id }
        XCTAssertEqual(matchingExpenses.count, 1, "Duplicate saves should not corrupt existing data")
        XCTAssertEqual(matchingExpenses.first?.title, "Critical Data")
    }

    private func uniqueName(_ prefix: String) -> String {
        "\(prefix) \(UUID().uuidString)"
    }
}
