//
//  ExpenseViewModel.swift
//  Fintrax
//
//  Fintrax documentation: Builds expense list, filtering, searching, add/edit, validation, and row presentation flows.
//

import Combine
import Foundation
import SwiftUI

/// ViewModel for adding/editing an expense
@MainActor
class ExpenseViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title = ""
    @Published var amount: Decimal = Decimal(0)
    @Published var date = Date()
    @Published var selectedCategoryID: UUID?
    @Published var note = ""
    @Published var isLoading = false
    @Published var loadingState: LoadingState<Expense> = .idle
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isValid = false
    @Published private(set) var fieldErrors: [String: String] = [:]
    
    // MARK: - Private Properties
    private let repository: FinanceDataRepository
    private var existingExpense: Expense?
    private let validation = FormValidationState()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Mode
    enum Mode {
        case create
        case edit(Expense)
    }
    
    private var mode: Mode
    
    // MARK: - Initialization
    init(
        repository: FinanceDataRepository? = nil,
        expense: Expense? = nil
    ) {
        self.repository = repository ?? .shared
        self.mode = expense.map { .edit($0) } ?? .create
        
        if let expense = expense {
            self.existingExpense = expense
            loadExpense(expense)
        }
        
        observeFormChanges()
        validateForm()
    }
    
    // MARK: - Computed Properties
    var isEditing: Bool {
        switch mode {
        case .edit:
            return true
        case .create:
            return false
        }
    }
    
    var titleText: LocalizedStringKey {
        switch mode {
        case .create:
            return L10n.Expenses.addExpense
        case .edit:
            return L10n.Expenses.editExpense
        }
    }
    
    var saveButtonText: LocalizedStringKey {
        switch mode {
        case .create:
            return L10n.Expenses.addExpense
        case .edit:
            return L10n.Expenses.saveChanges
        }
    }
    
    // MARK: - Public Methods
    
    /// Save the expense (create or update)
    func save() async {
        validateForm()
        
        guard isValid else {
            let messages = fieldErrors.values.joined(separator: "\n")
            alertMessage = messages.isEmpty
                ? L10n.string(L10n.Expenses.fixErrors)
                : messages
            showAlert = true
            return
        }
        
        loadingState = .loading
        isLoading = true
        
        do {
            switch mode {
            case .create:
                // Create new expense
                let newExpense = Expense(
                    title: title,
                    amount: amount,
                    date: date,
                    categoryID: selectedCategoryID!,
                    note: note.isEmpty ? nil : note
                )
                
                try await repository.saveExpense(newExpense)
                loadingState = .success(newExpense)
                 
            case .edit(let existingExpense):
                // Update existing expense
                var updatedExpense = existingExpense
                try updatedExpense.update(
                    title: title,
                    amount: amount,
                    date: date,
                    categoryID: selectedCategoryID!,
                    note: note.isEmpty ? nil : note
                )
                
                try await repository.updateExpense(updatedExpense)
                loadingState = .success(updatedExpense)
            }
            
            isLoading = false
        } catch {
            loadingState = .failure(error)
            isLoading = false
            alertMessage = L10n.format(L10n.Expenses.saveFailed, error.localizedDescription)
            showAlert = true
        }
    }
    
    /// Load expense data into the form
    private func loadExpense(_ expense: Expense) {
        title = expense.title
        amount = expense.amount
        date = expense.date
        selectedCategoryID = expense.categoryID
        note = expense.note ?? ""
    }
    
    /// Reset the form
    func resetForm() {
        title = ""
        amount = Decimal(0)
        date = Date()
        selectedCategoryID = nil
        note = ""
        validation.clearAllErrors()
        validateForm()
    }
    
    /// Validate the form
    func validateForm() {
        validation.clearAllErrors()
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validation.setError(for: "title", message: L10n.string(L10n.Expenses.titleRequired))
        } else if title.count > 100 {
            validation.setError(for: "title", message: L10n.format(L10n.Expenses.titleTooLong, 100))
        }

        if amount <= .zero {
            validation.setError(for: "amount", message: L10n.string(L10n.Expenses.amountPositive))
        }

        if selectedCategoryID == nil {
            validation.setError(for: "category", message: L10n.string(L10n.Expenses.categoryRequired))
        }
        
        // Validate note (optional)
        if !note.isEmpty && note.count > 500 {
            validation.setError(for: "note", message: L10n.format(L10n.Expenses.noteTooLong, 500))
        }
        
        fieldErrors = validation.errors
        isValid = validation.isValid
    }
    
    /// Observe form fields and re-validate when any value changes
    private func observeFormChanges() {
        Publishers.CombineLatest4($title, $amount, $selectedCategoryID, $note)
            .combineLatest($date)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.validateForm()
            }
            .store(in: &cancellables)
    }
    
    /// Get error message for a field
    func errorMessage(for field: String) -> String? {
        fieldErrors[field]
    }
    
    /// Check if a field has an error
    func hasError(for field: String) -> Bool {
        fieldErrors[field] != nil
    }
    
    /// Update title and validate
    func updateTitle(_ newTitle: String) {
        title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        validateForm()
    }
    
    /// Update amount and validate
    func updateAmount(_ newAmount: Decimal) {
        amount = newAmount
        validateForm()
    }
    
    /// Update date and validate
    func updateDate(_ newDate: Date) {
        date = newDate
        validateForm()
    }
    
    /// Update category and validate
    func updateCategory(_ categoryId: UUID?) {
        selectedCategoryID = categoryId
        validateForm()
    }
    
    /// Update note and validate
    func updateNote(_ newNote: String) {
        note = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        validateForm()
    }
    
    /// Check if there are unsaved changes
    func hasChanges() -> Bool {
        guard let existing = existingExpense else {
            // For new expense, check if any field has been filled
            return !title.isEmpty || amount > 0 || !note.isEmpty || selectedCategoryID != nil
        }
        
        // For existing expense, check if any field changed
        return existing.title != title ||
               existing.amount != amount ||
               existing.date != date ||
               existing.categoryID != selectedCategoryID ||
               (existing.note ?? "") != note
    }
    
    /// Discard changes and reset to original values
    func discardChanges() {
        if let existing = existingExpense {
            loadExpense(existing)
        } else {
            resetForm()
        }
    }
    
    /// Get formatted amount for display
    func formattedAmount() -> String {
        return amount.formattedAmount()
    }
    
    /// Get formatted date for display
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ExpenseViewModelPreview()
}

private struct ExpenseViewModelPreview: View {
    @StateObject private var viewModel = ExpenseViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.titleText)
                .font(.title)
            
            TextField("Title", text: $viewModel.title)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(viewModel.hasError(for: "title") ? Color.red : Color.clear, lineWidth: 1)
                )
            
            if let error = viewModel.errorMessage(for: "title") {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Text("Amount: \(viewModel.formattedAmount())")
            Text("Date: \(viewModel.formattedDate())")
            Text("Valid: \(viewModel.isValid ? "Yes" : "No")")
                .foregroundColor(viewModel.isValid ? .green : .red)
            
            Button(viewModel.saveButtonText) {
                Task {
                    await viewModel.save()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValid)
        }
        .padding()
    }
}
