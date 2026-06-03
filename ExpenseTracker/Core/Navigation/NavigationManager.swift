//
//  NavigationManager.swift
//  Fintrax
//
//  Fintrax documentation: Defines tab routing and navigation state for the Fintrax app shell.
//

import SwiftUI

/// Navigation state manager for the app
class NavigationManager: ObservableObject {
    /// Current navigation path
    @Published var path = NavigationPath()
    
    /// Current selected tab in the sidebar
    @Published var selectedTab: NavigationDestination = .dashboard
    
    /// Navigate to a specific destination
    /// - Parameter destination: The destination to navigate to
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }
    
    /// Navigate back to previous screen
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// Navigate back to root
    func navigateToRoot() {
        path.removeLast(path.count)
    }
    
    /// Pop back to a specific destination
    /// - Parameter destination: The destination to pop to
    func popTo(destination: NavigationDestination) {
        // This would require tracking path history
        // For now, implement back navigation multiple times
        path.removeLast()
    }
    
    /// Navigate programmatically to a tab
    /// - Parameter tab: The tab to navigate to
    func selectTab(_ tab: NavigationDestination) {
        selectedTab = tab
        navigateToRoot() // Clear the navigation path when switching tabs
    }
}

/// Navigation destinations used throughout the app
enum NavigationDestination: Hashable, Codable {
    case dashboard
    case expenseList
    case analytics
    case addExpense(expenseID: UUID?)
    case categoryManagement
    case budgetSettings
    case settings
    case securitySettings
    case exportData
    
    /// Returns the display title for this destination
    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .expenseList:
            return "Expenses"
        case .analytics:
            return "Analytics"
        case .addExpense:
            return "Expense Details"
        case .categoryManagement:
            return "Categories"
        case .budgetSettings:
            return "Budgets"
        case .settings:
            return "Settings"
        case .securitySettings:
            return "Security"
        case .exportData:
            return "Export"
        }
    }
    
    /// Returns the SF Symbol name for this destination
    var systemImage: String {
        switch self {
        case .dashboard:
            return "chart.pie.fill"
        case .expenseList:
            return "list.bullet"
        case .analytics:
            return "chart.xyaxis.line"
        case .addExpense:
            return "plus.circle.fill"
        case .categoryManagement:
            return "tag.fill"
        case .budgetSettings:
            return "banknote.fill"
        case .settings:
            return "gear"
        case .securitySettings:
            return "lock.shield"
        case .exportData:
            return "square.and.arrow.up"
        }
    }
    
    /// Determines if this destination should be in the sidebar
    var showInSidebar: Bool {
        switch self {
        case .dashboard, .expenseList, .analytics, .budgetSettings, .settings:
            return true
        case .addExpense, .categoryManagement, .securitySettings, .exportData:
            return false
        }
    }
    
    /// Returns the sidebar destinations in order
    static var sidebarDestinations: [NavigationDestination] {
        return [.dashboard, .expenseList, .analytics, .budgetSettings, .settings]
    }
}

// MARK: - Navigation Helper Extensions
extension NavigationManager {
    /// Convenience method for adding new expense
    func addNewExpense() {
        navigate(to: .addExpense(expenseID: nil))
    }
    
    /// Convenience method for editing existing expense
    /// - Parameter expenseID: ID of the expense to edit
    func editExpense(id expenseID: UUID) {
        navigate(to: .addExpense(expenseID: expenseID))
    }
    
    /// Check if current root view matches a destination
    /// - Parameter destination: The destination to check
    /// - Returns: Whether we're at the root of that destination
    func isAtRoot(of destination: NavigationDestination) -> Bool {
        return path.isEmpty && selectedTab == destination
    }
}
