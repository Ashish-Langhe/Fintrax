//
//  AnalyticsSections.swift
//  Fintrax
//

import SwiftUI

struct AnalyticsHeaderSection: View {
    var body: some View {
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
}

struct AnalyticsRangeSelector: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
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
}

struct AnalyticsStorySection: View {
    let dashboard: DashboardData
    let viewModel: DashboardViewModel

    private var averageSpend: Decimal {
        dashboard.totalTransactions > 0 ? dashboard.totalSpending / Decimal(dashboard.totalTransactions) : .zero
    }

    private var topCategory: (Category, Decimal)? {
        dashboard.categoryBreakdown.first
    }

    private var topShare: Double {
        topCategory.map { dashboard.getCategorySpendingPercentage(for: $0.0) * 100 } ?? 0
    }

    private var netFlow: Decimal {
        viewModel.selectedRangeNetCashFlow
    }

    private var netFlowPositive: Bool {
        netFlow >= 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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

                    Text(storySubtitle)
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
                AnalyticsStoryMetric(title: "Total Spend", value: viewModel.formatCurrency(dashboard.totalSpending), icon: "creditcard.fill", tint: AppDesignSystem.Colors.primary)
                AnalyticsStoryMetric(title: "Net Balance", value: viewModel.formatCurrency(netFlow), icon: netFlowPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill", tint: netFlowPositive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AnalyticsInsightChip(title: "Top Category", value: topCategory?.0.name ?? "None", detail: topCategory == nil ? L10n.string("No category data") : L10n.format("analytics.detail.percentOfSpend", String(format: "%.0f", topShare)), icon: topCategory?.0.iconName ?? "tag.fill", tint: topCategory?.0.displayColor ?? AppDesignSystem.Colors.primary)
                    AnalyticsInsightChip(title: "Avg Expense", value: viewModel.formatCurrency(averageSpend), detail: "Per transaction", icon: "waveform.path.ecg.rectangle.fill", tint: AppDesignSystem.Colors.info)
                    AnalyticsInsightChip(title: "Transactions", value: "\(dashboard.totalTransactions)", detail: dashboard.dateRange.localizedString, icon: "list.bullet.rectangle.fill", tint: AppDesignSystem.Colors.primary)
                    AnalyticsInsightChip(title: netFlowPositive ? "Healthy Flow" : "Watch Flow", value: netFlowPositive ? L10n.string("Positive") : L10n.string("Negative"), detail: "Income minus spend", icon: netFlowPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill", tint: netFlowPositive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .analyticsPanel(accent: netFlowPositive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning)
    }

    private var storySubtitle: String {
        guard let topCategory else {
            return L10n.string("Add more expenses to uncover category movement and spending concentration.")
        }

        return L10n.format("analytics.story.topCategory", topCategory.0.name, String(format: "%.0f%%", topShare), dashboard.totalTransactions)
    }
}

struct AnalyticsChartExplorerSection: View {
    let dashboard: DashboardData
    @Bindable var viewModel: DashboardViewModel
    let onCategorySelected: (Category) -> Void

    var body: some View {
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
                onCategorySelected: onCategorySelected
            )
            .padding(.top, viewModel.selectedChartType == .bar ? 10 : 0)
        }
        .padding(16)
        .analyticsPanel(accent: AppDesignSystem.Colors.primary)
    }
}

struct AnalyticsTopCategoriesSection: View {
    let dashboard: DashboardData
    let viewModel: DashboardViewModel
    let onCategorySelected: (Category) -> Void

    private var topCategories: [(Category, Decimal)] {
        Array(dashboard.categoryBreakdown.prefix(5))
    }

    private var remainingCount: Int {
        max(dashboard.categoryBreakdown.count - topCategories.count, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                tableHeader

                ForEach(Array(topCategories.enumerated()), id: \.element.0.id) { index, item in
                    let category = item.0
                    let amount = item.1
                    let share = dashboard.getCategorySpendingPercentage(for: category)

                    Button {
                        onCategorySelected(category)
                    } label: {
                        AnalyticsCategoryTableRow(rank: index + 1, category: category, amount: viewModel.formatCurrency(amount), share: share)
                    }
                    .buttonStyle(.plain)

                    if index < topCategories.count - 1 {
                        Divider().padding(.leading, 54)
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

    private var tableHeader: some View {
        HStack {
            Text("Category").frame(maxWidth: .infinity, alignment: .leading)
            Text("Spend").frame(width: 86, alignment: .trailing)
            Text("Share").frame(width: 54, alignment: .trailing)
        }
        .font(AppDesignSystem.Typography.caption2.weight(.bold))
        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
        .textCase(.uppercase)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}

struct AnalyticsRecentTransactionsSection: View {
    let dashboard: DashboardData
    let viewModel: DashboardViewModel

    private var categoryMap: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: dashboard.categoryBreakdown.map { ($0.0.id, $0.0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                tableHeader

                ForEach(Array(dashboard.recentExpenses.enumerated()), id: \.element.id) { index, expense in
                    AnalyticsRecentTransactionRow(expense: expense, category: categoryMap[expense.categoryID], amount: viewModel.formatCurrency(expense.amount))

                    if index < dashboard.recentExpenses.count - 1 {
                        Divider().padding(.leading, 48)
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

    private var tableHeader: some View {
        HStack {
            Text("Transaction").frame(maxWidth: .infinity, alignment: .leading)
            Text("Date").frame(width: 62, alignment: .trailing)
            Text("Amount").frame(width: 84, alignment: .trailing)
        }
        .font(AppDesignSystem.Typography.caption2.weight(.bold))
        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
        .textCase(.uppercase)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}
