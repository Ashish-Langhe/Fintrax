//
//  DashboardView.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI

/// Main dashboard view showing expense analytics and summaries
struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @StateObject private var navigationManager = NavigationManager()
    @State private var showingNotifications = false
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            ScrollView {
                LazyVStack(spacing: 24) {
                    headerSection
                    
                    // Loading state
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.currentError {
                        errorView(error)
                    } else if viewModel.hasData && viewModel.hasExpensesInDateRange {
                        dashboardContent
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle(L10n.Dashboard.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DashboardNotificationButton(count: viewModel.notificationCount) {
                        showingNotifications = true
                    }
                }
            }
            .refreshable {
                await viewModel.refreshDashboard()
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .task {
            loadingRotation = 360
            await viewModel.loadDashboardData()
        }
        .background(FintraxTabBackground(style: .dashboard))
        .fintraxAssistantPresence(entrance: .dashboardArrival)
        .sheet(isPresented: $showingNotifications) {
            DashboardNotificationCenterView(
                bills: viewModel.actionableBillNotifications,
                onMarkPaid: { bill in
                    await viewModel.markBillPaid(bill)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            if let dashboard = viewModel.dashboardData {
                DashboardHeroCard(
                    period: L10n.Dashboard.thisMonth,
                    spending: viewModel.formatCurrency(dashboard.totalSpending),
                    netFlow: viewModel.formatCurrency(viewModel.selectedRangeNetCashFlow),
                    transactionCount: dashboard.totalTransactions,
                    isPositiveFlow: viewModel.selectedRangeNetCashFlow >= 0
                )
            } else {
                DashboardHeroCard(
                    period: L10n.Dashboard.thisMonth,
                    spending: viewModel.formatCurrency(.zero),
                    netFlow: viewModel.formatCurrency(.zero),
                    transactionCount: 0,
                    isPositiveFlow: true
                )
            }

            if let dashboard = viewModel.dashboardData {
                DashboardInsightStrip(
                    topCategory: viewModel.topSpendingCategory,
                    averageTransaction: dashboard.totalTransactions > 0
                        ? viewModel.formatCurrency(dashboard.totalSpending / Decimal(dashboard.totalTransactions))
                        : viewModel.formatCurrency(.zero),
                    upcomingBills: viewModel.upcomingBillCount,
                    billTotal: viewModel.formatCurrency(viewModel.unpaidBillTotal)
                )
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                budgetLeftCard

                DashboardMetricCard(
                    title: L10n.Dashboard.income,
                    value: viewModel.formatCurrency(viewModel.selectedRangeIncome),
                    subtitle: L10n.Dashboard.cashReceived,
                    icon: "arrow.down.circle.fill",
                    accent: AppDesignSystem.Colors.success
                )
            }
        }
    }

    // MARK: - Budget Left Card
    
    @ViewBuilder
    private var budgetLeftCard: some View {
        DashboardMetricCard(
            title: L10n.Dashboard.budgetLeft,
            value: viewModel.hasMonthlyBudget ? viewModel.formatCurrency(viewModel.remainingBudget) : L10n.string(L10n.Dashboard.notSet),
            subtitle: viewModel.hasMonthlyBudget
                ? (viewModel.isOverBudget ? L10n.Dashboard.overBudget : LocalizedStringKey(L10n.format(L10n.Dashboard.daysLeft, viewModel.daysRemainingInMonth)))
                : L10n.Dashboard.setMonthlyBudget,
            icon: viewModel.hasMonthlyBudget ? (viewModel.isOverBudget ? "exclamationmark.triangle.fill" : "target") : "plus.circle.fill",
            accent: viewModel.hasMonthlyBudget ? (viewModel.isOverBudget ? .red : .green) : AppDesignSystem.Colors.warning
        )
    }
    
    // MARK: - Dashboard Content
    
    @ViewBuilder
    private var dashboardContent: some View {
        priorityBriefSection

        if let dashboard = viewModel.dashboardData {
            spendingOverviewSection(dashboard)
        }

        // Budget warnings (if any)
        if viewModel.hasBudgetWarnings {
            budgetWarningsSection
        }
        
    }

    private var priorityBriefSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L10n.Dashboard.priorityBrief, systemImage: "sparkles")
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()

                Text(L10n.Dashboard.actionable)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 10) {
                DashboardPriorityRow(
                    icon: viewModel.isOverBudget ? "exclamationmark.triangle.fill" : "target",
                    title: viewModel.hasMonthlyBudget ? (viewModel.isOverBudget ? L10n.Dashboard.budgetNeedsAttention : L10n.Dashboard.budgetOnTrack) : L10n.Dashboard.monthlyBudgetNotSet,
                    subtitle: viewModel.hasMonthlyBudget
                        ? LocalizedStringKey(L10n.format(L10n.Dashboard.budgetRemaining, viewModel.formatCurrency(viewModel.remainingBudget), viewModel.daysRemainingInMonth))
                        : L10n.Dashboard.setBudgetGuidance,
                    tint: viewModel.hasMonthlyBudget ? (viewModel.isOverBudget ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success) : AppDesignSystem.Colors.warning
                )

                DashboardPriorityRow(
                    icon: viewModel.upcomingBillCount > 0 ? "bell.badge.fill" : "bell.fill",
                    title: viewModel.upcomingBillCount > 0 ? LocalizedStringKey(L10n.format(L10n.Dashboard.billsDueSoon, viewModel.upcomingBillCount)) : L10n.Dashboard.noUrgentBills,
                    subtitle: viewModel.upcomingBillCount > 0
                        ? LocalizedStringKey(L10n.format(L10n.Dashboard.unpaidBills, viewModel.formatCurrency(viewModel.unpaidBillTotal)))
                        : L10n.Dashboard.clearNextFewDays,
                    tint: viewModel.upcomingBillCount > 0 ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.info
                )
            }
        }
        .padding(16)
        .dashboardPanel(accent: AppDesignSystem.Colors.primary)
    }

    private func spendingOverviewSection(_ dashboard: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(
                title: L10n.Dashboard.financialPulse,
                subtitle: dashboard.dateRange.localizedKey,
                icon: "waveform.path.ecg.rectangle.fill",
                tint: AppDesignSystem.Colors.info
            )

            DashboardPulseCard(
                spending: viewModel.formatCurrency(dashboard.totalSpending),
                income: viewModel.formatCurrency(viewModel.selectedRangeIncome),
                netFlow: viewModel.formatCurrency(viewModel.selectedRangeNetCashFlow),
                transactionCount: dashboard.totalTransactions,
                remainingBudget: viewModel.hasMonthlyBudget ? viewModel.formatCurrency(viewModel.remainingBudget) : L10n.string(L10n.Dashboard.notSet),
                budgetProgress: budgetProgress,
                isOverBudget: viewModel.isOverBudget,
                hasBudget: viewModel.hasMonthlyBudget
            )
        }
    }

    private var budgetProgress: Double {
        guard viewModel.hasMonthlyBudget else { return 0 }
        let remaining = NSDecimalNumber(decimal: max(viewModel.remainingBudget, .zero))
        let spent = NSDecimalNumber(decimal: viewModel.dashboardData?.totalSpending ?? .zero)
        let total = remaining.adding(spent)
        guard total.doubleValue > 0 else { return 0 }
        return min(max(spent.dividing(by: total).doubleValue, 0), 1)
    }
    // MARK: - Budget Warnings Section
    
    @ViewBuilder
    private var budgetWarningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: viewModel.hasExceededBudgets ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                    .foregroundColor(viewModel.hasExceededBudgets ? .red : .orange)
                Text(L10n.Dashboard.budgetAlerts)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if let dashboard = viewModel.dashboardData {
                ForEach(dashboard.budgetStatuses, id: \.0.id) { category, status in
                    switch status {
                    case .approachingLimit, .exceededLimit:
                        BudgetStatusIndicator(
                            category: category,
                            budgetStatus: status,
                            spending: viewModel.getCategorySpending(for: category),
                            onCategorySelected: { _ in
                                navigationManager.navigate(to: .analytics)
                            }
                        )
                    case .withinLimit:
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Support Views
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Enhanced loading indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .blue.opacity(0.8),
                                .blue.opacity(0.4),
                                .blue.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(loadingRotation))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: loadingRotation)
            }
            
            Text(L10n.Dashboard.loading)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .opacity(loadingTextOpacity)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: loadingTextOpacity)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.5))
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @State private var loadingRotation: Double = 0
    @State private var loadingTextOpacity: Double = 1.0
    
    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(L10n.Dashboard.errorTitle)
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(L10n.Dashboard.retry) {
                Task {
                    await viewModel.loadDashboardData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(L10n.Dashboard.emptyTitle)
                .font(.headline)
            Text(L10n.Dashboard.emptyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Navigation Methods
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .addExpense(_):
            Text(L10n.Dashboard.addEditExpense)
                .navigationTitle(L10n.Dashboard.expenseDetails)
        case .expenseList:
            ExpenseListView()
        case .analytics:
            AnalyticsView()
        case .categoryManagement:
            CategoryManagementView()
        case .budgetSettings:
            BudgetSettingsPlaceholder()
        case .settings:
            SettingsPlaceholder()
        case .securitySettings:
            SecuritySettingsPlaceholder()
        case .exportData:
            ExportDataPlaceholder()
        case .dashboard:
            // Should not happen as dashboard is the root
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
