//
//  SettingsRows.swift
//  Fintrax
//

import SwiftUI

struct SettingsSectionCard<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.lg) {
            HStack(alignment: .top, spacing: AppDesignSystem.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.lg, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.xs) {
                    Text(title)
                        .font(AppDesignSystem.Typography.headline)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text(subtitle)
                        .font(AppDesignSystem.Typography.footnote)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            content
        }
        .padding(AppDesignSystem.Spacing.lg)
        .settingsPanel(accent: tint)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppDesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            Text(LocalizedStringKey(title))
                .font(AppDesignSystem.Typography.callout)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            Spacer(minLength: AppDesignSystem.Spacing.md)

            Text(LocalizedStringKey(value))
                .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppDesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text(LocalizedStringKey(subtitle))
                        .font(AppDesignSystem.Typography.footnote)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textTertiary)
            }
            .padding(AppDesignSystem.Spacing.md)
            .background(Color(.secondarySystemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
        }
        .buttonStyle(.plain)
        .interactiveButton()
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppDesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(LocalizedStringKey(subtitle))
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppDesignSystem.Spacing.md)

            Toggle(LocalizedStringKey(title), isOn: $isOn)
                .labelsHidden()
                .tint(tint)
        }
        .padding(AppDesignSystem.Spacing.md)
        .background(Color(.secondarySystemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppDesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(LocalizedStringKey(subtitle))
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textTertiary)
        }
        .padding(AppDesignSystem.Spacing.md)
        .background(Color(.secondarySystemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
    }
}

struct SettingsPill: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppDesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(LocalizedStringKey(title))
                .font(AppDesignSystem.Typography.caption.weight(.bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, AppDesignSystem.Spacing.md)
        .padding(.vertical, AppDesignSystem.Spacing.sm)
        .background(tint.opacity(0.12), in: Capsule())
    }
}
