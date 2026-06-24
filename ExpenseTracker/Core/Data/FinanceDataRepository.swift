//
//  FinanceDataRepository.swift
//  Fintrax
//
//  Fintrax documentation: Coordinates cross-feature data loading, mutation, and change notifications.
//

import Foundation

/// Aggregates every data source needed to render the dashboard in one call.
///
/// Dashboard screens should prefer this snapshot over loading individual stores
/// because it keeps cross-feature totals, bill badges, and category data aligned.
struct DashboardDataSnapshot: Sendable {
    let expenses: [Expense]
    let categories: [Category]
    let budgets: [Budget]
    let monthlyBudget: MonthlyBudget?
    let incomes: [IncomeRecord]
    let bills: [BillReminder]
}

/// Aggregates the finance data required by export/report generation.
struct ReportDataSnapshot: Sendable {
    let expenses: [Expense]
    let categories: [Category]
    let incomes: [IncomeRecord]
    let bills: [BillReminder]
}

// MARK: - Repository Capabilities

@MainActor
protocol ExpenseDataProviding {
    func loadExpenses() async throws -> [Expense]
    func saveExpense(_ expense: Expense) async throws
    func updateExpense(_ expense: Expense) async throws
    func deleteExpense(id expenseID: UUID) async throws
}

@MainActor
protocol CategoryDataProviding {
    func loadCategories() async throws -> [Category]
    func saveCategory(_ category: Category) async throws
    func updateCategory(_ category: Category) async throws
    func deleteCategory(id categoryID: UUID) async throws
}

@MainActor
protocol BudgetDataProviding {
    func loadMonthlyBudget() async throws -> MonthlyBudget?
    func saveMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws
    func updateMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws
    func deleteMonthlyBudget() async throws
}

@MainActor
protocol IncomeDataProviding {
    func loadIncomeRecords() throws -> [IncomeRecord]
}

@MainActor
protocol DashboardSnapshotProviding {
    func loadDashboardSnapshot() async throws -> DashboardDataSnapshot
    func markBillReminderPaid(id billID: UUID) throws
}

@MainActor
protocol ReportSnapshotProviding {
    func loadReportSnapshot() async throws -> ReportDataSnapshot
}

@MainActor
protocol DeveloperDataModeProviding {
    func setMockDataEnabled(_ enabled: Bool)
    func resetMockData()
}

typealias ExpenseListDataProviding = ExpenseDataProviding & CategoryDataProviding
typealias BudgetOverviewDataProviding = BudgetDataProviding & ExpenseDataProviding & IncomeDataProviding
typealias DashboardDataProviding = DashboardSnapshotProviding & ExpenseDataProviding

