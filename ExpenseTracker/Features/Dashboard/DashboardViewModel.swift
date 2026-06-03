//
//  DashboardViewModel.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import Foundation
import Observation
import Combine

/// ViewModel for managing dashboard data and state
@Observable
final class DashboardViewModel {
    // MARK: - Published Properties
    
    /// Current dashboard data
    private(set) var dashboardData: DashboardData?
    
    /// Loading state for dashboard data
    private(set) var loadingState: LoadingState<DashboardData> = .idle
    
    /// Currently selected date range
    var selectedDateRange: DateRangeOption = .thisMonth {
        didSet {
            if selectedDateRange != oldValue {
                Task {
                    await loadDashboardData()
                }
            }
        }
    }
    
    /// Currently selected category for detailed view
    var selectedCategory: Category?
    
    /// Chart interaction state
    var selectedChartType: ChartType = .pie {
        didSet {
            selectedCategory = nil
        }
    }
    
    // MARK: - Private Properties
    
    private let repository: FinanceDataRepository
    private let eventBus: AppEventBus
    
    // Monthly budget state
    private var monthlyBudget: MonthlyBudget?
    private var currentExpenses: [Expense] = []
    private var currentIncomes: [IncomeRecord] = []
    private var currentBills: [BillReminder] = []
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Initialization
    
    @MainActor
    init(
        repository: FinanceDataRepository? = nil,
        eventBus: AppEventBus? = nil
    ) {
        self.repository = repository ?? .shared
        self.eventBus = eventBus ?? .shared
        setupNotifications()
    }
    
