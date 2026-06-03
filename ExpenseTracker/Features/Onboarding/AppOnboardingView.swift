//
//  AppOnboardingView.swift
//  Fintrax
//
//  Fintrax documentation: Builds first-run onboarding and launch splash experiences.
//

import SwiftUI

struct AppLaunchSplashView: View {
    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 26) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.13))
                        .frame(width: 188, height: 188)
                        .scaleEffect(pulse ? 1.08 : 0.92)

                    Circle()
                        .stroke(AppDesignSystem.Colors.info.opacity(0.20), lineWidth: 18)
                        .frame(width: 218, height: 218)
                        .scaleEffect(pulse ? 0.98 : 1.04)

                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 124, height: 124)
                        .overlay {
                            RoundedRectangle(cornerRadius: 36, style: .continuous)
                                .stroke(Color.white.opacity(0.42), lineWidth: 1)
                        }
                        .shadow(color: Color.black.opacity(0.13), radius: 24, x: 0, y: 14)

                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 58, weight: .bold))
                        .foregroundStyle(AppDesignSystem.Gradients.primary)
                        .symbolEffect(.pulse, value: pulse)
                }
                .scaleEffect(appeared ? 1 : 0.86)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Fintrax")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("Preparing your financial workspace")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AppDesignSystem.Colors.primary.opacity(index == 1 ? 0.9 : 0.28))
                            .frame(width: index == 1 ? 10 : 8, height: index == 1 ? 10 : 8)
                            .scaleEffect(pulse && index == 1 ? 1.2 : 1)
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct AppOnboardingView: View {
    let onComplete: () -> Void

    @State private var selectedPage = 0
    @State private var splashVisible = true
    @State private var heroExpanded = false

    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            OnboardingBackground()

            if splashVisible {
                splashView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                onboardingPages
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.78)) {
                heroExpanded = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    splashVisible = false
                }
            }
        }
    }

    private var splashView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primary.opacity(0.12))
                    .frame(width: 176, height: 176)
                    .scaleEffect(heroExpanded ? 1.08 : 0.72)

                Circle()
                    .stroke(AppDesignSystem.Colors.info.opacity(0.22), lineWidth: 18)
                    .frame(width: 204, height: 204)
                    .rotationEffect(.degrees(heroExpanded ? 18 : -18))

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 116, height: 116)
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(Color.white.opacity(0.42), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 14)

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(AppDesignSystem.Gradients.primary)
                    .symbolEffect(.pulse, value: heroExpanded)
            }

            VStack(spacing: 8) {
                Text("Fintrax")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text("A calmer way to understand your money")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(heroExpanded ? 1 : 0)
            .offset(y: heroExpanded ? 0 : 16)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == 1 ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.primary.opacity(0.24))
                        .frame(width: index == 1 ? 22 : 8, height: 8)
                }
            }
            .padding(.bottom, 34)
        }
        .padding(.horizontal, 28)
    }

    private var onboardingPages: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)

            VStack(spacing: 18) {
                pageIndicator

                Button {
                    if selectedPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            selectedPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(selectedPage == pages.count - 1 ? "Start Securely" : "Continue")
                            .font(.headline.weight(.semibold))

                        Image(systemName: selectedPage == pages.count - 1 ? "lock.shield.fill" : "arrow.right")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppDesignSystem.Gradients.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: AppDesignSystem.Colors.primary.opacity(0.28), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
                .frame(height: 56)

                Button {
                    onComplete()
                } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .frame(height: 34)
                }
                .buttonStyle(.plain)
                .opacity(selectedPage == pages.count - 1 ? 0 : 1)
                .disabled(selectedPage == pages.count - 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(height: 152)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selectedPage ? AppDesignSystem.Colors.primary : Color.white.opacity(0.58))
                    .frame(width: index == selectedPage ? 28 : 8, height: 8)
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedPage)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            let isCompactHeight = proxy.size.height < 690
            let visualSize = min(proxy.size.width * 0.58, isCompactHeight ? 180 : 236)

            VStack(spacing: isCompactHeight ? 16 : 24) {
                Spacer(minLength: isCompactHeight ? 10 : 22)

                visual(size: visualSize)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: isCompactHeight ? 8 : 12) {
                    Text(page.title)
                        .font(.system(size: isCompactHeight ? 27 : 31, weight: .bold, design: .rounded))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(page.subtitle)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .lineLimit(3)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: min(proxy.size.width - 44, 380))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                VStack(spacing: isCompactHeight ? 9 : 12) {
                    ForEach(page.highlights, id: \.title) { highlight in
                        OnboardingHighlightRow(highlight: highlight, tint: page.tint)
                    }
                }
                .frame(maxWidth: min(proxy.size.width - 36, 390))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

                Spacer(minLength: isCompactHeight ? 8 : 16)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.84)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }

    private func visual(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(page.tint.opacity(0.14))
                .frame(width: size * 0.9, height: size * 0.9)

            Circle()
                .stroke(page.tint.opacity(0.16), lineWidth: 20)
                .frame(width: size, height: size)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: size * 0.70, height: size * 0.70)
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.42), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.11), radius: 22, x: 0, y: 12)

            Image(systemName: page.heroIcon)
                .font(.system(size: size * 0.27, weight: .bold))
                .foregroundStyle(page.gradient)
        }
        .frame(width: size, height: size)
    }
}

