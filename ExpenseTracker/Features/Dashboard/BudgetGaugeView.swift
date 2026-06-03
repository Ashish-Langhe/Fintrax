//
//  BudgetGaugeView.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI
import Charts

/// Advanced animated gauge indicator for budget visualization with progress rings
struct BudgetGaugeView: View {
    let spent: Decimal
    let budget: Decimal
    let categoryName: String
    let categoryColor: Color
    
    @State private var animatedProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private var spendingPercentage: Double {
        guard budget > 0 else { return 0 }
        return Double(truncating: (spent / budget) as NSNumber)
    }
    
    private var gaugeColor: Color {
        switch spendingPercentage {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange 
        case 0.8..<0.95: return .red
        default: return .red
        }
    }
    
    private var gaugeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                gaugeColor.opacity(0.8),
                gaugeColor,
                gaugeColor.opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated gauge ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .opacity(0.3)
                
                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        gaugeGradient,
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 0.8), value: animatedProgress)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), 
                              value: pulseScale)
                
                // Inner content
                VStack(spacing: 4) {
                    Text(formatCurrency(spent))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("of \(formatCurrency(budget))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(spendingPercentage * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(gaugeColor)
                }
            }
            .frame(width: 140, height: 140)
            
            // Category name with status indicator
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 8, height: 8)
                
                Text(categoryName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption2)
                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusBackgroundColor.opacity(0.2))
                .foregroundColor(statusBackgroundColor)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .task {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = min(spendingPercentage, 1.0)
            }
            
            // Add pulse effect for critical budgets
            if spendingPercentage >= 0.8 {
                pulseScale = 1.05
            }
        }
        .onChange(of: spendingPercentage) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = min(newValue, 1.0)
            }
            
            pulseScale = newValue >= 0.8 ? 1.05 : 1.0
        }
    }
    
    private var statusIcon: String {
        switch spendingPercentage {
        case 0..<0.5: return "checkmark.circle.fill"
        case 0.5..<0.8: return "exclamationmark.triangle.fill"
        case 0.8..<0.95: return "minus.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch spendingPercentage {
        case 0..<0.5: return "On Track"
        case 0.5..<0.8: return "Warning"
        case 0.8..<0.95: return "Critical"
        default: return "Exceeded"
        }
    }
    
    private var statusBackgroundColor: Color {
        switch spendingPercentage {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        case 0.8..<0.95: return .red
        default: return .red
        }
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

/// Compact budget gauge for dashboard grid
struct CompactBudgetGaugeView: View {
    let spent: Decimal
    let budget: Decimal
    let categoryName: String
    let categoryColor: Color
    
    @State private var animatedProgress: Double = 0
    
    private var spendingPercentage: Double {
        guard budget > 0 else { return 0 }
        return Double(truncating: (spent / budget) as NSNumber)
    }
    
    private var gaugeColor: Color {
        switch spendingPercentage {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 6, height: 6)
                
                Text(categoryName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(spendingPercentage * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(gaugeColor)
            }
            
            // Compact progress bar
            HStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                            .clipShape(Capsule())
                        
                        Rectangle()
                            .fill(gaugeColor)
                            .frame(width: geometry.size.width * animatedProgress, height: 4)
                            .clipShape(Capsule())
                            .animation(.easeInOut(duration: 0.8), value: animatedProgress)
                    }
                }
                .frame(height: 4)
            }
            
            HStack {
                Text(formatCurrency(spent))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("/ \(formatCurrency(budget))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
        .task {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = min(spendingPercentage, 1.0)
            }
        }
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
    ScrollView {
        VStack(spacing: 20) {
            BudgetGaugeView(
                spent: 15000,
                budget: 20000,
                categoryName: "Food & Dining",
                categoryColor: .red
            )
            
            BudgetGaugeView(
                spent: 8000,
                budget: 10000,
                categoryName: "Transportation",
                categoryColor: .blue
            )
            
            BudgetGaugeView(
                spent: 25000,
                budget: 20000,
                categoryName: "Shopping",
                categoryColor: .purple
            )
        }
        .padding()
    }
}