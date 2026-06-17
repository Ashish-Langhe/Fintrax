//
//  FintraxAssistantPresence.swift
//  Fintrax
//
//  Fintrax documentation: Provides the animated assistant presence used across insight-heavy screens.
//

import SwiftUI

struct FintraxAssistantPresenceModifier: ViewModifier {
    let entrance: FintraxAssistantEntrance
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                FintraxAssistantLauncher(entrance: entrance) {
                    isPresented = true
                }
                .padding(.trailing, 18)
                .padding(.bottom, 82)
            }
            .sheet(isPresented: $isPresented) {
                FintraxAssistantSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
    }
}

extension View {
    func fintraxAssistantPresence(entrance: FintraxAssistantEntrance = .subtle) -> some View {
        modifier(FintraxAssistantPresenceModifier(entrance: entrance))
    }
}

enum FintraxAssistantEntrance {
    case dashboardArrival
    case subtle
}

private struct FintraxAssistantLauncher: View {
    let entrance: FintraxAssistantEntrance
    let action: () -> Void
    @State private var isBlinking = false
    @State private var shimmer = false
    @State private var hasEntered = false
    @State private var arrivalSpark = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                action()
            }
        } label: {
            FintraxAssistantBot(size: 72, isBlinking: isBlinking, isThinking: shimmer)
                .overlay(alignment: .topLeading) {
                    if entrance == .dashboardArrival {
                        arrivalTrail
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Fintrax assistant")
        .opacity(hasEntered ? 1 : entrance == .dashboardArrival ? 0 : 1)
        .scaleEffect(hasEntered ? 1 : entrance == .dashboardArrival ? 0.58 : 1)
        .rotationEffect(.degrees(hasEntered ? 0 : entrance == .dashboardArrival ? -16 : 0))
        .offset(
            x: hasEntered ? 0 : entrance == .dashboardArrival ? 92 : 0,
            y: hasEntered ? 0 : entrance == .dashboardArrival ? 118 : 0
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                shimmer = true
            }
            startEntrance()
            startBlinking()
        }
    }

    @ViewBuilder
    private var arrivalTrail: some View {
        if arrivalSpark {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.18 + Double(index) * 0.14))
                        .frame(width: CGFloat(7 + index * 3), height: CGFloat(7 + index * 3))
                        .offset(x: CGFloat(-22 - index * 8), y: CGFloat(22 + index * 6))
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.82)))
        }
    }

    private func startEntrance() {
        guard !hasEntered else { return }

        if entrance == .dashboardArrival {
            arrivalSpark = true
            withAnimation(.interpolatingSpring(stiffness: 112, damping: 12).delay(0.42)) {
                hasEntered = true
            }
            withAnimation(.easeOut(duration: 0.46).delay(1.08)) {
                arrivalSpark = false
            }
        } else {
            hasEntered = true
        }
    }

    private func startBlinking() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: AssistantBlinkRhythm.nextPause())
                await AssistantBlinkRhythm.performBlink { blink in
                    isBlinking = blink
                }
            }
        }
    }
}

private struct FintraxAssistantSheet: View {
    @State private var selectedPrompt: AssistantPrompt?
    @State private var insights: [AssistantInsight] = []
    @State private var loadingState: AssistantLoadingState = .loading
    @State private var isThinking = false
    @State private var isBlinking = false

    private let prompts = AssistantPrompt.samples
    private let repository = FinanceDataRepository.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                promptGrid
                previewResponse
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(FintraxTabBackground(style: .analytics))
        .onAppear {
            startBlinking()
        }
        .task {
            await loadInsights()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            FintraxAssistantBot(size: 76, isBlinking: isBlinking, isThinking: isThinking)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fintrax Assistant")
                    .font(AppDesignSystem.Typography.title3)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text("Ask quick questions about spending, savings, budgets, and category patterns.")
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(assistantPanel(accent: AppDesignSystem.Colors.primary))
    }

    private var promptGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick asks")
                .font(AppDesignSystem.Typography.calloutEmphasized)
                .foregroundStyle(AppDesignSystem.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(prompts) { prompt in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                            selectedPrompt = prompt
                            isThinking = false
                        }
                    } label: {
                        AssistantPromptChip(prompt: prompt, isSelected: selectedPrompt == prompt)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(assistantPanel(accent: AppDesignSystem.Colors.info))
    }

