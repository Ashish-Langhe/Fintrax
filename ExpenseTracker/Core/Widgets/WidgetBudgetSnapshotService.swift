//
//  WidgetBudgetSnapshotService.swift
//  Fintrax
//
//  Fintrax documentation: Publishes budget summaries for Home and Lock Screen widgets.
//

import Foundation
import WidgetKit

@MainActor
struct WidgetBudgetSnapshotService {
    static let shared = WidgetBudgetSnapshotService()

    private let store = WidgetBudgetSnapshotStore()
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func update(from snapshot: DashboardDataSnapshot) {
        let isSyncedWithIncome = userDefaults.bool(forKey: BudgetCalculations.incomeBudgetSyncKey)
        let activeBudget = BudgetCalculations.activeMonthlyBudgetAmount(
            manualBudget: snapshot.monthlyBudget,
            incomes: snapshot.incomes,
            isSyncedWithIncome: isSyncedWithIncome
        )
        let spent = BudgetCalculations.calculateCurrentMonthExpenses(snapshot.expenses)
        let remaining = activeBudget.map { $0 - spent }
        let usage = activeBudget.map {
            NSDecimalNumber(decimal: $0 > 0 ? spent / $0 : .zero).doubleValue
        } ?? 0

        let widgetSnapshot = WidgetBudgetSnapshot(
            budgetAmount: activeBudget,
            spentAmount: spent,
            remainingAmount: remaining,
            usagePercentage: usage,
            daysRemaining: BudgetCalculations.daysRemainingInCurrentMonth(),
            isSyncedWithIncome: isSyncedWithIncome,
            updatedAt: Date()
        )

        store.saveSnapshot(widgetSnapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetBudgetSnapshotStore.budgetWidgetKind)
    }
}
