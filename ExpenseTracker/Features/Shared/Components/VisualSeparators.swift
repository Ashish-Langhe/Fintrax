//
//  VisualSeparators.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

// MARK: - Visual Separators

struct VisualSeparator: View {
    let separatorType: SeparatorType
    let height: CGFloat
    let color: Color
    
    enum SeparatorType {
        case solid
        case dashed
        case dotted
        case gradient
        case decorative
        case wavy
    }
    
    init(separatorType: SeparatorType = .solid, height: CGFloat = 1, color: Color = .gray) {
        self.separatorType = separatorType
        self.height = height
        self.color = color
    }
    
    var body: some View {
        switch separatorType {
        case .solid:
            solidSeparator
        case .dashed:
            dashedSeparator
        case .dotted:
            dottedSeparator
        case .gradient:
            gradientSeparator
        case .decorative:
            decorativeSeparator
        case .wavy:
            wavySeparator
        }
    }
    
    @ViewBuilder
    private var solidSeparator: some View {
        Rectangle()
            .fill(color.opacity(0.3))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: height/2))
    }
    
    @ViewBuilder
    private var dashedSeparator: some View {
        HStack(spacing: 8) {
            ForEach(0..<20, id: \.self) { _ in
                Rectangle()
                    .fill(color.opacity(0.4))
                    .frame(width: 12, height: height)
                    .clipShape(Capsule())
            }
        }
    }
    
    @ViewBuilder
    private var dottedSeparator: some View {
        HStack(spacing: 4) {
            ForEach(0..<40, id: \.self) { _ in
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: height, height: height)
            }
        }
    }
    
    @ViewBuilder
    private var gradientSeparator: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0),
                        color.opacity(0.5),
                        color.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
    }
    
    @ViewBuilder
    private var decorativeSeparator: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 4, height: 4)
            
            Rectangle()
                .fill(color.opacity(0.2))
                .frame(height: height)
                .clipShape(Capsule())
            
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 4, height: 4)
        }
    }
    
    @ViewBuilder
    private var wavySeparator: some View {
        Canvas { context, size in
            let cgContext = context.cgContext
            let path = CGMutablePath()
            
            path.move(to: CGPoint(x: 0, y: size.height / 2))
            
            for i in 0..<Int(size.width) {
                let x = CGFloat(i)
                let y = size.height / 2 + sin(Double(i) * 0.1) * size.height / 4
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            cgContext.setStrokeColor(color.opacity(0.4).cgColor)
            cgContext.setLineWidth(height)
            cgContext.setLineCap(.round)
            cgContext.addPath(path)
            cgContext.strokePath()
        }
        .frame(height: height * 3)
    }
}

// MARK: - Section Divider

struct SectionDivider: View {
    let title: String?
    let icon: String?
    let color: Color
    
    init(title: String? = nil, icon: String? = nil, color: Color = .blue) {
        self.title = title
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let title = title, let icon = icon {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color.opacity(0.7))
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color.opacity(0.7))
                }
                .opacity(0.8)
            }
            
            VisualSeparator(separatorType: .decorative, color: color)
        }
        .padding(.horizontal)
    }
}

// MARK: - Progress Separator

struct ProgressSeparator: View {
    let progress: Double // 0.0 to 1.0
    let totalColor: Color
    let progressColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(progressColor.opacity(0.6))
                    .frame(width: geometry.size.width * progress)
                Rectangle()
                    .fill(totalColor.opacity(0.2))
                    .frame(width: geometry.size.width * (1 - progress))
            }
            .clipShape(Capsule())
        }
        .frame(height: 4)
    }
}

// MARK: - View Extensions

extension View {
    func sectionDivider() -> some View {
        self.overlay(VisualSeparator(separatorType: .gradient, color: .blue))
    }
    
    func cardDivider() -> some View {
        self.padding(.vertical, 8)
    }
}