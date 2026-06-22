//
//  PDFReportView.swift
//  Fintrax
//

import SwiftUI
import UIKit
import PDFKit

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
    @State private var messageIsSuccess = false

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
                    Text(range.localizedKey).tag(range)
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

                Text(selectedCategoryID.flatMap(categoryName(for:)).map { L10n.format("finance.report.scopeCategory", $0) } ?? L10n.string("Exports will include all expenses for the selected period."))
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
                    Text(LocalizedStringKey(isExporting ? "Creating Report..." : "Create PDF Report"))
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
                    Text(LocalizedStringKey(isExporting ? "Creating Export..." : "Create CSV Export"))
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
                    .foregroundStyle(messageIsSuccess ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
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
            messageIsSuccess = false
        }
        .onChange(of: selectedCategoryID) { _, _ in
            reportURL = nil
            csvURL = nil
            previewItem = nil
            message = nil
            messageIsSuccess = false
        }
    }

    @MainActor
    private func loadCategories() async {
        do {
            categories = try await repository.loadCategories()
        } catch {
            message = error.localizedDescription
            messageIsSuccess = false
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
            message = selectedCategoryID.flatMap(categoryName(for:)).map { L10n.format("finance.report.pdfCategoryReady", $0) } ?? L10n.string("PDF report ready to preview.")
            messageIsSuccess = true
        } catch {
            message = error.localizedDescription
            messageIsSuccess = false
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
            message = selectedCategoryID.flatMap(categoryName(for:)).map { L10n.format("finance.report.csvCategoryReady", $0) } ?? L10n.string("CSV export ready to share.")
            messageIsSuccess = true
        } catch {
            message = error.localizedDescription
            messageIsSuccess = false
        }
    }
}

struct PDFPreviewItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct PDFReportPreviewSheet: View {
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

struct PDFKitPreview: UIViewRepresentable {
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
