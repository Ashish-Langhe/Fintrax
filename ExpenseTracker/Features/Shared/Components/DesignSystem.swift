//
//  DesignSystem.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI
import UIKit

// MARK: - Design System

struct AppDesignSystem {
    struct AppShadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Colors
    
    struct Colors {
        // Primary Colors
        static let primary = Color(red: 0.25, green: 0.55, blue: 0.95)
        static let primaryLight = Color(red: 0.45, green: 0.75, blue: 0.95)
        static let primaryDark = Color(red: 0.15, green: 0.35, blue: 0.75)
        
        // Status Colors
        static let success = Color(red: 0.35, green: 0.75, blue: 0.35)
        static let warning = Color(red: 0.98, green: 0.65, blue: 0.25)
        static let error = Color(red: 0.95, green: 0.35, blue: 0.35)
        static let info = Color(red: 0.25, green: 0.75, blue: 0.85)
        
        // Neutral Colors
        static let background = Color.dynamic(
            light: UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.045, green: 0.055, blue: 0.075, alpha: 1)
        )
        static let surface = Color(.secondarySystemBackground)
        static let surfaceVariant = Color.dynamic(
            light: UIColor(red: 0.98, green: 0.96, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.075, green: 0.085, blue: 0.115, alpha: 1)
        )
        static let elevatedSurface = Color.dynamic(
            light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.105, green: 0.115, blue: 0.155, alpha: 1)
        )
        static let outline = Color(.separator).opacity(0.36)
        
        // Text Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Headings
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        
        // Body
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.semibold)
        static let callout = Font.callout
        static let calloutEmphasized = Font.callout.weight(.semibold)
        
        // Small Text
        static let subheadline = Font.subheadline.weight(.medium)
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        
        // Component-specific spacing
        static let cardPadding = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        static let sectionPadding = EdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24)
        static let listItemPadding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let card = [
            AppShadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4),
            AppShadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
        ]
        
        static let elevated = [
            AppShadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6),
            AppShadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 12)
        ]
        
        static let button = AppShadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        static let subtle = AppShadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Gradients
    
    struct Gradients {
        static let primary = LinearGradient(
            gradient: Gradient(colors: [Colors.primary, Colors.primaryLight]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let success = LinearGradient(
            gradient: Gradient(colors: [Colors.success, Colors.success.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warning = LinearGradient(
            gradient: Gradient(colors: [Colors.warning, Colors.warning.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let error = LinearGradient(
            gradient: Gradient(colors: [Colors.error, Colors.error.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let surface = LinearGradient(
            gradient: Gradient(colors: [Colors.surface, Colors.surfaceVariant]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let background = LinearGradient(
            gradient: Gradient(colors: [
                Colors.background,
                Colors.surfaceVariant,
                Colors.primary.opacity(0.08)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Component Styles
    
    struct ComponentStyles {
        // Cards
        static let standardCard: some View = EmptyView()
            .background(Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .shadow(color: Shadows.card[0].color, radius: Shadows.card[0].radius, x: Shadows.card[0].x, y: Shadows.card[0].y)
            .shadow(color: Shadows.card[1].color, radius: Shadows.card[1].radius, x: Shadows.card[1].x, y: Shadows.card[1].y)
        
        // Buttons
        static let primaryButton: some View = EmptyView()
            .background(Gradients.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .shadow(color: Shadows.button.color, radius: Shadows.button.radius, x: Shadows.button.x, y: Shadows.button.y)
        
        // Sections
        static let section: some View = EmptyView()
            .background(Gradients.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .shadow(color: Shadows.subtle.color, radius: Shadows.subtle.radius, x: Shadows.subtle.x, y: Shadows.subtle.y)
    }
}

// MARK: - View Extensions for Design System

extension View {
    func primaryGradient() -> some View {
        self.background(AppDesignSystem.Gradients.primary)
    }
    
    func cardStyle() -> some View {
        self
            .background(AppDesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.lg))
            .shadow(color: AppDesignSystem.Shadows.card[0].color, radius: AppDesignSystem.Shadows.card[0].radius, x: AppDesignSystem.Shadows.card[0].x, y: AppDesignSystem.Shadows.card[0].y)
            .shadow(color: AppDesignSystem.Shadows.card[1].color, radius: AppDesignSystem.Shadows.card[1].radius, x: AppDesignSystem.Shadows.card[1].x, y: AppDesignSystem.Shadows.card[1].y)
    }
    
    func sectionStyle() -> some View {
        self
            .background(AppDesignSystem.Gradients.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.lg))
            .shadow(color: AppDesignSystem.Shadows.subtle.color, radius: AppDesignSystem.Shadows.subtle.radius, x: AppDesignSystem.Shadows.subtle.x, y: AppDesignSystem.Shadows.subtle.y)
    }
    
    func designSpacing(_ amount: CGFloat) -> some View {
        self.padding(.all, amount)
    }
    
    func componentPadding() -> some View {
        self.padding(AppDesignSystem.Spacing.cardPadding)
    }
    
    func sectionPadding() -> some View {
        self.padding(AppDesignSystem.Spacing.sectionPadding)
    }
}

// MARK: - Shadow Helper

extension Color {
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    func radius(_ radius: CGFloat) -> Color {
        return self // Placeholder for shadow functionality
    }
    
    func x(_ x: CGFloat) -> Color {
        return self // Placeholder for shadow functionality
    }
    
    func y(_ y: CGFloat) -> Color {
        return self // Placeholder for shadow functionality
    }
}
