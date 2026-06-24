//
//  FintraxAppIntents.swift
//  Fintrax
//
//  Fintrax documentation: Exposes Fintrax actions and categories to Siri, Shortcuts, and Spotlight.
//

import AppIntents
import Foundation

struct FintraxCategoryEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let defaultQuery = FintraxCategoryQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: "Fintrax"
        )
    }
}

struct FintraxCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FintraxCategoryEntity] {
        let categories = try await FintraxIntentService().categories()
        return categories
            .filter { identifiers.contains($0.id.uuidString) }
            .map(FintraxCategoryEntity.init(category:))
    }

    func suggestedEntities() async throws -> [FintraxCategoryEntity] {
        try await FintraxIntentService().categories().map(FintraxCategoryEntity.init(category:))
    }

    func defaultResult() async -> FintraxCategoryEntity? {
        let categories = (try? await FintraxIntentService().categories()) ?? []
        let preferredCategory = categories.first {
            $0.name.localizedCaseInsensitiveCompare("Food") == .orderedSame
        } ?? categories.first

        return preferredCategory.map(FintraxCategoryEntity.init(category:))
    }
}

extension FintraxCategoryEntity {
    init(category: Category) {
        self.id = category.id.uuidString
        self.name = category.name
    }
}

struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "siri.intent.addExpense.title"
    static let description = IntentDescription("siri.intent.addExpense.description")
    static let openAppWhenRun = false
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) for \(\.$amount)")
    }

    @Parameter(title: "siri.parameter.amount")
    var amount: Double

    @Parameter(title: "siri.parameter.expense")
    var title: String

    @Parameter(title: "siri.parameter.category")
    var category: FintraxCategoryEntity?

    @Parameter(title: "siri.parameter.note")
    var note: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = try await FintraxIntentService().addExpense(
            title: title,
            amount: amount,
            categoryID: category?.id,
            note: note
        )

        return .result(dialog: IntentDialog(stringLiteral: L10n.format(
            "siri.dialog.expenseAdded",
            result.title,
            result.categoryName,
            CurrencyFormatter.format(result.amount, maximumFractionDigits: 2, minimumFractionDigits: 0)
        )))
    }
}

struct QuickAddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "siri.intent.quickAddExpense.title"
    static let description = IntentDescription("siri.intent.quickAddExpense.description")
    static let openAppWhenRun = false
    static var parameterSummary: some ParameterSummary {
        Summary("Add expense from \(\.$expenseDetails)")
    }

    @Parameter(title: "siri.parameter.expenseDetails")
    var expenseDetails: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = try await FintraxIntentService().addExpense(fromSpokenText: expenseDetails)

        return .result(dialog: IntentDialog(stringLiteral: L10n.format(
            "siri.dialog.expenseAdded",
            result.title,
            result.categoryName,
            CurrencyFormatter.format(result.amount, maximumFractionDigits: 2, minimumFractionDigits: 0)
        )))
    }
}

struct GetMonthlyExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "siri.intent.monthlySpend.title"
    static let description = IntentDescription("siri.intent.monthlySpend.description")
    static let openAppWhenRun = false
    static var parameterSummary: some ParameterSummary {
        Summary("Check \(\.$category) spending this month")
    }

    @Parameter(title: "siri.parameter.category")
    var category: FintraxCategoryEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = try await FintraxIntentService().monthlySpend(for: category.id)
        if result.transactionCount == 0 {
            return .result(dialog: IntentDialog(stringLiteral: L10n.format(
                "siri.dialog.noMonthlySpend",
                result.categoryName
            )))
        }

        return .result(dialog: IntentDialog(stringLiteral: L10n.format(
            "siri.dialog.monthlySpend",
            CurrencyFormatter.format(result.amount, maximumFractionDigits: 2, minimumFractionDigits: 0),
            result.categoryName,
            result.transactionCount
        )))
    }
}

struct OpenAddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "siri.intent.openAddExpense.title"
    static let description = IntentDescription("siri.intent.openAddExpense.description")
    static let openAppWhenRun = true
    static var parameterSummary: some ParameterSummary {
        Summary("Open add expense")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppIntentNavigationRouter.shared.openAddExpense()
        return .result(dialog: IntentDialog(stringLiteral: L10n.string("siri.dialog.openAddExpense")))
    }
}

struct FintraxAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickAddExpenseIntent(),
            phrases: [
                "\(.applicationName) add expense",
                "\(.applicationName) log expense",
                "\(.applicationName) record spending",
                "Run \(.applicationName) add expense",
                "Start \(.applicationName) expense entry",
                "Tell \(.applicationName) to add expense",
                "Use \(.applicationName) to add expense",
                "Ask \(.applicationName) to log expense",
                "In \(.applicationName), add expense",
                "In \(.applicationName), log expense",
                "Add an expense in \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Add money spent in \(.applicationName)",
                "Add expense to \(.applicationName)"
            ],
            shortTitle: "siri.shortcut.addExpense.shortTitle",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: GetMonthlyExpenseIntent(),
            phrases: [
                "\(.applicationName) monthly spending",
                "\(.applicationName) category spending",
                "Run \(.applicationName) monthly spending",
                "Ask \(.applicationName) for monthly spending",
                "Tell \(.applicationName) to check spending",
                "In \(.applicationName), check monthly spending",
                "Check monthly spending in \(.applicationName)",
                "How much did I spend in \(.applicationName)",
                "How much did I spend on \(\.$category) this month in \(.applicationName)",
                "Check \(\.$category) spending this month in \(.applicationName)",
                "In \(.applicationName), check \(\.$category) spending"
            ],
            shortTitle: "siri.shortcut.monthlySpend.shortTitle",
            systemImageName: "chart.pie.fill"
        )

        AppShortcut(
            intent: OpenAddExpenseIntent(),
            phrases: [
                "\(.applicationName) open add expense",
                "\(.applicationName) create expense",
                "Run \(.applicationName) create expense",
                "Start \(.applicationName) add expense",
                "Tell \(.applicationName) to open add expense",
                "Use \(.applicationName) to create expense",
                "In \(.applicationName), open add expense",
                "Open add expense in \(.applicationName)",
                "Create expense in \(.applicationName)"
            ],
            shortTitle: "siri.shortcut.openAddExpense.shortTitle",
            systemImageName: "square.and.pencil"
        )
    }
}
