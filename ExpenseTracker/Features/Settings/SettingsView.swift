//
//  SettingsView.swift
//  Fintrax
//
//  Fintrax documentation: Builds settings, app preferences, diagnostics, category access, and security controls.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("pinLockEnabled") private var pinLockEnabled = false
    @AppStorage("appPin") private var appPin = ""
    @AppStorage(DeveloperDataMode.mockDataEnabledKey) private var mockDataEnabled = false

    @State private var activeSheet: SettingsSheet?
    @State private var appSize = "Calculating"
    @State private var appeared = false
    @State private var developerTapCount = 0
    @State private var showDeveloperDataDialog = false

    private let appInfo = AppInfo.current
    private let repository = FinanceDataRepository.shared

    private var currentLanguage: AppLanguage {
        settingsManager.settings.language
    }

    private var headerTitle: String {
        L10n.string("settings.header.title", language: currentLanguage)
    }

    private var headerSubtitle: String {
        L10n.string("settings.header.subtitle", language: currentLanguage)
    }

    private var themeBinding: Binding<ThemeOption> {
        Binding(
            get: { settingsManager.settings.theme },
            set: { settingsManager.updateTheme($0) }
        )
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { settingsManager.settings.language },
            set: { settingsManager.updateLanguage($0) }
        )
    }

    var body: some View {
        ZStack {
            FintraxTabBackground(style: .settings)

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppDesignSystem.Spacing.xl) {
                    heroCard
                    financeSection
                    appearanceSection
                    securitySection
                    deviceSection
                    appSection
                }
                .padding(.horizontal, AppDesignSystem.Spacing.lg)
                .padding(.top, AppDesignSystem.Spacing.md)
                .padding(.bottom, AppDesignSystem.Spacing.xxxl)
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .task {
            appSize = await AppInfo.formattedBundleSize()
        }
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) {
                appeared = true
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .changePin:
                ChangePinSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .confirmationDialog(
            "Developer Data Mode",
            isPresented: $showDeveloperDataDialog,
            titleVisibility: .visible
        ) {
            Button(LocalizedStringKey(mockDataEnabled ? "Mock Data Active" : "Use Mock Data")) {
                setDeveloperMockMode(true)
            }
            .disabled(mockDataEnabled)

            Button(LocalizedStringKey(mockDataEnabled ? "Switch to Real Data" : "Real Data Active")) {
                setDeveloperMockMode(false)
            }
            .disabled(!mockDataEnabled)

            Button("Reset Mock Data") {
                repository.resetMockData()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Real data is never deleted. Mock mode is developer-only and replaces app reads with demo data.")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.lg) {
            HStack(alignment: .top, spacing: AppDesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Gradients.primary)
                        .frame(width: 62, height: 62)
                        .shadow(color: AppDesignSystem.Colors.primary.opacity(0.28), radius: 18, x: 0, y: 10)

                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, value: appeared)
                }

                VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.xs) {
                    Text(headerTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text(headerSubtitle)
                        .font(AppDesignSystem.Typography.callout)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: AppDesignSystem.Spacing.md) {
                SettingsPill(
                    icon: pinLockEnabled ? "lock.shield.fill" : "lock.open.fill",
                    title: pinLockEnabled ? "PIN Active" : "PIN Optional",
                    tint: pinLockEnabled ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning
                )
                SettingsPill(icon: themeBinding.wrappedValue.iconName, title: themeBinding.wrappedValue.displayName, tint: AppDesignSystem.Colors.primary)

                if mockDataEnabled {
                    SettingsPill(icon: "testtube.2", title: "Mock Data", tint: AppDesignSystem.Colors.info)
                } else if developerTapCount > 0 {
                    SettingsPill(icon: "hammer.fill", title: L10n.format("settings.developer.accessProgress", developerTapCount), tint: AppDesignSystem.Colors.primaryDark)
                }
            }
        }
        .padding(AppDesignSystem.Spacing.xl)
        .settingsPanel(accent: AppDesignSystem.Colors.primary)
        .contentShape(RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xxl, style: .continuous))
        .onTapGesture {
            handleDeveloperAccessTap()
        }
        .offset(y: appeared ? 0 : 14)
        .opacity(appeared ? 1 : 0)
    }

    private func handleDeveloperAccessTap() {
        if developerTapCount < 5 {
            developerTapCount += 1
        }

        if developerTapCount >= 5 {
            developerTapCount = 0
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showDeveloperDataDialog = true
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func setDeveloperMockMode(_ enabled: Bool) {
        repository.setMockDataEnabled(enabled)
        mockDataEnabled = enabled
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private var appearanceSection: some View {
        SettingsSectionCard(
            title: L10n.Settings.appearanceTitle,
            subtitle: L10n.Settings.appearanceSubtitle,
            icon: "circle.lefthalf.filled",
            tint: AppDesignSystem.Colors.primary
        ) {
            Picker(selection: themeBinding) {
                ForEach(ThemeOption.allCases, id: \.self) { option in
                    Label(LocalizedStringKey(option.displayName), systemImage: option.iconName)
                        .tag(option)
                }
            } label: {
                Text(L10n.Settings.appTheme)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.Settings.appTheme)

            VStack(alignment: .leading, spacing: AppDesignSystem.Spacing.sm) {
                Label(L10n.Settings.appLanguage, systemImage: "globe")
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Picker(selection: languageBinding) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(LocalizedStringKey(language.displayName))
                            .tag(language)
                    }
                } label: {
                    Text(L10n.Settings.appLanguage)
                }
                .pickerStyle(.menu)
                .accessibilityLabel(L10n.Settings.appLanguage)
            }
            .padding(AppDesignSystem.Spacing.md)
            .background(Color(.secondarySystemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
        }
    }

    private var financeSection: some View {
        SettingsSectionCard(
            title: "Finance Tools",
            subtitle: "Track income, bill reminders, and export polished PDF reports.",
            icon: "briefcase.fill",
            tint: AppDesignSystem.Colors.info
        ) {
            NavigationLink {
                CategoryManagementView()
            } label: {
                SettingsNavigationRow(
                    icon: "tag.fill",
                    title: "Categories",
                    subtitle: "Manage category names, icons, and colors",
                    tint: AppDesignSystem.Colors.primary
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                IncomeTrackingView()
            } label: {
                SettingsNavigationRow(
                    icon: "arrow.down.circle.fill",
                    title: "Income Tracking",
                    subtitle: "Add salary, freelance, refunds, and other inflows",
                    tint: AppDesignSystem.Colors.success
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                BillRemindersView()
            } label: {
                SettingsNavigationRow(
                    icon: "bell.badge.fill",
                    title: "Payment Reminders",
                    subtitle: "Schedule bill alerts with sound, badge, and repeat options",
                    tint: AppDesignSystem.Colors.warning
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                PDFReportView()
            } label: {
                SettingsNavigationRow(
                    icon: "doc.richtext.fill",
                    title: "Export Reports",
                    subtitle: "Create share-ready PDF and CSV summaries",
                    tint: AppDesignSystem.Colors.primary
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var securitySection: some View {
        SettingsSectionCard(
            title: "Security",
            subtitle: "Choose whether Fintrax should ask for a 6-digit PIN on launch.",
            icon: "lock.shield.fill",
            tint: AppDesignSystem.Colors.success
        ) {
            SettingsInfoRow(
                icon: pinLockEnabled ? "checkmark.seal.fill" : "lock.open.fill",
                title: "App lock",
                value: pinLockEnabled ? "Required on launch" : "Off",
                tint: pinLockEnabled ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning
            )

            SettingsToggleRow(
                icon: "lock.shield.fill",
                title: "Enable PIN Lock",
                subtitle: pinLockEnabled ? "PIN screen appears when the app opens" : "Open Fintrax directly without PIN",
                tint: AppDesignSystem.Colors.success,
                isOn: Binding(
                    get: { pinLockEnabled },
                    set: { enabled in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if enabled {
                            if appPin.isEmpty {
                                activeSheet = .changePin
                            } else {
                                pinLockEnabled = true
                            }
                        } else {
                            pinLockEnabled = false
                        }
                    }
                )
            )

            SettingsActionRow(
                icon: "key.fill",
                title: appPin.isEmpty ? "Set App PIN" : "Change App PIN",
                subtitle: appPin.isEmpty ? "Create your first 6-digit unlock code" : "Update your 6-digit unlock code",
                tint: AppDesignSystem.Colors.warning
            ) {
                activeSheet = .changePin
            }
        }
    }

    private var deviceSection: some View {
        SettingsSectionCard(
            title: "Device",
            subtitle: "Runtime details for the current installation.",
            icon: "iphone",
            tint: AppDesignSystem.Colors.info
        ) {
            SettingsInfoRow(icon: "apple.logo", title: "iOS Version", value: appInfo.iOSVersion, tint: AppDesignSystem.Colors.info)
            SettingsInfoRow(icon: "iphone.gen3", title: "Device", value: appInfo.deviceModel, tint: AppDesignSystem.Colors.primaryLight)
            SettingsInfoRow(icon: "externaldrive.fill", title: "App Size", value: appSize, tint: AppDesignSystem.Colors.warning)
        }
    }

    private var appSection: some View {
        SettingsSectionCard(
            title: "App Info",
            subtitle: "Version, build, and onboarding controls.",
            icon: "info.circle.fill",
            tint: AppDesignSystem.Colors.primaryDark
        ) {
            SettingsInfoRow(icon: "app.badge.fill", title: "Version", value: appInfo.version, tint: AppDesignSystem.Colors.primary)
            SettingsInfoRow(icon: "hammer.fill", title: "Build", value: appInfo.build, tint: AppDesignSystem.Colors.primaryDark)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                hasCompletedOnboarding = false
            } label: {
                HStack(spacing: AppDesignSystem.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                    Text("Replay Onboarding")
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppDesignSystem.Spacing.lg)
                .padding(.vertical, AppDesignSystem.Spacing.md)
                .background(AppDesignSystem.Gradients.primary, in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
            }
            .buttonStyle(.plain)
            .interactiveButton()
            .accessibilityLabel("Replay onboarding")
        }
    }

}

private enum SettingsSheet: Identifiable {
    case changePin

    var id: String {
        switch self {
        case .changePin: return "changePin"
        }
    }
}

private struct ChangePinSheet: View {
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

private struct PinTextField: View {
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

private struct SettingsSectionCard<Content: View>: View {
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

private struct SettingsInfoRow: View {
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

private struct SettingsActionRow: View {
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

private struct SettingsToggleRow: View {
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

private struct SettingsNavigationRow: View {
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

private struct SettingsPill: View {
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

private struct SettingsBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                Circle()
                    .fill(AppDesignSystem.Colors.primary.opacity(0.12))
                    .frame(width: 210, height: 210)
                    .blur(radius: 28)
                    .offset(x: -76, y: drift ? 18 : -18)

                Circle()
                    .fill(AppDesignSystem.Colors.warning.opacity(0.12))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)
                    .offset(x: size.width - 106, y: size.height * 0.58)

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 82, weight: .semibold))
                    .foregroundStyle(AppDesignSystem.Colors.primary.opacity(0.055))
                    .rotationEffect(.degrees(drift ? -8 : 5))
                    .offset(x: size.width * 0.64, y: 60)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 76, weight: .semibold))
                    .foregroundStyle(AppDesignSystem.Colors.success.opacity(0.06))
                    .rotationEffect(.degrees(drift ? 7 : -6))
                    .offset(x: size.width * 0.08, y: size.height * 0.7)
            }

            SettingsTexture()
                .opacity(0.42)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5.4).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

private struct SettingsTexture: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 18
            for x in stride(from: 0, through: size.width, by: step) {
                for y in stride(from: 0, through: size.height, by: step) {
                    let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.primary.opacity(0.045)))
                }
            }
        }
    }
}

private struct AppInfo {
    let version: String
    let build: String
    let bundleIdentifier: String
    let iOSVersion: String
    let deviceModel: String

    static var current: AppInfo {
        let dictionary = Bundle.main.infoDictionary
        return AppInfo(
            version: dictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            build: dictionary?["CFBundleVersion"] as? String ?? "1",
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "Unknown",
            iOSVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            deviceModel: UIDevice.current.model
        )
    }

    static func formattedBundleSize() async -> String {
        await Task.detached(priority: .utility) {
            let bytes = folderSize(at: Bundle.main.bundleURL)
            return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
        }.value
    }

    private static func folderSize(at url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) else {
                continue
            }
            total += UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }
}

private extension ThemeOption {
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
}

private extension AppLanguage {
    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .marathi: return "मराठी"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        }
    }
}

private extension View {
    func settingsPanel(accent: Color) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xxl, style: .continuous)
                        .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.88))

                    LinearGradient(
                        colors: [accent.opacity(0.09), Color.clear, AppDesignSystem.Colors.surfaceVariant.opacity(0.34)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xxl, style: .continuous))
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xxl, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primary.opacity(0.12), accent.opacity(0.20), Color.primary.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: accent.opacity(0.10), radius: 22, x: 0, y: 14)
            .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SettingsManager())
    }
}
