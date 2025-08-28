//
//  LeaseDirectoryManager.swift
//  MaterialsAndPractices
//
//  Manages the three-tier lease directory structure for template organization,
//  working copies, and completed lease agreements. Provides file operations for the
//  lease workflow with audit trail integration.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CryptoKit

/// Manages lease directories and file operations
/// Provides centralized access to lease template management and file system operations
class LeaseDirectoryManager {
    
    // MARK: - Constants
    
    /// Directory names for the lease system
    enum DirectoryName: String, CaseIterable {
        case templates = "LeaseTemplates"
        case working = "WorkingLeaseTemplates"
        case completed = "CompletedLeaseAgreements"
        
        var displayName: String {
            switch self {
            case .templates:
                return "Lease Template Masters"
            case .working:
                return "Working Lease Templates"
            case .completed:
                return "Completed Lease Agreements"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = LeaseDirectoryManager()
    
    /// Base documents directory
    private let documentsDirectory: URL
    
    /// Base lease directory
    private let leaseBaseDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        leaseBaseDirectory = documentsDirectory.appendingPathComponent("Leases")
        
        // Ensure base directory exists
        createLeaseDirectories()
    }
    
    // MARK: - Directory Management
    
    /// Creates all required lease directories if they don't exist
    private func createLeaseDirectories() {
        let fileManager = FileManager.default
        
        // Create base lease directory
        if !fileManager.fileExists(atPath: leaseBaseDirectory.path) {
            do {
                try fileManager.createDirectory(at: leaseBaseDirectory, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created base lease directory: \(leaseBaseDirectory.path)")
            } catch {
                print("❌ Error creating lease directory: \(error)")
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
    
    /// Returns the URL for a specific lease directory
    /// - Parameter directory: The directory type
    /// - Returns: URL for the directory
    func directoryURL(for directory: DirectoryName) -> URL {
        return leaseBaseDirectory.appendingPathComponent(directory.rawValue)
    }
    
    // MARK: - Template Management
    
    /// Copies a template from templates to working directory
    /// - Parameters:
    ///   - templateName: Name of the template without extension
    ///   - workingName: Name for the working copy
    /// - Throws: LeaseError if operation fails
    func copyTemplateToWorking(templateName: String, workingName: String) throws {
        let sourceURL = directoryURL(for: .templates).appendingPathComponent("\(templateName).md")
        let destinationURL = directoryURL(for: .working).appendingPathComponent("\(workingName).md")
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw LeaseError.templateNotFound(templateName)
        }
        
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        print("📋 Copied template '\(templateName)' to working as '\(workingName)'")
    }
    
    /// Lists files in a directory
    /// - Parameter directory: The directory to list
    /// - Returns: Array of file names without extensions
    func listFiles(in directory: DirectoryName) -> [String] {
        let directoryURL = directoryURL(for: directory)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            return fileURLs
                .filter { $0.pathExtension == "md" }
                .map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            print("❌ Error listing files in \(directory.displayName): \(error)")
            return []
        }
    }
    
    /// Lists lease files for a specific year
    /// - Parameter year: The growing year
    /// - Returns: Array of lease file names with metadata
    func listLeaseFiles(for year: Int) -> [LeaseFileInfo] {
        let yearDirectory = directoryURL(for: .completed).appendingPathComponent("\(year)")
        
        guard FileManager.default.fileExists(atPath: yearDirectory.path) else {
            return []
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: yearDirectory, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            
            return fileURLs
                .filter { $0.pathExtension == "md" }
                .compactMap { url in
                    do {
                        let resourceValues = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                        return LeaseFileInfo(
                            fileName: url.deletingPathExtension().lastPathComponent,
                            filePath: url.path,
                            creationDate: resourceValues.creationDate ?? Date(),
                            fileSize: resourceValues.fileSize ?? 0,
                            year: year
                        )
                    } catch {
                        print("❌ Error reading file metadata for \(url.lastPathComponent): \(error)")
                        return nil
                    }
                }
                .sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("❌ Error listing files in year \(year): \(error)")
            return []
        }
    }
    
    /// Lists all available years with lease files
    /// - Returns: Array of years with lease files, sorted descending
    func listAvailableYears() -> [Int] {
        let completedURL = directoryURL(for: .completed)
        
        do {
            let directoryURLs = try FileManager.default.contentsOfDirectory(at: completedURL, includingPropertiesForKeys: [.isDirectoryKey])
            
            return directoryURLs
                .filter { url in
                    let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    return isDirectory && Int(url.lastPathComponent) != nil
                }
                .compactMap { Int($0.lastPathComponent) }
                .sorted { $0 > $1 }
        } catch {
            print("❌ Error listing year directories: \(error)")
            return []
        }
    }
    
    /// Creates a completed lease agreement from working template
    /// - Parameters:
    ///   - workingTemplateName: Name of the working template
    ///   - leaseData: Data to populate in the lease
    /// - Returns: Information about the created lease
    /// - Throws: LeaseError if operation fails
    func createCompletedLease(
        workingTemplateName: String,
        leaseData: LeaseCreationData
    ) throws -> CreatedLeaseInfo {
        let workingTemplateURL = directoryURL(for: .working).appendingPathComponent("\(workingTemplateName).md")
        
        guard FileManager.default.fileExists(atPath: workingTemplateURL.path) else {
            throw LeaseError.workingTemplateNotFound(workingTemplateName)
        }
        
        // Create year-based directory structure
        let yearDirectory = createYearDirectory(for: leaseData.growingYear)
        
        // Generate filename using requested convention: Farm + Year + Version + ID
        let farmPrefix = String((leaseData.propertyName ?? "FARM").prefix(4)).uppercased()
        let yearSuffix = String(leaseData.growingYear)
        let version = "V01" // Start with version 1, increment if file exists
        let uniqueId = UUID().uuidString.prefix(4).uppercased()
        
        let baseFileName = "\(farmPrefix)\(yearSuffix)\(version)\(uniqueId)"
        let fileName = "\(baseFileName).md"
        
        let completedURL = yearDirectory.appendingPathComponent(fileName)
        
        // Handle file conflicts by incrementing version
        let finalURL = try generateUniqueFileName(baseURL: completedURL, baseFileName: baseFileName)
        
        // Read working template with error handling
        let templateContent: String
        do {
            templateContent = try String(contentsOf: workingTemplateURL)
        } catch {
            throw LeaseError.fileAccessError("Unable to read template: \(error.localizedDescription)")
        }
        
        // Populate template with lease data
        let populatedContent = populateTemplate(templateContent, with: leaseData)
        
        // Write completed lease with proper error handling
        do {
            try populatedContent.write(to: finalURL, atomically: true, encoding: .utf8)
        } catch {
            throw LeaseError.fileCreationFailed("Unable to save lease file: \(error.localizedDescription)")
        }
        
        // Generate hash for audit trail
        let contentData = populatedContent.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: contentData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        let createdInfo = CreatedLeaseInfo(
            id: UUID(),
            fileName: finalURL.lastPathComponent,
            filePath: finalURL.path,
            fileHash: hashString,
            shortHash: String(hashString.prefix(8)),
            longHash: hashString,
            leaseData: leaseData
        )
        
        print("✅ Created lease agreement: \(finalURL.lastPathComponent) in \(yearDirectory.lastPathComponent)")
        return createdInfo
    }
    
    /// Creates year-based directory structure
    /// - Parameter year: The growing year
    /// - Returns: URL to the year directory
    private func createYearDirectory(for year: Int) -> URL {
        let yearDirectory = directoryURL(for: .completed).appendingPathComponent("\(year)")
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: yearDirectory.path) {
            do {
                try fileManager.createDirectory(at: yearDirectory, withIntermediateDirectories: true, attributes: nil)
                print("✅ Created year directory: \(yearDirectory.path)")
            } catch {
                print("❌ Error creating year directory: \(error)")
                // Fall back to base completed directory if year directory creation fails
                return directoryURL(for: .completed)
            }
        }
        
        return yearDirectory
    }
    
    /// Generates a unique filename by incrementing version if file exists
    /// - Parameters:
    ///   - baseURL: The base URL for the file
    ///   - baseFileName: The base filename without extension
    /// - Returns: A unique URL for the file
    /// - Throws: LeaseError if unable to generate unique name
    private func generateUniqueFileName(baseURL: URL, baseFileName: String) throws -> URL {
        let fileManager = FileManager.default
        var currentURL = baseURL
        var version = 1
        
        // Try up to 99 versions
        while fileManager.fileExists(atPath: currentURL.path) && version < 100 {
            version += 1
            let versionString = String(format: "V%02d", version)
            
            // Replace the version part in the filename
            var components = baseFileName.components(separatedBy: "V")
            if components.count >= 2 {
                let beforeVersion = components[0]
                let afterVersion = components[1].dropFirst(2) // Remove the "01" part
                let newFileName = "\(beforeVersion)\(versionString)\(afterVersion).md"
                currentURL = baseURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            } else {
                // Fallback: append version to end
                let newFileName = "\(baseFileName)\(versionString).md"
                currentURL = baseURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            }
        }
        
        if version >= 100 {
            throw LeaseError.fileCreationFailed("Unable to generate unique filename after 99 attempts")
        }
        
        return currentURL
    }
    
    /// Populates a template with lease data
    /// - Parameters:
    ///   - template: The template content
    ///   - data: The lease data
    /// - Returns: Populated template content
    private func populateTemplate(_ template: String, with data: LeaseCreationData) -> String {
        var content = template
        
        // Add lease header
        let headerSection = """
        
        ## Lease Agreement Details
        - **Lease ID:** \(data.leaseId?.uuidString ?? "N/A")
        - **Property:** \(data.propertyName ?? "N/A")
        - **Farmer:** \(data.farmerName ?? "N/A")
        - **Created:** \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))
        - **Growing Year:** \(data.growingYear)
        
        """
        
        // Insert header after first # header
        if let range = content.range(of: "\n", options: [], range: content.range(of: "#")!.upperBound..<content.endIndex) {
            content.insert(contentsOf: headerSection, at: range.upperBound)
        }
        
        // Replace template variables
        content = content.replacingOccurrences(of: "{{lease_id}}", with: data.leaseId?.uuidString ?? "")
        content = content.replacingOccurrences(of: "{{property_name}}", with: data.propertyName ?? "")
        content = content.replacingOccurrences(of: "{{farmer_name}}", with: data.farmerName ?? "")
        content = content.replacingOccurrences(of: "{{growing_year}}", with: "\(data.growingYear)")
        content = content.replacingOccurrences(of: "{{lease_type}}", with: data.leaseType ?? "")
        content = content.replacingOccurrences(of: "{{start_date}}", with: data.startDate.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "")
        content = content.replacingOccurrences(of: "{{end_date}}", with: data.endDate.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "")
        content = content.replacingOccurrences(of: "{{rent_amount}}", with: data.rentAmount?.description ?? "")
        content = content.replacingOccurrences(of: "{{rent_frequency}}", with: data.rentFrequency ?? "")
        
        return content
    }
    
    /// Calculates file hash for audit purposes
    /// - Parameter fileURL: URL of the file to hash
    /// - Returns: SHA256 hash string
    /// - Throws: Error if file cannot be read
    func calculateFileHash(for fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Supporting Types

/// Information about a created lease agreement
struct CreatedLeaseInfo {
    let id: UUID
    let fileName: String
    let filePath: String
    let fileHash: String
    let shortHash: String
    let longHash: String
    let leaseData: LeaseCreationData
}

/// Information about a lease file on disk
struct LeaseFileInfo {
    let fileName: String
    let filePath: String
    let creationDate: Date
    let fileSize: Int
    let year: Int
    
    var displayName: String {
        // Extract readable information from filename
        // Format: FARM2024V01ABCD -> Farm (2024) V01
        if fileName.count >= 8 {
            let farmCode = String(fileName.prefix(4))
            let yearCode = String(fileName.dropFirst(4).prefix(4))
            let versionCode = String(fileName.dropFirst(8).prefix(3))
            return "\(farmCode) (\(yearCode)) \(versionCode)"
        }
        return fileName
    }
}

/// Data required to create a lease agreement
struct LeaseCreationData {
    let leaseId: UUID?
    let propertyName: String?
    let farmerName: String?
    let growingYear: Int
    let leaseType: String?
    let startDate: Date?
    let endDate: Date?
    let rentAmount: Decimal?
    let rentFrequency: String?
}

/// Lease system errors
enum LeaseError: LocalizedError {
    case templateNotFound(String)
    case workingTemplateNotFound(String)
    case fileCreationFailed(String)
    case fileAccessError(String)
    case invalidTemplate(String)
    case directoryCreationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Template '\(name)' not found"
        case .workingTemplateNotFound(let name):
            return "Working template '\(name)' not found"
        case .fileCreationFailed(let reason):
            return "Failed to create file: \(reason)"
        case .fileAccessError(let reason):
            return "File access error: \(reason)"
        case .invalidTemplate(let reason):
            return "Invalid template: \(reason)"
        case .directoryCreationFailed(let reason):
            return "Failed to create directory: \(reason)"
        }
    }
}
