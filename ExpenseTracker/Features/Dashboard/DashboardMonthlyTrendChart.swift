//
//  DashboardMonthlyTrendChart.swift
//  Fintrax
//

import SwiftUI

struct RefinedMonthlyTrendChart: View {
    let trend: [(String, Decimal)]
    @Binding var selectedMonth: String?
    let maxValue: Double
    let reveal: Bool
    let formatCurrency: (Decimal) -> String
    let monthLabel: (String) -> String

    private var selectedData: (month: String, amount: Decimal)? {
        guard let selectedMonth else {
            return trend.last.map { ($0.0, $0.1) }
        }
        return trend.first { $0.0 == selectedMonth }.map { ($0.0, $0.1) }
    }

    private var trendPoints: [MonthlyTrendPoint] {
        trend.enumerated().map { index, item in
            let previousAmount = index > 0 ? trend[index - 1].1 : nil
            return MonthlyTrendPoint(
                month: item.0,
                amount: item.1,
                value: NSDecimalNumber(decimal: item.1).doubleValue * (reveal ? 1 : 0.02),
                previousAmount: previousAmount,
                tint: trendColor(current: item.1, previous: previousAmount),
                isSelected: selectedMonth == nil ? index == trend.indices.last : selectedMonth == item.0
            )
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Spend")
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)

                    Text(selectedData.map { formatCurrency($0.amount) } ?? formatCurrency(.zero))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)

                    Text(selectedData?.month ?? L10n.string("No month selected"))
                        .font(AppDesignSystem.Typography.caption)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: trendDirectionIcon)
                        .font(.caption.weight(.bold))

                    Text(latestDeltaLabel)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                }
                .foregroundStyle(trendDirectionColor)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(trendDirectionColor.opacity(0.12), in: Capsule())
            }

            MonthlyTrendPlot(
                points: trendPoints,
                maxValue: max(maxValue, 1),
                selectedMonth: $selectedMonth,
                formatCurrency: formatCurrency,
                monthLabel: monthLabel
            )
            .frame(height: 314)
            .animation(.spring(response: 0.55, dampingFraction: 0.86), value: reveal)
            .animation(.spring(response: 0.34, dampingFraction: 0.84), value: selectedMonth)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.thinMaterial)

                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.primary.opacity(0.12),
                        AppDesignSystem.Colors.info.opacity(0.08),
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: AppDesignSystem.Colors.primary.opacity(0.10), radius: 18, x: 0, y: 12)
    }

    private var latestDeltaLabel: String {
        guard trend.count >= 2 else { return "Flat" }
        return deltaLabel(current: trend[trend.count - 1].1, previous: trend[trend.count - 2].1)
    }

    private var trendDirectionIcon: String {
        guard trend.count >= 2 else { return "minus.circle.fill" }
        let latest = trend[trend.count - 1].1
        let previous = trend[trend.count - 2].1
        if latest > previous { return "arrow.up.right.circle.fill" }
        if latest < previous { return "arrow.down.right.circle.fill" }
        return "minus.circle.fill"
    }

    private var trendDirectionColor: Color {
        guard trend.count >= 2 else { return AppDesignSystem.Colors.info }
        let latest = trend[trend.count - 1].1
        let previous = trend[trend.count - 2].1
        if latest > previous { return AppDesignSystem.Colors.error }
        if latest < previous { return AppDesignSystem.Colors.success }
        return AppDesignSystem.Colors.info
    }

    private func trendColor(current: Decimal, previous: Decimal?) -> Color {
        guard let previous else { return AppDesignSystem.Colors.primary }
        if current > previous { return AppDesignSystem.Colors.error }
        if current < previous { return AppDesignSystem.Colors.success }
        return AppDesignSystem.Colors.info
    }

    private func deltaLabel(current: Decimal, previous: Decimal?) -> String {
        guard let previous, previous > 0 else { return "Base" }
        let change = ((current - previous) / previous) * 100
        let value = NSDecimalNumber(decimal: change).doubleValue
        if abs(value) < 1 { return "Flat" }
        return String(format: "%@%.0f%%", value > 0 ? "+" : "", value)
    }

    struct MonthlyTrendPoint: Identifiable {
        let month: String
        let amount: Decimal
        let value: Double
        let previousAmount: Decimal?
        let tint: Color
        let isSelected: Bool

        var id: String { month }
    }
}

struct TrendLineShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let firstPoint = points.first else { return }
            path.move(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }
}