    private var previewResponse: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch loadingState {
            case .loading:
                AssistantLoadingCard()
                    .onAppear {
                        isThinking = true
                    }
            case .failed(let message):
                AssistantInsightCard(
                    insight: AssistantInsight(
                        promptID: "error",
                        title: "Could not read finance data",
                        value: "Try again",
                        message: message,
                        action: "I will keep the assistant available once the data store responds.",
                        icon: "exclamationmark.triangle.fill",
                        tint: AppDesignSystem.Colors.error,
                        detailRows: []
                    )
                )
                .onAppear {
                    isThinking = false
                }
            case .loaded:
                ForEach(visibleInsights) { insight in
                    AssistantInsightCard(insight: insight)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.86), value: selectedPrompt)
    }

    private var visibleInsights: [AssistantInsight] {
        if let selectedPrompt {
            return insights.filter { $0.promptID == selectedPrompt.id }
        }

        return Array(insights.prefix(3))
    }

    private func assistantPanel(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.78))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
    }

    private func startBlinking() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: AssistantBlinkRhythm.nextPause())
                await AssistantBlinkRhythm.performBlink { blink in
                    isBlinking = blink
                }
            }
        }
    }

    @MainActor
    private func loadInsights() async {
        loadingState = .loading
        isThinking = true

        do {
            let snapshot = try await repository.loadDashboardSnapshot()
            let generatedInsights = AssistantInsightEngine.makeInsights(from: snapshot)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                insights = generatedInsights
                selectedPrompt = generatedInsights.first.flatMap { insight in
                    prompts.first(where: { $0.id == insight.promptID })
                }
                loadingState = .loaded
                isThinking = false
            }
        } catch {
            loadingState = .failed(error.localizedDescription)
            isThinking = false
        }
    }
}

private enum AssistantLoadingState: Equatable {
    case loading
    case loaded
    case failed(String)
}

private enum AssistantBlinkRhythm {
    static func nextPause() -> UInt64 {
        let seconds = Double.random(in: 3.6...7.4)
        return UInt64(seconds * 1_000_000_000)
    }

    @MainActor
    static func performBlink(_ setBlinking: @escaping (Bool) -> Void) async {
        await closeAndOpen(setBlinking, closedFor: 0.105)

        if Int.random(in: 1...7) == 1 {
            try? await Task.sleep(nanoseconds: 120_000_000)
            await closeAndOpen(setBlinking, closedFor: 0.085)
        }
    }

    @MainActor
    private static func closeAndOpen(_ setBlinking: @escaping (Bool) -> Void, closedFor seconds: Double) async {
        withAnimation(.easeInOut(duration: 0.075)) {
            setBlinking(true)
        }

        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))

        withAnimation(.easeInOut(duration: 0.11)) {
            setBlinking(false)
        }
    }
}

private struct FintraxAssistantBot: View {
    let size: CGFloat
    let isBlinking: Bool
    let isThinking: Bool
    @State private var breath = false
    @State private var hover = false
    @State private var sparkle = false
    @State private var eyeGlint = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppDesignSystem.Colors.primary.opacity(isThinking ? 0.22 : 0.12))
                .frame(width: size * 1.05, height: size * 1.05)
                .scaleEffect(breath ? 1.12 : 0.92)
                .blur(radius: size * 0.04)

            Image("FintraxAssistantMascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size * 1.05)
                .scaleEffect(breath ? 1.018 : 0.992)
                .rotationEffect(.degrees(hover ? -2.6 : 2.2))
                .offset(y: hover ? -size * 0.055 : size * 0.025)
                .shadow(color: AppDesignSystem.Colors.primary.opacity(0.28), radius: size * 0.22, x: 0, y: size * 0.12)

            animatedEyes
                .rotationEffect(.degrees(hover ? -2.6 : 2.2))
                .offset(y: hover ? -size * 0.055 : size * 0.025)

            if isThinking || sparkle {
                sparkleField
            }
        }
        .frame(width: size * 1.15, height: size * 1.22)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.15).repeatForever(autoreverses: true)) {
                breath = true
                hover = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                sparkle = true
            }
            withAnimation(.easeInOut(duration: 1.65).repeatForever(autoreverses: true)) {
                eyeGlint = true
            }
        }
    }

    private var animatedEyes: some View {
        ZStack {
            mascotEye(x: -0.070)
            mascotEye(x: 0.074)
        }
        .frame(width: size, height: size * 1.05)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func mascotEye(x: CGFloat) -> some View {
        ZStack {
            if isBlinking {
                Capsule()
                    .fill(Color(red: 0.02, green: 0.08, blue: 0.20).opacity(0.94))
                    .frame(width: size * 0.105, height: size * 0.022)
                    .overlay {
                        Capsule()
                            .fill(AppDesignSystem.Colors.info.opacity(0.42))
                            .frame(width: size * 0.074, height: size * 0.008)
                    }
            } else {
                Circle()
                    .fill(Color.white.opacity(0.96))
                    .frame(width: size * 0.030, height: size * 0.030)
                    .blur(radius: 0.15)
                    .offset(x: eyeGlint ? size * 0.012 : -size * 0.004, y: eyeGlint ? -size * 0.010 : -size * 0.016)

                Circle()
                    .stroke(AppDesignSystem.Colors.info.opacity(eyeGlint ? 0.58 : 0.30), lineWidth: 1)
                    .frame(width: size * 0.105, height: size * 0.105)
                    .scaleEffect(eyeGlint ? 1.04 : 0.96)
            }
        }
        .offset(x: size * x, y: -size * 0.155)
    }

    private var sparkleField: some View {
        ZStack {
            spark(offsetX: -0.42, offsetY: -0.38, scale: 0.68)
            spark(offsetX: 0.42, offsetY: -0.24, scale: 0.52)
            spark(offsetX: 0.35, offsetY: 0.30, scale: 0.44)
        }
    }

    private func spark(offsetX: CGFloat, offsetY: CGFloat, scale: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.11, weight: .bold))
            .foregroundStyle(AppDesignSystem.Colors.warning.opacity(0.86))
            .scaleEffect(sparkle ? scale * 1.18 : scale * 0.82)
            .opacity(sparkle ? 0.95 : 0.42)
            .offset(x: size * offsetX, y: size * offsetY)
    }
}

