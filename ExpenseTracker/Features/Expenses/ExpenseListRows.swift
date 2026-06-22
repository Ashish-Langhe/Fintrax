//
//  ExpenseListRows.swift
//  Fintrax
//
//  Fintrax documentation: Extracted reusable expense screen components.
//

import SwiftUI
import Foundation

struct ToolbarIconLabel: View {
    let systemImage: String
    let tint: Color
    var isAnimating = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(Color(.systemBackground).opacity(0.68), in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.30), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(isAnimating ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isAnimating)
    }
}

/// Empty expense state
struct EmptyExpenseState: View {
    let hasActiveFilters: Bool
    let onResetFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 98, height: 98)

                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "tray")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text(hasActiveFilters ? L10n.Expenses.noMatchingExpenses : L10n.Expenses.noExpensesYet)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hasActiveFilters ? L10n.Expenses.adjustFilters : L10n.Expenses.addFirstExpense)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if hasActiveFilters {
                Button {
                    onResetFilters()
                } label: {
                    Text(L10n.Expenses.resetFilters)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExpenseFeedHeader: View {
    let count: Int
    let period: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Expenses.transactions)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .textCase(.uppercase)

                Text(period)
                    .font(AppDesignSystem.Typography.caption2.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }

            Spacer()

            Text(L10n.format(L10n.Expenses.itemCount, count))
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppDesignSystem.Colors.primary.opacity(0.10), in: Capsule())
        }
        .padding(.horizontal, 2)
    }
}

/// Expense row
struct ExpenseRow: View {
    let expense: Expense
    let category: Category?
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(categoryColor.opacity(0.13))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: category?.iconName ?? "tag.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(categoryColor)
                }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(expense.title)
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(expense.formattedAmount())
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.error)
                        .lineLimit(1)
                        .minimumScaleFactor(0.64)
                        .frame(minWidth: 86, alignment: .trailing)
                }

                HStack(spacing: 6) {
                    if let category {
                        Text(category.name)
                            .foregroundStyle(categoryColor)

                        Text("•")
                            .foregroundStyle(AppDesignSystem.Colors.textTertiary)
                    }

                    Text(formattedDate)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }
                .font(AppDesignSystem.Typography.caption.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(AppDesignSystem.Typography.caption.weight(.medium))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(categoryColor.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.Expenses.deleteExpense, systemImage: "trash")
            }
        }
    }
    
    private var categoryColor: Color {
        if let category {
            return category.displayColor
        }

        // Generate a consistent color based on category ID
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .mint]
        let hash = abs(expense.categoryID.hashValue)
        let index = hash % colors.count
        return colors[index]
    }

    private var formattedDate: String {
        expense.date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct ExpenseTexturedBackground: View {
    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background

            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 18

                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.42, y: size.height))
                }

                context.stroke(path, with: .color(Color.primary.opacity(0.04)), lineWidth: 1)

                let dotColor = Color.primary.opacity(0.06)
                for row in stride(from: CGFloat(32), through: size.height, by: 76) {
                    for column in stride(from: CGFloat(18), through: size.width, by: 86) {
                        let rect = CGRect(x: column, y: row, width: 3, height: 3)
                        context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
