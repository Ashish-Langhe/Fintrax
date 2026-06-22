//
//  FintraxAssistantBot.swift
//  Fintrax
//

import SwiftUI

struct FintraxAssistantBot: View {
    let size: CGFloat
    let isBlinking: Bool
    let isThinking: Bool
    @State private var breath = false
    @State private var hover = false
    @State private var sparkle = false
    @State private var eyeGlint = false

    var body: some View {
        ZStack {
            assistantAura

            RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.elevatedSurface.opacity(0.82),
                            AppDesignSystem.Colors.primary.opacity(0.18),
                            AppDesignSystem.Colors.info.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 1.02, height: size * 1.02)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.48),
                                    AppDesignSystem.Colors.info.opacity(0.26),
                                    AppDesignSystem.Colors.primary.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: AppDesignSystem.Colors.primary.opacity(0.18), radius: size * 0.22, x: 0, y: size * 0.12)
                .scaleEffect(breath ? 1.015 : 0.985)
                .offset(y: size * 0.05)

            Ellipse()
                .fill(Color.black.opacity(0.24))
                .frame(width: size * 0.86, height: size * 0.19)
                .blur(radius: size * 0.045)
                .offset(y: size * 0.53)
                .scaleEffect(x: hover ? 0.92 : 1.08, y: hover ? 0.82 : 1.0)

            Image("FintraxAssistantMascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size * 1.05)
                .scaleEffect(breath ? 1.018 : 0.992)
                .rotationEffect(.degrees(hover ? -2.6 : 2.2))
                .offset(y: hover ? -size * 0.055 : size * 0.025)
                .shadow(color: AppDesignSystem.Colors.info.opacity(0.34), radius: size * 0.18, x: 0, y: size * 0.07)
                .shadow(color: AppDesignSystem.Colors.primary.opacity(0.28), radius: size * 0.24, x: 0, y: size * 0.13)

            animatedEyes
                .rotationEffect(.degrees(hover ? -2.6 : 2.2))
                .offset(y: hover ? -size * 0.055 : size * 0.025)

            if isThinking || sparkle {
                sparkleField
            }
        }
        .frame(width: size * 1.22, height: size * 1.28)
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

    private var assistantAura: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.40, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            AppDesignSystem.Colors.info.opacity(isThinking ? 0.34 : 0.26),
                            AppDesignSystem.Colors.primary.opacity(isThinking ? 0.24 : 0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.12,
                        endRadius: size * 0.78
                    )
                )
                .frame(width: size * 1.48, height: size * 1.32)
                .scaleEffect(breath ? 1.06 : 0.94)
                .blur(radius: size * 0.035)

            RoundedRectangle(cornerRadius: size * 0.38, style: .continuous)
                .fill(AppDesignSystem.Colors.info.opacity(0.10))
                .frame(width: size * 1.24, height: size * 1.14)
                .scaleEffect(breath ? 1.04 : 0.98)
                .blur(radius: size * 0.08)
        }
        .offset(y: size * 0.02)
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
