//
//  AppEventBus.swift
//  Fintrax
//
//  Fintrax documentation: Coordinates cross-feature data loading, mutation, and change notifications.
//

import Combine
import Foundation

/// Canonical set of data domains that can invalidate one or more screens.
enum AppDataChange: CaseIterable {
    case budget
    case expense
    case category
    case income
    case billReminder

    var notificationName: Notification.Name {
        switch self {
        case .budget:
            return .budgetDidChange
        case .expense:
            return .expenseDidChange
        case .category:
            return .categoryDidChange
        case .income:
            return .incomeDidChange
        case .billReminder:
            return .billReminderDidChange
        }
    }
}

/// Lightweight in-process event bus for cross-feature refreshes.
///
/// Screens subscribe to domain-specific changes instead of tightly coupling to
/// each other's view models. This keeps Dashboard, Analytics, Expenses, Budget,
/// Settings, and Finance screens synchronized after repository mutations.
@MainActor
final class AppEventBus: Sendable {
    static let shared = AppEventBus()

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    /// Broadcasts that one data domain changed.
    func post(_ change: AppDataChange) {
        notificationCenter.post(name: change.notificationName, object: nil)
    }

    /// Returns a Combine publisher that emits whenever the requested domain changes.
    func publisher(for change: AppDataChange) -> AnyPublisher<Void, Never> {
        notificationCenter
            .publisher(for: change.notificationName)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
