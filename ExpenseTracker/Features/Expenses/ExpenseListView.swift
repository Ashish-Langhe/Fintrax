//
//  ExpenseListView.swift
//  Fintrax
//
//  Fintrax documentation: Builds expense list, filtering, searching, add/edit, validation, and row presentation flows.
//

import SwiftUI
import Foundation

/// Main expense list view
struct ExpenseListView: View {
    @StateObject private var viewModel = ExpenseListViewModel()
    @Environment(\.locale) private var locale
    @State private var showingAddExpense = false
    @State private var expenseToEdit: Expense?
    @State private var showingFilterSheet = false
    @State private var displayMode: ExpenseDisplayMode = .list
    @State private var calendarMonth = Date()
    
    let categories: [Category]
    let budgets: [Budget]
    
    init(categories: [Category] = [], budgets: [Budget] = []) {
        self.categories = categories
        self.budgets = budgets
    }
    
    private var displayCategories: [Category] {
        categories.isEmpty ? viewModel.categories : categories
    }

    private var deleteExpenseMessage: String {
        guard let expense = viewModel.expenseToDelete else {
            return L10n.string("expenses.delete.genericMessage")
        }
        return L10n.format(L10n.Expenses.deleteSpecificMessage, expense.title)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FintraxTabBackground(style: .expenses)

                if viewModel.loadingState.isLoading && viewModel.expenses.isEmpty {
                    ProgressView(L10n.Expenses.loading)
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 0) {
                        // Filter and search bar
                        FilterAndSearchBar(
                            selectedCategory: $viewModel.selectedCategory,
                            selectedDateRange: $viewModel.selectedDateRange,
                            searchText: $viewModel.searchText,
                            smartSearchSummary: viewModel.smartSearchSummary,
                            categories: displayCategories,
                            showingFilterSheet: $showingFilterSheet
                        )

                        ExpenseDisplayModePicker(selection: $displayMode)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        
                        // Expense list or empty state
                        if viewModel.filteredExpenses.isEmpty {
                            EmptyExpenseState(
                                hasActiveFilters: viewModel.hasActiveFilters(),
                                onResetFilters: {
                                    viewModel.resetFilters()
                                }
                            )
                        } else {
                            switch displayMode {
                            case .list:
                                expenseList
                            case .calendar:
                                ExpenseCalendarInsightView(
                                    expenses: viewModel.filteredExpenses,
                                    categories: viewModel.categories,
                                    selectedMonth: $calendarMonth
                                )
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(L10n.Expenses.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        ToolbarIconLabel(systemImage: "plus", tint: .blue)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await viewModel.refreshData()
                        }
                    } label: {
                        ToolbarIconLabel(
                            systemImage: viewModel.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise",
                            tint: .teal,
                            isAnimating: viewModel.isRefreshing
                        )
                    }
                    .disabled(viewModel.isRefreshing)
                    
                    if viewModel.hasActiveFilters() {
                        Button {
                            viewModel.resetFilters()
                        } label: {
                            ToolbarIconLabel(systemImage: "xmark.circle.fill", tint: .red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                NavigationStack {
                    AddEditExpenseView(categories: viewModel.categories)
                }
            }
            .sheet(item: $expenseToEdit) { expense in
                NavigationStack {
                    AddEditExpenseView(expense: expense, categories: viewModel.categories)
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(
                    selectedCategory: $viewModel.selectedCategory,
                    selectedDateRange: $viewModel.selectedDateRange,
                    sortOption: $viewModel.sortOption,
                    categories: displayCategories
                )
            }
            .fintraxModal(
                isPresented: viewModel.showingDeleteAlert,
                title: L10n.string("expenses.delete.question"),
                message: deleteExpenseMessage,
                icon: "trash.fill",
                tint: AppDesignSystem.Colors.error,
                primaryAction: FintraxModalAction(title: L10n.string("expenses.delete.action"), icon: "trash.fill", tint: AppDesignSystem.Colors.error, isDestructive: true) {
                    Task {
                        await viewModel.confirmDelete()
                    }
                },
                secondaryAction: FintraxModalAction(title: L10n.string("expenses.delete.keep"), icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
                    viewModel.cancelDelete()
                }
            )
            .task {
                await viewModel.loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .categoryDidChange)) { _ in
                Task { await viewModel.refreshData() }
            }
            .onChange(of: showingAddExpense) { _, isPresented in
                if !isPresented {
                    Task { await viewModel.refreshData() }
                }
            }
            .onChange(of: expenseToEdit) { _, expense in
                if expense == nil {
                    Task { await viewModel.refreshData() }
                }
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.selectedDateRange) { _, _ in
                viewModel.applyFilters()
            }
            .onChange(of: viewModel.sortOption) { _, _ in
                viewModel.applyFilters()
            }
            .onChange(of: locale.identifier) { _, _ in
                viewModel.applyFilters()
            }
        }
    }
    
    private var expenseList: some View {
        List {
            Section {
                ExpenseListSummaryCard(
                    total: viewModel.totalFilteredAmount().formattedAmount(),
                    count: viewModel.filteredCount(),
                    average: averageFilteredAmount.formattedAmount(),
                    period: expenseListPeriod,
                    hasFilters: viewModel.hasActiveFilters()
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            Section {
                ExpenseFeedHeader(
                    count: viewModel.filteredCount(),
                    period: expenseListPeriod
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(viewModel.filteredExpenses) { expense in
                ExpenseRow(
                    expense: expense,
                    category: viewModel.category(for: expense.categoryID),
                    onTap: {
                        expenseToEdit = expense
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteExpense(expense)
                        }
                    }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.refreshData()
        }
    }

    private var averageFilteredAmount: Decimal {
        let count = viewModel.filteredCount()
        guard count > 0 else { return .zero }

        return NSDecimalNumber(decimal: viewModel.totalFilteredAmount())
            .dividing(by: NSDecimalNumber(value: count))
            .decimalValue
    }

    private var expenseListPeriod: String {
        viewModel.selectedDateRange == .allTime ? L10n.string("expenses.period.allTime") : viewModel.selectedDateRange.localizedString
    }

}

private enum ExpenseDisplayMode: String, CaseIterable, Identifiable {
    case list = "List"
    case calendar = "Month"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .list:
            L10n.Expenses.listMode
        case .calendar:
            L10n.Expenses.monthMode
        }
    }

    var icon: String {
        switch self {
        case .list:
            return "list.bullet.rectangle"
        case .calendar:
            return "calendar"
        }
    }
}

private struct ExpenseDisplayModePicker: View {
    @Binding var selection: ExpenseDisplayMode

    var body: some View {
        Picker(selection: $selection) {
            ForEach(ExpenseDisplayMode.allCases) { mode in
                Label(mode.title, systemImage: mode.icon)
                    .tag(mode)
            }
        } label: {
            Text(L10n.Expenses.displayModeAccessibility)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(L10n.Expenses.displayModeAccessibility)
    }
}

private struct ExpenseListSummaryCard: View {
    let total: String
    let count: Int
    let average: String
    let period: String
    let hasFilters: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle.fill" : "creditcard.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        LinearGradient(
                            colors: hasFilters ? [.orange, .pink] : [.blue, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(hasFilters ? L10n.Expenses.filteredSpend : L10n.Expenses.expenseActivity)
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(total)
                        .font(AppDesignSystem.Typography.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(period)
                        .font(AppDesignSystem.Typography.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("\(count)")
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground).opacity(0.72), in: Capsule())
            }

            HStack(spacing: 10) {
                SummaryMetricPill(title: L10n.Expenses.average, value: average, icon: "chart.line.uptrend.xyaxis")
                SummaryMetricPill(title: L10n.Expenses.entries, value: L10n.format(L10n.Expenses.itemCount, count), icon: "list.bullet.rectangle")
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.92))

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color.blue.opacity(0.08),
                        Color.teal.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 7)
    }
}

private struct SummaryMetricPill: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground).opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ExpenseCalendarInsightView: View {
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
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
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

private struct ExpenseCalendarDayDetail: Identifiable {
    let date: Date

    var id: TimeInterval {
        date.timeIntervalSinceReferenceDate
    }
}

private struct ExpenseDayDetailSheet: View {
    let date: Date
    let expenses: [Expense]
    let categories: [Category]

    private var totalSpend: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var highestExpense: Expense? {
        expenses.max { $0.amount < $1.amount }
    }

    private var topCategory: Category? {
        let grouped = Dictionary(grouping: expenses, by: \.categoryID)
        guard let categoryID = grouped.max(by: { lhs, rhs in
            lhs.value.reduce(Decimal.zero) { $0 + $1.amount } < rhs.value.reduce(Decimal.zero) { $0 + $1.amount }
        })?.key else {
            return nil
        }
        return categories.first { $0.id == categoryID }
    }

    private var dateTitle: String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sheetHeader
                insightGrid

                if expenses.isEmpty {
                    emptyState
                } else {
                    expenseRows
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(FintraxTabBackground(style: .expenses))
    }

    private var sheetHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: expenses.isEmpty ? "calendar" : "calendar.badge.clock")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background((topCategory?.displayColor ?? AppDesignSystem.Colors.primary).gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(dateTitle)
                        .font(AppDesignSystem.Typography.title3)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(expenses.isEmpty ? L10n.Expenses.noExpensesOnDate : LocalizedStringKey(L10n.format(L10n.Expenses.expensesRecorded, expenses.count)))
                        .font(AppDesignSystem.Typography.caption.weight(.semibold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(totalSpend.formattedAmount())
                    .font(AppDesignSystem.Typography.title2)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer()

                Text(L10n.Expenses.dayTotal)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Capsule())
            }
        }
        .padding(18)
        .background(sheetPanelBackground(accent: topCategory?.displayColor ?? AppDesignSystem.Colors.primary))
    }

    private var insightGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            DayDetailInsightChip(
                icon: "list.bullet.rectangle.fill",
                title: L10n.Expenses.entries,
                value: "\(expenses.count)",
                tint: AppDesignSystem.Colors.info
            )

            DayDetailInsightChip(
                icon: topCategory?.iconName ?? "tag.fill",
                title: L10n.Expenses.topCategory,
                value: topCategory?.name ?? L10n.string(L10n.Expenses.none),
                tint: topCategory?.displayColor ?? AppDesignSystem.Colors.textSecondary
            )

            DayDetailInsightChip(
                icon: "arrow.up.right.circle.fill",
                title: L10n.Expenses.highestItem,
                value: highestExpense?.formattedAmount() ?? "₹0",
                tint: AppDesignSystem.Colors.warning
            )

            DayDetailInsightChip(
                icon: "chart.pie.fill",
                title: L10n.Expenses.avgEntry,
                value: averageExpenseAmount.formattedAmount(),
                tint: AppDesignSystem.Colors.success
            )
        }
    }

    private var averageExpenseAmount: Decimal {
        guard !expenses.isEmpty else { return .zero }
        return totalSpend / Decimal(expenses.count)
    }

    private var expenseRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Expenses.title)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()

