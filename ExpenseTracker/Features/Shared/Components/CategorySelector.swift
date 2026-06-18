//
//  CategorySelector.swift
//  Fintrax
//
//  Fintrax documentation: Defines shared SwiftUI components, modifiers, design tokens, and validation utilities.
//

import SwiftUI

/// Category selector view
struct CategorySelectorView: View {
    @Binding var selectedCategoryID: UUID?
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let categories: [Category]
    let allowCustomCategories: Bool
    let includeAllCategoriesOption: Bool
    
    init(
        selectedCategoryID: Binding<UUID?>,
        categories: [Category] = [],
        allowCustomCategories: Bool = true,
        includeAllCategoriesOption: Bool = true
    ) {
        self._selectedCategoryID = selectedCategoryID
        self.categories = categories
        self.allowCustomCategories = allowCustomCategories
        self.includeAllCategoriesOption = includeAllCategoriesOption
    }
    
    var body: some View {
        List {
            if includeAllCategoriesOption {
                Section {
                    Button(action: {
                        selectedCategoryID = nil
                    }) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            Text(L10n.Expenses.allCategories)
                            Spacer()
                            if selectedCategoryID == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            if categories.isEmpty {
                Section {
                    ContentUnavailableView(
                        L10n.Expenses.noCategoriesTitle,
                        systemImage: "tag",
                        description: Text(L10n.Expenses.noCategoriesDescription)
                    )
                }
            } else {
                Section {
                    ForEach(categories) { category in
                        CategoryRow(
                            category: category,
                            isSelected: selectedCategoryID == category.id,
                            onTap: {
                                selectedCategoryID = category.id
                            },
                            dismissOnSelect: !includeAllCategoriesOption
                        )
                    }
                }
            }
            
            if allowCustomCategories {
                Section {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(L10n.Expenses.addNewCategory)
                            Spacer()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle(L10n.Expenses.selectCategoryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .fintraxModal(
            isPresented: showingAddCategory,
            title: L10n.string(L10n.Expenses.addCategory),
            message: L10n.string(L10n.Expenses.addCategoryMessage),
            icon: "tag.fill",
            tint: AppDesignSystem.Colors.primary,
            primaryAction: FintraxModalAction(title: L10n.string(L10n.Expenses.addCategory), icon: "plus", tint: AppDesignSystem.Colors.primary) {
                addCategory()
            },
            secondaryAction: FintraxModalAction(title: L10n.string("expenses.cancel"), icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
                showingAddCategory = false
                newCategoryName = ""
            },
            textFieldPlaceholder: L10n.string(L10n.Expenses.categoryNamePlaceholder),
            textFieldValue: $newCategoryName
        )
        .fintraxModal(
            isPresented: showingAlert,
            title: L10n.string("expenses.common.category"),
            message: alertMessage,
            icon: "exclamationmark.triangle.fill",
            tint: AppDesignSystem.Colors.warning,
            primaryAction: FintraxModalAction(title: L10n.string(L10n.Expenses.gotIt), icon: "checkmark", tint: AppDesignSystem.Colors.primary) {
                showingAlert = false
            }
        )
    }
    
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = L10n.string(L10n.Expenses.categoryNameEmpty)
            showingAlert = true
            return
        }
        
        guard trimmedName.count <= 50 else {
            alertMessage = L10n.format(L10n.Expenses.categoryNameTooLong, 50)
            showingAlert = true
            return
        }
        
        // Check for duplicates
        if categories.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = L10n.string(L10n.Expenses.categoryDuplicate)
            showingAlert = true
            return
        }
        
        // In a real app, you would create the category here
        // For now, just simulate it
        alertMessage = L10n.string(L10n.Expenses.categoryCreatePlaceholder)
        showingAddCategory = false
        showingAlert = true
        newCategoryName = ""
    }
}

/// Category row component
struct CategoryRow: View {
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    var dismissOnSelect: Bool = false
    
    var body: some View {
        Button(action: {
            onTap()
            if dismissOnSelect {
                dismiss()
            }
        }) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if category.isDefault {
                        Text(L10n.Expenses.defaultCategory)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }
}

/// Simple category selector (non-navigation view)
struct SimpleCategorySelector: View {
    @Binding var selectedCategoryID: UUID?
    @State private var expanded = false
    
    let categories: [Category]
    let placeholder: String
    
    init(selectedCategoryID: Binding<UUID?>, categories: [Category] = [], placeholder: String = L10n.string(L10n.Expenses.selectCategory)) {
        self._selectedCategoryID = selectedCategoryID
        self.categories = categories
        self.placeholder = placeholder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let selectedCategory = categories.first(where: { $0.id == selectedCategoryID }) {
                selectedCategoryView(selectedCategory)
            } else {
                placeholderView()
            }
            
            if expanded {
                Divider()
                categoryList
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .onTapGesture {
            expanded.toggle()
        }
    }
    
    private func placeholderView() -> some View {
        HStack {
            Image(systemName: "tag")
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(placeholder)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(expanded ? 180 : 0))
                .animation(.easeInOut(duration: 0.2), value: expanded)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func selectedCategoryView(_ category: Category) -> some View {
        HStack {
            Image(systemName: category.iconName)
                .foregroundColor(category.color)
                .frame(width: 24)
            
            Text(category.name)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(expanded ? 180 : 0))
                .animation(.easeInOut(duration: 0.2), value: expanded)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var categoryList: some View {
        ForEach(categories) { category in
            CategoryRow(
                category: category,
                isSelected: selectedCategoryID == category.id,
                onTap: {
                    selectedCategoryID = category.id
                    expanded = false
                }
            )
        }
    }
}

#Preview {
    CategorySelectorPreview()
}

private struct CategorySelectorPreview: View {
    @State private var selectedCategoryID: UUID?
    @State private var showingFullSelector = false
    
    let categories = Category.sampleCategories()
    
    var body: some View {
        VStack(spacing: 20) {
            // Simple selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Simple Category Selector")
                    .font(.headline)
                
                SimpleCategorySelector(
                    selectedCategoryID: $selectedCategoryID,
                    categories: categories
                )
            }
            .padding()
            
            // Full selector button
            Button("Show Full Category Selector") {
                showingFullSelector = true
            }
            .sheet(isPresented: $showingFullSelector) {
                CategorySelectorView(
                    selectedCategoryID: $selectedCategoryID,
                    categories: categories
                )
            }
            
            Spacer()
        }
        .padding()
    }
}
