//
//  CropAmendmentSeeder.swift
//  MaterialsAndPractices
//
//  Seeds common crop amendments used on farms for testing and initial setup.
//  Includes both OMRI-listed organic amendments and conventional options.
//
//  Created by GitHub Copilot on 12/18/24.
//

import Foundation
import CoreData

/// Seeder class for pre-populating common crop amendments
class CropAmendmentSeeder {
    
    /// Seeds common crop amendments into the Core Data context
    /// - Parameter context: The Core Data managed object context
    static func seedAmendments(in context: NSManagedObjectContext) {
        // Check if amendments already exist
        let fetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        
        do {
            let existingAmendments = try context.fetch(fetchRequest)
            if !existingAmendments.isEmpty {
                print("Amendments already seeded")
                return
            }
        } catch {
            print("Error checking existing amendments: \(error)")
            return
        }
        
        // Seed common organic amendments
        let organicAmendments = createOrganicAmendments()
        
        // Seed conventional amendments
        let conventionalAmendments = createConventionalAmendments()
        
        // Combine all amendments
        let allAmendments = organicAmendments + conventionalAmendments
        
        // Create amendment entities
        for amendmentData in allAmendments {
            let amendment = CropAmendment(context: context)
            amendment.amendmentID = UUID()
            amendment.dateApplied = Date()
            amendment.productName = amendmentData.productName
            amendment.applicationRate = amendmentData.applicationRate
            amendment.unitOfMeasure = amendmentData.unitOfMeasure
            amendment.cropTreated = amendmentData.cropTreated
            amendment.location = amendmentData.location
            amendment.applicationMethod = amendmentData.applicationMethod
            amendment.productType = amendmentData.productType
            amendment.omriListed = amendmentData.omriListed
            amendment.epaRegistrationNumber = amendmentData.epaRegistrationNumber
            amendment.reEntryIntervalHours = amendmentData.reEntryIntervalHours
            amendment.preHarvestIntervalDays = amendmentData.preHarvestIntervalDays
            amendment.weatherConditions = amendmentData.weatherConditions
            amendment.applicatorName = amendmentData.applicatorName
            amendment.applicatorCertificationID = amendmentData.applicatorCertificationID
            amendment.batchLotNumber = amendmentData.batchLotNumber
            amendment.notes = amendmentData.notes
        }
        
        // Save context
        do {
            try context.save()
            print("Successfully seeded \(allAmendments.count) crop amendments")
        } catch {
            print("Error saving seeded amendments: \(error)")
        }
    }
    
    /// Creates organic OMRI-listed amendments
    private static func createOrganicAmendments() -> [AmendmentData] {
        return [
            AmendmentData(
                productName: "Compost (OMRI Listed)",
                applicationRate: "2-4",
                unitOfMeasure: "cubic yards per acre",
                cropTreated: "All crops",
                location: "Field application",
                applicationMethod: "Broadcast and incorporate",
                productType: "Organic matter",
                omriListed: true,
                epaRegistrationNumber: nil,
                reEntryIntervalHours: 0,
                preHarvestIntervalDays: 0,
                weatherConditions: "Dry conditions preferred",
                applicatorName: "Farm worker",
                applicatorCertificationID: nil,
                batchLotNumber: nil,
                notes: "Improves soil structure and fertility"
            ),
            AmendmentData(
                productName: "Fish Emulsion (OMRI Listed)",
                applicationRate: "1-2",
                unitOfMeasure: "gallons per acre",
                cropTreated: "Leafy greens",
                location: "Field application",
                applicationMethod: "Foliar spray",
                productType: "Organic fertilizer",
                omriListed: true,
                epaRegistrationNumber: nil,
                reEntryIntervalHours: 4,
                preHarvestIntervalDays: 0,
                weatherConditions: "Avoid windy conditions",
                applicatorName: "Certified applicator",
                applicatorCertificationID: "ORG-001",
                batchLotNumber: "FE-2024-001",
                notes: "Provides quick nitrogen boost"
            ),
            AmendmentData(
                productName: "Neem Oil (OMRI Listed)",
                applicationRate: "0.5-1",
                unitOfMeasure: "ounces per gallon",
                cropTreated: "Vegetables",
                location: "Field application",
                applicationMethod: "Foliar spray",
                productType: "Organic pesticide",
                omriListed: true,
                epaRegistrationNumber: "70051-2",
                reEntryIntervalHours: 4,
                preHarvestIntervalDays: 0,
                weatherConditions: "Apply in evening to avoid leaf burn",
                applicatorName: "Certified applicator",
                applicatorCertificationID: "ORG-001",
                batchLotNumber: "NO-2024-003",
                notes: "Controls aphids and soft-bodied insects"
            ),
            AmendmentData(
                productName: "Kelp Meal (OMRI Listed)",
                applicationRate: "10-20",
                unitOfMeasure: "pounds per acre",
                cropTreated: "All crops",
                location: "Field application",
                applicationMethod: "Broadcast",
                productType: "Organic fertilizer",
                omriListed: true,
                epaRegistrationNumber: nil,
                reEntryIntervalHours: 0,
                preHarvestIntervalDays: 0,
                weatherConditions: "Any",
                applicatorName: "Farm worker",
                applicatorCertificationID: nil,
                batchLotNumber: "KM-2024-005",
                notes: "Provides trace minerals and growth hormones"
            ),
            AmendmentData(
                productName: "Bt (Bacillus thuringiensis) OMRI Listed",
                applicationRate: "1-2",
                unitOfMeasure: "pounds per acre",
                cropTreated: "Brassicas",
                location: "Field application",
                applicationMethod: "Foliar spray",
                productType: "Organic pesticide",
                omriListed: true,
                epaRegistrationNumber: "73049-39",
                reEntryIntervalHours: 4,
                preHarvestIntervalDays: 0,
                weatherConditions: "Apply in evening, avoid rain within 6 hours",
                applicatorName: "Certified applicator",
                applicatorCertificationID: "ORG-001",
                batchLotNumber: "BT-2024-007",
                notes: "Controls caterpillars and worms"
            )
        ]
    }
    