                Text(L10n.Expenses.highToLow)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.62), in: Capsule())
            }

            VStack(spacing: 0) {
                ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                    MonthDayExpenseRow(
                        expense: expense,
                        category: categories.first { $0.id == expense.categoryID }
                    )

                    if index < expenses.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
        }
        .padding(16)
        .background(sheetPanelBackground(accent: AppDesignSystem.Colors.info))
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .frame(width: 42, height: 42)
                .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.70), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.Expenses.quietDay)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(L10n.Expenses.quietDayMessage)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sheetPanelBackground(accent: AppDesignSystem.Colors.textSecondary))
    }

    private func sheetPanelBackground(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.76))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct DayDetailInsightChip: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct CalendarStatTile: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: Circle())

            Text(title)
                .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)

            Text(value)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct CalendarMicroMetric: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.54), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct CalendarLegendPill: View {
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppDesignSystem.Colors.primary.opacity(0.18 + Double(index) * 0.17))
                    .frame(width: 12, height: 8)
            }

            Text(L10n.Expenses.spend)
                .font(AppDesignSystem.Typography.caption2.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.64), in: Capsule())
        .overlay {
            Capsule()
                .stroke(AppDesignSystem.Colors.primary.opacity(0.14), lineWidth: 1)
        }
        .accessibilityLabel(L10n.Expenses.darkerDaysAccessibility)
    }
}

