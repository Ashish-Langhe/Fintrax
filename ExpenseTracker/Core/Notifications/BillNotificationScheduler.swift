//
//  BillNotificationScheduler.swift
//  Fintrax
//
//  Fintrax documentation: Manages local notification scheduling, badge counts, and app notification identifiers.
//

import Foundation
import UserNotifications

/// Schedules and cancels local notifications for bill reminders.
///
/// Repeating bill reminders are implemented as a rolling set of one-time daily
/// follow-ups. This gives Fintrax control over cancelling every pending reminder
/// as soon as the user marks a bill complete.
enum BillNotificationScheduler {
    /// Number of future daily follow-ups scheduled for repeat-until-paid bills.
    private static let followUpDays = 14

    /// Requests alert, sound, and badge permission only when needed.
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    /// Replaces all pending notifications for a bill with the latest schedule.
    static func scheduleReminder(for bill: BillReminder, badgeCount: Int = 0) async {
        cancelReminder(for: bill.id)

        guard bill.reminderEnabled, !bill.isPaid else {
            return
        }

        guard await requestAuthorizationIfNeeded() else { return }

        await scheduleDueReminder(for: bill, badgeCount: badgeCount)

        if bill.repeatsUntilPaid {
            await scheduleFollowUps(for: bill, badgeCount: badgeCount)
        }
    }

    /// Removes pending and delivered notifications associated with a bill.
    static func cancelReminder(for billID: UUID) {
        let identifiers = notificationIdentifiers(for: billID)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Schedules a short test notification so users can verify device alert behavior.
    static func scheduleTestReminder() async -> Bool {
        guard await requestAuthorizationIfNeeded() else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Fintrax payment reminder"
        content.body = "This is how payment reminders will alert you."
        content.sound = .default
        content.threadIdentifier = "fintrax-bills"

        let request = UNNotificationRequest(
            identifier: "fintrax.bill.test",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            ErrorLogger.log(error, context: "BillNotificationScheduler.scheduleTestReminder")
            return false
        }
    }

    /// Schedules the primary due-date notification at the selected reminder time.
    private static func scheduleDueReminder(for bill: BillReminder, badgeCount: Int) async {
        let calendar = Calendar.current
        let fireDate = bill.scheduledNotificationDate
        guard fireDate > Date() else { return }
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: dueNotificationIdentifier(for: bill.id),
            content: notificationContent(
                title: "Bill reminder",
                body: "\(bill.title) is due today. Amount: \(CurrencyFormatter.format(bill.amount))",
                badgeCount: badgeCount,
                alertStyle: bill.alertStyle
            ),
            trigger: trigger
        )

        await add(request)
    }

    /// Schedules daily follow-ups after the due date for repeat-until-paid bills.
    private static func scheduleFollowUps(for bill: BillReminder, badgeCount: Int) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: bill.dueDate)
        let startDay = max(today, calendar.date(byAdding: .day, value: 1, to: dueDay) ?? dueDay)

        for offset in 0..<followUpDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }
            let fireDate = date(on: day, matchingTimeFrom: bill.reminderTime)
            guard fireDate > Date() else { continue }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: followUpNotificationIdentifier(for: bill.id, offset: offset),
                content: notificationContent(
                    title: "Bill still pending",
                    body: "\(bill.title) is unpaid. Mark it complete in Fintrax to stop reminders.",
                    badgeCount: badgeCount,
                    alertStyle: bill.alertStyle
                ),
                trigger: trigger
            )

            await add(request)
        }
    }

    private static func add(_ request: UNNotificationRequest) async {
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            ErrorLogger.log(error, context: "BillNotificationScheduler.scheduleReminder")
        }
    }

    private static func notificationContent(
        title: String,
        body: String,
        badgeCount: Int,
        alertStyle: BillReminder.AlertStyle
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if alertStyle == .soundAndVibration {
            content.sound = .default
        }
        content.threadIdentifier = "fintrax-bills"
        content.badge = NSNumber(value: badgeCount)
        return content
    }

    private static func date(on day: Date, matchingTimeFrom reminderTime: Date) -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        return calendar.date(from: DateComponents(
            year: dayComponents.year,
            month: dayComponents.month,
            day: dayComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? day
    }

    private static func notificationIdentifiers(for billID: UUID) -> [String] {
        [legacyNotificationIdentifier(for: billID), dueNotificationIdentifier(for: billID)] + (0..<followUpDays).map {
            followUpNotificationIdentifier(for: billID, offset: $0)
        }
    }

    /// Old identifier kept so upgrades can cancel requests from earlier builds.
    private static func legacyNotificationIdentifier(for billID: UUID) -> String {
        "fintrax.bill.\(billID.uuidString)"
    }

    private static func dueNotificationIdentifier(for billID: UUID) -> String {
        "fintrax.bill.\(billID.uuidString).due"
    }

    private static func followUpNotificationIdentifier(for billID: UUID, offset: Int) -> String {
        "fintrax.bill.\(billID.uuidString).followup.\(offset)"
    }
}

/// Shared INR formatter used by finance and notification copy.
enum CurrencyFormatter {
    static func format(_ amount: Decimal, maximumFractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0"
    }
}