    /// Creates conventional amendments (not OMRI listed)
    private static func createConventionalAmendments() -> [AmendmentData] {
        return [
            AmendmentData(
                productName: "Synthetic NPK 10-10-10",
                applicationRate: "50-100",
                unitOfMeasure: "pounds per acre",
                cropTreated: "Field crops",
                location: "Field application",
                applicationMethod: "Broadcast and incorporate",
                productType: "Synthetic fertilizer",
                omriListed: false,
                epaRegistrationNumber: nil,
                reEntryIntervalHours: 0,
                preHarvestIntervalDays: 0,
                weatherConditions: "Before rain or irrigation",
                applicatorName: "Farm worker",
                applicatorCertificationID: nil,
                batchLotNumber: "NPK-2024-010",
                notes: "Fast-acting synthetic fertilizer"
            ),
            AmendmentData(
                productName: "Malathion (Conventional Pesticide)",
                applicationRate: "1-2",
                unitOfMeasure: "pints per acre",
                cropTreated: "Fruit trees",
                location: "Orchard application",
                applicationMethod: "Spray application",
                productType: "Conventional pesticide",
                omriListed: false,
                epaRegistrationNumber: "66222-16",
                reEntryIntervalHours: 12,
                preHarvestIntervalDays: 7,
                weatherConditions: "Calm, dry weather",
                applicatorName: "Licensed pesticide applicator",
                applicatorCertificationID: "PEST-2024-001",
                batchLotNumber: "MAL-2024-015",
                notes: "Controls aphids and scale insects - NOT ORGANIC APPROVED"
            ),
            AmendmentData(
                productName: "Glyphosate Herbicide",
                applicationRate: "1-3",
                unitOfMeasure: "quarts per acre",
                cropTreated: "Perennial weeds",
                location: "Field edges",
                applicationMethod: "Spot spray",
                productType: "Conventional herbicide",
                omriListed: false,
                epaRegistrationNumber: "524-475",
                reEntryIntervalHours: 4,
                preHarvestIntervalDays: 14,
                weatherConditions: "No rain for 6 hours",
                applicatorName: "Licensed pesticide applicator",
                applicatorCertificationID: "PEST-2024-001",
                batchLotNumber: "GLY-2024-020",
                notes: "Systemic herbicide - NOT APPROVED FOR ORGANIC PRODUCTION"
            )
        ]
    }
}

/// Data structure for amendment information
private struct AmendmentData {
    let productName: String
    let applicationRate: String
    let unitOfMeasure: String
    let cropTreated: String
    let location: String
    let applicationMethod: String
    let productType: String
    let omriListed: Bool
    let epaRegistrationNumber: String?
    let reEntryIntervalHours: Int16
    let preHarvestIntervalDays: Int16
    let weatherConditions: String?
    let applicatorName: String
    let applicatorCertificationID: String?
    let batchLotNumber: String?
    let notes: String?
}