private struct ExpenseMonthDay: Identifiable {
    let id = UUID()
    let date: Date?
    let dayNumber: Int?
    let amount: Decimal
    let count: Int
    let isToday: Bool
    let isSelected: Bool

    static func blank() -> ExpenseMonthDay {
        ExpenseMonthDay(date: nil, dayNumber: nil, amount: .zero, count: 0, isToday: false, isSelected: false)
    }
}

private struct ExpenseMonthDayCell: View {
    let day: ExpenseMonthDay
    let maxAmount: Decimal
    let onSelect: () -> Void

    private var hasSpend: Bool {
        day.amount > 0
    }

    private var intensity: Double {
        guard maxAmount > 0, hasSpend else { return 0 }
        return min(max(NSDecimalNumber(decimal: day.amount / maxAmount).doubleValue, 0.18), 1)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    Text(day.dayNumber.map(String.init) ?? "")
                        .font(AppDesignSystem.Typography.caption.weight(day.isSelected ? .bold : .semibold))
                        .foregroundStyle(dayTextColor)
                        .frame(height: 15)

                    if day.isToday && day.date != nil {
                        Circle()
                            .fill(day.isSelected ? Color.white.opacity(0.90) : AppDesignSystem.Colors.primary)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity)

                if hasSpend {
                    Text(shortAmount(day.amount))
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(day.isSelected ? .white : AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                } else if day.date != nil {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(day.isToday ? AppDesignSystem.Colors.primary.opacity(0.26) : Color.clear)
                        .frame(width: 14, height: 5)
                } else {
                    Color.clear.frame(height: 10)
                }

                spendIndicator
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(dayBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(dayBorderColor, lineWidth: day.isSelected ? 1.2 : 0.8)
            }
            .shadow(color: shadowColor, radius: day.isSelected ? 9 : 0, x: 0, y: day.isSelected ? 6 : 0)
        }
        .buttonStyle(.plain)
        .disabled(day.date == nil)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dayTextColor: Color {
        if day.isSelected { return .white }
        if day.date == nil { return .clear }
        if day.isToday { return AppDesignSystem.Colors.primary }
        return AppDesignSystem.Colors.textPrimary
    }

    private var dayBackground: some ShapeStyle {
        if day.isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.primary,
                        AppDesignSystem.Colors.primaryDark.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        if hasSpend {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.primary.opacity(0.08 + (0.14 * intensity)),
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(AppDesignSystem.Colors.elevatedSurface.opacity(day.date == nil ? 0 : 0.54))
    }

    private var dayBorderColor: Color {
        if day.isSelected { return Color.white.opacity(0.38) }
        if hasSpend { return AppDesignSystem.Colors.primary.opacity(0.14 + (0.12 * intensity)) }
        if day.isToday { return AppDesignSystem.Colors.primary.opacity(0.26) }
        return Color.white.opacity(0.12)
    }

    private var shadowColor: Color {
        AppDesignSystem.Colors.primary.opacity(0.20)
    }

    @ViewBuilder
    private var spendIndicator: some View {
        if hasSpend {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(spendBarColor(for: index))
                        .frame(width: 6, height: 3)
                }
            }
            .opacity(day.isSelected ? 0.95 : 0.72)
        } else {
            Color.clear.frame(height: 3)
        }
    }

