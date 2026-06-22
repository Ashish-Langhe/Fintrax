//
//  AnalyticsCategoryDetailView.swift
//  Fintrax
//

import SwiftUI

struct AnalyticsCategoryDetailView: View {
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
