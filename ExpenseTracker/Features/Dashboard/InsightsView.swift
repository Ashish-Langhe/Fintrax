//
//  InsightsView.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI

/// Personalized insights with visually appealing callout cards
struct InsightsView: View {
    let dashboardData: DashboardData
    let userPreferences: UserPreferences
    
    @State private var expandedInsight: InsightType?
    @State private var animationScale: CGFloat = 0.8
    @State private var pulseEffect: Double = 0
    
    enum InsightType: String, CaseIterable, Identifiable {
        case spendingTrends = "Spending Trends"
        case budgetAlerts = "Budget Alerts" 
        case categoryAnalysis = "Category Analysis"
        case savingsOpportunities = "Savings Opportunities"
        case spendingPatterns = "Spending Patterns"
        case recommendations = "Recommendations"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .spendingTrends: return "chart.line.uptrend.xyaxis"
            case .budgetAlerts: return "exclamationmark.triangle.fill"
            case .categoryAnalysis: return "chart.pie.fill"
            case .savingsOpportunities: return "banknote.fill"
            case .spendingPatterns: return "calendar"
            case .recommendations: return "lightbulb.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .spendingTrends: return .blue
            case .budgetAlerts: return .red
            case .categoryAnalysis: return .purple
            case .savingsOpportunities: return .green
            case .spendingPatterns: return .orange
            case .recommendations: return .yellow
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            headerSection
            
            // Insights grid
            insightsGrid
            
