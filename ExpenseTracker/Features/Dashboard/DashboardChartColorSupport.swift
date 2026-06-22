//
//  DashboardChartColorSupport.swift
//  Fintrax
//

import SwiftUI

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
