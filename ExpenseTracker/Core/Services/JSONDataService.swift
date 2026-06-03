//
//  JSONDataService.swift
//  Fintrax
//
//  Fintrax documentation: Implements reusable data, export, budget, category, and configuration services for the app.
//

import Foundation

/// JSON data service for expense tracking data persistence
@MainActor
class JSONDataService: ObservableObject, Sendable {
    private let config: Configuration
    private let backupManager: BackupManager
    private var isStorageInitialized = false
    
    // File names for persistent storage
    private enum FileName {
        static let expenses = "expenses"
        static let categories = "categories"
        static let budgets = "budgets"
        static let settings = "settings"
        static let monthlyBudget = "monthly_budget"
    }

    private enum MigrationFlag {
        static func swiftDataCompleted(for fileName: String) -> String {
            "Fintrax.swiftDataMigrationCompleted.\(fileName)"
        }
    }
    
    /// Configuration for JSON data service
    struct Configuration: Sendable {
        let documentsDirectory: URL
        let maxBackups: Int
        let enableBackups: Bool
        
        init(documentsDirectory: URL, maxBackups: Int = 5, enableBackups: Bool = true) {
            self.documentsDirectory = documentsDirectory
            self.maxBackups = maxBackups
            self.enableBackups = enableBackups
        }
    }
    
    /// Shared instance for the data service
    static let shared = JSONDataService()
    
    init(configuration: Configuration? = nil) {
        let config = configuration ?? ConfigurationService.shared.getConfigurationSync()
        self.config = config
        self.backupManager = BackupManager(configuration: config)
    }
    
    // MARK: - Expense Operations
    
    /// Load all expenses from persistent storage
    /// - Returns: Array of Expense objects
    /// - Throws: DataServiceError if file cannot be read or parsed
    func loadExpenses() async throws -> [Expense] {
        await ensureStorageReady()
        let expenses = try SwiftDataStore.shared.loadExpenses()
        if expenses.isEmpty, fileExists(FileName.expenses), !hasCompletedSwiftDataMigration(for: FileName.expenses) {
            let legacyExpenses = try await loadCollection(from: FileName.expenses, type: [Expense].self)
            for expense in legacyExpenses {
                try? SwiftDataStore.shared.saveExpense(expense)
            }
            finishSwiftDataMigration(for: FileName.expenses)
            return try SwiftDataStore.shared.loadExpenses()
        }

        if !expenses.isEmpty {
            finishSwiftDataMigration(for: FileName.expenses)
        }

        return expenses
    }
    
    /// Save a new expense to persistent storage
    /// - Parameter expense: The expense to save
    /// - Throws: DataServiceError if save fails
    func saveExpense(_ expense: Expense) async throws {
        await ensureStorageReady()
        
        let validation = expense.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid expense data")
        }
        