private struct AssistantLoadingCard: View {
    @State private var pulse = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .frame(width: 38, height: 38)
                .background(AppDesignSystem.Colors.primary.opacity(0.12), in: Circle())
                .scaleEffect(pulse ? 1.08 : 0.94)

            VStack(alignment: .leading, spacing: 7) {
                Text("Reading your money pattern")
                    .font(AppDesignSystem.Typography.calloutEmphasized)
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                Text("Checking expenses, income, budgets, bills, and daily spending behavior.")
                    .font(AppDesignSystem.Typography.caption)
                    .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(assistantPanel(accent: AppDesignSystem.Colors.primary))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func assistantPanel(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.78))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct AssistantInsightCard: View {
    let insight: AssistantInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insight.icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(insight.tint)
                    .frame(width: 40, height: 40)
                    .background(insight.tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(AppDesignSystem.Typography.calloutEmphasized)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)

                    Text(insight.value)
                        .font(AppDesignSystem.Typography.title3.weight(.bold))
                        .foregroundStyle(insight.tint)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 0)
            }

            Text(insight.message)
                .font(AppDesignSystem.Typography.caption)
                .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !insight.detailRows.isEmpty {
                VStack(spacing: 8) {
                    ForEach(insight.detailRows) { row in
                        HStack(spacing: 10) {
                            Image(systemName: row.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(insight.tint)
                                .frame(width: 24, height: 24)
                                .background(insight.tint.opacity(0.10), in: Circle())

                            Text(row.title)
                                .font(AppDesignSystem.Typography.caption)
                                .foregroundStyle(AppDesignSystem.Colors.textSecondary)

                            Spacer(minLength: 8)

                            Text(row.value)
                                .font(AppDesignSystem.Typography.caption.weight(.semibold))
                                .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                    }
                }
                .padding(12)
                .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppDesignSystem.Colors.warning)

                Text(insight.action)
                    .font(AppDesignSystem.Typography.caption.weight(.medium))
                    .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(assistantPanel(accent: insight.tint))
    }

    private func assistantPanel(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppDesignSystem.Colors.elevatedSurface.opacity(0.78))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct AssistantPromptChip: View {
    let prompt: AssistantPrompt
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: prompt.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : prompt.tint)
                .frame(width: 30, height: 30)
                .background((isSelected ? Color.white.opacity(0.18) : prompt.tint.opacity(0.12)), in: Circle())

            Text(prompt.title)
                .font(AppDesignSystem.Typography.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : AppDesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(promptBackground)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.30) : prompt.tint.opacity(0.14), lineWidth: 1)
        }
    }

    private var promptBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(prompt.tint.gradient)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.72),
                    AppDesignSystem.Colors.surfaceVariant.opacity(0.44)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct AssistantPrompt: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let tint: Color
    let preview: String

    static let samples: [AssistantPrompt] = [
        AssistantPrompt(
            id: "highest-day",
            title: "Highest spend day",
            icon: "calendar.badge.exclamationmark",
            tint: AppDesignSystem.Colors.warning,
            preview: "Find the date where your spending peaked this month."
        ),
        AssistantPrompt(
            id: "saving-day",
            title: "Best saving day",
            icon: "leaf.fill",
            tint: AppDesignSystem.Colors.success,
            preview: "Highlight the calmest spending day this month."
        ),
        AssistantPrompt(
            id: "food-month",
            title: "Food this month",
            icon: "fork.knife",
            tint: AppDesignSystem.Colors.primary,
            preview: "Explain food spending and its share of this month."
        ),
        AssistantPrompt(
            id: "budget-risk",
            title: "Budget risk",
            icon: "target",
            tint: AppDesignSystem.Colors.info,
            preview: "Compare spending pace against your monthly budget."
        ),
        AssistantPrompt(
            id: "cash-flow",
            title: "Income vs spend",
            icon: "arrow.left.arrow.right.circle.fill",
            tint: AppDesignSystem.Colors.success,
            preview: "Show this month's income, spend, and net balance."
        ),
        AssistantPrompt(
            id: "frequent-spend",
            title: "Frequent spends",
            icon: "repeat.circle.fill",
            tint: AppDesignSystem.Colors.warning,
            preview: "Spot repeated expense titles and habits."
        )
    ]
}

