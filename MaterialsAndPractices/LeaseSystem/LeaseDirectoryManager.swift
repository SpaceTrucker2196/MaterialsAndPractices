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
        
        // Generate filename for completed lease
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let guid = UUID().uuidString.prefix(8).lowercased()
        let fileName = "\(dateString)_\(workingTemplateName)_\(guid).md"
        
        let completedURL = directoryURL(for: .completed).appendingPathComponent(fileName)
        
        // Read working template
        let templateContent = try String(contentsOf: workingTemplateURL)
        
        // Populate template with lease data
        let populatedContent = populateTemplate(templateContent, with: leaseData)
        
        // Write completed lease
        try populatedContent.write(to: completedURL, atomically: true, encoding: .utf8)
        
        // Generate hash for audit trail
        let contentData = populatedContent.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: contentData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        let createdInfo = CreatedLeaseInfo(
            id: UUID(),
            fileName: fileName,
            filePath: completedURL.path,
            fileHash: hashString,
            shortHash: String(hashString.prefix(8)),
            longHash: hashString,
            leaseData: leaseData
        )
        
        print("✅ Created lease agreement: \(fileName)")
        return createdInfo
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
    case invalidTemplate(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Template '\(name)' not found"
        case .workingTemplateNotFound(let name):
            return "Working template '\(name)' not found"
        case .fileCreationFailed(let reason):
            return "Failed to create file: \(reason)"
        case .invalidTemplate(let reason):
            return "Invalid template: \(reason)"
        }
    }
}
