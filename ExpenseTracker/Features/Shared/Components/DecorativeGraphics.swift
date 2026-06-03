//
//  DecorativeGraphics.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

// MARK: - Decorative Graphics

struct DecorativeGraphicsModifier: ViewModifier {
    let graphicType: GraphicType
    
    enum GraphicType {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case background
        case accent
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(decorativeGraphic, alignment: alignmentForType)
    }
    
    @ViewBuilder
    private var decorativeGraphic: some View {
        switch graphicType {
        case .topLeft:
            topLeftGraphic
        case .topRight:
            topRightGraphic
        case .bottomLeft:
            bottomLeftGraphic
        case .bottomRight:
            bottomRightGraphic
        case .background:
            backgroundGraphic
        case .accent:
            accentGraphic
        }
    }
    
    private var alignmentForType: Alignment {
        switch graphicType {
        case .topLeft:
            return .topLeading
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomRight:
            return .bottomTrailing
        case .background:
            return .center
        case .accent:
            return .topTrailing
        }
    }
    
    // MARK: - Graphic Components
    
    @ViewBuilder
    private var topLeftGraphic: some View {
        Canvas { context, size in
            let cgContext = context.cgContext
            
            // Draw flowing curve
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addCurve(
                to: CGPoint(x: size.width * 0.3, y: size.height * 0.3),
                control1: CGPoint(x: size.width * 0.1, y: size.height * 0.2),
                control2: CGPoint(x: size.width * 0.2, y: size.height * 0.1)
            )
            path.addCurve(
                to: CGPoint(x: size.width * 0.2, y: size.height * 0.6),
                control1: CGPoint(x: size.width * 0.3, y: size.height * 0.4),
                control2: CGPoint(x: size.width * 0.25, y: size.height * 0.5)
            )
            
            cgContext.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.3).cgColor)
            cgContext.setLineWidth(2)
            cgContext.addPath(path)
            cgContext.strokePath()
        }
        .frame(width: 80, height: 80)
        .opacity(0.6)
        .drawingGroup(opaque: false)
    }
    
    @ViewBuilder
    private var topRightGraphic: some View {
        Canvas { context, size in
            let cgContext = context.cgContext
            
            // Draw circular pattern
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius: CGFloat = min(size.width, size.height) / 3
            
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4
                let startPoint = CGPoint(
                    x: center.x + cos(angle) * radius * 0.5,
                    y: center.y + sin(angle) * radius * 0.5
                )
                let endPoint = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                
                cgContext.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.2).cgColor)
                cgContext.setLineWidth(1.5)
                cgContext.move(to: startPoint)
                cgContext.addLine(to: endPoint)
                cgContext.strokePath()
            }
        }
        .frame(width: 60, height: 60)
        .opacity(0.5)
        .drawingGroup(opaque: false)
    }
    
    @ViewBuilder
    private var bottomLeftGraphic: some View {
        Canvas { context, size in
            let cgContext = context.cgContext
            
            // Draw triangular pattern
            let path = CGMutablePath()
            path.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.9))
            path.addLine(to: CGPoint(x: size.width * 0.3, y: size.height * 0.7))
            path.addLine(to: CGPoint(x: size.width * 0.2, y: size.height * 0.9))
            path.closeSubpath()
            
            cgContext.setFillColor(UIColor.systemGreen.withAlphaComponent(0.15).cgColor)
            cgContext.addPath(path)
            cgContext.fillPath()
            
            // Second triangle
            let path2 = CGMutablePath()
            path2.move(to: CGPoint(x: size.width * 0.2, y: size.height * 0.8))
            path2.addLine(to: CGPoint(x: size.width * 0.4, y: size.height * 0.6))
            path2.addLine(to: CGPoint(x: size.width * 0.3, y: size.height * 0.8))
            path2.closeSubpath()
            
            cgContext.setFillColor(UIColor.systemGreen.withAlphaComponent(0.25).cgColor)
            cgContext.addPath(path2)
            cgContext.fillPath()
        }
        .frame(width: 70, height: 70)
        .opacity(0.6)
    }
    
    @ViewBuilder
    private var bottomRightGraphic: some View {
        Canvas { context, size in
            let cgContext = context.cgContext
            
            // Draw wave pattern
            let path = CGMutablePath()
            path.move(to: CGPoint(x: size.width, y: size.height))
            
            for i in 0..<4 {
                let x = size.width - CGFloat(i) * 15
                let y = size.height - sin(Double(i)) * 10
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            cgContext.setStrokeColor(UIColor.systemOrange.withAlphaComponent(0.2).cgColor)
            cgContext.setLineWidth(2)
            cgContext.addPath(path)
            cgContext.strokePath()
        }
        .frame(width: 80, height: 80)
        .opacity(0.5)
    }
    
    @ViewBuilder
    private var backgroundGraphic: some View {
        Canvas { context, size in
            let cgContext = context.cgContext
            
            // Draw subtle circles
            for i in 0..<5 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let radius = CGFloat.random(in: 10...30)
                
                let path = CGMutablePath()
                path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                
                cgContext.setFillColor(UIColor.systemBlue.withAlphaComponent(0.05).cgColor)
                cgContext.addPath(path)
                cgContext.fillPath()
            }
        }
        .opacity(0.3)
    }
    
    @ViewBuilder
    private var accentGraphic: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 8, height: 8)
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 6, height: 6)
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 4, height: 4)
        }
        .padding(8)
    }
}

// MARK: - View Extensions

extension View {
    func decorativeGraphic(_ type: DecorativeGraphicsModifier.GraphicType) -> some View {
        self.modifier(DecorativeGraphicsModifier(graphicType: type))
    }
    
    func sectionWithDecorations() -> some View {
        self
            .decorativeGraphic(.topLeft)
            .decorativeGraphic(.bottomRight)
    }
    
    func headerWithDecorations() -> some View {
        self
            .decorativeGraphic(.topRight)
            .decorativeGraphic(.accent)
    }
}