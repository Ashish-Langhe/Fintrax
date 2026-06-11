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
            .frame(height: selectedChartType == .pie ? 292 : 330)
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

private struct CategoryBreakdownDonut: View {
    let breakdown: [(Category, Decimal)]
    let selectedCategory: Category?
    let selectedAmount: String
    let subtitle: String
    let totalAmount: Decimal
    @Binding var selectedAngle: Double?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.elevatedSurface.opacity(0.66),
                            AppDesignSystem.Colors.surfaceVariant.opacity(0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: AppDesignSystem.Colors.primary.opacity(0.10), radius: 18, x: 0, y: 12)

            Chart {
                ForEach(Array(breakdown.enumerated()), id: \.element.0.id) { _, item in
                    let category = item.0
                    let amount = item.1
                    let isSelected = selectedCategory == nil || selectedCategory?.id == category.id

                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue),
                        innerRadius: .ratio(0.60),
                        outerRadius: .ratio(selectedCategory?.id == category.id ? 0.98 : 0.92),
                        angularInset: 1.8
                    )
                    .foregroundStyle(category.displayColor.opacity(isSelected ? 0.96 : 0.34))
                }
            }
            .chartLegend(.hidden)
            .chartAngleSelection(value: $selectedAngle)
            .frame(height: 236)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            DonutCenterSummary(
                title: selectedCategory?.name ?? "Total",
                amount: selectedAmount,
                subtitle: subtitle,
                tint: selectedCategory?.displayColor ?? AppDesignSystem.Colors.primary
            )
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
    }
}

private struct DonutCenterSummary: View {
    let title: String
    let amount: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .lineLimit(1)

            Text(amount)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(subtitle)
                .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 124, height: 104)
        .background(
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.16),
                                AppDesignSystem.Colors.elevatedSurface.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay {
            Circle()
                .stroke(tint.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: tint.opacity(0.16), radius: 14, x: 0, y: 8)
    }
}

private struct RefinedMonthlyTrendChart: View {
    let trend: [(String, Decimal)]
    @Binding var selectedMonth: String?
    let maxValue: Double
    let reveal: Bool
    let formatCurrency: (Decimal) -> String
    let monthLabel: (String) -> String

    private var selectedData: (month: String, amount: Decimal)? {
        guard let selectedMonth else {
            return trend.last.map { ($0.0, $0.1) }
        }
        return trend.first { $0.0 == selectedMonth }.map { ($0.0, $0.1) }
    }

    private var trendPoints: [MonthlyTrendPoint] {
        trend.enumerated().map { index, item in
            let previousAmount = index > 0 ? trend[index - 1].1 : nil
            return MonthlyTrendPoint(
                month: item.0,
                amount: item.1,
                value: NSDecimalNumber(decimal: item.1).doubleValue * (reveal ? 1 : 0.02),
                previousAmount: previousAmount,
                tint: trendColor(current: item.1, previous: previousAmount),
                isSelected: selectedMonth == nil ? index == trend.indices.last : selectedMonth == item.0
            )
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Spend")
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)

                    Text(selectedData.map { formatCurrency($0.amount) } ?? formatCurrency(.zero))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    Text(selectedData?.month ?? "No month selected")
                        .font(AppDesignSystem.Typography.caption)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: trendDirectionIcon)
                        .font(.caption.weight(.bold))

