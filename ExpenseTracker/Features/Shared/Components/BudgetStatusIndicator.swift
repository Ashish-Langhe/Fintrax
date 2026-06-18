//
//  BudgetStatusIndicator.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

/// Component for displaying budget status with visual indicators
struct BudgetStatusIndicator: View {
    let category: Category
    let budgetStatus: BudgetStatus
    let spending: Decimal
    let onCategorySelected: (Category) -> Void
    
    var body: some View {
        Button(action: {
            onCategorySelected(category)
        }) {
            HStack(spacing: 12) {
                // Status icon
                statusIcon
                
                // Category and budget info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(budgetStatus.message)
                        .font(.caption)
                        .foregroundColor(statusColor.opacity(0.8))
                }
                
                Spacer()
                
                // Spend amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(spending))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(L10n.format("common.ofValue", formatCurrency(limit)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(statusBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Status Icon
    
    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 32, height: 32)
            
            Image(systemName: statusIconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(statusColor)
        }
    }
    
    // MARK: - Status Properties
    
    private var statusColor: Color {
        switch budgetStatus {
        case .withinLimit:
            return .green
        case .approachingLimit:
            return .orange
        case .exceededLimit:
            return .red
        }
    }
    
    private var statusBackground: Color {
        switch budgetStatus {
        case .withinLimit:
            return Color.green.opacity(0.05)
        case .approachingLimit:
            return Color.orange.opacity(0.05)
        case .exceededLimit:
            return Color.red.opacity(0.05)
        }
    }
    
    private var statusIconName: String {
        switch budgetStatus {
        case .withinLimit:
            return "checkmark.circle.fill"
        case .approachingLimit:
            return "exclamationmark.triangle.fill"
        case .exceededLimit:
            return "xmark.circle.fill"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0"
    }
    
    // Get the budget limit - for this component, we might need to pass it or calculate differently
    private var limit: Decimal {
        // This is a placeholder - in a real implementation, you'd get this from the budget
        // For now, we'll estimate based on the percentage, avoiding division by zero
        let percentage = budgetStatus.percentage
        guard percentage > 0 else { return Decimal.zero }
        return spending / Decimal(percentage)
    }
}

/// Simplified budget status indicator for compact display
struct CompactBudgetStatusIndicator: View {
    let budgetStatus: BudgetStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusColorName)
                .font(.caption2)
                .foregroundColor(statusColor)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch budgetStatus {
        case .withinLimit:
            return .green
        case .approachingLimit:
            return .orange
        case .exceededLimit:
            return .red
        }
    }
    
    private var statusColorName: String {
        switch budgetStatus {
        case .withinLimit:
            return "On Track"
        case .approachingLimit:
            return "Warning"
        case .exceededLimit:
            return "Exceeded"
        }
    }
}

/// Progress bar style budget status indicator
struct BudgetProgressBar: View {
    let budgetStatus: BudgetStatus
    let spending: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Budget Used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(budgetStatus.percentage * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                        .clipShape(Capsule())
                    
                    // Progress bar
                    Rectangle()
                        .fill(statusColor)
                        .frame(
                            width: min(geometry.size.width * Double(budgetStatus.percentage), geometry.size.width),
                            height: 6
                        )
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.3), value: budgetStatus.percentage)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var statusColor: Color {
        switch budgetStatus {
        case .withinLimit:
            return .green
        case .approachingLimit:
            return .orange
        case .exceededLimit:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        // Full budget status indicator
        BudgetStatusIndicator(
            category: Category(id: UUID(), name: "Food", isDefault: true),
            budgetStatus: .approachingLimit(percentage: 0.85),
            spending: 8500,
            onCategorySelected: { _ in }
        )
        
        BudgetStatusIndicator(
            category: Category(id: UUID(), name: "Transportation", isDefault: true),
            budgetStatus: .exceededLimit(percentage: 1.15),
            spending: 11500,
            onCategorySelected: { _ in }
        )
        
        BudgetStatusIndicator(
            category: Category(id: UUID(), name: "Entertainment", isDefault: true),
            budgetStatus: .withinLimit(percentage: 0.45),
            spending: 4500,
            onCategorySelected: { _ in }
        )
        
        Divider()
        
        // Compact indicator
        HStack(spacing: 12) {
            CompactBudgetStatusIndicator(budgetStatus: .withinLimit(percentage: 0.45))
            CompactBudgetStatusIndicator(budgetStatus: .approachingLimit(percentage: 0.85))
            CompactBudgetStatusIndicator(budgetStatus: .exceededLimit(percentage: 1.15))
        }
        
        Divider()
        
        // Progress bar
        BudgetProgressBar(budgetStatus: .withinLimit(percentage: 0.45), spending: 4500)
        BudgetProgressBar(budgetStatus: .approachingLimit(percentage: 0.85), spending: 8500)
        BudgetProgressBar(budgetStatus: .exceededLimit(percentage: 1.15), spending: 11500)
    }
    .padding()
}
