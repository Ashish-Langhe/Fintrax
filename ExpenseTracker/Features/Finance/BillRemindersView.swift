//
//  BillRemindersView.swift
//  Fintrax
//

import SwiftUI

struct BillRemindersView: View {
    private let repository = FinanceDataRepository.shared

    @State private var bills: [BillReminder] = []
    @State private var showingForm = false
    @State private var editingBill: BillReminder?
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    private var unpaidBills: [BillReminder] {
        bills.filter { !$0.isPaid }
    }

    private var repeatingBills: [BillReminder] {
        unpaidBills.filter { $0.reminderEnabled && $0.repeatsUntilPaid }
    }

    private var attentionBills: [BillReminder] {
        unpaidBills.filter(\.requiresAttention)
    }

    var body: some View {
        FinanceScreen(title: "Payment Reminders", subtitle: "Schedule payment alerts with sound, badge, and repeat-until-complete options.", icon: "bell.badge.fill", tint: AppDesignSystem.Colors.warning) {
            billOverviewCard

            if bills.isEmpty {
                FinanceEmptyState(icon: "bell.fill", title: "No bill reminders", subtitle: "Add rent, EMI, subscriptions, and utility bills.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(bills) { bill in
                        HStack(spacing: 10) {
                            FinanceListRow(
                                icon: bill.isPaid ? "checkmark.circle.fill" : (bill.isOverdue ? "exclamationmark.circle.fill" : "bell.circle.fill"),
                                title: bill.title,
                                subtitle: billSubtitle(for: bill),
                                value: CurrencyFormatter.format(bill.amount),
                                tint: bill.isPaid ? AppDesignSystem.Colors.success : (bill.isOverdue ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.warning)
                            )
                            .onTapGesture {
                                editingBill = bill
                            }

                            VStack(spacing: 8) {
                                Button {
                                    togglePaid(bill)
                                } label: {
                                    Image(systemName: bill.isPaid ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(AppDesignSystem.Colors.success)
                                        .frame(width: 40, height: 40)
                                        .background(AppDesignSystem.Colors.success.opacity(0.12), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(bill.isPaid ? "Mark unpaid" : "Mark paid")

                                Button(role: .destructive) {
                                    deleteBill(bill)
                                } label: {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppDesignSystem.Colors.error)
                                        .frame(width: 40, height: 40)
                                        .background(AppDesignSystem.Colors.error.opacity(0.12), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete \(bill.title)")
                            }
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.error)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.success)
            }
        }
        .toolbar {
            Button {
                showingForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .task { loadBills() }
        .sheet(isPresented: $showingForm) {
            BillEditorView(bill: nil) { bill in
                saveBill(bill)
            }
        }
        .sheet(item: $editingBill) { bill in
            BillEditorView(bill: bill) { updated in
                updateBill(updated)
            }
        }
    }

    private var billOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(AppDesignSystem.Gradients.warning, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unpaid Bills")
                        .font(AppDesignSystem.Typography.callout)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    Text(CurrencyFormatter.format(unpaidBills.unpaidTotal))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                }

                Spacer()
            }

            Text("Use Sound + Vibration for stronger payment alerts. iOS controls the final vibration and ringtone behavior from device Notification settings.")
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                FinanceMetricChip(title: "Open", value: "\(unpaidBills.count)", tint: AppDesignSystem.Colors.warning)
                FinanceMetricChip(title: "Attention", value: "\(attentionBills.count)", tint: AppDesignSystem.Colors.error)
                FinanceMetricChip(title: "Repeating", value: "\(repeatingBills.count)", tint: AppDesignSystem.Colors.primary)
            }

            Button {
                Task { await sendTestReminder() }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Send Test Alert")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .font(AppDesignSystem.Typography.footnote.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppDesignSystem.Gradients.warning, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.warning.opacity(0.16),
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.9),
                    AppDesignSystem.Colors.primary.opacity(0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppDesignSystem.Colors.warning.opacity(0.18), lineWidth: 1)
        }
    }

    private func billSubtitle(for bill: BillReminder) -> String {
        var parts = [
            bill.dueDate.formatted(date: .abbreviated, time: .omitted),
            bill.reminderEnabled ? L10n.format("finance.bill.reminderTime", bill.formattedReminderTime) : L10n.string("Reminder off")
        ]

        if bill.reminderEnabled && bill.repeatsUntilPaid && !bill.isPaid {
            parts.append(L10n.string("Repeats until complete"))
        }

        if bill.reminderEnabled {
            parts.append(L10n.string(bill.alertStyle.title))
        }

        return parts.joined(separator: " • ")
    }

    @MainActor
    private func loadBills() {
        do {
            bills = try repository.loadBillReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func saveBill(_ bill: BillReminder) {
        do {
            try repository.saveBillReminder(bill)
            statusMessage = L10n.string("Payment reminder saved.")
            loadBills()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func updateBill(_ bill: BillReminder) {
        do {
            try repository.updateBillReminder(bill)
            statusMessage = L10n.string("Payment reminder updated.")
            loadBills()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func togglePaid(_ bill: BillReminder) {
        var updated = bill
        updated.isPaid.toggle()
        updated.updatedAt = Date()
        updateBill(updated)
    }

    @MainActor
    private func deleteBill(_ bill: BillReminder) {
        do {
            try repository.deleteBillReminder(id: bill.id)
            statusMessage = L10n.string("Payment reminder deleted.")
            loadBills()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func sendTestReminder() async {
        let scheduled = await BillNotificationScheduler.scheduleTestReminder()
        statusMessage = scheduled ? L10n.string("Test alert scheduled. It should arrive in about 5 seconds.") : nil
        errorMessage = scheduled ? nil : L10n.string("Notification permission is disabled for Fintrax.")
    }
}
