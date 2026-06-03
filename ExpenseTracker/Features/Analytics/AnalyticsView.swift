//
//  AnalyticsView.swift
//  Fintrax
//
//  Fintrax documentation: Builds the Analytics experience, including charts, AI-style spending analysis, and drill-down views.
//

import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var showingCategoryDetail = false
    @State private var hasRunAIAnalysis = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                analyticsHeader
                rangeSelector

                if viewModel.isLoading {
                    analyticsLoadingView
                } else if let error = viewModel.currentError {
                    analyticsErrorView(error)
                } else if let dashboard = viewModel.dashboardData, viewModel.hasExpensesInDateRange {
                    if let analysis = viewModel.spendingAIAnalysis {
                        AIAnalyzeSection(
                            analysis: analysis,
                            hasRunAnalysis: $hasRunAIAnalysis,
                            formatCurrency: viewModel.formatCurrency
                        )
                    }
                    chartExplorer(dashboard)
                    analyticsSummary(dashboard)
                    topCategoriesSection(dashboard)
                    recentEventsSection(dashboard)
                } else {
                    analyticsEmptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .background(AnalyticsBackground())
        .refreshable {
            await viewModel.refreshDashboard()
        }
        .task {
            await viewModel.loadDashboardData()
        }
        .sheet(isPresented: $showingCategoryDetail) {
            if let selectedCategory = viewModel.selectedCategory {
                AnalyticsCategoryDetailView(category: selectedCategory, viewModel: viewModel)
            }
        }
    }

    private var analyticsHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            AnimatedWalletSpendingIcon()

            VStack(alignment: .leading, spacing: 5) {
                Text("Spending Analytics")
                    .font(AppDesignSystem.Typography.title2)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text("Explore category breakdowns, monthly movement, and spending concentration.")
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .analyticsPanel(accent: AppDesignSystem.Colors.primary)
    }

    private var rangeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Date Range", systemImage: "calendar.badge.clock")
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DateRangeOption.allCases) { option in
                        Button {
                            viewModel.selectedDateRange = option
                            hasRunAIAnalysis = false
                        } label: {
                            AnalyticsRangeChip(title: option.rawValue, isSelected: viewModel.selectedDateRange == option)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .analyticsPanel(accent: AppDesignSystem.Colors.info)
    }

    private func chartExplorer(_ dashboard: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Explore", systemImage: "chart.pie.fill")
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()
            }

            Picker("Chart Type", selection: $viewModel.selectedChartType) {
                ForEach(DashboardViewModel.ChartType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            DashboardChartsView(
                dashboardData: dashboard,
                selectedChartType: viewModel.selectedChartType,
                onCategorySelected: { category in
                    viewModel.selectCategory(category)
                    showingCategoryDetail = true
                }
            )
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.primary)
    }

    private func analyticsSummary(_ dashboard: DashboardData) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            AnalyticsStatTile(
                title: "Total Spend",
                value: viewModel.formatCurrency(dashboard.totalSpending),
                subtitle: "\(dashboard.totalTransactions) expenses",
                icon: "creditcard.fill",
                tint: AppDesignSystem.Colors.primary
            )

            AnalyticsStatTile(
                title: "Average",
                value: dashboard.totalTransactions > 0 ? viewModel.formatCurrency(dashboard.totalSpending / Decimal(dashboard.totalTransactions)) : viewModel.formatCurrency(0),
                subtitle: "Per expense",
                icon: "waveform.path.ecg.rectangle.fill",
                tint: AppDesignSystem.Colors.info
            )

            AnalyticsStatTile(
                title: "Income",
                value: viewModel.formatCurrency(viewModel.selectedRangeIncome),
                subtitle: viewModel.selectedDateRange.rawValue,
                icon: "arrow.down.circle.fill",
                tint: AppDesignSystem.Colors.success
            )

            AnalyticsStatTile(
                title: "Net Flow",
                value: viewModel.formatCurrency(viewModel.selectedRangeNetCashFlow),
                subtitle: "Income minus spend",
                icon: viewModel.selectedRangeNetCashFlow >= 0 ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.downtrend.xyaxis.circle.fill",
                tint: viewModel.selectedRangeNetCashFlow >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error
            )
        }
    }

    private func topCategoriesSection(_ dashboard: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top Categories", systemImage: "tag.fill")
                .font(AppDesignSystem.Typography.headline)

            ForEach(dashboard.categoryBreakdown.prefix(5), id: \.0.id) { category, amount in
                Button {
                    viewModel.selectCategory(category)
                    showingCategoryDetail = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(category.displayColor)
                            .frame(width: 38, height: 38)
                            .background(category.displayColor.opacity(0.13), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.name)
                                .font(AppDesignSystem.Typography.calloutEmphasized)
                                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                            Text("\(String(format: "%.1f", dashboard.getCategorySpendingPercentage(for: category)))% of spending")
                                .font(AppDesignSystem.Typography.footnote)
                                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        }

                        Spacer()

                        Text(viewModel.formatCurrency(amount))
                            .font(AppDesignSystem.Typography.calloutEmphasized)
                            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    }
                    .padding(12)
                    .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.warning)
    }

    private func recentEventsSection(_ dashboard: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Events", systemImage: "clock.arrow.circlepath")
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()

                Text("\(dashboard.recentExpenses.count)")
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.info)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.info.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 10) {
                ForEach(dashboard.recentExpenses) { expense in
                    ExpenseRowView(expense: expense)
                }
            }
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.info)
    }

    private var analyticsLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading analytics...")
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .analyticsPanel(accent: AppDesignSystem.Colors.info)
    }

    private func analyticsErrorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(AppDesignSystem.Colors.error)
            Text("Could not load analytics")
                .font(AppDesignSystem.Typography.headline)
            Text(error.localizedDescription)
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .analyticsPanel(accent: AppDesignSystem.Colors.error)
    }

    private var analyticsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
            Text("No analytics yet")
                .font(AppDesignSystem.Typography.headline)
            Text("Add expenses to unlock category breakdowns and monthly trends.")
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .analyticsPanel(accent: AppDesignSystem.Colors.primary)
    }
}

