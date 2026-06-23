//
//  FintraxModalOverlay.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

struct FintraxModalAction {
    let title: String
    let icon: String
    let tint: Color
    let isDestructive: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String,
        tint: Color,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.isDestructive = isDestructive
        self.action = action
    }
}

struct FintraxModalOverlay: View {
    let title: String
    let message: String
    let icon: String
    let tint: Color
    let primaryAction: FintraxModalAction
    let secondaryAction: FintraxModalAction?
    var textFieldPlaceholder: String?
    @Binding var textFieldValue: String

    @FocusState private var isTextFieldFocused: Bool
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()
                .onTapGesture {
                    secondaryAction?.action()
                }

            VStack(spacing: AppDesignSystem.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 72, height: 72)
                        .scaleEffect(appeared ? 1 : 0.82)

                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(tint)
                }

                VStack(spacing: AppDesignSystem.Spacing.sm) {
                    Text(title)
                        .font(AppDesignSystem.Typography.title3)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(AppDesignSystem.Typography.callout)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let textFieldPlaceholder {
                    TextField(textFieldPlaceholder, text: $textFieldValue)
                        .font(AppDesignSystem.Typography.bodyEmphasized)
                        .textInputAutocapitalization(.words)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, AppDesignSystem.Spacing.lg)
                        .padding(.vertical, AppDesignSystem.Spacing.md)
                        .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.75), in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous)
                                .stroke(isTextFieldFocused ? tint.opacity(0.7) : AppDesignSystem.Colors.outline, lineWidth: 1)
                        }
                }

                VStack(spacing: AppDesignSystem.Spacing.md) {
                    Button {
                        primaryAction.action()
                    } label: {
                        modalButtonLabel(primaryAction)
                            .foregroundStyle(.white)
                            .background(
                                primaryAction.isDestructive ? AppDesignSystem.Gradients.error : LinearGradient(colors: [primaryAction.tint, primaryAction.tint.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .interactiveButton()

                    if let secondaryAction {
                        Button {
                            secondaryAction.action()
                        } label: {
                            modalButtonLabel(secondaryAction)
                                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                                .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.72), in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AppDesignSystem.Spacing.xxl)
            .frame(maxWidth: 360)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.96))

                    LinearGradient(
                        colors: [tint.opacity(0.12), Color.clear, AppDesignSystem.Colors.surfaceVariant.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppDesignSystem.Colors.cardStroke, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.22), radius: 28, x: 0, y: 18)
            .padding(.horizontal, AppDesignSystem.Spacing.xl)
            .scaleEffect(appeared ? 1 : 0.94)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    appeared = true
                }
                if textFieldPlaceholder != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        isTextFieldFocused = true
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private func modalButtonLabel(_ action: FintraxModalAction) -> some View {
        HStack(spacing: AppDesignSystem.Spacing.sm) {
            Image(systemName: action.icon)
                .font(.system(size: 14, weight: .bold))
            Text(action.title)
                .font(AppDesignSystem.Typography.calloutEmphasized)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppDesignSystem.Spacing.md)
    }
}

extension View {
    func fintraxModal(
        isPresented: Bool,
        title: String,
        message: String,
        icon: String,
        tint: Color,
        primaryAction: FintraxModalAction,
        secondaryAction: FintraxModalAction? = nil,
        textFieldPlaceholder: String? = nil,
        textFieldValue: Binding<String> = .constant("")
    ) -> some View {
        overlay {
            if isPresented {
                FintraxModalOverlay(
                    title: title,
                    message: message,
                    icon: icon,
                    tint: tint,
                    primaryAction: primaryAction,
                    secondaryAction: secondaryAction,
                    textFieldPlaceholder: textFieldPlaceholder,
                    textFieldValue: textFieldValue
                )
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isPresented)
    }
}
