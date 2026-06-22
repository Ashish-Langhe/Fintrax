//
//  DashboardCategoryDetailView.swift
//  Fintrax
//
//  Fintrax documentation: Extracted reusable dashboard presentation components.
//

import SwiftUI
import Foundation

struct CategoryDetailView: View {
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
            Text(L10n.Dashboard.totalSpending)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(viewModel.formatCurrency(viewModel.getCategorySpending(for: category)))
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(L10n.format(L10n.Dashboard.transactions, expenses.count))
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
                Text(L10n.Dashboard.budgetStatus)
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
            Text(L10n.Dashboard.expenses)
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(expenses) { expense in
                ExpenseRowView(expense: expense)
            }
        }
    }
}
