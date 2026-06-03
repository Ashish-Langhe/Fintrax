//
//  EnhancedBorders.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

// MARK: - Enhanced Borders

struct EnhancedBorderModifier: ViewModifier {
    let borderType: BorderType
    let color: Color
    let width: CGFloat
    let cornerRadius: CGFloat
    
    enum BorderType {
        case solid
        case gradient
        case dashed
        case dotted
        case glow
        case rounded
    }
    
    init(
        borderType: BorderType = .solid,
        color: Color = .blue,
        width: CGFloat = 1,
        cornerRadius: CGFloat = 12
    ) {
        self.borderType = borderType
        self.color = color
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        switch borderType {
        case .solid:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(color, lineWidth: width)
                )
        case .gradient:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color,
                                    color.opacity(0.6),
                                    color.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: width
                        )
                )
        case .dashed:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            color,
                            style: StrokeStyle(
                                lineWidth: width,
                                lineCap: .round,
                                dash: [8, 4]
                            )
                        )
                )
        case .dotted:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            color,
                            style: StrokeStyle(
                                lineWidth: width,
                                lineCap: .round,
                                dash: [2, 3]
                            )
                        )
                )
        case .glow:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(color.opacity(0.5), lineWidth: width)
                )
        case .rounded:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.8),
                                    color.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: width
                        )
                )
        }
    }
}

// MARK: - Enhanced Spacing

struct EnhancedSpacingModifier: ViewModifier {
    let spacingType: SpacingType
    let padding: EdgeInsets
    let margin: EdgeInsets
    
    enum SpacingType {
        case compact
        case comfortable
        case spacious
        case custom(padding: EdgeInsets, margin: EdgeInsets)
    }
    
    init(spacingType: SpacingType) {
        self.spacingType = spacingType
        
        switch spacingType {
        case .compact:
            self.padding = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            self.margin = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .comfortable:
            self.padding = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
            self.margin = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .spacious:
            self.padding = EdgeInsets(top: 24, leading: 28, bottom: 24, trailing: 28)
            self.margin = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        case .custom(let padding, let margin):
            self.padding = padding
            self.margin = margin
        }
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .padding(margin)
    }
}

// MARK: - Card Enhancement

struct CardEnhancement: ViewModifier {
    let style: CardStyle
    
    enum CardStyle {
        case basic
        case elevated
        case outlined
        case glass
        case premium
    }
    
    func body(content: Content) -> some View {
        switch style {
        case .basic:
            content
                .padding(.comfortable)
                .enhancedBorder(.solid, color: .gray.opacity(0.3), width: 1)
                .background(Color(.secondarySystemBackground))
        case .elevated:
            content
                .padding(.comfortable)
                .enhancedBorder(.gradient, color: .blue, width: 1)
                .background(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        case .outlined:
            content
                .padding(.comfortable)
                .enhancedBorder(.dashed, color: .blue.opacity(0.6), width: 1.5)
                .background(Color(.tertiarySystemBackground))
        case .glass:
            content
                .padding(.comfortable)
                .enhancedBorder(.glow, color: .blue, width: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        case .premium:
            content
                .padding(.spacious)
                .enhancedBorder(.rounded, color: .blue, width: 2)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.05),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
    }
}

// MARK: - View Extensions

extension View {
    func enhancedBorder(_ type: EnhancedBorderModifier.BorderType, color: Color, width: CGFloat = 1, cornerRadius: CGFloat = 12) -> some View {
        self.modifier(EnhancedBorderModifier(borderType: type, color: color, width: width, cornerRadius: cornerRadius))
    }
    
    func enhancedSpacing(_ type: EnhancedSpacingModifier.SpacingType) -> some View {
        self.modifier(EnhancedSpacingModifier(spacingType: type))
    }
    
    func cardEnhancement(_ style: CardEnhancement.CardStyle) -> some View {
        self.modifier(CardEnhancement(style: style))
    }
}

// MARK: - Convenience Spacing Types

extension EnhancedSpacingModifier.SpacingType {
    static let compact = Self.compact
    static let comfortable = Self.comfortable
    static let spacious = Self.spacious
}