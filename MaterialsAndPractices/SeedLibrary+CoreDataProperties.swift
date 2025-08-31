//
//  SeedLibrary+CoreDataProperties.swift
//  MaterialsAndPractices
//
//  Core Data properties for SeedLibrary entity.
//  Auto-generated properties for seed inventory management and organic certification tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

extension SeedLibrary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SeedLibrary> {
        return NSFetchRequest<SeedLibrary>(entityName: "SeedLibrary")
    }

    @NSManaged public var createdDate: Date?
    @NSManaged public var germinationRate: Double
    @NSManaged public var germinationTestDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var intendedUse: String?
    @NSManaged public var isCertifiedOrganic: Bool
    @NSManaged public var isGMO: Bool
    @NSManaged public var isUntreated: Bool
    @NSManaged public var lastModifiedDate: Date?
    @NSManaged public var lotNumber: String?
    @NSManaged public var notes: String?
    @NSManaged public var origin: String?
    @NSManaged public var productionYear: Int16
    @NSManaged public var purchasedDate: Date?
    @NSManaged public var quantity: Double
    @NSManaged public var seedName: String?
    @NSManaged public var storageLocation: String?
    @NSManaged public var unit: String?
    @NSManaged public var cultivar: Cultivar?
    @NSManaged public var grows: NSSet?
    @NSManaged public var supplierSource: SupplierSource?

}

// MARK: Generated accessors for grows
extension SeedLibrary {

    @objc(addGrowsObject:)
    @NSManaged public func addToGrows(_ value: Grow)

    @objc(removeGrowsObject:)
    @NSManaged public func removeFromGrows(_ value: Grow)

    @objc(addGrows:)
    @NSManaged public func addToGrows(_ values: NSSet)

    @objc(removeGrows:)
    @NSManaged public func removeFromGrows(_ values: NSSet)

}

extension SeedLibrary : Identifiable {

}