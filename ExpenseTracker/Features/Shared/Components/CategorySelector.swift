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
                            
                            Text("All Categories")
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
                        "No Categories",
                        systemImage: "tag",
                        description: Text("Categories could not be loaded. Go back and try again.")
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
                            
                            Text("Add New Category")
                            Spacer()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
        .fintraxModal(
            isPresented: showingAddCategory,
            title: "Add Category",
            message: "Enter a short category name. You can edit icon and color from the Categories tab.",
            icon: "tag.fill",
            tint: AppDesignSystem.Colors.primary,
            primaryAction: FintraxModalAction(title: "Add Category", icon: "plus", tint: AppDesignSystem.Colors.primary) {
                addCategory()
            },
            secondaryAction: FintraxModalAction(title: "Cancel", icon: "xmark", tint: AppDesignSystem.Colors.textSecondary) {
                showingAddCategory = false
                newCategoryName = ""
            },
            textFieldPlaceholder: "Category Name",
            textFieldValue: $newCategoryName
        )
        .fintraxModal(
            isPresented: showingAlert,
            title: "Category",
            message: alertMessage,
            icon: "exclamationmark.triangle.fill",
            tint: AppDesignSystem.Colors.warning,
            primaryAction: FintraxModalAction(title: "Got It", icon: "checkmark", tint: AppDesignSystem.Colors.primary) {
                showingAlert = false
            }
        )
    }
    
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Category name cannot be empty"
            showingAlert = true
            return
        }
        
        guard trimmedName.count <= 50 else {
            alertMessage = "Category name cannot exceed 50 characters"
            showingAlert = true
            return
        }
        
        // Check for duplicates
        if categories.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "A category with this name already exists"
            showingAlert = true
            return
        }
        
        // In a real app, you would create the category here
        // For now, just simulate it
        alertMessage = "Feature to create new categories would be implemented here"
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
                        Text("Default category")
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
    
    init(selectedCategoryID: Binding<UUID?>, categories: [Category] = [], placeholder: String = "Select Category") {
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
