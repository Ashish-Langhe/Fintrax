//
//  DashboardChartsView.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI
import Charts

/// Charts container view for dashboard visualization
struct DashboardChartsView: View {
    let dashboardData: DashboardData
    let selectedChartType: DashboardViewModel.ChartType
    let onCategorySelected: (Category) -> Void
    
    @State private var selectedCategory: Category?
    @State private var selectedMonth: String?
    @State private var selectedCategoryAngle: Double?
    @State private var chartReveal = false
    
    // Performance optimization constants
    private enum ChartConstants {
        static let maxPieChartSegments = 10
        static let maxBarChartMonths = 12
        static let animationDuration: Double = 0.3
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart content based on selected type
            Group {
                switch selectedChartType {
                case .pie:
                    pieChartView
                case .bar:
                    barChartView
                }
            }
            .frame(height: selectedChartType == .pie ? 292 : 420)
            .chartBackground { _ in
                Color.clear
            }
            .onAppear {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.86)) {
                    chartReveal = true
                }
            }
            
            // Chart legend/details section
            if selectedChartType == .pie {
                pieChartLegend
            }
        }
    }
    
    // MARK: - Pie Chart View
    
    @ViewBuilder
    private var pieChartView: some View {
        if !optimizedCategoryBreakdown.isEmpty {
            CategoryBreakdownDonut(
                breakdown: optimizedCategoryBreakdown,
                selectedCategory: selectedCategory,
                selectedAmount: selectedCategorySummary,
                subtitle: selectedCategory == nil ? "\(dashboardData.totalTransactions) expenses" : selectedCategoryPercentLabel,
                totalAmount: dashboardData.totalSpending,
                selectedAngle: $selectedCategoryAngle
            )
            .onChange(of: selectedCategoryAngle) { _, newValue in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    selectedCategory = category(forAngle: newValue)
                    if let selectedCategory {
                        onCategorySelected(selectedCategory)
                    }
                }
            }
        } else {
            emptyChartView("No Categories", "Add expenses with different categories to see the breakdown")
        }
    }
    
    private func annotationText(for amount: Decimal) -> some View {
        Text(formatCurrency(amount))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                ZStack {
                    Capsule()
                        .fill(.thinMaterial)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    private func isCategorySelected(_ category: Category) -> Bool {
        return selectedCategory == nil || selectedCategory?.id == category.id
    }
    
    @ViewBuilder
    private func categoryAnnotation(category: Category, amount: Decimal) -> some View {
        if selectedCategory?.id == category.id {
            Text(formatCurrency(amount))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
        }
    }
    
    private var selectedCategorySummary: String {
        guard let selectedCategory,
              let amount = optimizedCategoryBreakdown.first(where: { $0.0.id == selectedCategory.id })?.1 else {
            return formatCurrency(dashboardData.totalSpending)
        }

        return formatCurrency(amount)
    }

    private var selectedCategoryPercentLabel: String {
        guard let selectedCategory else { return "" }
        let percentage = dashboardData.getCategorySpendingPercentage(for: selectedCategory) * 100
        return String(format: "%.1f%% of spend", percentage)
    }

    private func category(forAngle angle: Double?) -> Category? {
        guard let angle else { return nil }

        var runningTotal = 0.0
        for item in optimizedCategoryBreakdown {
            runningTotal += NSDecimalNumber(decimal: item.1).doubleValue
            if angle <= runningTotal {
                return item.0
            }
        }

        return nil
    }
    
    // MARK: - Bar Chart View
    
    @ViewBuilder
    private var barChartView: some View {
        if !optimizedMonthlyTrend.isEmpty {
            RefinedMonthlyTrendChart(
                trend: optimizedMonthlyTrend,
                selectedMonth: $selectedMonth,
                maxValue: monthlyTrendUpperBound,
                reveal: chartReveal,
                formatCurrency: formatCurrency,
                monthLabel: monthAxisLabel
            )
        } else {
            emptyChartView("No Monthly Data", "Add expenses over multiple months to see the trend")
        }
    }
    // MARK: - Optimized Data for Charts
    
    private var optimizedCategoryBreakdown: [(Category, Decimal)] {
        let breakdown = dashboardData.categoryBreakdown
        
        if breakdown.count <= ChartConstants.maxPieChartSegments {
            return breakdown
        } else {
            // Group smaller categories into "Other"
            let topCategories = Array(breakdown.prefix(ChartConstants.maxPieChartSegments - 1))
            let otherTotal = breakdown.dropFirst(ChartConstants.maxPieChartSegments - 1)
                .reduce(Decimal.zero) { sum, item in
                    sum + item.1
                }
            
            let otherCategory = Category(
                id: UUID(),
                name: "Other",
                isDefault: true
            )
            return topCategories + [(otherCategory, otherTotal)]
        }
    }
    
    private var optimizedMonthlyTrend: [(String, Decimal)] {
        let trend = dashboardData.monthlyTrend
        
        if trend.count <= ChartConstants.maxBarChartMonths {
            return trend
        } else {
            // Take the most recent months
            return Array(trend.suffix(ChartConstants.maxBarChartMonths))
        }
    }

    private var monthlyTrendUpperBound: Double {
        let maxValue = optimizedMonthlyTrend
            .map { NSDecimalNumber(decimal: $0.1).doubleValue }
            .max() ?? 0
        return max(maxValue * 1.22, 100)
    }
    
    // MARK: - Pie Chart Legend
    
    private var pieChartLegend: some View {
        let quickCategories = Array(optimizedCategoryBreakdown.prefix(4))
        let remainingCount = max(optimizedCategoryBreakdown.count - quickCategories.count, 0)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Quick Select", systemImage: "hand.tap.fill")
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                if remainingCount > 0 {
                    Text("+\(remainingCount)")
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppDesignSystem.Colors.primary.opacity(0.11), in: Capsule())
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(quickCategories, id: \.0.id) { categoryData in
                    categoryLegendRow(category: categoryData.0, amount: categoryData.1)
                }
            }

            if remainingCount > 0 {
                Text("Full category comparison is available in the table below.")
                    .font(AppDesignSystem.Typography.caption2.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    private func categoryLegendRow(category: Category, amount: Decimal) -> some View {
        Button(action: {
            toggleCategorySelection(category)
        }) {
            HStack(spacing: 12) {
                categoryColorIndicator(category: category)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(categoryPercentageText(category: category))
                        .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                        .foregroundStyle(category.displayColor)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.thinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectionBackgroundColor(category: category))
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(selectedCategory?.id == category.id ? 0.4 : 0.2),
                                Color.white.opacity(selectedCategory?.id == category.id ? 0.2 : 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(selectedCategory?.id == category.id ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedCategory?.id)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func categoryPercentageText(category: Category) -> String {
        let percentage = dashboardData.getCategorySpendingPercentage(for: category) * 100
        return String(format: "%.0f%% of spend", percentage)
    }
    
    private func toggleCategorySelection(_ category: Category) {
        if selectedCategory?.id == category.id {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
    
    private func categoryColorIndicator(category: Category) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(category.displayColor)
            
            Image(systemName: category.iconName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(width: 18, height: 18)
    }
    
    private func categoryInfo(category: Category, amount: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(category.name)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(formatCurrency(amount))
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { proxy in
                let percentage = dashboardData.getCategorySpendingPercentage(for: category)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5).opacity(0.75))
                    Capsule()
                        .fill(category.displayColor)
                        .frame(width: max(8, proxy.size.width * percentage))
                }
            }
            .frame(height: 5)
            .padding(.top, 3)
        }
    }
    
    private func categoryPercentage(category: Category) -> some View {
        let percentage = dashboardData.getCategorySpendingPercentage(for: category) * 100
        return Text(String(format: "%.1f%%", percentage))
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func selectionBackgroundColor(category: Category) -> Color {
        return selectedCategory?.id == category.id ? Color.blue.opacity(0.1) : Color.clear
    }
    
    // MARK: - Empty Chart View
    
    @ViewBuilder
    private func emptyChartView(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0 // Use no decimals for charts
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0"
    }

    private func monthAxisLabel(_ month: String) -> String {
        let parts = month.split(separator: " ")
        return parts.first.map(String.init) ?? month
    }
}


#Preview {
    // Create sample data for preview
    let sampleDashboard = DashboardData.generate(
        from: [],
        categories: [
            Category(id: UUID(), name: "Food", isDefault: true),
            Category(id: UUID(), name: "Transportation", isDefault: true),
            Category(id: UUID(), name: "Entertainment", isDefault: true)
        ],
        budgets: []
    )
    
    return VStack {
        DashboardChartsView(
            dashboardData: sampleDashboard,
            selectedChartType: .pie,
            onCategorySelected: { _ in }
        )
        
        Divider()
        
        DashboardChartsView(
            dashboardData: sampleDashboard,
            selectedChartType: .bar,
            onCategorySelected: { _ in }
        )
    }
    .padding()
}
