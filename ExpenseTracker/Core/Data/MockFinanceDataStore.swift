//
//  MockFinanceDataStore.swift
//  Fintrax
//
//  Fintrax documentation: Provides developer-only demo finance data without touching user data.
//

import Foundation

struct MockFinanceSnapshot: Sendable {
    let expenses: [Expense]
    let categories: [Category]
    let budgets: [Budget]
    let monthlyBudget: MonthlyBudget?
    let incomes: [IncomeRecord]
    let bills: [BillReminder]
}

@MainActor
final class MockFinanceDataStore: Sendable {
    static let shared = MockFinanceDataStore()

    private(set) var expenses: [Expense] = []
    private(set) var categories: [Category] = []
    private(set) var budgets: [Budget] = []
    private(set) var monthlyBudget: MonthlyBudget?
    private(set) var incomes: [IncomeRecord] = []
    private(set) var bills: [BillReminder] = []

    private init() {
        reset()
    }

    func reset() {
        let now = Date()
        let calendar = Calendar.current

        categories = [
            Category(id: fixedID("category-food"), name: "Food", iconName: "fork.knife", colorName: "orange", isDefault: true),
            Category(id: fixedID("category-transport"), name: "Transportation", iconName: "car.fill", colorName: "blue", isDefault: true),
            Category(id: fixedID("category-shopping"), name: "Shopping", iconName: "bag.fill", colorName: "pink", isDefault: true),
            Category(id: fixedID("category-utilities"), name: "Utilities", iconName: "bolt.fill", colorName: "yellow", isDefault: true),
            Category(id: fixedID("category-health"), name: "Health", iconName: "heart.fill", colorName: "red", isDefault: true),
            Category(id: fixedID("category-entertainment"), name: "Entertainment", iconName: "tv.fill", colorName: "purple", isDefault: true),
            Category(id: fixedID("category-travel"), name: "Travel", iconName: "airplane", colorName: "cyan", isDefault: false),
            Category(id: fixedID("category-other"), name: "Other", iconName: "ellipsis.circle.fill", colorName: "gray", isDefault: true)
        ]

        monthlyBudget = MonthlyBudget(amount: 85000)

        budgets = [
            Budget(categoryID: categoryID(named: "Food"), monthlyLimit: 22000),
            Budget(categoryID: categoryID(named: "Transportation"), monthlyLimit: 12000),
            Budget(categoryID: categoryID(named: "Shopping"), monthlyLimit: 16000),
            Budget(categoryID: categoryID(named: "Utilities"), monthlyLimit: 9000),
            Budget(categoryID: categoryID(named: "Entertainment"), monthlyLimit: 10000),
            Budget(categoryID: categoryID(named: "Travel"), monthlyLimit: 18000)
        ]

        incomes = [
            IncomeRecord(title: "Salary", amount: 125000, date: date(monthOffset: 0, day: 1, from: now), source: "Employer"),
            IncomeRecord(title: "Freelance App Audit", amount: 24000, date: date(monthOffset: -1, day: 18, from: now), source: "Consulting"),
            IncomeRecord(title: "Salary", amount: 125000, date: date(monthOffset: -1, day: 1, from: now), source: "Employer"),
            IncomeRecord(title: "Tax Refund", amount: 18000, date: date(monthOffset: -2, day: 10, from: now), source: "Refund"),
            IncomeRecord(title: "Salary", amount: 122000, date: date(monthOffset: -2, day: 1, from: now), source: "Employer"),
            IncomeRecord(title: "Salary", amount: 122000, date: date(monthOffset: -3, day: 1, from: now), source: "Employer"),
            IncomeRecord(title: "Freelance Dashboard", amount: 30000, date: date(monthOffset: -4, day: 22, from: now), source: "Consulting"),
            IncomeRecord(title: "Salary", amount: 118000, date: date(monthOffset: -4, day: 1, from: now), source: "Employer")
        ]

        bills = [
            BillReminder(title: "Credit Card Payment", amount: 18400, dueDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now, note: "Demo reminder", isPaid: false, reminderEnabled: true, repeatsUntilPaid: true),
            BillReminder(title: "Rent Transfer", amount: 42000, dueDate: calendar.date(byAdding: .day, value: 6, to: now) ?? now, note: "Monthly rent", isPaid: false, reminderEnabled: true, repeatsUntilPaid: false),
            BillReminder(title: "Internet Bill", amount: 1499, dueDate: calendar.date(byAdding: .day, value: -3, to: now) ?? now, note: "Overdue demo item", isPaid: false, reminderEnabled: true, repeatsUntilPaid: true),
            BillReminder(title: "Insurance Premium", amount: 7200, dueDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now, note: nil, isPaid: false, reminderEnabled: false)
        ]

        expenses = makeExpenses(from: now)
    }

