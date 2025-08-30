//
//  SupplierWorkflowTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for the complete supplier management workflow including creation, selection,
//  and association with cultivars and amendments. Ensures organic certification
//  tracking and compliance functionality works correctly.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
import SwiftUI
@testable import MaterialsAndPractices

class SupplierWorkflowTests: XCTestCase {
    var viewContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        viewContext = PersistenceController.preview.container.viewContext
    }
    
    override func tearDown() {
        viewContext = nil
        super.tearDown()
    }
    
    // MARK: - Supplier Creation Tests
    
    func testCreateSupplierWorkflow() {
        // Test basic supplier creation
        let supplier = SupplierSource(context: viewContext)
        supplier.id = UUID()
        supplier.name = "Test Organic Seeds"
        supplier.supplierType = SupplierKind.seed.rawValue
        supplier.contactPerson = "John Smith"
        supplier.phoneNumber = "555-123-4567"
        supplier.email = "john@organicseeds.com"
        supplier.address = "123 Farm Road"
        supplier.city = "Portland"
        supplier.state = "OR"
        supplier.zipCode = "97201"
        supplier.isOrganicCertified = true
        supplier.certificationNumber = "CERT-12345"
        supplier.certificationExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        
        // Test validation
        let errors = supplier.validateForSave()
        XCTAssertTrue(errors.isEmpty, "Valid supplier should have no validation errors")
        
        // Test computed properties
        XCTAssertEqual(supplier.displayName, "Test Organic Seeds")
        XCTAssertEqual(supplier.kind, .seed)
        XCTAssertTrue(supplier.isCertified)
        XCTAssertFalse(supplier.isCertificationExpired)
        XCTAssertEqual(supplier.formattedPhoneNumber, "(555) 123-4567")
        XCTAssertEqual(supplier.fullAddress, "123 Farm Road, Portland, OR, 97201")
        
        // Save to Core Data
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save supplier: \(error)")
        }
    }
    
    func testSupplierValidationErrors() {
        let supplier = SupplierSource(context: viewContext)
        supplier.id = UUID()
        supplier.name = "" // Invalid empty name
        supplier.email = "invalid-email" // Invalid email format
        supplier.isOrganicCertified = true
        // Missing certification number and expiry date
        
        let errors = supplier.validateForSave()
        XCTAssertFalse(errors.isEmpty, "Invalid supplier should have validation errors")
        
        // Check specific error types
        let errorMessages = errors.map { $0.message }
        XCTAssertTrue(errorMessages.contains { $0.contains("name") })
        XCTAssertTrue(errorMessages.contains { $0.contains("email") })
        XCTAssertTrue(errorMessages.contains { $0.contains("certificationNumber") })
        XCTAssertTrue(errorMessages.contains { $0.contains("certificationExpiryDate") })
    }
    
    func testSupplierCertificationExpiry() {
        let supplier = SupplierSource(context: viewContext)
        supplier.id = UUID()
        supplier.name = "Test Supplier"
        supplier.isOrganicCertified = true
        
        // Test expired certification
        supplier.certificationExpiryDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        XCTAssertTrue(supplier.isCertificationExpired)
        XCTAssertEqual(supplier.daysUntilExpiry, -30)
        
        // Test soon-to-expire certification
        supplier.certificationExpiryDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        XCTAssertFalse(supplier.isCertificationExpired)
        XCTAssertEqual(supplier.daysUntilExpiry, 30)
        
        // Test future certification
        supplier.certificationExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        XCTAssertFalse(supplier.isCertificationExpired)
        XCTAssertTrue((supplier.daysUntilExpiry ?? 0) > 300)
    }
    
    // MARK: - Supplier Selection Tests
    
    func testSupplierFiltering() {
        // Create test suppliers
        let seedSupplier1 = createTestSupplier(name: "Organic Seeds Co", type: .seed, certified: true)
        let seedSupplier2 = createTestSupplier(name: "Heritage Seeds", type: .seed, certified: false)
        let fertilizer = createTestSupplier(name: "Organic Fertilizer Co", type: .fertilizer, certified: true)
        let amendment = createTestSupplier(name: "Compost Co", type: .amendment, certified: false)
        
        // Test filtering by type
        let seedRequest = SupplierSource.fetchRequestSortedByName()
        seedRequest.predicate = NSPredicate(format: "supplierType == %@", SupplierKind.seed.rawValue)
        
        do {
            let seedSuppliers = try viewContext.fetch(seedRequest)
            XCTAssertEqual(seedSuppliers.count, 2)
            XCTAssertTrue(seedSuppliers.contains(seedSupplier1))
            XCTAssertTrue(seedSuppliers.contains(seedSupplier2))
        } catch {
            XCTFail("Failed to fetch seed suppliers: \(error)")
        }
        
        // Test filtering by organic certification
        let organicRequest = SupplierSource.fetchRequestSortedByName()
        organicRequest.predicate = NSPredicate(format: "isOrganicCertified == YES")
        
        do {
            let organicSuppliers = try viewContext.fetch(organicRequest)
            XCTAssertEqual(organicSuppliers.count, 2)
            XCTAssertTrue(organicSuppliers.contains(seedSupplier1))
            XCTAssertTrue(organicSuppliers.contains(fertilizer))
        } catch {
            XCTFail("Failed to fetch organic suppliers: \(error)")
        }
    }
    
    func testSupplierSearch() {
        // Create test suppliers
        createTestSupplier(name: "Organic Valley Seeds", type: .seed, certified: true)
        createTestSupplier(name: "Heritage Seed Company", type: .seed, certified: false)
        createTestSupplier(name: "Portland Compost", type: .amendment, certified: true)
        
        // Test search by name
        let searchRequest = SupplierSource.search("Organic")
        do {
            let results = try viewContext.fetch(searchRequest)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.name, "Organic Valley Seeds")
        } catch {
            XCTFail("Search failed: \(error)")
        }
        
        // Test search by city
        createTestSupplier(name: "Seattle Seeds", type: .seed, certified: true, city: "Seattle")
        let citySearchRequest = SupplierSource.search("Seattle")
        do {
            let results = try viewContext.fetch(citySearchRequest)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.name, "Seattle Seeds")
        } catch {
            XCTFail("City search failed: \(error)")
        }
    }
    
    // MARK: - Cultivar Association Tests
    
    func testCultivarSupplierAssociation() {
        // Create test data
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Tomato"
        cultivar.isOrganicCertified = true
        
        let supplier = createTestSupplier(name: "Organic Seeds", type: .seed, certified: true)
        
        // Test association
        cultivar.addToSeedSources(supplier)
        
        // Verify relationships
        XCTAssertEqual(cultivar.seedSourcesArray.count, 1)
        XCTAssertEqual(cultivar.seedSourcesArray.first, supplier)
        
        let supplierCultivars = supplier.cultivars as? Set<Cultivar> ?? []
        XCTAssertTrue(supplierCultivars.contains(cultivar))
        
        // Save and verify persistence
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save association: \(error)")
        }
    }
    
    func testMultipleSupplierAssociation() {
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Cultivar"
        
        // Create multiple suppliers
        let supplier1 = createTestSupplier(name: "Supplier 1", type: .seed, certified: true)
        let supplier2 = createTestSupplier(name: "Supplier 2", type: .seed, certified: false)
        let supplier3 = createTestSupplier(name: "Supplier 3", type: .seed, certified: true)
        
        // Associate all suppliers
        cultivar.addToSeedSources(supplier1)
        cultivar.addToSeedSources(supplier2)
        cultivar.addToSeedSources(supplier3)
        
        // Verify all associations
        XCTAssertEqual(cultivar.seedSourcesArray.count, 3)
        XCTAssertTrue(cultivar.seedSourcesArray.contains(supplier1))
        XCTAssertTrue(cultivar.seedSourcesArray.contains(supplier2))
        XCTAssertTrue(cultivar.seedSourcesArray.contains(supplier3))
        
        // Test removal
        cultivar.removeFromSeedSources(supplier2)
        XCTAssertEqual(cultivar.seedSourcesArray.count, 2)
        XCTAssertFalse(cultivar.seedSourcesArray.contains(supplier2))
    }
    
    // MARK: - Amendment Association Tests
    
    func testAmendmentSupplierAssociation() {
        // Create test amendment
        let amendment = CropAmendment(context: viewContext)
        amendment.productName = "Test Compost"
        amendment.productType = "Organic Matter"
        amendment.omriListed = true
        amendment.currentInventoryAmount = 100.0
        
        let supplier = createTestSupplier(name: "Compost Supplier", type: .amendment, certified: true)
        
        // Test association
        amendment.supplier = supplier
        
        // Verify relationships
        XCTAssertEqual(amendment.supplier, supplier)
        
        let supplierAmendments = supplier.cropAmendments as? Set<CropAmendment> ?? []
        XCTAssertTrue(supplierAmendments.contains(amendment))
        
        // Save and verify persistence
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save amendment association: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testSupplierCreationPerformance() {
        measure {
            for i in 0..<100 {
                createTestSupplier(
                    name: "Performance Supplier \(i)",
                    type: i % 2 == 0 ? .seed : .amendment,
                    certified: i % 3 == 0
                )
            }
        }
    }
    
    func testSupplierSearchPerformance() {
        // Create many suppliers
        for i in 0..<1000 {
            createTestSupplier(
                name: "Supplier \(i)",
                type: .seed,
                certified: i % 2 == 0
            )
        }
        
        measure {
            let request = SupplierSource.search("Supplier 5")
            do {
                _ = try viewContext.fetch(request)
            } catch {
                XCTFail("Search performance test failed: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @discardableResult
    private func createTestSupplier(
        name: String,
        type: SupplierKind,
        certified: Bool,
        city: String = "Test City"
    ) -> SupplierSource {
        let supplier = SupplierSource(context: viewContext)
        supplier.id = UUID()
        supplier.name = name
        supplier.supplierType = type.rawValue
        supplier.city = city
        supplier.isOrganicCertified = certified
        
        if certified {
            supplier.certificationNumber = "CERT-\(UUID().uuidString.prefix(8))"
            supplier.certificationExpiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        }
        
        return supplier
    }
}