private struct AssistantInsight: Identifiable {
    let id = UUID()
    let promptID: String
    let title: String
    let value: String
    let message: String
    let action: String
    let icon: String
    let tint: Color
    let detailRows: [AssistantInsightRow]
}

private struct AssistantInsightRow: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
}

private enum AssistantInsightEngine {
    static func makeInsights(from snapshot: DashboardDataSnapshot, now: Date = Date(), calendar: Calendar = .current) -> [AssistantInsight] {
        guard let currentMonth = calendar.dateInterval(of: .month, for: now) else {
            return [emptyInsight(message: "I could not identify the current month range.")]
        }

        let expenses = snapshot.expenses.filter { currentMonth.contains($0.date) }
        let incomes = snapshot.incomes.filter { currentMonth.contains($0.date) }
        let categoryMap = Dictionary(uniqueKeysWithValues: snapshot.categories.map { ($0.id, $0) })
        let totalSpend = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let totalIncome = incomes.reduce(Decimal.zero) { $0 + $1.amount }

        guard !expenses.isEmpty || !incomes.isEmpty else {
            return [emptyInsight(message: "Add a few expenses or switch to demo data, and I can start answering money questions.")]
        }

        return [
            highestSpendDayInsight(expenses: expenses, totalSpend: totalSpend, calendar: calendar),
            bestSavingDayInsight(expenses: expenses, calendar: calendar),
            foodInsight(expenses: expenses, totalSpend: totalSpend, categoryMap: categoryMap),
            budgetRiskInsight(expenses: expenses, monthlyBudget: snapshot.monthlyBudget, now: now, calendar: calendar),
            cashFlowInsight(totalIncome: totalIncome, totalSpend: totalSpend, incomes: incomes, expenses: expenses),
            frequentSpendInsight(expenses: expenses, categoryMap: categoryMap)
        ]
    }

    private static func highestSpendDayInsight(expenses: [Expense], totalSpend: Decimal, calendar: Calendar) -> AssistantInsight {
        let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        let best = grouped
            .map { (date: $0.key, amount: $0.value.reduce(Decimal.zero) { $0 + $1.amount }, count: $0.value.count) }
            .max { $0.amount < $1.amount }

        guard let best else {
            return emptyInsight(promptID: "highest-day", message: "No expenses found for this month yet.")
        }

        let share = totalSpend > 0 ? NSDecimalNumber(decimal: best.amount / totalSpend).doubleValue : 0
        return AssistantInsight(
            promptID: "highest-day",
            title: "Highest spend day",
            value: best.date.formatted(date: .abbreviated, time: .omitted),
            message: "You spent \(CurrencyFormatter.format(best.amount)) across \(best.count) entries on this date, about \(Int((share * 100).rounded()))% of this month's spending.",
            action: "Open expenses for this date before month-end review; one unusually heavy day often explains the whole trend.",
            icon: "calendar.badge.exclamationmark",
            tint: AppDesignSystem.Colors.warning,
            detailRows: [
                AssistantInsightRow(icon: "indianrupeesign.circle.fill", title: "Day total", value: CurrencyFormatter.format(best.amount)),
                AssistantInsightRow(icon: "list.bullet", title: "Entries", value: "\(best.count)")
            ]
        )
    }

