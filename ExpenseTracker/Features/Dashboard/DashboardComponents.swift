//
//  DashboardComponents.swift
//  Fintrax
//
//  Fintrax documentation: Extracted reusable dashboard presentation components.
//

import SwiftUI
import Foundation

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(expense.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatCurrency(expense.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.thinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.1))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            Color.red.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.3))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .scaleEffect(1.0)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0.00"
    }
}

struct DashboardHeroCard: View {
    let period: LocalizedStringKey
    let spending: String
    let netFlow: String
    let transactionCount: Int
    let isPositiveFlow: Bool

    @State private var hasAppeared = false
    @State private var glowPulse = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))

                        Text(period)
                            .font(AppDesignSystem.Typography.caption.weight(.bold))
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(.white.opacity(0.78))

                    Text(L10n.Dashboard.moneySnapshot)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(L10n.Dashboard.currentMonthOverview)
                        .font(AppDesignSystem.Typography.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 48, height: 48)

                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, value: glowPulse)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                Text(L10n.Dashboard.totalSpent)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .textCase(.uppercase)

                Text(spending)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
                    .contentTransition(.numericText())
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                DashboardHeroMiniStat(
                    title: L10n.Dashboard.entries,
                    value: "\(transactionCount)",
                    icon: "list.bullet.rectangle.fill",
                    revealDelay: 0.08
                )

                DashboardHeroMiniStat(
                    title: L10n.Dashboard.netBalance,
                    value: netFlow,
                    icon: isPositiveFlow ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill",
                    tint: isPositiveFlow ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.warning,
                    revealDelay: 0.16
                )
            }

            HStack(spacing: 9) {
                Image(systemName: isPositiveFlow ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))

                Text(isPositiveFlow ? L10n.Dashboard.incomeHigher : L10n.Dashboard.spendingHigher)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primaryDark,
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.info.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 142, weight: .bold))
                    .foregroundStyle(.white.opacity(0.055))
                    .rotationEffect(.degrees(glowPulse ? -4 : 2))
                    .offset(x: glowPulse ? 80 : 88, y: glowPulse ? 22 : 30)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 160, height: 160)
                    .scaleEffect(glowPulse ? 1.08 : 0.96)
                    .offset(x: -112, y: 126)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: AppDesignSystem.Colors.primary.opacity(glowPulse ? 0.28 : 0.18), radius: glowPulse ? 30 : 22, x: 0, y: 14)
        .scaleEffect(isPressed ? 0.985 : 1)
        .offset(y: hasAppeared ? 0 : 10)
        .opacity(hasAppeared ? 1 : 0)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) {
                hasAppeared = true
            }

            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

private struct DashboardHeroMiniStat: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    var tint: Color = .white
    var revealDelay: Double = 0

    @State private var hasAppeared = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint == .white ? .white : tint)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .textCase(.uppercase)

                Text(value)
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        }
        .offset(y: hasAppeared ? 0 : 8)
        .opacity(hasAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.84).delay(revealDelay)) {
                hasAppeared = true
            }
        }
    }
}

struct DashboardInsightStrip: View {
    let topCategory: (Category, Decimal)?
    let averageTransaction: String
    let upcomingBills: Int
    let billTotal: String

    var body: some View {
        HStack(spacing: 10) {
            DashboardMiniInsight(
                icon: topCategory?.0.iconName ?? "tag.fill",
                title: L10n.Dashboard.top,
                value: topCategory?.0.name ?? L10n.string(L10n.Dashboard.none),
                tint: topCategory?.0.displayColor ?? AppDesignSystem.Colors.primary
            )

            DashboardMiniInsight(
                icon: "waveform.path.ecg.rectangle.fill",
                title: L10n.Dashboard.average,
                value: averageTransaction,
                tint: AppDesignSystem.Colors.info
            )

            DashboardMiniInsight(
                icon: upcomingBills > 0 ? "bell.badge.fill" : "bell.fill",
                title: upcomingBills > 0 ? LocalizedStringKey(L10n.format(L10n.Dashboard.due, upcomingBills)) : L10n.Dashboard.bills,
                value: upcomingBills > 0 ? billTotal : L10n.string(L10n.Dashboard.clear),
                tint: upcomingBills > 0 ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.success
            )
        }
    }
}

private struct DashboardMiniInsight: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .dashboardPanel(accent: tint, cornerRadius: 18)
    }
}

