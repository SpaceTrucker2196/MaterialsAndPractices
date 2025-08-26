//
//  InspectionArchitecture.swift
//  MaterialsAndPractices
//
//  Clean architecture implementation for the inspection management system.
//  Follows Uncle Bob's clean architecture principles with domain entities,
//  use cases, and clear separation of concerns for maintainable code.
//
//  Created by GitHub Copilot on 12/19/24.
//

import Foundation
import CoreData
import CryptoKit

// MARK: - Domain Layer - Entities

/// Domain entity representing an inspection template
struct InspectionTemplateEntity {
    let id: UUID
    let name: String
    let category: InspectionCategory
    let templateContent: String
    let version: String
    let checklistItems: [ChecklistItemEntity]
    
    // Business rules
    var isValid: Bool {
        return !name.isEmpty && !templateContent.isEmpty && !checklistItems.isEmpty
    }
    
    var criticalItemsCount: Int {
        return checklistItems.filter { $0.priority == .critical }.count
    }
    
    var hasRequiredSections: Bool {
        return templateContent.contains("## Section") && templateContent.contains("Inspector Summary")
    }
}

/// Domain entity for checklist items
struct ChecklistItemEntity {
    let id: UUID
    let description: String
    let priority: InspectionPriority
    let sectionNumber: Int
    let itemNumber: Int
    let isCompleted: Bool
    let completedAt: Date?
    let completedBy: String?
    let notes: String?
    
    // Business rules
    var isValidCompletion: Bool {
        if isCompleted {
            return completedAt != nil && completedBy != nil
        }
        return true
    }
}

/// Domain entity for a working inspection
struct WorkingInspectionEntity {
    let id: UUID
    let templateId: UUID
    let name: String
    let category: InspectionCategory
    let scheduledTime: InspectionTime
    let frequency: InspectionFrequency
    let entityReference: EntityReference?
    let inspectors: [InspectorEntity]
    let team: WorkTeamEntity?
    let checklistItems: [ChecklistItemEntity]
    let createdAt: Date
    
    // Business rules
    var isReadyForCompletion: Bool {
        let criticalItemsCompleted = checklistItems
            .filter { $0.priority == .critical }
            .allSatisfy { $0.isCompleted }
        return criticalItemsCompleted && !inspectors.isEmpty
    }
    
    var completionPercentage: Double {
        guard !checklistItems.isEmpty else { return 0 }
        let completedCount = checklistItems.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(checklistItems.count)
    }
    
    var estimatedDuration: TimeInterval {
        // Base time plus time per checklist item
        let baseTime: TimeInterval = 15 * 60 // 15 minutes
        let itemTime: TimeInterval = Double(checklistItems.count) * 2 * 60 // 2 minutes per item
        return baseTime + itemTime
    }
}

/// Domain entity for completed inspections
struct CompletedInspectionEntity {
    let id: UUID
    let templateId: UUID
    let workingInspectionId: UUID
    let name: String
    let category: InspectionCategory
    let completedAt: Date
    let inspectors: [InspectorEntity]
    let team: WorkTeamEntity?
    let entityReference: EntityReference?
    let auditTrail: AuditTrailEntity
    let completedItems: [ChecklistItemEntity]
    let fileName: String
    let filePath: String
    
    // Business rules
    var isCompliant: Bool {
        let criticalItemsCompleted = completedItems
            .filter { $0.priority == .critical }
            .allSatisfy { $0.isCompleted }
        return criticalItemsCompleted
    }
    
    var complianceScore: Double {
        guard !completedItems.isEmpty else { return 0 }
        
        let weights: [InspectionPriority: Double] = [
            .critical: 4.0,
            .high: 3.0,
            .medium: 2.0,
            .low: 1.0
        ]
        
        let totalWeightedScore = completedItems.reduce(0.0) { sum, item in
            let weight = weights[item.priority] ?? 1.0
            return sum + (item.isCompleted ? weight : 0)
        }
        
        let maxPossibleScore = completedItems.reduce(0.0) { sum, item in
            let weight = weights[item.priority] ?? 1.0
            return sum + weight
        }
        
        return maxPossibleScore > 0 ? totalWeightedScore / maxPossibleScore : 0
    }
}

/// Domain entity for audit trail
struct AuditTrailEntity {
    let id: UUID
    let inspectionId: UUID
    let fileHash: String
    let shortHash: String
    let longHash: String
    let createdAt: Date
    let inspector: String
    let verificationCode: String
    
    // Business rules
    var isValid: Bool {
        return !fileHash.isEmpty && !shortHash.isEmpty && !longHash.isEmpty
    }
    
    func generateVerificationCode() -> String {
        let combined = "\(inspectionId.uuidString)\(fileHash)\(createdAt.timeIntervalSince1970)"
        let hash = SHA256.hash(data: combined.data(using: .utf8) ?? Data())
        return String(hash.prefix(8).compactMap { String(format: "%02x", $0) }.joined().prefix(8))
    }
}

/// Domain entity for inspectors
struct InspectorEntity {
    let id: UUID
    let name: String
    let canInspect: Bool
    let certifications: [String]
    