    var snapshot: MockFinanceSnapshot {
        MockFinanceSnapshot(
            expenses: expenses.sorted { $0.date > $1.date },
            categories: categories,
            budgets: budgets,
            monthlyBudget: monthlyBudget,
            incomes: incomes.sorted { $0.date > $1.date },
            bills: bills.sorted { $0.dueDate < $1.dueDate }
        )
    }

    func saveExpense(_ expense: Expense) throws {
        guard !expenses.contains(where: { $0.id == expense.id }) else {
            throw DataServiceError.constraintViolation("Mock expense already exists")
        }
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) throws {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            throw DataServiceError.notFound("Mock expense not found")
        }
        expenses[index] = expense
    }

    func deleteExpense(id: UUID) throws {
        guard expenses.contains(where: { $0.id == id }) else {
            throw DataServiceError.notFound("Mock expense not found")
        }
        expenses.removeAll { $0.id == id }
    }

    func saveCategory(_ category: Category) throws {
        guard !categories.contains(where: { $0.id == category.id || $0.name.localizedCaseInsensitiveCompare(category.name) == .orderedSame }) else {
            throw DataServiceError.constraintViolation("Mock category already exists")
        }
        categories.append(category)
    }

    func updateCategory(_ category: Category) throws {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            throw DataServiceError.notFound("Mock category not found")
        }
        categories[index] = category
    }

    func deleteCategory(id: UUID) throws {
        guard let category = categories.first(where: { $0.id == id }) else {
            throw DataServiceError.notFound("Mock category not found")
        }
        guard !category.isDefault else {
            throw DataServiceError.constraintViolation("Default mock categories cannot be deleted")
        }
        guard !expenses.contains(where: { $0.categoryID == id }) else {
            throw DataServiceError.constraintViolation("Cannot delete mock category with expenses")
        }
        categories.removeAll { $0.id == id }
    }

    func saveMonthlyBudget(_ budget: MonthlyBudget) {
        monthlyBudget = budget
    }

    func deleteMonthlyBudget() {
        monthlyBudget = nil
    }

    func saveIncomeRecord(_ income: IncomeRecord) throws {
        guard !incomes.contains(where: { $0.id == income.id }) else {
            throw DataServiceError.constraintViolation("Mock income already exists")
        }
        incomes.append(income)
    }

    func updateIncomeRecord(_ income: IncomeRecord) throws {
        guard let index = incomes.firstIndex(where: { $0.id == income.id }) else {
            throw DataServiceError.notFound("Mock income not found")
        }
        incomes[index] = income
    }

    func deleteIncomeRecord(id: UUID) throws {
        guard incomes.contains(where: { $0.id == id }) else {
            throw DataServiceError.notFound("Mock income not found")
        }
        incomes.removeAll { $0.id == id }
    }

    func saveBillReminder(_ bill: BillReminder) throws {
        guard !bills.contains(where: { $0.id == bill.id }) else {
            throw DataServiceError.constraintViolation("Mock reminder already exists")
        }
        bills.append(bill)
    }

    func updateBillReminder(_ bill: BillReminder) throws {
        guard let index = bills.firstIndex(where: { $0.id == bill.id }) else {
            throw DataServiceError.notFound("Mock reminder not found")
        }
        bills[index] = bill
    }

    func deleteBillReminder(id: UUID) throws {
        guard bills.contains(where: { $0.id == id }) else {
            throw DataServiceError.notFound("Mock reminder not found")
        }
        bills.removeAll { $0.id == id }
    }

    private func makeExpenses(from now: Date) -> [Expense] {
        let monthlyTemplates: [[(String, Decimal, String, Int)]] = [
            [
                ("Groceries and staples", 6400, "Food", 3),
                ("Metro card recharge", 1800, "Transportation", 5),
                ("Team dinner", 3200, "Food", 8),
                ("Electricity bill", 4100, "Utilities", 12),
                ("Running shoes", 5400, "Shopping", 16),
                ("Movie night", 1600, "Entertainment", 20),
                ("Doctor consultation", 2200, "Health", 23),
                ("Weekend cafe", 1450, "Food", 27)
            ],
            [
                ("Monthly groceries", 7200, "Food", 2),
                ("Cab rides", 3600, "Transportation", 7),
                ("Streaming subscriptions", 1499, "Entertainment", 9),
                ("Pharmacy", 980, "Health", 14),
                ("Home decor", 8200, "Shopping", 18),
                ("Water bill", 1200, "Utilities", 21),
                ("Airport taxi", 2100, "Travel", 25)
            ],
            [
                ("Grocery run", 5800, "Food", 4),
                ("Fuel", 4600, "Transportation", 6),
                ("Weekend trip hotel", 14500, "Travel", 11),
                ("Restaurant", 4200, "Food", 13),
                ("Mobile bill", 999, "Utilities", 17),
                ("Gifts", 6800, "Shopping", 22),
                ("Concert tickets", 5200, "Entertainment", 26)
            ],
            [
                ("Supermarket", 6100, "Food", 1),
                ("Car service", 7800, "Transportation", 8),
                ("Electricity bill", 3900, "Utilities", 10),
                ("Dental cleaning", 3500, "Health", 15),
                ("Clothing", 9400, "Shopping", 19),
                ("Gaming subscription", 799, "Entertainment", 24)
            ],
            [
                ("Groceries", 6900, "Food", 3),
                ("Train tickets", 2400, "Travel", 7),
                ("Fuel", 4300, "Transportation", 9),
                ("Utilities bundle", 5300, "Utilities", 12),
                ("Fitness checkup", 1800, "Health", 18),
                ("Books", 2100, "Shopping", 21),
                ("Dinner with friends", 3800, "Food", 28)
            ]
        ]

        return monthlyTemplates.enumerated().flatMap { monthOffset, items in
            items.enumerated().map { index, item in
                Expense(
                    id: fixedID("expense-\(monthOffset)-\(index)"),
                    title: item.0,
                    amount: item.1,
                    date: date(monthOffset: -monthOffset, day: item.3, from: now),
                    categoryID: categoryID(named: item.2),
                    note: "Mock demo data"
                )
            }
        }
    }

    private func categoryID(named name: String) -> UUID {
        categories.first { $0.name == name }?.id ?? fixedID("category-other")
    }

    private func date(monthOffset: Int, day: Int, from date: Date) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let shifted = calendar.date(byAdding: .month, value: monthOffset, to: date) ?? date
        var components = calendar.dateComponents([.year, .month], from: shifted)
        components.day = min(max(day, 1), 28)
        components.hour = 10 + (day % 8)
        components.minute = (day * 7) % 60
        return calendar.date(from: components) ?? shifted
    }

    private func fixedID(_ seed: String) -> UUID {
        let hash = abs(seed.hashValue)
        let part1 = String(format: "%08X", hash & 0xffffffff)
        let part2 = String(format: "%04X", (hash >> 8) & 0xffff)
        let part3 = String(format: "%04X", (hash >> 16) & 0xffff)
        let part4 = String(format: "%04X", (hash >> 24) & 0xffff)
        let part5 = String(format: "%012X", hash & 0xffffffffffff)
        return UUID(uuidString: "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)") ?? UUID()
    }
}
