//
//  InspectionDirectoryManager.swift
//  MaterialsAndPractices
//
//  Manages the three-tier inspection directory structure for template organization,
//  working copies, and completed inspections. Provides file operations for the
//  inspection workflow with audit trail integration.
//
//  Created by GitHub Copilot on 12/19/24.
//

import Foundation
import CryptoKit

/// Manages inspection directories and file operations
/// Provides centralized access to inspection template management and file system operations
class InspectionDirectoryManager {
    
    // MARK: - Constants
    
    /// Directory names for the inspection system
    enum DirectoryName: String, CaseIterable {
        case templates = "InspectionTemplates"
        case working = "WorkingInspectionTemplates"
        case completed = "CompletedInspectionTemplates"
        
        var displayName: String {
            switch self {
            case .templates:
                return "Template Masters"
            case .working:
                return "Working Templates"
            case .completed:
                return "Completed Inspections"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = InspectionDirectoryManager()
    
    /// Base documents directory
    private let documentsDirectory: URL
    
    /// Base inspection directory
    private let inspectionBaseDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        inspectionBaseDirectory = documentsDirectory.appendingPathComponent("Inspections")
        
        // Ensure base directory exists
        createInspectionDirectories()
    }
    
    // MARK: - Directory Management
    
    /// Creates all required inspection directories if they don't exist
    private func createInspectionDirectories() {
        let fileManager = FileManager.default
        
        // Create base inspection directory
        if !fileManager.fileExists(atPath: inspectionBaseDirectory.path) {
            do {
                try fileManager.createDirectory(at: inspectionBaseDirectory, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created base inspection directory: \(inspectionBaseDirectory.path)")
            } catch {
                print("❌ Error creating inspection directory: \(error)")
            }
        }
        
        // Create all subdirectories
        for directory in DirectoryName.allCases {
            let directoryURL = directoryURL(for: directory)
            if !fileManager.fileExists(atPath: directoryURL.path) {
                do {
                    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                    print("✅ Created \(directory.displayName) directory: \(directoryURL.path)")
                } catch {
                    print("❌ Error creating \(directory.displayName) directory: \(error)")
                }
            }
        }
    }
    
    /// Returns the URL for a specific inspection directory
    /// - Parameter directory: The directory type
    /// - Returns: URL for the directory
    func directoryURL(for directory: DirectoryName) -> URL {
        return inspectionBaseDirectory.appendingPathComponent(directory.rawValue)
    }
    
    // MARK: - Template Management
    
    /// Copies a template from templates to working directory
    /// - Parameters:
    ///   - templateName: Name of the template file
    ///   - newName: Name for the working copy
    /// - Returns: URL of the copied working template
    func copyTemplateToWorking(templateName: String, newName: String) throws -> URL {
        let sourceURL = directoryURL(for: .templates).appendingPathComponent("\(templateName).md")
        let destinationURL = directoryURL(for: .working).appendingPathComponent("\(newName).md")
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw InspectionError.templateNotFound(templateName)
        }
        
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        print("✅ Copied template '\(templateName)' to working directory as '\(newName)'")
        
        return destinationURL
    }
    
    /// Creates a new inspection from a working template
    /// - Parameters:
    ///   - workingTemplateName: Name of the working template
    ///   - inspectionData: Data to populate the inspection
    /// - Returns: Information about the created inspection
    func createInspectionFromWorkingTemplate(
        workingTemplateName: String,
        inspectionData: InspectionCreationData
    ) throws -> CreatedInspectionInfo {
        let workingTemplateURL = directoryURL(for: .working).appendingPathComponent("\(workingTemplateName).md")
        
        guard FileManager.default.fileExists(atPath: workingTemplateURL.path) else {
            throw InspectionError.workingTemplateNotFound(workingTemplateName)
        }
        
        // Generate filename for completed inspection
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let guid = UUID().uuidString.prefix(8).lowercased()
        let fileName = "\(dateString)_\(workingTemplateName)_\(guid).md"
        
        let completedURL = directoryURL(for: .completed).appendingPathComponent(fileName)
        
        // Read working template
        let templateContent = try String(contentsOf: workingTemplateURL)
        
        // Populate template with inspection data
        let populatedContent = populateTemplate(templateContent, with: inspectionData)
        
        // Write completed inspection
        try populatedContent.write(to: completedURL, atomically: true, encoding: .utf8)
        
        // Generate hash for audit trail
        let contentData = populatedContent.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: contentData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        let createdInfo = CreatedInspectionInfo(
            id: UUID(),
            fileName: fileName,
            filePath: completedURL.path,
            fileHash: hashString,
            shortHash: String(hashString.prefix(8)),
            longHash: hashString,
            inspectionData: inspectionData
        )
        
        print("✅ Created inspection: \(fileName)")
        return createdInfo
    }
    
    /// Populates a template with inspection data
    /// - Parameters:
    ///   - template: The template content
    ///   - data: The inspection data
    /// - Returns: Populated template content
    private func populateTemplate(_ template: String, with data: InspectionCreationData) -> String {
        var content = template
        
        // Add inspection header
        let headerSection = """
        
        # Inspection Header
        **Inspection ID:** \(data.inspectionId?.uuidString ?? UUID().uuidString)
        **Date:** \(DateFormatter.mediumDate.string(from: Date()))
        **Time:** \(data.scheduledTime)
        **Inspector(s):** \(data.inspectorNames.joined(separator: ", "))
        **Team:** \(data.teamName ?? "N/A")
        **Category:** \(data.category)
        **Frequency:** \(data.recurrenceFrequency)
        **Entity Type:** \(data.entityType ?? "General")
        **Entity ID:** \(data.entityId?.uuidString ?? "N/A")
        **Farm:** \(data.farmName ?? "N/A")
        **Field:** \(data.fieldName ?? "N/A")
        **Lot ID:** \(data.lotId ?? "N/A")
        
        ---
        
        """
        
        // Insert header after title
        if let titleRange = content.range(of: "\n", options: [], range: content.startIndex..<content.endIndex) {
            content.insert(contentsOf: headerSection, at: titleRange.upperBound)
        } else {
            content = headerSection + content
        }
        
        return content
    }
    
    // MARK: - File Operations
    
    /// Lists all files in a directory
    /// - Parameter directory: The directory to list
    /// - Returns: Array of file names
    func listFiles(in directory: DirectoryName) -> [String] {
        let directoryURL = directoryURL(for: directory)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.nameKey],
                options: [.skipsHiddenFiles]
            )
            
