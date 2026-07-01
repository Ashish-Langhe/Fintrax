//
//  FinnyVoiceCommandService.swift
//  Fintrax
//
//  Fintrax documentation: Parses local VoiceFin commands and creates Finny responses.
//

import SwiftUI

struct FinnyVoiceExpenseDraft: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let amount: Decimal
    let date: Date
    let category: Category

    var expense: Expense {
        Expense(title: title, amount: amount, date: date, categoryID: category.id, note: L10n.string("assistant.voice.expenseNote"))
    }
}

struct FinnyVoiceResponse: Identifiable {
    enum ResponseKind {
        case answer
        case confirmation
        case success
        case warning
    }

    let id = UUID()
    let kind: ResponseKind
    let title: String
    let message: String
    let spokenText: String
    let icon: String
    let tint: Color
    let detailRows: [AssistantInsightRow]
    let pendingExpense: FinnyVoiceExpenseDraft?
}

struct FinnyVoiceCommandService {
    private let smartCategoryService = SmartCategoryService()
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func response(for transcript: String, snapshot: DashboardDataSnapshot, now: Date = Date()) -> FinnyVoiceResponse {
        let command = normalize(transcript)

        if let draft = expenseDraft(from: transcript, normalizedCommand: command, categories: snapshot.categories, now: now) {
            return expenseConfirmation(for: draft)
        }

        if asksForHighestSpendDay(command) {
            return dailySpendResponse(
                title: L10n.string("assistant.voice.highestDay.title"),
                mode: .highest,
                snapshot: snapshot,
                now: now
            )
        }

        if asksForLowestSpendDay(command) {
            return dailySpendResponse(
                title: L10n.string("assistant.voice.lowestDay.title"),
                mode: .lowest,
                snapshot: snapshot,
                now: now
            )
        }

        if asksForSummary(command) {
            return summaryResponse(snapshot: snapshot, now: now)
        }

        if let spendingQuery = spendingQuery(from: command, snapshot: snapshot, now: now) {
            return spendingResponse(for: spendingQuery, snapshot: snapshot)
        }

        return FinnyVoiceResponse(
            kind: .warning,
            title: L10n.string("assistant.voice.unknown.title"),
            message: L10n.string("assistant.voice.unknown.message"),
            spokenText: L10n.string("assistant.voice.unknown.spoken"),
            icon: "questionmark.bubble.fill",
            tint: AppDesignSystem.Colors.warning,
            detailRows: [],
            pendingExpense: nil
        )
    }

    func savedExpenseResponse(for draft: FinnyVoiceExpenseDraft) -> FinnyVoiceResponse {
        FinnyVoiceResponse(
            kind: .success,
            title: L10n.string("assistant.voice.saved.title"),
            message: L10n.format("assistant.voice.saved.message", draft.title, CurrencyFormatter.format(draft.amount), draft.category.name),
            spokenText: L10n.format("assistant.voice.saved.spoken", draft.title, CurrencyFormatter.format(draft.amount), draft.category.name),
            icon: "checkmark.seal.fill",
            tint: AppDesignSystem.Colors.success,
            detailRows: [
                AssistantInsightRow(icon: "indianrupeesign.circle.fill", title: L10n.string("assistant.voice.amount"), value: CurrencyFormatter.format(draft.amount)),
                AssistantInsightRow(icon: "tag.fill", title: L10n.string("assistant.voice.category"), value: draft.category.name)
            ],
            pendingExpense: nil
        )
    }

    private func expenseDraft(from rawTranscript: String, normalizedCommand: String, categories: [Category], now: Date) -> FinnyVoiceExpenseDraft? {
        guard containsAny(normalizedCommand, terms: ["add", "spent", "paid", "record", "log"]) else { return nil }
        guard let amount = amount(from: normalizedCommand), amount > .zero else { return nil }

        let title = expenseTitle(from: rawTranscript, normalizedCommand: normalizedCommand, amount: amount)
        guard !title.isEmpty else { return nil }

        let suggestion = smartCategoryService.suggestCategory(for: title, categories: categories)
        let fallback = categories.first { $0.name.localizedCaseInsensitiveCompare("Other") == .orderedSame } ?? categories.first
        guard let category = suggestion?.category ?? fallback else { return nil }

        return FinnyVoiceExpenseDraft(
            title: title,
            amount: amount,
            date: date(from: normalizedCommand, now: now),
            category: category
        )
    }

    private func expenseConfirmation(for draft: FinnyVoiceExpenseDraft) -> FinnyVoiceResponse {
        FinnyVoiceResponse(
            kind: .confirmation,
            title: L10n.string("assistant.voice.confirmExpense.title"),
            message: L10n.format("assistant.voice.confirmExpense.message", draft.title, CurrencyFormatter.format(draft.amount), draft.category.name),
            spokenText: L10n.format("assistant.voice.confirmExpense.spoken", draft.title, CurrencyFormatter.format(draft.amount), draft.category.name),
            icon: "mic.badge.plus",
            tint: AppDesignSystem.Colors.primary,
            detailRows: [
                AssistantInsightRow(icon: "indianrupeesign.circle.fill", title: L10n.string("assistant.voice.amount"), value: CurrencyFormatter.format(draft.amount)),
                AssistantInsightRow(icon: "tag.fill", title: L10n.string("assistant.voice.category"), value: draft.category.name)
            ],
            pendingExpense: draft
        )
    }

