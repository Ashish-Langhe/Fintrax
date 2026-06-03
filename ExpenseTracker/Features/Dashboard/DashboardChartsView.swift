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
    @State private var selectedBarMonth: String?
    
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
            .frame(height: 280)
            .chartBackground { _ in
                Color.clear
            }
            
            // Chart legend/details section
            if selectedChartType == .pie {
                pieChartLegend
            } else if selectedChartType == .bar {
                barChartDetails
            }
        }
    }
    
    // MARK: - Pie Chart View
    
    @ViewBuilder
    private var pieChartView: some View {
        if !optimizedCategoryBreakdown.isEmpty {
            Chart {
                ForEach(0..<optimizedCategoryBreakdown.count, id: \.self) { index in
                    let (category, amount) = optimizedCategoryBreakdown[index]
                    let isSelected = selectedCategory == nil || selectedCategory?.id == category.id
                    
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue),
                        innerRadius: .ratio(0.58),
                        outerRadius: .ratio(selectedCategory?.id == category.id ? 1.0 : 0.94),
                        angularInset: isSelected ? 1.0 : 2.0
                    )
                    .foregroundStyle(category.displayColor)
                    .opacity(isSelected ? 1.0 : 0.34)
                }
            }
            .chartLegend(.hidden)
            .chartAngleSelection(value: $selectedCategoryAngle)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    ZStack {
                        VStack(spacing: 4) {
                            Text("Total")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(selectedCategorySummary)
                                .font(.title3)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.75)
                            Text(selectedCategory?.name ?? "\(dashboardData.totalTransactions) expenses")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                    }
                }
            }
            .onChange(of: selectedCategoryAngle) { _, newValue in
                selectedCategory = category(forAngle: newValue)
                if let selectedCategory {
                    onCategorySelected(selectedCategory)
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
            Chart {
                ForEach(0..<optimizedMonthlyTrend.count, id: \.self) { index in
                    let (month, amount) = optimizedMonthlyTrend[index]
                    let isMonthSelectedValue = selectedMonth == nil || selectedMonth == month

                    AreaMark(
                        x: .value("Month", month),
                        y: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.18, green: 0.55, blue: 0.82).opacity(0.34),
                                Color(red: 0.18, green: 0.55, blue: 0.82).opacity(0.04)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Month", month),
                        y: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue)
                    )
                    .foregroundStyle(Color(red: 0.13, green: 0.45, blue: 0.74))
                    .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Month", month),
                        y: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue)
                    )
                    .foregroundStyle(isMonthSelectedValue ? Color(red: 0.13, green: 0.45, blue: 0.74) : Color.white)
                    .symbolSize(isMonthSelectedValue ? 120 : 74)
                    .annotation(position: .top) {
                        if isMonthSelectedValue {
                            monthAnnotation(month: month, amount: amount)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedBarMonth)
            .chartYScale(domain: 0...monthlyTrendUpperBound)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    if let month = value.as(String.self) {
                        AxisValueLabel(monthAxisLabel(month))
                            .font(.caption2)
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                        .foregroundStyle(Color.secondary.opacity(0.18))
                    if let amount = value.as(Double.self) {
                        AxisValueLabel(formatCurrency(Decimal(amount)))
                            .font(.caption2)
                    }
                }
            }
            .onChange(of: selectedBarMonth) { _, newValue in
                selectedMonth = newValue
            }
        } else {
            emptyChartView("No Monthly Data", "Add expenses over multiple months to see the trend")
        }
    }
    

    
    @ViewBuilder
    private func monthAnnotation(month: String, amount: Decimal) -> some View {
        if selectedMonth == month {
            Text(formatCurrency(amount))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        Capsule()
                            .fill(.thinMaterial)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.15))
                            )
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.blue.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
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
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(optimizedCategoryBreakdown.enumerated()), id: \.element.0.id) { index, categoryData in
                categoryLegendRow(category: categoryData.0, amount: categoryData.1)
            }
        }
    }
    
    private func categoryLegendRow(category: Category, amount: Decimal) -> some View {
        Button(action: {
            toggleCategorySelection(category)
        }) {
            HStack(spacing: 12) {
                categoryColorIndicator(category: category)
                categoryInfo(category: category, amount: amount)
                Spacer()
                categoryPercentage(category: category)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.thinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectionBackgroundColor(category: category))
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
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
    
    // MARK: - Bar Chart Details
    
    private var barChartDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(optimizedMonthlyTrend.enumerated()), id: \.element.0) { index, monthData in
                monthDetailRow(month: monthData.0, amount: monthData.1)
            }
        }
    }
    
    private func monthDetailRow(month: String, amount: Decimal) -> some View {
        Button(action: {
            toggleMonthSelection(month)
        }) {
            HStack(spacing: 12) {
                monthIndicator(month: month)
                monthInfo(month: month, amount: amount)
                Spacer()
                detailsLabel()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.thinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(monthSelectionBackgroundColor(month: month))
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(selectedMonth == month ? 0.4 : 0.2),
                                Color.white.opacity(selectedMonth == month ? 0.2 : 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(selectedMonth == month ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMonth)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleMonthSelection(_ month: String) {
        if selectedMonth == month {
            selectedMonth = nil
        } else {
            selectedMonth = month
        }
    }
    
    private func monthIndicator(month: String) -> some View {
        Image(systemName: selectedMonth == month ? "chart.line.uptrend.xyaxis.circle.fill" : "circle.fill")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(selectedMonth == month ? Color.blue : Color.secondary.opacity(0.45))
            .frame(width: 18, height: 18)
    }
    
    private func monthInfo(month: String, amount: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(month)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(formatCurrency(amount))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func detailsLabel() -> some View {
        Text("Monthly")
            .font(.caption)
            .foregroundColor(.blue)
    }
    
    private func monthSelectionBackgroundColor(month: String) -> Color {
        return selectedMonth == month ? Color.blue.opacity(0.1) : Color.clear
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

// MARK: - Color Extension for Categories

extension Color {
    init(_ categoryName: String) {
        let colors: [String: Color] = [
            "Food": Color(red: 0.88, green: 0.28, blue: 0.26),
            "Transportation": Color(red: 0.14, green: 0.48, blue: 0.78),
            "Entertainment": Color(red: 0.47, green: 0.36, blue: 0.78),
            "Utilities": Color(red: 0.93, green: 0.55, blue: 0.18),
            "Health": Color(red: 0.20, green: 0.62, blue: 0.42),
            "Shopping": Color(red: 0.83, green: 0.30, blue: 0.56),
            "Other": Color(red: 0.42, green: 0.47, blue: 0.54)
        ]
        
        if let color = colors[categoryName] {
            self = color
        } else {
            self = Color.stablePaletteColor(for: categoryName)
        }
    }
    
    // Enhanced gradient colors for categories
    static func categoryGradient(for categoryName: String) -> LinearGradient {
        let baseColor = Color(categoryName)
        
        return LinearGradient(
            gradient: Gradient(colors: [
                baseColor.opacity(0.9),
                baseColor.opacity(0.7),
                baseColor.opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func stablePaletteColor(for value: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.18, green: 0.57, blue: 0.73),
            Color(red: 0.72, green: 0.38, blue: 0.25),
            Color(red: 0.36, green: 0.58, blue: 0.35),
            Color(red: 0.55, green: 0.45, blue: 0.74),
            Color(red: 0.76, green: 0.49, blue: 0.19),
            Color(red: 0.25, green: 0.62, blue: 0.58),
            Color(red: 0.65, green: 0.35, blue: 0.48)
        ]
        let scalarTotal = value.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[abs(scalarTotal) % colors.count]
    }
}

// MARK: - Random Color Helper

extension Color {
    static var random: Color {
        let allColors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow, .cyan, .mint]
        let index = Int.random(in: 0..<allColors.count)
        return allColors[index]
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
