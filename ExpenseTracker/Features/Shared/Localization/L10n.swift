//
//  L10n.swift
//  Fintrax
//
//  Fintrax documentation: Centralizes localized string keys used by SwiftUI views.
//

import SwiftUI

enum L10n {
    static func string(_ key: String) -> String {
        localizedBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func string(_ key: String, language: AppLanguage) -> String {
        localizedBundle(for: language).localizedString(forKey: key, value: nil, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }

    private static var localizedBundle: Bundle {
        let languageCode = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue

        guard languageCode != AppLanguage.system.rawValue,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }

        return bundle
    }

    private static func localizedBundle(for language: AppLanguage) -> Bundle {
        guard language != .system,
              let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }

        return bundle
    }

    private static var locale: Locale {
        let languageCode = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        guard languageCode != AppLanguage.system.rawValue else {
            return .autoupdatingCurrent
        }
        return Locale(identifier: languageCode)
    }

    enum Tab {
        static let dashboard: LocalizedStringKey = "tab.dashboard"
        static let expenses: LocalizedStringKey = "tab.expenses"
        static let analytics: LocalizedStringKey = "tab.analytics"
        static let budget: LocalizedStringKey = "tab.budget"
        static let settings: LocalizedStringKey = "tab.settings"
    }

    enum DateRange {
        static let last7Days: LocalizedStringKey = "dateRange.last7Days"
        static let last30Days: LocalizedStringKey = "dateRange.last30Days"
        static let last90Days: LocalizedStringKey = "dateRange.last90Days"
        static let thisMonth: LocalizedStringKey = "dateRange.thisMonth"
        static let thisYear: LocalizedStringKey = "dateRange.thisYear"
        static let allTime: LocalizedStringKey = "dateRange.allTime"
    }

