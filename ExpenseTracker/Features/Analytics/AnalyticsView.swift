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
                    analyticsStorySection(dashboard)
                    chartExplorer(dashboard)
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
        .background(FintraxTabBackground(style: .analytics))
        .fintraxAssistantPresence()
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
                        } label: {
                            AnalyticsRangeChip(title: option.localizedString, isSelected: viewModel.selectedDateRange == option)
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

    private func analyticsStorySection(_ dashboard: DashboardData) -> some View {
        let averageSpend = dashboard.totalTransactions > 0
            ? dashboard.totalSpending / Decimal(dashboard.totalTransactions)
            : Decimal.zero
        let topCategory = dashboard.categoryBreakdown.first
        let topShare = topCategory.map { dashboard.getCategorySpendingPercentage(for: $0.0) * 100 } ?? 0
        let netFlow = viewModel.selectedRangeNetCashFlow
        let netFlowPositive = netFlow >= 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppDesignSystem.Gradients.primary)
                        .frame(width: 44, height: 44)

                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Spending Story")
                        .font(AppDesignSystem.Typography.headline)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text(storySubtitle(for: dashboard, topCategory: topCategory, topShare: topShare))
                        .font(AppDesignSystem.Typography.caption)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(viewModel.selectedDateRange.localizedKey)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 10) {
                AnalyticsStoryMetric(
                    title: "Total Spend",
                    value: viewModel.formatCurrency(dashboard.totalSpending),
                    icon: "creditcard.fill",
                    tint: AppDesignSystem.Colors.primary
                )

                AnalyticsStoryMetric(
                    title: "Net Balance",
                    value: viewModel.formatCurrency(netFlow),
                    icon: netFlowPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    tint: netFlowPositive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AnalyticsInsightChip(
                        title: "Top Category",
                        value: topCategory?.0.name ?? "None",
                        detail: topCategory == nil ? L10n.string("No category data") : L10n.format("analytics.detail.percentOfSpend", String(format: "%.0f", topShare)),
                        icon: topCategory?.0.iconName ?? "tag.fill",
                        tint: topCategory?.0.displayColor ?? AppDesignSystem.Colors.primary
                    )

                    AnalyticsInsightChip(
                        title: "Avg Expense",
                        value: viewModel.formatCurrency(averageSpend),
                        detail: "Per transaction",
                        icon: "waveform.path.ecg.rectangle.fill",
                        tint: AppDesignSystem.Colors.info
                    )

                    AnalyticsInsightChip(
                        title: "Transactions",
                        value: "\(dashboard.totalTransactions)",
                        detail: dashboard.dateRange.localizedString,
                        icon: "list.bullet.rectangle.fill",
                        tint: AppDesignSystem.Colors.primary
                    )

                    AnalyticsInsightChip(
                        title: netFlowPositive ? "Healthy Flow" : "Watch Flow",
                        value: netFlowPositive ? L10n.string("Positive") : L10n.string("Negative"),
                        detail: "Income minus spend",
                        icon: netFlowPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        tint: netFlowPositive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error
                    )
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .analyticsPanel(accent: netFlowPositive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning)
    }

    private func storySubtitle(
        for dashboard: DashboardData,
        topCategory: (Category, Decimal)?,
        topShare: Double
    ) -> String {
        guard let topCategory else {
            return L10n.string("Add more expenses to uncover category movement and spending concentration.")
        }

        return L10n.format(
            "analytics.story.topCategory",
            topCategory.0.name,
            String(format: "%.0f%%", topShare),
            dashboard.totalTransactions
        )
    }

    private func chartExplorer(_ dashboard: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Visual Explorer", systemImage: "chart.pie.fill")
                        .font(AppDesignSystem.Typography.headline)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text("Tap a segment or quick chip to open category detail.")
                        .font(AppDesignSystem.Typography.caption)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }

                Spacer()
            }

            Picker("Chart Type", selection: $viewModel.selectedChartType) {
                ForEach(DashboardViewModel.ChartType.allCases) { type in
                    Text(LocalizedStringKey(type.displayName)).tag(type)
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
            .padding(.top, viewModel.selectedChartType == .bar ? 10 : 0)
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.primary)
    }

    private func topCategoriesSection(_ dashboard: DashboardData) -> some View {
        let topCategories = Array(dashboard.categoryBreakdown.prefix(5))
        let remainingCount = max(dashboard.categoryBreakdown.count - topCategories.count, 0)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Category Table", systemImage: "tablecells.fill")
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()

                Text(L10n.format("analytics.categories.topCount", topCategories.count))
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.warning)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.warning.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 0) {
                HStack {
                    Text("Category")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Spend")
                        .frame(width: 86, alignment: .trailing)
                    Text("Share")
                        .frame(width: 54, alignment: .trailing)
                }
                .font(AppDesignSystem.Typography.caption2.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)

                ForEach(Array(topCategories.enumerated()), id: \.element.0.id) { index, item in
                    let category = item.0
                    let amount = item.1
                    let share = dashboard.getCategorySpendingPercentage(for: category)

                    Button {
                        viewModel.selectCategory(category)
                        showingCategoryDetail = true
                    } label: {
                        AnalyticsCategoryTableRow(
                            rank: index + 1,
                            category: category,
                            amount: viewModel.formatCurrency(amount),
                            share: share
                        )
                    }
                    .buttonStyle(.plain)

                    if index < topCategories.count - 1 {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
            .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppDesignSystem.Colors.warning.opacity(0.12), lineWidth: 1)
            }

            if remainingCount > 0 {
                Text(L10n.format("analytics.categories.more", remainingCount))
                    .font(AppDesignSystem.Typography.caption.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.warning)
    }

    private func recentEventsSection(_ dashboard: DashboardData) -> some View {
        let categoryMap = Dictionary(uniqueKeysWithValues: dashboard.categoryBreakdown.map { ($0.0.id, $0.0) })

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Transactions", systemImage: "receipt.fill")
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

            VStack(spacing: 0) {
                HStack {
                    Text("Transaction")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Date")
                        .frame(width: 62, alignment: .trailing)
                    Text("Amount")
                        .frame(width: 84, alignment: .trailing)
                }
                .font(AppDesignSystem.Typography.caption2.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)

                ForEach(Array(dashboard.recentExpenses.enumerated()), id: \.element.id) { index, expense in
                    AnalyticsRecentTransactionRow(
                        expense: expense,
                        category: categoryMap[expense.categoryID],
                        amount: viewModel.formatCurrency(expense.amount)
                    )

                    if index < dashboard.recentExpenses.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppDesignSystem.Colors.info.opacity(0.12), lineWidth: 1)
            }
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.info)
    }

    private struct AnalyticsCategoryTableRow: View {
        let rank: Int
        let category: Category
        let amount: String
        let share: Double

        private var shareText: String {
            String(format: "%.0f%%", share * 100)
        }

        var body: some View {
            VStack(spacing: 7) {
                HStack(spacing: 10) {
                    Text("\(rank)")
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(category.displayColor)
                        .frame(width: 22, height: 22)
                        .background(category.displayColor.opacity(0.12), in: Circle())

                    Image(systemName: category.iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(category.displayColor)
                        .frame(width: 24, height: 24)

                    Text(category.name)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(amount)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .frame(width: 86, alignment: .trailing)

                    Text(shareText)
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(category.displayColor)
                        .frame(width: 54, alignment: .trailing)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppDesignSystem.Colors.surfaceVariant.opacity(0.72))

                        Capsule()
                            .fill(category.displayColor.gradient)
                            .frame(width: proxy.size.width * min(max(share, 0), 1))
                    }
                }
                .frame(height: 4)
                .padding(.leading, 56)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(category.name), \(amount), \(shareText) of spending")
        }
    }

    private struct AnalyticsRecentTransactionRow: View {
        let expense: Expense
        let category: Category?
        let amount: String

        private var dateText: String {
            expense.date.formatted(.dateTime.day().month(.abbreviated))
        }

        private var iconName: String {
            category?.iconName ?? "creditcard.fill"
        }

        private var tint: Color {
            category?.displayColor ?? AppDesignSystem.Colors.info
        }

        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(expense.title)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(category?.name ?? L10n.string("Uncategorized"))
                        .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(dateText)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .frame(width: 62, alignment: .trailing)

                Text(amount)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.error)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .frame(width: 84, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(expense.title), \(category?.name ?? L10n.string("Uncategorized")), \(dateText), \(amount)")
        }
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
        Text(LocalizedStringKey(title))
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

private struct AnalyticsStoryMetric: View {
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
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct AnalyticsInsightChip: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Text(LocalizedStringKey(detail))
                    .font(AppDesignSystem.Typography.caption2.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 172, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
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
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                Text(value)
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(LocalizedStringKey(subtitle))
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
                        subtitle: L10n.format("analytics.category.expenses", expenses.count),
                        icon: category.iconName,
                        tint: category.displayColor
                    )

                    ForEach(expenses) { expense in
                        ExpenseRowView(expense: expense)
                    }
                }
                .padding()
            }
            .background(FintraxTabBackground(style: .analytics))
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


#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
