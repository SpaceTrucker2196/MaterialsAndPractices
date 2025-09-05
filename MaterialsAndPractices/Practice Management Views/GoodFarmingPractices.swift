/// ALL THE BEST ENUMS

import Foundation
import SwiftUI
import CoreData


/// Enumeration of common weed and pest management methods
/// Backed by Int32 for Core Data storage
@objc enum WeedAndPestManagmentMethod: Int32, CaseIterable, Identifiable {
    // MARK: - Cultural
    case cropRotation = 0
    case coverCropping = 1
    case intercropping = 2
    case resistantVarieties = 3
    case sanitation = 4

    // MARK: - Mechanical / Physical
    case handWeeding = 10
    case cultivation = 11
    case mowing = 12
    case mulching = 13
    case flaming = 14
    case tillage = 15
    case barriersRowCovers = 16
    case trapping = 17
    case solarization = 18

    // MARK: - Biological
    case beneficialInsects = 20
    case biologicalSprays = 21
    case grazingAnimals = 22
    case microbialControls = 23

    // MARK: - Chemical
    case organicApprovedPesticides = 30
    case herbicides = 31
    case insecticides = 32
    case fungicides = 33
    
    case other = 99

    public var id: Int32 { rawValue }

    /// Human-readable display name
    var displayName: String {
        switch self {
        // Cultural
        case .cropRotation: return "🌾 Crop Rotation"
        case .coverCropping: return "🌱 Cover Cropping"
        case .intercropping: return "🌿 Intercropping"
        case .resistantVarieties: return "🧬 Resistant Varieties"
        case .sanitation: return "🧼 Sanitation"

        // Mechanical
        case .handWeeding: return "✋ Hand Weeding"
        case .cultivation: return "🚜 Cultivation"
        case .mowing: return "✂️ Mowing"
        case .mulching: return "🍂 Mulching"
        case .flaming: return "🔥 Flaming"
        case .tillage: return "🔧 Tillage"
        case .barriersRowCovers: return "🪢 Barriers / Row Covers"
        case .trapping: return "🪤 Trapping"
        case .solarization: return "☀️ Solarization"

        // Biological
        case .beneficialInsects: return "🐞 Beneficial Insects"
        case .biologicalSprays: return "🧴 Biological Sprays (Bt, Neem)"
        case .grazingAnimals: return "🐑 Grazing Animals"
        case .microbialControls: return "🦠 Microbial Controls"

        // Chemical
        case .organicApprovedPesticides: return "✅ OMRI-Approved Pesticides"
        case .herbicides: return "🌿 Herbicides"
        case .insecticides: return "🐜 Insecticides"
        case .fungicides: return "🍄 Fungicides"
        case .other:
            return " Other"
        }
    }

    /// Category grouping for filtering/presentation
    var category: ManagementCategory {
        switch self {
        case .cropRotation, .coverCropping, .intercropping, .resistantVarieties, .sanitation:
            return .cultural
        case .handWeeding, .cultivation, .mowing, .mulching, .flaming,
             .tillage, .barriersRowCovers, .trapping, .solarization:
            return .mechanical
        case .beneficialInsects, .biologicalSprays, .grazingAnimals, .microbialControls:
            return .biological
        case .organicApprovedPesticides, .herbicides, .insecticides, .fungicides:
            return .chemical
        case .other:
            return .other
        }
    }
}

/// Categories for organizing management methods
@objc enum ManagementCategory: Int32, CaseIterable {
    case cultural = 0
    case mechanical = 1
    case biological = 2
    case chemical = 3
    case other = 99

    var label: String {
        switch self {
        case .cultural: return "Cultural"
        case .mechanical: return "Mechanical / Physical"
        case .biological: return "Biological"
        case .chemical: return "Chemical"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .cultural: return "leaf.fill"
        case .mechanical: return "hammer.fill"
        case .biological: return "ladybug.fill"
        case .chemical: return "flask.fill"
        case .other:
            return "leaf.fill"
        }
    }
}
/// Enumeration of common methods for applying soil amendments
// MARK: - Int32-backed enum to match Core Data
@objc public enum ApplicationMethod: Int32, CaseIterable, Identifiable {
    case broadcastSurface       = 0
    case broadcastIncorporated  = 1
    case banding                = 2
    case sideDress              = 3
    case fertigation            = 4
    case foliarSpray            = 5
    case dripIrrigation         = 6
    case soilInjection          = 7
    case topDress               = 8
    case inRow                  = 9
    case seedTreatment          = 10
    case transplantDip          = 11
    case compostMulch           = 12
    case other                  = 99

    public var id: Int32 { rawValue }

    var displayName: String {
        switch self {
        case .broadcastSurface:      return "Broadcast (Surface)"
        case .broadcastIncorporated: return "Broadcast (Incorporated)"
        case .banding:               return "Banding"
        case .sideDress:             return "Side-dress"
        case .fertigation:           return "Fertigation"
        case .foliarSpray:           return "Foliar Spray"
        case .dripIrrigation:        return "Drip Irrigation"
        case .soilInjection:         return "Soil Injection"
        case .topDress:              return "Top Dress"
        case .inRow:                 return "In-row"
        case .seedTreatment:         return "Seed Treatment"
        case .transplantDip:         return "Transplant Dip"
        case .compostMulch:          return "Compost / Mulch Application"
        case .other:                 return "Other"
        }
    }
}

