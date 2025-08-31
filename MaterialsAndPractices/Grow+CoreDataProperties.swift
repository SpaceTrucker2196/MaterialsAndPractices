//
//  Grow+CoreDataProperties.swift
//  MaterialsAndPractices
//
//  Core Data properties for Grow entity.
//  Auto-generated properties for active cultivation tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

extension Grow {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Grow> {
        return NSFetchRequest<Grow>(entityName: "Grow")
    }

    @NSManaged public var address: String?
    @NSManaged public var city: String?
    @NSManaged public var county: String?
    @NSManaged public var drivingDirections: String?
    @NSManaged public var expectedHavestDate: String?
    @NSManaged public var growType: String?
    @NSManaged public var harvestDate: Date?
    @NSManaged public var inspectionStatus: String?
    @NSManaged public var locationName: String?
    @NSManaged public var lotId: String?
    @NSManaged public var manager: String?
    @NSManaged public var managerPhone: String?
    @NSManaged public var nextInspectionDue: Date?
    @NSManaged public var notes: String?
    @NSManaged public var plantedDate: Date?
    @NSManaged public var propertyOwner: String?
    @NSManaged public var propertyOwnerPhone: String?
    @NSManaged public var propertyType: String?
    @NSManaged public var size: Double
    @NSManaged public var state: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var title: String?
    @NSManaged public var zip: String?
    @NSManaged public var amendments: NSSet?
    @NSManaged public var cultivar: Cultivar?
    @NSManaged public var field: Field?
    @NSManaged public var seed: NSSet?
    @NSManaged public var work: NSSet?
    @NSManaged public var workOrders: NSSet?

}

// MARK: Generated accessors for amendments
extension Grow {

    @objc(addAmendmentsObject:)
    @NSManaged public func addToAmendments(_ value: Amendment)

    @objc(removeAmendmentsObject:)
    @NSManaged public func removeFromAmendments(_ value: Amendment)

    @objc(addAmendments:)
    @NSManaged public func addToAmendments(_ values: NSSet)

    @objc(removeAmendments:)
    @NSManaged public func removeFromAmendments(_ values: NSSet)

}

// MARK: Generated accessors for seed
extension Grow {

    @objc(addSeedObject:)
    @NSManaged public func addToSeed(_ value: SeedLibrary)

    @objc(removeSeedObject:)
    @NSManaged public func removeFromSeed(_ value: SeedLibrary)

    @objc(addSeed:)
    @NSManaged public func addToSeed(_ values: NSSet)

    @objc(removeSeed:)
    @NSManaged public func removeFromSeed(_ values: NSSet)

}

// MARK: Generated accessors for work
extension Grow {

    @objc(addWorkObject:)
    @NSManaged public func addToWork(_ value: Work)

    @objc(removeWorkObject:)
    @NSManaged public func removeFromWork(_ value: Work)

    @objc(addWork:)
    @NSManaged public func addToWork(_ values: NSSet)

    @objc(removeWork:)
    @NSManaged public func removeFromWork(_ values: NSSet)

}

// MARK: Generated accessors for workOrders
extension Grow {

    @objc(addWorkOrdersObject:)
    @NSManaged public func addToWorkOrders(_ value: WorkOrder)

    @objc(removeWorkOrdersObject:)
    @NSManaged public func removeFromWorkOrders(_ value: WorkOrder)

    @objc(addWorkOrders:)
    @NSManaged public func addToWorkOrders(_ values: NSSet)

    @objc(removeWorkOrders:)
    @NSManaged public func removeFromWorkOrders(_ values: NSSet)

}

extension Grow : Identifiable {

}