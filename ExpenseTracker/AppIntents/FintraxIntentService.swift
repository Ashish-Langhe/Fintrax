//
//  FintraxIntentService.swift
//  Fintrax
//
//  Fintrax documentation: Provides Siri/App Intent use cases through existing finance services.
//

import Foundation

@MainActor
struct FintraxIntentService {
    private let repository: FinanceDataRepository
    private let categoryService: SmartCategoryService

    init(
        repository: FinanceDataRepository? = nil,
        categoryService: SmartCategoryService = SmartCategoryService()
    ) {
        self.repository = repository ?? .shared
        self.categoryService = categoryService
    }

    func categories() async throws -> [Category] {
        try await repository.loadCategories().sorted { $0.name < $1.name }
    }

    func addExpense(title: String, amount: Double, categoryID: String?, note: String?) async throws -> FintraxExpenseIntentResult {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNote = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let decimalAmount = Decimal(amount)

        guard !cleanTitle.isEmpty, decimalAmount > 0 else {
            throw FintraxIntentError.invalidExpense
        }

        let categories = try await categories()
        guard let category = resolveCategory(for: cleanTitle, categoryID: categoryID, categories: categories) else {
            throw FintraxIntentError.categoryNotFound
        }

        let expense = Expense(
            title: cleanTitle,
            amount: decimalAmount,
            date: Date(),
            categoryID: category.id,
            note: cleanNote
        )

        let validation = expense.validate()
        guard validation.isValid else {
            throw FintraxIntentError.validationFailed(validation.error ?? L10n.string("siri.error.invalidExpense"))
        }

        try await repository.saveExpense(expense)

        return FintraxExpenseIntentResult(
            title: expense.title,
            amount: expense.amount,
            categoryName: category.name
        )
    }

    func addExpense(fromSpokenText spokenText: String) async throws -> FintraxExpenseIntentResult {
        let parsedExpense = try parseSpokenExpense(spokenText)
        return try await addExpense(
            title: parsedExpense.title,
            amount: parsedExpense.amount,
            categoryID: nil,
            note: nil
        )
    }

    func monthlySpend(for categoryID: String) async throws -> FintraxMonthlySpendIntentResult {
        guard let categoryUUID = UUID(uuidString: categoryID) else {
            throw FintraxIntentError.categoryNotFound
        }

        async let expenses = repository.loadExpenses()
        async let categories = repository.loadCategories()
        let loadedCategories = try await categories

        guard let category = loadedCategories.first(where: { $0.id == categoryUUID }) else {
            throw FintraxIntentError.categoryNotFound
        }

        let loadedExpenses = try await expenses
        let monthlyExpenses = DateRangeOption.thisMonth.filterExpenses(loadedExpenses)
            .filter { $0.categoryID == category.id }
        let total = monthlyExpenses.reduce(Decimal.zero) { $0 + $1.amount }

        return FintraxMonthlySpendIntentResult(
            categoryName: category.name,
            amount: total,
            transactionCount: monthlyExpenses.count
        )
    }

    private func resolveCategory(for title: String, categoryID: String?, categories: [Category]) -> Category? {
        if let categoryID,
           let uuid = UUID(uuidString: categoryID),
           let category = categories.first(where: { $0.id == uuid }) {
            return category
        }

        if let suggestion = categoryService.suggestCategory(for: title, categories: categories) {
            return suggestion.category
        }

        return categories.first {
            $0.name.localizedCaseInsensitiveCompare("Other") == .orderedSame
        }
    }

    private func parseSpokenExpense(_ spokenText: String) throws -> (title: String, amount: Double) {
        let cleanText = spokenText
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let match = cleanText.range(
            of: #"(?i)(?:₹|rs\.?|inr|rupees?)?\s*([0-9]+(?:\.[0-9]{1,2})?)"#,
            options: .regularExpression
        ) else {
            throw FintraxIntentError.invalidExpense
        }

        let amountText = String(cleanText[match])
            .replacingOccurrences(of: #"(?i)[₹\s]|rs\.?|inr|rupees?"#, with: "", options: .regularExpression)

        guard let amount = Double(amountText), amount > 0 else {
            throw FintraxIntentError.invalidExpense
        }

        let title = cleanText
            .replacingCharacters(in: match, with: " ")
            .replacingOccurrences(
                of: #"(?i)\b(expense|spent|spend|payment|paid|for|on|of)\b"#,
                with: " ",
                options: .regularExpression
            )
            .split(separator: " ")
            .joined(separator: " ")

        guard !title.isEmpty else {
            throw FintraxIntentError.invalidExpense
        }

        return (title, amount)
    }
}

struct FintraxExpenseIntentResult: Sendable {
    let title: String
    let amount: Decimal
    let categoryName: String
}

struct FintraxMonthlySpendIntentResult: Sendable {
    let categoryName: String
    let amount: Decimal
    let transactionCount: Int
}

enum FintraxIntentError: LocalizedError {
    case invalidExpense
    case categoryNotFound
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidExpense:
            return L10n.string("siri.error.invalidExpense")
        case .categoryNotFound:
            return L10n.string("siri.error.categoryNotFound")
        case .validationFailed(let message):
            return message
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
