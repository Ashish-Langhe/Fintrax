//
//  AssistantInsightComponents.swift
//  Fintrax
//

import SwiftUI

struct AssistantLoadingCard: View {
    @State private var pulse = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(AppDesignSystem.Colors.primary.gradient, in: Circle())
                .scaleEffect(pulse ? 1.08 : 0.94)

            VStack(alignment: .leading, spacing: 7) {
                Text(L10n.Assistant.loadingTitle)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(L10n.Assistant.loadingMessage)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(assistantPanel(accent: AppDesignSystem.Colors.primary, isProminent: true))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func assistantPanel(accent: Color, isProminent: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.elevatedSurface.opacity(isProminent ? 0.94 : 0.82),
                        AppDesignSystem.Colors.surfaceVariant.opacity(isProminent ? 0.56 : 0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
    }
}

struct AssistantInsightCard: View {
    let insight: AssistantInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(LocalizedStringKey(insight.title), systemImage: insight.icon)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(insight.tint)
                        .lineLimit(1)

                    Text(insight.value)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 10)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(insight.tint.gradient, in: Circle())
                    .shadow(color: insight.tint.opacity(0.22), radius: 12, x: 0, y: 6)
            }

            Text(insight.message)
                .font(AppDesignSystem.Typography.callout)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !insight.detailRows.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(insight.detailRows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: row.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(insight.tint)
                                .frame(width: 26, height: 26)
                                .background(insight.tint.opacity(0.11), in: Circle())

                            Text(LocalizedStringKey(row.title))
                                .font(AppDesignSystem.Typography.caption2.weight(.bold))
                                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                                .textCase(.uppercase)

                            Text(row.value)
                                .font(AppDesignSystem.Typography.caption.weight(.bold))
                                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                        .padding(11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.28), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.warning)

                Text(insight.action)
                    .font(AppDesignSystem.Typography.caption.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
        }
        .padding(17)
        .background(assistantPanel(accent: insight.tint))
    }

    private func assistantPanel(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.92),
                        AppDesignSystem.Colors.surfaceVariant.opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: accent.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

struct AssistantPromptChip: View {
    let prompt: AssistantPrompt
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: prompt.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : prompt.tint)
                .frame(width: 28, height: 28)
                .background((isSelected ? Color.white.opacity(0.18) : prompt.tint.opacity(0.12)), in: Circle())

            Text(LocalizedStringKey(prompt.title))
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : AppDesignSystem.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(height: 48)
        .background(
            Capsule(style: .continuous)
                .fill(promptBackground)
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.30) : prompt.tint.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: isSelected ? prompt.tint.opacity(0.18) : .clear, radius: 12, x: 0, y: 7)
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

struct VoiceWaveformView: View {
    @State private var phase = false

    private let heights: [CGFloat] = [16, 28, 20, 34, 24]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(heights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(AppDesignSystem.Colors.primary.gradient)
                    .frame(width: 4, height: phase ? height : max(8, height * 0.48))
                    .animation(
                        .easeInOut(duration: 0.52)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.06),
                        value: phase
                    )
            }
        }
        .frame(width: 42, height: 38)
        .onAppear {
            phase = true
        }
    }
}

struct FinnyVoiceResponseCard: View {
    let response: FinnyVoiceResponse
    let isSaving: Bool
    let onConfirm: (FinnyVoiceExpenseDraft) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: response.icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(response.tint.gradient, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(response.title)
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text(response.message)
                        .font(AppDesignSystem.Typography.caption.weight(.medium))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if !response.detailRows.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(response.detailRows) { row in
                        HStack(spacing: 8) {
                            Image(systemName: row.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(response.tint)
                                .frame(width: 24, height: 24)
                                .background(response.tint.opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                                    .textCase(.uppercase)

                                Text(row.value)
                                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.30), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }

            if let draft = response.pendingExpense {
                HStack(spacing: 10) {
                    Button {
                        onConfirm(draft)
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption.weight(.bold))
                            }

                            Text(L10n.string("assistant.voice.saveExpense"))
                                .font(AppDesignSystem.Typography.caption.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(response.tint.gradient, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                            .frame(width: 42, height: 42)
                            .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.42), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .accessibilityLabel(L10n.string("assistant.voice.dismiss"))
                }
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(response.tint.opacity(0.08))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(response.tint.opacity(0.16), lineWidth: 1)
        }
    }
}
