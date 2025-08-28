//
//  CropAmendment+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Tracks crop amendments for organic certification compliance and
//  record keeping. Supports OMRI listing verification and application tracking.
//
//  Created by GitHub Copilot on 12/18/24.
//

import Foundation
import CoreData

@objc(CropAmendment)
public class CropAmendment: NSManagedObject {
    
    /// Convenience initializer for creating new crop amendments
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: CropAmendment.entity(), insertInto: context)
        self.amendmentID = UUID()
        self.dateApplied = Date()
        self.omriListed = true // Default to organic-compliant
    }
    
    /// Formatted display name for the amendment
    var displayName: String {
        return productName.isEmpty ? "Unnamed Amendment" : productName
    }
    
    /// Application rate with unit for display
    var formattedApplicationRate: String {
        if applicationRate.isEmpty || unitOfMeasure.isEmpty {
            return "Rate not specified"
        }
        return "\(applicationRate) \(unitOfMeasure)"
    }
    
    /// Organic compliance status text
    var organicComplianceStatus: String {
        return omriListed ? "OMRI Listed" : "Not OMRI Listed"
    }
    
    /// Color for organic compliance display
    var organicComplianceColor: String {
        return omriListed ? "requiredForOrganic" : "failedForOrganic"
    }
    
    /// Safety interval information
    var safetyIntervalInfo: String {
        var info: [String] = []
        
        if reEntryIntervalHours > 0 {
            info.append("Re-entry: \(reEntryIntervalHours)h")
        }
        
        if preHarvestIntervalDays > 0 {
            info.append("Pre-harvest: \(preHarvestIntervalDays)d")
        }
        
        return info.isEmpty ? "No restrictions" : info.joined(separator: ", ")
    }
    
    /// Full description for work order notes
    var fullDescription: String {
        var description = "Amendment: \(displayName)"
        
        if !applicationRate.isEmpty && !unitOfMeasure.isEmpty {
            description += " - Rate: \(applicationRate) \(unitOfMeasure)"
        }
        
        if !applicationMethod.isEmpty {
            description += " - Method: \(applicationMethod)"
        }
        
        description += " - \(organicComplianceStatus)"
        
        if !safetyIntervalInfo.isEmpty && safetyIntervalInfo != "No restrictions" {
            description += " - \(safetyIntervalInfo)"
        }
        
        return description
    }
}