        try SwiftDataStore.shared.saveExpense(expense)
        finishSwiftDataMigration(for: FileName.expenses)
    }
    
    /// Update an existing expense in persistent storage
    /// - Parameter expense: The expense with updated values
    /// - Throws: DataServiceError if update fails
    func updateExpense(_ expense: Expense) async throws {
        try SwiftDataStore.shared.updateExpense(expense)
        finishSwiftDataMigration(for: FileName.expenses)
    }
    
    /// Delete an expense from persistent storage
    /// - Parameter expenseID: ID of the expense to delete
    /// - Throws: DataServiceError if delete fails
    func deleteExpense(id expenseID: UUID) async throws {
        try SwiftDataStore.shared.deleteExpense(id: expenseID)
        finishSwiftDataMigration(for: FileName.expenses)
    }
    
    // MARK: - Category Operations
    
    /// Load all categories from persistent storage
    /// - Returns: Array of Category objects
    /// - Throws: DataServiceError if file cannot be read or parsed
    func loadCategories() async throws -> [Category] {
        await ensureStorageReady()
        try SwiftDataStore.shared.seedDefaultCategoriesIfNeeded()

        let categories = try SwiftDataStore.shared.loadCategories()
        if categories.count <= DefaultCategories.count,
           fileExists(FileName.categories),
           !hasCompletedSwiftDataMigration(for: FileName.categories) {
            do {
                let legacyCategories = try await loadCollection(from: FileName.categories, type: [Category].self)
                for legacyCategory in legacyCategories {
                    let category = categoryWithDefaultPresentation(legacyCategory)
                    try? SwiftDataStore.shared.upsertCategoryPreservingIdentity(category)
                }
            } catch {
                ErrorLogger.log(error, context: "loadCategories.legacyMigration")
            }
            try SwiftDataStore.shared.seedDefaultCategoriesIfNeeded()
            finishSwiftDataMigration(for: FileName.categories)
            return try SwiftDataStore.shared.loadCategories()
        }

        finishSwiftDataMigration(for: FileName.categories)
        return categories
    }
    
    /// Save a new category to persistent storage
    /// - Parameter category: The category to save
    /// - Throws: DataServiceError if save fails
    func saveCategory(_ category: Category) async throws {
        try SwiftDataStore.shared.saveCategory(categoryWithDefaultPresentation(category))
        finishSwiftDataMigration(for: FileName.categories)
    }
    
    /// Update an existing category in persistent storage
    /// - Parameter category: The category with updated values
    /// - Throws: DataServiceError if update fails
    func updateCategory(_ category: Category) async throws {
        try SwiftDataStore.shared.updateCategory(categoryWithDefaultPresentation(category))
        finishSwiftDataMigration(for: FileName.categories)
    }
    
    /// Delete a category from persistent storage
    /// - Parameter categoryID: ID of the category to delete
    /// - Throws: DataServiceError if delete fails
    func deleteCategory(id categoryID: UUID) async throws {
        await ensureStorageReady()

        let expenses = try SwiftDataStore.shared.loadExpenses()
        let hasAttachedExpenses = expenses.contains { $0.categoryID == categoryID }
        let replacementCategoryID = hasAttachedExpenses ? try replacementCategoryID(forDeleting: categoryID) : nil

        try SwiftDataStore.shared.deleteCategory(id: categoryID, reassignExpensesTo: replacementCategoryID)
        finishSwiftDataMigration(for: FileName.categories)
        finishSwiftDataMigration(for: FileName.expenses)
    }
    
    // MARK: - Budget Operations
    
    /// Load all budgets from persistent storage
    /// - Returns: Array of Budget objects
    /// - Throws: DataServiceError if file cannot be read or parsed
    func loadBudgets() async throws -> [Budget] {
        await ensureStorageReady()
        return try await loadCollection(from: FileName.budgets, type: [Budget].self)
    }
    
    /// Save a new budget to persistent storage
    /// - Parameter budget: The budget to save
    /// - Throws: DataServiceError if save fails
    func saveBudget(_ budget: Budget) async throws {
        var budgets = try await loadBudgets()
        
        // Check for duplicate budgets for the same category
        if budgets.contains(where: { $0.categoryID == budget.categoryID }) {
            throw DataServiceError.constraintViolation("Budget for category already exists")
        }
        
        // Validate the budget
        let validation = budget.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid budget data")
        }
        
        budgets.append(budget)
        try await saveToFile(budgets, fileName: FileName.budgets)
    }
    
    /// Update an existing budget in persistent storage
    /// - Parameter budget: The budget with updated values
    /// - Throws: DataServiceError if update fails
    func updateBudget(_ budget: Budget) async throws {
        var budgets = try await loadBudgets()
        
        guard let index = budgets.firstIndex(where: { $0.id == budget.id }) else {
            throw DataServiceError.notFound("Budget with ID \(budget.id) not found")
        }
        
        // Validate before updating
        let validation = budget.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid budget data")
        }
        
        budgets[index] = budget
        try await saveToFile(budgets, fileName: FileName.budgets)
    }
    
    /// Delete a budget from persistent storage
    /// - Parameter budgetID: ID of the budget to delete
    /// - Throws: DataServiceError if delete fails
    func deleteBudget(id budgetID: UUID) async throws {
        var budgets = try await loadBudgets()
        
        guard budgets.contains(where: { $0.id == budgetID }) else {
            throw DataServiceError.notFound("Budget with ID \(budgetID) not found")
        }
        
        budgets.removeAll { $0.id == budgetID }
        try await saveToFile(budgets, fileName: FileName.budgets)
    }
    
    // MARK: - Monthly Budget Operations
    
    /// Load the monthly budget from persistent storage
    /// - Returns: MonthlyBudget or nil if none exists
    /// - Throws: DataServiceError if file cannot be read or parsed
    func loadMonthlyBudget() async throws -> MonthlyBudget? {
        await ensureStorageReady()
        if let swiftDataBudget = try SwiftDataStore.shared.loadMonthlyBudget() {
            finishSwiftDataMigration(for: FileName.monthlyBudget)
            return swiftDataBudget
        }

        finishSwiftDataMigration(for: FileName.monthlyBudget)
        return nil
    }
    
    /// Save the monthly budget to persistent storage
    /// - Parameter monthlyBudget: The monthly budget to save
    /// - Throws: DataServiceError if save fails
    func saveMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws {
        // Validate the budget before saving
        let validation = monthlyBudget.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid monthly budget data")
        }
        
        try SwiftDataStore.shared.saveMonthlyBudget(monthlyBudget)
        finishSwiftDataMigration(for: FileName.monthlyBudget)
    }
    
    /// Update the monthly budget in persistent storage
    /// - Parameter monthlyBudget: The updated monthly budget
    /// - Throws: DataServiceError if update fails
    func updateMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws {
        try await saveMonthlyBudget(monthlyBudget) // Simple overwrite for single budget
    }
    
    /// Delete the monthly budget from persistent storage
    /// - Throws: DataServiceError if delete fails
    func deleteMonthlyBudget() async throws {
        do {
            try SwiftDataStore.shared.deleteMonthlyBudget()
        } catch DataServiceError.notFound where fileExists(FileName.monthlyBudget) {
            // The budget may still exist only in the retired JSON store.
        }
        finishSwiftDataMigration(for: FileName.monthlyBudget)
    }
    
    // MARK: - Settings Operations
    
    /// Load app settings from persistent storage
    /// - Returns: AppSettings object or default if none exists
    /// - Throws: DataServiceError if file cannot be read
    func loadSettings() async throws -> AppSettings {
        await ensureStorageReady()
        do {
            return try await loadFromFile(FileName.settings, type: AppSettings.self)
        } catch DataServiceError.notFound {
            return AppSettings()
        }
    }
    
    /// Save app settings to persistent storage
    /// - Parameter settings: The settings to save
    /// - Throws: DataServiceError if save fails
    func saveSettings(_ settings: AppSettings) async throws {
        // Validate settings consistency
        guard settings.validate() else {
            throw DataServiceError.validationError("Invalid settings configuration")
        }
        
        try await saveToFile(settings, fileName: FileName.settings)
    }
    
    // MARK: - Private Helper Methods
    
    /// Ensures storage directory and default JSON files exist before any read/write.
    private func ensureStorageReady() async {
        guard !isStorageInitialized else { return }
        
        try? FileManager.default.createDirectory(
            at: config.documentsDirectory,
            withIntermediateDirectories: true
        )
        
        if !fileExists(FileName.expenses) {
            try? await saveToFile([Expense](), fileName: FileName.expenses)
        }
        
        if !fileExists(FileName.budgets) {
            try? await saveToFile([Budget](), fileName: FileName.budgets)
        }
        
        if !fileExists(FileName.settings) {
            try? await saveToFile(AppSettings(), fileName: FileName.settings)
        }
        
        if !fileExists(FileName.categories) {
            await createDefaultCategories()
        }
        
        isStorageInitialized = true
    }
    
    private func fileExists(_ fileName: String) -> Bool {
        let fileURL = config.documentsDirectory.appendingPathComponent("\(fileName).json")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    private func hasCompletedSwiftDataMigration(for fileName: String) -> Bool {
        UserDefaults.standard.bool(forKey: MigrationFlag.swiftDataCompleted(for: fileName))
    }

    private func markSwiftDataMigrationCompleted(for fileName: String) {
        UserDefaults.standard.set(true, forKey: MigrationFlag.swiftDataCompleted(for: fileName))
    }

    private func finishSwiftDataMigration(for fileName: String) {
        markSwiftDataMigrationCompleted(for: fileName)
        removeLegacyFileIfNeeded(fileName)
    }

    private func removeLegacyFileIfNeeded(_ fileName: String) {
        let fileURL = config.documentsDirectory.appendingPathComponent("\(fileName).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            ErrorLogger.log(error, context: "removeLegacyFileIfNeeded.\(fileName)")
        }
    }

    private func categoryWithDefaultPresentation(_ category: Category) -> Category {
        guard let definition = DefaultCategoryDefinitions.first(where: {
            $0.name.localizedCaseInsensitiveCompare(category.name) == .orderedSame
        }) else {
            return category
        }

        var updatedCategory = category
        updatedCategory.iconName = category.iconName == "tag.fill" ? definition.iconName : category.iconName
        updatedCategory.colorName = category.colorName == "blue" ? definition.colorName : category.colorName
        updatedCategory.isDefault = true
        return updatedCategory
    }

    private func replacementCategoryID(forDeleting categoryID: UUID) throws -> UUID {
        let categories = try SwiftDataStore.shared.loadCategories()

        if let other = categories.first(where: {
            $0.id != categoryID && $0.name.localizedCaseInsensitiveCompare("Other") == .orderedSame
        }) {
            return other.id
        }

        if let fallback = categories.first(where: { $0.id != categoryID }) {
            return fallback.id
        }

        let uncategorized = Category(
            name: "Uncategorized",
            iconName: "tray.fill",
            colorName: "gray",
            isDefault: false
        )
        try SwiftDataStore.shared.saveCategory(uncategorized)
        return uncategorized.id
    }
    
    /// Load a JSON array, returning an empty array when the file does not exist yet.
    private func loadCollection<T: Codable>(from fileName: String, type: [T].Type) async throws -> [T] {
        do {
            return try await loadFromFile(fileName, type: type)
        } catch DataServiceError.notFound {
            return []
        }
    }
    
    /// Generic file loading method
    /// - Parameters:
    ///   - fileName: Name of the file (without extension)
    ///   - type: The type to decode to
    /// - Returns: Decoded object
    /// - Throws: DataServiceError if file cannot be read or parsed
    private func loadFromFile<T: Codable>(_ fileName: String, type: T.Type) async throws -> T {
        let fileURL = config.documentsDirectory.appendingPathComponent("\(fileName).json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw DataServiceError.notFound("File \(fileName).json not found")
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = Self.makeDecoder()
            let item = try decoder.decode(type, from: data)
            return item
        } catch let error as DecodingError {
            throw DataServiceError.readError("Failed to decode JSON from \(fileName).json: \(error.localizedDescription)")
        } catch {
            throw DataServiceError.readError("Failed to read file \(fileName).json: \(error.localizedDescription)")
        }
    }
    
    /// Generic file saving method with atomic writes and backup
    /// - Parameters:
    ///   - item: The object to save
    ///   - fileName: Name of the file (without extension)
    /// - Throws: DataServiceError if save fails
    private func saveToFile<T: Codable>(_ item: T, fileName: String) async throws {
        let fileURL = config.documentsDirectory.appendingPathComponent("\(fileName).json")
        let tempURL = fileURL.appendingPathExtension("tmp")
        
        do {
            // Create backup if enabled
            if config.enableBackups && FileManager.default.fileExists(atPath: fileURL.path) {
                try await backupManager.createBackup(of: fileName)
            }
            
            let data = try Self.makeEncoder().encode(item)
            try data.write(to: tempURL)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                _ = try FileManager.default.replaceItem(
                    at: fileURL,
                    withItemAt: tempURL,
                    backupItemName: nil,
                    options: [],
                    resultingItemURL: nil
                )
            } else {
                try FileManager.default.moveItem(at: tempURL, to: fileURL)
            }
        } catch {
            // Clean up temp file if it exists
            try? FileManager.default.removeItem(at: tempURL)
            throw DataServiceError.writeError("Failed to save to \(fileName).json: \(error.localizedDescription)")
        }
    }
    
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }
    
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    /// Create default expense categories file
    private func createDefaultCategories() async {
        let defaultCategories = DefaultCategoryDefinitions.map { definition in
            Category(
                name: definition.name,
                iconName: definition.iconName,
                colorName: definition.colorName,
                isDefault: true
            )
        }
        
        do {
            try await saveToFile(defaultCategories, fileName: FileName.categories)
        } catch {
            ErrorLogger.log(error, context: "createDefaultCategories")
        }
    }
}