            return fileURLs
                .filter { $0.pathExtension == "md" }
                .map { $0.deletingPathExtension().lastPathComponent }
                .sorted()
        } catch {
            print("❌ Error listing files in \(directory.displayName): \(error)")
            return []
        }
    }
    
    /// Reads the content of a template file
    /// - Parameters:
    ///   - fileName: Name of the file (without extension)
    ///   - directory: Directory containing the file
    /// - Returns: File content
    func readTemplate(fileName: String, from directory: DirectoryName) throws -> String {
        let fileURL = directoryURL(for: directory).appendingPathComponent("\(fileName).md")
        return try String(contentsOf: fileURL)
    }
    
    /// Deletes a file from a directory
    /// - Parameters:
    ///   - fileName: Name of the file (without extension)
    ///   - directory: Directory containing the file
    func deleteFile(fileName: String, from directory: DirectoryName) throws {
        let fileURL = directoryURL(for: directory).appendingPathComponent("\(fileName).md")
        try FileManager.default.removeItem(at: fileURL)
        print("✅ Deleted file: \(fileName) from \(directory.displayName)")
    }
    
    /// Generates hash for a file
    /// - Parameter fileURL: URL of the file
    /// - Returns: SHA256 hash string
    func generateFileHash(for fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Supporting Types

/// Information about a created inspection
struct CreatedInspectionInfo {
    let id: UUID
    let fileName: String
    let filePath: String
    let fileHash: String
    let shortHash: String
    let longHash: String
    let inspectionData: InspectionCreationData
}

/// Data required to create an inspection
struct InspectionCreationData {
    let inspectionId: UUID?
    let inspectionName: String
    let category: String
    let scheduledTime: String
    let recurrenceFrequency: String
    let inspectorNames: [String]
    let teamName: String?
    let entityType: String?
    let entityId: UUID?
    let farmName: String?
    let fieldName: String?
    let lotId: String?
}

/// Inspection system errors
enum DMInspectionError: LocalizedError {
    case templateNotFound(String)
    case workingTemplateNotFound(String)
    case directoryCreationFailed(String)
    case fileOperationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Template '\(name)' not found"
        case .workingTemplateNotFound(let name):
            return "Working template '\(name)' not found"
        case .directoryCreationFailed(let path):
            return "Failed to create directory at \(path)"
        case .fileOperationFailed(let operation):
            return "File operation failed: \(operation)"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
