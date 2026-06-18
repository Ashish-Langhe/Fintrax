//
//  AddEditExpenseNavigationView.swift
//  Fintrax
//
//  Fintrax documentation: Builds expense list, filtering, searching, add/edit, validation, and row presentation flows.
//

import SwiftUI

/// Wrapper view for AddEditExpenseView that handles navigation parameters
struct AddEditExpenseNavigationView: View {
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var expense: Expense?
    @State private var isLoading = true
    @State private var error: String?
    
    let expenseID: UUID?
    private let navigationManager = NavigationManager()
    
    init(expenseID: UUID? = nil) {
        self.expenseID = expenseID
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView(L10n.Expenses.loadingShort)
            } else if let error = error {
                ErrorView(message: error) {
                    Task {
                        await loadExpense()
                    }
                }
            } else {
                if let expense = expense {
                    AddEditExpenseView(expense: expense)
                } else {
                    AddEditExpenseView()
                }
            }
        }
        .task {
            await loadExpense()
        }
    }
    
    private func loadExpense() async {
        guard let expenseID = expenseID else {
            isLoading = false
            return
        }
        
        do {
            let expenses = try await FinanceDataRepository.shared.loadExpenses()
            expense = expenses.first { $0.id == expenseID }
            isLoading = false
        } catch {
            self.error = L10n.format(L10n.Expenses.loadFailed, error.localizedDescription)
            isLoading = false
        }
    }
}

/// Simple error view for loading failures
private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(L10n.Expenses.error)
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Text(L10n.Expenses.retry)
            }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