    private func spendingQuery(from command: String, snapshot: DashboardDataSnapshot, now: Date) -> SpendingQuery? {
        guard containsAny(command, terms: ["how much", "spend", "spent", "expense", "expenses"]) else { return nil }

        let interval = dateInterval(from: command, now: now)
        let categories = snapshot.categories
        let matchedCategory = categories.first { category in
            command.contains(normalize(category.name))
        }

        var merchant = command
        let removableTerms = [
            "how much", "did i", "do i", "spend", "spent", "on", "for", "in", "this month", "last month",
            "this week", "last week", "today", "yesterday", "expenses", "expense", "show me", "tell me"
        ]
        removableTerms.forEach { merchant = merchant.replacingOccurrences(of: $0, with: " ") }

        if let matchedCategory {
            merchant = merchant.replacingOccurrences(of: normalize(matchedCategory.name), with: " ")
        }

        merchant = merchant
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return SpendingQuery(
            dateInterval: interval,
            category: matchedCategory,
            merchant: merchant.isEmpty ? nil : merchant
        )
    }

    private func spendingResponse(for query: SpendingQuery, snapshot: DashboardDataSnapshot) -> FinnyVoiceResponse {
        let categoryMap = Dictionary(uniqueKeysWithValues: snapshot.categories.map { ($0.id, $0) })
        let expenses = snapshot.expenses.filter { expense in
            query.dateInterval.contains(expense.date)
            && (query.category == nil || expense.categoryID == query.category?.id)
            && (query.merchant == nil || normalize(expense.title).contains(query.merchant ?? ""))
        }
        let total = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let label = query.category?.name ?? query.merchant?.capitalized ?? L10n.string("assistant.voice.allExpenses")
        let topCategory = topCategoryName(from: expenses, categoryMap: categoryMap)

        return FinnyVoiceResponse(
            kind: .answer,
            title: L10n.string("assistant.voice.spending.title"),
            message: L10n.format("assistant.voice.spending.message", CurrencyFormatter.format(total), label, expenses.count),
            spokenText: L10n.format("assistant.voice.spending.spoken", CurrencyFormatter.format(total), label),
            icon: "chart.bar.doc.horizontal.fill",
            tint: AppDesignSystem.Colors.info,
            detailRows: [
                AssistantInsightRow(icon: "list.bullet", title: L10n.string("assistant.voice.entries"), value: "\(expenses.count)"),
                AssistantInsightRow(icon: "tag.fill", title: L10n.string("assistant.voice.topCategory"), value: topCategory)
            ],
            pendingExpense: nil
        )
    }

    private func dailySpendResponse(title: String, mode: DailySpendMode, snapshot: DashboardDataSnapshot, now: Date) -> FinnyVoiceResponse {
        let interval = dateInterval(from: "this month", now: now)
        let today = calendar.startOfDay(for: now)
        let grouped = Dictionary(grouping: snapshot.expenses.filter { interval.contains($0.date) }) {
            calendar.startOfDay(for: $0.date)
        }
        let days = dates(from: interval.start, through: today)
        let totals = days.map { date in
            let expenses = grouped[date] ?? []
            return (date: date, total: expenses.reduce(Decimal.zero) { $0 + $1.amount }, count: expenses.count)
        }
        let selected = mode == .highest
            ? totals.max { $0.total < $1.total }
            : totals.min {
                if $0.total != $1.total {
                    return $0.total < $1.total
                }
                return $0.date > $1.date
            }

        guard let selected else {
            return emptyDataResponse()
        }

        let date = selected.date.formatted(date: .abbreviated, time: .omitted)
        let amount = CurrencyFormatter.format(selected.total)
        return FinnyVoiceResponse(
            kind: .answer,
            title: title,
            message: L10n.format("assistant.voice.day.message", date, amount, selected.count),
            spokenText: L10n.format("assistant.voice.day.spoken", date, amount),
            icon: mode == .highest ? "calendar.badge.exclamationmark" : "leaf.fill",
            tint: mode == .highest ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.success,
            detailRows: [
                AssistantInsightRow(icon: "indianrupeesign.circle.fill", title: L10n.string("assistant.voice.amount"), value: amount),
                AssistantInsightRow(icon: "list.bullet", title: L10n.string("assistant.voice.entries"), value: "\(selected.count)")
            ],
            pendingExpense: nil
        )
    }

