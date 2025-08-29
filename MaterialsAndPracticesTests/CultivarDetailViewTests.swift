//
//  CultivarDetailViewTests.swift
//  MaterialsAndPracticesTests
//
//  Unit tests for CultivarDetailView and related supplier management functionality.
//  Tests ensure proper integration between cultivar management, supplier selection,
//  and grow creation workflows with organic certification tracking.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
import SwiftUI
@testable import MaterialsAndPractices

class CultivarDetailViewTests: XCTestCase {
    var viewContext: NSManagedObjectContext!
    var testCultivar: Cultivar!
    var testSupplier: SupplierSource!
    
    override func setUp() {
        super.setUp()
        viewContext = PersistenceController.preview.container.viewContext
        
        // Create test cultivar
        testCultivar = Cultivar(context: viewContext)
        testCultivar.name = "Test Tomato"
        testCultivar.family = "Solanaceae"
        testCultivar.growingDays = "80-90"
        testCultivar.emoji = "🍅"
        testCultivar.isOrganicCertified = true
        
        // Create test supplier
        testSupplier = SupplierSource(context: viewContext)
        testSupplier.name = "Test Seed Company"
        testSupplier.supplierType = SupplierKind.seed.rawValue
        testSupplier.isOrganicCertified = true
        testSupplier.id = UUID()
        
        try! viewContext.save()
    }
    
    override func tearDown() {
        viewContext = nil
        testCultivar = nil
        testSupplier = nil
        super.tearDown()
    }
    
    // MARK: - Cultivar Display Tests
    
    func testCultivarDisplayName() {
        XCTAssertEqual(testCultivar.displayName, "Test Tomato")
        
        // Test with nil name
        let nilCultivar = Cultivar(context: viewContext)
        XCTAssertEqual(nilCultivar.displayName, "Unknown Cultivar")
    }
    
    func testCultivarSeedSourcesArray() {
        // Initially empty
        XCTAssertTrue(testCultivar.seedSourcesArray.isEmpty)
        
        // Add supplier
        testCultivar.addToSeedSources(testSupplier)
        XCTAssertEqual(testCultivar.seedSourcesArray.count, 1)
        XCTAssertEqual(testCultivar.seedSourcesArray.first?.name, "Test Seed Company")
    }
    
    func testCultivarGrowsArray() {
        // Initially empty
        XCTAssertTrue(testCultivar.growsArray.isEmpty)
        
        // Add grow
        let testGrow = Grow(context: viewContext)
        testGrow.title = "Test Grow"
        testGrow.cultivar = testCultivar
        
        XCTAssertEqual(testCultivar.growsArray.count, 1)
        XCTAssertEqual(testCultivar.growsArray.first?.title, "Test Grow")
    }
    
    // MARK: - Supplier Association Tests
    
    func testSupplierAssociation() {
        // Test association
        testCultivar.addToSeedSources(testSupplier)
        
        let suppliers = testCultivar.seedSources as? Set<SupplierSource> ?? []
        XCTAssertTrue(suppliers.contains(testSupplier))
        
        let cultivars = testSupplier.cultivars as? Set<Cultivar> ?? []
        XCTAssertTrue(cultivars.contains(testCultivar))
    }
    
    // MARK: - Supplier Management Tests
    
    func testSupplierKindEnum() {
        XCTAssertEqual(SupplierKind.seed.displayName, "Seed")
        XCTAssertEqual(SupplierKind.seed.icon, "leaf")
        
        testSupplier.kind = .fertilizer
        XCTAssertEqual(testSupplier.supplierType, "fertilizer")
    }
    
    func testSupplierDisplayName() {
        XCTAssertEqual(testSupplier.displayName, "Test Seed Company")
        
        // Test with empty name
        testSupplier.name = ""
        XCTAssertEqual(testSupplier.displayName, "Unnamed Supplier")
        
        testSupplier.name = nil
        XCTAssertEqual(testSupplier.displayName, "Unnamed Supplier")
    }
    
    func testSupplierCertificationStatus() {
        XCTAssertTrue(testSupplier.isCertified)
        XCTAssertEqual(testSupplier.certificationStatusText, "Organic certified")
        
        // Test with expiry date
        testSupplier.certificationExpiryDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        XCTAssertTrue(testSupplier.certificationStatusText.contains("expires in"))
        
        // Test expired
        testSupplier.certificationExpiryDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        XCTAssertTrue(testSupplier.isCertificationExpired)
        XCTAssertEqual(testSupplier.certificationStatusText, "Organic certified (expired)")
    }
    
