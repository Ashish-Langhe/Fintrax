//
//  FinanceComponents.swift
//  Fintrax
//

import SwiftUI
import UIKit

struct FinanceMetricChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
            Text(LocalizedStringKey(title))
                .font(AppDesignSystem.Typography.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FinanceReminderRepeatPanel: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .frame(width: 44, height: 44)
                .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Toggle("Repeat until complete", isOn: $isOn)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .tint(AppDesignSystem.Colors.primary)

                Text("Fintrax will keep sending daily follow-ups after the due date until this bill is marked complete.")
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.primary.opacity(0.12),
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesignSystem.Colors.primary.opacity(0.16), lineWidth: 1)
        }
    }
}

struct FinanceReminderAlertStylePanel: View {
    @Binding var selection: BillReminder.AlertStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: selection.icon)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(AppDesignSystem.Colors.warning)
                    .frame(width: 44, height: 44)
                    .background(AppDesignSystem.Colors.warning.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Alert Style")
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text("Sound notifications can vibrate based on iPhone settings.")
                        .font(AppDesignSystem.Typography.footnote)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Picker("Alert Style", selection: $selection) {
                ForEach(BillReminder.AlertStyle.allCases) { style in
                    Label(LocalizedStringKey(style.title), systemImage: style.icon)
                        .tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.warning.opacity(0.12),
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesignSystem.Colors.warning.opacity(0.16), lineWidth: 1)
        }
    }
}

struct FinanceScreen<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(tint)
                            .frame(width: 56, height: 56)
                            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(title))
                                .font(.title2.weight(.bold))
                            Text(LocalizedStringKey(subtitle))
                                .font(AppDesignSystem.Typography.footnote)
                                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding()
                    .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    content
                }
                .padding()
            }
        }
        .navigationTitle(LocalizedStringKey(title))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FinanceSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.callout)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                Text(value)
                    .font(.title3.weight(.bold))
                Text(LocalizedStringKey(subtitle))
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct FinanceListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                Text(LocalizedStringKey(subtitle))
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(value)
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
        }
        .padding()
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct FinanceEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
            Text(LocalizedStringKey(title))
                .font(AppDesignSystem.Typography.headline)
            Text(LocalizedStringKey(subtitle))
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.8), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct FinanceEditorShell<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    let saveAction: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppDesignSystem.Gradients.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        content
                    }
                    .padding()
                }
            }
            .navigationTitle(LocalizedStringKey(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveAction)
                }
            }
        }
    }
}

struct FinanceTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            TextField(LocalizedStringKey(placeholder), text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
