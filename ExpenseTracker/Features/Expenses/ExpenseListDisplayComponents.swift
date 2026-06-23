//
//  ExpenseListDisplayComponents.swift
//  Fintrax
//
//  Fintrax documentation: Extracted reusable expense screen components.
//

import SwiftUI
import Foundation

enum ExpenseDisplayMode: String, CaseIterable, Identifiable {
    case list = "List"
    case calendar = "Month"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .list:
            L10n.Expenses.listMode
        case .calendar:
            L10n.Expenses.monthMode
        }
    }

    var icon: String {
        switch self {
        case .list:
            return "list.bullet.rectangle"
        case .calendar:
            return "calendar"
        }
    }
}

struct ExpenseDisplayModePicker: View {
    @Binding var selection: ExpenseDisplayMode

    var body: some View {
        Picker(selection: $selection) {
            ForEach(ExpenseDisplayMode.allCases) { mode in
                Label(mode.title, systemImage: mode.icon)
                    .tag(mode)
            }
        } label: {
            Text(L10n.Expenses.displayModeAccessibility)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(L10n.Expenses.displayModeAccessibility)
    }
}

struct ExpenseListSummaryCard: View {
    let total: String
    let count: Int
    let average: String
    let period: String
    let hasFilters: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle.fill" : "creditcard.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        LinearGradient(
                            colors: hasFilters ? [.orange, .pink] : [.blue, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(hasFilters ? L10n.Expenses.filteredSpend : L10n.Expenses.expenseActivity)
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(total)
                        .font(AppDesignSystem.Typography.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(period)
                        .font(AppDesignSystem.Typography.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("\(count)")
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppDesignSystem.Colors.controlFill, in: Capsule())
            }

            HStack(spacing: 10) {
                SummaryMetricPill(title: L10n.Expenses.average, value: average, icon: "chart.line.uptrend.xyaxis")
                SummaryMetricPill(title: L10n.Expenses.entries, value: L10n.format(L10n.Expenses.itemCount, count), icon: "list.bullet.rectangle")
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppDesignSystem.Colors.cardFill)

                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.cardOverlay,
                        Color.blue.opacity(0.08),
                        Color.teal.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesignSystem.Colors.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 7)
    }
}

private struct SummaryMetricPill: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .fintraxControlFill(cornerRadius: 14)
    }
}