private struct AnalyticsRangeChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(AppDesignSystem.Typography.footnote.weight(.bold))
            .foregroundStyle(isSelected ? .white : AppDesignSystem.Colors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AppDesignSystem.Gradients.primary : LinearGradient(colors: [
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.70),
                        AppDesignSystem.Colors.surfaceVariant.opacity(0.44)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.34) : AppDesignSystem.Colors.primary.opacity(0.15), lineWidth: 1)
            }
            .shadow(color: isSelected ? AppDesignSystem.Colors.primary.opacity(0.22) : Color.black.opacity(0.05), radius: 8, x: 0, y: 5)
    }
}

private struct AnalyticsStatTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                Text(value)
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(subtitle)
                    .font(AppDesignSystem.Typography.caption2)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .analyticsPanel(accent: tint)
    }
}

private struct AnimatedWalletSpendingIcon: View {
    @State private var coinLift = false
    @State private var pulse = false
    @State private var cardSlide = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppDesignSystem.Gradients.primary)
                .frame(width: 64, height: 64)
                .shadow(color: AppDesignSystem.Colors.primary.opacity(pulse ? 0.28 : 0.12), radius: pulse ? 16 : 8, x: 0, y: 8)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 34, height: 21)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.white.opacity(0.62), lineWidth: 1.4)
                )
                .offset(x: cardSlide ? 6 : 0, y: -6)

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .frame(width: 38, height: 28)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(AppDesignSystem.Colors.primary.opacity(0.88))
                    .frame(width: 15, height: 17)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.88))
                            .frame(width: 4, height: 4)
                    )
                    .offset(x: 4)
            }
            .offset(y: 7)

            Circle()
                .fill(AppDesignSystem.Colors.warning)
                .frame(width: 15, height: 15)
                .overlay(
                    Text("₹")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                )
                .offset(x: 18, y: coinLift ? -25 : -15)
                .opacity(coinLift ? 0.35 : 1)

            Circle()
                .stroke(Color.white.opacity(pulse ? 0.04 : 0.28), lineWidth: 1)
                .frame(width: pulse ? 58 : 44, height: pulse ? 58 : 44)
        }
        .frame(width: 68, height: 68)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                coinLift = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                cardSlide = true
            }
        }
    }
}