                    Text(latestDeltaLabel)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                }
                .foregroundStyle(trendDirectionColor)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(trendDirectionColor.opacity(0.12), in: Capsule())
            }

            MonthlyTrendPlot(
                points: trendPoints,
                maxValue: max(maxValue, 1),
                selectedMonth: $selectedMonth,
                formatCurrency: formatCurrency,
                monthLabel: monthLabel
            )
            .frame(height: 288)
            .animation(.spring(response: 0.55, dampingFraction: 0.86), value: reveal)
            .animation(.spring(response: 0.34, dampingFraction: 0.84), value: selectedMonth)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.thinMaterial)

                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.primary.opacity(0.12),
                        AppDesignSystem.Colors.info.opacity(0.08),
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: AppDesignSystem.Colors.primary.opacity(0.10), radius: 18, x: 0, y: 12)
    }

    private var latestDeltaLabel: String {
        guard trend.count >= 2 else { return "Flat" }
        return deltaLabel(current: trend[trend.count - 1].1, previous: trend[trend.count - 2].1)
    }

    private var trendDirectionIcon: String {
        guard trend.count >= 2 else { return "minus.circle.fill" }
        let latest = trend[trend.count - 1].1
        let previous = trend[trend.count - 2].1
        if latest > previous { return "arrow.up.right.circle.fill" }
        if latest < previous { return "arrow.down.right.circle.fill" }
        return "minus.circle.fill"
    }

    private var trendDirectionColor: Color {
        guard trend.count >= 2 else { return AppDesignSystem.Colors.info }
        let latest = trend[trend.count - 1].1
        let previous = trend[trend.count - 2].1
        if latest > previous { return AppDesignSystem.Colors.error }
        if latest < previous { return AppDesignSystem.Colors.success }
        return AppDesignSystem.Colors.info
    }

    private func trendColor(current: Decimal, previous: Decimal?) -> Color {
        guard let previous else { return AppDesignSystem.Colors.primary }
        if current > previous { return AppDesignSystem.Colors.error }
        if current < previous { return AppDesignSystem.Colors.success }
        return AppDesignSystem.Colors.info
    }

    private func deltaLabel(current: Decimal, previous: Decimal?) -> String {
        guard let previous, previous > 0 else { return "Base" }
        let change = ((current - previous) / previous) * 100
        let value = NSDecimalNumber(decimal: change).doubleValue
        if abs(value) < 1 { return "Flat" }
        return String(format: "%@%.0f%%", value > 0 ? "+" : "", value)
    }

    fileprivate struct MonthlyTrendPoint: Identifiable {
        let month: String
        let amount: Decimal
        let value: Double
        let previousAmount: Decimal?
        let tint: Color
        let isSelected: Bool

        var id: String { month }
    }
}

private struct TrendLineShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let firstPoint = points.first else { return }
            path.move(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }
}

