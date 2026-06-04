//
//  SwiftDataStore.swift
//  Fintrax
//
//  Fintrax documentation: Implements reusable data, export, budget, category, and configuration services for the app.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataStore: Sendable {
    static let shared = SwiftDataStore()

    private let container: ModelContainer
    private let context: ModelContext

    private init() {
        do {
            container = try ModelContainer(
                for: StoredCategory.self,
                StoredExpense.self,
                StoredMonthlyBudget.self,
                StoredIncomeRecord.self,
                StoredBillReminder.self
            )
            context = ModelContext(container)
        } catch {
            fatalError("Failed to initialize SwiftData store: \(error.localizedDescription)")
        }
    }

    func seedDefaultCategoriesIfNeeded() throws {
        let existing = try loadCategories()
        guard !existing.isEmpty else {
            for definition in DefaultCategoryDefinitions {
                try saveCategory(Category(
                    name: definition.name,
                    iconName: definition.iconName,
                    colorName: definition.colorName,
                    isDefault: true
                ))
            }
            return
        }

        for definition in DefaultCategoryDefinitions {
            if let category = existing.first(where: { $0.name.localizedCaseInsensitiveCompare(definition.name) == .orderedSame }) {
                var updated = category
                updated.iconName = updated.iconName.isEmpty ? definition.iconName : updated.iconName
                updated.colorName = updated.colorName.isEmpty ? definition.colorName : updated.colorName
                updated.isDefault = true
                try updateCategory(updated)
            }
        }
    }

    func loadCategories() throws -> [Category] {
        let descriptor = FetchDescriptor<StoredCategory>()
        return try context.fetch(descriptor)
            .map { $0.category }
            .sorted {
                if $0.isDefault != $1.isDefault {
                    return $0.isDefault && !$1.isDefault
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    func saveCategory(_ category: Category) throws {
        let validation = category.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid category data")
        }

        if try categoryNameExists(category.name) {
            throw DataServiceError.constraintViolation("Category with name '\(category.name)' already exists")
        }

        context.insert(StoredCategory(
            id: category.id,
            name: category.name,
            iconName: category.iconName,
            colorName: category.colorName,
            isDefault: category.isDefault,
            createdAt: category.createdAt,
            updatedAt: category.updatedAt
        ))
        try context.save()
    }

    func upsertCategoryPreservingIdentity(_ category: Category) throws {
        let validation = category.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid category data")
        }

        if let storedCategory = try storedCategory(id: category.id) {
            storedCategory.update(from: category)
            try context.save()
            return
        }

        if let storedCategory = try storedCategory(name: category.name) {
            storedCategory.id = category.id
            storedCategory.update(from: category)
            try context.save()
            return
        }

        try saveCategory(category)
    }

    func updateCategory(_ category: Category) throws {
        let validation = category.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid category data")
        }

        if try categoryNameExists(category.name, excluding: category.id) {
            throw DataServiceError.constraintViolation("Category with name '\(category.name)' already exists")
        }

        guard let storedCategory = try storedCategory(id: category.id) else {
            throw DataServiceError.notFound("Category with ID \(category.id) not found")
        }

        storedCategory.update(from: category)
        try context.save()
    }

    func deleteCategory(id categoryID: UUID, reassignExpensesTo replacementCategoryID: UUID? = nil) throws {
        guard let storedCategory = try storedCategory(id: categoryID) else {
            throw DataServiceError.notFound("Category with ID \(categoryID) not found")
        }

        if storedCategory.isDefault {
            throw DataServiceError.constraintViolation("Default categories cannot be deleted")
        }

        let attachedExpenses = try storedExpenses(categoryID: categoryID)
        if !attachedExpenses.isEmpty, replacementCategoryID == nil {
            throw DataServiceError.constraintViolation("Cannot delete category with associated expenses")
        }

        if let replacementCategoryID {
            for expense in attachedExpenses {
                expense.categoryID = replacementCategoryID
                expense.updatedAt = Date()
            }
        }

        context.delete(storedCategory)
        try context.save()
    }

    func loadExpenses() throws -> [Expense] {
        let descriptor = FetchDescriptor<StoredExpense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try context.fetch(descriptor).map(\.expense)
    }

    func saveExpense(_ expense: Expense) throws {
        let validation = expense.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid expense data")
        }

        if try storedExpense(id: expense.id) != nil {
            throw DataServiceError.constraintViolation("Expense with ID \(expense.id) already exists")
        }

        context.insert(StoredExpense(
            id: expense.id,
            title: expense.title,
            amount: expense.amount,
            date: expense.date,
            categoryID: expense.categoryID,
            note: expense.note,
            createdAt: expense.createdAt,
            updatedAt: expense.updatedAt
        ))
        try context.save()
    }

    func updateExpense(_ expense: Expense) throws {
        let validation = expense.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid expense data")
        }

        guard let storedExpense = try storedExpense(id: expense.id) else {
            throw DataServiceError.notFound("Expense with ID \(expense.id) not found")
        }

        storedExpense.update(from: expense)
        try context.save()
    }

    func deleteExpense(id expenseID: UUID) throws {
        guard let storedExpense = try storedExpense(id: expenseID) else {
            throw DataServiceError.notFound("Expense with ID \(expenseID) not found")
        }

        context.delete(storedExpense)
        try context.save()
    }

    func loadMonthlyBudget() throws -> MonthlyBudget? {
        let descriptor = FetchDescriptor<StoredMonthlyBudget>()
        return try context.fetch(descriptor).first?.monthlyBudget
    }

    func saveMonthlyBudget(_ monthlyBudget: MonthlyBudget) throws {
        let validation = monthlyBudget.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid monthly budget data")
        }

        if let storedBudget = try context.fetch(FetchDescriptor<StoredMonthlyBudget>()).first {
            storedBudget.update(from: monthlyBudget)
        } else {
            context.insert(StoredMonthlyBudget(amount: monthlyBudget.amount, setAt: monthlyBudget.setAt))
        }

        try context.save()
    }

    func deleteMonthlyBudget() throws {
        let storedBudgets = try context.fetch(FetchDescriptor<StoredMonthlyBudget>())
        guard !storedBudgets.isEmpty else {
            throw DataServiceError.notFound("Monthly budget not found")
        }

        for storedBudget in storedBudgets {
            context.delete(storedBudget)
        }
        try context.save()
    }

    func loadIncomeRecords() throws -> [IncomeRecord] {
        let descriptor = FetchDescriptor<StoredIncomeRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.incomeRecord)
    }

    func saveIncomeRecord(_ income: IncomeRecord) throws {
        let validation = income.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid income data")
        }

        if try storedIncomeRecord(id: income.id) != nil {
            throw DataServiceError.constraintViolation("Income record already exists")
        }

        context.insert(StoredIncomeRecord(
            id: income.id,
            title: income.title,
            amount: income.amount,
            date: income.date,
            source: income.source,
            note: income.note,
            createdAt: income.createdAt,
            updatedAt: income.updatedAt
        ))
        try context.save()
    }

    func updateIncomeRecord(_ income: IncomeRecord) throws {
        let validation = income.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid income data")
        }

        guard let storedIncome = try storedIncomeRecord(id: income.id) else {
            throw DataServiceError.notFound("Income record not found")
        }

        storedIncome.update(from: income)
        try context.save()
    }

    func deleteIncomeRecord(id incomeID: UUID) throws {
        guard let storedIncome = try storedIncomeRecord(id: incomeID) else {
            throw DataServiceError.notFound("Income record not found")
        }

        context.delete(storedIncome)
        try context.save()
    }

    func loadBillReminders() throws -> [BillReminder] {
        let descriptor = FetchDescriptor<StoredBillReminder>(
            sortBy: [SortDescriptor(\.dueDate)]
        )
        return try context.fetch(descriptor).map(\.billReminder)
    }

    func saveBillReminder(_ bill: BillReminder) throws {
        let validation = bill.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid bill reminder data")
        }

        if try storedBillReminder(id: bill.id) != nil {
            throw DataServiceError.constraintViolation("Bill reminder already exists")
        }

        context.insert(StoredBillReminder(
            id: bill.id,
            title: bill.title,
            amount: bill.amount,
            dueDate: bill.dueDate,
            note: bill.note,
            isPaid: bill.isPaid,
            reminderEnabled: bill.reminderEnabled,
            reminderTime: bill.reminderTime,
            repeatsUntilPaid: bill.repeatsUntilPaid,
            alertStyleRawValue: bill.alertStyle.rawValue,
            createdAt: bill.createdAt,
            updatedAt: bill.updatedAt
        ))
        try context.save()
    }

    func updateBillReminder(_ bill: BillReminder) throws {
        let validation = bill.validate()
        guard validation.isValid else {
            throw DataServiceError.validationError(validation.error ?? "Invalid bill reminder data")
        }

        guard let storedBill = try storedBillReminder(id: bill.id) else {
            throw DataServiceError.notFound("Bill reminder not found")
        }

        storedBill.update(from: bill)
        try context.save()
    }

    func deleteBillReminder(id billID: UUID) throws {
        guard let storedBill = try storedBillReminder(id: billID) else {
            throw DataServiceError.notFound("Bill reminder not found")
        }

        context.delete(storedBill)
        try context.save()
    }

    private func categoryNameExists(_ name: String, excluding categoryID: UUID? = nil) throws -> Bool {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return try loadCategories().contains { category in
            category.name.lowercased() == normalized && category.id != categoryID
        }
    }

    private func storedCategory(id: UUID) throws -> StoredCategory? {
        var descriptor = FetchDescriptor<StoredCategory>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func storedCategory(name: String) throws -> StoredCategory? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return try context.fetch(FetchDescriptor<StoredCategory>()).first { category in
            category.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    private func storedExpense(id: UUID) throws -> StoredExpense? {
        var descriptor = FetchDescriptor<StoredExpense>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func storedIncomeRecord(id: UUID) throws -> StoredIncomeRecord? {
        var descriptor = FetchDescriptor<StoredIncomeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func storedBillReminder(id: UUID) throws -> StoredBillReminder? {
        var descriptor = FetchDescriptor<StoredBillReminder>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func expenseCount(categoryID: UUID) throws -> Int {
        let descriptor = FetchDescriptor<StoredExpense>(
            predicate: #Predicate { $0.categoryID == categoryID }
        )
        return try context.fetchCount(descriptor)
    }

    private func storedExpenses(categoryID: UUID) throws -> [StoredExpense] {
        let descriptor = FetchDescriptor<StoredExpense>(
            predicate: #Predicate { $0.categoryID == categoryID }
        )
        return try context.fetch(descriptor)
    }
}
