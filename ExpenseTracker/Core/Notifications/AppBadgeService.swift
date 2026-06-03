//
//  AppBadgeService.swift
//  Fintrax
//
//  Fintrax documentation: Manages local notification scheduling, badge counts, and app notification identifiers.
//

import Foundation
import UIKit
import UserNotifications

enum AppBadgeService {
    static func actionableBillCount(from bills: [BillReminder]) -> Int {
        bills.filter(\.requiresAttention).count
    }

    @MainActor
    static func updateBillBadgeCount(from bills: [BillReminder]) {
        setBadgeCount(actionableBillCount(from: bills))
    }

    @MainActor
    static func setBadgeCount(_ count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error {
                    ErrorLogger.log(error, context: "AppBadgeService.setBadgeCount")
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}
