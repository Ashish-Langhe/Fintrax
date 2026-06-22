//
//  ExpenseCSVExporter.swift
//  Fintrax
//
//  CSV export and preview generation for expenses.
//

import Foundation

struct ExpenseCSVExporter: Sendable {
    private var reportLanguage: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue) ?? .system
    }

    private var reportLocale: Locale {
        reportLanguage.locale
    }

    private func reportText(_ key: String) -> String {
        L10n.string(key, language: reportLanguage)
    }

    @MainActor
    func exportExpensesToCSV(
        _ expenses: [Expense],
        dateRange: DateRangeOption? = nil,
        categories: [Category] = []
    ) throws -> URL {
        let filteredExpenses = dateRange?.filterExpenses(expenses) ?? expenses

        guard !filteredExpenses.isEmpty else {
            throw ExportError.emptyDataSet
        }

        let csvData = try createCSVData(from: filteredExpenses, categories: categories)
        let documentsPath = ConfigurationService.shared.documentsDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileURL = documentsPath.appendingPathComponent("expense_export_\(timestamp).csv")

        try csvData.write(to: fileURL)
        return fileURL
    }

    func createCSVData(
        from expenses: [Expense],
        categories: [Category] = [],
        includeHeader: Bool = true
    ) throws -> Data {
        var csvRows: [String] = []

        if includeHeader {
            let headers = [
                reportText("report.csv.date"),
                reportText("report.csv.title"),
                reportText("report.csv.amount"),
                reportText("report.csv.category"),
                reportText("report.csv.note")
            ].map(escapeCSVValue)
            csvRows.append(headers.joined(separator: ","))
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = reportLocale

        for expense in expenses {
            let category = categories.first { $0.id == expense.categoryID }
            let categoryName = category?.name ?? reportText("report.common.unknown")
            let row = [
                formatter.string(from: expense.date),
                expense.title,
                expense.formattedAmount(),
                categoryName,
                expense.note ?? ""
            ].map(escapeCSVValue)

            csvRows.append(row.joined(separator: ","))
        }

        guard let data = csvRows.joined(separator: "\n").data(using: .utf8) else {
            throw ExportError.formatError("Failed to convert CSV string to data")
        }

        return data
    }

    func validateExportParameters(_ expenses: [Expense], dateRange: DateRangeOption?) -> ValidationResult {
        guard !expenses.isEmpty else {
            return ValidationResult(isValid: false, error: "No expenses to export")
        }

        if let dateRange {
            let filteredExpenses = dateRange.filterExpenses(expenses)
            guard !filteredExpenses.isEmpty else {
                return ValidationResult(isValid: false, error: "No expenses found in selected date range")
            }
        }

        return ValidationResult(isValid: true)
    }

    func generateExportPreview(
        _ expenses: [Expense],
        categories: [Category] = [],
        dateRange: DateRangeOption? = nil
    ) throws -> String {
        let filteredExpenses = dateRange?.filterExpenses(expenses) ?? expenses
        let previewExpenses = Array(filteredExpenses.prefix(5))

        guard !previewExpenses.isEmpty else {
            return L10n.string("No expenses to export")
        }

        let previewData = try createCSVData(from: previewExpenses, categories: categories)
        return String(data: previewData, encoding: .utf8) ?? L10n.string("Failed to generate preview")
    }

    func getShareableURL(for fileURL: URL) -> URL {
        fileURL
    }

    private func escapeCSVValue(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }

        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedValue)\""
    }
}