    private static func bestSavingDayInsight(expenses: [Expense], calendar: Calendar) -> AssistantInsight {
        let today = calendar.startOfDay(for: Date())
        let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        let daysWithSpend = grouped
            .map { (date: $0.key, amount: $0.value.reduce(Decimal.zero) { $0 + $1.amount }, count: $0.value.count) }
            .filter { $0.date <= today }

        guard let lowest = daysWithSpend.min(by: { $0.amount < $1.amount }) else {
            return emptyInsight(promptID: "saving-day", message: "No expense days found for this month yet.")
        }

        return AssistantInsight(
            promptID: "saving-day",
            title: "Best saving day",
            value: lowest.date.formatted(date: .abbreviated, time: .omitted),
            message: "This was your calmest recorded spend day with \(CurrencyFormatter.format(lowest.amount)) across \(lowest.count) entries.",
            action: "Notice what was different on that day. Repeating that routine is usually easier than only cutting big purchases.",
            icon: "leaf.fill",
            tint: AppDesignSystem.Colors.success,
            detailRows: [
                AssistantInsightRow(icon: "indianrupeesign.circle.fill", title: "Lowest day total", value: CurrencyFormatter.format(lowest.amount)),
                AssistantInsightRow(icon: "calendar", title: "Tracked spend days", value: "\(daysWithSpend.count)")
            ]
        )
    }

    private static func foodInsight(expenses: [Expense], totalSpend: Decimal, categoryMap: [UUID: Category]) -> AssistantInsight {
        let foodExpenses = expenses.filter { expense in
            guard let category = categoryMap[expense.categoryID] else { return false }
            return category.name.localizedCaseInsensitiveContains("food")
        }
        let amount = foodExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        let share = totalSpend > 0 ? NSDecimalNumber(decimal: amount / totalSpend).doubleValue : 0
        let average = foodExpenses.isEmpty ? Decimal.zero : amount / Decimal(foodExpenses.count)

        return AssistantInsight(
            promptID: "food-month",
            title: "Food this month",
            value: CurrencyFormatter.format(amount),
            message: foodExpenses.isEmpty
                ? "I did not find Food category expenses this month."
                : "Food is \(Int((share * 100).rounded()))% of monthly spend with \(foodExpenses.count) entries.",
            action: foodExpenses.isEmpty
                ? "If food items are going into Other, update those categories and I will read the pattern correctly."
                : "A useful control is setting a weekly food ceiling near \(CurrencyFormatter.format((amount / Decimal(max(1, Calendar.current.component(.day, from: Date())))) * 7)).",
            icon: "fork.knife",
            tint: AppDesignSystem.Colors.primary,
            detailRows: [
                AssistantInsightRow(icon: "percent", title: "Share of spend", value: "\(Int((share * 100).rounded()))%"),
                AssistantInsightRow(icon: "chart.bar.fill", title: "Avg entry", value: CurrencyFormatter.format(average))
            ]
        )
    }

    private static func budgetRiskInsight(expenses: [Expense], monthlyBudget: MonthlyBudget?, now: Date, calendar: Calendar) -> AssistantInsight {
        guard let monthlyBudget else {
            return AssistantInsight(
                promptID: "budget-risk",
                title: "Budget risk",
                value: "Budget not set",
                message: "I can analyze budget pace once a monthly budget is configured.",
                action: "Set a monthly budget to unlock risk, safe daily spend, and month-end projection.",
                icon: "target",
                tint: AppDesignSystem.Colors.warning,
                detailRows: []
            )
        }

        let spent = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let usage = monthlyBudget.amount > 0 ? NSDecimalNumber(decimal: spent / monthlyBudget.amount).doubleValue : 0
        let range = calendar.range(of: .day, in: .month, for: now)
        let day = max(calendar.component(.day, from: now), 1)
        let totalDays = max(range?.count ?? day, day)
        let daysLeft = max(totalDays - day, 0)
        let currentDaily = spent / Decimal(day)
        let projected = currentDaily * Decimal(totalDays)
        let remaining = monthlyBudget.amount - spent
        let safeDaily = daysLeft > 0 ? max(remaining, .zero) / Decimal(daysLeft) : .zero
        let tint: Color = usage >= 1 ? AppDesignSystem.Colors.error : usage >= 0.8 ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.info

        return AssistantInsight(
            promptID: "budget-risk",
            title: "Budget risk",
            value: "\(Int((usage * 100).rounded()))% used",
            message: "You have \(daysLeft) days left. At the current pace, month-end spend may reach \(CurrencyFormatter.format(projected)).",
            action: usage >= 1
                ? "Pause non-essential spends first; you are already beyond the planned monthly limit."
                : "Keep daily spend near \(CurrencyFormatter.format(safeDaily)) to stay inside the budget.",
            icon: usage >= 1 ? "exclamationmark.triangle.fill" : "target",
            tint: tint,
            detailRows: [
                AssistantInsightRow(icon: "wallet.pass.fill", title: "Budget", value: CurrencyFormatter.format(monthlyBudget.amount)),
                AssistantInsightRow(icon: "arrow.down.forward.circle.fill", title: "Safe daily", value: CurrencyFormatter.format(safeDaily))
            ]
        )
    }

