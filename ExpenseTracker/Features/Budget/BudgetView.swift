//
//  BudgetView.swift
//  Fintrax
//
//  Fintrax documentation: Builds budget creation, update, progress, and budget insight UI.
//

import SwiftUI
import Observation

/// Main budget view for managing monthly budget
struct BudgetView: View {
    @State private var viewModel = BudgetViewModel()
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                FintraxTabBackground(style: .budget)

                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Current budget display card
                        budgetDisplayCard
                        
                        // Budget status and insights
                        if viewModel.hasBudget {
                            budgetStatusSection
                            spendingInsightsSection
                        } else {
                            emptyBudgetState
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasBudget {
                        Menu {
                            Button("Edit Budget", systemImage: "pencil") {
                                showingEditSheet = true
                            }
                            
                            Button("Delete Budget", systemImage: "trash", role: .destructive) {
                                showingDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else {
                        Button("Set Budget", systemImage: "plus") {
                            showingEditSheet = true
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadBudgetData()
            }
            .sheet(isPresented: $showingEditSheet) {
                BudgetEditSheet(
                    currentBudget: viewModel.currentBudget,
                    onSave: { amount in
                        let result: String?
                        if viewModel.currentBudget == nil {
                            result = await viewModel.setBudget(amount)
                        } else {
                            result = await viewModel.updateBudget(amount)
                        }

                        if let result {
                            successMessage = result
                            showingSuccessAlert = true
                            return true
                        }

                        return false
                    }
                )
            }
            .overlay {
                if showingSuccessAlert {
                    BudgetSuccessOverlay(
                        message: successMessage,
                        onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                showingSuccessAlert = false
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .fintraxModal(
                isPresented: showingDeleteAlert,
                title: L10n.string("Delete Budget?"),
                message: L10n.string("This removes your monthly budget. Expense history stays untouched, but budget progress will disappear."),
                icon: "trash.fill",
                tint: AppDesignSystem.Colors.error,
                primaryAction: FintraxModalAction(title: L10n.string("Delete Budget"), icon: "trash.fill", tint: AppDesignSystem.Colors.error, isDestructive: true) {
                    showingDeleteAlert = false
                    Task {
                        await viewModel.deleteBudget()
                        if viewModel.currentError == nil {
                            successMessage = L10n.string("Budget deleted successfully")
                            showingSuccessAlert = true
                        }
                    }
                },
                secondaryAction: FintraxModalAction(title: L10n.string("Keep Budget"), icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
                    showingDeleteAlert = false
                }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: showingSuccessAlert)
        }
        .task {
            await viewModel.loadBudgetData()
        }
    }
    
    // MARK: - Budget Display Card
    
    @ViewBuilder
    private var budgetDisplayCard: some View {
        VStack(spacing: 16) {
            if let budget = viewModel.currentBudget {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Monthly Budget")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Text(viewModel.formatCurrency(budget.amount))
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.70)

                            Text("Set on \(budget.setAt, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: viewModel.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                            .font(.title2)
                            .foregroundStyle(viewModel.isOverBudget ? .red : .green)
                            .frame(width: 48, height: 48)
                            .background((viewModel.isOverBudget ? Color.red : Color.green).opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppDesignSystem.Colors.controlFill)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [budgetAccentColor.opacity(0.75), budgetAccentColor],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: proxy.size.width * min(viewModel.budgetUsagePercentage, 1.0))
                            }
                        }
                        .frame(height: 12)

                        HStack {
                            Text("\(Int(viewModel.budgetUsagePercentage * 100))% used")
                                .fontWeight(.semibold)
                                .foregroundStyle(budgetAccentColor)
                            Spacer()
                            Text(LocalizedStringKey(viewModel.isOverBudget ? "Limit exceeded" : "On track"))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }

                    HStack {
                        BudgetMiniStat(
                            title: "Spent",
                            value: viewModel.formatCurrency(viewModel.spentThisMonth),
                            icon: "creditcard.fill",
                            tint: .red
                        )

                        BudgetMiniStat(
                            title: viewModel.isOverBudget ? "Over" : "Left",
                            value: viewModel.formatCurrency(abs(viewModel.remainingBudget)),
                            icon: viewModel.isOverBudget ? "arrow.up.right.circle.fill" : "wallet.pass.fill",
                            tint: viewModel.isOverBudget ? .red : .green
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .budgetCard()
            }
        }
    }

    private var budgetAccentColor: Color {
        if viewModel.isOverBudget {
            return .red
        }

        if viewModel.budgetUsagePercentage >= 0.8 {
            return .orange
        }

        return .green
    }
    
    // MARK: - Budget Status Section
    
    @ViewBuilder
    private var budgetStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BudgetSectionHeader(title: "Budget Status", icon: "gauge.with.dots.needle.67percent", tint: budgetAccentColor)
            
            if let status = viewModel.budgetStatus {
                BudgetStatusCard(
                    status: status,
                    remainingBudget: viewModel.remainingBudget,
                    spentThisMonth: viewModel.spentThisMonth,
                    currencyFormatter: viewModel.formatCurrency
                )
            }
        }
        .padding(18)
        .budgetCard(cornerRadius: 20)
    }
    
    // MARK: - Spending Insights Section
    
    @ViewBuilder
    private var spendingInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BudgetSectionHeader(title: "Spending Insights", icon: "chart.bar.xaxis", tint: .blue)

            if !viewModel.budgetIntelligenceInsights.isEmpty {
                VStack(spacing: 10) {
                    ForEach(viewModel.budgetIntelligenceInsights) { insight in
                        BudgetIntelligenceRow(insight: insight)
                    }
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InsightCard(
                    title: "Spent This Month",
                    value: viewModel.formatCurrency(viewModel.spentThisMonth),
                    subtitle: L10n.format("budget.insight.transactions", viewModel.currentMonthTransactions),
                    icon: "creditcard.fill",
                    tint: .red
                )
                
                InsightCard(
                    title: viewModel.isOverBudget ? "Over Budget" : "Remaining Budget",
                    value: viewModel.formatCurrency(abs(viewModel.remainingBudget)),
                    subtitle: viewModel.isOverBudget ? L10n.string("Over budget") : L10n.format("budget.insight.daysLeft", BudgetCalculations.daysRemainingInCurrentMonth()),
                    icon: viewModel.isOverBudget ? "exclamationmark.triangle.fill" : "wallet.pass.fill",
                    tint: viewModel.isOverBudget ? .red : .green
                )
                
                if let recommendedDaily = viewModel.recommendedDailySpending {
                    InsightCard(
                        title: "Daily Recommendation",
                        value: viewModel.formatCurrency(recommendedDaily),
                        subtitle: "To stay on track",
                        icon: "calendar.badge.clock",
                        tint: .blue
                    )
                }
                
                InsightCard(
                    title: "Average Expense",
                    value: viewModel.formatCurrency(viewModel.averageTransactionAmount),
                    subtitle: "Across this month",
                    icon: "chart.line.uptrend.xyaxis",
                    tint: .teal
                )
            }
        }
        .padding(18)
        .budgetCard(cornerRadius: 20)
    }
    
    // MARK: - Empty Budget State
    
    @ViewBuilder
    private var emptyBudgetState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 104, height: 104)

                Image(systemName: "target")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            Text("No Budget Set")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Set a monthly budget to track your spending and get personalized insights.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Set Up Budget") {
                showingEditSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(26)
        .frame(maxWidth: .infinity)
        .budgetCard(cornerRadius: 24)
        .padding(.top, 14)
    }
}