private struct AnalyticsCategoryDetailView: View {
    let category: Category
    let viewModel: DashboardViewModel
    @State private var expenses: [Expense] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    AnalyticsStatTile(
                        title: "Category Total",
                        value: viewModel.formatCurrency(viewModel.getCategorySpending(for: category)),
                        subtitle: "\(expenses.count) expenses",
                        icon: category.iconName,
                        tint: category.displayColor
                    )

                    ForEach(expenses) { expense in
                        ExpenseRowView(expense: expense)
                    }
                }
                .padding()
            }
            .background(AnalyticsBackground())
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                expenses = await viewModel.getExpensesForSelectedCategory()
            }
        }
    }
}

private struct AnalyticsBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.primary.opacity(0.10),
                    AppDesignSystem.Colors.info.opacity(0.08),
                    AppDesignSystem.Colors.warning.opacity(0.06)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
        }
    }
}

private extension View {
    func analyticsPanel(accent: Color) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.thinMaterial)

                LinearGradient(
                    colors: [accent.opacity(0.10), Color.clear, AppDesignSystem.Colors.elevatedSurface.opacity(0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: accent.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

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

/// One expandable recommendation or observation shown in the AI Analyze section.
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
                detail: "\(formatPercent(topCategory.percentage)) of your selected-period spend is in \(topCategory.category.name). This is the first category to optimize.",
                icon: topCategory.category.iconName,
                tint: topCategory.category.displayColor
            ))
        }

        insights.append(SpendingAIInsight(
            kind: .daily,
            title: "Daily Pace",
            value: formatCurrency(averageDailySpend),
            detail: "Your average daily spend for \(dateRange.rawValue.lowercased()) is \(formatCurrency(averageDailySpend)). At this pace, a 30-day month lands near \(formatCurrency(projectedMonthlySpend)).",
            icon: "calendar.day.timeline.left",
            tint: AppDesignSystem.Colors.info
        ))

        if let savingDay {
            insights.append(SpendingAIInsight(
                kind: .saving,
                title: "Saving Day",
                value: savingDay.date.formatted(date: .abbreviated, time: .omitted),
                detail: savingDay.amount == .zero ? "This was your cleanest day with no recorded spend. Try repeating the same routine once or twice a week." : "This was your lowest-spend day at \(formatCurrency(savingDay.amount)). Use it as a template for lighter spending days.",
                icon: "sparkles",
                tint: AppDesignSystem.Colors.success
            ))
        }

        if let peakDay {
            insights.append(SpendingAIInsight(
                kind: .pattern,
                title: "Peak Spend Day",
                value: peakDay.date.formatted(date: .abbreviated, time: .omitted),
                detail: "Your highest spending day was \(formatCurrency(peakDay.amount)). Review what happened that day and decide if it was planned or avoidable.",
                icon: "chart.line.uptrend.xyaxis",
                tint: AppDesignSystem.Colors.warning
            ))
        }

        if let biggestExpense {
            insights.append(SpendingAIInsight(
                kind: .pattern,
                title: "Largest Transaction",
                value: biggestExpense.formattedAmount(),
                detail: "\(biggestExpense.title) is your largest single spend. Big-ticket items are easier to plan than many small leaks, so mark these ahead in budgets.",
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
            return "Spending is running ahead of income"
        }
        if let topCategory, topCategory.percentage >= 0.45 {
            return "\(topCategory.category.name) is driving your spend"
        }
        return "Your spending pattern is ready to optimize"
    }

    private static func summaryText(totalSpend: Decimal, averageDailySpend: Decimal, days: Int, dateRange: DateRangeOption) -> String {
        "In \(dateRange.rawValue.lowercased()), Fintrax reviewed \(days) days and found \(formatCurrency(totalSpend)) total spend with a daily pace of \(formatCurrency(averageDailySpend))."
    }

    private static func recommendationValue(savingsRate: Double?) -> String {
        guard let savingsRate else { return "Set a cap" }
        return savingsRate >= 0.2 ? "Protect surplus" : "Tighten spend"
    }

    private static func recommendationDetail(
        savingsRate: Double?,
        averageDailySpend: Decimal,
        topCategory: SpendingCategoryInsight?
    ) -> String {
        let suggestedDailyCut = averageDailySpend * Decimal(0.10)
        if let savingsRate, savingsRate >= 0.2 {
            return "You are keeping a healthy surplus. Move part of it to savings first, then spend from the remainder."
        }

        if let topCategory {
            return "Try reducing \(topCategory.category.name) by 10%. That starts with a daily target cut near \(formatCurrency(suggestedDailyCut))."
        }

        return "Set a daily soft cap and review it every evening. A 10% daily reduction starts near \(formatCurrency(suggestedDailyCut))."
    }

    private static func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0"
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

private struct AIAnalyzeSection: View {
    let analysis: SpendingAIAnalysis
    @Binding var hasRunAnalysis: Bool
    let formatCurrency: (Decimal) -> String

    @State private var isScanning = false
    @State private var expandedInsightID: UUID?
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if hasRunAnalysis {
                summaryGrid
                    .transition(.opacity.combined(with: .move(edge: .top)))

                LazyVStack(spacing: 12) {
                    ForEach(Array(analysis.insights.enumerated()), id: \.element.id) { index, insight in
                        AIInsightCard(
                            insight: insight,
                            isExpanded: expandedInsightID == insight.id,
                            delay: Double(index) * 0.06
                        ) {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                expandedInsightID = expandedInsightID == insight.id ? nil : insight.id
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.primary)
        .animation(.spring(response: 0.48, dampingFraction: 0.86), value: hasRunAnalysis)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppDesignSystem.Gradients.primary)
                    .frame(width: 56, height: 56)
                    .shadow(color: AppDesignSystem.Colors.primary.opacity(pulse ? 0.28 : 0.08), radius: pulse ? 16 : 8, x: 0, y: 8)

                Image(systemName: isScanning ? "wand.and.stars.inverse" : "brain.head.profile")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isScanning ? 8 : 0))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("AI Analyze")
                    .font(AppDesignSystem.Typography.title3)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(hasRunAnalysis ? analysis.headline : "Run a quick local scan of your spending behaviour.")
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if hasRunAnalysis {
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        hasRunAnalysis = false
                        expandedInsightID = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.72), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close AI analysis")
            }

            Button {
                runAnalysis()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: isScanning ? "sparkles" : "play.fill")
                    Text(isScanning ? "Scanning" : (hasRunAnalysis ? "Refresh" : "Analyze"))
                }
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(AppDesignSystem.Gradients.primary, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isScanning)
        }
    }

    private var summaryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(analysis.summary)
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                AIFactTile(title: "Daily Spend", value: formatCurrency(analysis.averageDailySpend), icon: "calendar", tint: AppDesignSystem.Colors.info)
                AIFactTile(title: "30-Day Pace", value: formatCurrency(analysis.projectedMonthlySpend), icon: "speedometer", tint: AppDesignSystem.Colors.warning)
                AIFactTile(title: "Saving Day", value: analysis.savingDay?.date.formatted(.dateTime.weekday(.abbreviated)) ?? "N/A", icon: "leaf.fill", tint: AppDesignSystem.Colors.success)
                AIFactTile(title: "Savings Rate", value: analysis.savingsRate.map { "\(Int(($0 * 100).rounded()))%" } ?? "Add income", icon: "chart.line.uptrend.xyaxis", tint: AppDesignSystem.Colors.primary)
            }
        }
    }

    private func runAnalysis() {
        isScanning = true
        expandedInsightID = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                hasRunAnalysis = true
                isScanning = false
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

private struct AIFactTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                Text(value)
                    .font(AppDesignSystem.Typography.footnote.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct AIInsightCard: View {
    let insight: SpendingAIInsight
    let isExpanded: Bool
    let delay: Double
    let onTap: () -> Void

    @State private var appeared = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(insight.tint)
                        .frame(width: 40, height: 40)
                        .background(insight.tint.opacity(0.13), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(AppDesignSystem.Typography.caption.weight(.bold))
                            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                            .textCase(.uppercase)

                        Text(insight.value)
                            .font(AppDesignSystem.Typography.calloutEmphasized)
                            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(insight.tint)
                }

                if isExpanded {
                    Text(insight.detail)
                        .font(AppDesignSystem.Typography.footnote)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        insight.tint.opacity(0.11),
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.68)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(insight.tint.opacity(isExpanded ? 0.34 : 0.14), lineWidth: 1)
            }
            .scaleEffect(appeared ? 1 : 0.96)
            .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(delay)) {
                appeared = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