struct TrendAreaShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let firstPoint = points.first, let lastPoint = points.last else { return }
            path.move(to: CGPoint(x: firstPoint.x, y: rect.maxY))
            path.addLine(to: firstPoint)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.addLine(to: CGPoint(x: lastPoint.x, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct MonthlyTrendPlot: View {
    let points: [RefinedMonthlyTrendChart.MonthlyTrendPoint]
    let maxValue: Double
    @Binding var selectedMonth: String?
    let formatCurrency: (Decimal) -> String
    let monthLabel: (String) -> String

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let plotRect = CGRect(
                    x: 54,
                    y: 44,
                    width: max(proxy.size.width - 68, 1),
                    height: max(proxy.size.height - 66, 1)
                )
                let chartPoints = positionedPoints(in: plotRect)

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.elevatedSurface.opacity(0.26),
                                    AppDesignSystem.Colors.primary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    gridLines(in: plotRect)
                    yAxisLabels(in: plotRect)

                    TrendAreaShape(points: chartPoints)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary.opacity(0.24),
                                    AppDesignSystem.Colors.info.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    TrendLineShape(points: chartPoints)
                        .stroke(
                            AppDesignSystem.Colors.primary,
                            style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)
                        )

                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        let position = chartPoints[safe: index] ?? .zero

                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                                selectedMonth = selectedMonth == point.month ? nil : point.month
                            }
                        } label: {
                            Circle()
                                .fill(point.isSelected ? point.tint : AppDesignSystem.Colors.elevatedSurface)
                                .frame(width: point.isSelected ? 13 : 9, height: point.isSelected ? 13 : 9)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white.opacity(point.isSelected ? 0.75 : 0.35), lineWidth: 1)
                                }
                                .shadow(color: point.tint.opacity(point.isSelected ? 0.26 : 0.08), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .position(position)
                        .accessibilityLabel(monthLabel(point.month))
                        .accessibilityValue(formatCurrency(point.amount))
                    }

                    if let selectedIndex = selectedPointIndex,
                       let selectedPoint = points[safe: selectedIndex],
                       let position = chartPoints[safe: selectedIndex] {
                        SelectedTrendMarker(
                            amount: formatCurrency(selectedPoint.amount),
                            delta: deltaLabel(for: selectedPoint),
                            tint: selectedPoint.tint
                        )
                        .position(x: min(max(position.x, 92), proxy.size.width - 54), y: max(position.y - 34, 24))

                        Rectangle()
                            .fill(selectedPoint.tint.opacity(0.22))
                            .frame(width: 1, height: plotRect.height)
                            .position(x: position.x, y: plotRect.midY)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            selectClosestMonth(to: value.location.x, in: plotRect)
                        }
                )
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                ForEach(points) { point in
                    Text(monthLabel(point.month))
                        .font(AppDesignSystem.Typography.caption2.weight(point.isSelected ? .bold : .semibold))
                        .foregroundStyle(point.isSelected ? point.tint : AppDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 6)

            MonthlyTrendKeyValues(
                average: formatCurrency(averageAmount),
                peak: peakPoint.map { formatCurrency($0.amount) } ?? formatCurrency(.zero),
                low: lowPoint.map { formatCurrency($0.amount) } ?? formatCurrency(.zero)
            )
        }
    }

    private var selectedPointIndex: Int? {
        guard let selectedMonth else { return points.indices.last }
        return points.firstIndex { $0.month == selectedMonth }
    }

    private var averageAmount: Decimal {
        guard !points.isEmpty else { return .zero }
        let total = points.reduce(Decimal.zero) { $0 + $1.amount }
        return total / Decimal(points.count)
    }

    private var peakPoint: RefinedMonthlyTrendChart.MonthlyTrendPoint? {
        points.max { $0.amount < $1.amount }
    }

    private var lowPoint: RefinedMonthlyTrendChart.MonthlyTrendPoint? {
        points.min { $0.amount < $1.amount }
    }

    private func positionedPoints(in rect: CGRect) -> [CGPoint] {
        guard !points.isEmpty else { return [] }

        return points.enumerated().map { index, point in
            let x: CGFloat
            if points.count == 1 {
                x = rect.midX
            } else {
                x = rect.minX + (CGFloat(index) / CGFloat(points.count - 1)) * rect.width
            }

            let ratio = maxValue > 0 ? min(max(point.value / maxValue, 0), 1) : 0
            let y = rect.maxY - CGFloat(ratio) * rect.height
            return CGPoint(x: x, y: y)
        }
    }

    private func gridLines(in rect: CGRect) -> some View {
        Path { path in
            for index in 0..<4 {
                let y = rect.minY + rect.height * CGFloat(index) / 3
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
        }
        .stroke(AppDesignSystem.Colors.outline.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
    }

    private func yAxisLabels(in rect: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            yAxisLabel(formatCurrency(Decimal(maxValue)), y: rect.minY - 8)
            yAxisLabel(formatCurrency(Decimal(maxValue / 2)), y: rect.midY - 8)
            yAxisLabel(formatCurrency(.zero), y: rect.maxY - 8)
        }
    }

    private func yAxisLabel(_ value: String, y: CGFloat) -> some View {
        Text(value)
            .font(AppDesignSystem.Typography.caption2)
            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .frame(width: 46, alignment: .trailing)
            .position(x: 25, y: y + 8)
    }

    private func deltaLabel(for point: RefinedMonthlyTrendChart.MonthlyTrendPoint) -> String {
        guard let previous = point.previousAmount, previous > 0 else { return "Base" }
        let change = ((point.amount - previous) / previous) * 100
        let value = NSDecimalNumber(decimal: change).doubleValue
        if abs(value) < 1 { return "Flat" }
        return String(format: "%@%.0f%%", value > 0 ? "+" : "", value)
    }

    private func selectClosestMonth(to xPosition: CGFloat, in rect: CGRect) {
        guard !points.isEmpty else { return }

        let clampedX = min(max(xPosition, rect.minX), rect.maxX)
        let ratio = rect.width > 0 ? (clampedX - rect.minX) / rect.width : 0
        let rawIndex = ratio * CGFloat(max(points.count - 1, 0))
        let index = min(max(Int(rawIndex.rounded()), 0), points.count - 1)
        selectedMonth = points[index].month
    }
}

struct SelectedTrendMarker: View {
    let amount: String
    let delta: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(amount)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            Text(delta)
                .font(AppDesignSystem.Typography.caption2.weight(.bold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: tint.opacity(0.14), radius: 9, x: 0, y: 5)
    }
}

struct MonthlyTrendKeyValues: View {
    let average: String
    let peak: String
    let low: String

    var body: some View {
        HStack(spacing: 8) {
            TrendKeyValue(title: "Avg", value: average, tint: AppDesignSystem.Colors.info)
            TrendKeyValue(title: "Peak", value: peak, tint: AppDesignSystem.Colors.error)
            TrendKeyValue(title: "Low", value: low, tint: AppDesignSystem.Colors.success)
        }
    }
}

struct TrendKeyValue: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)

                Text(value)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.34), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
