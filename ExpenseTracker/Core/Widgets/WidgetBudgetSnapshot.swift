//
//  WidgetBudgetSnapshot.swift
//  Fintrax
//
//  Fintrax documentation: Defines the compact shared budget snapshot used by widgets.
//

import Foundation

enum WidgetBudgetState: String, Codable, Sendable {
    case noBudget
    case healthy
    case attention
    case overBudget
}

struct WidgetBudgetSnapshot: Codable, Sendable {
    let budgetAmount: Decimal?
    let spentAmount: Decimal
    let remainingAmount: Decimal?
    let usagePercentage: Double
    let daysRemaining: Int
    let isSyncedWithIncome: Bool
    let updatedAt: Date

    var state: WidgetBudgetState {
        guard budgetAmount != nil else { return .noBudget }
        if usagePercentage >= 1.0 { return .overBudget }
        if usagePercentage >= 0.8 { return .attention }
        return .healthy
    }

    static let placeholder = WidgetBudgetSnapshot(
        budgetAmount: 50_000,
        spentAmount: 28_400,
        remainingAmount: 21_600,
        usagePercentage: 0.57,
        daysRemaining: 12,
        isSyncedWithIncome: true,
        updatedAt: Date()
    )

    static let empty = WidgetBudgetSnapshot(
        budgetAmount: nil,
        spentAmount: .zero,
        remainingAmount: nil,
        usagePercentage: 0,
        daysRemaining: 0,
        isSyncedWithIncome: false,
        updatedAt: Date()
    )
}

struct WidgetBudgetSnapshotStore {
    static let budgetWidgetKind = "FintraxBudgetWidget"
    static let appGroupIdentifier = "group.com.globant.ExpenseTracker"
    private static let snapshotKey = "fintrax.widget.budgetSnapshot"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupIdentifier) ?? .standard
    }

    func loadSnapshot() -> WidgetBudgetSnapshot {
        guard let data = defaults.data(forKey: Self.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetBudgetSnapshot.self, from: data) else {
            return .empty
        }

        return snapshot
    }

    func saveSnapshot(_ snapshot: WidgetBudgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }
}
