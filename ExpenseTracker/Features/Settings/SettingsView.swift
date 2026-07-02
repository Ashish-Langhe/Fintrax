//
//  SettingsView.swift
//  Fintrax
//
//  Fintrax documentation: Builds settings, app preferences, diagnostics, category access, and security controls.
//

import SwiftUI
import UIKit

private enum SettingsSpotlightSheet: String, Identifiable {
    case categories
    case income
    case bills
    case reports

    var id: String { rawValue }
}

private struct DeveloperBackupShareItem: Identifiable {
    let id = UUID()
    let fileURL: URL
}

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @ObservedObject private var intentRouter = AppIntentNavigationRouter.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("pinLockEnabled") private var pinLockEnabled = false
    @AppStorage("appPin") private var appPin = ""
    @AppStorage("biometricUnlockEnabled") private var biometricUnlockEnabled = false
    @AppStorage(DeveloperDataMode.mockDataEnabledKey) private var mockDataEnabled = false
    @AppStorage(WidgetBudgetSnapshotStore.syncEnabledKey) private var widgetBudgetSyncEnabled = false

    @State private var activeSheet: SettingsSheet?
    @State private var spotlightSheet: SettingsSpotlightSheet?
    @State private var appSize = "Calculating"
    @State private var appeared = false
    @State private var developerTapCount = 0
    @State private var showDeveloperDataDialog = false
    @State private var showDeveloperBackupAlert = false
    @State private var developerBackupMessage = ""
    @State private var developerBackupShareItem: DeveloperBackupShareItem?
    @State private var spotlightDestinations: Set<FintraxSpotlightDestination> = []

    private let appInfo = AppInfo.current
    private let repository = FinanceDataRepository.shared
    private let spotlightIndexingService = SpotlightIndexingService()
    private let biometricService = BiometricAuthService()
    private let developerBackupService = DeveloperDataBackupService()

    private var currentLanguage: AppLanguage {
        settingsManager.settings.language
    }

    private var headerTitle: String {
        L10n.string("settings.header.title", language: currentLanguage)
    }

    private var headerSubtitle: String {
        L10n.string("settings.header.subtitle", language: currentLanguage)
    }

    private var biometricAvailability: BiometricAuthService.Availability {
        biometricService.availability()
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
                    spotlightSection
                    widgetSection
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
            spotlightDestinations = spotlightIndexingService.selectedDestinations()
        }
        .onChange(of: currentLanguage) { _, _ in
            Task {
                await spotlightIndexingService.reindexSelectedDestinations()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) {
                appeared = true
            }
            presentPendingSpotlightDestinationIfNeeded()
        }
        .onChange(of: intentRouter.pendingDestination) { _, _ in
            presentPendingSpotlightDestinationIfNeeded()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .changePin:
                ChangePinSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $spotlightSheet) { sheet in
            NavigationStack {
                spotlightDestinationView(for: sheet)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $developerBackupShareItem) { item in
            ActivityShareSheet(activityItems: [item.fileURL])
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

            Button("settings.developer.backup.take") {
                takeDeveloperBackup()
            }

            Button("settings.developer.backup.fetch") {
                fetchDeveloperBackup()
            }

            Button("settings.developer.backup.export") {
                exportDeveloperBackup()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Real data is never deleted. Mock mode is developer-only and replaces app reads with demo data.")
        }
        .alert(
            "settings.developer.backup.alertTitle",
            isPresented: $showDeveloperBackupAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(developerBackupMessage)
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

    private func takeDeveloperBackup() {
        Task {
            do {
                let summary = try await developerBackupService.createBackup()
                await MainActor.run {
                    developerBackupMessage = L10n.format("settings.developer.backup.success", summary.totalRecords)
                    showDeveloperBackupAlert = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                ErrorLogger.log(error, context: "SettingsView.takeDeveloperBackup")
                await MainActor.run {
                    developerBackupMessage = L10n.string("settings.developer.backup.failed")
                    showDeveloperBackupAlert = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }

    private func fetchDeveloperBackup() {
        Task {
            do {
                let summary = try await developerBackupService.restoreLatestBackup()
                await MainActor.run {
                    developerBackupMessage = L10n.format("settings.developer.backup.restoreSuccess", summary.totalRecords)
                    showDeveloperBackupAlert = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                ErrorLogger.log(error, context: "SettingsView.fetchDeveloperBackup")
                await MainActor.run {
                    developerBackupMessage = L10n.string("settings.developer.backup.restoreFailed")
                    showDeveloperBackupAlert = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }

    private func exportDeveloperBackup() {
        Task {
            do {
                let summary = try await developerBackupService.exportBackup()
                await MainActor.run {
                    developerBackupShareItem = DeveloperBackupShareItem(fileURL: summary.fileURL)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                ErrorLogger.log(error, context: "SettingsView.exportDeveloperBackup")
                await MainActor.run {
                    developerBackupMessage = L10n.string("settings.developer.backup.exportFailed")
                    showDeveloperBackupAlert = true
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }

    private func setSpotlightDestination(_ destination: FintraxSpotlightDestination, enabled: Bool) {
        if enabled {
            spotlightDestinations.insert(destination)
        } else {
            spotlightDestinations.remove(destination)
        }

        Task {
            await spotlightIndexingService.setEnabled(enabled, for: destination)
            await MainActor.run {
                spotlightDestinations = spotlightIndexingService.selectedDestinations()
            }
        }
    }

    private func isSpotlightDestinationEnabled(_ destination: FintraxSpotlightDestination) -> Binding<Bool> {
        Binding(
            get: { spotlightDestinations.contains(destination) },
            set: { setSpotlightDestination(destination, enabled: $0) }
        )
    }

    private func presentPendingSpotlightDestinationIfNeeded() {
        guard let destination = intentRouter.pendingDestination else { return }

        switch destination {
        case .categories:
            spotlightSheet = .categories
        case .income:
            spotlightSheet = .income
        case .bills:
            spotlightSheet = .bills
        case .reports:
            spotlightSheet = .reports
        default:
            return
        }

        _ = intentRouter.consumePendingDestination()
    }

    @ViewBuilder
    private func spotlightDestinationView(for destination: SettingsSpotlightSheet) -> some View {
        switch destination {
        case .categories:
            CategoryManagementView()
        case .income:
            IncomeTrackingView()
        case .bills:
            BillRemindersView()
        case .reports:
            PDFReportView()
        }
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
            .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.xl, style: .continuous))
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

    private var spotlightSection: some View {
        SettingsSectionCard(
            title: "settings.spotlight.title",
            subtitle: "settings.spotlight.subtitle",
            icon: "magnifyingglass.circle.fill",
            tint: AppDesignSystem.Colors.primary
        ) {
            ForEach(FintraxSpotlightDestination.allCases) { destination in
                SettingsToggleRow(
                    icon: spotlightIcon(for: destination),
                    title: destination.titleKey,
                    subtitle: destination.subtitleKey,
                    tint: spotlightTint(for: destination),
                    isOn: isSpotlightDestinationEnabled(destination)
                )
            }
        }
    }

    private var widgetSection: some View {
        SettingsSectionCard(
            title: "settings.widgets.title",
            subtitle: "settings.widgets.subtitle",
            icon: "rectangle.inset.filled.and.person.filled",
            tint: AppDesignSystem.Colors.info
        ) {
            SettingsToggleRow(
                icon: "rectangle.grid.1x2.fill",
                title: "settings.widgets.budgetSync.title",
                subtitle: "settings.widgets.budgetSync.subtitle",
                tint: AppDesignSystem.Colors.info,
                isOn: Binding(
                    get: { widgetBudgetSyncEnabled },
                    set: { enabled in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        widgetBudgetSyncEnabled = enabled
                        if enabled {
                            publishCurrentWidgetSnapshot()
                        } else {
                            WidgetBudgetSnapshotService.shared.clear()
                        }
                    }
                )
            )
        }
    }

    private func spotlightIcon(for destination: FintraxSpotlightDestination) -> String {
        switch destination {
        case .dashboard:
            "rectangle.grid.2x2.fill"
        case .expenses:
            "creditcard.fill"
        case .analytics:
            "chart.line.uptrend.xyaxis"
        case .budget:
            "target"
        case .settings:
            "slider.horizontal.3"
        case .income:
            "arrow.down.circle.fill"
        case .bills:
            "bell.badge.fill"
        case .reports:
            "doc.richtext.fill"
        case .categories:
            "tag.fill"
        }
    }

    private func spotlightTint(for destination: FintraxSpotlightDestination) -> Color {
        switch destination {
        case .dashboard, .settings:
            AppDesignSystem.Colors.primary
        case .expenses, .reports:
            AppDesignSystem.Colors.info
        case .analytics:
            AppDesignSystem.Colors.primaryDark
        case .budget, .bills:
            AppDesignSystem.Colors.warning
        case .income:
            AppDesignSystem.Colors.success
        case .categories:
            AppDesignSystem.Colors.primaryLight
        }
    }

    private func publishCurrentWidgetSnapshot() {
        Task {
            do {
                _ = try await repository.loadDashboardSnapshot()
            } catch {
                ErrorLogger.log(error, context: "SettingsView.publishCurrentWidgetSnapshot")
            }
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
                            biometricUnlockEnabled = false
                        }
                    }
                )
            )

            SettingsInfoRow(
                icon: biometricAvailability.kind.iconName,
                title: "biometric.settings.status",
                value: biometricStatusValue,
                tint: biometricAvailability.isAvailable ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.textTertiary
            )

            SettingsToggleRow(
                icon: biometricAvailability.kind.iconName,
                title: "biometric.settings.toggle",
                subtitle: biometricToggleSubtitle,
                tint: biometricAvailability.isAvailable ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.textTertiary,
                isOn: Binding(
                    get: { biometricUnlockEnabled && pinLockEnabled && biometricAvailability.isAvailable },
                    set: { enabled in
                        setBiometricUnlock(enabled)
                    }
                )
            )
            .disabled(!biometricAvailability.isAvailable)
            .opacity(biometricAvailability.isAvailable ? 1 : 0.68)

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

    private var biometricStatusValue: String {
        guard biometricAvailability.isAvailable else {
            return L10n.string("biometric.settings.unavailable")
        }

        if biometricUnlockEnabled && pinLockEnabled {
            return L10n.string("biometric.settings.enabled")
        }

        return L10n.string(biometricAvailability.kind.titleKey)
    }

    private var biometricToggleSubtitle: String {
        guard biometricAvailability.isAvailable else {
            return L10n.string("biometric.settings.unavailableSubtitle")
        }

        guard !appPin.isEmpty else {
            return L10n.string("biometric.settings.setPinFirst")
        }

        return biometricUnlockEnabled ? L10n.string("biometric.settings.unlocksLaunch") : L10n.string("biometric.settings.enableSubtitle")
    }

    private func setBiometricUnlock(_ enabled: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard enabled else {
            biometricUnlockEnabled = false
            return
        }

        guard biometricAvailability.isAvailable else {
            biometricUnlockEnabled = false
            return
        }

        guard !appPin.isEmpty else {
            activeSheet = .changePin
            return
        }

        Task {
            let success = await biometricService.authenticate(reason: L10n.string("biometric.settings.enableReason"))
            await MainActor.run {
                if success {
                    pinLockEnabled = true
                    biometricUnlockEnabled = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    biometricUnlockEnabled = false
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
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

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SettingsManager())
    }
}