// MARK: - Supporting Views

private struct BudgetStatusCard: View {
    let status: BudgetStatus
    let remainingBudget: Decimal
    let spentThisMonth: Decimal
    let currencyFormatter: (Decimal) -> String
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: statusIcon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 42, height: 42)
                    .background(statusColor.opacity(0.12), in: Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(remainingBudget < 0 ? L10n.format("budget.status.overBy", currencyFormatter(abs(remainingBudget))) : L10n.format("budget.status.remaining", currencyFormatter(remainingBudget)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }

            HStack(spacing: 10) {
                BudgetMiniStat(
                    title: "Spent",
                    value: currencyFormatter(spentThisMonth),
                    icon: "creditcard.fill",
                    tint: .red
                )

                BudgetMiniStat(
                    title: remainingBudget < 0 ? "Over" : "Remaining",
                    value: currencyFormatter(abs(remainingBudget)),
                    icon: remainingBudget < 0 ? "arrow.up.right.circle.fill" : "wallet.pass.fill",
                    tint: remainingBudget < 0 ? .red : .green
                )
            }
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .withinLimit:
            return "checkmark.circle.fill"
        case .approachingLimit:
            return "exclamationmark.triangle.fill"
        case .exceededLimit:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .withinLimit:
            return .green
        case .approachingLimit:
            return .orange
        case .exceededLimit:
            return .red
        }
    }
}

private struct BudgetIntelligenceRow: View {
    let insight: BudgetIntelligenceInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(insight.message)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        }
    }

    private var tint: Color {
        switch insight.tone {
        case .positive:
            return AppDesignSystem.Colors.success
        case .warning:
            return AppDesignSystem.Colors.warning
        case .critical:
            return AppDesignSystem.Colors.error
        case .action:
            return AppDesignSystem.Colors.primary
        case .neutral:
            return AppDesignSystem.Colors.info
        }
    }
}

private struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(title))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            
                Text(value)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                
                Text(LocalizedStringKey(subtitle))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .fintraxControlFill(cornerRadius: 16)
    }
}

private struct BudgetMiniStat: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 27, height: 27)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .fintraxControlFill(cornerRadius: 14)
    }
}

private struct BudgetSuccessOverlay: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.20)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 82, height: 82)
                    .background(Color.green.opacity(0.13), in: Circle())

                VStack(spacing: 7) {
                    Text("Budget Updated")
                        .font(.title3.weight(.bold))

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(22)
            .frame(maxWidth: 320)
            .budgetCard(cornerRadius: 24)
            .padding(.horizontal, 28)
        }
    }
}

private struct BudgetSectionHeader: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(LocalizedStringKey(title))
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
    }
}

private extension View {
    func budgetCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .fintraxSurface(cornerRadius: cornerRadius, accent: AppDesignSystem.Colors.primary)
    }
}

#Preview {
    BudgetView()
}
