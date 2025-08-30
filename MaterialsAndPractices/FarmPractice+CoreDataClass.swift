//
//  FarmPractice+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Created by GitHub Copilot for practice management functionality
//

import Foundation
import CoreData

@objc(FarmPractice)
public class FarmPractice: NSManagedObject {
    
    /// Creates a default FarmPractice instance
    static func createDefault(in context: NSManagedObjectContext) -> FarmPractice {
        let practice = FarmPractice(context: context)
        practice.practiceID = UUID()
        practice.name = "New Practice"
        practice.descriptionText = "Describe the recordkeeping or food safety practice."
        practice.trainingRequired = "Training details not yet provided."
        practice.frequency = "As needed"
        practice.certification = "Unspecified"
        practice.lastUpdated = Date()
        return practice
    }
    
    /// Creates predefined farm practices from the problem statement
  
}
