//
//  SimpleBudgetProgressView.swift
//  Fintrax
//
//  Fintrax documentation: Builds budget creation, update, progress, and budget insight UI.
//

import SwiftUI

/// Simple progress view for budget status
struct SimpleBudgetProgressView: View {
    let spent: Decimal
    let budget: Decimal
    let status: BudgetStatus
    
    private var spendingPercentage: Double {
        guard budget > 0 else { return 0 }
        return Double(truncating: (spent / budget) as NSNumber)
    }
    
    private var progressColor: Color {
        switch status {
        case .withinLimit:
            return .green
        case .approachingLimit:
            return .orange
        case .exceededLimit:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            ProgressView(value: spendingPercentage, total: 1.0)
                .tint(progressColor)
                .scaleEffect(x: 1, y: 2)
            
            HStack {
                Text("\(Int(spendingPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(progressColor)
                
                Spacer()
                
                Text(currencyFormat(spent))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if budget > 0 {
                Text(L10n.format("common.ofValue", currencyFormat(budget)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func currencyFormat(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0"
    }
}
