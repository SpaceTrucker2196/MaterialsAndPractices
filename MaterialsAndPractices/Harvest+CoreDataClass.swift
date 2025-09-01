//
//  Harvest+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for Harvest entity.
//  Provides business logic for harvest tracking and compliance management.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(Harvest)
public class Harvest: NSManagedObject {
    
    // MARK: - Enums
    
    public enum HarvestUnit: Int16, CaseIterable {
        case pounds = 0, kilograms = 1, each = 2, cases = 3, bunches = 4
        var symbol: String {
            switch self {
            case .pounds: return "lb"
            case .kilograms: return "kg"
            case .each: return "ea"
            case .cases: return "cs"
            case .bunches: return "bn"
            }
        }
    }

    public enum HarvestDestination: Int16, CaseIterable {
        case cooler = 0, packhouse = 1, washArea = 2, directSale = 3, compost = 4, other = 5
    }

    public enum ComplianceFlag: Int16, CaseIterable {
        case unknown = 0, yes = 1, no = 2
    }
    
    // MARK: - Computed Properties
    
    var quantityUnit: HarvestUnit {
        get { HarvestUnit(rawValue: quantityUnitRaw) ?? .pounds }
        set { quantityUnitRaw = newValue.rawValue }
    }
    
    var harvestDestination: HarvestDestination {
        get { HarvestDestination(rawValue: harvestDestinationRaw) ?? .cooler }
        set { harvestDestinationRaw = newValue.rawValue }
    }
    
    var sanitationVerified: ComplianceFlag {
        get { ComplianceFlag(rawValue: sanitationVerifiedRaw) ?? .unknown }
        set { sanitationVerifiedRaw = newValue.rawValue }
    }
    
    var comminglingRisk: ComplianceFlag {
        get { ComplianceFlag(rawValue: comminglingRiskRaw) ?? .unknown }
        set { comminglingRiskRaw = newValue.rawValue }
    }
    
    var contaminationRisk: ComplianceFlag {
        get { ComplianceFlag(rawValue: contaminationRiskRaw) ?? .unknown }
        set { contaminationRiskRaw = newValue.rawValue }
    }
    
    /// Display name for the harvest
    var displayName: String {
        if let notes = notes, !notes.isEmpty {
            return notes
        }
        if let harvestDate = harvestDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Harvest \(formatter.string(from: harvestDate))"
        }
        return "Harvest"
    }
    
    /// Formatted quantity display
    var quantityDisplay: String {
        let v = max(0, quantityValue)
        return String(format: "%.2f %@", v, quantityUnit.symbol)
    }
    
    /// Formatted net quantity display
    var netQuantityDisplay: String {
        let v = max(0, netQuantityValue)
        return String(format: "%.2f %@", v, quantityUnit.symbol)
    }
    
    /// Check if harvest is compliant with organic standards
    var isCompliant: Bool {
        sanitationVerified != .no &&
        comminglingRisk != .no &&
        contaminationRisk != .no &&
        !(complianceHold) &&
        (isCertifiedOrganic)
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch request sorted by harvest date
    static func fetchRequestSortedByDate() -> NSFetchRequest<Harvest> {
        let request: NSFetchRequest<Harvest> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Harvest.harvestDate, ascending: false)]
        return request
    }
    
    /// Fetch request for harvests in a specific year
    static func fetchRequestForYear(_ year: Int) -> NSFetchRequest<Harvest> {
        let request = fetchRequestSortedByDate()
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        request.predicate = NSPredicate(format: "harvestDate >= %@ AND harvestDate < %@", startOfYear as NSDate, endOfYear as NSDate)
        return request
    }
    
    /// Fetch request for harvests from active grows
    static func fetchRequestForActiveGrows() -> NSFetchRequest<Harvest> {
        let request = fetchRequestSortedByDate()
        request.predicate = NSPredicate(format: "cropPlan.grows.@count > 0 AND ANY cropPlan.grows.harvestDate == nil")
        return request
    }
}