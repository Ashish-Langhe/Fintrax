//
//  PinEntryView.swift
//  Fintrax
//
//  Fintrax documentation: Builds PIN entry and app lock presentation.
//

import SwiftUI
import UIKit

struct PinEntryView: View {
    private let pinLength = 6

    let onAuthenticated: () -> Void

    @AppStorage("appPin") private var appPin = ""
    @AppStorage("biometricUnlockEnabled") private var biometricUnlockEnabled = false
    @State private var enteredPin = ""
    @State private var showError = false
    @State private var biometricPromptAttempted = false
    @State private var shakeOffset: CGFloat = 0
    @State private var headerAppeared = false
    @State private var shieldPulse = false

    private let biometricService = BiometricAuthService()

    private let keypadRows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "delete.left"]
    ]

    var body: some View {
        ZStack {
            PinSecurityBackground()

            VStack(spacing: AppDesignSystem.Spacing.xxxl) {
                Spacer(minLength: AppDesignSystem.Spacing.xl)

                header

                VStack(spacing: AppDesignSystem.Spacing.xxl) {
                    pinDots
                    errorMessage
                    biometricUnlockButton
                    keypad
                }
                .padding(.horizontal, AppDesignSystem.Spacing.xxl)
                .padding(.vertical, AppDesignSystem.Spacing.xxxl)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xxl, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xxl, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 16)
                .offset(x: shakeOffset)
                .scaleEffect(headerAppeared ? 1 : 0.96)
                .opacity(headerAppeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1), value: headerAppeared)

                Spacer(minLength: AppDesignSystem.Spacing.xl)
            }
            .padding(.horizontal, AppDesignSystem.Spacing.xl)
            .padding(.vertical, AppDesignSystem.Spacing.xxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                headerAppeared = true
            }

            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                shieldPulse = true
            }

            authenticateWithBiometricsIfAvailable(automatic: true)
        }
    }

    private var header: some View {
        VStack(spacing: AppDesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primary.opacity(0.14))
                    .frame(width: 116, height: 116)
                    .scaleEffect(shieldPulse ? 1.08 : 0.94)

                Circle()
                    .stroke(AppDesignSystem.Colors.primary.opacity(0.2), lineWidth: 2)
                    .frame(width: 138, height: 138)
                    .scaleEffect(shieldPulse ? 1.02 : 0.9)
                    .opacity(shieldPulse ? 0.35 : 0.8)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(AppDesignSystem.Gradients.primary)
                    .symbolEffect(.pulse, value: shieldPulse)
            }
            .accessibilityHidden(true)

            VStack(spacing: AppDesignSystem.Spacing.sm) {
                Text(L10n.PinLock.welcomeBack)
                    .font(AppDesignSystem.Typography.title1)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(L10n.PinLock.enterPin)
                    .font(AppDesignSystem.Typography.callout)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }
            .multilineTextAlignment(.center)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 12)
            .animation(.easeOut(duration: 0.35).delay(0.15), value: headerAppeared)
        }
    }

    private var pinDots: some View {
        HStack(spacing: AppDesignSystem.Spacing.md) {
            ForEach(0..<pinLength, id: \.self) { index in
                RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.round, style: .continuous)
                    .fill(index < enteredPin.count ? AppDesignSystem.Colors.primary : Color.white.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.round, style: .continuous)
                            .stroke(index < enteredPin.count ? AppDesignSystem.Colors.primary.opacity(0.25) : AppDesignSystem.Colors.outline, lineWidth: 1)
                    }
                    .frame(width: index < enteredPin.count ? 34 : 18, height: 14)
                    .animation(.spring(response: 0.25, dampingFraction: 0.72), value: enteredPin.count)
            }
        }
        .frame(height: 28)
        .accessibilityLabel(L10n.PinLock.pinEntryAccessibility)
        .accessibilityValue(L10n.format(L10n.PinLock.digitsEntered, enteredPin.count, pinLength))
    }

    @ViewBuilder
    private var errorMessage: some View {
        Text(showError ? L10n.PinLock.incorrectPin : " ")
            .font(AppDesignSystem.Typography.footnote.weight(.semibold))
            .foregroundStyle(AppDesignSystem.Colors.error)
            .frame(height: 18)
            .animation(.easeInOut(duration: 0.18), value: showError)
    }

    private var keypad: some View {
        VStack(spacing: AppDesignSystem.Spacing.md) {
            ForEach(keypadRows, id: \.self) { row in
                HStack(spacing: AppDesignSystem.Spacing.md) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(for: key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var biometricUnlockButton: some View {
        let availability = biometricService.availability()
        if biometricUnlockEnabled, availability.isAvailable {
            Button {
                authenticateWithBiometricsIfAvailable(automatic: false)
            } label: {
                Label(LocalizedStringKey("biometric.unlock.button"), systemImage: availability.kind.iconName)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, AppDesignSystem.Spacing.lg)
                    .padding(.vertical, AppDesignSystem.Spacing.sm)
                    .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .interactiveButton(scaleEffect: 0.96)
            .accessibilityHint(LocalizedStringKey("biometric.unlock.hint"))
        }
    }

    @ViewBuilder
    private func keypadButton(for key: String) -> some View {
        if key.isEmpty {
            Color.clear
                .frame(width: 72, height: 60)
        } else {
            Button {
                handleKey(key)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        }

                    if key == "delete.left" {
                        Image(systemName: key)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    } else {
                        Text(key)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    }
                }
                .frame(width: 72, height: 60)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(key == "delete.left" ? L10n.PinLock.deleteDigit : LocalizedStringKey(L10n.format(L10n.PinLock.digit, key)))
            .interactiveButton(scaleEffect: 0.92)
        }
    }

    private func handleKey(_ key: String) {
        showError = false

        if key == "delete.left" {
            guard !enteredPin.isEmpty else { return }
            enteredPin.removeLast()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        guard enteredPin.count < pinLength else { return }

        enteredPin.append(key)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if enteredPin.count == pinLength {
            validatePin()
        }
    }

    private func validatePin() {
        if enteredPin == appPin {
            completeAuthentication()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            showError = true
            animateIncorrectPin()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                enteredPin = ""
            }
        }
    }

    private func authenticateWithBiometricsIfAvailable(automatic: Bool) {
        guard biometricUnlockEnabled else { return }
        let availability = biometricService.availability()
        guard availability.isAvailable else { return }
        if automatic {
            guard !biometricPromptAttempted else { return }
            biometricPromptAttempted = true
        }

        Task {
            let success = await biometricService.authenticate(reason: L10n.string("biometric.unlock.reason"))
            guard success else { return }
            await MainActor.run {
                completeAuthentication()
            }
        }
    }

    private func completeAuthentication() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            headerAppeared = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            onAuthenticated()
            enteredPin = ""
        }
    }

    private func animateIncorrectPin() {
        withAnimation(.easeInOut(duration: 0.06).repeatCount(5, autoreverses: true)) {
            shakeOffset = 12
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.08)) {
                shakeOffset = 0
            }
        }
    }
}

private struct PinSecurityBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                Image(systemName: "creditcard.fill")
                    .font(.system(size: 76, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.primary.opacity(0.08))
                    .rotationEffect(.degrees(drift ? -10 : 8))
                    .offset(x: size.width * 0.62, y: drift ? 72 : 46)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 68, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.success.opacity(0.12))
                    .rotationEffect(.degrees(drift ? 9 : -7))
                    .offset(x: size.width * 0.08, y: size.height * 0.62)

                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 92, weight: .regular))
                    .foregroundStyle(AppDesignSystem.Colors.warning.opacity(0.12))
                    .rotationEffect(.degrees(drift ? 6 : -4))
                    .offset(x: size.width * 0.68, y: size.height * 0.74)

                Circle()
                    .stroke(AppDesignSystem.Colors.info.opacity(0.14), lineWidth: 18)
                    .frame(width: 210, height: 210)
                    .offset(x: drift ? -62 : -84, y: 86)

                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(AppDesignSystem.Colors.primary.opacity(0.08), lineWidth: 14)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(drift ? 18 : 9))
                    .offset(x: size.width - 96, y: size.height * 0.18)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
        }
    }
}

#Preview {
    PinEntryView {}
}
