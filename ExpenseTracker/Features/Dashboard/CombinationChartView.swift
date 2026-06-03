//
//  CombinationChartView.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI
import Charts

/// Interactive multi-axis combination chart with bar and line overlays
struct CombinationChartView: View {
    let categoryData: [(category: Category, monthlyData: [(month: String, amount: Decimal)])]
    let totalMonthlyData: [(String, Decimal)]
    
    @State private var selectedCategory: Category?
    @State private var selectedMonth: String?
    @State private var chartType: ChartDisplayType = .overlay
    @State private var animationScale: CGFloat = 0.8
    
    enum ChartDisplayType: String, CaseIterable {
        case overlay = "Overlay"
        case grouped = "Grouped"
        case split = "Split View"
    }
    
    var body: some View {
        VStack(alignment: .leading, spending: 16) {
            // Chart type selector
            Picker("Chart Type", selection: $chartType) {
                ForEach(ChartDisplayType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Main chart
            chartContentView
                .frame(height: 320)
                .scaleEffect(animationScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationScale)
                .task {
                    withAnimation {
                        animationScale = 1.0
                    }
                }
            
            // Category selector grid
            categorySelectorGrid
            
            // Insights panel
            insightsPanel
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .onChange(of: chartType) { _, _ in
            selectedCategory = nil
            selectedMonth = nil
        }
    }
    
    @ViewBuilder
    private var chartContentView: some View {
        switch chartType {
        case .overlay:
            overlayChartView
        case .grouped:
            groupedChartView
        case .split:
            splitChartView
        }
    }
    
    // MARK: - Overlay Chart (Bar + Line)
    
    private var overlayChartView: some View {
        Chart {
            // Bar marks for total spending
            ForEach(Array(totalMonthlyData.enumerated()), id: \.element.0) { index, monthData in
                BarMark(
                    x: .value("Month", monthData.0),
                    y: .value("Total Spending", NSDecimalNumber(decimal: monthData.1).doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.8), .blue]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .opacity(0.6)
                .cornerRadius(4)
            }
            
            // Line marks for selected category
            if let selectedCategory = selectedCategory,
               let categoryMonthly = getCategoryMonthlyData(selectedCategory) {
                ForEach(Array(categoryMonthly.enumerated()), id: \.element.0) { index, monthData in
                    LineMark(
                        x: .value("Month", monthData.0),
                        y: .value("Category Spending", NSDecimalNumber(decimal: monthData.1).doubleValue)
                    )
                    .foregroundStyle(Color(selectedCategory.name))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol {
                        Circle()
                            .fill(Color(selectedCategory.name))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                if let month = value.as(String.self) {
                    AxisValueLabel(month.prefix(3))
                        .font(.caption)
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                if let amount = value.as(Double.self) {
                    AxisValueLabel(formatCurrency(Decimal(amount)))
                        .font(.caption2)
                }
            }
        }
        .chartAngleSelection(value: .constant(nil))
        .chartBackground { chartProxy in
            LinearGradient(
                gradient: Gradient(colors: [.clear,	Color.blue.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Grouped Chart
    
    private var groupedChartView: some View {
        Chart {
            ForEach(Array(categoryData.enumerated()), id: \.element.category.id) { index, categoryInfo in
                ForEach(Array(categoryInfo.monthlyData.enumerated()), id: \.element.0) { monthIndex, monthData in
                    BarMark(
                        x: .value("Month", monthData.0),
                        y: .value("Amount", NSDecimalNumber(decimal: monthData.1).doubleValue)
                    )
                    .foregroundStyle(Color(categoryInfo.category.name))
                    .position(by: .value("Category", categoryInfo.category.name))
                    .opacity(selectedCategory?.id == categoryInfo.category.id ? 1.0 : 0.7)
                    .cornerRadius(2)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                if let month = value.as(String.self) {
                    AxisValueLabel(month.prefix(3))
                        .font(.caption)
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                if let amount = value.as(Double.self) {
                    AxisValueLabel(formatCurrency(Decimal(amount)))
                        .font(.caption2)
                }
            }
        }
    }
    
    // MARK: - Split View Chart
    
    private var splitChartView: some View {
        VStack(spacing: 0) {
            // Upper chart: Total spending
            Chart {
                ForEach(Array(totalMonthlyData.enumerated()), id: \.element.0) { index, monthData in
                    BarMark(
                        x: .value("Month", monthData.0),
                        y: .value("Total", NSDecimalNumber(decimal: monthData.1).doubleValue)
                    )
                    .foregroundStyle(.blue.opacity(0.7))
                    .cornerRadius(4)
                }
            }
            .frame(height: 140)
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel(formatCurrency(Decimal(amount)))
                            .font(.caption2)
                    }
                }
            }
            
            Divider()
            
            // Lower chart: Category breakdown
            if let selectedCategory = selectedCategory,
               let categoryMonthly = getCategoryMonthlyData(selectedCategory) {
                Chart {
                    ForEach(Array(categoryMonthly.enumerated()), id: \.element.0) { index, monthData in
                        AreaMark(
                            x: .value("Month", monthData.0),
                            y: .value("Category", NSDecimalNumber(decimal: monthData.1).doubleValue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(selectedCategory.name).opacity(0.8),
                                    Color(selectedCategory.name).opacity(0.2)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 140)
                .chartYAxis {
                    AxisMarks { value in
                        if let amount = value.as(Double.self) {
                            AxisValueLabel(formatCurrency(Decimal(amount)))
                                .font(.caption2)
                        }
                    }
                }
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 140)
                    .overlay(
                        Text("Select a category below")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
    
    // MARK: - Category Selector Grid
    
    private var categorySelectorGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(categoryData, id: \.category.id) { categoryInfo in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if selectedCategory?.id == categoryInfo.category.id {
                                selectedCategory = nil
                            } else {
                                selectedCategory = categoryInfo.category
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(categoryInfo.category.name))
                                .frame(width: 8, height: 8)
                            
                            Text(categoryInfo.category.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selectedCategory?.id == categoryInfo.category.id ?
                                    Color(categoryInfo.category.name).opacity(0.2) :
                                    Color(.tertiarySystemBackground)
                                )
                        )
                        .foregroundColor(
                            selectedCategory?.id == categoryInfo.category.id ?
                            Color(categoryInfo.category.name) : .primary
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Insights Panel
    
    private var insightsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let selectedCategory = selectedCategory,
               let insights = generateInsights(for: selectedCategory) {
                VStack(spacing: 6) {
                    ForEach(insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text(insight)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
            } else {
                Text("Select a category to see insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCategoryMonthlyData(_ category: Category) -> [(String, Decimal)]? {
        return categoryData.first { $0.category.id == category.id }?.monthlyData
    }
    
    private func generateInsights(for category: Category) -> [String]? {
        guard let monthlyData = getCategoryMonthlyData(category) else { return nil }
        
        var insights: [String] = []
        
        // Calculate average monthly spending
        let average = monthlyData.reduce(Decimal.zero) { sum, item in sum + item.1 } / Decimal(monthlyData.count)
        
        // Check if last month is above average
        if let lastMonth = monthlyData.last, lastMonth.1 > average {
            let percentage = ((lastMonth.1 - average) / average) * 100
            insights.append("Last month's spending is \(Int(percentage))% above average")
        }
        
        // Check spending trend
        if monthlyData.count >= 2 {
            let lastTwo = monthlyData.suffix(2)
            let trend = lastTwo.last!.1 - lastTwo.first!.1
            if trend > 0 {
                insights.append("Spending increased this month")
            } else {
                insights.append("Good! Spending decreased this month")
            }
        }
        
        // Identify peak month
        if let peak = monthlyData.max(by: { $0.1 < $1.1 }) {
            insights.append("Peak spending in \(peak.0)")
        }
        
        return insights.isEmpty ? nil : insights
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0"
    }
}

#Preview {
    CombinationChartView(
        categoryData: [
            (
                Category(id: UUID(), name: "Food", isDefault: true),
                [("Jan", 5000), ("Feb", 6000), ("Mar", 4500), ("Apr", 7000)]
            ),
            (
                Category(id: UUID(), name: "Transport", isDefault: true),
                [("Jan", 2000), ("Feb", 2500), ("Mar", 1800), ("Apr", 2200)]
            )
        ],
        totalMonthlyData: [
            ("Jan", 8000), ("Feb", 9500), ("Mar", 7200), ("Apr", 10200)
        ]
    )
}