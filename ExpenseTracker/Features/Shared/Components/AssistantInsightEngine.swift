//
//  AssistantInsightEngine.swift
//  Fintrax
//

import SwiftUI

struct AssistantPrompt: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let tint: Color
    let preview: String

    static let samples: [AssistantPrompt] = [
        AssistantPrompt(
            id: "highest-day",
            title: "Highest spend day",
            icon: "calendar.badge.exclamationmark",
            tint: AppDesignSystem.Colors.warning,
            preview: "Find the date where your spending peaked this month."
        ),
        AssistantPrompt(
            id: "saving-day",
            title: "Best saving day",
            icon: "leaf.fill",
            tint: AppDesignSystem.Colors.success,
            preview: "Highlight the calmest spending day this month."
        ),
        AssistantPrompt(
            id: "food-month",
            title: "Food this month",
            icon: "fork.knife",
            tint: AppDesignSystem.Colors.primary,
            preview: "Explain food spending and its share of this month."
        ),
        AssistantPrompt(
            id: "budget-risk",
            title: "Budget risk",
            icon: "target",
            tint: AppDesignSystem.Colors.info,
            preview: "Compare spending pace against your monthly budget."
        ),
        AssistantPrompt(
            id: "cash-flow",
            title: "Income vs spend",
            icon: "arrow.left.arrow.right.circle.fill",
            tint: AppDesignSystem.Colors.success,
            preview: "Show this month's income, spend, and net balance."
        ),
        AssistantPrompt(
            id: "frequent-spend",
            title: "Frequent spends",
            icon: "repeat.circle.fill",
            tint: AppDesignSystem.Colors.warning,
            preview: "Spot repeated expense titles and habits."
        )
    ]
}

struct AssistantInsight: Identifiable {
    let id = UUID()
    let promptID: String
    let title: String
    let value: String
    let message: String
    let action: String
    let icon: String
    let tint: Color
    let detailRows: [AssistantInsightRow]
}

struct AssistantInsightRow: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
}

enum AssistantInsightEngine {
    static func makeInsights(from snapshot: DashboardDataSnapshot, now: Date = Date(), calendar: Calendar = .current) -> [AssistantInsight] {
        guard let currentMonth = calendar.dateInterval(of: .month, for: now) else {
            return [emptyInsight(message: L10n.string("I could not identify the current month range."))]
        }

        let expenses = snapshot.expenses.filter { currentMonth.contains($0.date) }
        let incomes = snapshot.incomes.filter { currentMonth.contains($0.date) }
        let categoryMap = Dictionary(uniqueKeysWithValues: snapshot.categories.map { ($0.id, $0) })
        let totalSpend = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let totalIncome = incomes.reduce(Decimal.zero) { $0 + $1.amount }

        guard !expenses.isEmpty || !incomes.isEmpty else {
            return [emptyInsight(message: L10n.string("Add a few expenses or switch to demo data, and I can start answering money questions."))]
        }

        return [
            highestSpendDayInsight(expenses: expenses, totalSpend: totalSpend, calendar: calendar),
            bestSavingDayInsight(expenses: expenses, calendar: calendar),
            foodInsight(expenses: expenses, totalSpend: totalSpend, categoryMap: categoryMap),
            budgetRiskInsight(
                expenses: expenses,
                activeBudgetAmount: snapshot.activeMonthlyBudgetAmount(),
                isSyncedWithIncome: UserDefaults.standard.bool(forKey: BudgetCalculations.incomeBudgetSyncKey),
                now: now,
                calendar: calendar
            ),
            cashFlowInsight(totalIncome: totalIncome, totalSpend: totalSpend, incomes: incomes, expenses: expenses),
            frequentSpendInsight(expenses: expenses, categoryMap: categoryMap)
        ]
    }

    private static func highestSpendDayInsight(expenses: [Expense], totalSpend: Decimal, calendar: Calendar) -> AssistantInsight {
        let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        let best = grouped
            .map { (date: $0.key, amount: $0.value.reduce(Decimal.zero) { $0 + $1.amount }, count: $0.value.count) }
            .max { $0.amount < $1.amount }

        guard let best else {
            return emptyInsight(promptID: "highest-day", message: L10n.string("No expenses found for this month yet."))
        }

        let share = totalSpend > 0 ? NSDecimalNumber(decimal: best.amount / totalSpend).doubleValue : 0
        return AssistantInsight(
            promptID: "highest-day",
            title: "Highest spend day",
            value: best.date.formatted(date: .abbreviated, time: .omitted),
            message: L10n.format("assistant.insight.highestDay.message", CurrencyFormatter.format(best.amount), best.count, Int((share * 100).rounded())),
            action: L10n.string("Open expenses for this date before month-end review; one unusually heavy day often explains the whole trend."),
            icon: "calendar.badge.exclamationmark",
            tint: AppDesignSystem.Colors.warning,
            detailRows: [
                AssistantInsightRow(icon: "indianrupeesign.circle.fill", title: "Day total", value: CurrencyFormatter.format(best.amount)),
                AssistantInsightRow(icon: "list.bullet", title: "Entries", value: "\(best.count)")
            ]
        )
    }

