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

    /// Smart guidance generated from current budget pace
    private(set) var budgetIntelligenceInsights: [BudgetIntelligenceInsight] = []

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
                budgetIntelligenceInsights = Self.makeBudgetIntelligenceInsights(
                    budgetAmount: budget.amount,
                    spentThisMonth: spentThisMonth,
                    transactionCount: currentMonthTransactions
                )
            } else {
                remainingBudget = 0
                budgetStatus = nil
                budgetUsagePercentage = 0
                recommendedDailySpending = nil
                budgetIntelligenceInsights = []
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
            budgetIntelligenceInsights = []
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

    private static func makeBudgetIntelligenceInsights(
        budgetAmount: Decimal,
        spentThisMonth: Decimal,
        transactionCount: Int,
        calendar: Calendar = .current,
        date: Date = Date()
    ) -> [BudgetIntelligenceInsight] {
        guard budgetAmount > 0,
              let monthRange = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }

        let day = calendar.component(.day, from: date)
        let totalDays = monthRange.count
        let daysElapsed = max(day, 1)
        let daysRemaining = max(totalDays - day, 0)
        let usage = NSDecimalNumber(decimal: spentThisMonth / budgetAmount).doubleValue
        let expectedUsage = Double(daysElapsed) / Double(max(totalDays, 1))
        let remaining = budgetAmount - spentThisMonth
        let currentDailySpend = spentThisMonth / Decimal(daysElapsed)
        let projectedMonthSpend = currentDailySpend * Decimal(totalDays)
        let safeDailySpend = daysRemaining > 0 ? max(remaining, .zero) / Decimal(daysRemaining) : .zero
        let dailyReduction = max(currentDailySpend - safeDailySpend, .zero)

        var insights: [BudgetIntelligenceInsight] = [
            BudgetIntelligenceInsight(
                title: "Budget used",
                message: "\(Int((usage * 100).rounded()))% used with \(daysRemaining) days left this month.",
                icon: usage >= 1 ? "exclamationmark.triangle.fill" : "gauge.with.dots.needle.67percent",
                tone: usage >= 1 ? .critical : usage >= 0.8 ? .warning : .positive
            )
        ]

        if projectedMonthSpend > budgetAmount {
            insights.append(
                BudgetIntelligenceInsight(
                    title: "Spending pace",
                    message: "At this pace, month-end spend may reach \(CurrencyFormatter.format(projectedMonthSpend)).",
                    icon: "speedometer",
                    tone: .warning
                )
            )

            if dailyReduction > 0, daysRemaining > 0 {
                insights.append(
                    BudgetIntelligenceInsight(
                        title: "Daily adjustment",
                        message: "Reduce daily spend by about \(CurrencyFormatter.format(dailyReduction)) to stay within budget.",
                        icon: "arrow.down.forward.circle.fill",
                        tone: .action
                    )
                )
            }
        } else if usage < expectedUsage {
            insights.append(
                BudgetIntelligenceInsight(
                    title: "Healthy pace",
                    message: "You are spending slower than the calendar pace for this month.",
                    icon: "checkmark.seal.fill",
                    tone: .positive
                )
            )
        } else {
            insights.append(
                BudgetIntelligenceInsight(
                    title: "Watch pace",
                    message: "Spending is slightly ahead of the calendar pace. Keep daily spend near \(CurrencyFormatter.format(safeDailySpend)).",
                    icon: "calendar.badge.clock",
                    tone: .warning
                )
            )
        }

        if transactionCount > 0 {
            insights.append(
                BudgetIntelligenceInsight(
                    title: "Transaction rhythm",
                    message: "\(transactionCount) entries this month, averaging \(CurrencyFormatter.format(currentDailySpend)) per day.",
                    icon: "list.bullet.rectangle.fill",
                    tone: .neutral
                )
            )
        }

        return insights
    }
}

struct BudgetIntelligenceInsight: Identifiable, Hashable {
    enum Tone: Hashable {
        case positive
        case warning
        case critical
        case action
        case neutral
    }

    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let tone: Tone
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