    enum Dashboard {
        static let title: LocalizedStringKey = "dashboard.title"
        static let thisMonth: LocalizedStringKey = "dashboard.period.thisMonth"
        static let income: LocalizedStringKey = "dashboard.metric.income"
        static let cashReceived: LocalizedStringKey = "dashboard.metric.cashReceived"
        static let budgetLeft: LocalizedStringKey = "dashboard.metric.budgetLeft"
        static let notSet = "dashboard.common.notSet"
        static let overBudget: LocalizedStringKey = "dashboard.budget.overBudget"
        static let daysLeft = "dashboard.budget.daysLeft"
        static let setMonthlyBudget: LocalizedStringKey = "dashboard.budget.setMonthlyBudget"
        static let priorityBrief: LocalizedStringKey = "dashboard.priority.title"
        static let actionable: LocalizedStringKey = "dashboard.priority.actionable"
        static let budgetNeedsAttention: LocalizedStringKey = "dashboard.priority.budgetNeedsAttention"
        static let budgetOnTrack: LocalizedStringKey = "dashboard.priority.budgetOnTrack"
        static let monthlyBudgetNotSet: LocalizedStringKey = "dashboard.priority.monthlyBudgetNotSet"
        static let budgetRemaining = "dashboard.priority.budgetRemaining"
        static let setBudgetGuidance: LocalizedStringKey = "dashboard.priority.setBudgetGuidance"
        static let billsDueSoon = "dashboard.priority.billsDueSoon"
        static let noUrgentBills: LocalizedStringKey = "dashboard.priority.noUrgentBills"
        static let unpaidBills = "dashboard.priority.unpaidBills"
        static let clearNextFewDays: LocalizedStringKey = "dashboard.priority.clearNextFewDays"
        static let financialPulse: LocalizedStringKey = "dashboard.financialPulse.title"
        static let budgetAlerts: LocalizedStringKey = "dashboard.budgetAlerts.title"
        static let loading: LocalizedStringKey = "dashboard.state.loading"
        static let errorTitle: LocalizedStringKey = "dashboard.state.errorTitle"
        static let retry: LocalizedStringKey = "dashboard.action.retry"
        static let emptyTitle: LocalizedStringKey = "dashboard.state.emptyTitle"
        static let emptyMessage: LocalizedStringKey = "dashboard.state.emptyMessage"
        static let addEditExpense: LocalizedStringKey = "dashboard.navigation.addEditExpense"
        static let expenseDetails: LocalizedStringKey = "dashboard.navigation.expenseDetails"
        static let moneySnapshot: LocalizedStringKey = "dashboard.hero.moneySnapshot"
        static let currentMonthOverview: LocalizedStringKey = "dashboard.hero.currentMonthOverview"
        static let totalSpent: LocalizedStringKey = "dashboard.hero.totalSpent"
        static let entries: LocalizedStringKey = "dashboard.common.entries"
        static let netBalance: LocalizedStringKey = "dashboard.hero.netBalance"
        static let incomeHigher: LocalizedStringKey = "dashboard.hero.incomeHigher"
        static let spendingHigher: LocalizedStringKey = "dashboard.hero.spendingHigher"
        static let top: LocalizedStringKey = "dashboard.insight.top"
        static let none = "dashboard.insight.none"
        static let average: LocalizedStringKey = "dashboard.insight.average"
        static let bills: LocalizedStringKey = "dashboard.insight.bills"
        static let due = "dashboard.insight.due"
        static let clear = "dashboard.insight.clear"
        static let spent: LocalizedStringKey = "dashboard.pulse.spent"
        static let netFlow: LocalizedStringKey = "dashboard.pulse.netFlow"
        static let monthlyBudget: LocalizedStringKey = "dashboard.pulse.monthlyBudget"
        static let budgetSetup: LocalizedStringKey = "dashboard.pulse.budgetSetup"
        static let spendingCrossedPlan: LocalizedStringKey = "dashboard.pulse.spendingCrossedPlan"
        static let spendingWithinPlan: LocalizedStringKey = "dashboard.pulse.spendingWithinPlan"
        static let setBudgetToTrack: LocalizedStringKey = "dashboard.pulse.setBudgetToTrack"
        static let totalSpending: LocalizedStringKey = "dashboard.category.totalSpending"
        static let transactions = "dashboard.category.transactions"
        static let budgetStatus: LocalizedStringKey = "dashboard.category.budgetStatus"
        static let expenses: LocalizedStringKey = "dashboard.category.expenses"
        static let notificationCount = "dashboard.notifications.count"
        static let noBillNotifications: LocalizedStringKey = "dashboard.notifications.none"
        static let notificationsTitle: LocalizedStringKey = "dashboard.notifications.title"
        static let notificationsSubtitle: LocalizedStringKey = "dashboard.notifications.subtitle"
        static let overdue: LocalizedStringKey = "dashboard.notifications.overdue"
        static let dueSoon: LocalizedStringKey = "dashboard.notifications.dueSoon"
        static let allCaughtUp: LocalizedStringKey = "dashboard.notifications.allCaughtUp"
        static let noRemindersNeedAttention: LocalizedStringKey = "dashboard.notifications.noRemindersNeedAttention"
        static let overdueStatus: LocalizedStringKey = "dashboard.notifications.overdueStatus"
        static let dueSoonStatus: LocalizedStringKey = "dashboard.notifications.dueSoonStatus"
        static let repeatsUntilComplete: LocalizedStringKey = "dashboard.notifications.repeatsUntilComplete"
        static let completing: LocalizedStringKey = "dashboard.notifications.completing"
        static let markComplete: LocalizedStringKey = "dashboard.notifications.markComplete"
    }

    enum Splash {
        static let preparingWorkspace: LocalizedStringKey = "splash.preparingWorkspace"
    }

    enum Onboarding {
        static let splashSubtitle: LocalizedStringKey = "onboarding.splash.subtitle"
        static let continueButton: LocalizedStringKey = "onboarding.action.continue"
        static let startSecurely: LocalizedStringKey = "onboarding.action.startSecurely"
        static let skip: LocalizedStringKey = "onboarding.action.skip"
        static let trackTitle: LocalizedStringKey = "onboarding.track.title"
        static let trackSubtitle: LocalizedStringKey = "onboarding.track.subtitle"
        static let fastEntryTitle: LocalizedStringKey = "onboarding.track.fastEntry.title"
        static let fastEntrySubtitle: LocalizedStringKey = "onboarding.track.fastEntry.subtitle"
        static let smartCategoriesTitle: LocalizedStringKey = "onboarding.track.smartCategories.title"
        static let smartCategoriesSubtitle: LocalizedStringKey = "onboarding.track.smartCategories.subtitle"
        static let aiTitle: LocalizedStringKey = "onboarding.ai.title"
        static let aiSubtitle: LocalizedStringKey = "onboarding.ai.subtitle"
        static let aiAnalyzeTitle: LocalizedStringKey = "onboarding.ai.analyze.title"
        static let aiAnalyzeSubtitle: LocalizedStringKey = "onboarding.ai.analyze.subtitle"
        static let savingGuidanceTitle: LocalizedStringKey = "onboarding.ai.savingGuidance.title"
        static let savingGuidanceSubtitle: LocalizedStringKey = "onboarding.ai.savingGuidance.subtitle"
        static let reportsTitle: LocalizedStringKey = "onboarding.reports.title"
        static let reportsSubtitle: LocalizedStringKey = "onboarding.reports.subtitle"
        static let selectableDataTitle: LocalizedStringKey = "onboarding.reports.selectableData.title"
        static let selectableDataSubtitle: LocalizedStringKey = "onboarding.reports.selectableData.subtitle"
        static let verifiedPDFTitle: LocalizedStringKey = "onboarding.reports.verifiedPDF.title"
        static let verifiedPDFSubtitle: LocalizedStringKey = "onboarding.reports.verifiedPDF.subtitle"
    }