/// Standardized Good Farming Practices for organic certification and food safety compliance
/// Provides comprehensive practice definitions with training, frequency, and certification requirements
enum GoodFarmingPractices: Int32, CaseIterable, Identifiable {
    case soilAmendmentRecordkeeping = 1
    case seedSourceDocumentation = 2
    case pestAndWeedManagementLog = 3
    case harvestRecordkeeping = 4
    case workerHygieneAndFoodSafetyTraining = 5
    case waterSourceAndQualityMonitoring = 6
    case manureAndCompostApplicationLog = 7
    case equipmentSanitationLog = 8
    case traceabilityLotCodesAndProductFlow = 9
    
    var id: Int32 { rawValue }
    
    /// Display name with emoji icon for visual recognition
    var name: String {
        switch self {
        case .soilAmendmentRecordkeeping:
            return "🧪 Soil Amendment Recordkeeping"
        case .seedSourceDocumentation:
            return "🌱 Seed Source Documentation"
        case .pestAndWeedManagementLog:
            return "🐞 Pest and Weed Management Log"
        case .harvestRecordkeeping:
            return "🌾 Harvest Recordkeeping"
        case .workerHygieneAndFoodSafetyTraining:
            return "🧼 Worker Hygiene and Food Safety Training"
        case .waterSourceAndQualityMonitoring:
            return "💧 Water Source and Quality Monitoring"
        case .manureAndCompostApplicationLog:
            return "♻️ Manure and Compost Application Log"
        case .equipmentSanitationLog:
            return "🧽 Equipment Sanitation Log"
        case .traceabilityLotCodesAndProductFlow:
            return "🔍 Traceability Lot Codes and Product Flow"
        }
    }
    
    /// Detailed practice description with implementation guidance
    var description: String {
        switch self {
        case .soilAmendmentRecordkeeping:
            return "Track all soil inputs including compost, manure, and other amendments. Include source, rate, application method, and dates."
        case .seedSourceDocumentation:
            return "Maintain records of seed purchases, noting organic status, treatment (if any), and supplier."
        case .pestAndWeedManagementLog:
            return "Document all pest and weed control activities, including physical, biological, and allowed synthetic methods."
        case .harvestRecordkeeping:
            return "Track harvest quantities, fields, dates, and destinations for traceability."
        case .workerHygieneAndFoodSafetyTraining:
            return "Document training for all employees on proper hygiene and safe produce handling practices."
        case .waterSourceAndQualityMonitoring:
            return "Record irrigation and wash water sources and periodic water testing results."
        case .manureAndCompostApplicationLog:
            return "Log details of raw manure or compost use including aging, C:N ratio, temperature, and application dates."
        case .equipmentSanitationLog:
            return "Track cleaning and sanitizing activities for harvest and processing tools and equipment."
        case .traceabilityLotCodesAndProductFlow:
            return "Track produce from field to customer using lot codes and detailed logs for product traceability."
        }
    }
    
    /// Required training for practice implementation
    var trainingRequired: String {
        switch self {
        case .soilAmendmentRecordkeeping:
            return "Organic soil health, OMRI-compliant materials handling."
        case .seedSourceDocumentation:
            return "Organic seed sourcing standards."
        case .pestAndWeedManagementLog:
            return "Integrated Pest Management (IPM) in organic systems."
        case .harvestRecordkeeping:
            return "Organic traceability and documentation."
        case .workerHygieneAndFoodSafetyTraining:
            return "USDA GAP worker hygiene training."
        case .waterSourceAndQualityMonitoring:
            return "Water safety standards and contamination prevention."
        case .manureAndCompostApplicationLog:
            return "Compost safety and NOP compliance."
        case .equipmentSanitationLog:
            return "Food safety sanitation protocols."
        case .traceabilityLotCodesAndProductFlow:
            return "Food traceability and lot tracking systems."
        }
    }
    
    /// Frequency of practice execution
    var frequency: String {
        switch self {
        case .soilAmendmentRecordkeeping:
            return "Every amendment event."
        case .seedSourceDocumentation:
            return "Per purchase/order."
        case .pestAndWeedManagementLog:
            return "Every application or activity."
        case .harvestRecordkeeping:
            return "Every harvest event."
        case .workerHygieneAndFoodSafetyTraining:
            return "Annually or upon hiring."
        case .waterSourceAndQualityMonitoring:
            return "Quarterly or per certifier requirement."
        case .manureAndCompostApplicationLog:
            return "Every use or turn event."
        case .equipmentSanitationLog:
            return "Daily or before/after each use."
        case .traceabilityLotCodesAndProductFlow:
            return "Per harvest and shipment."
        }
    }
    
