//
//  FarmPractice+CoreDataProperties.swift
//  MaterialsAndPractices
//
//  Created by GitHub Copilot for practice management functionality
//

import Foundation
import CoreData

extension FarmPractice {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FarmPractice> {
        return NSFetchRequest<FarmPractice>(entityName: "FarmPractice")
    }

    @NSManaged public var practiceID: UUID
    @NSManaged public var name: String
    @NSManaged public var descriptionText: String
    @NSManaged public var trainingRequired: String
    @NSManaged public var frequency: String
    @NSManaged public var certification: String
    @NSManaged public var lastUpdated: Date
    @NSManaged public var workOrders: NSSet?

}

// MARK: Generated accessors for workOrders
extension FarmPractice {

    @objc(addWorkOrdersObject:)
    @NSManaged public func addToWorkOrders(_ value: WorkOrder)

    @objc(removeWorkOrdersObject:)
    @NSManaged public func removeFromWorkOrders(_ value: WorkOrder)

    @objc(addWorkOrders:)
    @NSManaged public func addToWorkOrders(_ values: NSSet)

    @objc(removeWorkOrders:)
    @NSManaged public func removeFromWorkOrders(_ values: NSSet)

}

extension FarmPractice : Identifiable {

}