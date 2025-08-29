//
//  SupplierSource+CoreDataProperties.swift
//  MaterialsAndPractices
//
//  Core Data properties for SupplierSource entity.
//  Auto-generated properties for supplier contact information and organic certification tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

extension SupplierSource {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SupplierSource> {
        return NSFetchRequest<SupplierSource>(entityName: "SupplierSource")
    }

    @NSManaged public var address: String?
    @NSManaged public var certificationExpiryDate: Date?
    @NSManaged public var certificationNumber: String?
    @NSManaged public var city: String?
    @NSManaged public var contactPerson: String?
    @NSManaged public var email: String?
    @NSManaged public var faxNumber: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isOrganicCertified: Bool
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var state: String?
    @NSManaged public var supplierType: String?
    @NSManaged public var websiteURL: String?
    @NSManaged public var zipCode: String?
    @NSManaged public var cropAmendments: NSSet?
    @NSManaged public var cultivars: NSSet?

}

// MARK: Generated accessors for cropAmendments
extension SupplierSource {

    @objc(addCropAmendmentsObject:)
    @NSManaged public func addToCropAmendments(_ value: CropAmendment)

    @objc(removeCropAmendmentsObject:)
    @NSManaged public func removeFromCropAmendments(_ value: CropAmendment)

    @objc(addCropAmendments:)
    @NSManaged public func addToCropAmendments(_ values: NSSet)

    @objc(removeCropAmendments:)
    @NSManaged public func removeFromCropAmendments(_ values: NSSet)

}

// MARK: Generated accessors for cultivars
extension SupplierSource {

    @objc(addCultivarsObject:)
    @NSManaged public func addToCultivars(_ value: Cultivar)

    @objc(removeCultivarsObject:)
    @NSManaged public func removeFromCultivars(_ value: Cultivar)

    @objc(addCultivars:)
    @NSManaged public func addToCultivars(_ values: NSSet)

    @objc(removeCultivars:)
    @NSManaged public func removeFromCultivars(_ values: NSSet)

}

extension SupplierSource : Identifiable {

}