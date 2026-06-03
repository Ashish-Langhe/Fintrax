//
//  BudgetViewModel.swift
//  Fintrax
//
//  Fintrax documentation: Builds budget creation, update, progress, and budget insight UI.
//

import Foundation
import Observation
import Combine

/// ViewModel for managing budget data and state
@Observable
final class BudgetViewModel {
    // MARK: - Published Properties
    
    /// Current monthly budget
    private(set) var currentBudget: MonthlyBudget?
    
    /// Loading state for budget operations
    private(set) var loadingState: LoadingState<MonthlyBudget> = .idle
    
    /// Remaining budget calculation
    private(set) var remainingBudget: Decimal = 0
    
    /// Total spent this month
    private(set) var spentThisMonth: Decimal = 0
    
    /// Budget status
    private(set) var budgetStatus: BudgetStatus?
    
    /// Budget usage percentage
    private(set) var budgetUsagePercentage: Double = 0
    
    /// Recommended daily spending
    private(set) var recommendedDailySpending: Decimal?
    
    /// Number of transactions this month
    private(set) var currentMonthTransactions: Int = 0

    /// Average current-month transaction amount
    var averageTransactionAmount: Decimal {
        guard currentMonthTransactions > 0 else { return 0 }
        return spentThisMonth / Decimal(currentMonthTransactions)
    }
    
    // MARK: - Private Properties
    
    private let repository: FinanceDataRepository
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Initialization
    
    @MainActor
    init(repository: FinanceDataRepository? = nil) {
        self.repository = repository ?? .shared
    }
    
    // MARK: - Public Methods
    
    /// Load budget data including current expenses
    @MainActor
    func loadBudgetData() async {
        loadingState = .loading
        
        do {
            // Load budget and expenses
            async let budget = repository.loadMonthlyBudget()
            async let expenses = repository.loadExpenses()
            
            let (budgetData, expensesData) = try await (budget, expenses)
            
            currentBudget = budgetData
            
            // Calculate current month spending
            spentThisMonth = BudgetCalculations.calculateCurrentMonthExpenses(expensesData)
            currentMonthTransactions = BudgetCalculations.getCurrentMonthTransactions(expensesData)
            
            // Calculate budget metrics
            if let budget = budgetData {
                remainingBudget = BudgetCalculations.calculateRemainingBudget(budget.amount, expenses: expensesData)
                budgetStatus = BudgetCalculations.getBudgetStatus(budget.amount, expenses: expensesData)
                budgetUsagePercentage = BudgetCalculations.calculateBudgetUsagePercentage(budget.amount, expenses: expensesData)
                recommendedDailySpending = BudgetCalculations.calculateRecommendedDailySpending(budget.amount, expenses: expensesData)
            } else {
                remainingBudget = 0
                budgetStatus = nil
                budgetUsagePercentage = 0
                recommendedDailySpending = nil
            }
            
            loadingState = .success(budgetData ?? MonthlyBudget(amount: 0))
        } catch {
            loadingState = .failure(error)
        }
    }
    
    /// Set a new monthly budget
    /// - Parameter amount: The budget amount
    /// - Returns: Success message or nil if failed
    @MainActor
    func setBudget(_ amount: Decimal) async -> String? {
        do {
            let newBudget = MonthlyBudget(amount: amount)
            try await repository.saveMonthlyBudget(newBudget)
            currentBudget = newBudget
            
            // Reload data to recalculate everything
            await loadBudgetData()
            return "Budget set successfully"
        } catch {
            loadingState = .failure(error)
            return nil
        }
    }
    
    /// Update existing budget
    /// - Parameter amount: The new budget amount
    /// - Returns: Success message or nil if failed
    @MainActor
    func updateBudget(_ amount: Decimal) async -> String? {
        guard var budget = currentBudget else {
            return await setBudget(amount)
        }
        
        do {
            try budget.updateAmount(amount)
            try await repository.updateMonthlyBudget(budget)
            currentBudget = budget
            
            // Reload data to recalculate everything
            await loadBudgetData()
            return "Budget updated successfully"
        } catch {
            loadingState = .failure(error)
            return nil
        }
    }
    
    /// Delete the monthly budget
    @MainActor
    func deleteBudget() async {
        do {
            try await repository.deleteMonthlyBudget()
            currentBudget = nil
            remainingBudget = 0
            budgetStatus = nil
            budgetUsagePercentage = 0
            recommendedDailySpending = nil
            loadingState = .idle
        } catch {
            loadingState = .failure(error)
        }
    }
    
    /// Formats currency amount for display
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0.00"
    }
    
    // MARK: - Computed Properties
    
    /// Whether a budget is set
    var hasBudget: Bool {
        return currentBudget != nil
    }
    
    /// Whether the budget is exceeded
    var isOverBudget: Bool {
        budgetUsagePercentage >= 1
    }
    
    /// Current loading state
    var isLoading: Bool {
        if case .loading = loadingState { return true }
        return false
    }
    
    /// Current error if any
    var currentError: Error? {
        if case .failure(let error) = loadingState { return error }
        return nil
    }
}

// MARK: - BudgetCalculations Extension

extension BudgetCalculations {
    /// Get number of transactions in current month
    /// - Parameter expenses: Array of expenses
    /// - Returns: Count of transactions in current month
    static func getCurrentMonthTransactions(_ expenses: [Expense]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start,
              let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end else {
            return 0
        }
        
        return expenses.filter { expense in
            expense.date >= startOfMonth && expense.date < endOfMonth
        }.count
    }
}
