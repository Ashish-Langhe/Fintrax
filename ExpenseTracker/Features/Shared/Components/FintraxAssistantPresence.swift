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

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                FintraxAssistantLauncher(entrance: entrance) {
                    isPresented = true
                }
                .padding(.trailing, 18)
                .padding(.bottom, 82)
            }
            .sheet(isPresented: $isPresented) {
                FintraxAssistantSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
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

private struct FintraxAssistantLauncher: View {
    let entrance: FintraxAssistantEntrance
    let action: () -> Void
    @State private var isBlinking = false
    @State private var shimmer = false
    @State private var hasEntered = false
    @State private var arrivalSpark = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                action()
            }
        } label: {
            FintraxAssistantBot(size: 72, isBlinking: isBlinking, isThinking: shimmer)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(AppDesignSystem.Colors.warning.gradient, in: Circle())
                        .offset(x: 2, y: 4)
                        .scaleEffect(arrivalSpark ? 1.18 : (shimmer ? 1.08 : 0.92))
                }
                .overlay(alignment: .topLeading) {
                    if entrance == .dashboardArrival {
                        arrivalTrail
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Fintrax assistant")
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
        } else {
            hasEntered = true
        }
    }

    private func startBlinking() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_300_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isBlinking = true
                    }
                }
                try? await Task.sleep(nanoseconds: 150_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.14)) {
                        isBlinking = false
                    }
                }
            }
        }
    }
}

private struct FintraxAssistantSheet: View {
    @State private var selectedPrompt: AssistantPrompt?
    @State private var isThinking = false
    @State private var isBlinking = false

    private let prompts = AssistantPrompt.samples

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                promptGrid
                previewResponse
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(FintraxTabBackground(style: .analytics))
        .onAppear {
            startBlinking()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            FintraxAssistantBot(size: 76, isBlinking: isBlinking, isThinking: isThinking)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fintrax Assistant")
                    .font(AppDesignSystem.Typography.title3)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text("Ask quick questions about spending, savings, budgets, and category patterns.")
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(assistantPanel(accent: AppDesignSystem.Colors.primary))
    }

    private var promptGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick asks")
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(prompts) { prompt in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                            selectedPrompt = prompt
                            isThinking = true
                        }
                    } label: {
                        AssistantPromptChip(prompt: prompt, isSelected: selectedPrompt == prompt)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(assistantPanel(accent: AppDesignSystem.Colors.info))
    }

    private var previewResponse: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: selectedPrompt?.icon ?? "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(selectedPrompt?.tint ?? AppDesignSystem.Colors.primary)
                .frame(width: 38, height: 38)
                .background((selectedPrompt?.tint ?? AppDesignSystem.Colors.primary).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(selectedPrompt?.title ?? "Assistant presence is live")
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(selectedPrompt?.preview ?? "The assistant is now available in the app shell. Next, we can connect it to your finance data so these asks return real insights.")
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(assistantPanel(accent: selectedPrompt?.tint ?? AppDesignSystem.Colors.primary))
    }

    private func assistantPanel(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.78))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
    }

    private func startBlinking() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_100_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isBlinking = true
                    }
                }
                try? await Task.sleep(nanoseconds: 140_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.14)) {
                        isBlinking = false
                    }
                }
            }
        }
    }
}