    /// Certification requirements for practice
    var certification: String {
        switch self {
        case .soilAmendmentRecordkeeping:
            return "NOP Organic Certification."
        case .seedSourceDocumentation:
            return "NOP Organic Certification."
        case .pestAndWeedManagementLog:
            return "NOP Organic Certification."
        case .harvestRecordkeeping:
            return "NOP Organic Certification."
        case .workerHygieneAndFoodSafetyTraining:
            return "USDA GAP / Harmonized GAP."
        case .waterSourceAndQualityMonitoring:
            return "USDA GAP, Organic Certification."
        case .manureAndCompostApplicationLog:
            return "NOP Organic Certification."
        case .equipmentSanitationLog:
            return "USDA GAP."
        case .traceabilityLotCodesAndProductFlow:
            return "USDA GAP, NOP Organic Certification."
        }
    }
    
    /// Emoji icon for visual identification
    var emoji: String {
        return String(name.prefix(2))
    }
    
    /// Color associated with practice type for UI theming
    var color: Color {
        switch self {
        case .soilAmendmentRecordkeeping, .manureAndCompostApplicationLog:
            return AppTheme.Colors.organicPractice
        case .seedSourceDocumentation:
            return AppTheme.Colors.secondary
        case .pestAndWeedManagementLog:
            return AppTheme.Colors.warning
        case .harvestRecordkeeping:
            return AppTheme.Colors.primary
        case .workerHygieneAndFoodSafetyTraining, .equipmentSanitationLog:
            return AppTheme.Colors.compliance
        case .waterSourceAndQualityMonitoring:
            return AppTheme.Colors.info
        case .traceabilityLotCodesAndProductFlow:
            return AppTheme.Colors.success
        }
    }
    
    /// Indicates if practice is primarily for organic certification
    var isOrganicPractice: Bool {
        return certification.contains("NOP Organic")
    }
    
    /// Indicates if practice is primarily for food safety
    var isFoodSafetyPractice: Bool {
        return certification.contains("USDA GAP")
    }
    
    /// Category grouping for practice organization
    var category: PracticeCategory {
        switch self {
        case .soilAmendmentRecordkeeping, .manureAndCompostApplicationLog:
            return .soilHealth
        case .seedSourceDocumentation:
            return .inputs
        case .pestAndWeedManagementLog:
            return .pestManagement
        case .harvestRecordkeeping, .traceabilityLotCodesAndProductFlow:
            return .harvesting
        case .workerHygieneAndFoodSafetyTraining, .equipmentSanitationLog:
            return .foodSafety
        case .waterSourceAndQualityMonitoring:
            return .waterSafety
        }
    }
}

/// Categories for organizing practices
enum PracticeCategory: String, CaseIterable {
    case soilHealth = "Soil Health"
    case inputs = "Inputs & Materials"
    case pestManagement = "Pest Management"
    case harvesting = "Harvesting & Traceability"
    case foodSafety = "Food Safety"
    case waterSafety = "Water Safety"
    
    var icon: String {
        switch self {
        case .soilHealth: return "leaf.fill"
        case .inputs: return "seedling"
        case .pestManagement: return "bug.fill"
        case .harvesting: return "basket.fill"
        case .foodSafety: return "hand.raised.fill"
        case .waterSafety: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .soilHealth: return AppTheme.Colors.organicPractice
        case .inputs: return AppTheme.Colors.secondary
        case .pestManagement: return AppTheme.Colors.warning
        case .harvesting: return AppTheme.Colors.primary
        case .foodSafety: return AppTheme.Colors.compliance
        case .waterSafety: return AppTheme.Colors.info
        }
    }
    
    /// Get practices for this category
    var practices: [GoodFarmingPractices] {
        return GoodFarmingPractices.allCases.filter { $0.category == self }
    }
}

// MARK: - Extensions for FarmPractice Integration

extension GoodFarmingPractices {
    /// Find matching FarmPractice entity for this enum case
    func findMatchingFarmPractice(in context: NSManagedObjectContext) -> FarmPractice? {
        let request: NSFetchRequest<FarmPractice> = FarmPractice.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", self.name)
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error finding farm practice: \(error)")
            return nil
        }
    }
    
    /// Create or update FarmPractice entity for this enum case
    func createOrUpdateFarmPractice(in context: NSManagedObjectContext) -> FarmPractice {
        if let existing = findMatchingFarmPractice(in: context) {
            // Update existing practice
            existing.descriptionText = self.description
            existing.trainingRequired = self.trainingRequired
            existing.frequency = self.frequency
            existing.certification = self.certification
            existing.lastUpdated = Date()
            return existing
        } else {
            // Create new practice
            let practice = FarmPractice(context: context)
            practice.practiceID = UUID()
            practice.name = self.name
            practice.descriptionText = self.description
            practice.trainingRequired = self.trainingRequired
            practice.frequency = self.frequency
            practice.certification = self.certification
            practice.lastUpdated = Date()
            return practice
        }
    }
}

extension FarmPractice {
    /// Get corresponding GoodFarmingPractices enum case
    var goodFarmingPractice: GoodFarmingPractices? {
        return GoodFarmingPractices.allCases.first { $0.name == self.name }
    }
}
