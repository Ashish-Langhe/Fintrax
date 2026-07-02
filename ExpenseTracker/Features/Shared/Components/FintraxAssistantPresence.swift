//
//  FintraxAssistantPresence.swift
//  Fintrax
//
//  Fintrax documentation: Provides the animated assistant presence used across insight-heavy screens.
//

import SwiftUI

struct FintraxAssistantPresenceModifier: ViewModifier {
    let entrance: FintraxAssistantEntrance
    @State private var isPresented = false
    @State private var dockCorner: FintraxAssistantDockCorner = .bottomTrailing
    @State private var launcherSize = FintraxAssistantLauncherSizeKey.defaultValue
    @GestureState private var dragTranslation: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    FintraxAssistantLauncher(entrance: entrance, dockSide: dockCorner.dockSide) {
                        isPresented = true
                    }
                    .background {
                        GeometryReader { launcherProxy in
                            Color.clear
                                .preference(key: FintraxAssistantLauncherSizeKey.self, value: launcherProxy.size)
                        }
                    }
                    .position(launcherPosition(in: proxy.size))
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .updating($dragTranslation) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                snapLauncher(after: value, in: proxy.size)
                            }
                    )
                    .animation(.spring(response: 0.34, dampingFraction: 0.82), value: dockCorner)
                    .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.86), value: dragTranslation)
                }
            }
            .onPreferenceChange(FintraxAssistantLauncherSizeKey.self) { size in
                guard size.width > 0, size.height > 0 else { return }
                launcherSize = size
            }
            .sheet(isPresented: $isPresented) {
                FintraxAssistantSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
    }

    private func launcherPosition(in size: CGSize) -> CGPoint {
        let base = dockCorner.point(in: size, launcherSize: launcherSize)
        let bounds = launcherBounds(in: size)
        return CGPoint(
            x: min(max(base.x + dragTranslation.width, bounds.minX), bounds.maxX),
            y: min(max(base.y + dragTranslation.height, bounds.minY), bounds.maxY)
        )
    }

    private func snapLauncher(after value: DragGesture.Value, in size: CGSize) {
        let base = dockCorner.point(in: size, launcherSize: launcherSize)
        let projected = CGPoint(
            x: base.x + value.translation.width + value.predictedEndTranslation.width * 0.18,
            y: base.y + value.translation.height + value.predictedEndTranslation.height * 0.18
        )

        dockCorner = FintraxAssistantDockCorner.nearest(to: projected, in: size, launcherSize: launcherSize)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func launcherBounds(in size: CGSize) -> (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) {
        let margin: CGFloat = 12
        let halfWidth = min(launcherSize.width / 2, max(size.width / 2 - margin, margin))
        let halfHeight = min(launcherSize.height / 2, max(size.height / 2 - margin, margin))

        return (
            minX: halfWidth + margin,
            maxX: max(halfWidth + margin, size.width - halfWidth - margin),
            minY: halfHeight + margin,
            maxY: max(halfHeight + margin, size.height - halfHeight - margin)
        )
    }
}

extension View {
    func fintraxAssistantPresence(entrance: FintraxAssistantEntrance = .subtle) -> some View {
        modifier(FintraxAssistantPresenceModifier(entrance: entrance))
    }
}

enum FintraxAssistantEntrance {
    case dashboardArrival
    case subtle
}

private enum FintraxAssistantDockCorner: CaseIterable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    func point(in size: CGSize, launcherSize: CGSize) -> CGPoint {
        let margin: CGFloat = 12
        let horizontalPadding = min(launcherSize.width / 2 + margin, max(size.width / 2, margin))
        let topPadding = min(launcherSize.height / 2 + margin, max(size.height / 2, margin))
        let bottomPadding = topPadding

        switch self {
        case .topLeading:
            return CGPoint(x: horizontalPadding, y: topPadding)
        case .topTrailing:
            return CGPoint(x: size.width - horizontalPadding, y: topPadding)
        case .bottomLeading:
            return CGPoint(x: horizontalPadding, y: size.height - bottomPadding)
        case .bottomTrailing:
            return CGPoint(x: size.width - horizontalPadding, y: size.height - bottomPadding)
        }
    }

    var dockSide: FintraxAssistantDockSide {
        switch self {
        case .topLeading, .bottomLeading:
            return .leading
        case .topTrailing, .bottomTrailing:
            return .trailing
        }
    }

    static func nearest(to point: CGPoint, in size: CGSize, launcherSize: CGSize) -> FintraxAssistantDockCorner {
        allCases.min { lhs, rhs in
            lhs.point(in: size, launcherSize: launcherSize).distanceSquared(to: point) < rhs.point(in: size, launcherSize: launcherSize).distanceSquared(to: point)
        } ?? .bottomTrailing
    }
}

private struct FintraxAssistantLauncherSizeKey: PreferenceKey {
    static var defaultValue: CGSize = CGSize(width: 310, height: 116)

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension CGPoint {
    func distanceSquared(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return dx * dx + dy * dy
    }
}
