//
//  FintraxAssistantLauncher.swift
//  Fintrax
//

import SwiftUI

struct FintraxAssistantLauncher: View {
    let entrance: FintraxAssistantEntrance
    let dockSide: FintraxAssistantDockSide
    let action: () -> Void
    @State private var isBlinking = false
    @State private var shimmer = false
    @State private var hasEntered = false
    @State private var arrivalSpark = false
    @State private var showGreeting = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                action()
            }
        } label: {
            HStack(alignment: .bottom, spacing: 2) {
                if dockSide == .trailing {
                    greetingSlot
                }

                FintraxAssistantBot(size: 90, isBlinking: isBlinking, isThinking: shimmer)
                    .overlay(alignment: .topLeading) {
                        if entrance == .dashboardArrival {
                            arrivalTrail
                        }
                    }

                if dockSide == .leading {
                    greetingSlot
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Assistant.accessibilityLabel)
        .opacity(hasEntered ? 1 : entrance == .dashboardArrival ? 0 : 1)
        .scaleEffect(hasEntered ? 1 : entrance == .dashboardArrival ? 0.58 : 1)
        .rotationEffect(.degrees(hasEntered ? 0 : entrance == .dashboardArrival ? -16 : 0))
        .offset(
            x: hasEntered ? 0 : entrance == .dashboardArrival ? 92 : 0,
            y: hasEntered ? 0 : entrance == .dashboardArrival ? 118 : 0
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                shimmer = true
            }
            startEntrance()
            startBlinking()
        }
    }

    @ViewBuilder
    private var arrivalTrail: some View {
        if arrivalSpark {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.18 + Double(index) * 0.14))
                        .frame(width: CGFloat(7 + index * 3), height: CGFloat(7 + index * 3))
                        .offset(x: CGFloat(-22 - index * 8), y: CGFloat(22 + index * 6))
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.82)))
        }
    }

    private var assistantGreeting: some View {
        Text(L10n.Assistant.greeting)
            .font(AppDesignSystem.Typography.caption.weight(.semibold))
            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 188, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.94))
            )
            .overlay(alignment: dockSide == .trailing ? .trailing : .leading) {
                TrianglePointer()
                    .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.94))
                    .frame(width: 10, height: 14)
                    .scaleEffect(x: dockSide == .trailing ? 1 : -1, y: 1)
                    .offset(x: dockSide == .trailing ? 11 : -11)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppDesignSystem.Colors.primary.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: AppDesignSystem.Colors.primary.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    private var greetingSlot: some View {
        assistantGreeting
            .opacity(showGreeting ? 1 : 0)
            .scaleEffect(showGreeting ? 1 : 0.96, anchor: dockSide == .trailing ? .trailing : .leading)
            .offset(x: showGreeting ? 0 : (dockSide == .trailing ? 8 : -8))
            .accessibilityHidden(!showGreeting)
            .allowsHitTesting(false)
    }

    private func startEntrance() {
        guard !hasEntered else { return }

        if entrance == .dashboardArrival {
            arrivalSpark = true
            withAnimation(.interpolatingSpring(stiffness: 112, damping: 12).delay(0.42)) {
                hasEntered = true
            }
            withAnimation(.easeOut(duration: 0.46).delay(1.08)) {
                arrivalSpark = false
            }
            scheduleGreeting()
        } else {
            hasEntered = true
        }
    }

    private func scheduleGreeting() {
        Task {
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                    showGreeting = true
                }
            }

            try? await Task.sleep(nanoseconds: 4_800_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.32)) {
                    showGreeting = false
                }
            }
        }
    }

    private func startBlinking() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: AssistantBlinkRhythm.nextPause())
                await AssistantBlinkRhythm.performBlink { blink in
                    isBlinking = blink
                }
            }
        }
    }
}

enum FintraxAssistantDockSide {
    case leading
    case trailing
}

private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
