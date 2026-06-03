//
//  DashboardData.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

/// Aggregated data model for dashboard visualization
struct DashboardData: Sendable {
    let totalSpending: Decimal
    let categoryBreakdown: [(Category, Decimal)]
    let monthlyTrend: [(String, Decimal)]
    let budgetStatuses: [(Category, BudgetStatus)]
    let recentExpenses: [Expense]
    let dateRange: DateRangeOption
    let totalTransactions: Int
    
    /// Generates dashboard data from expenses, categories, and budgets
    static func generate(
        from expenses: [Expense],
        categories: [Category],
        budgets: [Budget],
        dateRange: DateRangeOption = .allTime
    ) -> DashboardData {
        // Filter expenses by date range
        let filteredExpenses = dateRange.filterExpenses(expenses)
        
        // Calculate total spending
        let totalSpending = filteredExpenses.reduce(Decimal.zero) { sum, expense in
            sum + expense.amount
        }
        
        // Calculate category breakdown
        let categoryBreakdown = calculateCategoryBreakdown(
            expenses: filteredExpenses,
            categories: categories
        )
        
        // Calculate monthly trend
        let monthlyTrend = calculateMonthlyTrend(expenses: expenses)
        
        // Calculate budget statuses
        let budgetStatuses = calculateBudgetStatuses(
            expenses: filteredExpenses,
            categories: categories,
            budgets: budgets
        )
        
        // Get recent expenses (last 5)
        let recentExpenses = Array(filteredExpenses
            .sorted { $0.date > $1.date }
            .prefix(5))
        
        return DashboardData(
            totalSpending: totalSpending,
            categoryBreakdown: categoryBreakdown,
            monthlyTrend: monthlyTrend,
            budgetStatuses: budgetStatuses,
            recentExpenses: recentExpenses,
            dateRange: dateRange,
            totalTransactions: filteredExpenses.count
        )
    }
    
    /// Calculates spending breakdown by category
    private static func calculateCategoryBreakdown(
        expenses: [Expense],
        categories: [Category]
    ) -> [(Category, Decimal)] {
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        let spendingByCategory = Dictionary(grouping: expenses) { $0.categoryID }
            .mapValues { expenses in
                expenses.reduce(Decimal.zero) { sum, expense in
                    sum + expense.amount
                }
            }
        
        return spendingByCategory.compactMap { (categoryID, amount) -> (Category, Decimal)? in
            guard let category = categoryMap[categoryID] else { return nil }
            return (category, amount)
        }
        .sorted { $0.1 > $1.1 } // Sort by amount descending
    }
    
    /// Calculates monthly spending trend
    private static func calculateMonthlyTrend(expenses: [Expense]) -> [(String, Decimal)] {
        guard !expenses.isEmpty else { return [] }

        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: expenses) { expense in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
        }
        
        let monthlySpending = groupedByMonth.mapValues { expenses in
            expenses.reduce(Decimal.zero) { sum, expense in
                sum + expense.amount
            }
        }
        
        let monthKeyFormatter = DateFormatter()
        monthKeyFormatter.dateFormat = "yyyy-MM"

        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM yyyy"

        let latestExpenseDate = expenses.map(\.date).max() ?? Date()
        let latestMonthComponents = calendar.dateComponents([.year, .month], from: latestExpenseDate)
        let latestMonth = calendar.date(from: latestMonthComponents) ?? latestExpenseDate

        return (0..<6)
            .compactMap { offset in
                calendar.date(byAdding: .month, value: -5 + offset, to: latestMonth)
            }
            .map { date in
                let key = monthKeyFormatter.string(from: date)
                return (labelFormatter.string(from: date), monthlySpending[key] ?? .zero)
            }
    }
    
    /// Calculates budget status for each category with a budget
    private static func calculateBudgetStatuses(
        expenses: [Expense],
        categories: [Category],
        budgets: [Budget]
    ) -> [(Category, BudgetStatus)] {
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let spendingByCategory = Dictionary(grouping: expenses) { $0.categoryID }
            .mapValues { expenses in
                expenses.reduce(Decimal.zero) { sum, expense in
                    sum + expense.amount
                }
            }
        
        return budgets.compactMap { budget -> (Category, BudgetStatus)? in
            guard let category = categoryMap[budget.categoryID] else { return nil }
            
            let spent = spendingByCategory[budget.categoryID] ?? Decimal.zero
            let percentage = Double(truncating: (spent / budget.monthlyLimit) as NSNumber)
            
            let status: BudgetStatus
            if percentage >= 1.0 {
                status = .exceededLimit(percentage: percentage)
            } else if percentage >= 0.8 {
                status = .approachingLimit(percentage: percentage)
            } else {
                status = .withinLimit(percentage: percentage)
            }
            
            return (category, status)
        }
        .sorted { lhs, rhs in
            // Sort by percentage descending to show most critical first
           (lhs.1.percentage > rhs.1.percentage)
        }
    }
    
    /// Returns the percentage of total spending for a given category
    func getCategorySpendingPercentage(for category: Category) -> Double {
        guard totalSpending > 0 else { return 0.0 }
        
        if let (_, amount) = categoryBreakdown.first(where: { $0.0.id == category.id }) {
            let result = amount / totalSpending
            return NSDecimalNumber(decimal: result).doubleValue
        }
        return 0.0
    }
    
    /// Returns the top spending category
    var topSpendingCategory: (Category, Decimal)? {
        return categoryBreakdown.first
    }
    
    /// Returns the most critical budget status (highest percentage)
    var mostCriticalBudgetStatus: (Category, BudgetStatus)? {
        return budgetStatuses.first
    }
}
