//
//  ExpenseCalendarInsightView.swift
//  Fintrax
//
//  Fintrax documentation: Extracted reusable expense screen components.
//

import SwiftUI
import Foundation

struct ExpenseCalendarInsightView: View {
    let expenses: [Expense]
    let categories: [Category]
    @Binding var selectedMonth: Date
    @State private var selectedDay: Date?
    @State private var dayDetail: ExpenseCalendarDayDetail?

    private let calendar = Calendar.current
    private let calendarColumns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 7)

    private var monthInterval: DateInterval {
        calendar.dateInterval(of: .month, for: selectedMonth) ?? DateInterval(start: selectedMonth, duration: 0)
    }

    private var monthExpenses: [Expense] {
        expenses.filter { expense in
            expense.date >= monthInterval.start && expense.date < monthInterval.end
        }
    }

    private var dailyTotals: [Date: Decimal] {
        Dictionary(grouping: monthExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        .mapValues { expenses in
            expenses.reduce(Decimal.zero) { $0 + $1.amount }
        }
    }

    private var totalSpend: Decimal {
        monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var maxDailySpend: Decimal {
        dailyTotals.values.max() ?? .zero
    }

    private var activeSpendDays: Int {
        dailyTotals.values.filter { $0 > 0 }.count
    }

    private var averageActiveDaySpend: Decimal {
        guard activeSpendDays > 0 else { return .zero }
        return totalSpend / Decimal(activeSpendDays)
    }

    private var highestSpendDay: (date: Date, amount: Decimal)? {
        dailyTotals.max { lhs, rhs in lhs.value < rhs.value }
            .map { ($0.key, $0.value) }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let startIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                calendarHeader
                monthStats
                monthCalendarGrid
                monthInsight
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            ensureSelectedDay()
        }
        .onChange(of: selectedMonth) { _, _ in
            ensureSelectedDay(reset: true)
        }
        .onChange(of: monthExpenses.map(\.id)) { _, _ in
            ensureSelectedDay()
        }
        .sheet(item: $dayDetail) { detail in
            ExpenseDayDetailSheet(
                date: detail.date,
                expenses: expensesForDay(detail.date),
                categories: categories
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    private var calendarHeader: some View {
        HStack(spacing: 12) {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36, height: 36)
                    .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.72), in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(AppDesignSystem.Typography.title3)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                Text(L10n.format(L10n.Expenses.entriesInMonth, monthExpenses.count))
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36, height: 36)
                    .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.72), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(calendarPanelBackground)
    }

    private var monthStats: some View {
        HStack(spacing: 10) {
            CalendarStatTile(title: L10n.Expenses.total, value: totalSpend.formattedAmount(), icon: "indianrupeesign.circle.fill", tint: AppDesignSystem.Colors.primary)
            CalendarStatTile(title: L10n.Expenses.activeDays, value: "\(activeSpendDays)", icon: "calendar.badge.checkmark", tint: AppDesignSystem.Colors.info)
            CalendarStatTile(title: L10n.Expenses.peakDay, value: maxDailySpend.formattedAmount(), icon: "flame.fill", tint: AppDesignSystem.Colors.warning)
        }
    }

    private var monthCalendarGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ExpenseCalendarSectionHeader(title: L10n.Expenses.monthCalendar, icon: "calendar", tint: AppDesignSystem.Colors.primary)

                Spacer(minLength: 8)

                CalendarLegendPill()
            }

            HStack(spacing: 8) {
                CalendarMicroMetric(
                    icon: "chart.bar.fill",
                    title: L10n.Expenses.avgActiveDay,
                    value: averageActiveDaySpend.formattedAmount(),
                    tint: AppDesignSystem.Colors.success
                )

                CalendarMicroMetric(
                    icon: "number",
                    title: L10n.Expenses.entries,
                    value: "\(monthExpenses.count)",
                    tint: AppDesignSystem.Colors.info
                )
            }

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 2)

            LazyVGrid(columns: calendarColumns, spacing: 7) {
                ForEach(calendarDays) { day in
                    ExpenseMonthDayCell(
                        day: day,
                        maxAmount: maxDailySpend,
                        onSelect: {
                            guard let date = day.date else { return }
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                selectedDay = date
                            }
                            dayDetail = ExpenseCalendarDayDetail(date: date)
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(calendarPanelBackground)
    }

    private var calendarDays: [ExpenseMonthDay] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [ExpenseMonthDay] = (0..<leadingBlanks).map { _ in .blank() }

        for day in monthRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else { continue }
            let start = calendar.startOfDay(for: date)
            let amount = dailyTotals[start] ?? .zero
            let expensesForDay = monthExpenses.filter { calendar.isDate($0.date, inSameDayAs: start) }
            days.append(
                ExpenseMonthDay(
                    date: start,
                    dayNumber: day,
                    amount: amount,
                    count: expensesForDay.count,
                    isToday: calendar.isDateInToday(start),
                    isSelected: selectedDay.map { calendar.isDate($0, inSameDayAs: start) } ?? false
                )
            )
        }

        while !days.count.isMultiple(of: 7) {
            days.append(.blank())
        }

        return days
    }

    private var monthInsight: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.warning)
                .frame(width: 34, height: 34)
                .background(AppDesignSystem.Colors.warning.opacity(0.13), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Expenses.monthlyInsight)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(insightText)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(calendarPanelBackground)
    }

    private var insightText: String {
        guard let highestSpendDay else {
            return L10n.string("expenses.calendar.noMonthlySpending")
        }

        let day = highestSpendDay.date.formatted(.dateTime.day().month(.abbreviated))
        let amount = highestSpendDay.amount.formattedAmount()
        if let category = topCategoryName {
            return L10n.format(L10n.Expenses.highestSpendingWithCategory, amount, day, category)
        }

        return L10n.format(L10n.Expenses.highestSpendingWithoutCategory, amount, day)
    }

    private var topCategoryName: String? {
        topCategoryName(for: monthExpenses)
    }

    private func topCategoryName(for expenses: [Expense]) -> String? {
        guard let categoryID = topCategoryID(for: expenses) else { return nil }
        return categories.first { $0.id == categoryID }?.name
    }

    private func topCategoryID(for expenses: [Expense]) -> UUID? {
        let grouped = Dictionary(grouping: expenses, by: \.categoryID)
        return grouped.max { lhs, rhs in
            lhs.value.reduce(Decimal.zero) { $0 + $1.amount } < rhs.value.reduce(Decimal.zero) { $0 + $1.amount }
        }?.key
    }

    private func expensesForDay(_ date: Date) -> [Expense] {
        monthExpenses
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.amount > $1.amount }
    }

    private var calendarPanelBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppDesignSystem.Colors.cardStroke, lineWidth: 1)
            }
    }

    private func moveMonth(by value: Int) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
        }
    }

    private func ensureSelectedDay(reset: Bool = false) {
        if !reset,
           let selectedDay,
           selectedDay >= monthInterval.start,
           selectedDay < monthInterval.end {
            return
        }

        selectedDay = dailyTotals.keys.sorted().last ?? monthInterval.start
    }

}
