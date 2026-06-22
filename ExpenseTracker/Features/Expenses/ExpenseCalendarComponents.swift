//
//  ExpenseCalendarComponents.swift
//  Fintrax
//

import SwiftUI
import Foundation

struct CalendarStatTile: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: Circle())

            Text(title)
                .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)

            Text(value)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
        }
    }
}

struct CalendarMicroMetric: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.54), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

struct CalendarLegendPill: View {
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppDesignSystem.Colors.primary.opacity(0.18 + Double(index) * 0.17))
                    .frame(width: 12, height: 8)
            }

            Text(L10n.Expenses.spend)
                .font(AppDesignSystem.Typography.caption2.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.64), in: Capsule())
        .overlay {
            Capsule()
                .stroke(AppDesignSystem.Colors.primary.opacity(0.14), lineWidth: 1)
        }
        .accessibilityLabel(L10n.Expenses.darkerDaysAccessibility)
    }
}

struct ExpenseMonthDay: Identifiable {
    let id = UUID()
    let date: Date?
    let dayNumber: Int?
    let amount: Decimal
    let count: Int
    let isToday: Bool
    let isSelected: Bool

    static func blank() -> ExpenseMonthDay {
        ExpenseMonthDay(date: nil, dayNumber: nil, amount: .zero, count: 0, isToday: false, isSelected: false)
    }
}

struct ExpenseMonthDayCell: View {
    let day: ExpenseMonthDay
    let maxAmount: Decimal
    let onSelect: () -> Void

    private var hasSpend: Bool {
        day.amount > 0
    }

    private var intensity: Double {
        guard maxAmount > 0, hasSpend else { return 0 }
        return min(max(NSDecimalNumber(decimal: day.amount / maxAmount).doubleValue, 0.18), 1)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    Text(day.dayNumber.map(String.init) ?? "")
                        .font(AppDesignSystem.Typography.caption.weight(day.isSelected ? .bold : .semibold))
                        .foregroundStyle(dayTextColor)
                        .frame(height: 15)

                    if day.isToday && day.date != nil {
                        Circle()
                            .fill(day.isSelected ? Color.white.opacity(0.90) : AppDesignSystem.Colors.primary)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity)

                if hasSpend {
                    Text(shortAmount(day.amount))
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(day.isSelected ? .white : AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                } else if day.date != nil {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(day.isToday ? AppDesignSystem.Colors.primary.opacity(0.26) : Color.clear)
                        .frame(width: 14, height: 5)
                } else {
                    Color.clear.frame(height: 10)
                }

                spendIndicator
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(dayBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(dayBorderColor, lineWidth: day.isSelected ? 1.2 : 0.8)
            }
            .shadow(color: shadowColor, radius: day.isSelected ? 9 : 0, x: 0, y: day.isSelected ? 6 : 0)
        }
        .buttonStyle(.plain)
        .disabled(day.date == nil)
        .accessibilityLabel(accessibilityLabel)
    }

    private var dayTextColor: Color {
        if day.isSelected { return .white }
        if day.date == nil { return .clear }
        if day.isToday { return AppDesignSystem.Colors.primary }
        return AppDesignSystem.Colors.textPrimary
    }

    private var dayBackground: some ShapeStyle {
        if day.isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.primary,
                        AppDesignSystem.Colors.primaryDark.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        if hasSpend {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.primary.opacity(0.08 + (0.14 * intensity)),
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(AppDesignSystem.Colors.elevatedSurface.opacity(day.date == nil ? 0 : 0.54))
    }

    private var dayBorderColor: Color {
        if day.isSelected { return Color.white.opacity(0.38) }
        if hasSpend { return AppDesignSystem.Colors.primary.opacity(0.14 + (0.12 * intensity)) }
        if day.isToday { return AppDesignSystem.Colors.primary.opacity(0.26) }
        return Color.white.opacity(0.12)
    }

    private var shadowColor: Color {
        AppDesignSystem.Colors.primary.opacity(0.20)
    }

    @ViewBuilder
    private var spendIndicator: some View {
        if hasSpend {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(spendBarColor(for: index))
                        .frame(width: 6, height: 3)
                }
            }
            .opacity(day.isSelected ? 0.95 : 0.72)
        } else {
            Color.clear.frame(height: 3)
        }
    }

    private func spendBarColor(for index: Int) -> Color {
        let threshold = Double(index + 1) / 3
        if intensity >= threshold {
            return day.isSelected ? .white : AppDesignSystem.Colors.primary
        }
        return day.isSelected ? Color.white.opacity(0.32) : AppDesignSystem.Colors.primary.opacity(0.18)
    }

    private var accessibilityLabel: String {
        guard let date = day.date else { return L10n.string(L10n.Expenses.blankCalendarDay) }
        let dateText = date.formatted(.dateTime.day().month(.wide))
        if hasSpend {
            return L10n.format(L10n.Expenses.dayAccessibilityWithSpend, dateText, day.amount.formattedAmount(), day.count)
        }
        return L10n.format(L10n.Expenses.dayAccessibilityNoSpend, dateText)
    }

    private func shortAmount(_ amount: Decimal) -> String {
        let value = NSDecimalNumber(decimal: amount).doubleValue
        if value >= 100_000 {
            return String(format: "₹%.0fL", value / 100_000)
        }
        if value >= 1_000 {
            return String(format: "₹%.0fk", value / 1_000)
        }
        return "₹\(Int(value))"
    }
}

struct MonthDayExpenseRow: View {
    let expense: Expense
    let category: Category?

    private var categoryColor: Color {
        category?.displayColor ?? AppDesignSystem.Colors.primary
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category?.iconName ?? "tag.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(categoryColor)
                .frame(width: 30, height: 30)
                .background(categoryColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Text(category?.name ?? L10n.string(L10n.Expenses.uncategorized))
                    .font(AppDesignSystem.Typography.caption2.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(expense.formattedAmount())
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.error)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
    }
}

struct ExpenseCalendarSectionHeader: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(title)
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            Spacer()
        }
    }
}

