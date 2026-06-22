//
//  IncomeTrackingView.swift
//  Fintrax
//

import SwiftUI

struct IncomeTrackingView: View {
    private let repository = FinanceDataRepository.shared

    @State private var incomes: [IncomeRecord] = []
    @State private var showingForm = false
    @State private var editingIncome: IncomeRecord?
    @State private var errorMessage: String?

    private var totalIncome: Decimal {
        DateRangeOption.thisMonth.filterIncome(incomes).totalIncome
    }

    var body: some View {
        FinanceScreen(title: "Income", subtitle: "Track salary, freelance, refunds, and other cash inflows.", icon: "arrow.down.circle.fill", tint: AppDesignSystem.Colors.success) {
            summaryCard

            if incomes.isEmpty {
                FinanceEmptyState(icon: "banknote.fill", title: "No income yet", subtitle: "Add income to understand your monthly cash flow.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(incomes) { income in
                        HStack(spacing: 10) {
                            FinanceListRow(
                                icon: "arrow.down.left.circle.fill",
                                title: income.title,
                                subtitle: "\(income.source) • \(income.date.formatted(date: .abbreviated, time: .omitted))",
                                value: CurrencyFormatter.format(income.amount),
                                tint: AppDesignSystem.Colors.success
                            )
                            .onTapGesture {
                                editingIncome = income
                            }

                            Button(role: .destructive) {
                                deleteIncome(income)
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppDesignSystem.Colors.error)
                                    .frame(width: 42, height: 42)
                                    .background(AppDesignSystem.Colors.error.opacity(0.12), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete \(income.title)")
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.error)
            }
        }
        .toolbar {
            Button {
                showingForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .task { loadIncomes() }
        .sheet(isPresented: $showingForm) {
            IncomeEditorView(income: nil) { income in
                saveIncome(income)
            }
        }
        .sheet(item: $editingIncome) { income in
            IncomeEditorView(income: income) { updated in
                updateIncome(updated)
            }
        }
    }

    private var summaryCard: some View {
        FinanceSummaryCard(
            title: "This Month Income",
            value: CurrencyFormatter.format(totalIncome),
            subtitle: L10n.format("finance.income.entries", DateRangeOption.thisMonth.filterIncome(incomes).count),
            icon: "chart.line.uptrend.xyaxis",
            tint: AppDesignSystem.Colors.success
        )
    }

    @MainActor
    private func loadIncomes() {
        do {
            incomes = try repository.loadIncomeRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func saveIncome(_ income: IncomeRecord) {
        do {
            try repository.saveIncomeRecord(income)
            loadIncomes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func updateIncome(_ income: IncomeRecord) {
        do {
            try repository.updateIncomeRecord(income)
            loadIncomes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteIncome(_ income: IncomeRecord) {
        do {
            try repository.deleteIncomeRecord(id: income.id)
            loadIncomes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension DateRangeOption {
    func filterIncome(_ incomes: [IncomeRecord]) -> [IncomeRecord] {
        let range = getDateRange()
        return incomes.filter { $0.date >= range.start && $0.date <= range.end }
    }
}
