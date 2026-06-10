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
                title: "Delete Budget?",
                message: "This removes your monthly budget. Expense history stays untouched, but budget progress will disappear.",
                icon: "trash.fill",
                tint: AppDesignSystem.Colors.error,
                primaryAction: FintraxModalAction(title: "Delete Budget", icon: "trash.fill", tint: AppDesignSystem.Colors.error, isDestructive: true) {
                    showingDeleteAlert = false
                    Task {
                        await viewModel.deleteBudget()
                        if viewModel.currentError == nil {
                            successMessage = "Budget deleted successfully"
                            showingSuccessAlert = true
                        }
                    }
                },
                secondaryAction: FintraxModalAction(title: "Keep Budget", icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
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
                                    .fill(Color(.systemBackground).opacity(0.62))

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
                            Text(viewModel.isOverBudget ? "Limit exceeded" : "On track")
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InsightCard(
                    title: "Spent This Month",
                    value: viewModel.formatCurrency(viewModel.spentThisMonth),
                    subtitle: "\(viewModel.currentMonthTransactions) transactions",
                    icon: "creditcard.fill",
                    tint: .red
                )
                
                InsightCard(
                    title: viewModel.isOverBudget ? "Over Budget" : "Remaining Budget",
                    value: viewModel.formatCurrency(abs(viewModel.remainingBudget)),
                    subtitle: viewModel.isOverBudget ? "Over budget" : "\(BudgetCalculations.daysRemainingInCurrentMonth()) days left",
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
                    
                    Text(remainingBudget < 0 ? "Over by: \(currencyFormatter(abs(remainingBudget)))" : "Remaining: \(currencyFormatter(remainingBudget))")
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
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            
                Text(value)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground).opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
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
                Text(title)
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
        .background(Color(.systemBackground).opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
    }
}

private struct BudgetTexturedBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 22

                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.36, y: size.height))
                }

                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)

                let dotColor = Color.primary.opacity(0.055)
                for row in stride(from: CGFloat(28), through: size.height, by: 86) {
                    for column in stride(from: CGFloat(22), through: size.width, by: 104) {
                        context.fill(Path(ellipseIn: CGRect(x: column, y: row, width: 4, height: 4)), with: .color(dotColor))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func budgetCard(cornerRadius: CGFloat = 22) -> some View {
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
    BudgetView()
}
