//
//  DeveloperDataMode.swift
//  Fintrax
//
//  Fintrax documentation: Controls hidden developer-only data source switching.
//

import Foundation

enum DeveloperDataMode {
    static let mockDataEnabledKey = "developerMockDataEnabled"

    #if DEBUG
    static var isMockDataEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: mockDataEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: mockDataEnabledKey) }
    }
    #else
    static var isMockDataEnabled: Bool {
        get { false }
        set { UserDefaults.standard.removeObject(forKey: mockDataEnabledKey) }
    }
    #endif
}