    var isQualified: Bool {
        return canInspect && !name.isEmpty
    }
}

/// Domain entity for entity references (Farm, Field, Grow, Infrastructure)
struct EntityReference {
    let entityId: UUID
    let entityType: EntityType
    let entityName: String
    let farmId: UUID?
    let fieldId: UUID?
    let lotId: String?
    
    enum EntityType: String, CaseIterable {
        case farm = "Farm"
        case field = "Field"
        case grow = "Grow"
        case infrastructure = "Infrastructure"
    }
}

/// Domain entity for work teams
struct WorkTeamEntity {
    let id: UUID
    let name: String
    let members: [InspectorEntity]
    let isActive: Bool
    
    var hasQualifiedInspectors: Bool {
        return members.contains { $0.canInspect }
    }
}

// MARK: - Domain Enums

enum InspectionCategory: String, CaseIterable {
    case grow = "Grow"
    case infrastructure = "Infrastructure"
    case healthSafety = "Health and Safety"
    case equipment = "Equipment"
    case organicManagement = "Organic Management"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .grow:
            return "leaf.fill"
        case .infrastructure:
            return "building.2.fill"
        case .healthSafety:
            return "cross.case.fill"
        case .equipment:
            return "wrench.and.screwdriver.fill"
        case .organicManagement:
            return "checkmark.seal.fill"
        }
    }
}

enum InspectionPriority: String, CaseIterable {
    case critical = "CRITICAL"
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
    
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "green"
        }
    }
}

enum InspectionTime: String, CaseIterable {
    case morning = "Morning"
    case evening = "Evening"
    case night = "Night"
    
    var timeRange: String {
        switch self {
        case .morning: return "6:00 AM - 12:00 PM"
        case .evening: return "12:00 PM - 6:00 PM"
        case .night: return "6:00 PM - 12:00 AM"
        }
    }
}

enum InspectionFrequency: String, CaseIterable {
    case oneTime = "One Time"
    case daily = "Every Day"
    case weekly = "Every Week"
    case earlyMonth = "Early Month"
    case midMonth = "Mid Month"
    case seasonal = "Each Season"
    case spring = "Spring"
    case summer = "Summer"
    case winter = "Winter"
    case fall = "Fall"
    
    var icon: String {
        switch self {
        case .oneTime: return "1.circle.fill"
        case .daily: return "calendar.circle.fill"
        case .weekly: return "calendar.badge.clock.fill"
        case .earlyMonth, .midMonth: return "calendar.badge.exclamationmark"
        case .seasonal: return "calendar.badge.plus"
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .winter: return "snowflake"
        case .fall: return "leaf.arrow.circlepath"
        }
    }
}

// MARK: - Use Cases Layer

/// Protocol for inspection template management use cases
protocol InspectionTemplateUseCaseProtocol {
    func getAvailableTemplates() async -> Result<[InspectionTemplateEntity], InspectionError>
    func getTemplate(id: UUID) async -> Result<InspectionTemplateEntity, InspectionError>
    func createWorkingTemplate(templateId: UUID, name: String) async -> Result<InspectionTemplateEntity, InspectionError>
    func seedTemplatesIfNeeded() async -> Result<Void, InspectionError>
}

/// Protocol for working inspection management use cases
protocol WorkingInspectionUseCaseProtocol {
    func createInspection(request: CreateInspectionRequest) async -> Result<WorkingInspectionEntity, InspectionError>
    func getWorkingInspections() async -> Result<[WorkingInspectionEntity], InspectionError>
    func updateChecklistItem(inspectionId: UUID, itemId: UUID, completion: ChecklistItemCompletion) async -> Result<Void, InspectionError>
    func completeInspection(inspectionId: UUID) async -> Result<CompletedInspectionEntity, InspectionError>
}

/// Protocol for completed inspection management use cases
protocol CompletedInspectionUseCaseProtocol {
    func getCompletedInspections() async -> Result<[CompletedInspectionEntity], InspectionError>
    func getInspection(id: UUID) async -> Result<CompletedInspectionEntity, InspectionError>
    func reconcileInspectionFiles() async -> Result<ReconciliationResult, InspectionError>
    func generateAuditReport(from: Date, to: Date) async -> Result<AuditReportEntity, InspectionError>
}

// MARK: - Request/Response Models

struct CreateInspectionRequest {
    let templateId: UUID
    let name: String
    let category: InspectionCategory
    let scheduledTime: InspectionTime
    let frequency: InspectionFrequency
    let entityReference: EntityReference?
    let inspectorIds: [UUID]
    let teamId: UUID?
}

struct ChecklistItemCompletion {
    let isCompleted: Bool
    let completedBy: String
    let notes: String?
    let completedAt: Date
}

struct ReconciliationResult {
    let missingFiles: [String]
    let orphanedRecords: [UUID]
    let inconsistentHashes: [(fileId: UUID, expectedHash: String, actualHash: String)]
    let newFiles: [String]
}

