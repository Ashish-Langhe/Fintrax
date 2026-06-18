//
//  L10n.swift
//  Fintrax
//
//  Fintrax documentation: Centralizes localized string keys used by SwiftUI views.
//

import SwiftUI

enum L10n {
    enum Tab {
        static let dashboard: LocalizedStringKey = "tab.dashboard"
        static let expenses: LocalizedStringKey = "tab.expenses"
        static let analytics: LocalizedStringKey = "tab.analytics"
        static let budget: LocalizedStringKey = "tab.budget"
        static let settings: LocalizedStringKey = "tab.settings"
    }

    enum Assistant {
        static let accessibilityLabel: LocalizedStringKey = "assistant.accessibility.label"
        static let greeting: LocalizedStringKey = "assistant.greeting"
        static let liveStatus: LocalizedStringKey = "assistant.header.status"
        static let title: LocalizedStringKey = "assistant.header.title"
        static let subtitle: LocalizedStringKey = "assistant.header.subtitle"
        static let chooseQuestion: LocalizedStringKey = "assistant.question.choose"
        static let loadingTitle: LocalizedStringKey = "assistant.loading.title"
        static let loadingMessage: LocalizedStringKey = "assistant.loading.message"
        static let readErrorTitle: LocalizedStringKey = "assistant.error.read.title"
        static let readErrorValue: LocalizedStringKey = "assistant.error.read.value"
        static let readErrorAction: LocalizedStringKey = "assistant.error.read.action"
    }

    enum Settings {
        static let appearanceTitle: LocalizedStringKey = "settings.appearance.title"
        static let appearanceSubtitle: LocalizedStringKey = "settings.appearance.subtitle"
        static let appTheme: LocalizedStringKey = "settings.appearance.theme"
        static let appLanguage: LocalizedStringKey = "settings.appearance.language"
    }
}
