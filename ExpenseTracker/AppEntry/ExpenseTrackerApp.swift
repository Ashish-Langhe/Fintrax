//
//  ExpenseTrackerApp.swift
//  Fintrax
//
//  Fintrax documentation: Describes app startup, root navigation, app lifecycle hooks, and dependency wiring.
//

import SwiftUI
import UIKit
import UserNotifications

/// Main app entry point
@main
struct ExpenseTrackerApp: SwiftUI.App {
    @UIApplicationDelegateAdaptor(FintraxAppDelegate.self) private var appDelegate
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .preferredColorScheme(settingsManager.settings.theme.colorScheme)
                .environment(\.locale, settingsManager.settings.language.locale)
        }
    }
}

final class FintraxAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        return [.banner, .list, .sound, .badge]
    }
}

/// Root content view with navigation
struct ContentView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("pinLockEnabled") private var pinLockEnabled = false
    @AppStorage("appPin") private var appPin = ""
    @StateObject private var navigationManager = NavigationManager()
    @State private var isAuthenticated = false
    @State private var showReturningSplash = true

    private var isPinGateRequired: Bool {
        pinLockEnabled && !appPin.isEmpty
    }
    
    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                AppOnboardingView {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        hasCompletedOnboarding = true
                        showReturningSplash = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if showReturningSplash {
                AppLaunchSplashView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if !isPinGateRequired || isAuthenticated {
                mainTabs
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                PinEntryView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                        isAuthenticated = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.25), value: showReturningSplash)
        .task {
            refreshNotificationBadge()
            guard hasCompletedOnboarding else { return }
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            showReturningSplash = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                isAuthenticated = !isPinGateRequired
                showReturningSplash = true
            } else if newPhase == .active, hasCompletedOnboarding {
                refreshNotificationBadge()
                Task {
                    try? await Task.sleep(nanoseconds: 850_000_000)
                    showReturningSplash = false
                }
            }
        }
        .onChange(of: pinLockEnabled) { _, enabled in
            isAuthenticated = !(enabled && !appPin.isEmpty)
        }
        .onChange(of: appPin) { _, pin in
            isAuthenticated = !(pinLockEnabled && !pin.isEmpty)
        }
        .onAppear {
            isAuthenticated = !isPinGateRequired
        }
        .withAppDependencies()
    }

    @MainActor
    private func refreshNotificationBadge() {
        do {
            _ = try FinanceDataRepository.shared.loadBillReminders()
        } catch {
            ErrorLogger.log(error, context: "ContentView.refreshNotificationBadge")
        }
    }

    private var mainTabs: some View {
        TabView(selection: $navigationManager.selectedTab) {
            dashboardTab
            expensesTab
            analyticsTab
            budgetTab
            settingsTab
        }
    }

    private var dashboardTab: some View {
        NavigationStack {
            DashboardView()
                .navigationTitle(L10n.Tab.dashboard)
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(NavigationDestination.dashboard)
        .tabItem {
            Label(L10n.Tab.dashboard, systemImage: tabIcon(for: .dashboard))
                .badge(navigationManager.selectedTab == NavigationDestination.dashboard ? "" : nil)
        }
    }

    private var expensesTab: some View {
        NavigationStack {
            ExpenseListView()
                .navigationTitle(L10n.Tab.expenses)
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(NavigationDestination.expenseList)
        .tabItem {
            Label(L10n.Tab.expenses, systemImage: tabIcon(for: .expenseList))
                .badge(navigationManager.selectedTab == NavigationDestination.expenseList ? "" : nil)
        }
    }

    private var analyticsTab: some View {
        NavigationStack {
            AnalyticsView()
                .navigationTitle(L10n.Tab.analytics)
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(NavigationDestination.analytics)
        .tabItem {
            Label(L10n.Tab.analytics, systemImage: tabIcon(for: .analytics))
                .badge(navigationManager.selectedTab == NavigationDestination.analytics ? "" : nil)
        }
    }

    private var budgetTab: some View {
        NavigationStack {
            BudgetView()
                .navigationTitle(L10n.Tab.budget)
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(NavigationDestination.budgetSettings)
        .tabItem {
            Label(L10n.Tab.budget, systemImage: tabIcon(for: .budgetSettings))
                .badge(navigationManager.selectedTab == NavigationDestination.budgetSettings ? "" : nil)
        }
    }

    private var settingsTab: some View {
        NavigationStack {
            SettingsView()
                .navigationTitle(L10n.Tab.settings)
                .navigationBarTitleDisplayMode(.large)
        }
        .tag(NavigationDestination.settings)
        .tabItem {
            Label(L10n.Tab.settings, systemImage: tabIcon(for: .settings))
        }
    }

    private func tabIcon(for destination: NavigationDestination) -> String {
        let isSelected = navigationManager.selectedTab == destination

        switch destination {
        case .dashboard:
            return isSelected ? "rectangle.grid.2x2.fill" : "rectangle.grid.2x2"
        case .expenseList:
            return isSelected ? "creditcard.fill" : "creditcard"
        case .analytics:
            return "chart.line.uptrend.xyaxis"
        case .budgetSettings:
            return "target"
        case .settings:
            return "slider.horizontal.3"
        default:
            return destination.systemImage
        }
    }
}

// MARK: - Placeholder Views (for future user stories)
struct BudgetSettingsPlaceholder: View {
    var body: some View {
        Text("Budget Settings (User Story 3)")
    }
}

struct SettingsPlaceholder: View {
    var body: some View {
        Text("Settings (User Story 4)")
    }
}

struct SecuritySettingsPlaceholder: View {
    var body: some View {
        Text("Security Settings (User Story 4)")
    }
}

struct ExportDataPlaceholder: View {
    var body: some View {
        Text("Export Data (User Story 4)")
    }
}

// MARK: - App Dependencies Extension
extension View {
    func withAppDependencies() -> some View {
        self
    }
}

struct ExpenseTrackerApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SettingsManager())
    }
}
