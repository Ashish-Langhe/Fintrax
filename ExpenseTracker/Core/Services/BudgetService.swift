//
//  BudgetService.swift
//  Fintrax
//
//  Fintrax documentation: Implements reusable data, export, budget, category, and configuration services for the app.
//

import Foundation

/// Service for managing category budgets
@MainActor
class BudgetService: ObservableObject, Sendable {
    private let dataService: JSONDataService
    private let categoryService: CategoryService
    
    /// Shared instance for the budget service
    static let shared = BudgetService(dataService: JSONDataService.shared, categoryService: CategoryService.shared)
    
    /// Initialize budget service
    /// - Parameters:
    ///   - dataService: JSON data service instance
    ///   - categoryService: Category service instance
    init(dataService: JSONDataService, categoryService: CategoryService) {
        self.dataService = dataService
        self.categoryService = categoryService
    }
    
    /// Calculate monthly spending for a category
    /// - Parameters:
    ///   - categoryID: ID of the category to calculate
    ///   - expenses: Array of expenses to evaluate
    ///   - date: Date to calculate for (default: current date)
    /// - Returns: Total spending for the month
    func calculateMonthlySpending(for categoryID: UUID, expenses: [Expense], date: Date = Date()) -> Decimal {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let startOfMonth = calendar.date(from: components),
              let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return Decimal(0)
        }
        
        let monthlyExpenses = expenses.filter { expense in
            expense.categoryID == categoryID &&
            expense.date >= startOfMonth &&
            expense.date < startOfNextMonth
        }
        
        return monthlyExpenses.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    /// Get all categories with their budget statuses
    /// - Parameters:
    ///   - categories: Array of categories
    ///   - budgets: Array of budgets
    ///   - expenses: Array of expenses
    /// - Returns: Array of tuples with category and budget status
    func getCategoryBudgetStatuses(_ categories: [Category], _ budgets: [Budget], _ expenses: [Expense]) -> [(Category, BudgetStatus)] {
        let now = Date()
        
        return categories.map { category in
            let budget = budgets.first { $0.categoryID == category.id }
            let monthlySpending = calculateMonthlySpending(for: category.id, expenses: expenses, date: now)
            let status = budget?.calculateStatus(spent: monthlySpending) ?? .withinLimit(percentage: 0.0)
            return (category, status)
        }
    }
    
    /// Get budget warnings for all categories
    /// - Parameters:
    ///   - budgets: Array of budgets
    ///   - expenses: Array of expenses
    /// - Returns: Array of budget warnings
    func getBudgetWarnings(_ budgets: [Budget], _ expenses: [Expense]) -> [BudgetWarning] {
        let now = Date()
        var warnings: [BudgetWarning] = []
        
        for budget in budgets {
            let monthlySpending = calculateMonthlySpending(for: budget.categoryID, expenses: expenses, date: now)
            let status = budget.calculateStatus(spent: monthlySpending)
            
            switch status {
            case .approachingLimit:
                warnings.append(BudgetWarning(
                    categoryID: budget.categoryID,
                    type: .approaching,
                    percentage: status.percentage,
                    message: "Approaching budget limit (\(Int(status.percentage * 100))%)"
                ))
            case .exceededLimit:
                warnings.append(BudgetWarning(
                    categoryID: budget.categoryID,
                    type: .exceeded,
                    percentage: status.percentage,
                    message: "Budget exceeded (\(Int(status.percentage * 100))%)"
                ))
            case .withinLimit:
                // No warning needed
                break
            }
        }
        
        return warnings.sorted { $0.percentage > $1.percentage }
    }
    
    /// Get budget health score (0-100)
    /// - Parameters:
    ///   - budgets: Array of budgets
    ///   - expenses: Array of expenses
    /// - Returns: Health score from 0 (poor) to 100 (excellent)
    func getBudgetHealthScore(_ budgets: [Budget], _ expenses: [Expense]) -> BudgetHealthScore {
        guard !budgets.isEmpty else {
            return BudgetHealthScore(score: 100, message: "No budgets set")
        }
        
        let now = Date()
        var totalScore = 0.0
        let budgetCount = Double(budgets.count)
        
        for budget in budgets {
            let monthlySpending = calculateMonthlySpending(for: budget.categoryID, expenses: expenses, date: now)
            let status = budget.calculateStatus(spent: monthlySpending)
            
            switch status {
            case .withinLimit:
                // Full points for within budget
                totalScore += 100
            case .approachingLimit:
                // Partial points for approaching limit
                totalScore += 100 - (status.percentage - 0.8) * 400 // 80% = 100pt, 100% = 0pt
            case .exceededLimit:
                // For exceeded, penalize based on how much over
                totalScore += max(0, 100 - (status.percentage - 1.0) * 200) // 100% = 100pt, 150% = 0pt
            }
        }
        
        let averageScore = totalScore / budgetCount
        let score = Int(round(averageScore))
        
        let message: String
        switch score {
        case 90...100:
            message = L10n.string("Excellent - All budgets well managed")
        case 70...89:
            message = L10n.string("Good - Most budgets on track")
        case 50...69:
            message = L10n.string("Fair - Some budgets approaching limits")
        case 25...49:
            message = L10n.string("Poor - Multiple budgets exceeded")
        default:
            message = L10n.string("Critical - Many budgets significantly exceeded")
        }
        
        return BudgetHealthScore(score: score, message: message)
    }
    