    private static func bestSavingDayInsight(expenses: [Expense], calendar: Calendar) -> AssistantInsight {
        let today = calendar.startOfDay(for: Date())
        guard let month = calendar.dateInterval(of: .month, for: today) else {
            return emptyInsight(promptID: "saving-day", message: L10n.string("No expense days found for this month yet."))
        }

        let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        let elapsedDays = dates(from: month.start, through: today, calendar: calendar)
        let dailyTotals = elapsedDays.map { date in
            let dayExpenses = grouped[date] ?? []
            return (
                date: date,
                amount: dayExpenses.reduce(Decimal.zero) { $0 + $1.amount },
                count: dayExpenses.count
            )
        }

        guard let lowest = dailyTotals.min(by: {
            if $0.amount != $1.amount {
                return $0.amount < $1.amount
            }
            return $0.date > $1.date
        }) else {
            return emptyInsight(promptID: "saving-day", message: L10n.string("No expense days found for this month yet."))
        }

        return AssistantInsight(
            promptID: "saving-day",
            title: "Best saving day",
            value: lowest.date.formatted(date: .abbreviated, time: .omitted),
            message: L10n.format("assistant.insight.savingDay.message", CurrencyFormatter.format(lowest.amount), lowest.count),
            action: L10n.string("Notice what was different on that day. Repeating that routine is usually easier than only cutting big purchases."),
            icon: "leaf.fill",
            tint: AppDesignSystem.Colors.success,
            detailRows: [
                AssistantInsightRow(icon: "indianrupeesign.circle.fill", title: "Lowest day total", value: CurrencyFormatter.format(lowest.amount)),
                AssistantInsightRow(icon: "calendar", title: "Tracked days", value: "\(dailyTotals.count)")
            ]
        )
    }

    private static func foodInsight(expenses: [Expense], totalSpend: Decimal, categoryMap: [UUID: Category]) -> AssistantInsight {
        let foodExpenses = expenses.filter { expense in
            guard let category = categoryMap[expense.categoryID] else { return false }
            return category.name.localizedCaseInsensitiveContains("food")
        }
        let amount = foodExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        let share = totalSpend > 0 ? NSDecimalNumber(decimal: amount / totalSpend).doubleValue : 0
        let average = foodExpenses.isEmpty ? Decimal.zero : amount / Decimal(foodExpenses.count)

        return AssistantInsight(
            promptID: "food-month",
            title: "Food this month",
            value: CurrencyFormatter.format(amount),
            message: foodExpenses.isEmpty
                ? L10n.string("I did not find Food category expenses this month.")
                : L10n.format("assistant.insight.food.message", Int((share * 100).rounded()), foodExpenses.count),
            action: foodExpenses.isEmpty
                ? L10n.string("If food items are going into Other, update those categories and I will read the pattern correctly.")
                : L10n.format("assistant.insight.food.action", CurrencyFormatter.format((amount / Decimal(max(1, Calendar.current.component(.day, from: Date())))) * 7)),
            icon: "fork.knife",
            tint: AppDesignSystem.Colors.primary,
            detailRows: [
                AssistantInsightRow(icon: "percent", title: "Share of spend", value: "\(Int((share * 100).rounded()))%"),
                AssistantInsightRow(icon: "chart.bar.fill", title: "Avg entry", value: CurrencyFormatter.format(average))
            ]
        )
    }

    private static func budgetRiskInsight(
        expenses: [Expense],
        activeBudgetAmount: Decimal?,
        isSyncedWithIncome: Bool,
        now: Date,
        calendar: Calendar
    ) -> AssistantInsight {
        guard let activeBudgetAmount else {
            return AssistantInsight(
                promptID: "budget-risk",
                title: "Budget risk",
                value: isSyncedWithIncome ? L10n.string("Income not recorded") : L10n.string("Budget not set"),
                message: isSyncedWithIncome
                    ? L10n.string("I can analyze budget pace once income is recorded for this month.")
                    : L10n.string("I can analyze budget pace once a monthly budget is configured."),
                action: isSyncedWithIncome
                    ? L10n.string("Add income this month so synced budget can use your available money.")
                    : L10n.string("Set a monthly budget to unlock risk, safe daily spend, and month-end projection."),
                icon: "target",
                tint: AppDesignSystem.Colors.warning,
                detailRows: []
            )
        }

        let spent = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let usage = activeBudgetAmount > 0 ? NSDecimalNumber(decimal: spent / activeBudgetAmount).doubleValue : 0
        let range = calendar.range(of: .day, in: .month, for: now)
        let day = max(calendar.component(.day, from: now), 1)
        let totalDays = max(range?.count ?? day, day)
        let daysLeft = max(totalDays - day, 0)
        let currentDaily = spent / Decimal(day)
        let projected = currentDaily * Decimal(totalDays)
        let remaining = activeBudgetAmount - spent
        let safeDaily = daysLeft > 0 ? max(remaining, .zero) / Decimal(daysLeft) : .zero
        let tint: Color = usage >= 1 ? AppDesignSystem.Colors.error : usage >= 0.8 ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.info

        return AssistantInsight(
            promptID: "budget-risk",
            title: "Budget risk",
            value: L10n.format("assistant.insight.budget.value", Int((usage * 100).rounded())),
            message: L10n.format("assistant.insight.budget.message", daysLeft, CurrencyFormatter.format(projected)),
            action: usage >= 1
                ? L10n.string("Pause non-essential spends first; you are already beyond the planned monthly limit.")
                : L10n.format("assistant.insight.budget.action", CurrencyFormatter.format(safeDaily)),
            icon: usage >= 1 ? "exclamationmark.triangle.fill" : "target",
            tint: tint,
            detailRows: [
                AssistantInsightRow(icon: "wallet.pass.fill", title: isSyncedWithIncome ? "Available money" : "Budget", value: CurrencyFormatter.format(activeBudgetAmount)),
                AssistantInsightRow(icon: "arrow.down.forward.circle.fill", title: "Safe daily", value: CurrencyFormatter.format(safeDaily))
            ]
        )
    }

