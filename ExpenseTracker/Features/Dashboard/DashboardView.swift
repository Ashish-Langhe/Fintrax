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
            .navigationTitle("Dashboard")
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
                    period: "This Month",
                    spending: viewModel.formatCurrency(dashboard.totalSpending),
                    netFlow: viewModel.formatCurrency(viewModel.selectedRangeNetCashFlow),
                    transactionCount: dashboard.totalTransactions,
                    isPositiveFlow: viewModel.selectedRangeNetCashFlow >= 0
                )
            } else {
                DashboardHeroCard(
                    period: "This Month",
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
                    title: "Income",
                    value: viewModel.formatCurrency(viewModel.selectedRangeIncome),
                    subtitle: "Cash received",
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
            title: "Budget Left",
            value: viewModel.hasMonthlyBudget ? viewModel.formatCurrency(viewModel.remainingBudget) : "Not set",
            subtitle: viewModel.hasMonthlyBudget
                ? (viewModel.isOverBudget ? "Over budget" : "\(viewModel.daysRemainingInMonth) days left")
                : "Set a monthly budget",
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
                Label("Priority Brief", systemImage: "sparkles")
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()

                Text("Actionable")
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 10) {
                DashboardPriorityRow(
                    icon: viewModel.isOverBudget ? "exclamationmark.triangle.fill" : "target",
                    title: viewModel.hasMonthlyBudget ? (viewModel.isOverBudget ? "Budget needs attention" : "Budget is on track") : "Monthly budget not set",
                    subtitle: viewModel.hasMonthlyBudget
                        ? "\(viewModel.formatCurrency(viewModel.remainingBudget)) left with \(viewModel.daysRemainingInMonth) days remaining"
                        : "Set a monthly budget to unlock stronger guidance.",
                    tint: viewModel.hasMonthlyBudget ? (viewModel.isOverBudget ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success) : AppDesignSystem.Colors.warning
                )

                DashboardPriorityRow(
                    icon: viewModel.upcomingBillCount > 0 ? "bell.badge.fill" : "bell.fill",
                    title: viewModel.upcomingBillCount > 0 ? "\(viewModel.upcomingBillCount) bills due soon" : "No urgent bill reminders",
                    subtitle: viewModel.upcomingBillCount > 0
                        ? "\(viewModel.formatCurrency(viewModel.unpaidBillTotal)) unpaid across open bills"
                        : "You are clear for the next few days.",
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
                title: "Financial Pulse",
                subtitle: dashboard.dateRange.rawValue,
                icon: "waveform.path.ecg.rectangle.fill",
                tint: AppDesignSystem.Colors.info
            )

            DashboardPulseCard(
                spending: viewModel.formatCurrency(dashboard.totalSpending),
                income: viewModel.formatCurrency(viewModel.selectedRangeIncome),
                netFlow: viewModel.formatCurrency(viewModel.selectedRangeNetCashFlow),
                transactionCount: dashboard.totalTransactions,
                remainingBudget: viewModel.hasMonthlyBudget ? viewModel.formatCurrency(viewModel.remainingBudget) : "Not set",
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
                Text("Budget Alerts")
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
            
            Text("Loading dashboard...")
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
            Text("Error Loading Dashboard")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
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
            Text("No Expenses Yet")
                .font(.headline)
            Text("Start adding expenses to see your spending analytics here.")
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
            Text("Add/Edit Expense")
                .navigationTitle("Expense Details")
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

// MARK: - Supporting Views

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(expense.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatCurrency(expense.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.thinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.1))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            Color.red.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.3))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
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
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .scaleEffect(1.0)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0.00"
    }
}

private struct DashboardHeroCard: View {
    let period: String
    let spending: String
    let netFlow: String
    let transactionCount: Int
    let isPositiveFlow: Bool