    enum PinLock {
        static let welcomeBack: LocalizedStringKey = "pinLock.welcomeBack"
        static let enterPin: LocalizedStringKey = "pinLock.enterPin"
        static let pinEntryAccessibility: LocalizedStringKey = "pinLock.accessibility.pinEntry"
        static let digitsEntered = "pinLock.accessibility.digitsEntered"
        static let incorrectPin: LocalizedStringKey = "pinLock.incorrectPin"
        static let deleteDigit: LocalizedStringKey = "pinLock.accessibility.deleteDigit"
        static let digit = "pinLock.accessibility.digit"
    }

    enum Sort {
        static let dateNewest: LocalizedStringKey = "sort.dateNewest"
        static let dateOldest: LocalizedStringKey = "sort.dateOldest"
        static let amountHighest: LocalizedStringKey = "sort.amountHighest"
        static let amountLowest: LocalizedStringKey = "sort.amountLowest"
        static let titleAZ: LocalizedStringKey = "sort.titleAZ"
        static let titleZA: LocalizedStringKey = "sort.titleZA"
    }

    enum Expenses {
        static let title: LocalizedStringKey = "expenses.title"
        static let loading: LocalizedStringKey = "expenses.loading"
        static let loadingShort: LocalizedStringKey = "expenses.loading.short"
        static let loadFailed = "expenses.loadFailed"
        static let error: LocalizedStringKey = "expenses.error"
        static let retry: LocalizedStringKey = "expenses.retry"
        static let cancel: LocalizedStringKey = "expenses.cancel"
        static let deleteQuestion: LocalizedStringKey = "expenses.delete.question"
        static let deleteGenericMessage: LocalizedStringKey = "expenses.delete.genericMessage"
        static let deleteSpecificMessage = "expenses.delete.specificMessage"
        static let deleteExpense: LocalizedStringKey = "expenses.delete.action"
        static let keepExpense: LocalizedStringKey = "expenses.delete.keep"
        static let listMode: LocalizedStringKey = "expenses.display.list"
        static let monthMode: LocalizedStringKey = "expenses.display.month"
        static let displayModeAccessibility: LocalizedStringKey = "expenses.display.accessibility"
        static let allTime: LocalizedStringKey = "expenses.period.allTime"
        static let filteredSpend: LocalizedStringKey = "expenses.summary.filteredSpend"
        static let expenseActivity: LocalizedStringKey = "expenses.summary.activity"
        static let average: LocalizedStringKey = "expenses.summary.average"
        static let entries: LocalizedStringKey = "expenses.common.entries"
        static let itemCount = "expenses.common.itemCount"
        static let entriesInMonth = "expenses.calendar.entriesInMonth"
        static let total: LocalizedStringKey = "expenses.calendar.total"
        static let activeDays: LocalizedStringKey = "expenses.calendar.activeDays"
        static let peakDay: LocalizedStringKey = "expenses.calendar.peakDay"
        static let monthCalendar: LocalizedStringKey = "expenses.calendar.monthCalendar"
        static let avgActiveDay: LocalizedStringKey = "expenses.calendar.avgActiveDay"
        static let monthlyInsight: LocalizedStringKey = "expenses.calendar.monthlyInsight"
        static let noMonthlySpending: LocalizedStringKey = "expenses.calendar.noMonthlySpending"
        static let topCategorySentence = "expenses.calendar.topCategorySentence"
        static let strongerPatterns: LocalizedStringKey = "expenses.calendar.strongerPatterns"
        static let highestSpendingWithCategory = "expenses.calendar.highestSpendingWithCategory"
        static let highestSpendingWithoutCategory = "expenses.calendar.highestSpendingWithoutCategory"
        static let noExpensesOnDate: LocalizedStringKey = "expenses.day.noExpensesOnDate"
        static let expensesRecorded = "expenses.day.expensesRecorded"
        static let dayTotal: LocalizedStringKey = "expenses.day.dayTotal"
        static let topCategory: LocalizedStringKey = "expenses.day.topCategory"
        static let none: String = "expenses.common.none"
        static let highestItem: LocalizedStringKey = "expenses.day.highestItem"
        static let avgEntry: LocalizedStringKey = "expenses.day.avgEntry"
        static let highToLow: LocalizedStringKey = "expenses.day.highToLow"
        static let quietDay: LocalizedStringKey = "expenses.day.quietDay"
        static let quietDayMessage: LocalizedStringKey = "expenses.day.quietDayMessage"
        static let spend: LocalizedStringKey = "expenses.calendar.spend"
        static let darkerDaysAccessibility: LocalizedStringKey = "expenses.calendar.darkerDaysAccessibility"
        static let blankCalendarDay: String = "expenses.calendar.blankDay"
        static let dayAccessibilityWithSpend = "expenses.calendar.dayAccessibilityWithSpend"
        static let dayAccessibilityNoSpend = "expenses.calendar.dayAccessibilityNoSpend"
        static let uncategorized: String = "expenses.common.uncategorized"
        static let search: LocalizedStringKey = "expenses.search.title"
        static let searchPlaceholder: LocalizedStringKey = "expenses.search.placeholder"
        static let clearSearch: LocalizedStringKey = "expenses.search.clear"
        static let clearSearchText: LocalizedStringKey = "expenses.search.clearText"
        static let allCategories: LocalizedStringKey = "expenses.filter.allCategories"
        static let openFilters: LocalizedStringKey = "expenses.filter.open"
        static let noMatchingExpenses: LocalizedStringKey = "expenses.empty.noMatching"
        static let noExpensesYet: LocalizedStringKey = "expenses.empty.noExpenses"
        static let adjustFilters: LocalizedStringKey = "expenses.empty.adjustFilters"
        static let addFirstExpense: LocalizedStringKey = "expenses.empty.addFirst"
        static let resetFilters: LocalizedStringKey = "expenses.filter.resetFilters"
        static let transactions: LocalizedStringKey = "expenses.feed.transactions"
        static let filterTitle: LocalizedStringKey = "expenses.filter.title"
        static let reset: LocalizedStringKey = "expenses.filter.reset"
        static let done: LocalizedStringKey = "expenses.filter.done"
        static let refine: LocalizedStringKey = "expenses.filter.refine"
        static let category: LocalizedStringKey = "expenses.common.category"
        static let showEveryExpense: LocalizedStringKey = "expenses.filter.showEveryExpense"
        static let filterByCategory = "expenses.filter.byCategory"
        static let dateRange: LocalizedStringKey = "expenses.filter.dateRange"
        static let sortBy: LocalizedStringKey = "expenses.filter.sortBy"
        static let selectedCategory: String = "expenses.filter.selectedCategory"
        static let newestFirst: LocalizedStringKey = "expenses.sortSubtitle.newest"
        static let oldestFirst: LocalizedStringKey = "expenses.sortSubtitle.oldest"
        static let highestAmountFirst: LocalizedStringKey = "expenses.sortSubtitle.highestAmount"
        static let lowestAmountFirst: LocalizedStringKey = "expenses.sortSubtitle.lowestAmount"
        static let aToZ: LocalizedStringKey = "expenses.sortSubtitle.aToZ"
        static let zToA: LocalizedStringKey = "expenses.sortSubtitle.zToA"
        static let addExpense: LocalizedStringKey = "expenses.form.addExpense"
        static let editExpense: LocalizedStringKey = "expenses.form.editExpense"
        static let saveChanges: LocalizedStringKey = "expenses.form.saveChanges"
        static let fixErrors: String = "expenses.form.fixErrors"
        static let saveFailed = "expenses.form.saveFailed"
        static let titleFieldName: String = "expenses.form.titleFieldName"
        static let titleRequired: String = "expenses.form.validation.titleRequired"
        static let titleTooLong: String = "expenses.form.validation.titleTooLong"
        static let amountRequired: String = "expenses.form.validation.amountRequired"
        static let amountPositive: String = "expenses.form.validation.amountPositive"
        static let categoryRequired: String = "expenses.form.validation.categoryRequired"
        static let noteTooLong: String = "expenses.form.noteTooLong"
        static let couldNotSave: LocalizedStringKey = "expenses.form.couldNotSave"
        static let reviewDetails: LocalizedStringKey = "expenses.form.reviewDetails"
        static let amount: LocalizedStringKey = "expenses.form.amount"
        static let chooseCategoryDetails: LocalizedStringKey = "expenses.form.chooseCategoryDetails"
        static let update: LocalizedStringKey = "expenses.form.update"
        static let new: LocalizedStringKey = "expenses.form.new"
        static let details: LocalizedStringKey = "expenses.form.details"
        static let titlePlaceholder: LocalizedStringKey = "expenses.form.titlePlaceholder"
        static let date: LocalizedStringKey = "expenses.form.date"
        static let noCategories: LocalizedStringKey = "expenses.form.noCategories"
        static let categoryLoadFailed: String = "expenses.form.categoryLoadFailed"
        static let selectCategory: String = "expenses.form.selectCategory"
        static let unknown: String = "expenses.common.unknown"
        static let note: LocalizedStringKey = "expenses.form.note"
        static let optionalNote: LocalizedStringKey = "expenses.form.optionalNote"
        static let readyToSave: LocalizedStringKey = "expenses.form.readyToSave"
        static let needsAttention: LocalizedStringKey = "expenses.form.needsAttention"
        static let completeRequiredFields: LocalizedStringKey = "expenses.form.completeRequiredFields"
        static let smartCategory: LocalizedStringKey = "expenses.form.smartCategory"
        static let smartCategoryAccessibility = "expenses.form.smartCategoryAccessibility"
        static let smartSearchSummary = "expenses.search.smartSummary"
        static let lastMonth: String = "expenses.search.lastMonth"
        static let thisMonth: String = "expenses.search.thisMonth"
        static let last30Days: String = "expenses.search.last30Days"
        static let recent: String = "expenses.search.recent"
        static let thisYear: String = "expenses.search.thisYear"
        static let noCategoriesTitle: LocalizedStringKey = "expenses.categorySelector.noCategories"
        static let noCategoriesDescription: LocalizedStringKey = "expenses.categorySelector.noCategoriesDescription"
        static let addNewCategory: LocalizedStringKey = "expenses.categorySelector.addNew"
        static let selectCategoryTitle: LocalizedStringKey = "expenses.categorySelector.selectTitle"
        static let addCategory: String = "expenses.categorySelector.addCategory"
        static let addCategoryMessage: String = "expenses.categorySelector.addCategoryMessage"
        static let categoryNamePlaceholder: String = "expenses.categorySelector.categoryName"
        static let gotIt: String = "expenses.categorySelector.gotIt"
        static let categoryNameEmpty: String = "expenses.categorySelector.nameEmpty"
        static let categoryNameTooLong: String = "expenses.categorySelector.nameTooLong"
        static let categoryDuplicate: String = "expenses.categorySelector.duplicate"
        static let categoryCreatePlaceholder: String = "expenses.categorySelector.createPlaceholder"
        static let defaultCategory: LocalizedStringKey = "expenses.categorySelector.defaultCategory"
    }