    /// Get budget progress for the month
    /// - Parameters:
    ///   - budget: Budget to calculate progress for
    ///   - expenses: Array of expenses
    /// - Returns: Budget progress information
    func getBudgetProgress(_ budget: Budget, _ expenses: [Expense]) -> BudgetProgress {
        let now = Date()
        let monthlySpending = calculateMonthlySpending(for: budget.categoryID, expenses: expenses, date: now)
        let remaining = budget.remainingBudget(spent: monthlySpending)
        let percentageRemaining = budget.monthlyLimit > 0 ? 
            Double(truncating: (remaining / budget.monthlyLimit) as NSNumber) * 100 : 0
        
        // Calculate days remaining in month
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components),
              let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return BudgetProgress(
                spent: monthlySpending,
                remaining: remaining,
                percentageSpent: Double(truncating: (monthlySpending / budget.monthlyLimit) as NSNumber) * 100,
                percentageRemaining: percentageRemaining,
                daysInMonth: 30,
                daysPassed: 15,
                dailyAverage: Decimal(0)
            )
        }
        
        let daysInMonth = calendar.dateComponents([.day], from: startOfMonth, to: startOfNextMonth).day ?? 30
        let daysPassed = calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 1
        let remainingDays = daysInMonth - daysPassed
        let dailyAverage = remainingDays > 0 ? remaining / Decimal(remainingDays) : Decimal(0)
        
        return BudgetProgress(
            spent: monthlySpending,
            remaining: remaining,
            percentageSpent: Double(truncating: (monthlySpending / budget.monthlyLimit) as NSNumber) * 100,
            percentageRemaining: percentageRemaining,
            daysInMonth: daysInMonth,
            daysPassed: daysPassed,
            dailyAverage: dailyAverage
        )
    }
    
    /// Get budget recommendations
    /// - Parameters:
    ///   - budgets: Array of budgets
    ///   - expenses: Array of expenses
    ///   - daysUntilMonthEnd: Days until end of current month
    /// - Returns: Array of budget recommendations
    func getBudgetRecommendations(_ budgets: [Budget], _ expenses: [Expense], daysUntilMonthEnd: Int = 30) -> [BudgetRecommendation] {
        let now = Date()
        var recommendations: [BudgetRecommendation] = []
        
        for budget in budgets {
            let monthlySpending = calculateMonthlySpending(for: budget.categoryID, expenses: expenses, date: now)
            let status = budget.calculateStatus(spent: monthlySpending)
            let progress = getBudgetProgress(budget, expenses)
            
            switch status {
            case .exceededLimit:
                recommendations.append(BudgetRecommendation(
                    categoryID: budget.categoryID,
                    type: .reduceSpending,
                    priority: .high,
                    title: L10n.string("Immediate Action Required"),
                    message: L10n.format("budget.recommendation.exceeded", abs(progress.remaining).formattedAmount()),
                    suggestedDailyLimit: progress.dailyAverage
                ))
            case .approachingLimit:
                let dailyLimit = progress.remaining / Decimal(daysUntilMonthEnd + 1)
                recommendations.append(BudgetRecommendation(
                    categoryID: budget.categoryID,
                    type: .limitSpending,
                    priority: .medium,
                    title: L10n.string("Budget Warning"),
                    message: L10n.format("budget.recommendation.limitDaily", dailyLimit.formattedAmount()),
                    suggestedDailyLimit: dailyLimit
                ))
            case .withinLimit:
                // Recommend if on track to exceed
                if daysUntilMonthEnd < 5 && progress.percentageSpent > 70 {
                    let remainingDays = daysUntilMonthEnd + 1
                    let suggestedDailyLimit = progress.remaining / Decimal(remainingDays)
                    recommendations.append(BudgetRecommendation(
                        categoryID: budget.categoryID,
                        type: .monitor,
                        priority: .low,
                        title: L10n.string("Monitor Spending"),
                        message: L10n.format("budget.recommendation.monitor", suggestedDailyLimit.formattedAmount()),
                        suggestedDailyLimit: suggestedDailyLimit
                    ))
                }
            }
        }
        
        return recommendations.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
}

// MARK: - Supporting Types

/// Budget warning type
enum BudgetWarningType {
    case approaching
    case exceeded
}

/// Budget warning for a category
struct BudgetWarning: Identifiable, Sendable {
    let id = UUID()
    let categoryID: UUID
    let type: BudgetWarningType
    let percentage: Double
    let message: String
}

/// Budget health score
struct BudgetHealthScore: Sendable {
    let score: Int
    let message: String
}

/// Budget progress information
struct BudgetProgress: Sendable {
    let spent: Decimal
    let remaining: Decimal
    let percentageSpent: Double
    let percentageRemaining: Double
    let daysInMonth: Int
    let daysPassed: Int
    let dailyAverage: Decimal
}

/// Budget recommendation
struct BudgetRecommendation: Identifiable, Sendable {
    let id = UUID()
    let categoryID: UUID
    let type: RecommendationType
    let priority: Priority
    let title: String
    let message: String
    let suggestedDailyLimit: Decimal
}

/// Budget recommendation type
enum RecommendationType {
    case reduceSpending
    case limitSpending
    case monitor
}

/// Recommendation priority
enum Priority: Sendable {
    case high
    case medium
    case low
    
    var sortOrder: Int {
        switch self {
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}
