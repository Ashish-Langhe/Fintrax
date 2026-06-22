//
//  FintraxAssistantSheet.swift
//  Fintrax
//

import SwiftUI

struct FintraxAssistantSheet: View {
    @State private var selectedPrompt: AssistantPrompt?
    @State private var insights: [AssistantInsight] = []
    @State private var loadingState: AssistantLoadingState = .loading
    @State private var isThinking = false
    @State private var isBlinking = false

    private let prompts = AssistantPrompt.samples
    private let repository = FinanceDataRepository.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                promptGrid
                previewResponse
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(FintraxTabBackground(style: .analytics))
        .onAppear {
            startBlinking()
        }
        .task {
            await loadInsights()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(AppDesignSystem.Colors.success)
                        .frame(width: 7, height: 7)

                    Text(L10n.Assistant.liveStatus)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .textCase(.uppercase)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.Assistant.title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)

                    Text(L10n.Assistant.subtitle)
                        .font(AppDesignSystem.Typography.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            FintraxAssistantBot(size: 82, isBlinking: isBlinking, isThinking: isThinking)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primaryDark,
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.info.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 132, height: 132)
                    .offset(x: 128, y: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 82, weight: .bold))
                    .foregroundStyle(.white.opacity(0.05))
                    .offset(x: -118, y: -12)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: AppDesignSystem.Colors.primary.opacity(0.18), radius: 24, x: 0, y: 14)
    }

    private var promptGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Assistant.chooseQuestion)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()

                if case .loaded = loadingState {
                    Text("\(insights.count) ready")
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppDesignSystem.Colors.primary.opacity(0.10), in: Capsule())
                }
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(prompts) { prompt in
                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                                selectedPrompt = prompt
                                isThinking = false
                            }
                        } label: {
                            AssistantPromptChip(prompt: prompt, isSelected: selectedPrompt == prompt)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var previewResponse: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch loadingState {
            case .loading:
                AssistantLoadingCard()
                    .onAppear {
                        isThinking = true
                    }
            case .failed(let message):
                AssistantInsightCard(
                    insight: AssistantInsight(
                        promptID: "error",
                        title: L10n.string("assistant.error.read.title"),
                        value: L10n.string("assistant.error.read.value"),
                        message: message,
                        action: L10n.string("assistant.error.read.action"),
                        icon: "exclamationmark.triangle.fill",
                        tint: AppDesignSystem.Colors.error,
                        detailRows: []
                    )
                )
                .onAppear {
                    isThinking = false
                }
            case .loaded:
                ForEach(visibleInsights) { insight in
                    AssistantInsightCard(insight: insight)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.86), value: selectedPrompt)
    }

    private var visibleInsights: [AssistantInsight] {
        if let selectedPrompt {
            return insights.filter { $0.promptID == selectedPrompt.id }
        }

        return Array(insights.prefix(3))
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
                try? await Task.sleep(nanoseconds: AssistantBlinkRhythm.nextPause())
                await AssistantBlinkRhythm.performBlink { blink in
                    isBlinking = blink
                }
            }
        }
    }

    @MainActor
    private func loadInsights() async {
        loadingState = .loading
        isThinking = true

        do {
            let snapshot = try await repository.loadDashboardSnapshot()
            let generatedInsights = AssistantInsightEngine.makeInsights(from: snapshot)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                insights = generatedInsights
                selectedPrompt = generatedInsights.first.flatMap { insight in
                    prompts.first(where: { $0.id == insight.promptID })
                }
                loadingState = .loaded
                isThinking = false
            }
        } catch {
            loadingState = .failed(error.localizedDescription)
            isThinking = false
        }
    }
}

private enum AssistantLoadingState: Equatable {
    case loading
    case loaded
    case failed(String)
}
