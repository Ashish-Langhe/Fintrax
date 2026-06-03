//
//  ConfigurationService.swift
//  Fintrax
//
//  Fintrax documentation: Implements reusable data, export, budget, category, and configuration services for the app.
//

import Foundation

/// Configuration service responsible for app-wide configuration and document directory management
@MainActor
@Observable
class ConfigurationService {
    static let shared = ConfigurationService()
    
    /// The documents directory for JSON file storage
    let documentsDirectory: URL
    
    /// The backup directory for automatic file backups
    let backupDirectory: URL
    
    /// Maximum number of backups to maintain
    let maxBackups: Int = 5
    
    private init() {
        // Get the documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not access documents directory")
        }
        
        self.documentsDirectory = documentsPath
        
        // Create backup subdirectory
        self.backupDirectory = documentsDirectory.appendingPathComponent("backups", isDirectory: true)
        
        // Create directories if they don't exist
        createDirectoriesIfNeeded()
    }
    
    /// Creates the documents and backup directories if they don't exist
    private func createDirectoriesIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: backupDirectory, 
                                                 withIntermediateDirectories: true)
        } catch {
            print("Error creating backup directory: \(error)")
        }
    }
    
    /// Gets the file URL for a specific JSON file name
    /// - Parameter fileName: The name of the JSON file (without extension)
    /// - Returns: The full URL to the file in documents directory
    func documentsURL(for fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent("\(fileName).json")
    }
    
    /// Gets the backup file URL for a specific JSON file
    /// - Parameters:
    ///   - fileName: The name of the original file
    ///   - timestamp: Timestamp for the backup
    /// - Returns: The full URL to the backup file
    func backupURL(for fileName: String, timestamp: Date = Date()) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestampString = formatter.string(from: timestamp)
        
        return backupDirectory.appendingPathComponent("\(fileName)_\(timestampString).json")
    }
    
    /// Gets all backup files for a specific original file
    /// - Parameter originalFileName: The name of the original file
    /// - Returns: Array of backup file URLs sorted by modification date (newest first)
    func getAllBackups(for originalFileName: String) -> [URL] {
        do {
            let backupFiles = try FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey]
            )
            
            let filteredBackups = backupFiles
                .filter { $0.lastPathComponent.hasPrefix("\(originalFileName)_") }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    return date1 > date2
                }
            
            return filteredBackups
        } catch {
            print("Error listing backup files: \(error)")
            return []
        }
    }
    
    /// Cleans up old backup files, keeping only the most recent `maxBackups`
    /// - Parameter originalFileName: The name of the original file to clean up backups for
    func cleanOldBackups(for originalFileName: String) {
        let backups = getAllBackups(for: originalFileName)
        
        // Remove excess backups beyond maxBackups
        if backups.count > maxBackups {
            let backupsToRemove = Array(backups.dropFirst(maxBackups))
            for backup in backupsToRemove {
                do {
                    try FileManager.default.removeItem(at: backup)
                } catch {
                    print("Error removing old backup: \(error)")
                }
            }
        }
    }
    
    /// Get configuration for use with services
    /// - Returns: Configuration object
    func getConfigurationSync() -> JSONDataService.Configuration {
        return JSONDataService.Configuration(
            documentsDirectory: documentsDirectory,
            maxBackups: maxBackups,
            enableBackups: true
        )
    }
    
    /// Get configuration for use with actors
    /// - Returns: Configuration object
    func getConfiguration() async -> JSONDataService.Configuration {
        return getConfigurationSync()
    }
}