private struct OnboardingHighlightRow: View {
    let highlight: OnboardingHighlight
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: highlight.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(highlight.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 62)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        }
        .clipped()
    }
}

private struct OnboardingBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                for x in stride(from: CGFloat.zero, through: size.width + size.height, by: 22) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x - size.height * 0.35, y: size.height))
                }
                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)
            }

            GeometryReader { proxy in
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 130, weight: .bold))
                    .foregroundStyle(AppDesignSystem.Colors.primary.opacity(0.08))
                    .rotationEffect(.degrees(drift ? 12 : -4))
                    .offset(x: proxy.size.width * 0.68, y: proxy.size.height * 0.08)

                Image(systemName: "creditcard.fill")
                    .font(.system(size: 120, weight: .semibold))
                    .foregroundStyle(AppDesignSystem.Colors.warning.opacity(0.10))
                    .rotationEffect(.degrees(drift ? -8 : 7))
                    .offset(x: proxy.size.width * 0.58, y: proxy.size.height * 0.72)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 110, weight: .semibold))
                    .foregroundStyle(AppDesignSystem.Colors.success.opacity(0.11))
                    .rotationEffect(.degrees(drift ? 8 : -9))
                    .offset(x: -24, y: proxy.size.height * 0.58)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let heroIcon: String
    let tint: Color
    let gradient: LinearGradient
    let highlights: [OnboardingHighlight]

    static let all = [
        OnboardingPage(
            title: "Track every spend with clarity",
            subtitle: "Capture expenses quickly, organize them by rich categories, and keep your records easy to scan.",
            heroIcon: "list.bullet.rectangle.portrait.fill",
            tint: AppDesignSystem.Colors.primary,
            gradient: AppDesignSystem.Gradients.primary,
            highlights: [
                OnboardingHighlight(icon: "plus.circle.fill", title: "Fast entry", subtitle: "Add expenses in a focused flow"),
                OnboardingHighlight(icon: "tag.fill", title: "Smart categories", subtitle: "Icons and colors stay synced")
            ]
        ),
        OnboardingPage(
            title: "AI analyze your spending behavior",
            subtitle: "Fintrax studies your patterns to reveal daily spend, saving days, top categories, and smarter ways to save.",
            heroIcon: "brain.head.profile",
            tint: AppDesignSystem.Colors.info,
            gradient: LinearGradient(colors: [AppDesignSystem.Colors.info, AppDesignSystem.Colors.primary], startPoint: .topLeading, endPoint: .bottomTrailing),
            highlights: [
                OnboardingHighlight(icon: "sparkles", title: "AI Analyze", subtitle: "Find behavior patterns fast"),
                OnboardingHighlight(icon: "leaf.fill", title: "Saving guidance", subtitle: "See better ways to save")
            ]
        ),
        OnboardingPage(
            title: "Share verified PDF reports",
            subtitle: "Create selected financial reports with charts, Fintrax watermark, and a verified stamp before sharing.",
            heroIcon: "doc.richtext.fill",
            tint: AppDesignSystem.Colors.success,
            gradient: AppDesignSystem.Gradients.success,
            highlights: [
                OnboardingHighlight(icon: "line.3.horizontal.decrease.circle.fill", title: "Selectable data", subtitle: "Share all or one category"),
                OnboardingHighlight(icon: "checkmark.seal.fill", title: "Verified PDF", subtitle: "Stamped by Fintrax")
            ]
        )
    ]
}

private struct OnboardingHighlight {
    let icon: String
    let title: String
    let subtitle: String
}

#Preview {
    AppOnboardingView {}
}
