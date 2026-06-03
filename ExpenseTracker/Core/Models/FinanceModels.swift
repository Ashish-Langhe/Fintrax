//
//  FinanceModels.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

struct IncomeRecord: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var amount: Decimal
    var date: Date
    var source: String
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date = Date(),
        source: String = "Salary",
        note: String? = nil
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amount = amount
        self.date = date
        self.source = source.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }

    func validate() -> ValidationResult {
        guard !title.isEmpty else {
            return ValidationResult(isValid: false, error: "Income title cannot be empty")
        }

        guard amount > 0 else {
            return ValidationResult(isValid: false, error: "Income amount must be greater than 0")
        }

        guard amount <= 99999999.99 else {
            return ValidationResult(isValid: false, error: "Income amount is too high")
        }

        return ValidationResult(isValid: true)
    }
}

struct BillReminder: Identifiable, Codable, Hashable, Sendable {
    enum AlertStyle: String, CaseIterable, Identifiable, Codable, Sendable {
        case soundAndVibration
        case silent

        var id: String { rawValue }

        var title: String {
            switch self {
            case .soundAndVibration:
                return "Sound + Vibration"
            case .silent:
                return "Silent Badge"
            }
        }

        var icon: String {
            switch self {
            case .soundAndVibration:
                return "speaker.wave.2.fill"
            case .silent:
                return "bell.slash.fill"
            }
        }
    }

    let id: UUID
    var title: String
    var amount: Decimal
    var dueDate: Date
    var note: String?
    var isPaid: Bool
    var reminderEnabled: Bool
    var reminderTime: Date
    var repeatsUntilPaid: Bool
    var alertStyle: AlertStyle
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        dueDate: Date = Date(),
        note: String? = nil,
        isPaid: Bool = false,
        reminderEnabled: Bool = true,
        reminderTime: Date = BillReminder.defaultReminderTime(),
        repeatsUntilPaid: Bool = false,
        alertStyle: AlertStyle = .soundAndVibration
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amount = amount
        self.dueDate = dueDate
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isPaid = isPaid
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.repeatsUntilPaid = repeatsUntilPaid
        self.alertStyle = alertStyle
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case dueDate
        case note
        case isPaid
        case reminderEnabled
        case reminderTime
        case repeatsUntilPaid
        case alertStyle
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Decimal.self, forKey: .amount)
        dueDate = try container.decode(Date.self, forKey: .dueDate)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        isPaid = try container.decode(Bool.self, forKey: .isPaid)
        reminderEnabled = try container.decode(Bool.self, forKey: .reminderEnabled)
        reminderTime = try container.decode(Date.self, forKey: .reminderTime)
        repeatsUntilPaid = try container.decodeIfPresent(Bool.self, forKey: .repeatsUntilPaid) ?? false
        alertStyle = try container.decodeIfPresent(AlertStyle.self, forKey: .alertStyle) ?? .soundAndVibration
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func validate() -> ValidationResult {
        guard !title.isEmpty else {
            return ValidationResult(isValid: false, error: "Bill title cannot be empty")
        }

        guard amount > 0 else {
            return ValidationResult(isValid: false, error: "Bill amount must be greater than 0")
        }

        return ValidationResult(isValid: true)
    }

    var isOverdue: Bool {
        !isPaid && dueDate < Calendar.current.startOfDay(for: Date())
    }

    var isDueSoon: Bool {
        guard !isPaid else { return false }
        let now = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return dueDate >= Calendar.current.startOfDay(for: now) && dueDate <= nextWeek
    }

    var requiresAttention: Bool {
        isOverdue || isDueSoon
    }

    var scheduledNotificationDate: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        return calendar.date(
            from: DateComponents(
                year: dateComponents.year,
                month: dateComponents.month,
                day: dateComponents.day,
                hour: timeComponents.hour,
                minute: timeComponents.minute
            )
        ) ?? dueDate
    }

    var formattedReminderTime: String {
        reminderTime.formatted(date: .omitted, time: .shortened)
    }

    static func defaultReminderTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

extension Array where Element == IncomeRecord {
    var totalIncome: Decimal {
        reduce(.zero) { $0 + $1.amount }
    }
}

extension Array where Element == BillReminder {
    var unpaidTotal: Decimal {
        filter { !$0.isPaid }.reduce(.zero) { $0 + $1.amount }
    }
}