    /// Setup notification observers for real-time updates
    @MainActor
    private func setupNotifications() {
        eventBus
            .publisher(for: .expense)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadDashboardData()
                }
            }
            .store(in: &cancellables)
        
        eventBus
            .publisher(for: .budget)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadDashboardData()
                }
            }
            .store(in: &cancellables)

        eventBus
            .publisher(for: .category)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadDashboardData()
                }
            }
            .store(in: &cancellables)

        eventBus
            .publisher(for: .income)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadDashboardData()
                }
            }
            .store(in: &cancellables)

        eventBus
            .publisher(for: .billReminder)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadDashboardData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads dashboard data from the data service
    @MainActor
    func loadDashboardData() async {
        loadingState = .loading
        
        do {
            let snapshot = try await repository.loadDashboardSnapshot()

            monthlyBudget = snapshot.monthlyBudget
            currentExpenses = snapshot.expenses
            currentIncomes = snapshot.incomes
            currentBills = snapshot.bills
            
            // Generate dashboard data
            let dashboard = DashboardData.generate(
                from: snapshot.expenses,
                categories: snapshot.categories,
                budgets: snapshot.budgets,
                dateRange: selectedDateRange
            )
            
            dashboardData = dashboard
            loadingState = .success(dashboard)
        } catch {
            loadingState = .failure(error)
        }
    }
    
    /// Refreshes dashboard data
    func refreshDashboard() async {
        await loadDashboardData()
    }
    
    /// Handles category selection from charts
    func selectCategory(_ category: Category) {
        selectedCategory = category
    }
    
    /// Clears category selection
    func clearCategorySelection() {
        selectedCategory = nil
    }
    
    /// Formats currency amount for display
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "₹0.00"
    }
    
    /// Gets spending amount for a specific category
    func getCategorySpending(for category: Category) -> Decimal {
        guard let dashboard = dashboardData else { return Decimal.zero }
        return dashboard.categoryBreakdown.first(where: { $0.0.id == category.id })?.1 ?? Decimal.zero
    }
    
    /// Gets spending percentage for a specific category
    func getCategorySpendingPercentage(for category: Category) -> Double {
        guard let dashboard = dashboardData else { return 0.0 }
        return dashboard.getCategorySpendingPercentage(for: category)
    }
    
    /// Gets budget status for a specific category
    func getBudgetStatus(for category: Category) -> BudgetStatus? {
        guard let dashboard = dashboardData else { return nil }
        return dashboard.budgetStatuses.first(where: { $0.0.id == category.id })?.1
    }
    
    /// Gets expenses for the selected category (filtered by date range)
    func getExpensesForSelectedCategory() async -> [Expense] {
        guard let selectedCategory = selectedCategory else { return [] }
        
        do {
            let expenses = try await repository.loadExpenses()
            return selectedDateRange.filterExpenses(expenses)
                .filter { $0.categoryID == selectedCategory.id }
                .sorted { $0.date > $1.date }
        } catch {
            return []
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether the dashboard is currently loading
    var isLoading: Bool {
        if case .loading = loadingState { return true }
        return false
    }
    
    /// Current error if any
    var currentError: Error? {
        if case .failure(let error) = loadingState { return error }
        return nil
    }
    
    /// Top spending category
    var topSpendingCategory: (Category, Decimal)? {
        return dashboardData?.topSpendingCategory
    }
    
    /// Most critical budget status
    var mostCriticalBudgetStatus: (Category, BudgetStatus)? {
        return dashboardData?.mostCriticalBudgetStatus
    }
    
    /// Whether there are any budget warnings
    var hasBudgetWarnings: Bool {
        guard let dashboard = dashboardData else { return false }
        return dashboard.budgetStatuses.contains { status in
            switch status.1 {
            case .approachingLimit, .exceededLimit:
                return true
            case .withinLimit:
                return false
            }
        }
    }
    
    /// Whether there are budget exceeded items
    var hasExceededBudgets: Bool {
        guard let dashboard = dashboardData else { return false }
        return dashboard.budgetStatuses.contains { status in
            switch status.1 {
            case .exceededLimit:
                return true
            case .withinLimit, .approachingLimit:
                return false
            }
        }
    }
    
    /// Whether there is data to display
    var hasData: Bool {
        return dashboardData != nil
    }
    
    /// Whether there are expenses in the current date range
    var hasExpensesInDateRange: Bool {
        return dashboardData?.totalTransactions ?? 0 > 0
    }
    
    /// Remaining budget for current month
    var remainingBudget: Decimal {
        guard let budget = monthlyBudget else { return 0 }
        return BudgetCalculations.calculateRemainingBudget(budget.amount, expenses: currentExpenses)
    }

    /// Whether a monthly budget has been configured
    var hasMonthlyBudget: Bool {
        monthlyBudget != nil
    }
    
    /// Whether user is over budget
    var isOverBudget: Bool {
        guard let budget = monthlyBudget else { return false }
        return BudgetCalculations.isOverBudget(budget.amount, expenses: currentExpenses)
    }
    
    /// Days remaining in current month
    var daysRemainingInMonth: Int {
        return BudgetCalculations.daysRemainingInCurrentMonth()
    }

    /// Income inside the selected dashboard date range
    var selectedRangeIncome: Decimal {
        selectedDateRange.filterIncome(currentIncomes).totalIncome
    }

    /// Net flow inside the selected dashboard date range
    var selectedRangeNetCashFlow: Decimal {
        selectedRangeIncome - (dashboardData?.totalSpending ?? .zero)
    }

    var spendingAIAnalysis: SpendingAIAnalysis? {
        guard let dashboardData, dashboardData.totalTransactions > 0 else { return nil }
        let expenses = selectedDateRange.filterExpenses(currentExpenses)
        guard !expenses.isEmpty else { return nil }

        return SpendingAIAnalyzer.analyze(
            expenses: expenses,
            categories: dashboardData.categoryBreakdown.map(\.0),
            categoryBreakdown: dashboardData.categoryBreakdown,
            income: selectedRangeIncome,
            dateRange: selectedDateRange
        )
    }

    /// Total unpaid bill amount
    var unpaidBillTotal: Decimal {
        currentBills.unpaidTotal
    }

    /// Number of open bills due in the next week
    var upcomingBillCount: Int {
        currentBills.filter(\.isDueSoon).count
    }

    var actionableBillNotifications: [BillReminder] {
        currentBills
            .filter(\.requiresAttention)
            .sorted {
                if $0.isOverdue != $1.isOverdue {
                    return $0.isOverdue && !$1.isOverdue
                }
                return $0.dueDate < $1.dueDate
            }
    }

    var notificationCount: Int {
        actionableBillNotifications.count
    }

    @MainActor
    func markBillPaid(_ bill: BillReminder) async {
        do {
            try repository.markBillReminderPaid(id: bill.id)
            await loadDashboardData()
        } catch {
            loadingState = .failure(error)
        }
    }
}

private extension DateRangeOption {
    func filterIncome(_ incomes: [IncomeRecord]) -> [IncomeRecord] {
        let range = getDateRange()
        return incomes.filter { $0.date >= range.start && $0.date <= range.end }
    }
}

// MARK: - Chart Types

extension DashboardViewModel {
    enum ChartType: String, CaseIterable, Identifiable {
        case pie = "Pie"
        case bar = "Bar"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .pie: return "Category Breakdown"
            case .bar: return "Monthly Trend"
            }
        }
    }
}
