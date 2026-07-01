//
//  ExpenseFilterSheet.swift
//  Fintrax
//
//  Fintrax documentation: Extracted reusable expense screen components.
//

import SwiftUI
import Foundation

struct FilterSheet: View {
    @Binding var selectedCategory: UUID?
    @Binding var selectedDateRange: DateRangeOption
    @Binding var sortOption: SortOption
    
    let categories: [Category]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                FintraxTabBackground(style: .expenses)

                ScrollView {
                    VStack(spacing: 18) {
                        filterHero
                        categorySection
                        dateRangeSection
                        sortSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle(L10n.Expenses.filterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        selectedCategory = nil
                        selectedDateRange = .thisMonth
                        sortOption = .dateDescending
                    } label: {
                        Text(L10n.Expenses.reset)
                    }
                    .disabled(!hasActiveFilters)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(L10n.Expenses.done)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private var filterHero: some View {
        HStack(spacing: 14) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [.blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Expenses.refine)
                    .font(.headline)
                Text(activeSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(18)
        .filterSheetCard()
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: L10n.Expenses.category, icon: "folder.fill", tint: .blue)

            LazyVStack(spacing: 10) {
                FilterSelectionRow(
                    title: L10n.string("expenses.filter.allCategories"),
                    subtitle: L10n.string("expenses.filter.showEveryExpense"),
                    icon: "square.grid.2x2.fill",
                    tint: .blue,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories) { category in
                    FilterSelectionRow(
                        title: category.name,
                        subtitle: L10n.format(L10n.Expenses.filterByCategory, category.name),
                        icon: "tag.fill",
                        tint: category.displayColor,
                        isSelected: selectedCategory == category.id
                    ) {
                        selectedCategory = category.id
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: L10n.Expenses.dateRange, icon: "calendar", tint: .teal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(DateRangeOption.allCases) { option in
                    FilterOptionChip(
                        title: option.localizedString,
                        icon: option == .allTime ? "clock.arrow.circlepath" : "calendar.badge.clock",
                        tint: .teal,
                        isSelected: selectedDateRange == option
                    ) {
                        selectedDateRange = option
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterSheetSectionHeader(title: L10n.Expenses.sortBy, icon: "arrow.up.arrow.down", tint: .orange)

            LazyVStack(spacing: 10) {
                ForEach(SortOption.allCases) { option in
                    FilterSelectionRow(
                        title: option.localizedString,
                        subtitle: sortSubtitle(for: option),
                        icon: sortIcon(for: option),
                        tint: .orange,
                        isSelected: sortOption == option
                    ) {
                        sortOption = option
                    }
                }
            }
        }
        .padding(18)
        .filterSheetCard()
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDateRange != .thisMonth || sortOption != .dateDescending
    }

    private var activeSummary: String {
        var parts: [String] = []
        parts.append(selectedCategoryName)
        parts.append(selectedDateRange.localizedString)
        parts.append(sortOption.localizedString)
        return parts.joined(separator: " • ")
    }

    private var selectedCategoryName: String {
        guard let selectedCategory else { return L10n.string("expenses.filter.allCategories") }
        return categories.first { $0.id == selectedCategory }?.name ?? L10n.string(L10n.Expenses.selectedCategory)
    }

    private func sortIcon(for option: SortOption) -> String {
        switch option {
        case .dateDescending, .dateAscending:
            return "calendar"
        case .amountDescending, .amountAscending:
            return "indianrupeesign.circle.fill"
        case .titleAscending, .titleDescending:
            return "textformat"
        }
    }

    private func sortSubtitle(for option: SortOption) -> String {
        switch option {
        case .dateDescending:
            return L10n.string("expenses.sortSubtitle.newest")
        case .dateAscending:
            return L10n.string("expenses.sortSubtitle.oldest")
        case .amountDescending:
            return L10n.string("expenses.sortSubtitle.highestAmount")
        case .amountAscending:
            return L10n.string("expenses.sortSubtitle.lowestAmount")
        case .titleAscending:
            return L10n.string("expenses.sortSubtitle.aToZ")
        case .titleDescending:
            return L10n.string("expenses.sortSubtitle.zToA")
        }
    }
}

private struct FilterSheetSectionHeader: View {
    let title: LocalizedStringKey
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.headline)

            Spacer()
        }
    }
}

private struct FilterSelectionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : tint)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? tint : .secondary.opacity(0.45))
            }
            .padding(12)
            .background(AppDesignSystem.Colors.controlFill.opacity(isSelected ? 1 : 0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.42) : AppDesignSystem.Colors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FilterOptionChip: View {
    let title: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : tint)
                        .frame(width: 32, height: 32)
                        .background(isSelected ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tint)
                    }
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppDesignSystem.Colors.controlFill.opacity(isSelected ? 1 : 0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.42) : AppDesignSystem.Colors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func filterSheetCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .fintraxSurface(cornerRadius: cornerRadius, accent: AppDesignSystem.Colors.primary)
    }
}
