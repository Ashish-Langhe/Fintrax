//
//  Category.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

/// Represents an expense category
struct Category: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var iconName: String
    var colorName: String
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconName
        case colorName
        case isDefault
        case createdAt
        case updatedAt
    }
    
    /// Initialize a new category
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: Category name
    ///   - isDefault: Whether this is a default category that can't be deleted
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "tag.fill",
        colorName: String = "blue",
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.iconName = iconName
        self.colorName = colorName
        self.isDefault = isDefault
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedName = try container.decode(String.self, forKey: .name)
        let presentation = Self.defaultPresentation(for: decodedName)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = decodedName.trimmingCharacters(in: .whitespacesAndNewlines)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? presentation.iconName
        colorName = try container.decodeIfPresent(String.self, forKey: .colorName) ?? presentation.colorName
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? presentation.isDefault
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    private static func defaultPresentation(for name: String) -> (iconName: String, colorName: String, isDefault: Bool) {
        guard let definition = DefaultCategoryDefinitions.first(where: {
            $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }) else {
            return ("tag.fill", "blue", false)
        }

        return (definition.iconName, definition.colorName, true)
    }
    
    /// Validate the category data
    /// - Returns: Validation result with error message if invalid
    func validate() -> ValidationResult {
        // Name validation
        if name.isEmpty {
            return ValidationResult(isValid: false, error: "Category name cannot be empty")
        }
        
        if name.count > 50 {
            return ValidationResult(isValid: false, error: "Category name cannot exceed 50 characters")
        }

        if iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ValidationResult(isValid: false, error: "Category icon cannot be empty")
        }
        
        return ValidationResult(isValid: true)
    }
    
    /// Update the category name
    /// - Parameter newName: The new name for the category
    mutating func updateName(_ newName: String) throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create temporary category for validation
        var tempCategory = self
        tempCategory.name = trimmedName
        
        let validation = tempCategory.validate()
        guard validation.isValid else {
            throw CategoryValidationError.invalidName(validation.error ?? "Invalid name")
        }
        
        // Default categories cannot be renamed
        if isDefault {
            throw CategoryValidationError.cannotRenameDefault
        }
        
        self.name = trimmedName
        self.updatedAt = Date()
    }

    mutating func updateDetails(name: String, iconName: String, colorName: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIcon = iconName.trimmingCharacters(in: .whitespacesAndNewlines)

        var tempCategory = self
        tempCategory.name = trimmedName
        tempCategory.iconName = trimmedIcon
        tempCategory.colorName = colorName

        let validation = tempCategory.validate()
        guard validation.isValid else {
            throw CategoryValidationError.invalidName(validation.error ?? "Invalid category")
        }

        self.name = trimmedName
        self.iconName = trimmedIcon
        self.colorName = colorName
        self.updatedAt = Date()
    }
    
    /// Check if this category can be deleted
    /// - Parameter expensesCount: Number of expenses associated with this category
    /// - Returns: Whether the category can be deleted and error message if not
    func canDelete(expensesCount: Int) -> (canDelete: Bool, reason: String?) {
        if isDefault {
            return (false, "Default categories cannot be deleted")
        }
        
        if expensesCount > 0 {
            return (false, "Cannot delete category with \(expensesCount) associated expense(s)")
        }
        
        return (true, nil)
    }
}

/// Category-specific errors
enum CategoryValidationError: LocalizedError, Sendable {
    case invalidName(String)
    case cannotRenameDefault
    case cannotDeleteDefault
    
    var errorDescription: String? {
        switch self {
        case .invalidName(let message):
            return message
        case .cannotRenameDefault:
            return "Default categories cannot be renamed"
        case .cannotDeleteDefault:
            return "Default categories cannot be deleted"
        }
    }
}

// MARK: - Sample Data for Testing
extension Category {
    /// Creates sample categories for testing and previews
    static func sampleCategories() -> [Category] {
        DefaultCategoryDefinitions.map { definition in
            Category(
                id: UUID(),
                name: definition.name,
                iconName: definition.iconName,
                colorName: definition.colorName,
                isDefault: true
            )
        } + [
            Category(id: UUID(), name: "Travel", iconName: "airplane", colorName: "cyan", isDefault: false),
            Category(id: UUID(), name: "Education", iconName: "book.fill", colorName: "purple", isDefault: false),
        ]
    }
}

struct DefaultCategoryDefinition: Sendable {
    let name: String
    let iconName: String
    let colorName: String
}

let DefaultCategoryDefinitions: [DefaultCategoryDefinition] = [
    DefaultCategoryDefinition(name: "Food", iconName: "fork.knife", colorName: "orange"),
    DefaultCategoryDefinition(name: "Transportation", iconName: "car.fill", colorName: "blue"),
    DefaultCategoryDefinition(name: "Entertainment", iconName: "tv.fill", colorName: "purple"),
    DefaultCategoryDefinition(name: "Utilities", iconName: "bolt.fill", colorName: "yellow"),
    DefaultCategoryDefinition(name: "Health", iconName: "heart.fill", colorName: "red"),
    DefaultCategoryDefinition(name: "Shopping", iconName: "bag.fill", colorName: "pink"),
    DefaultCategoryDefinition(name: "Other", iconName: "ellipsis.circle.fill", colorName: "gray")
]
