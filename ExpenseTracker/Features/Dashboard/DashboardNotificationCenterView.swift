//
//  DashboardNotificationCenterView.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI

struct DashboardNotificationButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.92))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(AppDesignSystem.Colors.primary.opacity(0.16), lineWidth: 1))
                    .position(x: 20, y: 22)

                Image(systemName: "bell.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .position(x: 20, y: 22)

                if count > 0 {
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.system(size: count > 99 ? 7 : 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, count > 99 ? 3 : 4)
                        .frame(minWidth: count > 99 ? 20 : 15, minHeight: 15)
                        .background(AppDesignSystem.Colors.error, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.85), lineWidth: 1))
                        .position(x: 31, y: 12)
                }
            }
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count > 0 ? L10n.format(L10n.Dashboard.notificationCount, count) : L10n.string("dashboard.notifications.none"))
    }
}

struct DashboardNotificationCenterView: View {
    @Environment(\.dismiss) private var dismiss

    let bills: [BillReminder]
    let onMarkPaid: (BillReminder) async -> Void

    private var overdueCount: Int {
        bills.filter(\.isOverdue).count
    }

    var body: some View {
        ZStack {
            DashboardTexturedBackground()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header

                    if bills.isEmpty {
                        emptyState
                    } else {
                        summaryStrip
                        ForEach(bills) { bill in
                            NotificationBillRow(bill: bill) {
                                await onMarkPaid(bill)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(AppDesignSystem.Gradients.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.Dashboard.notificationsTitle)
                    .font(AppDesignSystem.Typography.title2)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text(L10n.Dashboard.notificationsSubtitle)
                    .font(AppDesignSystem.Typography.callout)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(AppDesignSystem.Colors.elevatedSurface, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            NotificationSummaryPill(
                icon: "exclamationmark.circle.fill",
                title: L10n.Dashboard.overdue,
                value: "\(overdueCount)",
                tint: AppDesignSystem.Colors.error
            )

            NotificationSummaryPill(
                icon: "calendar.badge.clock",
                title: L10n.Dashboard.dueSoon,
                value: "\(max(bills.count - overdueCount, 0))",
                tint: AppDesignSystem.Colors.warning
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(AppDesignSystem.Colors.success)

            Text(L10n.Dashboard.allCaughtUp)
                .font(AppDesignSystem.Typography.title3)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            Text(L10n.Dashboard.noRemindersNeedAttention)
                .font(AppDesignSystem.Typography.callout)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
        .padding(.horizontal, 20)
        .dashboardPanel(accent: AppDesignSystem.Colors.success)
    }
}

private struct NotificationSummaryPill: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Text(title)
                    .font(AppDesignSystem.Typography.caption.weight(.semibold))
            }
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct NotificationBillRow: View {
    let bill: BillReminder
    let onMarkPaid: () async -> Void

    @State private var isCompleting = false

    private var tint: Color {
        bill.isOverdue ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.warning
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: bill.isOverdue ? "exclamationmark.triangle.fill" : "bell.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(bill.title)
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 8)

                    Text(CurrencyFormatter.format(bill.amount))
                        .font(AppDesignSystem.Typography.footnote.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                }

                Text("\(bill.isOverdue ? Text(L10n.Dashboard.overdueStatus) : Text(L10n.Dashboard.dueSoonStatus)) • \(bill.dueDate.formatted(date: .abbreviated, time: .omitted)) • \(bill.formattedReminderTime)")
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if bill.repeatsUntilPaid {
                    Label(L10n.Dashboard.repeatsUntilComplete, systemImage: "repeat")
                        .font(AppDesignSystem.Typography.caption.weight(.semibold))
                        .foregroundStyle(AppDesignSystem.Colors.primary)
                }

                Button {
                    Task {
                        isCompleting = true
                        await onMarkPaid()
                        isCompleting = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCompleting ? "hourglass" : "checkmark.circle.fill")
                        Text(isCompleting ? L10n.Dashboard.completing : L10n.Dashboard.markComplete)
                    }
                    .font(AppDesignSystem.Typography.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(AppDesignSystem.Colors.success, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isCompleting)
            }
        }
        .padding(16)
        .dashboardPanel(accent: tint)
    }
}
