//
//  CurrencyInputField.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

/// Custom amount input field with INR currency formatting
struct CurrencyInputField: View {
    @Binding var value: Decimal
    let placeholder: String
    
    @State private var textValue = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text("₹")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $textValue)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .onChange(of: textValue) { _, newValue in
                    updateValue(from: newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            textValue = formatDecimal(value)
        }
    }
    
    /// Update the bound value from text input
    private func updateValue(from text: String) {
        // Remove currency symbol and any non-numeric characters except decimal point
        let cleanedText = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        
        // Convert to decimal
        value = Decimal(string: cleanedText) ?? Decimal(0)
        
        // Update display text to maintain consistent formatting
        if isFocused {
            textValue = cleanedText
        } else {
            textValue = formatDecimal(value)
        }
    }
    
    /// Format decimal value for display
    private func formatDecimal(_ decimal: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        
        let formatted = formatter.string(from: NSDecimalNumber(decimal: decimal)) ?? "₹0.00"
        return formatted.replacingOccurrences(of: "₹", with: "")
    }
}