//
//  InteractiveDataCard.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI
import Charts

/// Rich visual data card with micro-interactions and haptic feedback
struct InteractiveDataCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let trendData: [Double]?
    let onTapAction: (() -> Void)?
    
    @State private var isPressed = false
    @State private var cardScale: CGFloat = 1.0
    @State private var glowEffect: Double = 0
    @State private var animatedValue: Double = 0
    
    var hasTrend: Bool {
        trendData != nil && !trendData!.isEmpty
    }
    
    init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        iconColor: Color = .blue,
        trendData: [Double]? = nil,
        onTapAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trendData = trendData
        self.onTapAction = onTapAction
    }
    
    var body: some View {
        Button(action: {
            triggerHapticFeedback()
            onTapAction?()
        }) {
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Main content
                mainContentSection
                
                // Footer with trend
                if hasTrend {
                    trendSection
                }
            }
            .padding(16)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                    
                    // Glow effect
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(iconColor.opacity(glowEffect), lineWidth: 2)
                        .opacity(glowEffect)
                    
                    // Background gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    iconColor.opacity(0.05),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .scaleEffect(cardScale)
            .shadow(
                color: iconColor.opacity(glowEffect * 0.3),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startValueAnimation()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        cardScale = 0.95
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        cardScale = 1.0
                        isPressed = false
                    }
                    
                    // Glow effect on release
                    withAnimation(.easeInOut(duration: 0.3)) {
                        glowEffect = 0.5
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            glowEffect = 0
                        }
                    }
                }
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            
            Spacer()
            
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Main Content Section
    
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Animated value display
                Text(formatAnimatedValue(animatedValue, formatStyle: value))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Trend Section
    
    private var trendSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Trend")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                trendIndicator
            }
            
            // Mini sparkline chart
            if let trendData = trendData, trendData.count > 1 {
                Chart {
                    ForEach(Array(trendData.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(iconColor.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    
                    // Gradient fill
                    ForEach(Array(trendData.enumerated()), id: \.offset) { index, value in
                        AreaMark(
                            x: .value("Index", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    iconColor.opacity(0.3),
                                    iconColor.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 40)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartAngleSelection(value: .constant(nil))
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Trend Indicator
    
    private var trendIndicator: some View {
        guard let trendData = trendData, trendData.count >= 2 else {
            return EmptyView()
        }
        
        let firstValue = trendData.first!
        let lastValue = trendData.last!
        let change = ((lastValue - firstValue) / firstValue) * 100
        
        return HStack(spacing: 4) {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
                .foregroundColor(change >= 0 ? .red : .green)
            
            Text(String(format: "%.1f%%", abs(change)))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(change >= 0 ? .red : .green)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill((change >= 0 ? .red : .green).opacity(0.1))
        )
    }
    
    // MARK: - Animation Methods
    
    private func startValueAnimation() {
        guard let numericValue = extractNumericValue(from: value) else {
            animatedValue = 0
            return
        }
        
        withAnimation(.easeInOut(duration: 1.2)) {
            animatedValue = numericValue
        }
    }
    
    private func formatAnimatedValue(_ value: Double, formatStyle: String) -> String {
        if formatStyle.contains("₹") {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "INR"
            formatter.locale = Locale(identifier: "en_IN")
            formatter.maximumFractionDigits = structure.largest(wallet))\.which(quantity .price. \").substrings){\n           (formatter.String(for: NSNumber(value: value)) ?? formatStyle)\n        } else {\n            return String(format: formatStyle, value)\n        }\n    }\n    \n    private func extractNumericValue(from: String) -> Double? {\n        // Extract numeric value from formatted string\n        let numericString = from.components(\n            separatedBy: CharacterSet.decimalDigits.inverted)\n            .joined()\n        return Double(numericString)\n    }\n    \n    private func triggerHapticFeedback() {\n        #if !os(macOS)\n        let impactFeedback = UIImpactFeedbackGenerator(style: .light)\n        impactFeedback.impactOccurred()\n        #endif\n    }\n}\n\n/// Specialized spending card with category breakdown\nstruct CategorySpendingCard: View {\n    let category: Category\n    let amount: Decimal\n    let percentage: Double\n    let trendData: [Double]?\n    let onTapAction: ((Category) -> Void)?\n    \n    @State private var isPressed = false\n    @State private var sparkleAnimation = false\n    \n    var body: some View {\n        InteractiveDataCard(\n            title: category.name,\n            value: formatCurrency(amount),\n            subtitle: \"\\(String(format: \"%.1f\", percentage))% of total spending\",\n            icon: categoryIcon,\n            iconColor: Color(category.name),\n            trendData: trendData\n        ) {\n            onTapAction?(category)\n        }\n        .overlay(\n            // Sparkle effect for top categories\n            percentage > 25 ? sparkleOverlay : nil\n        )\n    }\n    \n    private var categoryIcon: String {\n        switch category.name {\n        case \"Food\": return \"fork.knife\"\n        case \"Transportation\": return \"car.fill\"\n        case \"Entertainment\": return \"tv.fill\"\n        case \"Utilities\": return \"bolt.fill\"\n        case \"Health\": return \"heart.fill\"\n        case \"Shopping\": return \"bag.fill\"\n        default: return \"circle.fill\"\n        }\n    }\n    \n    private var sparkleOverlay: some View {\n        Rectangle()\n            .fill(Color.clear)\n            .overlay(\n                Image(systemName: \"sparkles\")\n                    .font(.caption)\n                    .foregroundColor(.yellow)\n                    .scaleEffect(sparkleAnimation ? 1.2 : 0.8)\n                    .opacity(sparkleAnimation ? 0.8 : 0)\n            )\n            .task {\n                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {\n                    sparkleAnimation = true\n                }\n            }\n    }\n    \n    private func formatCurrency(_ amount: Decimal) -> String {\n        let formatter = NumberFormatter()\n        formatter.numberStyle = .currency\n        formatter.currencyCode = \"INR\"\n        formatter.locale = Locale(identifier: \"en_IN\")\n        formatter.maximumFractionDigits = 0\n        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? \"₹0\"\n    }\n}\n\n/// Budget status card with progress visualization\nstruct BudgetStatusCard: View {\n    let budget: (Category, BudgetStatus, spent: Decimal, limit: Decimal)\n    let onTapAction: ((Category) -> Void)?\n    \n    @State private var progressAnimation: Double = 0\n    @State private var alertPulse = false\n    \n    var statusColor: Color {\n        switch budget.1 {\n        case .withinLimit: return .green\n        case .approachingLimit: return .orange\n        case .exceededLimit: return .red\n        }\n    }\n    \n    var statusIcon: String {\n        switch budget.1 {\n        case .withinLimit: return \"checkmark.shield.fill\"\n        case .approachingLimit: return \"exclamationmark.shield.fill\"\n        case .exceededLimit: return \"xmark.shield.fill\"\n        }\n    }\n    \n    var spendingPercentage: Double {\n        guard budget.limit > 0 else { return 0 }\n        return Double(truncating: (budget.spent / budget.limit) as NSNumber)\n    }\n    \n    var body: some View {\n        InteractiveDataCard(\n            title: \"\\(budget.0.name) Budget\",\n            value: formatCurrency(budget.spent),\n            subtitle: \"of \\(formatCurrency(budget.limit)) limit\",\n            icon: statusIcon,\n            iconColor: statusColor,\n            trendData: generateTrendData()\n        ) {\n            onTapAction?(budget.0)\n        }\n        .overlay(\n            // Alert badge for critical budgets\n            spendingPercentage >= 0.8 ? alertBadge : nil\n        )\n        .task {\n            withAnimation(.easeInOut(duration: 1.5)) {\n                progressAnimation = min(spendingPercentage, 1.0)\n            }\n        }\n        .onChange(of: spendingPercentage) { _, newValue in\n            withAnimation(.easeInOut(duration: 0.8)) {\n                progressAnimation = min(newValue, 1.0)\n            }\n        }\n    }\n    \n    private var alertBadge: some View {\n        VStack {\n            HStack {\n                Spacer()\n                Circle()\n                    .fill(statusColor)\n                    .frame(width: 8, height: 8)\n                    .scaleEffect(alertPulse ? 1.5 : 1.0)\n                    .opacity(alertPulse ? 0.6 : 1.0)\n            }\n            Spacer()\n        }\n        .task {\n            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {\n                alertPulse = true\n            }\n        }\n    }\n    \n    private func generateTrendData() -> [Double] {\n        // Generate mock trend data based on spending percentage\n        let baseValue = spendingPercentage * 100\n        return [\n            baseValue * 0.8,\n            baseValue * 0.9,\n            baseValue * 0.85,\n            baseValue\n        ]\n    }\n    \n    private func formatCurrency(_ amount: Decimal) -> String {\n        let formatter = NumberFormatter()\n        formatter.numberStyle = .currency\n        formatter.currencyCode = \"INR\"\n        formatter.locale = Locale(identifier: \"en_IN\")\n        formatter.maximumFractionDigits = 0\n        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? \"₹0\"\n    }\n}\n\n#Preview {\n    ScrollView {\n        VStack(spacing: 16) {\n            InteractiveDataCard(\n                title: \"Total Spending\",\n                value: \"₹45,000\",\n                subtitle: \"This month\",\n                icon: \"indianrupeesign.circle.fill\",\n                iconColor: .blue,\n                trendData: [30000, 35000, 32000, 45000],\n                onTapAction: { }\n            )\n            \n            CategorySpendingCard(\n                category: Category(id: UUID(), name: \"Food\", isDefault: true),\n                amount: 15000,\n                percentage: 33.3,\n                trendData: [12000, 13000, 14000, 15000],\n                onTapAction: { _ in }\n            )\n            \n            BudgetStatusCard(\n                budget: (\n                    Category(id: UUID(), name: \"Transportation\", isDefault: true),\n                    .approachingLimit(percentage: 0.85),\n                    8500,\n                    10000\n                ),\n                onTapAction: { _ in }\n            )\n        }\n        .padding()\n    }\n}