//
//  ExportService.swift
//  Fintrax
//
//  Facade for user-facing export flows.
//

import Foundation

struct ExportService: Sendable {
    private let csvExporter = ExpenseCSVExporter()
    private let pdfRenderer = FinancialPDFReportRenderer()

    @MainActor
    func exportExpensesToCSV(
        _ expenses: [Expense],
        dateRange: DateRangeOption? = nil,
        categories: [Category] = []
    ) async throws -> URL {
        try csvExporter.exportExpensesToCSV(expenses, dateRange: dateRange, categories: categories)
    }

    func createCSVData(
        from expenses: [Expense],
        categories: [Category] = [],
        includeHeader: Bool = true
    ) throws -> Data {
        try csvExporter.createCSVData(from: expenses, categories: categories, includeHeader: includeHeader)
    }

    func validateExportParameters(_ expenses: [Expense], dateRange: DateRangeOption?) -> ValidationResult {
        csvExporter.validateExportParameters(expenses, dateRange: dateRange)
    }

    func generateExportPreview(
        _ expenses: [Expense],
        categories: [Category] = [],
        dateRange: DateRangeOption? = nil
    ) throws -> String {
        try csvExporter.generateExportPreview(expenses, categories: categories, dateRange: dateRange)
    }

    func getShareableURL(for fileURL: URL) -> URL {
        csvExporter.getShareableURL(for: fileURL)
    }

    @MainActor
    func exportFinancialReportPDF(
        expenses: [Expense],
        categories: [Category],
        incomes: [IncomeRecord],
        bills: [BillReminder],
        dateRange: DateRangeOption = .thisMonth,
        categoryFilterID: UUID? = nil
    ) throws -> URL {
        try pdfRenderer.exportFinancialReportPDF(
            expenses: expenses,
            categories: categories,
            incomes: incomes,
            bills: bills,
            dateRange: dateRange,
            categoryFilterID: categoryFilterID
        )
    }
}