    private func spendBarColor(for index: Int) -> Color {
        let threshold = Double(index + 1) / 3
        if intensity >= threshold {
            return day.isSelected ? .white : AppDesignSystem.Colors.primary
        }
        return day.isSelected ? Color.white.opacity(0.32) : AppDesignSystem.Colors.primary.opacity(0.18)
    }

    private var accessibilityLabel: String {
        guard let date = day.date else { return L10n.string(L10n.Expenses.blankCalendarDay) }
        let dateText = date.formatted(.dateTime.day().month(.wide))
        if hasSpend {
            return L10n.format(L10n.Expenses.dayAccessibilityWithSpend, dateText, day.amount.formattedAmount(), day.count)
        }
        return L10n.format(L10n.Expenses.dayAccessibilityNoSpend, dateText)
    }

    private func shortAmount(_ amount: Decimal) -> String {
        let value = NSDecimalNumber(decimal: amount).doubleValue
        if value >= 100_000 {
            return String(format: "₹%.0fL", value / 100_000)
        }
        if value >= 1_000 {
            return String(format: "₹%.0fk", value / 1_000)
        }
        return "₹\(Int(value))"
    }
}

private struct MonthDayExpenseRow: View {
    let expense: Expense
    let category: Category?

    private var categoryColor: Color {
        category?.displayColor ?? AppDesignSystem.Colors.primary
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category?.iconName ?? "tag.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(categoryColor)
                .frame(width: 30, height: 30)
                .background(categoryColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Text(category?.name ?? L10n.string(L10n.Expenses.uncategorized))
                    .font(AppDesignSystem.Typography.caption2.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(expense.formattedAmount())
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.error)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
    }
}

private struct ExpenseCalendarSectionHeader: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(title)
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            Spacer()
        }
    }
}

