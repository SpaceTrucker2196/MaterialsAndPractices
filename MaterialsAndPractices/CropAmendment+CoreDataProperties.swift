//
//  CropAmendment+CoreDataProperties.swift
//  MaterialsAndPractices
//
//  Core Data properties for CropAmendment entity
//
//  Created by GitHub Copilot on 12/18/24.
//

import Foundation
import CoreData

extension CropAmendment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CropAmendment> {
        return NSFetchRequest<CropAmendment>(entityName: "CropAmendment")
    }

    @NSManaged public var amendmentID: UUID
    @NSManaged public var dateApplied: Date
    @NSManaged public var productName: String
    @NSManaged public var applicationRate: String
    @NSManaged public var unitOfMeasure: String
    @NSManaged public var cropTreated: String
    @NSManaged public var location: String
    @NSManaged public var applicationMethod: String
    @NSManaged public var productType: String
    @NSManaged public var omriListed: Bool
    @NSManaged public var epaRegistrationNumber: String?
    @NSManaged public var reEntryIntervalHours: Int16
    @NSManaged public var preHarvestIntervalDays: Int16
    @NSManaged public var weatherConditions: String?
    @NSManaged public var applicatorName: String
    @NSManaged public var applicatorCertificationID: String?
    @NSManaged public var batchLotNumber: String?
    @NSManaged public var notes: String?

}

extension CropAmendment : Identifiable {

}