    @State private var hasAppeared = false
    @State private var glowPulse = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))

                        Text(period)
                            .font(AppDesignSystem.Typography.caption.weight(.bold))
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(.white.opacity(0.78))

                    Text("Money Snapshot")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("Current month spending overview")
                        .font(AppDesignSystem.Typography.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 58, height: 58)

                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, value: glowPulse)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Total Spent")
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .textCase(.uppercase)

                Text(spending)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 10) {
                DashboardHeroMiniStat(
                    title: "Entries",
                    value: "\(transactionCount)",
                    icon: "list.bullet.rectangle.fill",
                    revealDelay: 0.08
                )

                DashboardHeroMiniStat(
                    title: "Net Balance",
                    value: netFlow,
                    icon: isPositiveFlow ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill",
                    tint: isPositiveFlow ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning,
                    revealDelay: 0.16
                )
            }

            HStack(spacing: 9) {
                Image(systemName: isPositiveFlow ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.bold))

                Text(isPositiveFlow ? "Income is higher than spending" : "Spending is higher than income")
                    .font(AppDesignSystem.Typography.calloutEmphasized)

                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
        }
        .padding(22)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primaryDark,
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.info.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 142, weight: .bold))
                    .foregroundStyle(.white.opacity(0.055))
                    .rotationEffect(.degrees(glowPulse ? -4 : 2))
                    .offset(x: glowPulse ? 80 : 88, y: glowPulse ? 22 : 30)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 160, height: 160)
                    .scaleEffect(glowPulse ? 1.08 : 0.96)
                    .offset(x: -112, y: 126)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: AppDesignSystem.Colors.primary.opacity(glowPulse ? 0.28 : 0.18), radius: glowPulse ? 30 : 22, x: 0, y: 14)
        .scaleEffect(isPressed ? 0.985 : 1)
        .offset(y: hasAppeared ? 0 : 10)
        .opacity(hasAppeared ? 1 : 0)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) {
                hasAppeared = true
            }

            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct DashboardHeroMiniStat: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = .white
    var revealDelay: Double = 0

    @State private var hasAppeared = false

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint == .white ? .white : tint)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .textCase(.uppercase)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        }
        .offset(y: hasAppeared ? 0 : 8)
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.84).delay(revealDelay)) {
                hasAppeared = true
            }
        }
    }
}

private struct DashboardInsightStrip: View {
    let topCategory: (Category, Decimal)?
    let averageTransaction: String
    let upcomingBills: Int
    let billTotal: String

    var body: some View {
        HStack(spacing: 10) {
            DashboardMiniInsight(
                icon: topCategory?.0.iconName ?? "tag.fill",
                title: "Top",
                value: topCategory?.0.name ?? "None",
                tint: topCategory?.0.displayColor ?? AppDesignSystem.Colors.primary
            )

            DashboardMiniInsight(
                icon: "waveform.path.ecg.rectangle.fill",
                title: "Average",
                value: averageTransaction,
                tint: AppDesignSystem.Colors.info
            )

            DashboardMiniInsight(
                icon: upcomingBills > 0 ? "bell.badge.fill" : "bell.fill",
                title: upcomingBills > 0 ? "\(upcomingBills) Due" : "Bills",
                value: upcomingBills > 0 ? billTotal : "Clear",
                tint: upcomingBills > 0 ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.success
            )
        }
    }
}

private struct DashboardMiniInsight: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .dashboardPanel(accent: tint, cornerRadius: 18)
    }
}

private struct DashboardSectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(subtitle)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
    }
}

private struct DashboardPulseCard: View {
    let spending: String
    let income: String
    let netFlow: String
    let transactionCount: Int
    let remainingBudget: String
    let budgetProgress: Double
    let isOverBudget: Bool
    let hasBudget: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                DashboardPulseMetric(
                    title: "Spent",
                    value: spending,
                    icon: "arrow.up.forward.circle.fill",
                    tint: AppDesignSystem.Colors.error
                )

                DashboardPulseMetric(
                    title: "Income",
                    value: income,
                    icon: "arrow.down.forward.circle.fill",
                    tint: AppDesignSystem.Colors.success
                )
            }

            HStack(spacing: 12) {
                DashboardPulseMetric(
                    title: "Net Flow",
                    value: netFlow,
                    icon: "equal.circle.fill",
                    tint: AppDesignSystem.Colors.info
                )

                DashboardPulseMetric(
                    title: "Entries",
                    value: "\(transactionCount)",
                    icon: "list.bullet.rectangle.fill",
                    tint: AppDesignSystem.Colors.primary
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(hasBudget ? "Monthly Budget" : "Budget Setup", systemImage: hasBudget ? "target" : "plus.circle.fill")
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(remainingBudget)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(isOverBudget ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.textPrimary)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppDesignSystem.Colors.surfaceVariant.opacity(0.76))

                        Capsule()
                            .fill((isOverBudget ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).gradient)
                            .frame(width: max(8, proxy.size.width * budgetProgress))
                    }
                }
                .frame(height: 9)

                Text(hasBudget ? (isOverBudget ? "Spending has crossed the monthly plan" : "Spending pace is within the monthly plan") : "Set a monthly budget to track pace")
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }
            .padding(12)
            .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.56), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(14)
        .dashboardPanel(accent: AppDesignSystem.Colors.info)
    }
}

