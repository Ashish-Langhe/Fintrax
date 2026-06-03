//
//  SpendingHeatmapView.swift
//  Fintrax
//
//  Fintrax documentation: Builds dashboard summaries, visualizations, notifications, and spending insight components.
//

import SwiftUI
import Charts

/// Data density heatmap for spending patterns visualization
struct SpendingHeatmapView: View {
    let monthlyData: [[Double]] // 7 days x 4 weeks grid
    let maxValue: Double
    let timeRange: HeatmapTimeRange
    
    @State private var selectedDay: (week: Int, day: Int)? = nil
    @State private var animationProgress: Double = 0
    @State private var hoverScale: Double = 1.0
    
    enum HeatmapTimeRange: String, CaseIterable {
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with time range selector
            headerSection
            
            // Heatmap grid
            heatmapGrid
            
            // Legend
            legendSection
            
            // Insights
            insightsSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .task {
            startAnimation()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Spending Intensity Heatmap")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Time Range", selection: $timeRange) {
                    ForEach(HeatmapTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            Text("Darker colors indicate higher spending")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Heatmap Grid
    
    private var heatmapGrid: some View {
        VStack(spacing: 4) {
            // Day labels
            HStack(spacing: 8) {
                Text("")
                    .frame(width: 40)
                
                ForEach(0..<7, id: \\.self) { day in
                    Text(dayName(day))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Week rows
            ForEach(0..<4, id: \\.self) { week in
                HStack(spacing: 8) {
                    Text("W\\(week + 1)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                    
                    // Day cells
                    ForEach(0..<7, id: \\.self) { day in
                        heatmapCell(week: week, day: day, value: monthlyData[week][day])
                    }
                }
            }
        }
    }
    
    // MARK: - Heatmap Cell
    
    private func heatmapCell(week: Int, day: Int, value: Double) -> some View {
        Button(action: {\n            if selectedDay?.week == week && selectedDay?.day == day {\n                selectedDay = nil\n            } else {\n                selectedDay = (week, day)\n            }\n        }) {\n            RoundedRectangle(cornerRadius: 6)\n                .fill(colorForValue(value))\n                .frame(height: 30)\n                .scaleEffect(\n                    animationProgress,\n                    anchor: selectedDay?.week == week && selectedDay?.day == day ? \\.center : .center\n                )\n                .overlay(\n                    selectedDay?.week == week && selectedDay?.day == day ?\n                    RoundedRectangle(cornerRadius: 6)\n                        .stroke(Color.primary, lineWidth: 2) :\n                    nil\n                )\n                .overlay(\n                    value == 0 ? nil : Text(amountText(value))\n                        .font(.caption2)\n                        .fontWeight(.medium)\n                        .foregroundColor(value > maxValue * 0.7 ? .white : .primary)\n                )\n        }\n        .buttonStyle(PlainButtonStyle())\n    }\n    \n    // MARK: - Legend Section\n    \n    private var legendSection: some View {\n        VStack(alignment: .leading, spacing: 8) {\n            Text(\"Intensity Scale\")\n                .font(.caption)\n                .fontWeight(.medium)\n                .foregroundColor(.secondary)\n            \n            HStack(spacing: 8) {\n                // Low intensity\n                RoundedRectangle(cornerRadius: 4)\n                    .fill(colorForValue(0))\n                    .frame(width: 20, height: 12)\n                \n                Text(\"Low\")\n                    .font(.caption2)\n                    .foregroundColor(.secondary)\n                \n                Spacer()\n                \n                // Medium intensity\n                RoundedRectangle(cornerRadius: 4)\n                    .fill(colorForValue(maxValue * 0.5))\n                    .frame(width: 20, height: 12)\n                \n                Text(\"Medium\")\n                    .font(.caption2)\n                    .foregroundColor(.secondary)\n                \n                Spacer()\n                \n                // High intensity\n                RoundedRectangle(cornerRadius: 4)\n                    .fill(colorForValue(maxValue * 0.8))\n                    .frame(width: 20, height: 12)\n                \n                Text(\"High\")\n                    .font(.caption2)\n                    .foregroundColor(.secondary)\n                \n                Spacer()\n                \n                // Very high intensity\n                RoundedRectangle(cornerRadius: 4)\n                    .fill(colorForValue(maxValue))\n                    .frame(width: 20, height: 12)\n                \n                Text(\"Very High\")\n                    .font(.caption2)\n                    .foregroundColor(.secondary)\n            }\n        }\n    }\n    \n    // MARK: - Insights Section\n    \n    private var insightsSection: some View {\n        VStack(alignment: .leading, spacing: 8) {\n            Text(\"Insights\")\n                .font(.subheadline)\n                .fontWeight(.semibold)\n            \n            LazyVStack(spacing: 6) {\n                ForEach(generateInsights(), id: \\.self) { insight in\n                    HStack(alignment: .top, spacing: 8) {\n                        Image(systemName: \"lightbulb\")\n                            .font(.caption)\n                            .foregroundColor(.orange)\n                            .padding(.top, 2)\n                        \n                        Text(insight)\n                            .font(.caption)\n                            .foregroundColor(.primary)\n                            .multilineTextAlignment(.leading)\n                        \n                        Spacer()\n                    }\n                    .padding(.horizontal, 8)\n                    .padding(.vertical, 4)\n                    .background(\n                        RoundedRectangle(cornerRadius: 8)\n                            .fill(Color.orange.opacity(0.08))\n                    )\n                }\n            }\n        }\n    }\n    \n    // MARK: - Helper Methods\n    \n    private func startAnimation() {\n        withAnimation(.easeInOut(duration: 1.5)) {\n            animationProgress = 1.0\n        }\n    }\n    \n    private func dayName(_ day: Int) -> String {\n        let days = [\"Mon\", \"Tue\", \"Wed\", \"Thu\", \"Fri\", \"Sat\", \"Sun\"]\n        return days[day]\n    }\n    \n    private func colorForValue(_ value: Double) -> Color {\n        guard maxValue > 0 else { return Color(.systemGray6) }\n        \n        let intensity = value / maxValue\n        \n        switch intensity {\n        case 0..<0.2:\n            return Color(.systemGray6)\n        case 0.2..<0.4:\n            return Color.green.opacity(0.3)\n        case 0.4..<0.6:\n            return Color.green.opacity(0.6)\n        case 0.6..<0.8:\n            return Color.orange.opacity(0.7)\n        default:\n            return Color.red.opacity(0.8)\n        }\n    }\n    \n    private func amountText(_ value: Double) -> String {\n        guard value > 0 else { return \"\" }\n        \n        if value >= 1000 {\n            return String(format: \"%.0fk\", value / 1000)\n        } else {\n            return String(format: \"%.0f\", value)\n        }\n    }\n    \n    private func generateInsights() -> [String] {\n        var insights: [String] = []\n        \n        // Find highest spending day\n        let maxValue2D = monthlyData.enumerated().max { lhs, rhs in\n            let maxValue1 = lhs.element.max() ?? 0\n            let maxValue2 = rhs.element.max() ?? 0\n            return maxValue1 < maxValue2\n        }\n        \n        if let maxWeek = maxValue2D?.offset, let maxValueRow = maxValue2D?.element {\n            if let maxDayIndex = maxValueRow.enumerated().max(by: { lhs, rhs in lhs.element < rhs.element })?.offset {\n                let dayValue = maxValueRow[maxDayIndex]\n                insights.append(\"Highest spending: \\(dayName(maxDayIndex)) of week \\(maxWeek + 1) (₹\\(Int(dayValue)))\")\n            }\n        }\n        \n        // Find spending pattern\n        let weekdayTotals = (0..<7).map { day in\n            monthlyData.reduce(0.0) { sum, week in sum + week[day] }\n        }\n        \n        if let maxWeekday = weekdayTotals.enumerated().max(by: { $0.element < $1.element })?.offset {\n            insights.append(\"Most expensive weekday: \\(dayName(maxWeekday))\")\n        }\n        \n        // Weekend vs weekday comparison\n        let weekendDays = [5, 6] // Saturday, Sunday\n        let weekdayDays = [0, 1, 2, 3, 4]\n        \n        let weekendTotal = weekendDays.reduce(0.0) { sum, day in\n            sum + monthlyData.reduce(0.0) { weekSum, week in weekSum + week[day] }\n        }\n        \n        let weekdayTotal = weekdayDays.reduce(0.0) { sum, day in\n            sum + monthlyData.reduce(0.0) { weekSum, week in weekSum + week[day] }\n        }\n        \n        if weekendTotal > weekdayTotal * 1.2 {\n            insights.append(\"Weekend spending is \\(String(format: \"%.0f\", (weekendTotal / weekdayTotal - 1) * 100))% higher than weekdays\")\n        }\n        \n        return insights\n    }\n}\n\n/// Spending pattern calendar view with visualization\nstruct SpendingCalendarView: View {\n    let expenses: [Expense]\n    let selectedMonth: Date\n    \n    @State private var selectedDate: Date?\n    @State private var calendarLayout = CalendarLayout.week\n    \n    enum CalendarLayout: String, CaseIterable {\n        case week = \"Week\"\n        case month = \"Month\"\n        case year = \"Year\"\n    }\n    \n    private var calendar: Calendar {\n        var calendar = Calendar.current\n        calendar.firstWeekday = 2 // Monday\n        return calendar\n    }\n    \n    var body: some View {\n        VStack(spacing: 16) {\n            // Header\n            headerSection\n            \n            // Calendar content\n            calendarContent\n            \n            // Selected date details\n            if let selectedDate = selectedDate {\n                selectedDateDetails(selectedDate)\n            }\n        }\n        .padding()\n        .background(\n            RoundedRectangle(cornerRadius: 20)\n                .fill(Color(.secondarySystemBackground))\n                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)\n        )\n    }\n    \n    private var headerSection: some View {\n        HStack {\n            Text(\"Spending Calendar\")\n                .font(.headline)\n                .fontWeight(.semibold)\n            \n            Spacer()\n            \n            Picker(\"View\", selection: $calendarLayout) {\n                ForEach(CalendarLayout.allCases) { layout in\n                    Text(layout.rawValue).tag(layout)\n                }\n            }\n            .pickerStyle(.segmented)\n            .frame(width: 150)\n        }\n    }\n    \n    @ViewBuilder\n    private var calendarContent: some View {\n        switch calendarLayout {\n        case .week:\n            weekCalendarView\n        case .month:\n            monthCalendarView\n        case .year:\n            yearCalendarView\n        }\n    }\n    \n    private var weekCalendarView: some View {\n        VStack(spacing: 0) {\n            dayOfWeekHeaders\n            weekGrid(4)\n        }\n    }\n    \n    private var monthCalendarView: some View {\n        VStack(spacing: 0) {\n            dayOfWeekHeaders\n            monthGrid\n        }\n    }\n    \n    private var yearCalendarView: some View {\n        VStack(spacing: 16) {\n            Text(\"Year Overview Coming Soon\")\n                .font(.subheadline)\n                .foregroundColor(.secondary)\n        }\n        .frame(height: 200)\n    }\n    \n    private var dayOfWeekHeaders: some View {\n        HStack(spacing: 0) {\n            ForEach(1 ..< 8) { day in\n                Text(weekdaySymbol(for: day))\n                    .font(.caption2)\n                    .fontWeight(.medium)\n                    .foregroundColor(.secondary)\n                    .frame(maxWidth: .infinity)\n            }\n        }\n        .padding(.bottom, 4)\n    }\n    \n    private func weekdaySymbol(for dayNumber: Int) -> String {\n        let weekdaySymbols = calendar.veryShortWeekdaySymbols\n        let dayIndex = dayNumber - 1\n        return weekdaySymbols[dayIndex % 7]\n    }\n    \n    private func weekGrid(_ weekCount: Int) -> some View {\n        VStack(spacing: 4) {\n            ForEach(0..<weekCount, id: \\.self) { week in\n                HStack(spacing: 4) {\n                    ForEach(0..<7, id: \\.self) { day in\n                        calendarDayCell(week: week, day: day)\n                    }\n                }\n            }\n        }\n    }\n    \n    private var monthGrid: some View {\n        VStack(spacing: 4) {\n            ForEach(0..<6, id: \\.self) { week in\n                HStack(spacing: 4) {\n                    ForEach(0..<7, id: \\.self) { day in\n                        calendarDayCell(week: week, day: day)\n                    }\n                }\n            }\n        }\n    }\n    \n    private func calendarDayCell(week: Int, day: Int) -> some View {\n        let date = dateFrom(week: week, day: day)\n        let dayExpenses = expensesForDate(date)\n        let totalAmount = dayExpenses.reduce(Decimal.zero) { $0 + $1.amount }\n        \n        return Button(action: {\n            selectedDate = selectedDate == date ? nil : date\n        }) {\n            VStack(spacing: 2) {\n                Text(dateFormatter.string(from: date))\n                    .font(.caption2)\n                    .fontWeight(.medium)\n                    .foregroundColor(isInCurrentMonth(date) ? .primary : .secondary)\n                \n                if totalAmount > 0 {\n                    Circle()\n                        .fill(spendingColorForAmount(totalAmount))\n                        .frame(width: 8, height: 8)\n                        .scaleEffect(selectedDate == date ? 1.3 : 1.0)\n                } else {\n                    Circle()\n                        .stroke(Color(.systemGray4), lineWidth: 1)\n                        .frame(width: 8, height: 8)\n                }\n            }\n            .frame(maxWidth: .infinity)\n            .frame(height: 40)\n            .background(\n                RoundedRectangle(cornerRadius: 8)\n                    .fill(\n                        selectedDate == date ?\n                        Color(.systemGray5) :\n                        Color.clear\n                    )\n            )\n        }\n        .buttonStyle(PlainButtonStyle())\n    }\n    \n    private func dateFrom(week: Int, day: Int) -> Date {\n        guard let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start else {\n            return selectedMonth\n        }\n        \n        guard let firstWeekday = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start else {\n            return startOfMonth\n        }\n        \n        return calendar.date(byAdding: .day, value: week * 7 + day, to: firstWeekday) ?? startOfMonth\n    }\n    \n    private func expensesForDate(_ date: Date) -> [Expense] {\n        let calendar = Calendar.current\n        return expenses.filter { expense in\n            calendar.isDate(expense.date, inSameDayAs: date)\n        }\n    }\n    \n    private func isInCurrentMonth(_ date: Date) -> Bool {\n        calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)\n    }\n    \n    private func spendingColorForAmount(_ amount: Decimal) -> Color {\n        let doubleAmount = NSDecimalNumber(decimal: amount).doubleValue\n        \n        switch doubleAmount {\n        case 0..<500:\n            return .green.opacity(0.6)\n        case 500..<1500:\n            return .orange.opacity(0.6)\n        default:\n            return .red.opacity(0.6)\n        }\n    }\n    \n    private func selectedDateDetails(_ date: Date) -> some View {\n        let dayExpenses = expensesForDate(date)\n        let totalAmount = dayExpenses.reduce(Decimal.zero) { $0 + $1.amount }\n        \n        return VStack(alignment: .leading, spacing: 8) {\n            Text(\"Details for \\(dateFormatter.string(from: date))\")\n                .font(.subheadline)\n                .fontWeight(.semibold)\n            \n            HStack {\n                Text(\"Total Spending:\")\n                    .font(.caption)\n                    .foregroundColor(.secondary)\n                \n                Spacer()\n                \n                Text(formatCurrency(totalAmount))\n                    .font(.caption)\n                    .fontWeight(.semibold)\n                    .foregroundColor(.red)\n            }\n            \n            Text(\"\\(dayExpenses.count) transaction\\(dayExpenses.count != 1 ? \"s\" : \"\")\")\n                .font(.caption2)\n                .foregroundColor(.secondary)\n        }\n        .padding()\n        .background(\n            RoundedRectangle(cornerRadius: 12)\n                .fill(Color(.tertiarySystemBackground))\n        )\n    }\n    \n    private var dateFormatter: DateFormatter {\n        let formatter = DateFormatter()\n        formatter.dateFormat = \"d\"\n        return formatter\n    }\n    \n    private func formatCurrency(_ amount: Decimal) -> String {\n        let formatter = NumberFormatter()\n        formatter.numberStyle = .currency\n        formatter.currencyCode = \"INR\"\n        formatter.locale = Locale(identifier: \"en_IN\")\n        formatter.maximumFractionDigits = 0\n        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? \"₹0\"\n    }\n}\n\n#Preview {\n    ScrollView {\n        VStack(spacing: 16) {\n            SpendingHeatmapView(\n                monthlyData: [\n                    [2000, 1500, 800, 3000, 2500, 5000, 1200],\n                    [1800, 2200, 900, 2800, 2300, 4500, 1500],\n                    [2100, 1600, 1100, 3200, 2600, 4800, 1400],\n                    [1700, 1900, 700, 2900, 2400, 4200, 1300]\n                ],\n                maxValue: 5000,\n                timeRange: .month\n            )\n            \n            SpendingCalendarView(\n                expenses: [],\n                selectedMonth: Date()\n            )\n        }\n        .padding()\n    }\n}