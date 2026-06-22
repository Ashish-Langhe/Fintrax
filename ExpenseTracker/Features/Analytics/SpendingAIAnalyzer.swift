//
//  SpendingAIAnalyzer.swift
//  Fintrax
//
//  Fintrax documentation: Local, deterministic spending analysis used by analytics and Finny.
//

import SwiftUI
import Foundation

/// Result object produced by Fintrax's local spending analysis engine.
///
/// This is intentionally deterministic and on-device. It does not call an
/// external AI provider; the UI presents these rule-based signals as an
/// AI-style assistant experience.
struct SpendingAIAnalysis: Sendable {
    let headline: String
    let summary: String
    let totalSpend: Decimal
    let averageDailySpend: Decimal
    let savingDay: SpendingDayInsight?
    let peakDay: SpendingDayInsight?
    let topCategory: SpendingCategoryInsight?
    let biggestExpense: Expense?
    let savingsRate: Double?
    let projectedMonthlySpend: Decimal
    let insights: [SpendingAIInsight]
}

/// One recommendation or observation produced by the local spending analysis engine.
struct SpendingAIInsight: Identifiable, Sendable {
    enum Kind: Sendable {
        case category
        case daily
        case saving
        case pattern
        case recommendation
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let value: String
    let detail: String
    let icon: String
    let tint: Color
}

/// Daily spend summary used for saving-day and peak-day insights.
struct SpendingDayInsight: Sendable {
    let date: Date
    let amount: Decimal
}

/// Category concentration summary used to explain where spend is clustered.
struct SpendingCategoryInsight: Sendable {
    let category: Category
    let amount: Decimal
    let percentage: Double
}

/// Local analysis engine for generating AI-style spending behaviour insights.
///
/// The analyzer favors explainable calculations: category concentration,
/// average daily spend, zero/low-spend days, peak days, largest transactions,
/// projected monthly pace, and income-aware savings rate.
enum SpendingAIAnalyzer {
    /// Builds a complete spending analysis for the selected Analytics date range.
    static func analyze(
        expenses: [Expense],
        categories: [Category],
        categoryBreakdown: [(Category, Decimal)],
        income: Decimal,
        dateRange: DateRangeOption
    ) -> SpendingAIAnalysis {
        let calendar = Calendar.current
        let sortedExpenses = expenses.sorted { $0.date < $1.date }
        let totalSpend = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let days = analysisDays(for: sortedExpenses, dateRange: dateRange, calendar: calendar)
        let averageDailySpend = divide(totalSpend, by: max(days.count, 1))
        let dailyTotals = dailySpend(expenses: expenses, calendar: calendar)
        let savingDay = bestSavingDay(from: days, dailyTotals: dailyTotals, calendar: calendar)
        let peakDay = peakSpendingDay(from: dailyTotals)
        let topCategory = categoryBreakdown.first.map { category, amount in
            SpendingCategoryInsight(
                category: category,
                amount: amount,
                percentage: totalSpend > 0 ? double(amount / totalSpend) : 0
            )
        }
        let biggestExpense = expenses.max { $0.amount < $1.amount }
        let savingsRate = income > 0 ? double((income - totalSpend) / income) : nil
        let projectedMonthlySpend = averageDailySpend * Decimal(30)
        let headline = headlineText(topCategory: topCategory, savingsRate: savingsRate)
        let summary = summaryText(
            totalSpend: totalSpend,
            averageDailySpend: averageDailySpend,
            days: days.count,
            dateRange: dateRange
        )

        return SpendingAIAnalysis(
            headline: headline,
            summary: summary,
            totalSpend: totalSpend,
            averageDailySpend: averageDailySpend,
            savingDay: savingDay,
            peakDay: peakDay,
            topCategory: topCategory,
            biggestExpense: biggestExpense,
            savingsRate: savingsRate,
            projectedMonthlySpend: projectedMonthlySpend,
            insights: buildInsights(
                topCategory: topCategory,
                averageDailySpend: averageDailySpend,
                savingDay: savingDay,
                peakDay: peakDay,
                biggestExpense: biggestExpense,
                savingsRate: savingsRate,
                projectedMonthlySpend: projectedMonthlySpend,
                dateRange: dateRange
            )
        )
    }

