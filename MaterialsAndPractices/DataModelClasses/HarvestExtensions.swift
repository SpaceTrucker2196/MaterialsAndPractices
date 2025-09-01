import Foundation
import CoreData

extension Harvest {
    
// MARK: - Typed accessors & enums

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


    var quantityUnit: HarvestUnit {
        get { HarvestUnit(rawValue: quantityUnitRaw) ?? .pounds }
        set { quantityUnitRaw = newValue.rawValue }
    }
    var harevestDestination: HarvestDestination {
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
    
    var quantityDisplay: String {
        let v = max(0, quantityValue)
        return String(format: "%.2f %@", v, quantityUnit.symbol)
    }
    var netQuantityDisplay: String {
        let v = max(0, netQuantityValue)
        return String(format: "%.2f %@", v, quantityUnit.symbol)
    }
    
    var isCompliant: Bool {
        sanitationVerified != .no &&
        comminglingRisk != .no &&
        contaminationRisk != .no &&
        !complianceHold &&
        isCertifiedOrganic
    }
    
    /// Generate a default lot code if missing, e.g. "2025-NFB3-TOM-0007"
    
}
