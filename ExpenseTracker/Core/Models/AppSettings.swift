//
//  AppSettings.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

/// Represents app-wide settings
struct AppSettings: Codable, Sendable {
    var theme: ThemeOption
    var language: AppLanguage
    var securityEnabled: Bool
    var securityType: SecurityType
    var exportDateRange: DateRangeOption

    enum CodingKeys: String, CodingKey {
        case theme
        case language
        case securityEnabled
        case securityType
        case exportDateRange
    }
    
    /// Initialize with default settings
    init() {
        self.theme = .system
        self.language = .system
        self.securityEnabled = false
        self.securityType = .none
        self.exportDateRange = .allTime
    }
    
    /// Initialize with custom settings
    /// - Parameters:
    ///   - theme: Theme preference
    ///   - securityEnabled: Whether security is enabled
    ///   - securityType: Type of security authentication
    ///   - exportDateRange: Default date range for exports
    init(
        theme: ThemeOption,
        language: AppLanguage = .system,
        securityEnabled: Bool,
        securityType: SecurityType,
        exportDateRange: DateRangeOption = .allTime
    ) {
        self.theme = theme
        self.language = language
        self.securityEnabled = securityEnabled
        self.securityType = securityType
        self.exportDateRange = exportDateRange
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        theme = try container.decodeIfPresent(ThemeOption.self, forKey: .theme) ?? .system
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        securityEnabled = try container.decodeIfPresent(Bool.self, forKey: .securityEnabled) ?? false
        securityType = try container.decodeIfPresent(SecurityType.self, forKey: .securityType) ?? .none
        exportDateRange = try container.decodeIfPresent(DateRangeOption.self, forKey: .exportDateRange) ?? .allTime
    }
    
    /// Enable security with specified type
    /// - Parameter type: Security type to enable
    mutating func enableSecurity(type: SecurityType) throws {
        guard type != .none else {
            throw AppSettingsError.invalidSecurityType
        }
        
        self.securityEnabled = true
        self.securityType = type
    }
    
    /// Disable security
    mutating func disableSecurity() {
        self.securityEnabled = false
        self.securityType = .none
    }
    
    /// Update theme preference
    /// - Parameter theme: New theme preference
    mutating func updateTheme(_ theme: ThemeOption) {
        self.theme = theme
    }

    /// Update language preference
    /// - Parameter language: New app language preference
    mutating func updateLanguage(_ language: AppLanguage) {
        self.language = language
    }
    
    /// Update default export date range
    /// - Parameter dateRange: New default date range
    mutating func updateExportDateRange(_ dateRange: DateRangeOption) {
        self.exportDateRange = dateRange
    }
    
    /// Validate settings consistency
    /// - Returns: Whether settings are valid
    func validate() -> Bool {
        // If security is enabled, security type should not be none
        if securityEnabled && securityType == .none {
            return false
        }
        
        // If security is disabled, security type should be none
        if !securityEnabled && securityType != .none {
            return false
        }
        
        return true
    }
}

/// App settings specific errors
enum AppSettingsError: LocalizedError, Sendable {
    case invalidSecurityType
    case inconsistentSettings
    
    var errorDescription: String? {
        switch self {
        case .invalidSecurityType:
            return "Invalid security type for enabling security"
        case .inconsistentSettings:
            return "Inconsistent settings configuration"
        }
    }
}

// MARK: - Settings Persistence Helper
class SettingsManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        static let theme = "appTheme"
        static let language = "appLanguage"
        static let securityEnabled = "securityEnabled"
        static let securityType = "securityType"
        static let exportDateRange = "exportDateRange"
    }
    
    /// Current app settings
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    /// Initialize settings manager
    init() {
        self.settings = Self.loadSettings()
    }
    
    /// Load settings from UserDefaults
    /// - Returns: Loaded app settings or defaults
    private static func loadSettings() -> AppSettings {
        let userDefaults = UserDefaults.standard
        
        let theme = ThemeOption(rawValue: userDefaults.string(forKey: Keys.theme) ?? ThemeOption.system.rawValue) ?? .system
        let language = AppLanguage(rawValue: userDefaults.string(forKey: Keys.language) ?? AppLanguage.system.rawValue) ?? .system
        let securityEnabled = userDefaults.bool(forKey: Keys.securityEnabled)
        let securityType = SecurityType(rawValue: userDefaults.string(forKey: Keys.securityType) ?? "None") ?? .none
        let exportDateRange = DateRangeOption(rawValue: userDefaults.string(forKey: Keys.exportDateRange) ?? "All Time") ?? .allTime
        
        return AppSettings(
            theme: theme,
            language: language,
            securityEnabled: securityEnabled,
            securityType: securityType,
            exportDateRange: exportDateRange
        )
    }
    
    /// Save settings to UserDefaults
    private func saveSettings() {
        userDefaults.set(settings.theme.rawValue, forKey: Keys.theme)
        userDefaults.set(settings.language.rawValue, forKey: Keys.language)
        userDefaults.set(settings.securityEnabled, forKey: Keys.securityEnabled)
        userDefaults.set(settings.securityType.rawValue, forKey: Keys.securityType)
        userDefaults.set(settings.exportDateRange.rawValue, forKey: Keys.exportDateRange)
    }
    
    /// Enable security with specified type
    /// - Parameter type: Security type to enable
    func enableSecurity(type: SecurityType) throws {
        try settings.enableSecurity(type: type)
    }
    
    /// Disable security
    func disableSecurity() {
        settings.disableSecurity()
    }
    
    /// Update theme preference
    /// - Parameter theme: New theme preference
    func updateTheme(_ theme: ThemeOption) {
        settings.updateTheme(theme)
    }

    /// Update language preference
    /// - Parameter language: New app language preference
    func updateLanguage(_ language: AppLanguage) {
        settings.updateLanguage(language)
    }
}

// MARK: - Sample Data for Testing
extension AppSettings {
    /// Creates sample settings for testing and previews
    static func sampleSettings() -> AppSettings {
        AppSettings(
            theme: .system,
            securityEnabled: false,
            securityType: .none,
            exportDateRange: .allTime
        )
    }
    
    /// Creates settings with security enabled for testing
    static func secureSampleSettings() -> AppSettings {
        AppSettings(
            theme: .dark,
            securityEnabled: true,
            securityType: .biometrics,
            exportDateRange: .thisMonth
        )
    }
}