    private static func cashFlowInsight(totalIncome: Decimal, totalSpend: Decimal, incomes: [IncomeRecord], expenses: [Expense]) -> AssistantInsight {
        let net = totalIncome - totalSpend
        let positive = net >= 0

        return AssistantInsight(
            promptID: "cash-flow",
            title: "Income vs spend",
            value: CurrencyFormatter.format(net),
            message: positive
                ? "You are currently cash-flow positive this month."
                : "Spending is ahead of recorded income this month.",
            action: positive
                ? "Protect this surplus by moving a fixed amount into savings before discretionary spending."
                : "Check whether income is missing first; if not, reduce the top two flexible categories.",
            icon: positive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
            tint: positive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error,
            detailRows: [
                AssistantInsightRow(icon: "plus.circle.fill", title: "Income", value: CurrencyFormatter.format(totalIncome)),
                AssistantInsightRow(icon: "minus.circle.fill", title: "Spend", value: CurrencyFormatter.format(totalSpend)),
                AssistantInsightRow(icon: "number", title: "Records", value: "\(incomes.count) income / \(expenses.count) expense")
            ]
        )
    }

    private static func frequentSpendInsight(expenses: [Expense], categoryMap: [UUID: Category]) -> AssistantInsight {
        let normalized = Dictionary(grouping: expenses) { normalizeTitle($0.title) }
            .mapValues { grouped in
                (
                    title: grouped.first?.title ?? "Expense",
                    amount: grouped.reduce(Decimal.zero) { $0 + $1.amount },
                    count: grouped.count,
                    category: grouped.first.flatMap { categoryMap[$0.categoryID]?.name } ?? "Uncategorized"
                )
            }
            .filter { $0.value.count > 1 }

        guard let top = normalized.values.sorted(by: {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.amount > $1.amount
        }).first else {
            return AssistantInsight(
                promptID: "frequent-spend",
                title: "Frequent spends",
                value: "No repeats yet",
                message: "I did not find repeated expense titles this month.",
                action: "As more entries come in, I will flag repeat habits like coffee, fuel, groceries, or subscriptions.",
                icon: "repeat.circle.fill",
                tint: AppDesignSystem.Colors.warning,
                detailRows: []
            )
        }

        return AssistantInsight(
            promptID: "frequent-spend",
            title: "Frequent spends",
            value: top.title,
            message: "This appeared \(top.count) times and totals \(CurrencyFormatter.format(top.amount)) this month.",
            action: "Repeated small spends are worth reviewing because they are easier to tune than rare large spends.",
            icon: "repeat.circle.fill",
            tint: AppDesignSystem.Colors.warning,
            detailRows: [
                AssistantInsightRow(icon: "number.circle.fill", title: "Frequency", value: "\(top.count)x"),
                AssistantInsightRow(icon: "tag.fill", title: "Category", value: top.category)
            ]
        )
    }

    private static func emptyInsight(promptID: String = "highest-day", message: String) -> AssistantInsight {
        AssistantInsight(
            promptID: promptID,
            title: "No insight yet",
            value: "Needs data",
            message: message,
            action: "Add expenses, income, and budget details so I can produce meaningful answers.",
            icon: "sparkles",
            tint: AppDesignSystem.Colors.primary,
            detailRows: []
        )
    }

    private static func normalizeTitle(_ title: String) -> String {
        title
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: " ")
    }
}