private struct TrendAreaShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let firstPoint = points.first, let lastPoint = points.last else { return }
            path.move(to: CGPoint(x: firstPoint.x, y: rect.maxY))
            path.addLine(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.addLine(to: CGPoint(x: lastPoint.x, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private struct MonthlyTrendPlot: View {
    let points: [RefinedMonthlyTrendChart.MonthlyTrendPoint]
    let maxValue: Double
    @Binding var selectedMonth: String?
    let formatCurrency: (Decimal) -> String
    let monthLabel: (String) -> String

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let plotRect = CGRect(
                    x: 54,
                    y: 18,
                    width: max(proxy.size.width - 68, 1),
                    height: max(proxy.size.height - 34, 1)
                )
                let chartPoints = positionedPoints(in: plotRect)

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.elevatedSurface.opacity(0.26),
                                    AppDesignSystem.Colors.primary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    gridLines(in: plotRect)
                    yAxisLabels(in: plotRect)

                    TrendAreaShape(points: chartPoints)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary.opacity(0.24),
                                    AppDesignSystem.Colors.info.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    TrendLineShape(points: chartPoints)
                        .stroke(
                            AppDesignSystem.Colors.primary,
                            style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)
                        )

                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        let position = chartPoints[safe: index] ?? .zero

                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                                selectedMonth = selectedMonth == point.month ? nil : point.month
                            }
                        } label: {
                            Circle()
                                .fill(point.isSelected ? point.tint : AppDesignSystem.Colors.elevatedSurface)
                                .frame(width: point.isSelected ? 13 : 9, height: point.isSelected ? 13 : 9)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white.opacity(point.isSelected ? 0.75 : 0.35), lineWidth: 1)
                                }
                                .shadow(color: point.tint.opacity(point.isSelected ? 0.26 : 0.08), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .position(position)
                        .accessibilityLabel(monthLabel(point.month))
                        .accessibilityValue(formatCurrency(point.amount))
                    }

                    if let selectedIndex = selectedPointIndex,
                       let selectedPoint = points[safe: selectedIndex],
                       let position = chartPoints[safe: selectedIndex] {
                        SelectedTrendMarker(
                            amount: formatCurrency(selectedPoint.amount),
                            delta: deltaLabel(for: selectedPoint),
                            tint: selectedPoint.tint
                        )
                        .position(x: min(max(position.x, 92), proxy.size.width - 54), y: max(position.y - 30, 24))

                        Rectangle()
                            .fill(selectedPoint.tint.opacity(0.22))
                            .frame(width: 1, height: plotRect.height)
                            .position(x: position.x, y: plotRect.midY)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            selectClosestMonth(to: value.location.x, in: plotRect)
                        }
                )
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                ForEach(points) { point in
                    Text(monthLabel(point.month))
                        .font(AppDesignSystem.Typography.caption2.weight(point.isSelected ? .bold : .semibold))
                        .foregroundStyle(point.isSelected ? point.tint : AppDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 6)

            MonthlyTrendKeyValues(
                average: formatCurrency(averageAmount),
                peak: peakPoint.map { formatCurrency($0.amount) } ?? formatCurrency(.zero),
                low: lowPoint.map { formatCurrency($0.amount) } ?? formatCurrency(.zero)
            )
        }
    }

    private var selectedPointIndex: Int? {
        guard let selectedMonth else { return points.indices.last }
        return points.firstIndex { $0.month == selectedMonth }
    }

    private var averageAmount: Decimal {
        guard !points.isEmpty else { return .zero }
        let total = points.reduce(Decimal.zero) { $0 + $1.amount }
        return total / Decimal(points.count)
    }

    private var peakPoint: RefinedMonthlyTrendChart.MonthlyTrendPoint? {
        points.max { $0.amount < $1.amount }
    }

    private var lowPoint: RefinedMonthlyTrendChart.MonthlyTrendPoint? {
        points.min { $0.amount < $1.amount }
    }

    private func positionedPoints(in rect: CGRect) -> [CGPoint] {
        guard !points.isEmpty else { return [] }

        return points.enumerated().map { index, point in
            let x: CGFloat
            if points.count == 1 {
                x = rect.midX
            } else {
                x = rect.minX + (CGFloat(index) / CGFloat(points.count - 1)) * rect.width
            }

            let ratio = maxValue > 0 ? min(max(point.value / maxValue, 0), 1) : 0
            let y = rect.maxY - CGFloat(ratio) * rect.height
            return CGPoint(x: x, y: y)
        }
    }

    private func gridLines(in rect: CGRect) -> some View {
        Path { path in
            for index in 0..<4 {
                let y = rect.minY + rect.height * CGFloat(index) / 3
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
        }
        .stroke(AppDesignSystem.Colors.outline.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
    }

    private func yAxisLabels(in rect: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            yAxisLabel(formatCurrency(Decimal(maxValue)), y: rect.minY - 8)
            yAxisLabel(formatCurrency(Decimal(maxValue / 2)), y: rect.midY - 8)
            yAxisLabel(formatCurrency(.zero), y: rect.maxY - 8)
        }
    }

    private func yAxisLabel(_ value: String, y: CGFloat) -> some View {
        Text(value)
            .font(AppDesignSystem.Typography.caption2)
            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .frame(width: 46, alignment: .trailing)
            .position(x: 25, y: y + 8)
    }

    private func deltaLabel(for point: RefinedMonthlyTrendChart.MonthlyTrendPoint) -> String {
        guard let previous = point.previousAmount, previous > 0 else { return "Base" }
        let change = ((point.amount - previous) / previous) * 100
        let value = NSDecimalNumber(decimal: change).doubleValue
        if abs(value) < 1 { return "Flat" }
        return String(format: "%@%.0f%%", value > 0 ? "+" : "", value)
    }

    private func selectClosestMonth(to xPosition: CGFloat, in rect: CGRect) {
        guard !points.isEmpty else { return }

        let clampedX = min(max(xPosition, rect.minX), rect.maxX)
        let ratio = rect.width > 0 ? (clampedX - rect.minX) / rect.width : 0
        let rawIndex = ratio * CGFloat(max(points.count - 1, 0))
        let index = min(max(Int(rawIndex.rounded()), 0), points.count - 1)
        selectedMonth = points[index].month
    }
}

private struct SelectedTrendMarker: View {
    let amount: String
    let delta: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(amount)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            Text(delta)
                .font(AppDesignSystem.Typography.caption2.weight(.bold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: tint.opacity(0.14), radius: 9, x: 0, y: 5)
    }
}

private struct MonthlyTrendKeyValues: View {
    let average: String
    let peak: String
    let low: String

    var body: some View {
        HStack(spacing: 8) {
            TrendKeyValue(title: "Avg", value: average, tint: AppDesignSystem.Colors.info)
            TrendKeyValue(title: "Peak", value: peak, tint: AppDesignSystem.Colors.error)
            TrendKeyValue(title: "Low", value: low, tint: AppDesignSystem.Colors.success)
        }
    }
}

private struct TrendKeyValue: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)

                Text(value)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.34), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
