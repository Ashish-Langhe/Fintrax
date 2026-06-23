//
//  ExpenseFilterSearchBar.swift
//  Fintrax
//
//  Fintrax documentation: Extracted reusable expense screen components.
//

import SwiftUI
import Foundation

struct FilterAndSearchBar: View {
    @Binding var selectedCategory: UUID?
    @Binding var selectedDateRange: DateRangeOption
    @Binding var searchText: String
    let smartSearchSummary: String?
    @FocusState private var isSearchFocused: Bool
    
    let categories: [Category]
    @Binding var showingFilterSheet: Bool

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDateRange != .allTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSearchFocused ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        (isSearchFocused ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.info)
                            .opacity(isSearchFocused ? 0.14 : 0.10),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Expenses.search)
                        .font(AppDesignSystem.Typography.caption2.weight(.bold))
                        .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)

                    TextField(L10n.Expenses.searchPlaceholder, text: $searchText)
                        .font(AppDesignSystem.Typography.callout)
                        .foregroundStyle(AppDesignSystem.Colors.textPrimary)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                }

                if !searchText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppDesignSystem.Colors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(AppDesignSystem.Colors.surfaceVariant.opacity(0.72), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Expenses.clearSearch)
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.elevatedSurface.opacity(0.92),
                        AppDesignSystem.Colors.surfaceVariant.opacity(0.48)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSearchFocused ? AppDesignSystem.Colors.primary.opacity(0.34) : Color.white.opacity(0.16),
                        lineWidth: isSearchFocused ? 1.1 : 0.8
                    )
            }
            .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 12)
            .shadow(color: AppDesignSystem.Colors.primary.opacity(isSearchFocused ? 0.16 : 0.08), radius: isSearchFocused ? 14 : 10, x: 0, y: 7)

            if let smartSearchSummary, !smartSearchSummary.isEmpty {
                HStack(spacing: 7) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.caption.weight(.bold))
                    Text(smartSearchSummary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(AppDesignSystem.Typography.caption.weight(.semibold))
                .foregroundStyle(AppDesignSystem.Colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppDesignSystem.Colors.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(AppDesignSystem.Colors.primary.opacity(0.16), lineWidth: 1)
                }
            }

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: selectedCategory.flatMap { categoryName(for: $0) } ?? L10n.string("expenses.filter.allCategories"),
                            icon: "folder.fill",
                        isActive: selectedCategory != nil,
                        onTap: {
                            showingFilterSheet = true
                        }
                    )

                        FilterChip(
                            title: selectedDateRange.localizedString,
                            icon: "calendar",
                            isActive: selectedDateRange != .allTime,
                            onTap: {
                                showingFilterSheet = true
                            }
                        )

                        if !searchText.isEmpty {
                            SearchStatusChip(searchText: searchText) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    searchText = ""
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: hasActiveFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease.circle")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(hasActiveFilters ? .white : AppDesignSystem.Colors.primary)
                        .frame(width: 38, height: 38)
                        .background(
                            hasActiveFilters ? AppDesignSystem.Gradients.primary : LinearGradient(colors: [
                                AppDesignSystem.Colors.elevatedSurface.opacity(0.82),
                                AppDesignSystem.Colors.surfaceVariant.opacity(0.52)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(AppDesignSystem.Colors.cardStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Expenses.openFilters)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.elevatedSurface.opacity(0.58),
                    AppDesignSystem.Colors.surfaceVariant.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1)
        }
    }
    
    private func categoryName(for categoryId: UUID?) -> String? {
        guard let categoryId = categoryId else { return nil }
        return categories.first { $0.id == categoryId }?.name
    }
}

private struct SearchStatusChip: View {
    let searchText: String
    let onClear: () -> Void

    var body: some View {
        Button(action: onClear) {
            HStack(spacing: 6) {
                Image(systemName: "text.magnifyingglass")
                    .font(.caption.weight(.bold))
                Text(searchText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2.weight(.bold))
            }
            .font(AppDesignSystem.Typography.caption.weight(.bold))
            .foregroundStyle(AppDesignSystem.Colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 180)
            .background(AppDesignSystem.Colors.primary.opacity(0.11), in: Capsule())
            .overlay(Capsule().stroke(AppDesignSystem.Colors.primary.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Expenses.clearSearchText)
    }
}

/// Filter chip component
struct FilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: isActive ? "checkmark.circle.fill" : icon)
                    .font(.caption.weight(.bold))
                if isActive {
                    Image(systemName: icon)
                        .font(.caption2.weight(.bold))
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isActive ?
                LinearGradient(colors: [Color.blue, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [AppDesignSystem.Colors.controlFill, AppDesignSystem.Colors.surfaceVariant.opacity(0.34)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : AppDesignSystem.Colors.cardStroke, lineWidth: 1)
            )
            .foregroundColor(isActive ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
