//
//  BudgetViewModelTests.swift
//  Fintrax
//
//  Verifies budget overview behavior with manual and income-synced limits.
//

import XCTest
@testable import ExpenseTracker

@MainActor
final class BudgetViewModelTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        userDefaultsSuiteName = "BudgetViewModelTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
        userDefaultsSuiteName = nil
        super.tearDown()
    }

    func testIncomeSyncUsesCurrentMonthIncomeAsActiveBudget() async {
        let repository = MockBudgetOverviewRepository(
            monthlyBudget: MonthlyBudget(amount: 50_000),
            expenses: [Expense(title: "Groceries", amount: 30_000, date: Date(), categoryID: UUID())],
            incomes: [IncomeRecord(title: "Salary", amount: 120_000, date: Date(), source: "Employer")]
        )
        let viewModel = BudgetViewModel(repository: repository, userDefaults: userDefaults)

        await viewModel.loadBudgetData()

        XCTAssertEqual(viewModel.activeBudgetAmount, 50_000)
        XCTAssertEqual(viewModel.remainingBudget, 20_000)

        await viewModel.setIncomeBudgetSyncEnabled(true)

        XCTAssertTrue(viewModel.isBudgetSyncedWithIncome)
        XCTAssertEqual(viewModel.incomeThisMonth, 120_000)
        XCTAssertEqual(viewModel.activeBudgetAmount, 120_000)
        XCTAssertEqual(viewModel.remainingBudget, 90_000)
    }

    func testDisablingIncomeSyncReturnsToManualBudget() async {
        let repository = MockBudgetOverviewRepository(
            monthlyBudget: MonthlyBudget(amount: 45_000),
            expenses: [Expense(title: "Fuel", amount: 10_000, date: Date(), categoryID: UUID())],
            incomes: [IncomeRecord(title: "Salary", amount: 90_000, date: Date(), source: "Employer")]
        )
        let viewModel = BudgetViewModel(repository: repository, userDefaults: userDefaults)

        await viewModel.setIncomeBudgetSyncEnabled(true)
        XCTAssertEqual(viewModel.activeBudgetAmount, 90_000)

        await viewModel.setIncomeBudgetSyncEnabled(false)

        XCTAssertFalse(viewModel.isBudgetSyncedWithIncome)
        XCTAssertEqual(viewModel.activeBudgetAmount, 45_000)
        XCTAssertEqual(viewModel.remainingBudget, 35_000)
    }

    func testDashboardUsesIncomeSyncedBudgetWhenEnabled() async {
        userDefaults.set(true, forKey: BudgetCalculations.incomeBudgetSyncKey)
        let categoryID = UUID()
        let category = Category(id: categoryID, name: "Food", iconName: "fork.knife", colorName: "blue")
        let repository = MockDashboardRepository(
            snapshot: DashboardDataSnapshot(
                expenses: [Expense(title: "Dinner", amount: 20_000, date: Date(), categoryID: categoryID)],
                categories: [category],
                budgets: [],
                monthlyBudget: MonthlyBudget(amount: 50_000),
                incomes: [IncomeRecord(title: "Salary", amount: 100_000, date: Date(), source: "Employer")],
                bills: []
            )
        )
        let viewModel = DashboardViewModel(
            repository: repository,
            eventBus: AppEventBus(),
            userDefaults: userDefaults
        )

        await viewModel.loadDashboardData()

        XCTAssertTrue(viewModel.hasMonthlyBudget)
        XCTAssertEqual(viewModel.activeMonthlyBudgetAmount, 100_000)
        XCTAssertEqual(viewModel.remainingBudget, 80_000)
        XCTAssertFalse(viewModel.isOverBudget)
    }
}

@MainActor
private final class MockBudgetOverviewRepository: BudgetOverviewDataProviding {
    private var monthlyBudget: MonthlyBudget?
    private var expenses: [Expense]
    private var incomes: [IncomeRecord]

    init(monthlyBudget: MonthlyBudget?, expenses: [Expense], incomes: [IncomeRecord]) {
        self.monthlyBudget = monthlyBudget
        self.expenses = expenses
        self.incomes = incomes
    }

    func loadMonthlyBudget() async throws -> MonthlyBudget? {
        monthlyBudget
    }

    func saveMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws {
        self.monthlyBudget = monthlyBudget
    }

    func updateMonthlyBudget(_ monthlyBudget: MonthlyBudget) async throws {
        self.monthlyBudget = monthlyBudget
    }

    func deleteMonthlyBudget() async throws {
        monthlyBudget = nil
    }

    func loadExpenses() async throws -> [Expense] {
        expenses
    }

    func saveExpense(_ expense: Expense) async throws {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) async throws {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
    }

    func deleteExpense(id expenseID: UUID) async throws {
        expenses.removeAll { $0.id == expenseID }
    }

    func loadIncomeRecords() throws -> [IncomeRecord] {
        incomes
    }
}

@MainActor
private final class MockDashboardRepository: DashboardDataProviding {
    let snapshot: DashboardDataSnapshot

    init(snapshot: DashboardDataSnapshot) {
        self.snapshot = snapshot
    }

    func loadDashboardSnapshot() async throws -> DashboardDataSnapshot {
        snapshot
    }

    func markBillReminderPaid(id billID: UUID) throws {}

    func loadExpenses() async throws -> [Expense] {
        snapshot.expenses
    }

    func saveExpense(_ expense: Expense) async throws {}

    func updateExpense(_ expense: Expense) async throws {}

    func deleteExpense(id expenseID: UUID) async throws {}
}