/// Filter and search bar
struct FilterAndSearchBar: View {
    @Binding var selectedCategory: UUID?
    @Binding var selectedDateRange: DateRangeOption
    @Binding var searchText: String
    let smartSearchSummary: String?
    @FocusState private var isSearchFocused: Bool
    
    let categories: [Category]
    @Binding var showingFilterSheet: Bool

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDateRange != .allTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSearchFocused ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        (isSearchFocused ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.info)
                            .opacity(isSearchFocused ? 0.14 : 0.10),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Expenses.search)
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)

                    TextField(L10n.Expenses.searchPlaceholder, text: $searchText)
                        .font(AppDesignSystem.Typography.callout)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                }

                if !searchText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.72), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Expenses.clearSearch)
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.92),
                        AppDesignSystem.Colors.surfaceVariant.opacity(0.48)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSearchFocused ? AppDesignSystem.Colors.primary.opacity(0.34) : Color.white.opacity(0.16),
                        lineWidth: isSearchFocused ? 1.1 : 0.8
                    )
            }
            .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 12)
            .shadow(color: AppDesignSystem.Colors.primary.opacity(isSearchFocused ? 0.16 : 0.08), radius: isSearchFocused ? 14 : 10, x: 0, y: 7)

            if let smartSearchSummary, !smartSearchSummary.isEmpty {
                HStack(spacing: 7) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.caption.weight(.bold))
                    Text(smartSearchSummary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(AppDesignSystem.Typography.caption.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppDesignSystem.Colors.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(AppDesignSystem.Colors.primary.opacity(0.16), lineWidth: 1)
                }
            }

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: selectedCategory.flatMap { categoryName(for: $0) } ?? L10n.string("expenses.filter.allCategories"),
                            icon: "folder.fill",
                        isActive: selectedCategory != nil,
                        onTap: {
                            showingFilterSheet = true
                        }
                    )

                        FilterChip(
                            title: selectedDateRange.localizedString,
                            icon: "calendar",
                            isActive: selectedDateRange != .allTime,
                            onTap: {
                                showingFilterSheet = true
                            }
                        )

                        if !searchText.isEmpty {
                            SearchStatusChip(searchText: searchText) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    searchText = ""
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease.circle")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(hasActiveFilters ? .white : AppDesignSystem.Colors.primary)
                        .frame(width: 38, height: 38)
                        .background(
                            hasActiveFilters ? AppDesignSystem.Gradients.primary : LinearGradient(colors: [
                                AppDesignSystem.Colors.elevatedSurface.opacity(0.82),
                                AppDesignSystem.Colors.surfaceVariant.opacity(0.52)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Expenses.openFilters)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.58),
                    AppDesignSystem.Colors.surfaceVariant.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1)
        }
    }
    
    private func categoryName(for categoryId: UUID?) -> String? {
        guard let categoryId = categoryId else { return nil }
        return categories.first { $0.id == categoryId }?.name
    }
}

private struct SearchStatusChip: View {
    let searchText: String
    let onClear: () -> Void