/// Main data facade for Fintrax feature screens.
///
/// The app currently uses JSON-backed stores for expenses/categories/budgets and
/// SwiftData for newer finance features such as income and bill reminders. This
/// repository hides that split from screens, posts app-wide change events after
/// mutations, and keeps bill notification/badge state synchronized with data.
@MainActor
final class FinanceDataRepository: DashboardSnapshotProviding,
                                   ExpenseDataProviding,
                                   CategoryDataProviding,
                                   BudgetDataProviding,
                                   IncomeDataProviding,
                                   ReportSnapshotProviding,
                                   DeveloperDataModeProviding,
                                   Sendable {
    static let shared = FinanceDataRepository()

    private let dataService: JSONDataService
    private let store: SwiftDataStore
    private let mockStore: MockFinanceDataStore
    private let eventBus: AppEventBus

    init(
        dataService: JSONDataService? = nil,
        store: SwiftDataStore? = nil,
        mockStore: MockFinanceDataStore? = nil,
        eventBus: AppEventBus? = nil
    ) {
        self.dataService = dataService ?? .shared
        self.store = store ?? .shared
        self.mockStore = mockStore ?? .shared
        self.eventBus = eventBus ?? .shared
    }

    /// Loads the dashboard-facing data set and refreshes the app badge from bills.
    func loadDashboardSnapshot() async throws -> DashboardDataSnapshot {
        if DeveloperDataMode.isMockDataEnabled {
            let snapshot = mockStore.snapshot
            AppBadgeService.updateBillBadgeCount(from: snapshot.bills)
            return DashboardDataSnapshot(
                expenses: snapshot.expenses,
                categories: snapshot.categories,
                budgets: snapshot.budgets,
                monthlyBudget: snapshot.monthlyBudget,
                incomes: snapshot.incomes,
                bills: snapshot.bills
            )
        }

        async let expenses = dataService.loadExpenses()
        async let categories = dataService.loadCategories()
        async let budgets = dataService.loadBudgets()
        async let monthlyBudget = dataService.loadMonthlyBudget()

        let bills = try store.loadBillReminders()
        AppBadgeService.updateBillBadgeCount(from: bills)

        return try await DashboardDataSnapshot(
            expenses: expenses,
            categories: categories,
            budgets: budgets,
            monthlyBudget: monthlyBudget,
            incomes: store.loadIncomeRecords(),
            bills: bills
        )
    }

    /// Loads the report-facing data set and refreshes the app badge from bills.
    func loadReportSnapshot() async throws -> ReportDataSnapshot {
        if DeveloperDataMode.isMockDataEnabled {
            let snapshot = mockStore.snapshot
            AppBadgeService.updateBillBadgeCount(from: snapshot.bills)
            return ReportDataSnapshot(
                expenses: snapshot.expenses,
                categories: snapshot.categories,
                incomes: snapshot.incomes,
                bills: snapshot.bills
            )
        }

        async let expenses = dataService.loadExpenses()
        async let categories = dataService.loadCategories()

        let bills = try store.loadBillReminders()
        AppBadgeService.updateBillBadgeCount(from: bills)

        return try await ReportDataSnapshot(
            expenses: expenses,
            categories: categories,
            incomes: store.loadIncomeRecords(),
            bills: bills
        )
    }

    func loadExpenses() async throws -> [Expense] {
        if DeveloperDataMode.isMockDataEnabled {
            return mockStore.snapshot.expenses
        }
        return try await dataService.loadExpenses()
    }

    func saveExpense(_ expense: Expense) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.saveExpense(expense)
            eventBus.post(.expense)
            return
        }
        try await dataService.saveExpense(expense)
        eventBus.post(.expense)
    }

    func updateExpense(_ expense: Expense) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.updateExpense(expense)
            eventBus.post(.expense)
            return
        }
        try await dataService.updateExpense(expense)
        eventBus.post(.expense)
    }

    func deleteExpense(id expenseID: UUID) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.deleteExpense(id: expenseID)
            eventBus.post(.expense)
            return
        }
        try await dataService.deleteExpense(id: expenseID)
        eventBus.post(.expense)
    }

    func loadCategories() async throws -> [Category] {
        if DeveloperDataMode.isMockDataEnabled {
            return mockStore.snapshot.categories
        }
        return try await dataService.loadCategories()
    }

    func saveCategory(_ category: Category) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.saveCategory(category)
            eventBus.post(.category)
            return
        }
        try await dataService.saveCategory(category)
        eventBus.post(.category)
    }

    func updateCategory(_ category: Category) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.updateCategory(category)
            eventBus.post(.category)
            return
        }
        try await dataService.updateCategory(category)
        eventBus.post(.category)
    }

    func deleteCategory(id categoryID: UUID) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.deleteCategory(id: categoryID)
            eventBus.post(.category)
            eventBus.post(.expense)
            return
        }
        try await dataService.deleteCategory(id: categoryID)
        eventBus.post(.category)
        eventBus.post(.expense)
    }

    func loadMonthlyBudget() async throws -> MonthlyBudget? {
        if DeveloperDataMode.isMockDataEnabled {
            return mockStore.snapshot.monthlyBudget
        }
        return try await dataService.loadMonthlyBudget()
    }

    func saveMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            mockStore.saveMonthlyBudget(monthlyBudget)
            eventBus.post(.budget)
            return
        }
        try await dataService.saveMonthlyBudget(monthlyBudget)
        eventBus.post(.budget)
    }

    func updateMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws {
        if DeveloperDataMode.isMockDataEnabled {
            mockStore.saveMonthlyBudget(monthlyBudget)
            eventBus.post(.budget)
            return
        }
        try await dataService.updateMonthlyBudget(monthlyBudget)
        eventBus.post(.budget)
    }

    func deleteMonthlyBudget() async throws {
        if DeveloperDataMode.isMockDataEnabled {
            mockStore.deleteMonthlyBudget()
            eventBus.post(.budget)
            return
        }
        try await dataService.deleteMonthlyBudget()
        eventBus.post(.budget)
    }

    func loadIncomeRecords() throws -> [IncomeRecord] {
        if DeveloperDataMode.isMockDataEnabled {
            return mockStore.snapshot.incomes
        }
        return try store.loadIncomeRecords()
    }

    func saveIncomeRecord(_ income: IncomeRecord) throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.saveIncomeRecord(income)
            eventBus.post(.income)
            return
        }
        try store.saveIncomeRecord(income)
        eventBus.post(.income)
    }

    func updateIncomeRecord(_ income: IncomeRecord) throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.updateIncomeRecord(income)
            eventBus.post(.income)
            return
        }
        try store.updateIncomeRecord(income)
        eventBus.post(.income)
    }

    func deleteIncomeRecord(id incomeID: UUID) throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.deleteIncomeRecord(id: incomeID)
            eventBus.post(.income)
            return
        }
        try store.deleteIncomeRecord(id: incomeID)
        eventBus.post(.income)
    }

    func loadBillReminders() throws -> [BillReminder] {
        if DeveloperDataMode.isMockDataEnabled {
            let bills = mockStore.snapshot.bills
            AppBadgeService.updateBillBadgeCount(from: bills)
            return bills
        }
        let bills = try store.loadBillReminders()
        AppBadgeService.updateBillBadgeCount(from: bills)
        return bills
    }

    func saveBillReminder(_ bill: BillReminder) throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.saveBillReminder(bill)
            eventBus.post(.billReminder)
            return
        }
        try store.saveBillReminder(bill)
        refreshBillNotificationState()
        eventBus.post(.billReminder)
    }

    func updateBillReminder(_ bill: BillReminder) throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.updateBillReminder(bill)
            eventBus.post(.billReminder)
            return
        }
        try store.updateBillReminder(bill)
        refreshBillNotificationState()
        eventBus.post(.billReminder)
    }

    func deleteBillReminder(id billID: UUID) throws {
        if DeveloperDataMode.isMockDataEnabled {
            try mockStore.deleteBillReminder(id: billID)
            eventBus.post(.billReminder)
            return
        }
        BillNotificationScheduler.cancelReminder(for: billID)
        try store.deleteBillReminder(id: billID)
        refreshBillNotificationState()
        eventBus.post(.billReminder)
    }

    /// Marks a reminder complete using repository update flow so notifications,
    /// badges, and event subscribers stay in sync.
    func markBillReminderPaid(id billID: UUID) throws {
        if DeveloperDataMode.isMockDataEnabled {
            guard var bill = mockStore.snapshot.bills.first(where: { $0.id == billID }) else {
                throw DataServiceError.notFound("Mock bill reminder not found")
            }
            bill.isPaid = true
            bill.updatedAt = Date()
            try mockStore.updateBillReminder(bill)
            eventBus.post(.billReminder)
            return
        }
        guard var bill = try store.loadBillReminders().first(where: { $0.id == billID }) else {
            throw DataServiceError.notFound("Bill reminder not found")
        }
        bill.isPaid = true
        bill.updatedAt = Date()
        try updateBillReminder(bill)
    }

    /// Rebuilds local notification requests and the app badge after bill changes.
    ///
    /// The scheduler cancels stale requests per bill before re-adding current
    /// ones, so this method can safely run after save, update, delete, or paid
    /// state changes.
    private func refreshBillNotificationState() {
        do {
            let bills = try store.loadBillReminders()
            let badgeCount = AppBadgeService.actionableBillCount(from: bills)
            AppBadgeService.setBadgeCount(badgeCount)

            for bill in bills {
                Task {
                    await BillNotificationScheduler.scheduleReminder(for: bill, badgeCount: badgeCount)
                }
            }
        } catch {
            ErrorLogger.log(error, context: "FinanceDataRepository.refreshBillNotificationState")
        }
    }

    func setMockDataEnabled(_ enabled: Bool) {
        DeveloperDataMode.isMockDataEnabled = enabled
        AppBadgeService.updateBillBadgeCount(from: enabled ? mockStore.snapshot.bills : (try? store.loadBillReminders()) ?? [])
        postAllDataChanged()
    }

    func resetMockData() {
        mockStore.reset()
        guard DeveloperDataMode.isMockDataEnabled else { return }
        postAllDataChanged()
    }

    private func postAllDataChanged() {
        AppDataChange.allCases.forEach { eventBus.post($0) }
    }
}
