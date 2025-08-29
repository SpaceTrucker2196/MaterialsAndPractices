//
//  SupplierSource+Extensions.swift
//  MaterialsAndPractices
//
//  Non-conflicting extensions for the Core Data–generated SupplierSource class.
//  Adds convenience APIs, formatting, validation, and fetch helpers.
//  NOTE: Does not redeclare any @NSManaged properties.
//

import Foundation
import CoreData

// ============================================================
// MARK: - Lightweight Type Helpers
// ============================================================

public enum SupplierKind: String, CaseIterable, Codable {
    case seed
    case fertilizer
    case amendment
    case equipment
    case service
    case packaging
    case transport
    case other
}

public extension SupplierKind {
    var displayName: String {
        switch self {
        case .seed: return "Seed"
        case .fertilizer: return "Fertilizer"
        case .amendment: return "Amendment"
        case .equipment: return "Equipment"
        case .service: return "Service"
        case .packaging: return "Packaging"
        case .transport: return "Transport"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .seed: return "leaf"
        case .fertilizer: return "drop.triangle"
        case .amendment: return "leaf.circle"
        case .equipment: return "wrench.and.screwdriver"
        case .service: return "person.2"
        case .packaging: return "shippingbox"
        case .transport: return "truck.box"
        case .other: return "building.2"
        }
    }
}

// ============================================================
// MARK: - SupplierSource Extensions
// ============================================================

public extension SupplierSource {
    /// Safe typed accessor mapping the `supplierType` String to a `SupplierKind`
    var kind: SupplierKind {
        get {
            SupplierKind(rawValue: supplierType?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? "") ?? .other
        }
        set { supplierType = newValue.rawValue }
    }

    /// Back-compat type alias (old code may have used `SupplierSource.SupplierType`)
    typealias SupplierType = SupplierKind
    var supplierTypeEnum: SupplierKind { kind }
}

// MARK: - Computed Convenience

public extension SupplierSource {
    var isCertified: Bool { isOrganicCertified }

    var isCertificationExpired: Bool {
        guard let expiry = certificationExpiryDate else { return false }
        return expiry < Date()
    }

    var daysUntilExpiry: Int? {
        guard let expiry = certificationExpiryDate else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: expiry)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    var formattedAddressSingleLine: String {
        [address, city, state, zipCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var formattedAddressMultiLine: String {
        let street = (address ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let locality = [city, state, zipCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return [street, locality].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    var fullAddress: String { formattedAddressSingleLine }

    var formattedPhoneNumber: String? {
        guard let raw = phoneNumber?.filter({ $0.isNumber }), !raw.isEmpty else { return nil }
        if raw.count == 10 {
            let a = raw.prefix(3)
            let b = raw.dropFirst(3).prefix(3)
            let c = raw.suffix(4)
            return "(\(a)) \(b)-\(c)"
        }
        return phoneNumber
    }

    var websiteURLValue: URL? {
        guard let s = websiteURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty else { return nil }
        if let url = URL(string: s), url.scheme != nil { return url }
        return URL(string: "https://\(s)")
    }

    var displayName: String {
        (name?.trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { $0.isEmpty ? nil : $0 } ?? "Unnamed Supplier"
    }

    var contactSummary: String {
        let person = contactPerson?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = formattedPhoneNumber ?? ""
        let email = self.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return [person, phone, email].filter { !$0.isEmpty }.joined(separator: " • ")
    }

    var certificationStatusText: String {
        guard isOrganicCertified else { return "Not organic certified" }
        if let d = certificationExpiryDate {
            if d < Date() { return "Organic certified (expired)" }
            if let days = daysUntilExpiry { return "Organic certified (expires in \(days) days)" }
        }
        return "Organic certified"
    }
}

// ============================================================
// MARK: - Validation
// ============================================================

public struct SupplierSourceValidationError: LocalizedError, Equatable {
    public let message: String
    public var errorDescription: String? { message }
    public static func field(_ name: String, _ issue: String) -> SupplierSourceValidationError {
        .init(message: "\(name): \(issue)")
    }
}

public extension SupplierSource {
    func validateForSave() -> [SupplierSourceValidationError] {
        var issues: [SupplierSourceValidationError] = []

        if displayName == "Unnamed Supplier" {
            issues.append(.field("name", "is required"))
        }
        if let email = email, !email.isEmpty, !email.contains("@") {
            issues.append(.field("email", "appears invalid"))
        }
        if isCertified {
            if certificationNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                issues.append(.field("certificationNumber", "is required when organic certified"))
            }
            if certificationExpiryDate == nil {
                issues.append(.field("certificationExpiryDate", "is required when organic certified"))
            }
        }
        return issues
    }
}

// ============================================================
// MARK: - Convenience Initializers / Upserts
// ============================================================

public extension SupplierSource {
    @discardableResult
    static func insert(
        in context: NSManagedObjectContext,
        guid: UUID = UUID(),
        name: String,
        kind: SupplierKind = .other,
        isOrganicCertified: Bool = false
    ) -> SupplierSource {
        let supplier = SupplierSource(context: context)
        supplier.guid = guid
        supplier.name = name
        supplier.kind = kind
        supplier.isOrganicCertified = isOrganicCertified
        return supplier
    }

    @discardableResult
    static func create(in context: NSManagedObjectContext, name: String, type: SupplierKind) -> SupplierSource {
        insert(in: context, name: name, kind: type)
    }

    func apply(
        name: String? = nil,
        contactPerson: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        websiteURL: String? = nil,
        kind: SupplierKind? = nil,
        isOrganicCertified: Bool? = nil,
        certificationNumber: String? = nil,
        certificationExpiryDate: Date? = nil,
        notes: String? = nil,
        faxNumber: String? = nil
    ) {
        if let name { self.name = name }
        if let contactPerson { self.contactPerson = contactPerson }
        if let email { self.email = email }
        if let phoneNumber { self.phoneNumber = phoneNumber }
        if let address { self.address = address }
        if let city { self.city = city }
        if let state { self.state = state }
        if let zipCode { self.zipCode = zipCode }
        if let websiteURL { self.websiteURL = websiteURL }
        if let kind { self.kind = kind }
        if let isOrganicCertified { self.isOrganicCertified = isOrganicCertified }
        if let certificationNumber { self.certificationNumber = certificationNumber }
        if let certificationExpiryDate { self.certificationExpiryDate = certificationExpiryDate }
        if let notes { self.notes = notes }
        if let faxNumber { self.faxNumber = faxNumber }
    }
}

// ============================================================
// MARK: - Fetch Helpers
// ============================================================

public extension SupplierSource {
    static func fetchRequestSortedByName() -> NSFetchRequest<SupplierSource> {
        let request: NSFetchRequest<SupplierSource> = SupplierSource.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(SupplierSource.name),
                             ascending: true,
                             selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return request
    }

    static func fetch(withID guid: UUID) -> NSFetchRequest<SupplierSource> {
        let request: NSFetchRequest<SupplierSource> = SupplierSource.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(SupplierSource.guid), guid as CVarArg)
        request.fetchLimit = 1
        return request
    }

    static func search(_ query: String) -> NSFetchRequest<SupplierSource> {
        let request: NSFetchRequest<SupplierSource> = SupplierSource.fetchRequest()
        let q = query as NSString
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(SupplierSource.name), q),
            NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(SupplierSource.contactPerson), q),
            NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(SupplierSource.city), q),
            NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(SupplierSource.state), q)
        ])
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(SupplierSource.name), ascending: true)]
        return request
    }
}
