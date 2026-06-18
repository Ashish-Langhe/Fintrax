//
//  DataServiceError.swift
//  Fintrax
//
//  Fintrax documentation: Defines Fintrax domain models and value types used across persistence, UI, and business logic.
//

import Foundation

/// Data service errors for JSON file operations
enum DataServiceError: LocalizedError, Equatable, Sendable {
    case readError(String)
    case writeError(String)
    case notFound(String)
    case validationError(String)
    case constraintViolation(String)
    case backupError(String)
    case fileAccessError(String)
    case deleteError(String)
    
    var errorDescription: String? {
        switch self {
        case .readError(let message):
            return L10n.format("error.data.read", message)
        case .writeError(let message):
            return L10n.format("error.data.write", message)
        case .notFound(let message):
            return L10n.format("error.data.notFound", message)
        case .validationError(let message):
            return L10n.format("error.data.validation", message)
        case .constraintViolation(let message):
            return L10n.format("error.data.constraint", message)
        case .backupError(let message):
            return L10n.format("error.data.backup", message)
        case .fileAccessError(let message):
            return L10n.format("error.data.fileAccess", message)
        case .deleteError(let message):
            return L10n.format("error.data.delete", message)
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .readError, .writeError, .backupError:
            return L10n.string("Please check available storage space and try again")
        case .fileAccessError:
            return L10n.string("Please ensure the app has permission to access files")
        case .validationError:
            return L10n.string("Please check your input and try again")
        case .constraintViolation:
            return L10n.string("Please review your data and try a different value")
        case .notFound:
            return L10n.string("The requested data could not be found")
        case .deleteError:
            return L10n.string("Please check file permissions and try again")
        }
    }
}

/// Export service errors
enum ExportError: LocalizedError, Equatable, Sendable {
    case exportFailed(String)
    case formatError(String)
    case fileAccessError(String)
    case emptyDataSet
    
    var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return L10n.format("error.export.failed", message)
        case .formatError(let message):
            return L10n.format("error.export.format", message)
        case .fileAccessError(let message):
            return L10n.format("error.data.fileAccess", message)
        case .emptyDataSet:
            return L10n.string("No data available to export")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .exportFailed:
            return L10n.string("Please try again with a smaller date range")
        case .formatError:
            return L10n.string("Please check your data and try again")
        case .fileAccessError:
            return L10n.string("Please ensure the app has permission to save files")
        case .emptyDataSet:
            return L10n.string("Please add expenses before exporting")
        }
    }
}

/// Security service errors
enum SecurityError: LocalizedError, Equatable, Sendable {
    case authenticationFailed(String)
    case biometricsNotAvailable
    case pinSetupFailed(String)
    case securityRemovalFailed(String)
    case pinMismatch
    case tooManyAttempts
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return L10n.format("error.security.authenticationFailed", message)
        case .biometricsNotAvailable:
            return L10n.string("Biometric authentication is not available on this device")
        case .pinSetupFailed(let message):
            return L10n.format("error.security.pinSetupFailed", message)
        case .securityRemovalFailed(let message):
            return L10n.format("error.security.removalFailed", message)
        case .pinMismatch:
            return L10n.string("PIN codes do not match")
        case .tooManyAttempts:
            return L10n.string("Too many failed authentication attempts")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return L10n.string("Please try again or use alternative authentication method")
        case .biometricsNotAvailable:
            return L10n.string("Please use PIN authentication instead")
        case .pinSetupFailed:
            return L10n.string("Please choose a different PIN")
        case .securityRemovalFailed:
            return L10n.string("Please try again or restart the app")
        case .pinMismatch:
            return L10n.string("Please ensure both PIN entries match")
        case .tooManyAttempts:
            return L10n.string("Please wait before trying again")
        }
    }
}

/// Database/entity errors
enum EntityError: LocalizedError, Equatable, Sendable {
    case duplicate(String)
    case invalidReference(String)
    case circularReference(String)
    case integrityViolation(String)
    
    var errorDescription: String? {
        switch self {
        case .duplicate(let message):
            return L10n.format("error.entity.duplicate", message)
        case .invalidReference(let message):
            return L10n.format("error.entity.invalidReference", message)
        case .circularReference(let message):
            return L10n.format("error.entity.circularReference", message)
        case .integrityViolation(let message):
            return L10n.format("error.entity.integrityViolation", message)
        }
    }
}

/// Network/connectivity errors (for future use)
enum NetworkError: LocalizedError, Equatable, Sendable {
    case timeout
    case noConnection
    case serverError(Int)
    case invalidResponse
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return L10n.string("Request timed out")
        case .noConnection:
            return L10n.string("No internet connection")
        case .serverError(let code):
            return L10n.format("error.network.server", code)
        case .invalidResponse:
            return L10n.string("Invalid server response")
        case .unauthorized:
            return L10n.string("Authentication required")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .timeout, .noConnection:
            return L10n.string("Please check your internet connection")
        case .serverError:
            return L10n.string("Please try again later")
        case .invalidResponse:
            return L10n.string("Please try again")
        case .unauthorized:
            return L10n.string("Please log in again")
        }
    }
}

/// General application errors
enum AppError: LocalizedError, Sendable {
    case unknown(Error)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return L10n.string("An unexpected error occurred")
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unknown, .custom:
            return L10n.string("Please try again or contact support")
        }
    }
}

// MARK: - Error Helpers
extension Error {
    /// Convert any error to a user-friendly AppError
    func toAppError() -> AppError {
        if let dataServiceError = self as? DataServiceError {
            return .custom(dataServiceError.localizedDescription)
        } else if let exportError = self as? ExportError {
            return .custom(exportError.localizedDescription)
        } else if let securityError = self as? SecurityError {
            return .custom(securityError.localizedDescription)
        } else {
            return .unknown(self)
        }
    }
}

// MARK: - Error Logging
struct ErrorLogger {
    /// Log errors for debugging
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Additional context about where the error occurred
    static func log(_ error: Error, context: String = "") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let contextInfo = context.isEmpty ? "" : " [Context: \(context)]"
        print("[\(timestamp)] Error\(contextInfo): \(error.localizedDescription)")
    }
}
