//
//  Cultivar+CoreDataProperties.swift
//  MaterialsAndPractices
//
//  Core Data properties for Cultivar entity.
//  Auto-generated properties for plant cultivar data and growing information.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

extension Cultivar {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cultivar> {
        return NSFetchRequest<Cultivar>(entityName: "Cultivar")
    }

    @NSManaged public var amendments: String?
    @NSManaged public var approvedCommonName: String?
    @NSManaged public var bestHarvest: String?
    @NSManaged public var bestPlantingDates: String?
    @NSManaged public var colorRGB: String?
    @NSManaged public var commonName: String?
    @NSManaged public var cultivarDescription: String?
    @NSManaged public var cultivarName: String?
    @NSManaged public var emoji: String?
    @NSManaged public var family: String?
    @NSManaged public var fruitName: String?
    @NSManaged public var genus: String?
    @NSManaged public var greenhouseInstructions: String?
    @NSManaged public var growingAdvice: String?
    @NSManaged public var growingDays: String?
    @NSManaged public var hardyZone: String?
    @NSManaged public var harvestInstructions: String?
    @NSManaged public var iosColor: String?
    @NSManaged public var isOrganicCertified: Bool
    @NSManaged public var name: String
    @NSManaged public var optimalZones: String?
    @NSManaged public var pests: String?
    @NSManaged public var plantingWeek: String?
    @NSManaged public var ripenessIndicators: String?
    @NSManaged public var season: String?
    @NSManaged public var soilConditions: String?
    @NSManaged public var soilInfo: String?
    @NSManaged public var transplantAge: String?
    @NSManaged public var usdaZoneList: String?
    @NSManaged public var weatherTolerance: String?
    @NSManaged public var grows: NSSet?
    @NSManaged public var seedLibrary: SeedLibrary?
    @NSManaged public var seedSources: NSSet?

}

// MARK: Generated accessors for grows
extension Cultivar {

    @objc(addGrowsObject:)
    @NSManaged public func addToGrows(_ value: Grow)

    @objc(removeGrowsObject:)
    @NSManaged public func removeFromGrows(_ value: Grow)

    @objc(addGrows:)
    @NSManaged public func addToGrows(_ values: NSSet)

    @objc(removeGrows:)
    @NSManaged public func removeFromGrows(_ values: NSSet)

}

// MARK: Generated accessors for seedSources
extension Cultivar {

    @objc(addSeedSourcesObject:)
    @NSManaged public func addToSeedSources(_ value: SupplierSource)

    @objc(removeSeedSourcesObject:)
    @NSManaged public func removeFromSeedSources(_ value: SupplierSource)

    @objc(addSeedSources:)
    @NSManaged public func addToSeedSources(_ values: NSSet)

    @objc(removeSeedSources:)
    @NSManaged public func removeFromSeedSources(_ values: NSSet)

}

extension Cultivar : Identifiable {

}