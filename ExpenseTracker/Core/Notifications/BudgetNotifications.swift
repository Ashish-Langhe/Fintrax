//
//  BudgetNotifications.swift
//  Fintrax
//
//  Fintrax documentation: Manages local notification scheduling, badge counts, and app notification identifiers.
//

import Foundation

/// Notification names for budget updates
extension Notification.Name {
    static let budgetDidChange = Notification.Name("BudgetDidChange")
    static let expenseDidChange = Notification.Name("ExpenseDidChange")
    static let categoryDidChange = Notification.Name("CategoryDidChange")
    static let incomeDidChange = Notification.Name("IncomeDidChange")
    static let billReminderDidChange = Notification.Name("BillReminderDidChange")
}
