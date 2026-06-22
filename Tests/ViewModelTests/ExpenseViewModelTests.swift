//
//  ExpenseViewModelTests.swift
//  Fintrax
//
//  Fintrax documentation: Verifies expense form behavior through protocol-backed repository injection.
//

import XCTest
@testable import ExpenseTracker

@MainActor
final class ExpenseViewModelTests: XCTestCase {
    func testSaveCreatesExpenseThroughInjectedRepository() async {
        let repository = MockExpenseRepository()
        let categoryID = UUID()
        let viewModel = ExpenseViewModel(repository: repository)

        viewModel.updateTitle("Team lunch")
        viewModel.updateAmount(Decimal(450))
        viewModel.updateCategory(categoryID)

        await viewModel.save()

        XCTAssertEqual(repository.savedExpenses.count, 1)
        XCTAssertEqual(repository.savedExpenses.first?.title, "Team lunch")
        XCTAssertEqual(repository.savedExpenses.first?.amount, Decimal(450))
        XCTAssertEqual(repository.savedExpenses.first?.categoryID, categoryID)
    }

    func testSaveUpdatesExistingExpenseThroughInjectedRepository() async {
        let repository = MockExpenseRepository()
        let categoryID = UUID()
        let existingExpense = Expense(
            title: "Fuel",
            amount: Decimal(1200),
            date: Date(),
            categoryID: categoryID
        )
        let viewModel = ExpenseViewModel(repository: repository, expense: existingExpense)

        viewModel.updateTitle("Petrol refill")
        viewModel.updateAmount(Decimal(1500))

        await viewModel.save()

        XCTAssertEqual(repository.updatedExpenses.count, 1)
        XCTAssertEqual(repository.updatedExpenses.first?.id, existingExpense.id)
        XCTAssertEqual(repository.updatedExpenses.first?.title, "Petrol refill")
        XCTAssertEqual(repository.updatedExpenses.first?.amount, Decimal(1500))
    }
}

@MainActor
private final class MockExpenseRepository: ExpenseDataProviding {
    private(set) var savedExpenses: [Expense] = []
    private(set) var updatedExpenses: [Expense] = []
    private var expenses: [Expense] = []

    func loadExpenses() async throws -> [Expense] {
        expenses
    }

    func saveExpense(_ expense: Expense) async throws {
        savedExpenses.append(expense)
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) async throws {
        updatedExpenses.append(expense)
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        } else {
            expenses.append(expense)
        }
    }

    func deleteExpense(id expenseID: UUID) async throws {
        expenses.removeAll { $0.id == expenseID }
    }
}