            // Expanded insight details
            if let expandedInsight = expandedInsight {
                expandedInsightView(expandedInsight)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .task {
            startAnimation()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Personalized Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("For You")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))
                )
            }
            
            Text("Discover patterns and opportunities in your spending")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
    
    // MARK: - Insights Grid
    
    private var insightsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(InsightType.allCases) { insightType in
                InsightCard(
                    type: insightType,
                    insights: generateInsights(for: insightType),
                    isExpanded: expandedInsight == insightType,
                    animationScale: animationScale
                ) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        expandedInsight = expandedInsight == insightType ? nil : insightType
                    }
                }
                .scaleEffect(1.0 + pulseEffect * (expandedInsight == insightType ? 0.02 : 0))
            }
        }
    }
    
    // MARK: - Expanded Insight View
    
    private func expandedInsightView(_ type: InsightType) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: type.iconName)
                    .font(.title3)
                    .foregroundColor(type.color)
                
                Text(type.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        expandedInsight = nil
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Detailed insights
            ForEach(generateDetailedInsights(for: type), id: \\.self) { insight in
                DetailedInsightCard(insight: insight)
            }
            
            // Action buttons
            actionButtons(for: type)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Action Buttons
    
    private func actionButtons(for type: InsightType) -> some View {
        HStack(spacing: 12) {
            Button(action: {\n                // Action based on insight type\n            }) {\n                HStack(spacing: 6) {\n                    Image(systemName: actionIcon(for: type))\n                        .font(.caption)\n                    Text(actionTitle(for: type))\n                        .font(.caption)\n                        .fontWeight(.medium)\n                }\n                .padding(.horizontal, 12)\n                .padding(.vertical, 6)\n                .background(type.color)\n                .foregroundColor(.white)\n                .clipShape(Capsule())\n            }\n            \n            Spacer()\n            \n            Button(\"Learn More\") {\n                // Navigate to detailed view\n            }\n            .font(.caption)\n            .foregroundColor(type.color)\n        }\n    }\n    \n    // MARK: - Animation Methods\n    \n    private func startAnimation() {\n        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {\n            animationScale = 1.0\n        }\n        \n        // Subtle pulse effect for important insights\n        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {\n            pulseEffect = 1.0\n        }\n    }\n    \n    // MARK: - Insight Generation Methods\n    \n    private func generateInsights(for type: InsightType) -> [String] {\n        switch type {\n        case .spendingTrends:\n            return [\n                \"Spending up 15% this month\",\n                \"Food expenses at yearly high\",\n                \"Transportation costs stable\"\n            ]\n        case .budgetAlerts:\n            return [\n                \"2 budgets exceeded\",\n                \"1 category approaching limit\",\n                \"Emergency fund low\"\n            ]\n        case .categoryAnalysis:\n            return [\n                \"Food dominates spending\",\n                \"Entertainment up 30%\",\n                \"Utilities under budget\"\n            ]\n        case .savingsOpportunities:\n            return [\n                \"₹5,000 potential savings\",\n                \"Subscriptions to review\",\n                \"Dining out frequency high\"\n            ]\n        case .spendingPatterns:\n            return [\n                \"Weekend spending higher\",\n                \"Monthly peak around 15th\",\n                \"Seasonal patterns detected\"\n            ]\n        case .recommendations:\n            return [\n                \"Set weekly limit\",\n                \"Review subscriptions\",\n                \"Consider meal planning\"\n            ]\n        }\n    }\n    \n    private func generateDetailedInsights(for type: InsightType) -> [DetailedInsight] {\n        switch type {\n        case .spendingTrends:\n            return [\n                DetailedInsight(\n                    title: \"Monthly Trend Analysis\",\n                    description: \"Your spending has increased by 15% compared to last month. This is primarily driven by increased food expenses.\",\n                    impact: .medium,\n                    actionable: true,\n                    category: .trend\n                ),\n                DetailedInsight(\n                    title: \"Category Performance\",\n                    description: \"Food expenses have reached their highest level this year, representing 40% of total spending.\",\n                    impact: .high,\n                    actionable: true,\n                    category: .category\n                )\n            ]\n        case .budgetAlerts:\n            return [\n                DetailedInsight(\n                    title: \"Budget Exceeded\",\n                    description: \"Entertainment budget exceeded by ₹2,000. Consider deferring non-essential expenses.\",\n                    impact: .high,\n                    actionable: true,\n                    category: .budget\n                )\n            ]\n        default:\n            return []\n        }\n    }\n    \n    private func actionIcon(for type: InsightType) -> String {\n        switch type {\n        case .spendingTrends: return \"chart.bar.fill\"\n        case .budgetAlerts: return \"pencil\"\n        case .categoryAnalysis: return \"list.bullet\"\n        case .savingsOpportunities: return \"plus.circle.fill\"\n        case .spendingPatterns: return \"calendar.badge.plus\"\n        case .recommendations: return \"arrow.right.circle.fill\"\n        }\n    }\n    \n    private func actionTitle(for type: InsightType) -> String {\n        switch type {\n        case .spendingTrends: return \"View Details\"\n        case .budgetAlerts: return \"Adjust Budgets\"\n        case .categoryAnalysis: return \"Analyze\"\n        case .savingsOpportunities: return \"Save Now\"\n        case .spendingPatterns: return \"Track habits\"\n        case .recommendations: return \"Apply\"\n        }\n    }\n}\n\n// MARK: - Insight Card Component\n\nstruct InsightCard: View {\n    let type: InsightsView.InsightType\n    let insights: [String]\n    let isExpanded: Bool\n    let animationScale: CGFloat\n    let onTapAction: () -> Void\n    \n    @State private var shimmerOffset: CGFloat = -200\n    @State private var pulseIntensity: Double = 0\n    \n    var hasImportantInsight: Bool {\n        insights.contains(where: { $0.lowercased().contains(\"exceeded\") || $0.lowercased().contains(\"alert\") })\n    }\n    \n    var body: some View {\n        Button(action: onTapAction) {\n            VStack(alignment: .leading, spacing: 12) {\n                // Header with icon\n                HStack {\n                    ZStack {\n                        Circle()\n                            .fill(type.color.opacity(0.15))\n                            .frame(width: 32, height: 32)\n                        \n                        Image(systemName: type.iconName)\n                            .font(.system(size: 14, weight: .medium))\n                            .foregroundColor(type.color)\n                    }\n                    \n                    Spacer()\n                    \n                    if hasImportantInsight {\n                        Circle()\n                            .fill(.red)\n                            .frame(width: 8, height: 8)\n                            .scaleEffect(pulseIntensity)\n                    }\n                }\n                \n                // Title\n                Text(type.rawValue)\n                    .font(.subheadline)\n                    .fontWeight(.semibold)\n                    .foregroundColor(.primary)\n                    .lineLimit(1)\n                \n                // Insights preview\n                VStack(alignment: .leading, spacing: 4) {\n                    ForEach(Array(insights.prefix(2)), id: \\.self) { insight in\n                        HStack(spacing: 6) {\n                            Circle()\n                                .fill(type.color.opacity(0.6))\n                                .frame(width: 4, height: 4)\n                            \n                            Text(insight)\n                                .font(.caption)\n                                .foregroundColor(.secondary)\n                                .lineLimit(1)\n                        }\n                    }\n                }\n                \n                // Footer\n                HStack {\n                    Text(\"\\(insights.count) insights\")\n                        .font(.caption2)\n                        .foregroundColor(.secondary)\n                    \n                    Spacer()\n                    \n                    if isExpanded {\n                        Image(systemName: \"chevron.up\")\n                            .font(.caption2)\n                    } else {\n                        Image(systemName: \"chevron.right\")\n                            .font(.caption2)\n                    }\n                }\n            }\n            .padding(16)\n            .background(\n                ZStack {\n                    // Base background\n                    RoundedRectangle(cornerRadius: 16)\n                        .fill(Color(.tertiarySystemBackground))\n                    \n                    // Shimmer effect for important insights\n                    if hasImportantInsight {\n                        RoundedRectangle(cornerRadius: 16)\n                            .fill(\n                                LinearGradient(\n                                    gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),\n                                    startPoint: .leading,\n                                    endPoint: .trailing\n                                )\n                            )\n                            .offset(x: shimmerOffset)\n                    }\n                }\n            )\n            .overlay(\n                RoundedRectangle(cornerRadius: 16)\n                    .stroke(\n                        isExpanded ? type.color.opacity(0.5) : Color.clear,\n                        lineWidth: 2\n                    )\n            )\n            .scaleEffect(animationScale)\n        }\n        .buttonStyle(PlainButtonStyle())\n        .task {\n            if hasImportantInsight {\n                // Start shimmer animation\n                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {\n                    shimmerOffset = 200\n                }\n                \n                // Pulse notification dot\n                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {\n                    pulseIntensity = 1.3\n                }\n            }\n        }\n    }\n}\n\n// MARK: - Detailed Insight Card\n\nstruct DetailedInsightCard: View {\n    let insight: DetailedInsight\n    \n    @State private var showFullDescription = false\n    \n    var impactColor: Color {\n        switch insight.impact {\n        case .low: return .green\n        case .medium: return .orange\n        case .high: return .red\n        }\n    }\n    \n    var body: some View {\n        VStack(alignment: .leading, spacing: 8) {\n            HStack(alignment: .top, spacing: 12) {\n                // Impact indicator\n                Circle()\n                    .fill(impactColor.opacity(0.2))\n                    .frame(width: 24, height: 24)\n                    .overlay(\n                        Circle()\n                            .fill(impactColor)\n                            .frame(width: 12, height: 12)\n                    )\n                \n                // Content\n                VStack(alignment: .leading, spacing: 4) {\n                    Text(insight.title)\n                        .font(.subheadline)\n                        .fontWeight(.medium)\n                        .foregroundColor(.primary)\n                    \n                    Text(insight.description)\n                        .font(.caption)\n                        .foregroundColor(.secondary)\n                        .lineLimit(showFullDescription ? nil : 2)\n                        .onTapGesture {\n                            withAnimation(.easeInOut(duration: 0.3)) {\n                                showFullDescription.toggle()\n                            }\n                        }\n                    \n                    // Tags\n                    HStack(spacing: 6) {\n                        ForEach(insight.tags, id: \\.self) { tag in\n                            Text(tag)\n                                .font(.caption2)\n                                .padding(.horizontal, 6)\n                                .padding(.vertical, 2)\n                                .background(\n                                    RoundedRectangle(cornerRadius: 6)\n                                        .fill(Color(.systemGray6))\n                                )\n                        }\n                    }\n                }\n                \n                Spacer()\n                \n                // Action indicator\n                if insight.actionable {\n                    Image(systemName: \"arrow.right.circle\")\n                        .font(.caption)\n                        .foregroundColor(.blue)\n                }\n            }\n        }\n        .padding(12)\n        .background(\n            RoundedRectangle(cornerRadius: 12)\n                .fill(Color(.secondarySystemBackground))\n        )\n    }\n}\n\n// MARK: - Data Models\n\nstruct DetailedInsight: Identifiable {\n    let id = UUID()\n    let title: String\n    let description: String\n    let impact: ImpactLevel\n    let actionable: Bool\n    let category: InsightCategory\n    let timestamp = Date()\n    \n    var tags: [String] {\n        var tags = [category.rawValue]\n        if actionable {\n            tags.append(\"Actionable\")\n        }\n        return tags\n    }\n}\n\nenum ImpactLevel: String, CaseIterable {\n    case low = \"Low\"\n    case medium = \"Medium\" \n    case high = \"High\"\n}\n\nenum InsightCategory: String, CaseIterable {\n    case trend = \"Trend\"\n    case budget = \"Budget\"\n    case category = \"Category\"\n    case pattern = \"Pattern\"\n    case recommendation = \"Recommendation\"\n}\n\nstruct UserPreferences {\n    let focusAreas: [InsightCategory]\n    let sensitivityToAlerts: SensitivityLevel\n    let preferredInsightTypes: [InsightsView.InsightType]\n}\n\nenum SensitivityLevel: String, CaseIterable {\n    case conservative = \"Conservative\"\n    case moderate = \"Moderate\"\n    case aggressive = \"Aggressive\"\n}\n\n#Preview {\n    ScrollView {\n        InsightsView(\n            dashboardData: DashboardData.generate(\n                from: [],\n                categories: [],\n                budgets: []\n            ),\n            userPreferences: UserPreferences(\n                focusAreas: [.trend, .budget],\n                sensitivityToAlerts: .moderate,\n                preferredInsightTypes: [.spendingTrends, .budgetAlerts]\n            )\n        )\n        .padding()\n    }\n}