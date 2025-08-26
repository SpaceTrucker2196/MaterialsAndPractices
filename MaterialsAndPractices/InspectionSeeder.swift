//
//  InspectionSeeder.swift
//  MaterialsAndPractices
//
//  Provides organic compliance inspection seeding functionality with top 10
//  common inspection types and comprehensive checklists for farm certification.
//  Supports organic farming compliance and certification maintenance.
//
//  Created by GitHub Copilot on 12/19/24.
//

import Foundation
import CoreData

/// Inspection seeder for organic compliance inspection templates
/// Provides comprehensive database of inspection types and checklist items
class InspectionSeeder {
    
    // MARK: - Main Seeding Function
    
    /// Seeds the inspection system with organic compliance inspection templates
    /// - Parameter context: Core Data managed object context
    static func seedOrganicInspections(context: NSManagedObjectContext) {
        
        // Check if inspections are already seeded
        let request: NSFetchRequest<Inspection> = Inspection.fetchRequest()
        
        do {
            let existingInspections = try context.fetch(request)
            if !existingInspections.isEmpty {
                print("Organic inspections already seeded")
                return
            }
        } catch {
            print("Error checking existing inspections: \(error)")
            return
        }
        
        // Seed all organic compliance inspection types
        seedSoilFertilityInspection(context: context)
        seedPestManagementInspection(context: context)
        seedSeedAndPlantingInspection(context: context)
        seedHarvestAndStorageInspection(context: context)
        seedRecordKeepingInspection(context: context)
        seedBufferZoneInspection(context: context)
        seedWaterQualityInspection(context: context)
        seedEquipmentCleanlinessInspection(context: context)
        seedOrganicIntegrityInspection(context: context)
        seedCertificationComplianceInspection(context: context)
        
        // Save context
        do {
            try context.save()
            print("Organic compliance inspections seeded successfully")
        } catch {
            print("Error saving organic inspections: \(error)")
        }
    }
    
    // MARK: - Top 10 Organic Compliance Inspections
    