    var body: some View {
        Button(action: onClear) {
            HStack(spacing: 6) {
                Image(systemName: "text.magnifyingglass")
                    .font(.caption.weight(.bold))
                Text(searchText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2.weight(.bold))
            }
            .font(AppDesignSystem.Typography.caption.weight(.bold))
            .foregroundStyle(AppDesignSystem.Colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 180)
            .background(AppDesignSystem.Colors.primary.opacity(0.11), in: Capsule())
            .overlay(Capsule().stroke(AppDesignSystem.Colors.primary.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Expenses.clearSearchText)
    }
}

/// Filter chip component
struct FilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: isActive ? "checkmark.circle.fill" : icon)
                    .font(.caption.weight(.bold))
                if isActive {
                    Image(systemName: icon)
                        .font(.caption2.weight(.bold))
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isActive ?
                LinearGradient(colors: [Color.blue, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [Color(.systemBackground).opacity(0.74), Color(.systemBackground).opacity(0.54)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : Color.white.opacity(0.26), lineWidth: 1)
            )
            .foregroundColor(isActive ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ToolbarIconLabel: View {
    let systemImage: String
    let tint: Color
    var isAnimating = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(Color(.systemBackground).opacity(0.68), in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.30), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(isAnimating ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isAnimating)
    }
}

/// Empty expense state
struct EmptyExpenseState: View {
    let hasActiveFilters: Bool
    let onResetFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 98, height: 98)

                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "tray")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text(hasActiveFilters ? L10n.Expenses.noMatchingExpenses : L10n.Expenses.noExpensesYet)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasActiveFilters ? L10n.Expenses.adjustFilters : L10n.Expenses.addFirstExpense)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if hasActiveFilters {
                Button {
                    onResetFilters()
                } label: {
                    Text(L10n.Expenses.resetFilters)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ExpenseFeedHeader: View {
    let count: Int
    let period: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Expenses.transactions)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .textCase(.uppercase)

                Text(period)
                    .font(AppDesignSystem.Typography.caption2.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }

            Spacer()

            Text(L10n.format(L10n.Expenses.itemCount, count))
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppDesignSystem.Colors.primary.opacity(0.10), in: Capsule())
        }
        .padding(.horizontal, 2)
    }
}

