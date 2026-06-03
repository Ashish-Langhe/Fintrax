//
//  SwiftDataModels.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation
import SwiftData

@Model
final class StoredCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorName: String
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorName: String,
        isDefault: Bool,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class StoredExpense {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: String
    var date: Date
    var categoryID: UUID
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date,
        categoryID: UUID,
        note: String?,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = NSDecimalNumber(decimal: amount).stringValue
        self.date = date
        self.categoryID = categoryID
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class StoredMonthlyBudget {
    @Attribute(.unique) var id: String
    var amount: String
    var setAt: Date

    init(id: String = "monthly-budget", amount: Decimal, setAt: Date = Date()) {
        self.id = id
        self.amount = NSDecimalNumber(decimal: amount).stringValue
        self.setAt = setAt
    }
}

@Model
final class StoredIncomeRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: String
    var date: Date
    var source: String
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date,
        source: String,
        note: String?,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = NSDecimalNumber(decimal: amount).stringValue
        self.date = date
        self.source = source
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class StoredBillReminder {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: String
    var dueDate: Date
    var note: String?
    var isPaid: Bool
    var reminderEnabled: Bool
    var reminderTime: Date?
    var repeatsUntilPaid: Bool = false
    var alertStyleRawValue: String = BillReminder.AlertStyle.soundAndVibration.rawValue
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        dueDate: Date,
        note: String?,
        isPaid: Bool,
        reminderEnabled: Bool,
        reminderTime: Date? = nil,
        repeatsUntilPaid: Bool = false,
        alertStyleRawValue: String = BillReminder.AlertStyle.soundAndVibration.rawValue,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = NSDecimalNumber(decimal: amount).stringValue
        self.dueDate = dueDate
        self.note = note
        self.isPaid = isPaid
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.repeatsUntilPaid = repeatsUntilPaid
        self.alertStyleRawValue = alertStyleRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension StoredCategory {
    var category: Category {
        var category = Category(id: id, name: name, iconName: iconName, colorName: colorName, isDefault: isDefault)
        category.createdAt = createdAt
        category.updatedAt = updatedAt
        return category
    }

    func update(from category: Category) {
        name = category.name
        iconName = category.iconName
        colorName = category.colorName
        isDefault = category.isDefault
        createdAt = category.createdAt
        updatedAt = category.updatedAt
    }
}

extension StoredExpense {
    var expense: Expense {
        var expense = Expense(
            id: id,
            title: title,
            amount: Decimal(string: amount) ?? .zero,
            date: date,
            categoryID: categoryID,
            note: note
        )
        expense.createdAt = createdAt
        expense.updatedAt = updatedAt
        return expense
    }

    func update(from expense: Expense) {
        title = expense.title
        amount = NSDecimalNumber(decimal: expense.amount).stringValue
        date = expense.date
        categoryID = expense.categoryID
        note = expense.note
        createdAt = expense.createdAt
        updatedAt = expense.updatedAt
    }
}

extension StoredMonthlyBudget {
    var monthlyBudget: MonthlyBudget {
        var budget = MonthlyBudget(amount: Decimal(string: amount) ?? .zero)
        budget.setAt = setAt
        return budget
    }

    func update(from monthlyBudget: MonthlyBudget) {
        amount = NSDecimalNumber(decimal: monthlyBudget.amount).stringValue
        setAt = monthlyBudget.setAt
    }
}

extension StoredIncomeRecord {
    var incomeRecord: IncomeRecord {
        var income = IncomeRecord(
            id: id,
            title: title,
            amount: Decimal(string: amount) ?? .zero,
            date: date,
            source: source,
            note: note
        )
        income.createdAt = createdAt
        income.updatedAt = updatedAt
        return income
    }

    func update(from income: IncomeRecord) {
        title = income.title
        amount = NSDecimalNumber(decimal: income.amount).stringValue
        date = income.date
        source = income.source
        note = income.note
        createdAt = income.createdAt
        updatedAt = income.updatedAt
    }
}

extension StoredBillReminder {
    var billReminder: BillReminder {
        var bill = BillReminder(
            id: id,
            title: title,
            amount: Decimal(string: amount) ?? .zero,
            dueDate: dueDate,
            note: note,
            isPaid: isPaid,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime ?? BillReminder.defaultReminderTime(),
            repeatsUntilPaid: repeatsUntilPaid,
            alertStyle: BillReminder.AlertStyle(rawValue: alertStyleRawValue) ?? .soundAndVibration
        )
        bill.createdAt = createdAt
        bill.updatedAt = updatedAt
        return bill
    }

    func update(from bill: BillReminder) {
        title = bill.title
        amount = NSDecimalNumber(decimal: bill.amount).stringValue
        dueDate = bill.dueDate
        note = bill.note
        isPaid = bill.isPaid
        reminderEnabled = bill.reminderEnabled
        reminderTime = bill.reminderTime
        repeatsUntilPaid = bill.repeatsUntilPaid
        alertStyleRawValue = bill.alertStyle.rawValue
        createdAt = bill.createdAt
        updatedAt = bill.updatedAt
    }
}
