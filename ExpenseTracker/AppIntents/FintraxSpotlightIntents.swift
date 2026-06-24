//
//  FintraxSpotlightIntents.swift
//  Fintrax
//
//  Fintrax documentation: Defines Spotlight-friendly app destinations and deep links.
//

import AppIntents
import Foundation

enum FintraxSpotlightDestination: String, AppEnum, CaseIterable, Identifiable {
    case dashboard
    case expenses
    case analytics
    case budget
    case settings
    case income
    case bills
    case reports
    case categories

    var id: String { rawValue }

    static var typeDisplayName: LocalizedStringResource = "spotlight.destination.typeName"
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "spotlight.destination.typeName"

    static var caseDisplayRepresentations: [FintraxSpotlightDestination: DisplayRepresentation] {
        [
            .dashboard: DisplayRepresentation(title: "spotlight.destination.dashboard", subtitle: "spotlight.destination.dashboard.subtitle"),
            .expenses: DisplayRepresentation(title: "spotlight.destination.expenses", subtitle: "spotlight.destination.expenses.subtitle"),
            .analytics: DisplayRepresentation(title: "spotlight.destination.analytics", subtitle: "spotlight.destination.analytics.subtitle"),
            .budget: DisplayRepresentation(title: "spotlight.destination.budget", subtitle: "spotlight.destination.budget.subtitle"),
            .settings: DisplayRepresentation(title: "spotlight.destination.settings", subtitle: "spotlight.destination.settings.subtitle"),
            .income: DisplayRepresentation(title: "spotlight.destination.income", subtitle: "spotlight.destination.income.subtitle"),
            .bills: DisplayRepresentation(title: "spotlight.destination.bills", subtitle: "spotlight.destination.bills.subtitle"),
            .reports: DisplayRepresentation(title: "spotlight.destination.reports", subtitle: "spotlight.destination.reports.subtitle"),
            .categories: DisplayRepresentation(title: "spotlight.destination.categories", subtitle: "spotlight.destination.categories.subtitle")
        ]
    }

    var appIntentDestination: AppIntentDestination {
        switch self {
        case .dashboard:
            .dashboard
        case .expenses:
            .expenses
        case .analytics:
            .analytics
        case .budget:
            .budget
        case .settings:
            .settings
        case .income:
            .income
        case .bills:
            .bills
        case .reports:
            .reports
        case .categories:
            .categories
        }
    }
}

struct OpenFintraxSpotlightDestinationIntent: AppIntent {
    static let title: LocalizedStringResource = "spotlight.intent.openDestination.title"
    static let description = IntentDescription("spotlight.intent.openDestination.description")
    static let openAppWhenRun = true

    @Parameter(title: "spotlight.parameter.destination")
    var destination: FintraxSpotlightDestination

    static var parameterSummary: some ParameterSummary {
        Summary("spotlight.summary.openDestination \(\.$destination)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppIntentNavigationRouter.shared.open(destination.appIntentDestination)
        return .result(dialog: IntentDialog(stringLiteral: L10n.format(
            "spotlight.dialog.openDestination",
            destination.localizedTitle
        )))
    }
}

extension FintraxSpotlightDestination {
    var titleKey: String {
        switch self {
        case .dashboard:
            "spotlight.destination.dashboard"
        case .expenses:
            "spotlight.destination.expenses"
        case .analytics:
            "spotlight.destination.analytics"
        case .budget:
            "spotlight.destination.budget"
        case .settings:
            "spotlight.destination.settings"
        case .income:
            "spotlight.destination.income"
        case .bills:
            "spotlight.destination.bills"
        case .reports:
            "spotlight.destination.reports"
        case .categories:
            "spotlight.destination.categories"
        }
    }

    var subtitleKey: String {
        "\(titleKey).subtitle"
    }

    var localizedTitle: String {
        L10n.string(titleKey)
    }

    var localizedSubtitle: String {
        L10n.string(subtitleKey)
    }
}