/// Expense row
struct ExpenseRow: View {
    let expense: Expense
    let category: Category?
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(categoryColor.opacity(0.13))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: category?.iconName ?? "tag.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(categoryColor)
                }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(expense.title)
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(expense.formattedAmount())
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.error)
                        .lineLimit(1)
                        .minimumScaleFactor(0.64)
                        .frame(minWidth: 86, alignment: .trailing)
                }

                HStack(spacing: 6) {
                    if let category {
                        Text(category.name)
                            .foregroundStyle(categoryColor)

                        Text("•")
                            .foregroundStyle(AppDesignSystem.Colors.textTertiary)
                    }

                    Text(formattedDate)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }
                .font(AppDesignSystem.Typography.caption.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(AppDesignSystem.Typography.caption.weight(.medium))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(categoryColor.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.Expenses.deleteExpense, systemImage: "trash")
            }
        }
    }
    
    private var categoryColor: Color {
        if let category {
            return category.displayColor
        }

        // Generate a consistent color based on category ID
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .mint]
        let hash = abs(expense.categoryID.hashValue)
        let index = hash % colors.count
        return colors[index]
    }

    private var formattedDate: String {
        expense.date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct ExpenseTexturedBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 18

                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.42, y: size.height))
                }

                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)

                let dotColor = Color.primary.opacity(0.06)
                for row in stride(from: CGFloat(32), through: size.height, by: 76) {
                    for column in stride(from: CGFloat(18), through: size.width, by: 86) {
                        let rect = CGRect(x: column, y: row, width: 3, height: 3)
                        context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Filter sheet
struct FilterSheet: View {
    @Binding var selectedCategory: UUID?
    @Binding var selectedDateRange: DateRangeOption
    @Binding var sortOption: SortOption
    
    let categories: [Category]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                FintraxTabBackground(style: .expenses)

                ScrollView {
                    VStack(spacing: 18) {
                        filterHero
                        categorySection
                        dateRangeSection
                        sortSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle(L10n.Expenses.filterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        selectedCategory = nil
                        selectedDateRange = .allTime
                        sortOption = .dateDescending
                    } label: {
                        Text(L10n.Expenses.reset)
                    }
                    .disabled(!hasActiveFilters)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(L10n.Expenses.done)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private var filterHero: some View {
        HStack(spacing: 14) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Expenses.refine)
                    .font(.headline)
                Text(activeSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(18)
        .filterSheetCard()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: L10n.Expenses.category, icon: "folder.fill", tint: .blue)

            LazyVStack(spacing: 10) {
                FilterSelectionRow(
                    title: L10n.string("expenses.filter.allCategories"),
                    subtitle: L10n.string("expenses.filter.showEveryExpense"),
                    icon: "square.grid.2x2.fill",
                    tint: .blue,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories) { category in
                    FilterSelectionRow(
                        title: category.name,
                        subtitle: L10n.format(L10n.Expenses.filterByCategory, category.name),
                        icon: "tag.fill",
                        tint: category.displayColor,
                        isSelected: selectedCategory == category.id
                    ) {
                        selectedCategory = category.id
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: L10n.Expenses.dateRange, icon: "calendar", tint: .teal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(DateRangeOption.allCases) { option in
                    FilterOptionChip(
                        title: option.localizedString,
                        icon: option == .allTime ? "clock.arrow.circlepath" : "calendar.badge.clock",
                        tint: .teal,
                        isSelected: selectedDateRange == option
                    ) {
                        selectedDateRange = option
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: L10n.Expenses.sortBy, icon: "arrow.up.arrow.down", tint: .orange)

            LazyVStack(spacing: 10) {
                ForEach(SortOption.allCases) { option in
                    FilterSelectionRow(
                        title: option.localizedString,
                        subtitle: sortSubtitle(for: option),
                        icon: sortIcon(for: option),
                        tint: .orange,
                        isSelected: sortOption == option
                    ) {
                        sortOption = option
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDateRange != .allTime || sortOption != .dateDescending
    }

    private var activeSummary: String {
        var parts: [String] = []
        parts.append(selectedCategoryName)
        parts.append(selectedDateRange.localizedString)
        parts.append(sortOption.localizedString)
        return parts.joined(separator: " • ")
    }

    private var selectedCategoryName: String {
        guard let selectedCategory else { return L10n.string("expenses.filter.allCategories") }
        return categories.first { $0.id == selectedCategory }?.name ?? L10n.string(L10n.Expenses.selectedCategory)
    }

    private func sortIcon(for option: SortOption) -> String {
        switch option {
        case .dateDescending, .dateAscending:
            return "calendar"
        case .amountDescending, .amountAscending:
            return "indianrupeesign.circle.fill"
        case .titleAscending, .titleDescending:
            return "textformat"
        }
    }

    private func sortSubtitle(for option: SortOption) -> String {
        switch option {
        case .dateDescending:
            return L10n.string("expenses.sortSubtitle.newest")
        case .dateAscending:
            return L10n.string("expenses.sortSubtitle.oldest")
        case .amountDescending:
            return L10n.string("expenses.sortSubtitle.highestAmount")
        case .amountAscending:
            return L10n.string("expenses.sortSubtitle.lowestAmount")
        case .titleAscending:
            return L10n.string("expenses.sortSubtitle.aToZ")
        case .titleDescending:
            return L10n.string("expenses.sortSubtitle.zToA")
        }
    }
}

private struct FilterSheetSectionHeader: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.headline)

            Spacer()
        }
    }
}

private struct FilterSelectionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : tint)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? tint : .secondary.opacity(0.45))
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(isSelected ? 0.78 : 0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.42) : Color.white.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FilterOptionChip: View {
    let title: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : tint)
                        .frame(width: 32, height: 32)
                        .background(isSelected ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tint)
                    }
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground).opacity(isSelected ? 0.78 : 0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.42) : Color.white.opacity(0.24), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func filterSheetCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(.secondarySystemBackground).opacity(0.90))

                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.blue.opacity(0.07), Color.teal.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.09), radius: 16, x: 0, y: 9)
    }
}

#Preview {
    ExpenseListView()
}