private struct DashboardPulseMetric: View {
    let title: String
    let value: String
    let icon: String
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

                Text(value)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct DashboardPriorityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(subtitle)
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.title2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(accent.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: accent.opacity(0.28), radius: 8, x: 0, y: 5)
            }

            HStack {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(accent.opacity(0.10), in: Capsule())
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 7)
    }
}

struct DashboardTexturedBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                Image(systemName: "rectangle.grid.2x2.fill")
                    .font(.system(size: 78, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.primary.opacity(0.08))
                    .rotationEffect(.degrees(drift ? -9 : 7))
                    .offset(x: size.width * 0.62, y: drift ? 76 : 48)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.success.opacity(0.12))
                    .rotationEffect(.degrees(drift ? 9 : -7))
                    .offset(x: size.width * 0.06, y: size.height * 0.58)

                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 94, weight: .regular))
                    .foregroundStyle(AppDesignSystem.Colors.warning.opacity(0.12))
                    .rotationEffect(.degrees(drift ? 6 : -4))
                    .offset(x: size.width * 0.66, y: size.height * 0.74)

                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.info.opacity(0.10))
                    .rotationEffect(.degrees(drift ? -8 : 5))
                    .offset(x: size.width * 0.08, y: drift ? size.height * 0.23 : size.height * 0.20)

                Circle()
                    .stroke(AppDesignSystem.Colors.info.opacity(0.14), lineWidth: 18)
                    .frame(width: 210, height: 210)
                    .offset(x: drift ? -62 : -84, y: 86)

                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(AppDesignSystem.Colors.primary.opacity(0.08), lineWidth: 14)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(drift ? 18 : 9))
                    .offset(x: size.width - 96, y: size.height * 0.18)

                Circle()
                    .stroke(AppDesignSystem.Colors.success.opacity(0.10), lineWidth: 12)
                    .frame(width: 154, height: 154)
                    .offset(x: size.width - 52, y: size.height * 0.52)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
        }
    }
}

extension View {
    func dashboardPanel(accent: Color, cornerRadius: CGFloat = 22) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)

                LinearGradient(
                    colors: [
                        accent.opacity(0.10),
                        Color.clear,
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: accent.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Category Detail View

private struct CategoryDetailView: View {
    let category: Category
    @State private var expenses: [Expense]
    let viewModel: DashboardViewModel
    
    init(category: Category, expenses: [Expense], viewModel: DashboardViewModel) {
        self.category = category
        self._expenses = State(initialValue: expenses)
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category header
                    categoryHeader
                    
                    // Budget status (if available)
                    if let budgetStatus = viewModel.getBudgetStatus(for: category) {
                        budgetStatusView(budgetStatus)
                    }
                    
                    // Expenses list
                    expensesList
                }
                .padding()
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                expenses = await viewModel.getExpensesForSelectedCategory()
            }
        }
    }
    
    @ViewBuilder
    private var categoryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Spending")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(viewModel.formatCurrency(viewModel.getCategorySpending(for: category)))
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("\(expenses.count) transactions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func budgetStatusView(_ status: BudgetStatus) -> some View {
        HStack(spacing: 12) {
            Image(systemName: {
                switch status {
                case .exceededLimit:
                    return "exclamationmark.triangle.fill"
                case .approachingLimit:
                    return "exclamationmark.triangle.fill"
                case .withinLimit:
                    return "info.circle.fill"
                }
            }())
            .foregroundColor({
                switch status {
                case .exceededLimit:
                    return .red
                case .approachingLimit:
                    return .orange
                case .withinLimit:
                    return .blue
                }
            }())
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget Status")
                    .font(.headline)
                Text(status.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var expensesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(expenses) { expense in
                ExpenseRowView(expense: expense)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
