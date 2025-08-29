//
//  FarmPracticeSeeder.swift
//  MaterialsAndPractices
//
//  Data seeder for default farm practices to populate the database
//  with predefined practices from the problem statement requirements
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CoreData

/// Seeder for default farm practices
class FarmPracticeSeeder {
    
    /// Seeds default farm practices if none exist
    static func seedDefaultPracticesIfNeeded(context: NSManagedObjectContext) {
        // Check if practices already exist
        let request: NSFetchRequest<FarmPractice> = FarmPractice.fetchRequest()
        
        do {
            let existingPractices = try context.fetch(request)
            
            // Only seed if no practices exist
            if existingPractices.isEmpty {
                let defaultPractices = FarmPractice.createPredefinedPractices(in: context)
                
                try context.save()
                
                print("✅ Seeded \(defaultPractices.count) default farm practices")
            } else {
                print("ℹ️ Farm practices already exist (\(existingPractices.count) practices), skipping seeding")
            }
        } catch {
            print("❌ Error seeding farm practices: \(error)")
        }
    }
    
    /// Force reseed all default practices (useful for updates)
    static func forceReseedPractices(context: NSManagedObjectContext) {
        // Delete existing practices
        let request: NSFetchRequest<FarmPractice> = FarmPractice.fetchRequest()
        
        do {
            let existingPractices = try context.fetch(request)
            for practice in existingPractices {
                context.delete(practice)
            }
            
            // Create new practices
            let defaultPractices = FarmPractice.createPredefinedPractices(in: context)
            
            try context.save()
            
            print("✅ Force reseeded \(defaultPractices.count) default farm practices")
        } catch {
            print("❌ Error force reseeding farm practices: \(error)")
        }
    }
}