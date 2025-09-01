//
//  SeedLibrary+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for SeedLibrary entity.
//  Provides business logic for seed inventory management and organic certification tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(SeedLibrary)
public class SeedLibrary: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Display name for the seed
    var displayName: String {
        if let seedName = seedName, !seedName.isEmpty {
            return seedName
        } else if let cultivarName = cultivar?.name {
            return "Seeds: \(cultivarName)"
        } else {
            return "Unnamed Seed"
        }
    }
    
    /// Array of grows using this seed
    var growsArray: [Grow] {
        let set = grows as? Set<Grow> ?? []
        return Array(set).sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
    
    /// Check if seed is expired based on production year
    var isExpired: Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        let maxAge = 5 // Seeds typically good for 5 years
        return (currentYear - Int(productionYear)) > maxAge
    }
    
    /// Check if germination test is current (within last year)
    var isGerminationTestCurrent: Bool {
        guard let testDate = germinationTestDate else { return false }
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return testDate >= oneYearAgo
    }
    
    /// Update the last modified date
    func updateModificationDate() {
        lastModifiedDate = Date()
    }
    
    // MARK: - Factory Methods
    
    /// Creates a new SeedLibrary instance from a Cultivar
    /// - Parameters:
    ///   - cultivar: The cultivar to create seeds from
    ///   - context: Core Data managed object context
    /// - Returns: New SeedLibrary instance
    static func createFromCultivar(_ cultivar: Cultivar, in context: NSManagedObjectContext) -> SeedLibrary {
        let seed = SeedLibrary(context: context)
        seed.id = UUID()
        seed.cultivar = cultivar
        seed.seedName = cultivar.name
        seed.createdDate = Date()
        seed.lastModifiedDate = Date()
        seed.quantity = 0
        seed.unit = "packets"
        seed.isCertifiedOrganic = false
        seed.isGMO = false
        seed.isUntreated = true
        seed.germinationRate = 0
        seed.productionYear = Int16(Calendar.current.component(.year, from: Date()))
        return seed
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch request sorted by seed name
    static func fetchRequestSortedByName() -> NSFetchRequest<SeedLibrary> {
        let request: NSFetchRequest<SeedLibrary> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SeedLibrary.seedName, ascending: true)]
        return request
    }
    
    /// Fetch request for organic seeds only
    static func fetchRequestOrganicOnly() -> NSFetchRequest<SeedLibrary> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "isCertifiedOrganic == true")
        return request
    }
    
    /// Fetch request for seeds with active grows
    static func fetchRequestWithActiveGrows() -> NSFetchRequest<SeedLibrary> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "ANY grows.harvestDate == nil")
        return request
    }
}