    /// Produces the date buckets that should be considered for daily averages.
    private static func analysisDays(for expenses: [Expense], dateRange: DateRangeOption, calendar: Calendar) -> [Date] {
        guard let firstExpense = expenses.first?.date, let lastExpense = expenses.last?.date else { return [] }
        let dateRangeBounds = dateRange.getDateRange()
        let start = dateRange == .allTime ? calendar.startOfDay(for: firstExpense) : dateRangeBounds.start
        let end = dateRange == .allTime ? calendar.startOfDay(for: lastExpense) : dateRangeBounds.end
        var days: [Date] = []
        var cursor = calendar.startOfDay(for: start)
        let finalDay = calendar.startOfDay(for: end)

        while cursor <= finalDay {
            days.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }

    /// Groups expenses into start-of-day totals for day-level pattern detection.
    private static func dailySpend(expenses: [Expense], calendar: Calendar) -> [Date: Decimal] {
        Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
            .mapValues { items in
                items.reduce(Decimal.zero) { $0 + $1.amount }
            }
    }

    /// Finds the lowest-spend day, including no-spend days inside the range.
    private static func bestSavingDay(from days: [Date], dailyTotals: [Date: Decimal], calendar: Calendar) -> SpendingDayInsight? {
        days
            .map { SpendingDayInsight(date: $0, amount: dailyTotals[$0] ?? .zero) }
            .min {
                if $0.amount == $1.amount {
                    return $0.date > $1.date
                }
                return $0.amount < $1.amount
            }
    }

    /// Finds the day with the highest total spend.
    private static func peakSpendingDay(from dailyTotals: [Date: Decimal]) -> SpendingDayInsight? {
        dailyTotals
            .map { SpendingDayInsight(date: $0.key, amount: $0.value) }
            .max { $0.amount < $1.amount }
    }

    /// Converts raw metrics into user-facing cards and recommendations.
    private static func buildInsights(
        topCategory: SpendingCategoryInsight?,
        averageDailySpend: Decimal,
        savingDay: SpendingDayInsight?,
        peakDay: SpendingDayInsight?,
        biggestExpense: Expense?,
        savingsRate: Double?,
        projectedMonthlySpend: Decimal,
        dateRange: DateRangeOption
    ) -> [SpendingAIInsight] {
        var insights: [SpendingAIInsight] = []

        if let topCategory {
            insights.append(SpendingAIInsight(
                kind: .category,
                title: "Most Spending",
                value: topCategory.category.name,
                detail: L10n.format("analytics.ai.detail.mostSpending", formatPercent(topCategory.percentage), topCategory.category.name),
                icon: topCategory.category.iconName,
                tint: topCategory.category.displayColor
            ))
        }

        insights.append(SpendingAIInsight(
            kind: .daily,
            title: "Daily Pace",
            value: formatCurrency(averageDailySpend),
            detail: L10n.format("analytics.ai.detail.dailyPace", dateRange.localizedString.lowercased(), formatCurrency(averageDailySpend), formatCurrency(projectedMonthlySpend)),
            icon: "calendar.day.timeline.left",
            tint: AppDesignSystem.Colors.info
        ))

        if let savingDay {
            insights.append(SpendingAIInsight(
                kind: .saving,
                title: "Saving Day",
                value: savingDay.date.formatted(date: .abbreviated, time: .omitted),
                detail: savingDay.amount == .zero ? L10n.string("This was your cleanest day with no recorded spend. Try repeating the same routine once or twice a week.") : L10n.format("analytics.ai.detail.savingDay", formatCurrency(savingDay.amount)),
                icon: "sparkles",
                tint: AppDesignSystem.Colors.success
            ))
        }

        if let peakDay {
            insights.append(SpendingAIInsight(
                kind: .pattern,
                title: "Peak Spend Day",
                value: peakDay.date.formatted(date: .abbreviated, time: .omitted),
                detail: L10n.format("analytics.ai.detail.peakDay", formatCurrency(peakDay.amount)),
                icon: "chart.line.uptrend.xyaxis",
                tint: AppDesignSystem.Colors.warning
            ))
        }

        if let biggestExpense {
            insights.append(SpendingAIInsight(
                kind: .pattern,
                title: "Largest Transaction",
                value: biggestExpense.formattedAmount(),
                detail: L10n.format("analytics.ai.detail.largestTransaction", biggestExpense.title),
                icon: "indianrupeesign.circle.fill",
                tint: AppDesignSystem.Colors.primary
            ))
        }

        insights.append(SpendingAIInsight(
            kind: .recommendation,
            title: "Savings Move",
            value: recommendationValue(savingsRate: savingsRate),
            detail: recommendationDetail(savingsRate: savingsRate, averageDailySpend: averageDailySpend, topCategory: topCategory),
            icon: "lightbulb.max.fill",
            tint: AppDesignSystem.Colors.success
        ))

        return insights
    }

    private static func headlineText(topCategory: SpendingCategoryInsight?, savingsRate: Double?) -> String {
        if let savingsRate, savingsRate < 0 {
            return L10n.string("Spending is running ahead of income")
        }
        if let topCategory, topCategory.percentage >= 0.45 {
            return L10n.format("analytics.ai.headline.categoryDriving", topCategory.category.name)
        }
        return L10n.string("Your spending pattern is ready to optimize")
    }

    private static func summaryText(totalSpend: Decimal, averageDailySpend: Decimal, days: Int, dateRange: DateRangeOption) -> String {
        L10n.format("analytics.ai.summary", dateRange.localizedString.lowercased(), days, formatCurrency(totalSpend), formatCurrency(averageDailySpend))
    }

    private static func recommendationValue(savingsRate: Double?) -> String {
        guard let savingsRate else { return L10n.string("Set a cap") }
        return savingsRate >= 0.2 ? L10n.string("Protect surplus") : L10n.string("Tighten spend")
    }

    private static func recommendationDetail(
        savingsRate: Double?,
        averageDailySpend: Decimal,
        topCategory: SpendingCategoryInsight?
    ) -> String {
        let suggestedDailyCut = averageDailySpend * Decimal(0.10)
        if let savingsRate, savingsRate >= 0.2 {
            return L10n.string("You are keeping a healthy surplus. Move part of it to savings first, then spend from the remainder.")
        }

        if let topCategory {
            return L10n.format("analytics.ai.detail.reduceCategory", topCategory.category.name, formatCurrency(suggestedDailyCut))
        }

        return L10n.format("analytics.ai.detail.softCap", formatCurrency(suggestedDailyCut))
    }

    private static func formatCurrency(_ amount: Decimal) -> String {
        CurrencyFormatter.format(amount)
    }

    private static func formatPercent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func divide(_ amount: Decimal, by divisor: Int) -> Decimal {
        guard divisor > 0 else { return .zero }
        return NSDecimalNumber(decimal: amount)
            .dividing(by: NSDecimalNumber(value: divisor))
            .decimalValue
    }

    private static func double(_ decimal: Decimal) -> Double {
        NSDecimalNumber(decimal: decimal).doubleValue
    }
}
