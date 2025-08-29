//
//  SupplierSource+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for SupplierSource entity representing farm supply companies and seed sources.
//  Manages supplier contact information, organic certification status, and relationships to 
//  cultivars and crop amendments for compliance tracking.
//
//  Features:
//  - Complete contact information tracking (name, address, phone, email, website)
//  - Organic certification status and expiry date management
//  - Supplier type categorization (seed, amendment, equipment, etc.)
//  - Relationships to cultivars as seed sources and crop amendments as suppliers
//  - Search and filtering support with proper indexing
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(SupplierSource)
public class SupplierSource: NSManagedObject {
    
    // MARK: - Convenience Properties
    
    /// Formatted display name for the supplier
    public var displayName: String {
        return name ?? "Unknown Supplier"
    }
    
    /// Full address string for display purposes
    public var fullAddress: String {
        var components: [String] = []
        
        if let address = address, !address.isEmpty {
            components.append(address)
        }
        
        var cityStateZip: [String] = []
        if let city = city, !city.isEmpty {
            cityStateZip.append(city)
        }
        if let state = state, !state.isEmpty {
            cityStateZip.append(state)
        }
        if let zipCode = zipCode, !zipCode.isEmpty {
            cityStateZip.append(zipCode)
        }
        
        if !cityStateZip.isEmpty {
            components.append(cityStateZip.joined(separator: ", "))
        }
        
        return components.joined(separator: "\n")
    }
    
    /// Primary contact information (phone or email)
    public var primaryContact: String? {
        if let phone = phoneNumber, !phone.isEmpty {
            return phone
        }
        return email
    }
    
    /// Certification status display text
    public var certificationStatusText: String {
        if isOrganicCertified {
            if let expiryDate = certificationExpiryDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Certified (expires \(formatter.string(from: expiryDate)))"
            } else {
                return "Organic Certified"
            }
        } else {
            return "Not Certified"
        }
    }
    
    /// Check if certification is expired or expiring soon
    public var isCertificationExpiringSoon: Bool {
        guard isOrganicCertified, let expiryDate = certificationExpiryDate else {
            return false
        }
        
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiryDate <= thirtyDaysFromNow
    }
    
    /// Supplier type as enum for better type safety
    public enum SupplierType: String, CaseIterable {
        case seed = "Seed"
        case amendment = "Amendment"
        case equipment = "Equipment"
        case fertilizer = "Fertilizer"
        case pesticide = "Pesticide"
        case organic = "Organic Inputs"
        case general = "General Farm Supply"
        case nursery = "Nursery"
        
        var displayName: String {
            return rawValue
        }
        
        var icon: String {
            switch self {
            case .seed:
                return "leaf.fill"
            case .amendment:
                return "flask.fill"
            case .equipment:
                return "wrench.and.screwdriver.fill"
            case .fertilizer:
                return "drop.fill"
            case .pesticide:
                return "shield.fill"
            case .organic:
                return "checkmark.seal.fill"
            case .general:
                return "building.2.fill"
            case .nursery:
                return "tree.fill"
            }
        }
    }
    
    /// Supplier type as enum value
    public var supplierTypeEnum: SupplierType? {
        get {
            guard let typeString = supplierType else { return nil }
            return SupplierType(rawValue: typeString)
        }
        set {
            supplierType = newValue?.rawValue
        }
    }
    
    // MARK: - Relationships Helpers
    
    /// Array of associated cultivars for seed sources
    public var cultivarsArray: [Cultivar] {
        let set = cultivars as? Set<Cultivar> ?? []
        return Array(set).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    /// Array of associated crop amendments
    public var cropAmendmentsArray: [CropAmendment] {
        let set = cropAmendments as? Set<CropAmendment> ?? []
        return Array(set).sorted { ($0.productName ?? "") < ($1.productName ?? "") }
    }
    
    /// Count of associated products
    public var productCount: Int {
        return cultivarsArray.count + cropAmendmentsArray.count
    }
    
    // MARK: - Factory Methods
    
    /// Create a new supplier source with default values
    /// - Parameters:
    ///   - context: Core Data managed object context
    ///   - name: Supplier name
    ///   - type: Supplier type
    /// - Returns: New SupplierSource instance
    public static func create(in context: NSManagedObjectContext, 
                             name: String, 
                             type: SupplierType) -> SupplierSource {
        let supplier = SupplierSource(context: context)
        supplier.id = UUID()
        supplier.name = name
        supplier.supplierTypeEnum = type
        supplier.isOrganicCertified = false
        return supplier
    }
    
    // MARK: - Validation
    
    /// Validate supplier data before saving
    /// - Throws: ValidationError if data is invalid
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try validateSupplierData()
    }
    
    public override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateSupplierData()
    }
    
    private func validateSupplierData() throws {
        // Validate required fields
        guard let supplierName = name, !supplierName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("name")
        }
        
        // Validate email format if provided
        if let emailAddress = email, !emailAddress.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: emailAddress) {
                throw ValidationError.invalidEmailFormat
            }
        }
        
        // Validate certification expiry date
        if isOrganicCertified, let expiryDate = certificationExpiryDate, expiryDate < Date() {
            // Allow expired certifications but flag them
            print("Warning: Supplier \(name ?? "Unknown") has expired organic certification")
        }
    }
    
    // MARK: - Search Support
    
    /// Create fetch request for suppliers matching search criteria
    /// - Parameters:
    ///   - searchText: Text to search in name, contact person, and notes
    ///   - type: Optional supplier type filter
    ///   - organicOnly: Filter for organic certified suppliers only
    /// - Returns: Configured fetch request
    public static func searchFetchRequest(searchText: String? = nil,
                                        type: SupplierType? = nil,
                                        organicOnly: Bool = false) -> NSFetchRequest<SupplierSource> {
        let request: NSFetchRequest<SupplierSource> = SupplierSource.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Search text filter
        if let searchText = searchText, !searchText.isEmpty {
            let searchPredicate = NSPredicate(format: 
                "name CONTAINS[cd] %@ OR contactPerson CONTAINS[cd] %@ OR notes CONTAINS[cd] %@",
                searchText, searchText, searchText)
            predicates.append(searchPredicate)
        }
        
        // Supplier type filter
        if let type = type {
            predicates.append(NSPredicate(format: "supplierType == %@", type.rawValue))
        }
        
        // Organic certification filter
        if organicOnly {
            predicates.append(NSPredicate(format: "isOrganicCertified == YES"))
        }
        
        // Combine all predicates
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Sort by name
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)]
        
        return request
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidEmailFormat
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidEmailFormat:
            return "Invalid email format"
        }
    }
}