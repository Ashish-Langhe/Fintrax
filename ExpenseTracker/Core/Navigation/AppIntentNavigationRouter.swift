//
//  AppIntentNavigationRouter.swift
//  Fintrax
//
//  Fintrax documentation: Bridges App Intent handoffs into the in-app SwiftUI navigation surface.
//

import Foundation

@MainActor
final class AppIntentNavigationRouter: ObservableObject {
    static let shared = AppIntentNavigationRouter()

    @Published var pendingDestination: AppIntentDestination?

    private init() {}

    func open(_ destination: AppIntentDestination) {
        pendingDestination = destination
    }

    func openAddExpense() {
        pendingDestination = .addExpense
    }

    func consumePendingDestination() -> AppIntentDestination? {
        let destination = pendingDestination
        pendingDestination = nil
        return destination
    }
}

enum AppIntentDestination: Equatable {
    case dashboard
    case expenses
    case analytics
    case budget
    case settings
    case addExpense
    case categories
    case income
    case bills
    case reports
}