    private func summaryResponse(snapshot: DashboardDataSnapshot, now: Date) -> FinnyVoiceResponse {
        let interval = dateInterval(from: "this week", now: now)
        let expenses = snapshot.expenses.filter { interval.contains($0.date) }
        let incomes = snapshot.incomes.filter { interval.contains($0.date) }
        let spend = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let income = incomes.reduce(Decimal.zero) { $0 + $1.amount }
        let net = income - spend

        return FinnyVoiceResponse(
            kind: .answer,
            title: L10n.string("assistant.voice.summary.title"),
            message: L10n.format("assistant.voice.summary.message", CurrencyFormatter.format(spend), CurrencyFormatter.format(income), CurrencyFormatter.format(net)),
            spokenText: L10n.format("assistant.voice.summary.spoken", CurrencyFormatter.format(spend), CurrencyFormatter.format(net)),
            icon: "sparkles.rectangle.stack.fill",
            tint: net >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning,
            detailRows: [
                AssistantInsightRow(icon: "minus.circle.fill", title: L10n.string("assistant.voice.spend"), value: CurrencyFormatter.format(spend)),
                AssistantInsightRow(icon: "plus.circle.fill", title: L10n.string("assistant.voice.income"), value: CurrencyFormatter.format(income))
            ],
            pendingExpense: nil
        )
    }

    private func emptyDataResponse() -> FinnyVoiceResponse {
        FinnyVoiceResponse(
            kind: .warning,
            title: L10n.string("assistant.voice.noData.title"),
            message: L10n.string("assistant.voice.noData.message"),
            spokenText: L10n.string("assistant.voice.noData.spoken"),
            icon: "tray.fill",
            tint: AppDesignSystem.Colors.warning,
            detailRows: [],
            pendingExpense: nil
        )
    }

    private func amount(from command: String) -> Decimal? {
        let cleaned = command
            .replacingOccurrences(of: "₹", with: " ")
            .replacingOccurrences(of: "rs", with: " ")
            .replacingOccurrences(of: "rupees", with: " ")
            .replacingOccurrences(of: "rupee", with: " ")

        return cleaned
            .components(separatedBy: CharacterSet(charactersIn: " ,"))
            .compactMap { Decimal(string: $0.filter { $0.isNumber || $0 == "." }) }
            .first
    }

    private func expenseTitle(from rawTranscript: String, normalizedCommand: String, amount: Decimal) -> String {
        var title = rawTranscript
        let amountText = NSDecimalNumber(decimal: amount).stringValue
        let remove = ["add", "spent", "paid", "record", "log", "expense", "for", "on", "₹", "rs", "rupees", "rupee", amountText]
        remove.forEach { token in
            title = title.replacingOccurrences(of: token, with: " ", options: [.caseInsensitive, .diacriticInsensitive])
        }

        if normalizedCommand.contains("today") {
            title = title.replacingOccurrences(of: "today", with: " ", options: [.caseInsensitive])
        }
        if normalizedCommand.contains("yesterday") {
            title = title.replacingOccurrences(of: "yesterday", with: " ", options: [.caseInsensitive])
        }

        return title
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters)
    }

    private func date(from command: String, now: Date) -> Date {
        if command.contains("yesterday") {
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
        return now
    }

    private func dateInterval(from command: String, now: Date) -> DateInterval {
        if command.contains("last month"),
           let currentMonth = calendar.dateInterval(of: .month, for: now),
           let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentMonth.start),
           let previousMonth = calendar.dateInterval(of: .month, for: previousMonthDate) {
            return previousMonth
        }

        if command.contains("last week"),
           let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now),
           let previousWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek.start),
           let previousWeek = calendar.dateInterval(of: .weekOfYear, for: previousWeekDate) {
            return previousWeek
        }

        if command.contains("this week"),
           let week = calendar.dateInterval(of: .weekOfYear, for: now) {
            return week
        }

        if command.contains("today") {
            let start = calendar.startOfDay(for: now)
            return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: start) ?? now)
        }

        if command.contains("yesterday") {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            let start = calendar.startOfDay(for: yesterday)
            return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: start) ?? now)
        }

        return calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: .distantPast, end: .distantFuture)
    }

    private func topCategoryName(from expenses: [Expense], categoryMap: [UUID: Category]) -> String {
        let grouped = Dictionary(grouping: expenses) { $0.categoryID }
            .mapValues { $0.reduce(Decimal.zero) { $0 + $1.amount } }
        guard let top = grouped.max(by: { $0.value < $1.value }) else {
            return L10n.string("assistant.voice.none")
        }
        return categoryMap[top.key]?.name ?? L10n.string("assistant.voice.uncategorized")
    }

    private func asksForHighestSpendDay(_ command: String) -> Bool {
        containsAny(command, terms: ["highest", "most", "maximum", "max"]) && command.contains("day")
    }

    private func asksForLowestSpendDay(_ command: String) -> Bool {
        containsAny(command, terms: ["lowest", "least", "minimum", "min", "saving day"]) && command.contains("day")
    }

    private func asksForSummary(_ command: String) -> Bool {
        containsAny(command, terms: ["summary", "summarize", "recap", "this week"])
    }

    private func containsAny(_ value: String, terms: [String]) -> Bool {
        terms.contains { value.contains($0) }
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func dates(from startDate: Date, through endDate: Date) -> [Date] {
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

private struct SpendingQuery {
    let dateInterval: DateInterval
    let category: Category?
    let merchant: String?
}

private enum DailySpendMode {
    case highest
    case lowest
}
