//
//  EnhancedBackgroundStyles.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

// MARK: - Enhanced Background Styles

struct EnhancedBackgroundModifier: ViewModifier {
    let backgroundType: BackgroundType
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    enum BackgroundType {
        case main
        case card
        case header
        case section
        case subtle
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundGradient)
            .scaleEffect(responsiveScale)
    }
    
    @ViewBuilder
    private var backgroundGradient: some View {
        switch backgroundType {
        case .main:
            LinearGradient(
                gradient: Gradient(colors: mainGradientColors),
                startPoint: responsiveStartPoint,
                endPoint: responsiveEndPoint
            )
        case .card:
            LinearGradient(
                gradient: Gradient(colors: cardGradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
        case .header:
            LinearGradient(
                gradient: Gradient(colors: headerGradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
        case .section:
            LinearGradient(
                gradient: Gradient(colors: sectionGradientColors),
                startPoint: responsiveStartPoint,
                endPoint: responsiveEndPoint
            )
        case .subtle:
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.3),
                    Color.clear
                ]),
                center: .center,
                startRadius: responsiveStartRadius,
                endRadius: responsiveEndRadius
            )
        }
    }
    
    // MARK: - Responsive Properties
    
    private var mainGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.1, green: 0.15, blue: 0.3),
                Color(red: 0.15, green: 0.1, blue: 0.2)
            ]
        } else {
            return [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 0.97)
            ]
        }
    }
    
    private var cardGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color.black.opacity(0.3),
                Color.black.opacity(0.5)
            ]
        } else {
            return [
                Color.white.opacity(0.9),
                Color.white.opacity(0.7)
            ]
        }
    }
    
    private var headerGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color.blue.opacity(0.2),
                Color.blue.opacity(0.1)
            ]
        } else {
            return [
                Color.blue.opacity(0.1),
                Color.blue.opacity(0.05)
            ]
        }
    }
    
    private var sectionGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.2, green: 0.2, blue: 0.25),
                Color(red: 0.15, green: 0.15, blue: 0.2)
            ]
        } else {
            return [
                Color(red: 0.96, green: 0.96, blue: 0.98),
                Color(red: 0.94, green: 0.94, blue: 0.96)
            ]
        }
    }
    
    private var responsiveStartPoint: UnitPoint {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .regular):
            return .topLeading
        case (.compact, .compact):
            return .top
        case (.regular, .regular):
            return .topLeading
        default:
            return .topLeading
        }
    }
    
    private var responsiveEndPoint: UnitPoint {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .regular):
            return .bottomTrailing
        case (.compact, .compact):
            return .bottom
        case (.regular, .regular):
            return .bottomTrailing
        default:
            return .bottomTrailing
        }
    }
    
    private var responsiveStartRadius: CGFloat {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .compact):
            return 30
        case (.compact, .regular):
            return 50
        case (.regular, .regular):
            return 80
        default:
            return 50
        }
    }
    
    private var responsiveEndRadius: CGFloat {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .compact):
            return 120
        case (.compact, .regular):
            return 200
        case (.regular, .regular):
            return 300
        default:
            return 200
        }
    }
    
    private var responsiveScale: CGFloat {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .compact):
            return 0.95
        case (.compact, .regular), (.regular, .compact):
            return 1.0
        case (.regular, .regular):
            return 1.05
        default:
            return 1.0
        }
    }
}

// MARK: - Pattern Overlay Modifier

struct PatternOverlayModifier: ViewModifier {
    let patternType: PatternType
    
    enum PatternType {
        case dots
        case grid
        case diagonal
        case subtle
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(patternOverlay.opacity(0.03))
    }
    
    @ViewBuilder
    private var patternOverlay: some View {
        switch patternType {
        case .dots:
            Canvas { context, size in
                let spacing: CGFloat = 20
                let maxDots = 100 // Performance limit
                
                var dotCount = 0
                for x in stride(from: 0, through: size.width, by: spacing) {
                    for y in stride(from: 0, through: size.height, by: spacing) {
                        if dotCount >= maxDots { break }
                        context.fill(
                            Path(ellipseIn: CGRect(x: x-1, y: y-1, width: 2, height: 2)),
                            with: .color(.black)
                        )
                        dotCount += 1
                    }
                    if dotCount >= maxDots { break }
                }
            }
            .drawingGroup(opaque: false, colorMode: .nonLinear)
        case .grid:
            Canvas { context, size in
                let spacing: CGFloat = 30
                context.stroke(
                    Path { path in
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for y in stride(from: 0, through: size.height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                    },
                    with: .color(.black),
                    lineWidth: 0.5
                )
            }
        case .diagonal:
            Canvas { context, size in
                let spacing: CGFloat = 25
                context.stroke(
                    Path { path in
                        for i in stride(from: -size.height, through: size.width, by: spacing) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i + size.height, y: size.height))
                        }
                    },
                    with: .color(.black),
                    lineWidth: 0.5
                )
            }
        case .subtle:
            Canvas { context, size in
                for _ in 0..<50 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let radius = CGFloat.random(in: 1...3)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2)),
                        with: .color(.blue.opacity(0.1))
                    )
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func enhancedBackground(_ type: EnhancedBackgroundModifier.BackgroundType) -> some View {
        self.modifier(EnhancedBackgroundModifier(backgroundType: type))
    }
    
    func patternOverlay(_ type: PatternOverlayModifier.PatternType) -> some View {
        self.modifier(PatternOverlayModifier(patternType: type))
    }
    
    func cardStyle() -> some View {
        self
            .enhancedBackground(.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
            .patternOverlay(.dots)
    }
    
    func sectionStyle() -> some View {
        self
            .enhancedBackground(.section)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 6)
            .patternOverlay(.subtle)
    }
}

// MARK: - Preview for Testing

struct EnhancedBackgroundStyles_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone SE (compact)
            VStack {
                Text("Main Background")
                    .frame(height: 100)
                    .enhancedBackground(.main)
                Text("Card Style")
                    .frame(height: 100)
                    .cardStyle()
                Text("Section Style")
                    .frame(height: 100)
                    .sectionStyle()
            }
            .previewDevice("iPhone SE (2nd generation)")
            
            // iPhone 14 Pro (compact/regular)
            VStack {
                Text("Main Background")
                    .frame(height: 100)
                    .enhancedBackground(.main)
                Text("Card Style")
                    .frame(height: 100)
                    .cardStyle()
                Text("Section Style")
                    .frame(height: 100)
                    .sectionStyle()
            }
            .previewDevice("iPhone 14 Pro")
            
            // iPad Air (regular/regular)
            VStack {
                Text("Main Background")
                    .frame(height: 100)
                    .enhancedBackground(.main)
                Text("Card Style")
                    .frame(height: 100)
                    .cardStyle()
                Text("Section Style")
                    .frame(height: 100)
                    .sectionStyle()
            }
            .previewDevice("iPad Air (5th generation)")
            
            // Dark mode test
            VStack {
                Text("Main Background - Dark")
                    .frame(height: 100)
                    .enhancedBackground(.main)
                Text("Card Style - Dark")
                    .frame(height: 100)
                    .cardStyle()
                Text("Section Style - Dark")
                    .frame(height: 100)
                    .sectionStyle()
            }
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 14 Pro")
        }
    }
}