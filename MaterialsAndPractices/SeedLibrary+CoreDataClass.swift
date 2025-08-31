//
//  SeedLibrary+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for SeedLibrary entity.
//  Provides business logic for seed inventory management and organic compliance tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(SeedLibrary)
public class SeedLibrary: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Display name for the seed entry
    var displayName: String {
        return seedName ?? cultivar?.displayName ?? "Unknown Seed"
    }
    
    /// Array of grows using this seed
    var growsArray: [Grow] {
        let set = grows as? Set<Grow> ?? []
        return Array(set).sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
    
    /// Formatted quantity string with units
    var quantityDisplay: String {
        if quantity > 0 {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            let quantityString = formatter.string(from: NSNumber(value: quantity)) ?? "\(quantity)"
            
            if let unit = unit, !unit.isEmpty {
                return "\(quantityString) \(unit)"
            } else {
                return quantityString
            }
        } else {
            return "No quantity specified"
        }
    }
    
    /// Check if seed is expired or past recommended use
    var isExpired: Bool {
        guard let purchaseDate = purchasedDate else { return false }
        
        // Most seeds are good for 2-3 years
        let calendar = Calendar.current
        let expirationDate = calendar.date(byAdding: .year, value: 3, to: purchaseDate) ?? purchaseDate
        return Date() > expirationDate
    }
    
    /// Check if germination test is current (within last year)
    var isGerminationTestCurrent: Bool {
        guard let testDate = germinationTestDate else { return false }
        
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return testDate > oneYearAgo
    }
    
    // MARK: - Helper Methods
    
    /// Initialize a new seed library entry with cultivar data
    /// - Parameters:
    ///   - cultivar: The source cultivar
    ///   - context: Core Data managed object context
    /// - Returns: Configured SeedLibrary instance
    static func createFromCultivar(_ cultivar: Cultivar, in context: NSManagedObjectContext) -> SeedLibrary {
        let seed = SeedLibrary(context: context)
        
        // Set unique identifier
        seed.id = UUID()
        
        // Set basic information from cultivar
        seed.seedName = cultivar.displayName
        seed.cultivar = cultivar
        seed.createdDate = Date()
        seed.lastModifiedDate = Date()
        
        // Set organic certification based on cultivar
        seed.isCertifiedOrganic = cultivar.isOrganicCertified
        
        // Default values for new seeds
        seed.isGMO = false
        seed.isUntreated = true
        seed.germinationRate = 0.0
        seed.quantity = 0.0
        seed.productionYear = Int16(Calendar.current.component(.year, from: Date()))
        
        return seed
    }
    
    /// Update modification date when seed is edited
    func updateModificationDate() {
        lastModifiedDate = Date()
    }
    
    /// Check if this seed meets organic compliance requirements
    var meetsOrganicCompliance: Bool {
        return isCertifiedOrganic && !isGMO && isUntreated
    }
    
    /// Get compliance status string for display
    var complianceStatus: String {
        if meetsOrganicCompliance {
            return "Organic Compliant"
        } else {
            var issues: [String] = []
            if !isCertifiedOrganic { issues.append("Not certified organic") }
            if isGMO { issues.append("Contains GMO") }
            if !isUntreated { issues.append("Treated seeds") }
            return "Non-compliant: \(issues.joined(separator: ", "))"
        }
    }
}

// MARK: - Fetch Request Helpers

extension SeedLibrary {
    
    /// Fetch request sorted by seed name
    static func fetchRequestSortedByName() -> NSFetchRequest<SeedLibrary> {
        let request: NSFetchRequest<SeedLibrary> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SeedLibrary.seedName, ascending: true)]
        return request
    }
    
    /// Fetch request for organic certified seeds only
    static func fetchRequestOrganicOnly() -> NSFetchRequest<SeedLibrary> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "isCertifiedOrganic == YES")
        return request
    }
    
    /// Fetch request for seeds from a specific supplier
    static func fetchRequestForSupplier(_ supplier: SupplierSource) -> NSFetchRequest<SeedLibrary> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "supplierSource == %@", supplier)
        return request
    }
}