struct AuditReportEntity {
    let id: UUID
    let generatedAt: Date
    let periodStart: Date
    let periodEnd: Date
    let totalInspections: Int
    let complianceRate: Double
    let criticalIssues: Int
    let inspectionsByCategory: [InspectionCategory: Int]
    let inspectorActivity: [String: Int]
}

// MARK: - Repository Protocols

protocol InspectionTemplateRepositoryProtocol {
    func getAllTemplates() async -> [InspectionTemplateEntity]
    func getTemplate(id: UUID) async -> InspectionTemplateEntity?
    func saveTemplate(_ template: InspectionTemplateEntity) async -> Bool
    func deleteTemplate(id: UUID) async -> Bool
}

protocol WorkingInspectionRepositoryProtocol {
    func getAllWorkingInspections() async -> [WorkingInspectionEntity]
    func getWorkingInspection(id: UUID) async -> WorkingInspectionEntity?
    func saveWorkingInspection(_ inspection: WorkingInspectionEntity) async -> Bool
    func deleteWorkingInspection(id: UUID) async -> Bool
}

protocol CompletedInspectionRepositoryProtocol {
    func getAllCompletedInspections() async -> [CompletedInspectionEntity]
    func getCompletedInspection(id: UUID) async -> CompletedInspectionEntity?
    func saveCompletedInspection(_ inspection: CompletedInspectionEntity) async -> Bool
    func getInspectionsByDateRange(from: Date, to: Date) async -> [CompletedInspectionEntity]
}

protocol AuditTrailRepositoryProtocol {
    func saveAuditEntry(_ auditTrail: AuditTrailEntity) async -> Bool
    func getAuditTrail(inspectionId: UUID) async -> AuditTrailEntity?
    func getAllAuditEntries() async -> [AuditTrailEntity]
}

// MARK: - Use Case Implementations

/// Implementation of inspection template use cases
class InspectionTemplateUseCase: InspectionTemplateUseCaseProtocol {
    private let templateRepository: InspectionTemplateRepositoryProtocol
    private let directoryManager: InspectionDirectoryManager
    private let templateSeeder: InspectionTemplateSeeder
    
    init(
        templateRepository: InspectionTemplateRepositoryProtocol,
        directoryManager: InspectionDirectoryManager,
        templateSeeder: InspectionTemplateSeeder
    ) {
        self.templateRepository = templateRepository
        self.directoryManager = directoryManager
        self.templateSeeder = templateSeeder
    }
    
    func getAvailableTemplates() async -> Result<[InspectionTemplateEntity], InspectionError> {
        let templates = await templateRepository.getAllTemplates()
        return .success(templates)
    }
    
    func getTemplate(id: UUID) async -> Result<InspectionTemplateEntity, InspectionError> {
        if let template = await templateRepository.getTemplate(id: id) {
            return .success(template)
        } else {
            return .failure(.templateNotFound(id.uuidString))
        }
    }
    
    func createWorkingTemplate(templateId: UUID, name: String) async -> Result<InspectionTemplateEntity, InspectionError> {
        guard let template = await templateRepository.getTemplate(id: templateId) else {
            return .failure(.templateNotFound(templateId.uuidString))
        }
        
        do {
            let _ = try directoryManager.copyTemplateToWorking(
                templateName: template.name,
                newName: name
            )
            
            let workingTemplate = InspectionTemplateEntity(
                id: UUID(),
                name: name,
                category: template.category,
                templateContent: template.templateContent,
                version: template.version,
                checklistItems: template.checklistItems
            )
            
            let success = await templateRepository.saveTemplate(workingTemplate)
            if success {
                return .success(workingTemplate)
            } else {
                return .failure(.saveOperationFailed("Failed to save working template"))
            }
        } catch {
            return .failure(.fileOperationFailed("Failed to copy template: \(error.localizedDescription)"))
        }
    }
    
    func seedTemplatesIfNeeded() async -> Result<Void, InspectionError> {
        templateSeeder.seedTemplatesIfNeeded()
        return .success(())
    }
}

// MARK: - Error Types

enum InspectionError: LocalizedError, Equatable {
    case templateNotFound(String)
    case workingTemplateNotFound(String)
    case inspectionNotFound(String)
    case invalidInspectionData(String)
    case fileOperationFailed(String)
    case saveOperationFailed(String)
    case auditTrailCreationFailed(String)
    case insufficientPermissions(String)
    case invalidHash(String)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound(let id):
            return "Template not found: \(id)"
        case .workingTemplateNotFound(let name):
            return "Working template not found: \(name)"
        case .inspectionNotFound(let id):
            return "Inspection not found: \(id)"
        case .invalidInspectionData(let reason):
            return "Invalid inspection data: \(reason)"
        case .fileOperationFailed(let reason):
            return "File operation failed: \(reason)"
        case .saveOperationFailed(let reason):
            return "Save operation failed: \(reason)"
        case .auditTrailCreationFailed(let reason):
            return "Audit trail creation failed: \(reason)"
        case .insufficientPermissions(let reason):
            return "Insufficient permissions: \(reason)"
        case .invalidHash(let reason):
            return "Invalid hash: \(reason)"
        }
    }
}