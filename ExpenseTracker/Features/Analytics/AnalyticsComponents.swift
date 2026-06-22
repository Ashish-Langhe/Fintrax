//
//  AnalyticsComponents.swift
//  Fintrax
//

import SwiftUI

struct AnalyticsCategoryTableRow: View {
        let rank: Int
        let category: Category
        let amount: String
        let share: Double

        private var shareText: String {
            String(format: "%.0f%%", share * 100)
        }

        var body: some View {
            VStack(spacing: 7) {
                HStack(spacing: 10) {
                    Text("\(rank)")
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(category.displayColor)
                        .frame(width: 22, height: 22)
                        .background(category.displayColor.opacity(0.12), in: Circle())

                    Image(systemName: category.iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(category.displayColor)
                        .frame(width: 24, height: 24)

                    Text(category.name)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(amount)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .frame(width: 86, alignment: .trailing)

                    Text(shareText)
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(category.displayColor)
                        .frame(width: 54, alignment: .trailing)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppDesignSystem.Colors.surfaceVariant.opacity(0.72))

                        Capsule()
                            .fill(category.displayColor.gradient)
                            .frame(width: proxy.size.width * min(max(share, 0), 1))
                    }
                }
                .frame(height: 4)
                .padding(.leading, 56)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(category.name), \(amount), \(shareText) of spending")
        }
    }

struct AnalyticsRecentTransactionRow: View {
        let expense: Expense
        let category: Category?
        let amount: String

        private var dateText: String {
            expense.date.formatted(.dateTime.day().month(.abbreviated))
        }

        private var iconName: String {
            category?.iconName ?? "creditcard.fill"
        }

        private var tint: Color {
            category?.displayColor ?? AppDesignSystem.Colors.info
        }

        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(expense.title)
                        .font(AppDesignSystem.Typography.caption.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(category?.name ?? L10n.string("Uncategorized"))
                        .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(dateText)
                    .font(AppDesignSystem.Typography.caption2.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .frame(width: 62, alignment: .trailing)

                Text(amount)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.error)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .frame(width: 84, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(expense.title), \(category?.name ?? L10n.string("Uncategorized")), \(dateText), \(amount)")
        }
    }

struct AnalyticsRangeChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(LocalizedStringKey(title))
            .font(AppDesignSystem.Typography.footnote.weight(.bold))
            .foregroundStyle(isSelected ? .white : AppDesignSystem.Colors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AppDesignSystem.Gradients.primary : LinearGradient(colors: [
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.70),
                        AppDesignSystem.Colors.surfaceVariant.opacity(0.44)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.34) : AppDesignSystem.Colors.primary.opacity(0.15), lineWidth: 1)
            }
            .shadow(color: isSelected ? AppDesignSystem.Colors.primary.opacity(0.22) : Color.black.opacity(0.05), radius: 8, x: 0, y: 5)
    }
}

struct AnalyticsStoryMetric: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

struct AnalyticsInsightChip: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.caption2.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(AppDesignSystem.Typography.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Text(LocalizedStringKey(detail))
                    .font(AppDesignSystem.Typography.caption2.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 172, alignment: .leading)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

struct AnalyticsStatTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(AppDesignSystem.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                Text(value)
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(LocalizedStringKey(subtitle))
                    .font(AppDesignSystem.Typography.caption2)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .analyticsPanel(accent: tint)
    }
}

struct AnimatedWalletSpendingIcon: View {
    @State private var coinLift = false
    @State private var pulse = false
    @State private var cardSlide = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppDesignSystem.Gradients.primary)
                .frame(width: 64, height: 64)
                .shadow(color: AppDesignSystem.Colors.primary.opacity(pulse ? 0.28 : 0.12), radius: pulse ? 16 : 8, x: 0, y: 8)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 34, height: 21)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.white.opacity(0.62), lineWidth: 1.4)
                )
                .offset(x: cardSlide ? 6 : 0, y: -6)

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .frame(width: 38, height: 28)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(AppDesignSystem.Colors.primary.opacity(0.88))
                    .frame(width: 15, height: 17)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.88))
                            .frame(width: 4, height: 4)
                    )
                    .offset(x: 4)
            }
            .offset(y: 7)

            Circle()
                .fill(AppDesignSystem.Colors.warning)
                .frame(width: 15, height: 15)
                .overlay(
                    Text("₹")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                )
                .offset(x: 18, y: coinLift ? -25 : -15)
                .opacity(coinLift ? 0.35 : 1)

            Circle()
                .stroke(Color.white.opacity(pulse ? 0.04 : 0.28), lineWidth: 1)
                .frame(width: pulse ? 58 : 44, height: pulse ? 58 : 44)
        }
        .frame(width: 68, height: 68)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                coinLift = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                cardSlide = true
            }
        }
    }
}