    private static func cashFlowInsight(totalIncome: Decimal, totalSpend: Decimal, incomes: [IncomeRecord], expenses: [Expense]) -> AssistantInsight {
        let net = totalIncome - totalSpend
        let positive = net >= 0

        return AssistantInsight(
            promptID: "cash-flow",
            title: "Income vs spend",
            value: CurrencyFormatter.format(net),
            message: positive
                ? L10n.string("You are currently cash-flow positive this month.")
                : L10n.string("Spending is ahead of recorded income this month."),
            action: positive
                ? L10n.string("Protect this surplus by moving a fixed amount into savings before discretionary spending.")
                : L10n.string("Check whether income is missing first; if not, reduce the top two flexible categories."),
            icon: positive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
            tint: positive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error,
            detailRows: [
                AssistantInsightRow(icon: "plus.circle.fill", title: "Income", value: CurrencyFormatter.format(totalIncome)),
                AssistantInsightRow(icon: "minus.circle.fill", title: "Spend", value: CurrencyFormatter.format(totalSpend)),
                AssistantInsightRow(icon: "number", title: "Records", value: L10n.format("assistant.insight.cashFlow.records", incomes.count, expenses.count))
            ]
        )
    }

    private static func frequentSpendInsight(expenses: [Expense], categoryMap: [UUID: Category]) -> AssistantInsight {
        let normalized = Dictionary(grouping: expenses) { normalizeTitle($0.title) }
            .mapValues { grouped in
                (
                    title: grouped.first?.title ?? "Expense",
                    amount: grouped.reduce(Decimal.zero) { $0 + $1.amount },
                    count: grouped.count,
                    category: grouped.first.flatMap { categoryMap[$0.categoryID]?.name } ?? "Uncategorized"
                )
            }
            .filter { $0.value.count > 1 }

        guard let top = normalized.values.sorted(by: {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.amount > $1.amount
        }).first else {
            return AssistantInsight(
                promptID: "frequent-spend",
                title: "Frequent spends",
                value: L10n.string("No repeats yet"),
                message: L10n.string("I did not find repeated expense titles this month."),
                action: L10n.string("As more entries come in, I will flag repeat habits like coffee, fuel, groceries, or subscriptions."),
                icon: "repeat.circle.fill",
                tint: AppDesignSystem.Colors.warning,
                detailRows: []
            )
        }

        return AssistantInsight(
            promptID: "frequent-spend",
            title: "Frequent spends",
            value: top.title,
            message: L10n.format("assistant.insight.frequent.message", top.count, CurrencyFormatter.format(top.amount)),
            action: L10n.string("Repeated small spends are worth reviewing because they are easier to tune than rare large spends."),
            icon: "repeat.circle.fill",
            tint: AppDesignSystem.Colors.warning,
            detailRows: [
                AssistantInsightRow(icon: "number.circle.fill", title: "Frequency", value: "\(top.count)x"),
                AssistantInsightRow(icon: "tag.fill", title: "Category", value: top.category)
            ]
        )
    }

    private static func emptyInsight(promptID: String = "highest-day", message: String) -> AssistantInsight {
        AssistantInsight(
            promptID: promptID,
            title: "No insight yet",
            value: L10n.string("Needs data"),
            message: message,
            action: L10n.string("Add expenses, income, and budget details so I can produce meaningful answers."),
            icon: "sparkles",
            tint: AppDesignSystem.Colors.primary,
            detailRows: []
        )
    }

    private static func normalizeTitle(_ title: String) -> String {
        title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: " ")
    }

    private static func dates(from startDate: Date, through endDate: Date, calendar: Calendar) -> [Date] {
        var dates: [Date] = []
        var date = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while date <= end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        return dates
    }
}
