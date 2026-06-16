//
//  FinanceFeatureViews.swift
//  Fintrax
//
//  Fintrax documentation: Builds income tracking, bill reminders, PDF export, and finance utility flows.
//

import SwiftUI
import UIKit
import PDFKit

struct IncomeTrackingView: View {
    private let repository = FinanceDataRepository.shared

    @State private var incomes: [IncomeRecord] = []
    @State private var showingForm = false
    @State private var editingIncome: IncomeRecord?
    @State private var errorMessage: String?

    private var totalIncome: Decimal {
        DateRangeOption.thisMonth.filterIncome(incomes).totalIncome
    }

    var body: some View {
        FinanceScreen(title: "Income", subtitle: "Track salary, freelance, refunds, and other cash inflows.", icon: "arrow.down.circle.fill", tint: AppDesignSystem.Colors.success) {
            summaryCard

            if incomes.isEmpty {
                FinanceEmptyState(icon: "banknote.fill", title: "No income yet", subtitle: "Add income to understand your monthly cash flow.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(incomes) { income in
                        HStack(spacing: 10) {
                            FinanceListRow(
                                icon: "arrow.down.left.circle.fill",
                                title: income.title,
                                subtitle: "\(income.source) • \(income.date.formatted(date: .abbreviated, time: .omitted))",
                                value: CurrencyFormatter.format(income.amount),
                                tint: AppDesignSystem.Colors.success
                            )
                            .onTapGesture {
                                editingIncome = income
                            }

                            Button(role: .destructive) {
                                deleteIncome(income)
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppDesignSystem.Colors.error)
                                    .frame(width: 42, height: 42)
                                    .background(AppDesignSystem.Colors.error.opacity(0.12), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete \(income.title)")
                        }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                    .foregroundStyle(AppDesignSystem.Colors.error)
            }
        }
        .toolbar {
            Button {
                showingForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .task { loadIncomes() }
        .sheet(isPresented: $showingForm) {
            IncomeEditorView(income: nil) { income in
                saveIncome(income)
            }
        }
        .sheet(item: $editingIncome) { income in
            IncomeEditorView(income: income) { updated in
                updateIncome(updated)
            }
        }
    }

    private var summaryCard: some View {
        FinanceSummaryCard(
            title: "This Month Income",
            value: CurrencyFormatter.format(totalIncome),
            subtitle: "\(DateRangeOption.thisMonth.filterIncome(incomes).count) income entries",
            icon: "chart.line.uptrend.xyaxis",
            tint: AppDesignSystem.Colors.success
        )
    }

    @MainActor
    private func loadIncomes() {
        do {
            incomes = try repository.loadIncomeRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func saveIncome(_ income: IncomeRecord) {
        do {
            try repository.saveIncomeRecord(income)
            loadIncomes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func updateIncome(_ income: IncomeRecord) {
        do {
            try repository.updateIncomeRecord(income)
            loadIncomes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteIncome(_ income: IncomeRecord) {
        do {
            try repository.deleteIncomeRecord(id: income.id)
            loadIncomes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

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
            bill.reminderEnabled ? "Reminder \(bill.formattedReminderTime)" : "Reminder off"
        ]

        if bill.reminderEnabled && bill.repeatsUntilPaid && !bill.isPaid {
            parts.append("Repeats until complete")
        }

        if bill.reminderEnabled {
            parts.append(bill.alertStyle.title)
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
            statusMessage = "Payment reminder saved."
            loadBills()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func updateBill(_ bill: BillReminder) {
        do {
            try repository.updateBillReminder(bill)
            statusMessage = "Payment reminder updated."
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
            statusMessage = "Payment reminder deleted."
            loadBills()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func sendTestReminder() async {
        let scheduled = await BillNotificationScheduler.scheduleTestReminder()
        statusMessage = scheduled ? "Test alert scheduled. It should arrive in about 5 seconds." : nil
        errorMessage = scheduled ? nil : "Notification permission is disabled for Fintrax."
    }
}

struct PDFReportView: View {
    private let repository = FinanceDataRepository.shared

    @State private var selectedRange: DateRangeOption = .thisMonth
    @State private var selectedCategoryID: UUID?
    @State private var categories: [Category] = []
    @State private var reportURL: URL?
    @State private var csvURL: URL?
    @State private var previewItem: PDFPreviewItem?
    @State private var isExporting = false
    @State private var message: String?

    var body: some View {
        FinanceScreen(title: "Export Reports", subtitle: "Create PDF summaries or CSV files for monthly review, sharing, and analysis.", icon: "doc.richtext.fill", tint: AppDesignSystem.Colors.info) {
            FinanceSummaryCard(
                title: "Report Center",
                value: "PDF + CSV",
                subtitle: "Includes totals, income, categories, trends, and transactions",
                icon: "chart.bar.doc.horizontal.fill",
                tint: AppDesignSystem.Colors.info
            )

            Picker("Date range", selection: $selectedRange) {
                ForEach(DateRangeOption.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Label("Report Scope", systemImage: "line.3.horizontal.decrease.circle.fill")
                    .font(AppDesignSystem.Typography.footnote.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)

                Picker("Report Scope", selection: $selectedCategoryID) {
                    Text("All Data").tag(UUID?.none)
                    ForEach(categories) { category in
                        Label(category.name, systemImage: category.iconName)
                            .tag(Optional(category.id))
                    }
                }
                .pickerStyle(.menu)

                Text(selectedCategoryID.flatMap(categoryName(for:)).map { "Exports will include only \($0) expenses for the selected period." } ?? "Exports will include all expenses for the selected period.")
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                Task { await exportPDF() }
            } label: {
                HStack {
                    Image(systemName: isExporting ? "hourglass" : "doc.badge.plus")
                    Text(isExporting ? "Creating Report..." : "Create PDF Report")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(.white)
                .padding()
                .background(AppDesignSystem.Gradients.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isExporting)

            Button {
                Task { await exportCSV() }
            } label: {
                HStack {
                    Image(systemName: isExporting ? "hourglass" : "tablecells.fill")
                    Text(isExporting ? "Creating Export..." : "Create CSV Export")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .padding()
                .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppDesignSystem.Colors.primary.opacity(0.14), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isExporting)

            if let reportURL {
                Button {
                    previewItem = PDFPreviewItem(url: reportURL)
                } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Preview Latest Report")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.primary)
                    .padding()
                    .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if let csvURL {
                ShareLink(item: csvURL) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share Latest CSV")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.success)
                    .padding()
                    .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if let message {
                Text(message)
                    .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                    .foregroundStyle(message.contains("created") ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
            }
        }
        .task {
            await loadCategories()
        }
        .sheet(item: $previewItem) { item in
            PDFReportPreviewSheet(item: item)
        }
        .onChange(of: selectedRange) { _, _ in
            reportURL = nil
            csvURL = nil
            previewItem = nil
            message = nil
        }
        .onChange(of: selectedCategoryID) { _, _ in
            reportURL = nil
            csvURL = nil
            previewItem = nil
            message = nil
        }
    }

    @MainActor
    private func loadCategories() async {
        do {
            categories = try await repository.loadCategories()
        } catch {
            message = error.localizedDescription
        }
    }

    private func categoryName(for id: UUID) -> String? {
        categories.first { $0.id == id }?.name
    }

    @MainActor
    private func exportPDF() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let snapshot = try await repository.loadReportSnapshot()
            let url = try ExportService().exportFinancialReportPDF(
                expenses: snapshot.expenses,
                categories: snapshot.categories,
                incomes: snapshot.incomes,
                bills: snapshot.bills,
                dateRange: selectedRange,
                categoryFilterID: selectedCategoryID
            )
            reportURL = url
            previewItem = PDFPreviewItem(url: url)
            message = selectedCategoryID.flatMap(categoryName(for:)).map { "\($0) PDF report ready to preview." } ?? "PDF report ready to preview."
        } catch {
            message = error.localizedDescription
        }
    }

    @MainActor
    private func exportCSV() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let snapshot = try await repository.loadReportSnapshot()
            let scopedExpenses = selectedCategoryID.map { id in
                snapshot.expenses.filter { $0.categoryID == id }
            } ?? snapshot.expenses
            let url = try await ExportService().exportExpensesToCSV(
                scopedExpenses,
                dateRange: selectedRange,
                categories: snapshot.categories
            )
            csvURL = url
            message = selectedCategoryID.flatMap(categoryName(for:)).map { "\($0) CSV export ready to share." } ?? "CSV export ready to share."
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct PDFPreviewItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct PDFReportPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: PDFPreviewItem

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 14) {
                    PDFKitPreview(url: item.url)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                        }
                        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)

                    ShareLink(item: item.url) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Share Report")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(.white)
                        .padding()
                        .background(AppDesignSystem.Gradients.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Preview Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PDFKitPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}

private struct IncomeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var source: String
    @State private var date: Date
    @State private var note: String

    let income: IncomeRecord?
    let onSave: (IncomeRecord) -> Void

    init(income: IncomeRecord?, onSave: @escaping (IncomeRecord) -> Void) {
        self.income = income
        self.onSave = onSave
        _title = State(initialValue: income?.title ?? "")
        _amount = State(initialValue: income.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? "")
        _source = State(initialValue: income?.source ?? "Salary")
        _date = State(initialValue: income?.date ?? Date())
        _note = State(initialValue: income?.note ?? "")
    }

    var body: some View {
        FinanceEditorShell(title: income == nil ? "Add Income" : "Update Income") {
            FinanceTextField(title: "Title", text: $title, placeholder: "Salary, Freelance, Refund")
            FinanceTextField(title: "Amount", text: $amount, placeholder: "50000", keyboardType: .decimalPad)
            FinanceTextField(title: "Source", text: $source, placeholder: "Salary")
            DatePicker("Date", selection: $date, displayedComponents: .date)
            FinanceTextField(title: "Note", text: $note, placeholder: "Optional")
        } saveAction: {
            let parsedAmount = Decimal(string: amount) ?? .zero
            var record = IncomeRecord(
                id: income?.id ?? UUID(),
                title: title,
                amount: parsedAmount,
                date: date,
                source: source,
                note: note.isEmpty ? nil : note
            )
            record.createdAt = income?.createdAt ?? Date()
            record.updatedAt = Date()
            onSave(record)
            dismiss()
        }
    }
}

private struct BillEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var dueDate: Date
    @State private var note: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var repeatsUntilPaid: Bool
    @State private var alertStyle: BillReminder.AlertStyle

    let bill: BillReminder?
    let onSave: (BillReminder) -> Void

    init(bill: BillReminder?, onSave: @escaping (BillReminder) -> Void) {
        self.bill = bill
        self.onSave = onSave
        _title = State(initialValue: bill?.title ?? "")
        _amount = State(initialValue: bill.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? "")
        _dueDate = State(initialValue: bill?.dueDate ?? Date())
        _note = State(initialValue: bill?.note ?? "")
        _reminderEnabled = State(initialValue: bill?.reminderEnabled ?? true)
        _reminderTime = State(initialValue: bill?.reminderTime ?? BillReminder.defaultReminderTime())
        _repeatsUntilPaid = State(initialValue: bill?.repeatsUntilPaid ?? false)
        _alertStyle = State(initialValue: bill?.alertStyle ?? .soundAndVibration)
    }

    var body: some View {
        FinanceEditorShell(title: bill == nil ? "Add Bill" : "Update Bill") {
            FinanceTextField(title: "Title", text: $title, placeholder: "Rent, EMI, Internet")
            FinanceTextField(title: "Amount", text: $amount, placeholder: "2500", keyboardType: .decimalPad)
            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
            Toggle("Internal reminder", isOn: $reminderEnabled)
                .padding()
                .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if reminderEnabled {
                DatePicker("Notification Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .padding()
                    .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                FinanceReminderRepeatPanel(isOn: $repeatsUntilPaid)
                FinanceReminderAlertStylePanel(selection: $alertStyle)
            }

            FinanceTextField(title: "Note", text: $note, placeholder: "Optional")
        } saveAction: {
            let parsedAmount = Decimal(string: amount) ?? .zero
            var record = BillReminder(
                id: bill?.id ?? UUID(),
                title: title,
                amount: parsedAmount,
                dueDate: dueDate,
                note: note.isEmpty ? nil : note,
                isPaid: bill?.isPaid ?? false,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                repeatsUntilPaid: reminderEnabled && repeatsUntilPaid,
                alertStyle: reminderEnabled ? alertStyle : .silent
            )
            record.createdAt = bill?.createdAt ?? Date()
            record.updatedAt = Date()
            onSave(record)
            dismiss()
        }
    }
}

private struct FinanceMetricChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
            Text(title)
                .font(AppDesignSystem.Typography.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FinanceReminderRepeatPanel: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .frame(width: 44, height: 44)
                .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Toggle("Repeat until complete", isOn: $isOn)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .tint(AppDesignSystem.Colors.primary)

                Text("Fintrax will keep sending daily follow-ups after the due date until this bill is marked complete.")
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.primary.opacity(0.12),
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesignSystem.Colors.primary.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct FinanceReminderAlertStylePanel: View {
    @Binding var selection: BillReminder.AlertStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: selection.icon)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(AppDesignSystem.Colors.warning)
                    .frame(width: 44, height: 44)
                    .background(AppDesignSystem.Colors.warning.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Alert Style")
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text("Sound notifications can vibrate based on iPhone settings.")
                        .font(AppDesignSystem.Typography.footnote)
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Picker("Alert Style", selection: $selection) {
                ForEach(BillReminder.AlertStyle.allCases) { style in
                    Label(style.title, systemImage: style.icon)
                        .tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.warning.opacity(0.12),
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesignSystem.Colors.warning.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct FinanceScreen<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppDesignSystem.Gradients.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(tint)
                            .frame(width: 56, height: 56)
                            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.title2.weight(.bold))
                            Text(subtitle)
                                .font(AppDesignSystem.Typography.footnote)
                                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        }
                    }
                    .padding()
                    .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    content
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FinanceSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppDesignSystem.Typography.callout)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                Text(value)
                    .font(.title3.weight(.bold))
                Text(subtitle)
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct FinanceListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                Text(subtitle)
                    .font(AppDesignSystem.Typography.footnote)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(value)
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
        }
        .padding()
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct FinanceEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
            Text(title)
                .font(AppDesignSystem.Typography.headline)
            Text(subtitle)
                .font(AppDesignSystem.Typography.footnote)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(AppDesignSystem.Colors.elevatedSurface.opacity(0.8), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct FinanceEditorShell<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    let saveAction: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppDesignSystem.Gradients.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        content
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveAction)
                }
            }
        }
    }
}

private struct FinanceTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppDesignSystem.Typography.footnote.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(AppDesignSystem.Colors.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private extension DateRangeOption {
    func filterIncome(_ incomes: [IncomeRecord]) -> [IncomeRecord] {
        let range = getDateRange()
        return incomes.filter { $0.date >= range.start && $0.date <= range.end }
    }
}
