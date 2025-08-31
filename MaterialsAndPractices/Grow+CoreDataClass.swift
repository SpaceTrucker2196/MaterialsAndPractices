//
//  Grow+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for Grow entity.
//  Provides business logic for active cultivation tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(Grow)
public class Grow: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Display name for the grow
    var displayName: String {
        if let title = title, !title.isEmpty {
            return title
        } else if let cultivarName = cultivar?.displayName {
            return "Grow: \(cultivarName)"
        } else if let seedName = seedArray.first?.displayName {
            return "Grow: \(seedName)"
        } else {
            return "Untitled Grow"
        }
    }
    
    /// Array of seeds used in this grow
    var seedArray: [SeedLibrary] {
        let set = seed as? Set<SeedLibrary> ?? []
        return Array(set).sorted { ($0.seedName ?? "") < ($1.seedName ?? "") }
    }
    
    /// Primary seed for this grow (first one if multiple)
    var primarySeed: SeedLibrary? {
        return seedArray.first
    }
    
    /// Check if grow is currently active (not harvested)
    var isActive: Bool {
        return harvestDate == nil
    }
    
    /// Days since planting
    var daysSincePlanting: Int? {
        guard let plantedDate = plantedDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: plantedDate, to: Date()).day
    }
    
    /// Estimated harvest date based on cultivar or seed data
    var estimatedHarvestDate: Date? {
        guard let plantedDate = plantedDate else { return nil }
        
        // Try to get growing days from cultivar first
        if let cultivar = cultivar {
            let growingDays = cultivar.parseGrowingDays()
            if growingDays.early > 0 {
                return Calendar.current.date(byAdding: .day, value: growingDays.early, to: plantedDate)
            }
        }
        
        // If no cultivar data, return nil for now
        // Could add growing days to SeedLibrary in future
        return nil
    }
    
    /// Check if grow is overdue for harvest
    var isOverdueForHarvest: Bool {
        guard let estimatedDate = estimatedHarvestDate,
              harvestDate == nil else { return false }
        return Date() > estimatedDate
    }
    
    /// Full location string
    var fullLocation: String {
        var components: [String] = []
        
        if let locationName = locationName, !locationName.isEmpty {
            components.append(locationName)
        }
        if let city = city, !city.isEmpty {
            components.append(city)
        }
        if let state = state, !state.isEmpty {
            components.append(state)
        }
        
        return components.isEmpty ? "No location specified" : components.joined(separator: ", ")
    }
}

// MARK: - Fetch Request Helpers

extension Grow {
    
    /// Fetch request sorted by title
    static func fetchRequestSortedByTitle() -> NSFetchRequest<Grow> {
        let request: NSFetchRequest<Grow> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Grow.title, ascending: true)]
        return request
    }
    
    /// Fetch request for active grows only (not harvested)
    static func fetchRequestActiveOnly() -> NSFetchRequest<Grow> {
        let request = fetchRequestSortedByTitle()
        request.predicate = NSPredicate(format: "harvestDate == nil")
        return request
    }
    
    /// Fetch request for grows planted in a specific year
    static func fetchRequestForYear(_ year: Int) -> NSFetchRequest<Grow> {
        let request = fetchRequestSortedByTitle()
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        request.predicate = NSPredicate(format: "plantedDate >= %@ AND plantedDate < %@", startOfYear as NSDate, endOfYear as NSDate)
        return request
    }
    
    /// Fetch request for grows using a specific seed
    static func fetchRequestForSeed(_ seed: SeedLibrary) -> NSFetchRequest<Grow> {
        let request = fetchRequestSortedByTitle()
        request.predicate = NSPredicate(format: "ANY seed == %@", seed)
        return request
    }
}