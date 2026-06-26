//
//  FintraxWidgets.swift
//  FintraxWidgets
//
//  Fintrax documentation: Renders Home Screen and Lock Screen budget widgets.
//

import SwiftUI
import WidgetKit

struct FintraxBudgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetBudgetSnapshot
}

struct FintraxBudgetProvider: TimelineProvider {
    private let store = WidgetBudgetSnapshotStore()

    func placeholder(in context: Context) -> FintraxBudgetEntry {
        FintraxBudgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FintraxBudgetEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetBudgetSnapshot.placeholder : store.loadSnapshot()
        completion(FintraxBudgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FintraxBudgetEntry>) -> Void) {
        let entry = FintraxBudgetEntry(date: Date(), snapshot: store.loadSnapshot())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1_800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct FintraxBudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FintraxBudgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallBudgetWidget(snapshot: entry.snapshot)
        case .systemMedium:
            MediumBudgetWidget(snapshot: entry.snapshot)
        case .accessoryCircular:
            CircularBudgetWidget(snapshot: entry.snapshot)
        case .accessoryRectangular:
            RectangularBudgetWidget(snapshot: entry.snapshot)
        case .accessoryInline:
            InlineBudgetWidget(snapshot: entry.snapshot)
        default:
            SmallBudgetWidget(snapshot: entry.snapshot)
        }
    }
}

struct SmallBudgetWidget: View {
    let snapshot: WidgetBudgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeader(state: snapshot.state, compact: true)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.remainingAmount == nil ? localized("widget.budget.notSet") : money(abs(snapshot.remainingAmount ?? .zero)))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(snapshot.remainingAmount ?? .zero < 0 ? "widget.budget.overBy" : "widget.budget.left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            BudgetProgressBar(progress: snapshot.usagePercentage, state: snapshot.state)

            Text(statusLine(for: snapshot))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetBackground(state: snapshot.state)
        }
    }
}

struct MediumBudgetWidget: View {
    let snapshot: WidgetBudgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                WidgetHeader(state: snapshot.state, compact: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.remainingAmount == nil ? localized("widget.budget.notSet") : money(abs(snapshot.remainingAmount ?? .zero)))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(snapshot.remainingAmount ?? .zero < 0 ? "widget.budget.overBudget" : "widget.budget.remainingThisMonth")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                BudgetProgressBar(progress: snapshot.usagePercentage, state: snapshot.state)
            }

            VStack(alignment: .leading, spacing: 10) {
                WidgetMetric(
                    title: "widget.budget.spent",
                    value: money(snapshot.spentAmount),
                    icon: "creditcard.fill",
                    tint: .blue
                )

                WidgetMetric(
                    title: "widget.budget.limit",
                    value: snapshot.budgetAmount.map(money) ?? localized("widget.budget.notSet"),
                    icon: snapshot.isSyncedWithIncome ? "arrow.down.circle.fill" : "target",
                    tint: snapshot.isSyncedWithIncome ? .green : .orange
                )

                Label(daysText(snapshot.daysRemaining), systemImage: "calendar")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: 128, alignment: .leading)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetBackground(state: snapshot.state)
        }
    }
}

struct CircularBudgetWidget: View {
    let snapshot: WidgetBudgetSnapshot

    var body: some View {
        Gauge(value: min(max(snapshot.usagePercentage, 0), 1)) {
            Image(systemName: icon(for: snapshot.state))
        } currentValueLabel: {
            Text(percent(snapshot.usagePercentage))
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(widgetTint(for: snapshot.state))
        .widgetLabel {
            Text(snapshot.remainingAmount.map { money(abs($0)) } ?? localized("widget.budget.notSet"))
        }
    }
}

struct RectangularBudgetWidget: View {
    let snapshot: WidgetBudgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label("widget.budget.title", systemImage: icon(for: snapshot.state))
                .font(.caption.weight(.semibold))

            Text(snapshot.remainingAmount == nil ? localized("widget.budget.notSet") : money(abs(snapshot.remainingAmount ?? .zero)))
                .font(.headline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(statusLine(for: snapshot))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct InlineBudgetWidget: View {
    let snapshot: WidgetBudgetSnapshot

    var body: some View {
        Text(inlineText(for: snapshot))
    }
}

struct WidgetHeader: View {
    let state: WidgetBudgetState
    let compact: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon(for: state))
                .font(.system(size: compact ? 12 : 13, weight: .bold))
                .foregroundStyle(widgetTint(for: state))
                .frame(width: compact ? 24 : 28, height: compact ? 24 : 28)
                .background(widgetTint(for: state).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("widget.budget.title")
                    .font((compact ? Font.caption : Font.footnote).weight(.bold))
                    .foregroundStyle(.primary)

                if !compact {
                    Text("widget.budget.subtitle")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

struct WidgetMetric: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }
}

struct BudgetProgressBar: View {
    let progress: Double
    let state: WidgetBudgetState

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.primary.opacity(0.08))

                Capsule()
                    .fill(widgetTint(for: state).gradient)
                    .frame(width: max(8, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 8)
    }
}

struct WidgetBackground: View {
    let state: WidgetBudgetState

    var body: some View {
        LinearGradient(
            colors: [
                widgetTint(for: state).opacity(0.16),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct FintraxBudgetWidget: Widget {
    let kind = WidgetBudgetSnapshotStore.budgetWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FintraxBudgetProvider()) { entry in
            FintraxBudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.budget.configuration.title")
        .description("widget.budget.configuration.description")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct FintraxWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FintraxBudgetWidget()
    }
}

private func icon(for state: WidgetBudgetState) -> String {
    switch state {
    case .noBudget:
        "target"
    case .healthy:
        "checkmark.seal.fill"
    case .attention:
        "exclamationmark.triangle.fill"
    case .overBudget:
        "arrow.up.right.circle.fill"
    }
}

private func widgetTint(for state: WidgetBudgetState) -> Color {
    switch state {
    case .noBudget:
        .blue
    case .healthy:
        .green
    case .attention:
        .orange
    case .overBudget:
        .red
    }
}

private func money(_ amount: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "INR"
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    return formatter.string(from: amount as NSDecimalNumber) ?? "₹0"
}

private func percent(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
}

private func localized(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

private func daysText(_ days: Int) -> String {
    String(format: localized("widget.budget.daysLeft"), days)
}

private func statusLine(for snapshot: WidgetBudgetSnapshot) -> String {
    switch snapshot.state {
    case .noBudget:
        return localized("widget.budget.setupPrompt")
    case .healthy:
        return daysText(snapshot.daysRemaining)
    case .attention:
        return localized("widget.budget.attention")
    case .overBudget:
        return localized("widget.budget.overLimit")
    }
}

private func inlineText(for snapshot: WidgetBudgetSnapshot) -> String {
    guard let remaining = snapshot.remainingAmount else {
        return localized("widget.budget.inlineNotSet")
    }

    let amount = money(abs(remaining))
    if remaining < 0 {
        return String(format: localized("widget.budget.inlineOver"), amount)
    }

    return String(format: localized("widget.budget.inlineLeft"), amount)
}
