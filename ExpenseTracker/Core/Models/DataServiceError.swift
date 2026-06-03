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
            return "Failed to read data: \(message)"
        case .writeError(let message):
            return "Failed to save data: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .constraintViolation(let message):
            return "Constraint violation: \(message)"
        case .backupError(let message):
            return "Backup error: \(message)"
        case .fileAccessError(let message):
            return "File access error: \(message)"
        case .deleteError(let message):
            return "Delete error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .readError, .writeError, .backupError:
            return "Please check available storage space and try again"
        case .fileAccessError:
            return "Please ensure the app has permission to access files"
        case .validationError:
            return "Please check your input and try again"
        case .constraintViolation:
            return "Please review your data and try a different value"
        case .notFound:
            return "The requested data could not be found"
        case .deleteError:
            return "Please check file permissions and try again"
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
            return "Export failed: \(message)"
        case .formatError(let message):
            return "Format error: \(message)"
        case .fileAccessError(let message):
            return "File access error: \(message)"
        case .emptyDataSet:
            return "No data available to export"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .exportFailed:
            return "Please try again with a smaller date range"
        case .formatError:
            return "Please check your data and try again"
        case .fileAccessError:
            return "Please ensure the app has permission to save files"
        case .emptyDataSet:
            return "Please add expenses before exporting"
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
            return "Authentication failed: \(message)"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .pinSetupFailed(let message):
            return "PIN setup failed: \(message)"
        case .securityRemovalFailed(let message):
            return "Failed to remove security: \(message)"
        case .pinMismatch:
            return "PIN codes do not match"
        case .tooManyAttempts:
            return "Too many failed authentication attempts"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please try again or use alternative authentication method"
        case .biometricsNotAvailable:
            return "Please use PIN authentication instead"
        case .pinSetupFailed:
            return "Please choose a different PIN"
        case .securityRemovalFailed:
            return "Please try again or restart the app"
        case .pinMismatch:
            return "Please ensure both PIN entries match"
        case .tooManyAttempts:
            return "Please wait before trying again"
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
            return "Duplicate entry: \(message)"
        case .invalidReference(let message):
            return "Invalid reference: \(message)"
        case .circularReference(let message):
            return "Circular reference: \(message)"
        case .integrityViolation(let message):
            return "Data integrity violation: \(message)"
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
            return "Request timed out"
        case .noConnection:
            return "No internet connection"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Authentication required"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .timeout, .noConnection:
            return "Please check your internet connection"
        case .serverError:
            return "Please try again later"
        case .invalidResponse:
            return "Please try again"
        case .unauthorized:
            return "Please log in again"
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
            return "An unexpected error occurred"
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unknown, .custom:
            return "Please try again or contact support"
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