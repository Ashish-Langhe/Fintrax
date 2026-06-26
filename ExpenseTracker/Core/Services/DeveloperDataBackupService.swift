//
//  DeveloperDataBackupService.swift
//  Fintrax
//
//  Fintrax documentation: Provides developer-only local backup and restore for real finance data.
//

import Foundation

struct DeveloperDataBackupSummary: Sendable {
    let expenses: Int
    let categories: Int
    let budgets: Int
    let incomes: Int
    let bills: Int
    let fileURL: URL

    var totalRecords: Int {
        expenses + categories + budgets + incomes + bills + 1
    }
}

@MainActor
struct DeveloperDataBackupService {
    private struct BackupPayload: Codable {
        let version: Int
        let createdAt: Date
        let expenses: [Expense]
        let categories: [Category]
        let budgets: [Budget]
        let monthlyBudget: MonthlyBudget?
        let incomes: [IncomeRecord]
        let bills: [BillReminder]
    }

    private enum FileName {
        static let latest = "fintrax_developer_backup_latest.json"
    }

    private let dataService: JSONDataService
    private let store: SwiftDataStore
    private let eventBus: AppEventBus
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.dataService = .shared
        self.store = .shared
        self.eventBus = .shared
        self.fileManager = fileManager
    }

    func createBackup() async throws -> DeveloperDataBackupSummary {
        try await writeCurrentBackup(returningExportFile: false)
    }

    func exportBackup() async throws -> DeveloperDataBackupSummary {
        try await writeCurrentBackup(returningExportFile: true)
    }

    private func writeCurrentBackup(returningExportFile: Bool) async throws -> DeveloperDataBackupSummary {
        let payload = try await currentPayload()
        let directory = try backupDirectory()
        let latestURL = directory.appendingPathComponent(FileName.latest)
        let datedURL = directory.appendingPathComponent(timestampedFileName(for: payload.createdAt))
        let data = try JSONEncoder.fintraxBackupEncoder.encode(payload)

        try data.write(to: latestURL, options: .atomic)
        try data.write(to: datedURL, options: .atomic)

        return summary(for: payload, fileURL: returningExportFile ? datedURL : latestURL)
    }

    func restoreLatestBackup() async throws -> DeveloperDataBackupSummary {
        let url = try backupDirectory().appendingPathComponent(FileName.latest)
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder.fintraxBackupDecoder.decode(BackupPayload.self, from: data)

        for category in payload.categories {
            try store.upsertCategoryPreservingIdentity(category)
        }

        for expense in payload.expenses {
            try upsertExpense(expense)
        }

        for budget in payload.budgets {
            try await dataService.upsertBudget(budget)
        }

        if let monthlyBudget = payload.monthlyBudget {
            try await dataService.saveMonthlyBudget(monthlyBudget)
        }

        for income in payload.incomes {
            try upsertIncome(income)
        }

        for bill in payload.bills {
            try upsertBill(bill)
        }

        AppDataChange.allCases.forEach { eventBus.post($0) }
        return summary(for: payload, fileURL: url)
    }

    private func currentPayload() async throws -> BackupPayload {
        let expenses = try await dataService.loadExpenses()
        let categories = try await dataService.loadCategories()
        let budgets = try await dataService.loadBudgets()
        let monthlyBudget = try await dataService.loadMonthlyBudget()

        return BackupPayload(
            version: 1,
            createdAt: Date(),
            expenses: expenses,
            categories: categories,
            budgets: budgets,
            monthlyBudget: monthlyBudget,
            incomes: try store.loadIncomeRecords(),
            bills: try store.loadBillReminders()
        )
    }

    private func upsertExpense(_ expense: Expense) throws {
        do {
            try store.saveExpense(expense)
        } catch DataServiceError.constraintViolation {
            try store.updateExpense(expense)
        }
    }

    private func upsertIncome(_ income: IncomeRecord) throws {
        do {
            try store.saveIncomeRecord(income)
        } catch DataServiceError.constraintViolation {
            try store.updateIncomeRecord(income)
        }
    }

    private func upsertBill(_ bill: BillReminder) throws {
        do {
            try store.saveBillReminder(bill)
        } catch DataServiceError.constraintViolation {
            try store.updateBillReminder(bill)
        }
    }

    private func backupDirectory() throws -> URL {
        let documents = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = documents.appendingPathComponent("FintraxBackups", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func timestampedFileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "fintrax_developer_backup_\(formatter.string(from: date)).json"
    }

    private func summary(for payload: BackupPayload, fileURL: URL) -> DeveloperDataBackupSummary {
        DeveloperDataBackupSummary(
            expenses: payload.expenses.count,
            categories: payload.categories.count,
            budgets: payload.budgets.count,
            incomes: payload.incomes.count,
            bills: payload.bills.count,
            fileURL: fileURL
        )
    }
}

private extension JSONEncoder {
    static var fintraxBackupEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var fintraxBackupDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