// MARK: - Backup Manager
@MainActor
private class BackupManager: Sendable {
    private let config: JSONDataService.Configuration
    
    init(configuration: JSONDataService.Configuration) {
        self.config = configuration
    }
    
    /// Create a backup of the specified file
    /// - Parameter fileName: Name of the file to backup
    /// - Throws: DataServiceError if backup fails
    func createBackup(of fileName: String) async throws {
        let fileURL = config.documentsDirectory.appendingPathComponent("\(fileName).json")
        let backupService = ConfigurationService.shared
        let backupURL = backupService.backupURL(for: fileName)
        
        do {
            // Ensure source file exists before trying to copy
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw DataServiceError.backupError("Source file does not exist: \(fileName)")
            }
            
            try FileManager.default.copyItem(at: fileURL, to: backupURL)
        } catch {
            throw DataServiceError.backupError("Failed to create backup for \(fileName): \(error.localizedDescription)")
        }
    }
    
    /// Clean up old backup files
    /// - Parameter fileName: Name of the original file
    func cleanOldBackups(for fileName: String) async {
        let backupService = ConfigurationService.shared
        let backups = backupService.getAllBackups(for: fileName)

        if backups.count > config.maxBackups {
            let backupsToRemove = Array(backups.dropFirst(config.maxBackups))
            for backup in backupsToRemove {
                do {
                    try FileManager.default.removeItem(at: backup)
                } catch {
                    ErrorLogger.log(error, context: "cleanOldBackups.removeBackup")
                }
            }
        }
    }
}