private struct FintraxAssistantBot: View {
    let size: CGFloat
    let isBlinking: Bool
    let isThinking: Bool
    @State private var breath = false
    @State private var hover = false
    @State private var sparkle = false
    @State private var eyeGlint = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppDesignSystem.Colors.primary.opacity(isThinking ? 0.22 : 0.12))
                .frame(width: size * 1.05, height: size * 1.05)
                .scaleEffect(breath ? 1.12 : 0.92)
                .blur(radius: size * 0.04)

            Image("FintraxAssistantMascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size * 1.05)
                .scaleEffect(breath ? 1.018 : 0.992)
                .rotationEffect(.degrees(hover ? -2.6 : 2.2))
                .offset(y: hover ? -size * 0.055 : size * 0.025)
                .shadow(color: AppDesignSystem.Colors.primary.opacity(0.28), radius: size * 0.22, x: 0, y: size * 0.12)

            animatedEyes
                .rotationEffect(.degrees(hover ? -2.6 : 2.2))
                .offset(y: hover ? -size * 0.055 : size * 0.025)

            if isThinking || sparkle {
                sparkleField
            }
        }
        .frame(width: size * 1.15, height: size * 1.22)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.15).repeatForever(autoreverses: true)) {
                breath = true
                hover = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                sparkle = true
            }
            withAnimation(.easeInOut(duration: 1.65).repeatForever(autoreverses: true)) {
                eyeGlint = true
            }
        }
    }

    private var animatedEyes: some View {
        ZStack {
            mascotEye(x: -0.070)
            mascotEye(x: 0.074)
        }
        .frame(width: size, height: size * 1.05)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func mascotEye(x: CGFloat) -> some View {
        ZStack {
            if isBlinking {
                Capsule()
                    .fill(Color(red: 0.02, green: 0.08, blue: 0.20).opacity(0.94))
                    .frame(width: size * 0.105, height: size * 0.022)
                    .overlay {
                        Capsule()
                            .fill(AppDesignSystem.Colors.info.opacity(0.42))
                            .frame(width: size * 0.074, height: size * 0.008)
                    }
            } else {
                Circle()
                    .fill(Color.white.opacity(0.96))
                    .frame(width: size * 0.030, height: size * 0.030)
                    .blur(radius: 0.15)
                    .offset(x: eyeGlint ? size * 0.012 : -size * 0.004, y: eyeGlint ? -size * 0.010 : -size * 0.016)

                Circle()
                    .stroke(AppDesignSystem.Colors.info.opacity(eyeGlint ? 0.58 : 0.30), lineWidth: 1)
                    .frame(width: size * 0.105, height: size * 0.105)
                    .scaleEffect(eyeGlint ? 1.04 : 0.96)
            }
        }
        .offset(x: size * x, y: -size * 0.155)
    }

    private var sparkleField: some View {
        ZStack {
            spark(offsetX: -0.42, offsetY: -0.38, scale: 0.68)
            spark(offsetX: 0.42, offsetY: -0.24, scale: 0.52)
            spark(offsetX: 0.35, offsetY: 0.30, scale: 0.44)
        }
    }

    private func spark(offsetX: CGFloat, offsetY: CGFloat, scale: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.11, weight: .bold))
            .foregroundStyle(AppDesignSystem.Colors.warning.opacity(0.86))
            .scaleEffect(sparkle ? scale * 1.18 : scale * 0.82)
            .opacity(sparkle ? 0.95 : 0.42)
            .offset(x: size * offsetX, y: size * offsetY)
    }
}

private struct AssistantPromptChip: View {
    let prompt: AssistantPrompt
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: prompt.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : prompt.tint)
                .frame(width: 30, height: 30)
                .background((isSelected ? Color.white.opacity(0.18) : prompt.tint.opacity(0.12)), in: Circle())

            Text(prompt.title)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : AppDesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(promptBackground)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.30) : prompt.tint.opacity(0.14), lineWidth: 1)
        }
    }

    private var promptBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(prompt.tint.gradient)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.72),
                    AppDesignSystem.Colors.surfaceVariant.opacity(0.44)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct AssistantPrompt: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let tint: Color
    let preview: String

    static let samples: [AssistantPrompt] = [
        AssistantPrompt(
            id: "highest-day",
            title: "Highest spend day",
            icon: "calendar.badge.exclamationmark",
            tint: AppDesignSystem.Colors.warning,
            preview: "I will scan daily totals and point out the date where spending peaked."
        ),
        AssistantPrompt(
            id: "saving-day",
            title: "Best saving day",
            icon: "leaf.fill",
            tint: AppDesignSystem.Colors.success,
            preview: "I will compare your low-spend days and highlight the strongest saving pattern."
        ),
        AssistantPrompt(
            id: "food-month",
            title: "Food this month",
            icon: "fork.knife",
            tint: AppDesignSystem.Colors.primary,
            preview: "I will total category spending and explain how food is moving this month."
        ),
        AssistantPrompt(
            id: "budget-risk",
            title: "Budget risk",
            icon: "target",
            tint: AppDesignSystem.Colors.info,
            preview: "I will compare spend pace against budget and call out categories needing attention."
        )
    ]
}
