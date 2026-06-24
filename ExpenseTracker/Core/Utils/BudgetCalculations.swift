//
//  BudgetCalculations.swift
//  Fintrax
//
//  Fintrax documentation: Provides shared calculation and validation helpers for finance workflows.
//

import Foundation

/// Utility functions for budget calculations
struct BudgetCalculations {
    static let incomeBudgetSyncKey = "budget.syncWithMonthlyIncome"
    
    /// Calculate total expenses for the current month
    /// - Parameter expenses: Array of expenses to aggregate
    /// - Returns: Total expenses for current month
    static func calculateCurrentMonthExpenses(_ expenses: [Expense]) -> Decimal {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start,
              let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end else {
            return Decimal(0)
        }
        
        return expenses
            .filter { expense in
                expense.date >= startOfMonth && expense.date < endOfMonth
            }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    static func calculateCurrentMonthIncome(_ incomes: [IncomeRecord]) -> Decimal {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start,
              let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end else {
            return .zero
        }

        return incomes
            .filter { income in
                income.date >= startOfMonth && income.date < endOfMonth
            }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    static func activeMonthlyBudgetAmount(
        manualBudget: MonthlyBudget?,
        incomes: [IncomeRecord],
        isSyncedWithIncome: Bool
    ) -> Decimal? {
        if isSyncedWithIncome {
            let income = calculateCurrentMonthIncome(incomes)
            return income > 0 ? income : nil
        }

        return manualBudget?.amount
    }
    
    /// Calculate total expenses for a specific month
    /// - Parameters:
    ///   - expenses: Array of expenses to aggregate
    ///   - date: Any date within the target month
    /// - Returns: Total expenses for the specified month
    static func calculateExpensesForMonth(_ expenses: [Expense], date: Date) -> Decimal {
        let calendar = Calendar.current
        
        guard let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start,
              let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end else {
            return Decimal(0)
        }
        
        return expenses
            .filter { expense in
                expense.date >= startOfMonth && expense.date < endOfMonth
            }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    /// Calculate remaining budget
    /// - Parameters:
    ///   - monthlyBudget: The monthly budget amount
    ///   - expenses: Array of expenses
    /// - Returns: Remaining budget (can be negative if over budget)
    static func calculateRemainingBudget(_ monthlyBudget: Decimal, expenses: [Expense]) -> Decimal {
        let currentMonthExpenses = calculateCurrentMonthExpenses(expenses)
        return monthlyBudget - currentMonthExpenses
    }
    
    /// Calculate budget usage percentage
    /// - Parameters:
    ///   - monthlyBudget: The monthly budget amount
    ///   - expenses: Array of expenses
    /// - Returns: Usage percentage (0.0 to 1.0+)
    static func calculateBudgetUsagePercentage(_ monthlyBudget: Decimal, expenses: [Expense]) -> Double {
        guard monthlyBudget > 0 else { return 0.0 }
        let currentMonthExpenses = calculateCurrentMonthExpenses(expenses)
        return Double(truncating: (currentMonthExpenses / monthlyBudget) as NSNumber)
    }
    
    /// Get budget status for display purposes
    /// - Parameters:
    ///   - monthlyBudget: The monthly budget amount
    ///   - expenses: Array of expenses
    /// - Returns: BudgetStatus with percentage and type
    static func getBudgetStatus(_ monthlyBudget: Decimal, expenses: [Expense]) -> BudgetStatus {
        let usagePercentage = calculateBudgetUsagePercentage(monthlyBudget, expenses: expenses)
        
        if usagePercentage < 0.8 {
            return .withinLimit(percentage: usagePercentage)
        } else if usagePercentage < 1.0 {
            return .approachingLimit(percentage: usagePercentage)
        } else {
            return .exceededLimit(percentage: usagePercentage)
        }
    }
    
    /// Check if user is over budget
    /// - Parameters:
    ///   - monthlyBudget: The monthly budget amount
    ///   - expenses: Array of expenses
    /// - Returns: Whether expenses exceed the budget
    static func isOverBudget(_ monthlyBudget: Decimal, expenses: [Expense]) -> Bool {
        let currentMonthExpenses = calculateCurrentMonthExpenses(expenses)
        return currentMonthExpenses > monthlyBudget
    }
    
    /// Calculate days remaining in current month
    /// - Returns: Number of days remaining until end of month
    static func daysRemainingInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        guard let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end else {
            return 0
        }
        
        let daysRemaining = calendar.dateComponents([.day], from: now, to: endOfMonth).day ?? 0
        return max(0, daysRemaining)
    }
    
    /// Calculate recommended daily spending to stay within budget
    /// - Parameters:
    ///   - monthlyBudget: The monthly budget amount
    ///   - expenses: Array of expenses
    /// - Returns: Recommended daily spending amount for remainder of month
    static func calculateRecommendedDailySpending(_ monthlyBudget: Decimal, expenses: [Expense]) -> Decimal {
        let currentMonthExpenses = calculateCurrentMonthExpenses(expenses)
        let remainingBudget = monthlyBudget - currentMonthExpenses
        let daysRemaining = daysRemainingInCurrentMonth()
        
        if daysRemaining <= 0 {
            return Decimal(0)
        }
        
        return remainingBudget / Decimal(daysRemaining)
    }
}
