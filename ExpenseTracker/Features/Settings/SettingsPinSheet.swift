//
//  SettingsPinSheet.swift
//  Fintrax
//

import SwiftUI
import UIKit

enum SettingsSheet: Identifiable {
    case changePin

    var id: String {
        switch self {
        case .changePin: return "changePin"
        }
    }
}

struct ChangePinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appPin") private var appPin = ""
    @AppStorage("pinLockEnabled") private var pinLockEnabled = false

    @State private var currentPin = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var message: String?
    @State private var messageIsError = false
    @State private var saved = false

    private var requiresCurrentPin: Bool {
        !appPin.isEmpty
    }

    private var canSave: Bool {
        (!requiresCurrentPin || currentPin.count == 6) && newPin.count == 6 && confirmPin.count == 6
    }

    var body: some View {
        ZStack {
            FintraxTabBackground(style: .settings)

            VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.xl) {
                HStack(spacing: AppDesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppDesignSystem.Colors.warning.opacity(0.16))
                            .frame(width: 52, height: 52)

                        Image(systemName: saved ? "checkmark.shield.fill" : "key.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(saved ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning)
                    }

                    VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.xs) {
                        Text(LocalizedStringKey(requiresCurrentPin ? "Change App PIN" : "Set App PIN"))
                            .font(AppDesignSystem.Typography.title3)
                            .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                        Text(LocalizedStringKey(requiresCurrentPin ? "Create a new 6-digit code for app unlock." : "Choose a 6-digit PIN to enable app lock."))
                            .font(AppDesignSystem.Typography.footnote)
                            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    }

                    Spacer()
                }

                VStack(spacing: AppDesignSystem.Spacing.md) {
                    if requiresCurrentPin {
                        PinTextField(title: "Current PIN", text: $currentPin)
                    }
                    PinTextField(title: "New PIN", text: $newPin)
                    PinTextField(title: "Confirm PIN", text: $confirmPin)
                }

                if let message {
                    HStack(spacing: AppDesignSystem.Spacing.sm) {
                        Image(systemName: messageIsError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        Text(message)
                    }
                    .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                    .foregroundStyle(messageIsError ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 0)

                Button {
                    savePin()
                } label: {
                    Text(LocalizedStringKey(saved ? (requiresCurrentPin ? "PIN Updated" : "PIN Enabled") : (requiresCurrentPin ? "Save New PIN" : "Enable PIN Lock")))
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppDesignSystem.Spacing.md)
                        .background(
                            canSave ? AppDesignSystem.Gradients.primary : LinearGradient(colors: [Color.gray.opacity(0.55), Color.gray.opacity(0.38)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSave || saved)
                .interactiveButton()
            }
            .padding(AppDesignSystem.Spacing.xl)
        }
    }

    private func savePin() {
        if requiresCurrentPin, currentPin != appPin {
            showMessage("Current PIN is incorrect.", isError: true)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        guard newPin == confirmPin else {
            showMessage("New PIN and confirmation do not match.", isError: true)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        if requiresCurrentPin, newPin == currentPin {
            showMessage("Choose a different PIN for better security.", isError: true)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        appPin = newPin
        pinLockEnabled = true
        saved = true
        showMessage(requiresCurrentPin ? "PIN updated successfully." : "PIN lock enabled successfully.", isError: false)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }

    private func showMessage(_ text: String, isError: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            message = L10n.string(text)
            messageIsError = isError
        }
    }
}

struct PinTextField: View {
    let title: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.sm) {
            Text(LocalizedStringKey(title))
                .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)

            SecureField("6 digits", text: $text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .focused($isFocused)
                .padding(.horizontal, AppDesignSystem.Spacing.lg)
                .padding(.vertical, AppDesignSystem.Spacing.md)
                .background(Color(.secondarySystemBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.lg, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.lg, style: .continuous)
                        .stroke(isFocused ? AppDesignSystem.Colors.primary.opacity(0.7) : Color.white.opacity(0.25), lineWidth: 1)
                }
                .onChange(of: text) { _, newValue in
                    let sanitized = String(newValue.filter(\.isNumber).prefix(6))
                    if sanitized != newValue {
                        text = sanitized
                    }
                }
        }
    }
}
