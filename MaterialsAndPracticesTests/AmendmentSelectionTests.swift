//
//  AmendmentSelectionTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for amendment selection functionality and Core Data integration
//  Verifies crash fixes and proper amendment tracking for organic compliance.
//
//  Created by GitHub Copilot on 12/18/24.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class AmendmentSelectionTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Seed test amendments
        createTestAmendments()
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
    }
    
    // MARK: - Core Data Entity Tests
    
    func testCropAmendmentEntityExists() throws {
        // This test verifies the Core Data entity exists and can be fetched
        let fetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        
        // Should not crash - this was the original issue
        let amendments = try viewContext.fetch(fetchRequest)
        
        XCTAssertNotNil(amendments, "Should be able to fetch CropAmendment entities")
    }
    
    func testCropAmendmentCreation() throws {
        let amendment = CropAmendment(context: viewContext)
        amendment.productName = "Test Amendment"
        amendment.applicationRate = "1.0"
        amendment.unitOfMeasure = "lbs/acre"
        amendment.productType = "Fertilizer"
        amendment.applicationMethod = "Broadcast"
        amendment.omriListed = true
        amendment.applicatorName = "Test Applicator"
        amendment.cropTreated = "Test Crop"
        amendment.location = "Test Field"
        
        try viewContext.save()
        
        XCTAssertNotNil(amendment.amendmentID, "Amendment should have auto-generated ID")
        XCTAssertEqual(amendment.productName, "Test Amendment")
        XCTAssertTrue(amendment.omriListed)
    }
    
    func testCropAmendmentProperties() throws {
        let amendment = createTestAmendment(name: "Kelp Meal", omriListed: true)
        
        XCTAssertEqual(amendment.displayName, "Kelp Meal")
        XCTAssertEqual(amendment.organicComplianceStatus, "OMRI Listed")
        XCTAssertEqual(amendment.organicComplianceColor, "requiredForOrganic")
        XCTAssertTrue(amendment.fullDescription.contains("Kelp Meal"))
        XCTAssertTrue(amendment.fullDescription.contains("OMRI Listed"))
    }
    
    func testNonOrganicAmendmentProperties() throws {
        let amendment = createTestAmendment(name: "Synthetic NPK", omriListed: false)
        
        XCTAssertEqual(amendment.organicComplianceStatus, "Not OMRI Listed")
        XCTAssertEqual(amendment.organicComplianceColor, "failedForOrganic")
        XCTAssertTrue(amendment.fullDescription.contains("Not OMRI Listed"))
    }
    
    // MARK: - Amendment Selection Tests
    
    func testAmendmentFiltering() throws {
        // Test organic filter
        let organicFetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        organicFetchRequest.predicate = NSPredicate(format: "omriListed == YES")
        
        let organicAmendments = try viewContext.fetch(organicFetchRequest)
        XCTAssertTrue(organicAmendments.allSatisfy { $0.omriListed })
        
        // Test conventional filter
        let conventionalFetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        conventionalFetchRequest.predicate = NSPredicate(format: "omriListed == NO")
        
        let conventionalAmendments = try viewContext.fetch(conventionalFetchRequest)
        XCTAssertTrue(conventionalAmendments.allSatisfy { !$0.omriListed })
    }
    
    func testAmendmentSearch() throws {
        let searchTerm = "compost"
        let fetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "productName CONTAINS[cd] %@ OR productType CONTAINS[cd] %@ OR applicationMethod CONTAINS[cd] %@", searchTerm, searchTerm, searchTerm)
        
        let searchResults = try viewContext.fetch(fetchRequest)
        XCTAssertTrue(searchResults.allSatisfy { amendment in
            amendment.productName.localizedCaseInsensitiveContains(searchTerm) ||
            amendment.productType.localizedCaseInsensitiveContains(searchTerm) ||
            amendment.applicationMethod.localizedCaseInsensitiveContains(searchTerm)
        })
    }
    
    // MARK: - Safety Interval Tests
    
    func testSafetyIntervalInfo() throws {
        let amendment = createTestAmendment(name: "Test Pesticide", omriListed: false)
        amendment.reEntryIntervalHours = 24
        amendment.preHarvestIntervalDays = 7
        
        let safetyInfo = amendment.safetyIntervalInfo
        XCTAssertTrue(safetyInfo.contains("Re-entry: 24h"))
        XCTAssertTrue(safetyInfo.contains("Pre-harvest: 7d"))
    }
    
    func testNoSafetyIntervals() throws {
        let amendment = createTestAmendment(name: "Safe Amendment", omriListed: true)
        amendment.reEntryIntervalHours = 0
        amendment.preHarvestIntervalDays = 0
        
        XCTAssertEqual(amendment.safetyIntervalInfo, "No restrictions")
    }
    
    // MARK: - Organic Certification Status Tests
    
    func testOrganicCertificationStatusWithOrganicAmendments() {
        let organicAmendments: Set<CropAmendment> = [
            createTestAmendment(name: "Compost", omriListed: true),
            createTestAmendment(name: "Kelp Meal", omriListed: true)
        ]
        
        let hasNonOrganic = organicAmendments.contains { !$0.omriListed }
        XCTAssertFalse(hasNonOrganic, "Should not contain non-organic amendments")
    }
    
    func testOrganicCertificationStatusWithMixedAmendments() {
        let mixedAmendments: Set<CropAmendment> = [
            createTestAmendment(name: "Compost", omriListed: true),
            createTestAmendment(name: "Synthetic NPK", omriListed: false)
        ]
        
        let hasNonOrganic = mixedAmendments.contains { !$0.omriListed }
        XCTAssertTrue(hasNonOrganic, "Should contain non-organic amendments")
    }
    
    // MARK: - Amendment Seeder Tests
    
    func testAmendmentSeederCreatesAmendments() throws {
        // Clear existing amendments
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: CropAmendment.fetchRequest())
        try viewContext.execute(deleteRequest)
        
        // Run seeder
        CropAmendmentSeeder.seedAmendments(in: viewContext)
        
        let fetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        let amendments = try viewContext.fetch(fetchRequest)
        
        XCTAssertGreaterThan(amendments.count, 0, "Seeder should create amendments")
        
        // Verify some specific amendments exist
        let compostAmendments = amendments.filter { $0.productName.contains("Compost") }
        XCTAssertGreaterThan(compostAmendments.count, 0, "Should have compost amendments")
        
        let organicAmendments = amendments.filter { $0.omriListed }
        let conventionalAmendments = amendments.filter { !$0.omriListed }
        
        XCTAssertGreaterThan(organicAmendments.count, 0, "Should have organic amendments")
        XCTAssertGreaterThan(conventionalAmendments.count, 0, "Should have conventional amendments")
    }
    
    // MARK: - Performance Tests
    
    func testAmendmentFetchPerformance() throws {
        // Create many amendments for performance testing
        for i in 0..<1000 {
            let amendment = CropAmendment(context: viewContext)
            amendment.productName = "Amendment \(i)"
            amendment.applicationRate = "1.0"
            amendment.unitOfMeasure = "lbs/acre"
            amendment.productType = "Test"
            amendment.applicationMethod = "Broadcast"
            amendment.omriListed = i % 2 == 0
            amendment.applicatorName = "Test"
            amendment.cropTreated = "Test"
            amendment.location = "Test"
        }
        
        try viewContext.save()
        
        measure {
            let fetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \CropAmendment.omriListed, ascending: false),
                NSSortDescriptor(keyPath: \CropAmendment.productName, ascending: true)
            ]
            
            do {
                _ = try viewContext.fetch(fetchRequest)
            } catch {
                XCTFail("Fetch should not fail: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestAmendments() {
        // Create test amendments for testing
        let organicAmendment = createTestAmendment(name: "Organic Compost", omriListed: true)
        organicAmendment.productType = "Soil Amendment"
        organicAmendment.applicationMethod = "Broadcast"
        
        let conventionalAmendment = createTestAmendment(name: "Synthetic Fertilizer", omriListed: false)
        conventionalAmendment.productType = "Fertilizer"
        conventionalAmendment.applicationMethod = "Injection"
        conventionalAmendment.epaRegistrationNumber = "EPA-12345"
        
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save test amendments: \(error)")
        }
    }
    
    @discardableResult
    private func createTestAmendment(name: String, omriListed: Bool) -> CropAmendment {
        let amendment = CropAmendment(context: viewContext)
        amendment.productName = name
        amendment.applicationRate = "1.0"
        amendment.unitOfMeasure = "lbs/acre"
        amendment.productType = "Test"
        amendment.applicationMethod = "Test Method"
        amendment.omriListed = omriListed
        amendment.applicatorName = "Test Applicator"
        amendment.cropTreated = "Test Crop"
        amendment.location = "Test Field"
        
        return amendment
    }
}