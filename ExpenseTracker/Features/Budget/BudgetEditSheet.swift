//
//  BudgetEditSheet.swift
//  Fintrax
//
//  Fintrax documentation: Builds budget creation, update, progress, and budget insight UI.
//

import SwiftUI
import Foundation

/// Sheet for editing or creating a budget
struct BudgetEditSheet: View {
    let currentBudget: MonthlyBudget?
    let onSave: (Decimal) async -> Bool
    
    @State private var budgetInput: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var validationState: ValidationState = .idle
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    amountCard

                    guidelineCard

                    if let currentBudget = currentBudget {
                        currentBudgetCard(currentBudget)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .background(BudgetSheetBackground())
            .navigationTitle(LocalizedStringKey(currentBudget == nil ? "Set Budget" : "Edit Budget"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(validationState != .valid || isLoading)
                    .fontWeight(.semibold)
                }
            }
            .disabled(isLoading)
        }
        .onAppear {
            setupInitialValue()
            isInputFocused = true
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppDesignSystem.Colors.background.opacity(0.82))
            }
        }
    }

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "target")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Budget")
                        .font(.headline)
                    Text(LocalizedStringKey(currentBudget == nil ? "Create your spending limit" : "Update your monthly limit"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("₹")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $budgetInput)
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .onChange(of: budgetInput) { _, newValue in
                        validateInput(newValue)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(AppDesignSystem.Colors.controlFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(validationState == .invalid ? Color.red.opacity(0.55) : AppDesignSystem.Colors.cardStroke, lineWidth: 1)
            )

            quickBudgetRow

            validationMessage
        }
        .padding(18)
        .budgetSheetCard()
    }

    private var quickBudgetRow: some View {
        HStack(spacing: 8) {
            ForEach([10000, 25000, 50000, 75000], id: \.self) { amount in
                Button {
                    budgetInput = "\(amount)"
                    validateInput(budgetInput)
                } label: {
                    Text("₹\(amount / 1000)k")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [AppDesignSystem.Colors.controlFill, Color.blue.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke(AppDesignSystem.Colors.cardStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var guidelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            BudgetSheetSectionHeader(title: "Guidelines", icon: "checklist", tint: .blue)

            VStack(alignment: .leading, spacing: 10) {
                GuidelineRow(
                    icon: "info.circle.fill",
                    title: "Minimum Amount",
                    description: "₹1.00 minimum"
                )
                
                GuidelineRow(
                    icon: "chart.bar.fill",
                    title: "Track Spending",
                    description: "Budget helps monitor monthly expenses"
                )
                
                GuidelineRow(
                    icon: "calendar",
                    title: "Monthly Reset",
                    description: "Budget resets at start of each month"
                )
            }
        }
        .padding(18)
        .budgetSheetCard()
    }

    private func currentBudgetCard(_ currentBudget: MonthlyBudget) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BudgetSheetSectionHeader(title: "Current Budget", icon: "wallet.pass.fill", tint: .green)

            VStack(spacing: 10) {
                BudgetSheetInfoRow(
                    title: "Current Amount",
                    value: BudgetValidation.formatBudgetAmount(currentBudget.amount),
                    icon: "indianrupeesign.circle.fill"
                )

                BudgetSheetInfoRow(
                    title: "Set On",
                    value: currentBudget.setAt.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar"
                )
            }
        }
        .padding(18)
        .budgetSheetCard()
    }

    @ViewBuilder
    private var validationMessage: some View {
        if let errorMessage = errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        } else if validationState == .valid {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Valid budget amount")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialValue() {
        if let currentBudget = currentBudget {
            budgetInput = BudgetValidation.formatBudgetAmountForInput(currentBudget.amount)
        } else {
            budgetInput = ""
        }
    }
    
    private func validateInput(_ input: String) {
        let result = BudgetValidation.validateAndParseBudgetInput(input)
        
        switch result {
        case .success(_):
            errorMessage = nil
            validationState = .valid
        case .failure(let error):
            errorMessage = error.localizedDescription
            validationState = .invalid
        }
    }
    
    private func saveBudget() {
        guard validationState == .valid else { return }
        
        isLoading = true
        
        let result = BudgetValidation.validateAndParseBudgetInput(budgetInput)
        
        switch result {
        case .success(let amount):
            Task {
                if await onSave(amount) {
                    dismiss()
                } else {
                    errorMessage = L10n.string("Failed to save budget. Please try again.")
                    isLoading = false
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    enum ValidationState {
        case idle
        case valid
        case invalid
    }
}

// MARK: - Supporting Views

private struct GuidelineRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(LocalizedStringKey(description))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(10)
        .fintraxControlFill(cornerRadius: 14)
    }
}

private struct BudgetSheetSectionHeader: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(LocalizedStringKey(title))
                .font(.headline)

            Spacer()
        }
    }
}

private struct BudgetSheetInfoRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.medium))

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(12)
        .fintraxControlFill(cornerRadius: 14)
    }
}

private struct BudgetSheetBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 20

                for y in stride(from: CGFloat.zero, through: size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y + size.width * 0.12))
                }

                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)

                let markColor = Color.primary.opacity(0.055)
                for row in stride(from: CGFloat(38), through: size.height, by: 96) {
                    for column in stride(from: CGFloat(24), through: size.width, by: 112) {
                        context.fill(Path(roundedRect: CGRect(x: column, y: row, width: 8, height: 8), cornerRadius: 2), with: .color(markColor))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func budgetSheetCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .fintraxSurface(cornerRadius: cornerRadius, accent: AppDesignSystem.Colors.primary)
    }
}

#Preview {
    BudgetEditSheet(
        currentBudget: nil,
        onSave: { _ in true }
    )
}

#Preview("Edit Existing") {
    BudgetEditSheet(
        currentBudget: MonthlyBudget.sample,
        onSave: { _ in true }
    )
}
