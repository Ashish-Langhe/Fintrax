//
//  DashboardCategoryBreakdownChart.swift
//  Fintrax
//

import SwiftUI
import Charts

struct CategoryBreakdownDonut: View {
    let breakdown: [(Category, Decimal)]
    let selectedCategory: Category?
    let selectedAmount: String
    let subtitle: String
    let totalAmount: Decimal
    @Binding var selectedAngle: Double?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.elevatedSurface.opacity(0.66),
                            AppDesignSystem.Colors.surfaceVariant.opacity(0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: AppDesignSystem.Colors.primary.opacity(0.10), radius: 18, x: 0, y: 12)

            Chart {
                ForEach(Array(breakdown.enumerated()), id: \.element.0.id) { _, item in
                    let category = item.0
                    let amount = item.1
                    let isSelected = selectedCategory == nil || selectedCategory?.id == category.id

                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue),
                        innerRadius: .ratio(0.60),
                        outerRadius: .ratio(selectedCategory?.id == category.id ? 0.98 : 0.92),
                        angularInset: 1.8
                    )
                    .foregroundStyle(category.displayColor.opacity(isSelected ? 0.96 : 0.34))
                }
            }
            .chartLegend(.hidden)
            .chartAngleSelection(value: $selectedAngle)
            .frame(height: 236)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            DonutCenterSummary(
                title: selectedCategory?.name ?? "Total",
                amount: selectedAmount,
                subtitle: subtitle,
                tint: selectedCategory?.displayColor ?? AppDesignSystem.Colors.primary
            )
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
    }
}

struct DonutCenterSummary: View {
    let title: String
    let amount: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .lineLimit(1)

            Text(amount)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(subtitle)
                .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 124, height: 104)
        .background(
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.16),
                                AppDesignSystem.Colors.elevatedSurface.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay {
            Circle()
                .stroke(tint.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: tint.opacity(0.16), radius: 14, x: 0, y: 8)
    }
}
