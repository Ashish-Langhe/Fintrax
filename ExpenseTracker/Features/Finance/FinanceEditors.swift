//
//  FinanceEditors.swift
//  Fintrax
//

import SwiftUI

struct IncomeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var source: String
    @State private var date: Date
    @State private var note: String

    let income: IncomeRecord?
    let onSave: (IncomeRecord) -> Void

    init(income: IncomeRecord?, onSave: @escaping (IncomeRecord) -> Void) {
        self.income = income
        self.onSave = onSave
        _title = State(initialValue: income?.title ?? "")
        _amount = State(initialValue: income.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? "")
        _source = State(initialValue: income?.source ?? "Salary")
        _date = State(initialValue: income?.date ?? Date())
        _note = State(initialValue: income?.note ?? "")
    }

    var body: some View {
        FinanceEditorShell(title: income == nil ? "Add Income" : "Update Income") {
            FinanceTextField(title: "Title", text: $title, placeholder: "Salary, Freelance, Refund")
            FinanceTextField(title: "Amount", text: $amount, placeholder: "50000", keyboardType: .decimalPad)
            FinanceTextField(title: "Source", text: $source, placeholder: "Salary")
            DatePicker("Date", selection: $date, displayedComponents: .date)
            FinanceTextField(title: "Note", text: $note, placeholder: "Optional")
        } saveAction: {
            let parsedAmount = Decimal(string: amount) ?? .zero
            var record = IncomeRecord(
                id: income?.id ?? UUID(),
                title: title,
                amount: parsedAmount,
                date: date,
                source: source,
                note: note.isEmpty ? nil : note
            )
            record.createdAt = income?.createdAt ?? Date()
            record.updatedAt = Date()
            onSave(record)
            dismiss()
        }
    }
}

struct BillEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var dueDate: Date
    @State private var note: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var repeatsUntilPaid: Bool
    @State private var alertStyle: BillReminder.AlertStyle

    let bill: BillReminder?
    let onSave: (BillReminder) -> Void

    init(bill: BillReminder?, onSave: @escaping (BillReminder) -> Void) {
        self.bill = bill
        self.onSave = onSave
        _title = State(initialValue: bill?.title ?? "")
        _amount = State(initialValue: bill.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? "")
        _dueDate = State(initialValue: bill?.dueDate ?? Date())
        _note = State(initialValue: bill?.note ?? "")
        _reminderEnabled = State(initialValue: bill?.reminderEnabled ?? true)
        _reminderTime = State(initialValue: bill?.reminderTime ?? BillReminder.defaultReminderTime())
        _repeatsUntilPaid = State(initialValue: bill?.repeatsUntilPaid ?? false)
        _alertStyle = State(initialValue: bill?.alertStyle ?? .soundAndVibration)
    }

    var body: some View {
        FinanceEditorShell(title: bill == nil ? "Add Bill" : "Update Bill") {
            FinanceTextField(title: "Title", text: $title, placeholder: "Rent, EMI, Internet")
            FinanceTextField(title: "Amount", text: $amount, placeholder: "2500", keyboardType: .decimalPad)
            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
            Toggle("Internal reminder", isOn: $reminderEnabled)
                .padding()
                .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if reminderEnabled {
                DatePicker("Notification Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .padding()
                    .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                FinanceReminderRepeatPanel(isOn: $repeatsUntilPaid)
                FinanceReminderAlertStylePanel(selection: $alertStyle)
            }

            FinanceTextField(title: "Note", text: $note, placeholder: "Optional")
        } saveAction: {
            let parsedAmount = Decimal(string: amount) ?? .zero
            var record = BillReminder(
                id: bill?.id ?? UUID(),
                title: title,
                amount: parsedAmount,
                dueDate: dueDate,
                note: note.isEmpty ? nil : note,
                isPaid: bill?.isPaid ?? false,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                repeatsUntilPaid: reminderEnabled && repeatsUntilPaid,
                alertStyle: reminderEnabled ? alertStyle : .silent
            )
            record.createdAt = bill?.createdAt ?? Date()
            record.updatedAt = Date()
            onSave(record)
            dismiss()
        }
    }
}