    enum Assistant {
        static let accessibilityLabel: LocalizedStringKey = "assistant.accessibility.label"
        static let greeting: LocalizedStringKey = "assistant.greeting"
        static let liveStatus: LocalizedStringKey = "assistant.header.status"
        static let title: LocalizedStringKey = "assistant.header.title"
        static let subtitle: LocalizedStringKey = "assistant.header.subtitle"
        static let chooseQuestion: LocalizedStringKey = "assistant.question.choose"
        static let loadingTitle: LocalizedStringKey = "assistant.loading.title"
        static let loadingMessage: LocalizedStringKey = "assistant.loading.message"
        static let readErrorTitle: LocalizedStringKey = "assistant.error.read.title"
        static let readErrorValue: LocalizedStringKey = "assistant.error.read.value"
        static let readErrorAction: LocalizedStringKey = "assistant.error.read.action"
    }

    enum Settings {
        static let headerTitle: LocalizedStringKey = "settings.header.title"
        static let headerSubtitle: LocalizedStringKey = "settings.header.subtitle"
        static let appearanceTitle: LocalizedStringKey = "settings.appearance.title"
        static let appearanceSubtitle: LocalizedStringKey = "settings.appearance.subtitle"
        static let appTheme: LocalizedStringKey = "settings.appearance.theme"
        static let appLanguage: LocalizedStringKey = "settings.appearance.language"
    }
}