    /// 1. Soil Fertility and Management Inspection
    private static func seedSoilFertilityInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Soil Fertility Management",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Soil test results current within 3 years", "critical"),
            ("Organic matter content meets minimum requirements", "critical"),
            ("Prohibited synthetic fertilizers not used", "critical"),
            ("Composting procedures follow organic standards", "high"),
            ("Cover crops used for soil building", "medium"),
            ("Crop rotation plan documented and followed", "high"),
            ("Soil amendment sources verified organic", "critical"),
            ("Soil erosion control measures in place", "medium"),
            ("pH levels appropriate for planned crops", "medium"),
            ("Micronutrient levels adequate", "low"),
            ("Green manure crops incorporated properly", "medium"),
            ("Tillage practices minimize soil disturbance", "medium")
        ])
    }
    
    /// 2. Pest and Disease Management Inspection
    private static func seedPestManagementInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Pest Management Compliance",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Integrated Pest Management plan documented", "critical"),
            ("Prohibited pesticides not used or stored", "critical"),
            ("Organic-approved pesticides properly documented", "critical"),
            ("Application records complete and accurate", "high"),
            ("Biological control methods implemented", "medium"),
            ("Cultural control practices in use", "medium"),
            ("Mechanical control methods employed", "medium"),
            ("Beneficial insect habitats maintained", "low"),
            ("Pest monitoring records current", "high"),
            ("Emergency treatment protocols documented", "medium"),
            ("Buffer zones maintained from conventional treatments", "critical"),
            ("Equipment cleaning records for pesticide application", "high")
        ])
    }
    
    /// 3. Seeds and Planting Material Inspection
    private static func seedSeedAndPlantingInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Seeds and Planting Materials",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Organic seed sources documented and verified", "critical"),
            ("Non-organic seed use justified and documented", "critical"),
            ("Treated seed prohibition compliance", "critical"),
            ("GMO-free verification for all seeds", "critical"),
            ("Transplant production follows organic standards", "high"),
            ("Seed storage prevents contamination", "medium"),
            ("Variety selection appropriate for organic system", "medium"),
            ("Seed testing records available", "medium"),
            ("Propagation methods comply with standards", "high"),
            ("Seedling media approved for organic use", "high")
        ])
    }
    
    /// 4. Harvest and Post-Harvest Handling Inspection
    private static func seedHarvestAndStorageInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Harvest and Storage",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Harvest equipment clean and contamination-free", "critical"),
            ("Storage facilities prevent organic/conventional mixing", "critical"),
            ("Post-harvest treatments comply with organic standards", "critical"),
            ("Processing aids approved for organic use", "high"),
            ("Cleaning and sanitizing procedures documented", "high"),
            ("Packaging materials meet organic requirements", "medium"),
            ("Temperature and humidity control systems functional", "medium"),
            ("Pest control in storage areas organic-compliant", "high"),
            ("Traceability systems in place", "high"),
            ("Quality control procedures documented", "medium")
        ])
    }
    
    /// 5. Record Keeping and Documentation Inspection
    private static func seedRecordKeepingInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Record Keeping Compliance",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Production records complete for past 3 years", "critical"),
            ("Input purchase receipts and documentation", "critical"),
            ("Application records with dates, rates, and areas", "critical"),
            ("Harvest records with quantities and dates", "high"),
            ("Sales records with buyer information", "high"),
            ("Land use history documented", "medium"),
            ("Equipment cleaning logs maintained", "medium"),
            ("Training records for staff", "medium"),
            ("Inspection and audit records filed", "high"),
            ("Organic system plan current and implemented", "critical"),
            ("Change notifications submitted timely", "high"),
            ("Financial records support organic premium", "medium")
        ])
    }
    
    /// 6. Buffer Zone and Contamination Prevention Inspection
    private static func seedBufferZoneInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Buffer Zone Compliance",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Adequate buffer zones established and maintained", "critical"),
            ("Drift prevention measures in place", "critical"),
            ("Neighboring land use documented", "high"),
            ("Buffer zone vegetation managed organically", "medium"),
            ("Physical barriers effective where needed", "medium"),
            ("Communication with neighbors documented", "medium"),
            ("Monitoring for contamination incidents", "high"),
            ("Emergency response plan for contamination", "high"),
            ("Buffer zone width adequate for all sources", "critical"),
            ("Seasonal management of buffer areas", "low")
        ])
    }
    
    /// 7. Water Quality and Management Inspection
    private static func seedWaterQualityInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Water Quality Management",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Water source testing results current", "critical"),
            ("Irrigation water meets organic standards", "critical"),
            ("Water conservation practices implemented", "medium"),
            ("Runoff prevention measures in place", "high"),
            ("Water storage systems clean and maintained", "medium"),
            ("Cross-contamination prevention in water systems", "high"),
            ("Drainage systems prevent standing water", "medium"),
            ("Well head protection adequate", "medium"),
            ("Water distribution system integrity maintained", "medium"),
            ("Emergency water supply plan documented", "low")
        ])
    }
    
    /// 8. Equipment Cleanliness and Maintenance Inspection
    private static func seedEquipmentCleanlinessInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Equipment Cleanliness",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Cleaning procedures prevent cross-contamination", "critical"),
            ("Cleaning materials approved for organic use", "critical"),
            ("Equipment storage prevents contamination", "high"),
            ("Maintenance records complete and current", "medium"),
            ("Shared equipment cleaning protocols followed", "high"),
            ("Harvest equipment cleaned between uses", "high"),
            ("Application equipment properly calibrated", "medium"),
            ("Storage areas clean and organized", "medium"),
            ("Personal protective equipment clean and functional", "medium"),
            ("Tool and equipment inventory current", "low")
        ])
    }
    
    /// 9. Organic System Integrity Inspection
    private static func seedOrganicIntegrityInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Organic System Integrity",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Organic system plan implemented as written", "critical"),
            ("All inputs approved for organic production", "critical"),
            ("Prohibited substances not present on farm", "critical"),
            ("Organic practices consistently applied", "high"),
            ("Staff training on organic requirements current", "medium"),
            ("Supplier verification procedures followed", "high"),
            ("Change approval process followed", "high"),
            ("Emergency use procedures documented", "medium"),
            ("Continuous improvement processes in place", "low"),
            ("Organic integrity maintained throughout system", "critical")
        ])
    }
    
    /// 10. Certification Compliance and Audit Preparation Inspection
    private static func seedCertificationComplianceInspection(context: NSManagedObjectContext) {
        let inspection = createInspection(
            context: context,
            type: "Certification Compliance",
            status: "template"
        )
        
        addChecklistItems(to: inspection, context: context, items: [
            ("Annual update submitted timely", "critical"),
            ("Certification fees current", "critical"),
            ("Previous inspection findings addressed", "critical"),
            ("Corrective actions implemented and documented", "high"),
            ("Organic system plan reflects current operations", "high"),
            ("Label compliance verified", "high"),
            ("Sales documentation supports organic claims", "high"),
            ("Inspector access procedures documented", "medium"),
            ("Emergency contact information current", "medium"),
            ("Certification documents displayed appropriately", "medium"),
            ("Complaint handling procedures in place", "medium"),
            ("Audit trail complete and verifiable", "critical")
        ])
    }
    
    // MARK: - Helper Functions
    
    /// Creates an inspection template
    private static func createInspection(
        context: NSManagedObjectContext,
        type: String,
        status: String
    ) -> Inspection {
        let inspection = Inspection(context: context)
        inspection.id = UUID()
        inspection.inspectionType = type
        inspection.status = status
        inspection.inspectorName = "Template"
        inspection.notes = "Standard organic compliance inspection template"
        return inspection
    }
    
    /// Adds checklist items to an inspection
    private static func addChecklistItems(
        to inspection: Inspection,
        context: NSManagedObjectContext,
        items: [(description: String, level: String)]
    ) {
        for (description, level) in items {
            let checklistItem = InspectionChecklistItem(context: context)
            checklistItem.id = UUID()
            checklistItem.itemDescription = description
            checklistItem.requirementLevel = level
            checklistItem.isCompleted = false
            checklistItem.inspection = inspection
        }
    }
}

// MARK: - Inspection Requirement Levels

/// Enumeration for inspection requirement levels
enum InspectionRequirementLevel: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayText: String {
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

/// Enumeration for inspection status
enum InspectionStatus: String, CaseIterable {
    case scheduled = "scheduled"
    case inProgress = "in_progress"
    case completed = "completed"
    case template = "template"
    
    var displayText: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .template: return "Template"
        }
    }
}