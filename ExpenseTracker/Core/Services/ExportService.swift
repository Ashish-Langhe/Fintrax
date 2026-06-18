//
//  ExportService.swift
//  Fintrax
//
//  Fintrax documentation: Implements reusable data, export, budget, category, and configuration services for the app.
//

import Foundation
import UIKit

/// Service for exporting expense data to CSV format
struct ExportService: Sendable {
    private var reportPrimaryText: UIColor {
        UIColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1.0)
    }

    private var reportSecondaryText: UIColor {
        UIColor(red: 0.36, green: 0.40, blue: 0.48, alpha: 1.0)
    }

    private var reportPanelFill: UIColor {
        UIColor(red: 0.96, green: 0.975, blue: 0.99, alpha: 1.0)
    }

    private var reportTrackFill: UIColor {
        UIColor(red: 0.87, green: 0.91, blue: 0.96, alpha: 1.0)
    }

    private var reportWatermark: UIColor {
        UIColor(red: 0.11, green: 0.31, blue: 0.72, alpha: 0.055)
    }

    private var reportLanguage: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue) ?? .system
    }

    private var reportLocale: Locale {
        reportLanguage.locale
    }

    private func reportText(_ key: String) -> String {
        L10n.string(key, language: reportLanguage)
    }
    
    /// Export expenses to CSV format
    /// - Parameters:
    ///   - expenses: Array of expenses to export
    ///   - dateRange: Optional date range filter for export
    /// - Returns: URL of exported file
    /// - Throws: ExportError if export fails
    @MainActor
    func exportExpensesToCSV(_ expenses: [Expense], dateRange: DateRangeOption? = nil, categories: [Category] = []) async throws -> URL {
        // Filter expenses by date range if provided
        let filteredExpenses = dateRange?.filterExpenses(expenses) ?? expenses
        
        // Check if there are expenses to export
        guard !filteredExpenses.isEmpty else {
            throw ExportError.emptyDataSet
        }
        
        // Create CSV data
        let csvData = try createCSVData(from: filteredExpenses, categories: categories)
        
        // Generate file URL
        let documentsPath = ConfigurationService.shared.documentsDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "expense_export_\(timestamp).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        // Write CSV data to file
        try csvData.write(to: fileURL)
        
        return fileURL
    }
    
    /// Create CSV data from expenses
    /// - Parameters:
    ///   - expenses: Array of expenses to convert
    ///   - categories: Array of categories for name lookup
    ///   - includeHeader: Whether to include CSV header row
    /// - Returns: CSV data as Data
    /// - Throws: ExportError if conversion fails
    func createCSVData(from expenses: [Expense], categories: [Category] = [], includeHeader: Bool = true) throws -> Data {
        var csvRows: [String] = []
        
        // Add header row
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
        
        // Add expense rows
        for expense in expenses {
            // Format date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = reportLocale
            let dateString = formatter.string(from: expense.date)
            
            // Format amount with INR symbol
            let amountString = expense.formattedAmount()
            
            // Get category name
            let category = categories.first { $0.id == expense.categoryID }
            let categoryName = category?.name ?? reportText("report.common.unknown")
            
            // Escape CSV fields (handle commas, quotes, newlines)
            let escapedTitle = escapeCSVValue(expense.title)
            let escapedNote = escapeCSVValue(expense.note ?? "")
            let escapedCategoryName = escapeCSVValue(categoryName)
            
            let row = "\(dateString),\(escapedTitle),\(amountString),\(escapedCategoryName),\(escapedNote)"
            csvRows.append(row)
        }
        
        // Join rows with newlines
        let csvString = csvRows.joined(separator: "\n")
        
        guard let data = csvString.data(using: .utf8) else {
            throw ExportError.formatError("Failed to convert CSV string to data")
        }
        
        return data
    }
    
    /// Escape CSV values to handle special characters
    /// - Parameter value: String value to escape
    /// - Returns: Escaped string
    private func escapeCSVValue(_ value: String) -> String {
        // If value contains comma, quote, or newline, wrap in quotes and escape internal quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedValue)\""
        } else {
            return value
        }
    }
    
    /// Validate CSV export parameters
    /// - Parameters:
    ///   - expenses: Array of expenses to validate
    ///   - dateRange: Optional date range to validate
    /// - Returns: Validation result
    func validateExportParameters(_ expenses: [Expense], dateRange: DateRangeOption?) -> ValidationResult {
        // Validate expenses array
        guard !expenses.isEmpty else {
            return ValidationResult(isValid: false, error: "No expenses to export")
        }
        
        // Filter by date range if provided and check if filtered expenses exist
        if let dateRange = dateRange {
            let filteredExpenses = dateRange.filterExpenses(expenses)
            guard !filteredExpenses.isEmpty else {
                return ValidationResult(isValid: false, error: "No expenses found in selected date range")
            }
        }
        
        return ValidationResult(isValid: true)
    }
    
    /// Generate preview of export (first 5 rows)
    /// - Parameters:
    ///   - expenses: Array of expenses to preview
    ///   - categories: Array of categories for name lookup
    ///   - dateRange: Optional date range filter
    /// - Returns: Preview string
    func generateExportPreview(_ expenses: [Expense], categories: [Category] = [], dateRange: DateRangeOption? = nil) throws -> String {
        let filteredExpenses = dateRange?.filterExpenses(expenses) ?? expenses
        let previewExpenses = Array(filteredExpenses.prefix(5))
        
        guard !previewExpenses.isEmpty else {
            return L10n.string("No expenses to export")
        }
        
        let previewData = try createCSVData(from: previewExpenses, categories: categories)
        return String(data: previewData, encoding: .utf8) ?? L10n.string("Failed to generate preview")
    }
    
    /// Get export file sharing URL
    /// - Parameter fileURL: Local file URL
    /// - Returns: URL that can be used for sharing
    func getShareableURL(for fileURL: URL) -> URL {
        // For iOS, we use the existing file URL
        // In a real app, you might move this to a temporary directory or use a share sheet
        return fileURL
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
        let categoryFilter = categoryFilterID.flatMap { id in
            categories.first { $0.id == id }
        }
        let scopedExpenses = categoryFilterID.map { id in
            expenses.filter { $0.categoryID == id }
        } ?? expenses
        let filteredExpenses = dateRange.filterExpenses(scopedExpenses)
        let filteredIncome = dateRange.filterIncome(incomes)
        let dashboard = DashboardData.generate(
            from: scopedExpenses,
            categories: categories,
            budgets: [],
            dateRange: dateRange
        )

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = reportLocale

        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        let scopeFileName = categoryFilter?.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-") ?? "All_Data"
        let fileName = "Fintrax_Report_\(scopeFileName)_\(timestampFormatter.string(from: Date())).pdf"
        let fileURL = ConfigurationService.shared.documentsDirectory.appendingPathComponent(fileName)

        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            drawPageBackground()
            drawWatermark()
            var y: CGFloat = 42

            drawTitle(categoryFilter.map { String(format: reportText("report.pdf.categoryTitle"), $0.name) } ?? reportText("report.pdf.financialTitle"), y: &y)
            drawVerifiedStamp()
            drawSubtitle("\(dateRange.localizedString) • \(categoryFilter?.name ?? reportText("report.pdf.allData")) • \(reportText("report.pdf.generated")) \(formatter.string(from: Date()))", y: &y)
            y += 18

            let totalIncome = filteredIncome.totalIncome
            let totalSpending = filteredExpenses.reduce(Decimal.zero) { $0 + $1.amount }
            let netCashFlow = totalIncome - totalSpending
            let unpaidBills = bills.filter { !$0.isPaid }

            drawReportSummaryCards(
                metrics: [
                    (reportText("report.pdf.income"), CurrencyFormatter.format(totalIncome), UIColor.systemGreen),
                    (reportText("report.pdf.spending"), CurrencyFormatter.format(totalSpending), UIColor.systemBlue),
                    (reportText("report.pdf.netFlow"), CurrencyFormatter.format(netCashFlow), netCashFlow >= 0 ? UIColor.systemGreen : UIColor.systemRed),
                    (reportText("report.pdf.unpaidBills"), CurrencyFormatter.format(unpaidBills.unpaidTotal), UIColor.systemOrange)
                ],
                y: &y
            )
            y += 20

            drawSection(reportText("report.pdf.analyticsGraphs"), y: &y)
            drawCategoryAnalyticsGraph(dashboard: dashboard, y: &y)
            y += 16

            if y > 610 {
                context.beginPage()
                drawPageBackground()
                drawWatermark()
                y = 42
            }

            drawMonthlyTrendGraph(dashboard.monthlyTrend, y: &y)
            y += 18

            drawSection(categoryFilter == nil ? reportText("report.pdf.topCategories") : String(format: reportText("report.pdf.selectedCategoryData"), categoryFilter?.name ?? reportText("report.pdf.selected")), y: &y)
            if dashboard.categoryBreakdown.isEmpty {
                drawBody(reportText("report.pdf.noExpensesPeriod"), y: &y)
            } else {
                for (category, amount) in dashboard.categoryBreakdown.prefix(6) {
                    drawMetric(category.name, CurrencyFormatter.format(amount), y: &y)
                }
            }

            y += 14
            drawSection(reportText("report.pdf.recentExpenses"), y: &y)
            if filteredExpenses.isEmpty {
                drawBody(reportText("report.pdf.noExpensesPeriod"), y: &y)
            } else {
                for expense in filteredExpenses.sorted(by: { $0.date > $1.date }).prefix(8) {
                    drawMetric("\(formatter.string(from: expense.date))  \(expense.title)", CurrencyFormatter.format(expense.amount), y: &y)
                }
            }

            if y > 650 {
                context.beginPage()
                drawPageBackground()
                drawWatermark()
                y = 42
            } else {
                y += 14
            }

            drawSection(reportText("report.pdf.upcomingBills"), y: &y)
            let upcomingBills = bills.filter { !$0.isPaid }.sorted { $0.dueDate < $1.dueDate }.prefix(8)
            if upcomingBills.isEmpty {
                drawBody(reportText("report.pdf.noUnpaidBills"), y: &y)
            } else {
                for bill in upcomingBills {
                    drawMetric("\(formatter.string(from: bill.dueDate))  \(bill.title)", CurrencyFormatter.format(bill.amount), y: &y)
                }
            }
        }

        return fileURL
    }

    private func drawReportSummaryCards(metrics: [(title: String, value: String, color: UIColor)], y: inout CGFloat) {
        let startX: CGFloat = 42
        let cardWidth: CGFloat = 124
        let cardHeight: CGFloat = 74
        let gap: CGFloat = 10

        for (index, metric) in metrics.enumerated() {
            let x = startX + CGFloat(index) * (cardWidth + gap)
            let rect = CGRect(x: x, y: y, width: cardWidth, height: cardHeight)
            drawRoundedRect(rect, fill: metric.color.withAlphaComponent(0.11), stroke: metric.color.withAlphaComponent(0.28), radius: 16)

            draw(metric.title, font: .systemFont(ofSize: 10, weight: .semibold), color: reportSecondaryText, frame: CGRect(x: x + 12, y: y + 12, width: cardWidth - 24, height: 16))
            draw(metric.value, font: .systemFont(ofSize: 15, weight: .bold), color: reportPrimaryText, frame: CGRect(x: x + 12, y: y + 34, width: cardWidth - 24, height: 24))
        }

        y += cardHeight + 2
    }

    private func drawVerifiedStamp() {
        let rect = CGRect(x: 416, y: 42, width: 154, height: 42)
        drawRoundedRect(rect, fill: UIColor.systemGreen.withAlphaComponent(0.10), stroke: UIColor.systemGreen.withAlphaComponent(0.36), radius: 16)

        let sealRect = CGRect(x: rect.minX + 10, y: rect.minY + 9, width: 24, height: 24)
        let sealPath = UIBezierPath(ovalIn: sealRect)
        UIColor.systemGreen.setFill()
        sealPath.fill()

        draw("✓", font: .systemFont(ofSize: 15, weight: .bold), color: .white, frame: CGRect(x: sealRect.minX, y: sealRect.minY + 1, width: sealRect.width, height: sealRect.height), alignment: .center)
        draw(reportText("report.pdf.verified"), font: .systemFont(ofSize: 11, weight: .bold), color: reportPrimaryText, frame: CGRect(x: rect.minX + 42, y: rect.minY + 8, width: 96, height: 15))
        draw(reportText("report.pdf.byFintrax"), font: .systemFont(ofSize: 9, weight: .semibold), color: reportSecondaryText, frame: CGRect(x: rect.minX + 42, y: rect.minY + 23, width: 96, height: 13))
    }

    private func drawPageBackground() {
        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: 612, height: 792)).fill()
    }

    private func drawWatermark() {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()
        context.translateBy(x: 306, y: 396)
        context.rotate(by: -.pi / 7)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 62, weight: .black),
            .foregroundColor: reportWatermark,
            .paragraphStyle: paragraph
        ]

        "FINTRAX".draw(
            in: CGRect(x: -220, y: -40, width: 440, height: 80),
            withAttributes: attributes
        )

        context.restoreGState()
    }

    private func drawCategoryAnalyticsGraph(dashboard: DashboardData, y: inout CGFloat) {
        let rect = CGRect(x: 42, y: y, width: 528, height: 190)
        drawRoundedRect(rect, fill: reportPanelFill, stroke: UIColor.systemBlue.withAlphaComponent(0.18), radius: 18)
        draw(reportText("report.pdf.categoryBreakdown"), font: .systemFont(ofSize: 14, weight: .bold), color: reportPrimaryText, frame: CGRect(x: rect.minX + 16, y: rect.minY + 14, width: 240, height: 20))

        guard !dashboard.categoryBreakdown.isEmpty, dashboard.totalSpending > 0 else {
            draw(reportText("report.pdf.noCategorySpending"), font: .systemFont(ofSize: 12), color: reportSecondaryText, frame: CGRect(x: rect.minX + 16, y: rect.minY + 50, width: rect.width - 32, height: 20))
            y += rect.height
            return
        }

        let rows = Array(dashboard.categoryBreakdown.prefix(5))
        let maxAmount = rows.map(\.1).max() ?? .zero
        let barStartX = rect.minX + 142
        let barMaxWidth: CGFloat = 290
        var rowY = rect.minY + 48

        for (index, item) in rows.enumerated() {
            let category = item.0
            let amount = item.1
            let color = reportColor(at: index)
            let amountRatio = maxAmount > 0 ? CGFloat(NSDecimalNumber(decimal: amount / maxAmount).doubleValue) : 0
            let percentage = dashboard.getCategorySpendingPercentage(for: category) * 100

            draw(category.name, font: .systemFont(ofSize: 11, weight: .medium), color: reportPrimaryText, frame: CGRect(x: rect.minX + 16, y: rowY - 1, width: 110, height: 16))

            let track = CGRect(x: barStartX, y: rowY, width: barMaxWidth, height: 12)
            drawRoundedRect(track, fill: reportTrackFill, stroke: .clear, radius: 6)
            drawRoundedRect(CGRect(x: track.minX, y: track.minY, width: max(6, track.width * amountRatio), height: track.height), fill: color, stroke: .clear, radius: 6)

            draw("\(CurrencyFormatter.format(amount)) • \(String(format: "%.0f", percentage))%", font: .systemFont(ofSize: 10, weight: .semibold), color: reportSecondaryText, frame: CGRect(x: barStartX + barMaxWidth + 10, y: rowY - 2, width: 84, height: 16), alignment: .right)
            rowY += 25
        }

        y += rect.height
    }

    private func drawMonthlyTrendGraph(_ trend: [(String, Decimal)], y: inout CGFloat) {
        let rect = CGRect(x: 42, y: y, width: 528, height: 188)
        drawRoundedRect(rect, fill: reportPanelFill, stroke: UIColor.systemPurple.withAlphaComponent(0.16), radius: 18)
        draw(reportText("report.pdf.monthlyTrend"), font: .systemFont(ofSize: 14, weight: .bold), color: reportPrimaryText, frame: CGRect(x: rect.minX + 16, y: rect.minY + 14, width: 240, height: 20))

        guard !trend.isEmpty else {
            draw(reportText("report.pdf.noMonthlyTrend"), font: .systemFont(ofSize: 12), color: reportSecondaryText, frame: CGRect(x: rect.minX + 16, y: rect.minY + 50, width: rect.width - 32, height: 20))
            y += rect.height
            return
        }

        let chartRect = CGRect(x: rect.minX + 22, y: rect.minY + 48, width: rect.width - 44, height: 102)
        let maxAmount = trend.map(\.1).max() ?? .zero
        let barGap: CGFloat = 10
        let barWidth = max(18, (chartRect.width - CGFloat(trend.count - 1) * barGap) / CGFloat(max(trend.count, 1)))

        for (index, item) in trend.enumerated() {
            let ratio = maxAmount > 0 ? CGFloat(NSDecimalNumber(decimal: item.1 / maxAmount).doubleValue) : 0
            let barHeight = max(5, chartRect.height * ratio)
            let x = chartRect.minX + CGFloat(index) * (barWidth + barGap)
            let barRect = CGRect(x: x, y: chartRect.maxY - barHeight, width: barWidth, height: barHeight)
            drawRoundedRect(barRect, fill: reportColor(at: index), stroke: .clear, radius: 6)

            draw(shortMonthLabel(item.0), font: .systemFont(ofSize: 8, weight: .medium), color: reportSecondaryText, frame: CGRect(x: x - 6, y: chartRect.maxY + 8, width: barWidth + 12, height: 14), alignment: .center)
        }

        y += rect.height
    }

    private func drawTitle(_ text: String, y: inout CGFloat) {
        draw(text, font: .systemFont(ofSize: 28, weight: .bold), color: reportPrimaryText, frame: CGRect(x: 42, y: y, width: 528, height: 38))
        y += 38
    }

    private func drawSubtitle(_ text: String, y: inout CGFloat) {
        draw(text, font: .systemFont(ofSize: 12, weight: .medium), color: reportSecondaryText, frame: CGRect(x: 42, y: y, width: 528, height: 18))
        y += 18
    }

    private func drawSection(_ text: String, y: inout CGFloat) {
        draw(text, font: .systemFont(ofSize: 17, weight: .bold), color: reportPrimaryText, frame: CGRect(x: 42, y: y, width: 528, height: 24))
        y += 30
    }

    private func drawMetric(_ title: String, _ value: String, y: inout CGFloat) {
        draw(title, font: .systemFont(ofSize: 12, weight: .regular), color: reportPrimaryText, frame: CGRect(x: 42, y: y, width: 360, height: 18))
        draw(value, font: .systemFont(ofSize: 12, weight: .semibold), color: reportPrimaryText, frame: CGRect(x: 410, y: y, width: 160, height: 18), alignment: .right)
        y += 22
    }

    private func drawBody(_ text: String, y: inout CGFloat) {
        draw(text, font: .systemFont(ofSize: 12, weight: .regular), color: reportSecondaryText, frame: CGRect(x: 42, y: y, width: 528, height: 18))
        y += 22
    }

    private func draw(_ text: String, font: UIFont, color: UIColor, frame: CGRect, alignment: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: frame, withAttributes: attributes)
    }

    private func drawRoundedRect(_ rect: CGRect, fill: UIColor, stroke: UIColor, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        fill.setFill()
        path.fill()
        if stroke != .clear {
            stroke.setStroke()
            path.lineWidth = 1
            path.stroke()
        }
    }

    private func reportColor(at index: Int) -> UIColor {
        [
            UIColor.systemBlue,
            UIColor.systemTeal,
            UIColor.systemOrange,
            UIColor.systemPurple,
            UIColor.systemGreen,
            UIColor.systemPink
        ][index % 6]
    }

    private func shortMonthLabel(_ label: String) -> String {
        label.split(separator: " ").first.map(String.init) ?? label
    }
}

private extension DateRangeOption {
    func filterIncome(_ incomes: [IncomeRecord]) -> [IncomeRecord] {
        let range = getDateRange()
        return incomes.filter { $0.date >= range.start && $0.date <= range.end }
    }
}