struct DashboardSectionHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(subtitle)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
    }
}

struct DashboardPulseCard: View {
    let spending: String
    let income: String
    let netFlow: String
    let transactionCount: Int
    let remainingBudget: String
    let budgetProgress: Double
    let isOverBudget: Bool
    let hasBudget: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                DashboardPulseMetric(
                    title: L10n.Dashboard.spent,
                    value: spending,
                    icon: "arrow.up.forward.circle.fill",
                    tint: AppDesignSystem.Colors.error
                )

                DashboardPulseMetric(
                    title: L10n.Dashboard.income,
                    value: income,
                    icon: "arrow.down.forward.circle.fill",
                    tint: AppDesignSystem.Colors.success
                )
            }

            HStack(spacing: 12) {
                DashboardPulseMetric(
                    title: L10n.Dashboard.netFlow,
                    value: netFlow,
                    icon: "equal.circle.fill",
                    tint: AppDesignSystem.Colors.info
                )

                DashboardPulseMetric(
                    title: L10n.Dashboard.entries,
                    value: "\(transactionCount)",
                    icon: "list.bullet.rectangle.fill",
                    tint: AppDesignSystem.Colors.primary
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(hasBudget ? L10n.Dashboard.monthlyBudget : L10n.Dashboard.budgetSetup, systemImage: hasBudget ? "target" : "plus.circle.fill")
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(remainingBudget)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(isOverBudget ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.textPrimary)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppDesignSystem.Colors.surfaceVariant.opacity(0.76))

                        Capsule()
                            .fill((isOverBudget ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).gradient)
                            .frame(width: max(8, proxy.size.width * budgetProgress))
                    }
                }
                .frame(height: 9)

                Text(hasBudget ? (isOverBudget ? L10n.Dashboard.spendingCrossedPlan : L10n.Dashboard.spendingWithinPlan) : L10n.Dashboard.setBudgetToTrack)
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }
            .padding(12)
            .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.56), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(14)
        .dashboardPanel(accent: AppDesignSystem.Colors.info)
    }
}

private struct DashboardPulseMetric: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
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

                Text(value)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

struct DashboardPriorityRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(subtitle)
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

struct DashboardMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let subtitle: LocalizedStringKey
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.title2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(accent.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: accent.opacity(0.28), radius: 8, x: 0, y: 5)
            }

            HStack {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(accent.opacity(0.10), in: Capsule())
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 7)
    }
}

struct DashboardTexturedBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                Image(systemName: "rectangle.grid.2x2.fill")
                    .font(.system(size: 78, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.primary.opacity(0.08))
                    .rotationEffect(.degrees(drift ? -9 : 7))
                    .offset(x: size.width * 0.62, y: drift ? 76 : 48)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.success.opacity(0.12))
                    .rotationEffect(.degrees(drift ? 9 : -7))
                    .offset(x: size.width * 0.06, y: size.height * 0.58)

                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 94, weight: .regular))
                    .foregroundStyle(AppDesignSystem.Colors.warning.opacity(0.12))
                    .rotationEffect(.degrees(drift ? 6 : -4))
                    .offset(x: size.width * 0.66, y: size.height * 0.74)

                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(AppDesignSystem.Colors.info.opacity(0.10))
                    .rotationEffect(.degrees(drift ? -8 : 5))
                    .offset(x: size.width * 0.08, y: drift ? size.height * 0.23 : size.height * 0.20)

                Circle()
                    .stroke(AppDesignSystem.Colors.info.opacity(0.14), lineWidth: 18)
                    .frame(width: 210, height: 210)
                    .offset(x: drift ? -62 : -84, y: 86)

                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(AppDesignSystem.Colors.primary.opacity(0.08), lineWidth: 14)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(drift ? 18 : 9))
                    .offset(x: size.width - 96, y: size.height * 0.18)

                Circle()
                    .stroke(AppDesignSystem.Colors.success.opacity(0.10), lineWidth: 12)
                    .frame(width: 154, height: 154)
                    .offset(x: size.width - 52, y: size.height * 0.52)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
        }
    }
}

extension View {
    func dashboardPanel(accent: Color, cornerRadius: CGFloat = 22) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)

                LinearGradient(
                    colors: [
                        accent.opacity(0.10),
                        Color.clear,
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: accent.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}
