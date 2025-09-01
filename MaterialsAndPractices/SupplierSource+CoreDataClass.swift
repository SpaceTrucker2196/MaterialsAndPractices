//
//  SupplierSource+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for SupplierSource entity.
//  Provides business logic for supplier contact information and organic certification tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(SupplierSource)
public class SupplierSource: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Display name for the supplier
    var displayName: String {
        return name ?? "Unknown Supplier"
    }
    
    /// Supplier kind enum from string value
    var kind: SupplierKind {
        return SupplierKind(rawValue: supplierType ?? "") ?? .other
    }
    
    /// Check if supplier is certified (has organic certification)
    var isCertified: Bool {
        return isOrganicCertified && certificationNumber != nil && certificationExpiryDate != nil
    }
    
    /// Check if certification is expired
    var isCertificationExpired: Bool {
        guard let expiryDate = certificationExpiryDate else { return false }
        return Date() > expiryDate
    }
    
    /// Days until certification expiry (negative if expired)
    var daysUntilExpiry: Int {
        guard let expiryDate = certificationExpiryDate else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }
    
    /// Formatted phone number
    var formattedPhoneNumber: String? {
        guard let phone = phoneNumber, !phone.isEmpty else { return nil }
        
        // Remove all non-numeric characters
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Format as (XXX) XXX-XXXX if 10 digits
        if digits.count == 10 {
            let area = String(digits.prefix(3))
            let exchange = String(digits.dropFirst(3).prefix(3))
            let number = String(digits.suffix(4))
            return "(\(area)) \(exchange)-\(number)"
        }
        
        return phone
    }
    
    /// Full address string
    var fullAddress: String {
        var components: [String] = []
        
        if let address = address, !address.isEmpty {
            components.append(address)
        }
        if let city = city, !city.isEmpty {
            components.append(city)
        }
        if let state = state, !state.isEmpty {
            components.append(state)
        }
        if let zip = zipCode, !zip.isEmpty {
            components.append(zip)
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Array of cultivars sorted by name
    var cultivarsArray: [Cultivar] {
        let set = cultivars as? Set<Cultivar> ?? []
        return Array(set).sorted { ($0.name) < ($1.name) }
    }
    
    /// Array of seed library entries sorted by name
    var seedArray: [SeedLibrary] {
        let set = seed as? Set<SeedLibrary> ?? []
        return Array(set).sorted { ($0.seedName ?? "") < ($1.seedName ?? "") }
    }
    
    // MARK: - Validation
    
    /// Validation errors for supplier
    func validateForSave() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Name is required
        if name?.isEmpty != false {
            errors.append(ValidationError(field: "name", message: "Supplier name is required"))
        }
        
        // Email format validation
        if let email = email, !email.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                errors.append(ValidationError(field: "email", message: "Invalid email format"))
            }
        }
        
        // Organic certification validation
        if isOrganicCertified {
            if certificationNumber?.isEmpty != false {
                errors.append(ValidationError(field: "certificationNumber", message: "Certification number required for organic suppliers"))
            }
            if certificationExpiryDate == nil {
                errors.append(ValidationError(field: "certificationExpiryDate", message: "Certification expiry date required for organic suppliers"))
            }
        }
        
        return errors
    }
}

// MARK: - Fetch Request Helpers

extension SupplierSource {
    
    /// Fetch request sorted by name
    static func fetchRequestSortedByName() -> NSFetchRequest<SupplierSource> {
        let request: NSFetchRequest<SupplierSource> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)]
        return request
    }
    
    /// Fetch request for specific supplier type
    static func fetchRequestForType(_ type: SupplierKind) -> NSFetchRequest<SupplierSource> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "supplierType == %@", type.rawValue)
        return request
    }
    
    /// Fetch request for organic certified suppliers only
    static func fetchRequestOrganicOnly() -> NSFetchRequest<SupplierSource> {
        let request = fetchRequestSortedByName()
        request.predicate = NSPredicate(format: "isOrganicCertified == YES")
        return request
    }
}

// MARK: - Supporting Types

/// Validation error structure
struct ValidationError {
    let field: String
    let message: String
}