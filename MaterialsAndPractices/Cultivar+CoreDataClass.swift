//
//  Cultivar+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for Cultivar entity.
//  Provides business logic for plant cultivar data and growing information.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(Cultivar)
public class Cultivar: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Display name for the cultivar
    var displayName: String {
        return name.isEmpty ? (commonName ?? "Unknown Cultivar") : name
    }
    
    /// Array of seed sources sorted by name
    var seedSourcesArray: [SupplierSource] {
        let set = seedSources as? Set<SupplierSource> ?? []
        return Array(set).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    /// Array of grows sorted by title
    var growsArray: [Grow] {
        let set = grows as? Set<Grow> ?? []
        return Array(set).sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
    
    /// Check if cultivar has any organic seed sources
    var hasOrganicSeedSources: Bool {
        return seedSourcesArray.contains { $0.isOrganicCertified }
    }
    
    /// Count of active grows for this cultivar
    var activeGrowsCount: Int {
        return growsArray.filter { $0.harvestDate == nil }.count
    }
}

// MARK: - Fetch Request Helpers

extension Cultivar {
    
    /// Fetch request sorted by name
    static func fetchRequestSortedByName() -> NSFetchRequest<Cultivar> {
        let request: NSFetchRequest<Cultivar> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Cultivar.name, ascending: true)]
        return request
    }
    
    /// Fetch request for organic certified cultivars only
    static func fetchRequestOrganicOnly() -> NSFetchRequest<Cultivar> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "isOrganicCertified == YES")
        return request
    }
    
    /// Fetch request filtered by family
    static func fetchRequestForFamily(_ family: String) -> NSFetchRequest<Cultivar> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "family == %@", family)
        return request
    }
}