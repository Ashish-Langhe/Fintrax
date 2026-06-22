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
                AnalyticsHeaderSection()
                AnalyticsRangeSelector(viewModel: viewModel)

                if viewModel.isLoading {
                    AnalyticsLoadingPanel()
                } else if let error = viewModel.currentError {
                    AnalyticsErrorPanel(error: error)
                } else if let dashboard = viewModel.dashboardData, viewModel.hasExpensesInDateRange {
                    AnalyticsStorySection(dashboard: dashboard, viewModel: viewModel)
                    AnalyticsChartExplorerSection(
                        dashboard: dashboard,
                        viewModel: viewModel,
                        onCategorySelected: showCategoryDetail
                    )
                    AnalyticsTopCategoriesSection(
                        dashboard: dashboard,
                        viewModel: viewModel,
                        onCategorySelected: showCategoryDetail
                    )
                    AnalyticsRecentTransactionsSection(dashboard: dashboard, viewModel: viewModel)
                } else {
                    AnalyticsEmptyPanel()
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

    private func showCategoryDetail(_ category: Category) {
        viewModel.selectCategory(category)
        showingCategoryDetail = true
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
