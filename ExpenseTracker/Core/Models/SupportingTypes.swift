//
//  SupportingTypes.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation
import SwiftUI

/// Theme options for the app
enum ThemeOption: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark
    
    /// Returns the color scheme for SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Security type options for app protection
enum SecurityType: String, CaseIterable, Codable, Sendable {
    case none = "None"
    case biometrics = "Biometrics"
    case pin = "PIN"
}

/// Date range options for filtering expenses
enum DateRangeOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case allTime = "All Time"
    
    var id: String { rawValue }
    
    /// Filters expenses by this date range
    func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .last7Days:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return expenses.filter { $0.date >= sevenDaysAgo }
        case .last30Days:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return expenses.filter { $0.date >= thirtyDaysAgo }
        case .last90Days:
            let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            return expenses.filter { $0.date >= ninetyDaysAgo }
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components) ?? now
            return expenses.filter { $0.date >= startOfMonth }
        case .thisYear:
            let components = calendar.dateComponents([.year], from: now)
            let startOfYear = calendar.date(from: components) ?? now
            return expenses.filter { $0.date >= startOfYear }
        case .allTime:
            return expenses
        }
    }
    
    /// Returns the date range as a tuple of start and end dates
    func getDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start: start, end: now)
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return (start: start, end: now)
        case .last90Days:
            let start = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            return (start: start, end: now)
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components) ?? now
            return (start: start, end: now)
        case .thisYear:
            let components = calendar.dateComponents([.year], from: now)
            let start = calendar.date(from: components) ?? now
            return (start: start, end: now)
        case .allTime:
            // Return a very old date as start
            let start = Date(timeIntervalSince1970: 0)
            return (start: start, end: now)
        }
    }
}

/// Budget status based on spending percentage
enum BudgetStatus: Sendable {
    case withinLimit(percentage: Double)
    case approachingLimit(percentage: Double)
    case exceededLimit(percentage: Double)
    
    /// Returns the color associated with this status
    var color: String {
        switch self {
        case .withinLimit: return "green"
        case .approachingLimit: return "orange"
        case .exceededLimit: return "red"
        }
    }
    
    /// Returns a descriptive message for this status
    var message: String {
        switch self {
        case .withinLimit(let percentage):
            return "Within budget (\(Int(percentage * 100))%)"
        case .approachingLimit(let percentage):
            return "Approaching budget limit (\(Int(percentage * 100))%)"
        case .exceededLimit(let percentage):
            return "Budget exceeded (\(Int(percentage * 100))%)"
        }
    }
    
    /// Returns the percentage value
    var percentage: Double {
        switch self {
        case .withinLimit(let percentage), .approachingLimit(let percentage), .exceededLimit(let percentage):
            return percentage
        }
    }
}

/// Loading state for async operations
enum LoadingState<T: Sendable>: Sendable {
    case idle
    case loading
    case success(T)
    case failure(Error)
    
    /// Whether the state is currently loading
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    /// The value if in success state
    var value: T? {
        if case .success(let value) = self { return value }
        return nil
    }
    
    /// The error if in failure state
    var error: Error? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

/// Default category names
let DefaultCategories = [
    "Food", 
    "Transportation", 
    "Entertainment", 
    "Utilities", 
    "Health", 
    "Shopping", 
    "Other"
]

/// Sort options for expense lists
enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case dateDescending = "Date (Newest First)"
    case dateAscending = "Date (Oldest First)"
    case amountDescending = "Amount (Highest First)"
    case amountAscending = "Amount (Lowest First)"
    case titleAscending = "Title (A-Z)"
    case titleDescending = "Title (Z-A)"
    
    var id: String { rawValue }
}