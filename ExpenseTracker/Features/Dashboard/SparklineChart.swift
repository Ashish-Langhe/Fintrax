//
//  SparklineChart.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI
import Charts

/// Spending trend sparkline visualization for category cards
struct SparklineChart: View {
    let data: [Double]
    let color: Color
    let style: SparklineStyle
    let showLabels: Bool
    
    enum SparklineStyle {
        case line
        case area
        case bars
        case points
        case combination
    }
    
    @State private var animationProgress: Double = 0
    @State private var selectedPoint: Int? = nil
    @State private var isAnimating = false
    
    init(
        data: [Double],
        color: Color = .blue,
        style: SparklineStyle = .line,
        showLabels: Bool = false
    ) {
        self.data = data
        self.color = color
        self.style = style
        self.showLabels = showLabels
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if showLabels {
                headerView
            }
            
            chartView
                .frame(height: 60)
                .onAppear {
                    startAnimation()
                }
            
            if showLabels {
                footerView
            }
        }
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text("Trend")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            trendIndicator
        }
    }
    
    // MARK: - Trend Indicator
    
    private var trendIndicator: some View {
        guard data.count >= 2 else {
            return EmptyView()
        }
        
        let firstValue = data.first!
        let lastValue = data.last!
        let change = ((lastValue - firstValue) / firstValue) * 100
        
        return HStack(spacing: 2) {
            Image(systemName: change >= 0 ? "triangle.fill" : "triangle.fill")
                .font(.caption2)
                .rotationEffect(.degrees(change >= 0 ? 0 : 180))
                .foregroundColor(change >= 0 ? .red : .green)
            
            Text(String(format: "%.0f%%", abs(change)))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(change >= 0 ? .red : .green)
        }
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart {
            switch style {
            case .line:
                lineChart
            case .area:
                areaChart
            case .bars:
                barsChart
            case .points:
                pointsChart
            case .combination:
                combinationChart
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartAngleSelection(value: .constant(nil))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    handlePointSelection(at: gesture.location.x)
                }
                .onEnded { _ in
                    selectedPoint = nil
                }
        )
    }
    
    // MARK: - Line Chart
    
    private var lineChart: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Index", index),
                y: .value("Value", interpolatedValue(value))
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }
    
    // MARK: - Area Chart
    
    private var areaChart: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
            AreaMark(
                x: .value("Index", index),
                y: .value("Value", interpolatedValue(value))
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0.6),
                        color.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    // MARK: - Bars Chart
    
    private var barsChart: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
            BarMark(
                x: .value("Index", index),
                y: .value("Value", interpolatedValue(value))
            )
            .foregroundStyle(color.opacity(0.8))
            .cornerRadius(1)
        }
    }
    
    // MARK: - Points Chart
    
    private var pointsChart: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
            PointMark(
                x: .value("Index", index),
                y: .value("Value", interpolatedValue(value))
            )
            .foregroundStyle(color)
            .symbolSize(selectedPoint == index ? 40 : 20)
            .foregroundStyle(selectedPoint == index ? color.opacity(1.0) : color.opacity(0.7))
        }
    }
    
    // MARK: - Combination Chart
    
    private var combinationChart: some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
            // Area fill
            AreaMark(
                x: .value("Index", index),
                y: .value("Value", interpolatedValue(value))
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0.3),
                        color.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Line overlay
            LineMark(
                x: .value("Index", index),
                y: .value("Value", interpolatedValue(value))
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            // Points
            PointMark(
                x: .value("Index", index),
                y: .value("Value", interpolatedValue(value))
            )
            .foregroundStyle(color)
            .symbolSize(selectedPoint == index ? 30 : 15)
        }
    }
    
    // MARK: - Footer View
    
    @ViewBuilder
    private var footerView: some View {
        HStack {
            if let minValue = data.min(), let maxValue = data.max() {
                Text(formatCurrency(minValue))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(maxValue))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnimation() {
        isAnimating = true
        withAnimation(.easeInOut(duration: 1.2)) {
            animationProgress = 1.0
        }
    }
    
    private func interpolatedValue(_ value: Double) -> Double {
        return value * animationProgress
    }
    
    private func handlePointSelection(at location: CGFloat) {
        guard !data.isEmpty else { return }
        
        let chartWidth: CGFloat = 200 // Approximate chart width
        let normalizedX = location / chartWidth
        let index = Int(normalizedX * Double(data.count))
        
        if index >= 0 && index < data.count {
            selectedPoint = index
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: "₹", with: "") ?? "0"
    }
}\n\n/// Compact sparkline widget for category cards\nstruct CompactSparklineWidget: View {\n    let category: Category\n    let data: [Double]\n    let currentSpending: Decimal\n    let onTapAction: ((Category) -> Void)?\n    \n    @State private var isHovered = false\n    @State private var glowIntensity: Double = 0\n    \n    var categoryColor: Color {\n        Color(category.name)\n    }\n    \n    var body: some View {\n        Button(action: {\n            onTapAction?(category)\n        }) {\n            HStack(spacing: 12) {\n                // Category indicator\n                VStack(spacing: 2) {\n                    Circle()\n                        .fill(categoryColor)\n                        .frame(width: 8, height: 8)\n                        .scaleEffect(isHovered ? 1.2 : 1.0)\n                    \n                    Text(category.name)\n                        .font(.caption)\n                        .fontWeight(.medium)\n                        .lineLimit(1)\n                        .foregroundColor(isHovered ? categoryColor : .primary)\n                }\n                \n                // Sparkline\n                SparklineChart(\n                    data: data,\n                    color: categoryColor,\n                    style: .combination,\n                    showLabels: false\n                )\n                \n                // Current value\n                VStack(alignment: .trailing, spacing: 2) {\n                    Text(formatCurrency(currentSpending))\n                        .font(.caption)\n                        .fontWeight(.semibold)\n                        .foregroundColor(.primary)\n                    \n                    if data.count >= 2 {\n                        let trend = ((data.last! - data.first!) / data.first!) * 100\n                        Text(String(format: \"%+.0f%%\", trend))\n                            .font(.caption2)\n                            .foregroundColor(trend >= 0 ? .red : .green)\n                    }\n                }\n            }\n            .padding(.horizontal, 12)\n            .padding(.vertical, 8)\n            .background(\n                RoundedRectangle(cornerRadius: 12)\n                    .fill(Color(.tertiarySystemBackground))\n                    .overlay(\n                        RoundedRectangle(cornerRadius: 12)\n                            .stroke(categoryColor.opacity(glowIntensity), lineWidth: 1)\n                    )\n            )\n        }\n        .buttonStyle(PlainButtonStyle())\n        .onHover { hovering in\n            withAnimation(.easeInOut(duration: 0.2)) {\n                isHovered = hovering\n                glowIntensity = hovering ? 0.3 : 0\n            }\n        }\n        .task {\n            // Subtle pulse effect for high-spending categories\n            if currentSpending > 10000 {\n                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {\n                    glowIntensity = 0.2\n                }\n            }\n        }\n    }\n    \n    private func formatCurrency(_ amount: Decimal) -> String {\n        let formatter = NumberFormatter()\n        formatter.numberStyle = .currency\n        formatter.currencyCode = \"INR\"\n        formatter.locale = Locale(identifier: \"en_IN\")\n        formatter.maximumFractionDigits = 0\n        return formatter.string(from: NSDecimalNumber(decimal: amount))?.replacingOccurrences(of: \"₹\", with: \"\") ?? \"0\"\n    }\n}\n\n///category spending card with integrated sparkline\nstruct CategorySparklineCard: View {\n    let category: Category\n    let currentAmount: Decimal\n    let percentageOfTotal: Double\n    let monthlyTrend: [Double]\n    let weeklyTrend: [Double]\n    \n    @State private var selectedView: TrendView = .monthly\n    @State private var animationValue: Double = 0\n    \n    enum TrendView: String, CaseIterable {\n        case monthly = \"Monthly\"\n        case weekly = \"Weekly\"\n    }\n    \n    var categoryColor: Color {\n        Color(category.name)\n    }\n    \n    var currentTrend: [Double] {\n        selectedView == .monthly ? monthlyTrend : weeklyTrend\n    }\n    \n    var body: some View {\n        VStack(spacing: 12) {\n            // Header with category info\n            headerSection\n            \n            // View selector\n            pickerSection\n            \n            // Sparkline chart\n            SparklineChart(\n                data: currentTrend,\n                color: categoryColor,\n                style: .area,\n                showLabels: true\n            )\n            \n            // Stats row\n            statsSection\n        }\n        .padding(16)\n        .background(\n            RoundedRectangle(cornerRadius: 16)\n                .fill(Color(.secondarySystemBackground))\n                .shadow(color: categoryColor.opacity(0.1), radius: 8, x: 0, y: 4)\n        )\n        .task {\n            withAnimation(.easeInOut(duration: 1.5)) {\n                animationValue = 1.0\n            }\n        }\n    }\n    \n    private var headerSection: some View {\n        HStack {\n            Circle()\n                .fill(categoryColor)\n                .frame(width: 12, height: 12)\n            \n            Text(category.name)\n                .font(.headline)\n                .fontWeight(.semibold)\n            \n            Spacer()\n            \n            VStack(alignment: .trailing, spacing: 2) {\n                Text(formatCurrency(currentAmount))\n                    .font(.title3)\n                    .fontWeight(.bold)\n                    .scaleEffect(animationValue)\n                \n                Text(\"\\(String(format: \"%.1f\", percentageOfTotal))%\")\n                    .font(.caption)\n                    .foregroundColor(.secondary)\n            }\n        }\n    }\n    \n    private var pickerSection: some View {\n        Picker(\"Trend View\", selection: $selectedView) {\n            ForEach(TrendView.allCases) { view in\n                Text(view.rawValue).tag(view)\n            }\n        }\n        .pickerStyle(.segmented)\n        .frame(height: 28)\n    }\n    \n    private var statsSection: some View {\n        HStack {\n            if let current = currentTrend.last, let previous = currentTrend.dropLast().last {\n                let change = ((current - previous) / previous) * 100\n                \n                HStack(spacing: 4) {\n                    Image(systemName: change >= 0 ? \"arrow.up\" : \"arrow.down\")\n                        .font(.caption)\n                        .foregroundColor(change >= 0 ? .red : .green)\n                    \n                    Text(String(format: \"%.1f%% from last\", abs(change)))\n                        .font(.caption)\n                        .foregroundColor(.secondary)\n                }\n            }\n            \n            Spacer()\n            \n            Text(\"\\(currentTrend.count) periods\")\n                .font(.caption)\n                .foregroundColor(.secondary)\n        }\n    }\n    \n    private func formatCurrency(_ amount: Decimal) -> String {\n        let formatter = NumberFormatter()\n        formatter.numberStyle = .currency\n        formatter.currencyCode = \"INR\"\n        formatter.locale = Locale(identifier: \"en_IN\")\n        formatter.maximumFractionDigits = 0\n        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? \"₹0\"\n    }\n}\n\n#Preview {\n    ScrollView {\n        VStack(spacing: 16) {\n            SparklineChart(\n                data: [1000, 1500, 1200, 1800, 1600, 2000],\n                color: .blue,\n                style: .combination,\n                showLabels: true\n            )\n            \n            CompactSparklineWidget(\n                category: Category(id: UUID(), name: \"Food\", isDefault: true),\n                data: [3000, 3500, 3200, 4500],\n                currentSpending: 15000,\n                onTapAction: { _ in }\n            )\n            \n            CategorySparklineCard(\n                category: Category(id: UUID(), name: \"Transportation\", isDefault: true),\n                currentAmount: 8500,\n                percentageOfTotal: 18.9,\n                monthlyTrend: [6000, 7000, 6500, 8500],\n                weeklyTrend: [1500, 1750, 1600, 2125]\n            )\n        }\n        .padding()\n    }\n}