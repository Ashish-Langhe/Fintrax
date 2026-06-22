//
//  ExpenseDayDetailSheet.swift
//  Fintrax
//

import SwiftUI
import Foundation

struct ExpenseCalendarDayDetail: Identifiable {
    let date: Date

    var id: TimeInterval {
        date.timeIntervalSinceReferenceDate
    }
}

struct ExpenseDayDetailSheet: View {
    let date: Date
    let expenses: [Expense]
    let categories: [Category]

    private var totalSpend: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var highestExpense: Expense? {
        expenses.max { $0.amount < $1.amount }
    }

    private var topCategory: Category? {
        let grouped = Dictionary(grouping: expenses, by: \.categoryID)
        guard let categoryID = grouped.max(by: { lhs, rhs in
            lhs.value.reduce(Decimal.zero) { $0 + $1.amount } < rhs.value.reduce(Decimal.zero) { $0 + $1.amount }
        })?.key else {
            return nil
        }
        return categories.first { $0.id == categoryID }
    }

    private var dateTitle: String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sheetHeader
                insightGrid

                if expenses.isEmpty {
                    emptyState
                } else {
                    expenseRows
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(FintraxTabBackground(style: .expenses))
    }

    private var sheetHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: expenses.isEmpty ? "calendar" : "calendar.badge.clock")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background((topCategory?.displayColor ?? AppDesignSystem.Colors.primary).gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(dateTitle)
                        .font(AppDesignSystem.Typography.title3)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(expenses.isEmpty ? L10n.Expenses.noExpensesOnDate : LocalizedStringKey(L10n.format(L10n.Expenses.expensesRecorded, expenses.count)))
                        .font(AppDesignSystem.Typography.caption.weight(.semibold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(totalSpend.formattedAmount())
                    .font(AppDesignSystem.Typography.title2)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer()

                Text(L10n.Expenses.dayTotal)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Capsule())
            }
        }
        .padding(18)
        .background(sheetPanelBackground(accent: topCategory?.displayColor ?? AppDesignSystem.Colors.primary))
    }

    private var insightGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            DayDetailInsightChip(
                icon: "list.bullet.rectangle.fill",
                title: L10n.Expenses.entries,
                value: "\(expenses.count)",
                tint: AppDesignSystem.Colors.info
            )

            DayDetailInsightChip(
                icon: topCategory?.iconName ?? "tag.fill",
                title: L10n.Expenses.topCategory,
                value: topCategory?.name ?? L10n.string(L10n.Expenses.none),
                tint: topCategory?.displayColor ?? AppDesignSystem.Colors.textSecondary
            )

            DayDetailInsightChip(
                icon: "arrow.up.right.circle.fill",
                title: L10n.Expenses.highestItem,
                value: highestExpense?.formattedAmount() ?? "₹0",
                tint: AppDesignSystem.Colors.warning
            )

            DayDetailInsightChip(
                icon: "chart.pie.fill",
                title: L10n.Expenses.avgEntry,
                value: averageExpenseAmount.formattedAmount(),
                tint: AppDesignSystem.Colors.success
            )
        }
    }

    private var averageExpenseAmount: Decimal {
        guard !expenses.isEmpty else { return .zero }
        return totalSpend / Decimal(expenses.count)
    }

    private var expenseRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Expenses.title)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Spacer()

                Text(L10n.Expenses.highToLow)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.62), in: Capsule())
            }

            VStack(spacing: 0) {
                ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                    MonthDayExpenseRow(
                        expense: expense,
                        category: categories.first { $0.id == expense.categoryID }
                    )

                    if index < expenses.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
        }
        .padding(16)
        .background(sheetPanelBackground(accent: AppDesignSystem.Colors.info))
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .frame(width: 42, height: 42)
                .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.70), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.Expenses.quietDay)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(L10n.Expenses.quietDayMessage)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sheetPanelBackground(accent: AppDesignSystem.Colors.textSecondary))
    }

    private func sheetPanelBackground(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.76))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
    }
}

struct DayDetailInsightChip: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}