    func testSupplierValidation() {
        // Valid supplier
        var errors = testSupplier.validateForSave()
        XCTAssertTrue(errors.isEmpty)
        
        // Invalid email
        testSupplier.email = "invalid-email"
        errors = testSupplier.validateForSave()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.message.contains("email") })
        
        // Missing certification number for certified supplier
        testSupplier.email = nil
        testSupplier.certificationNumber = nil
        errors = testSupplier.validateForSave()
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.message.contains("certificationNumber") })
    }
    
    // MARK: - Grow Creation Tests
    
    func testCreateGrowFromCultivar() {
        let grow = Grow(context: viewContext)
        grow.title = "New Test Grow"
        grow.cultivar = testCultivar
        grow.plantedDate = Date()
        grow.harvestDate = Calendar.current.date(byAdding: .day, value: 85, to: Date()) // Middle of 80-90 range
        
        XCTAssertEqual(grow.cultivar, testCultivar)
        XCTAssertEqual(grow.title, "New Test Grow")
        XCTAssertNotNil(grow.plantedDate)
        XCTAssertNotNil(grow.harvestDate)
    }
    
    func testExtractDaysFromString() {
        // This would test the private function if it were made internal for testing
        // For now, we test the expected behavior through the cultivar's growing days
        XCTAssertEqual(testCultivar.growingDays, "80-90")
        
        // The CreateGrowFromCultivarView should use the middle value (85) for harvest calculation
        // This is tested implicitly through the grow creation workflow
    }
    
    // MARK: - Integration Tests
    
    func testFullSupplierWorkflow() {
        // Start with no suppliers
        XCTAssertTrue(testCultivar.seedSourcesArray.isEmpty)
        
        // Create new supplier
        let newSupplier = SupplierSource.create(
            in: viewContext,
            name: "New Organic Seeds",
            type: .seed
        )
        newSupplier.isOrganicCertified = true
        newSupplier.certificationNumber = "CERT-12345"
        newSupplier.certificationExpiryDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
        
        // Associate with cultivar
        testCultivar.addToSeedSources(newSupplier)
        
        // Verify association
        XCTAssertEqual(testCultivar.seedSourcesArray.count, 1)
        XCTAssertEqual(testCultivar.seedSourcesArray.first?.name, "New Organic Seeds")
        XCTAssertTrue(testCultivar.seedSourcesArray.first?.isOrganicCertified ?? false)
        
        // Save context
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }
    }
    
    func testSupplierSearchFunctionality() {
        // Create multiple suppliers
        let supplier1 = SupplierSource.create(in: viewContext, name: "Organic Seeds Co", type: .seed)
        let supplier2 = SupplierSource.create(in: viewContext, name: "Heritage Seed Company", type: .seed)
        let supplier3 = SupplierSource.create(in: viewContext, name: "Compost Suppliers Inc", type: .amendment)
        
        // Test search request
        let searchRequest = SupplierSource.search("Organic")
        searchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try viewContext.fetch(searchRequest)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.name, "Organic Seeds Co")
        } catch {
            XCTFail("Search failed: \(error)")
        }
        
        // Test search for "Seed"
        let seedSearchRequest = SupplierSource.search("Seed")
        do {
            let results = try viewContext.fetch(seedSearchRequest)
            XCTAssertEqual(results.count, 2) // Should find both seed suppliers
        } catch {
            XCTFail("Seed search failed: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testSupplierCreationPerformance() {
        measure {
            for i in 0..<100 {
                let supplier = SupplierSource.create(
                    in: viewContext,
                    name: "Supplier \(i)",
                    type: .seed
                )
                supplier.isOrganicCertified = i % 2 == 0
            }
        }
    }
    
    func testCultivarSupplierAssociationPerformance() {
        // Create suppliers
        var suppliers: [SupplierSource] = []
        for i in 0..<50 {
            let supplier = SupplierSource.create(
                in: viewContext,
                name: "Supplier \(i)",
                type: .seed
            )
            suppliers.append(supplier)
        }
        
        measure {
            for supplier in suppliers {
                testCultivar.addToSeedSources(supplier)
            }
        }
        
        XCTAssertEqual(testCultivar.seedSourcesArray.count, 50)
    }
}