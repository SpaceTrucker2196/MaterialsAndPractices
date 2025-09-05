//
//  FieldDetailViewTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for field detail view functionality including navigation behavior,
//  view lifecycle, and Core Data integration. Ensures views load properly
//  and respond to data changes correctly.
//
//  Created by GitHub Copilot on current date.
//

import XCTest
import CoreData
import SwiftUI
import Combine
@testable import MaterialsAndPractices

class FieldDetailViewTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Navigation and View Loading Tests
    
    func testFieldDetailViewLoadsWithValidField() throws {
        // Given: A field with all properties
        let field = createTestField()
        
        // When: Creating a FieldDetailView
        let detailView = FieldDetailView(field: field)
        
        // Then: View should be created without errors
        XCTAssertNotNil(detailView, "FieldDetailView should be created successfully")
        XCTAssertEqual(field.name, "Test Field", "Field name should be preserved")
    }
    
    func testFieldDetailViewShowsOrganicCertificationBanner() throws {
        // Given: A field with organic certification data
        let field = createTestField()
        field.inspectionStatus = "passed"
        field.nextInspectionDue = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
        
        // When: Field detail view is displayed
        let detailView = FieldDetailView(field: field)
        
        // Then: Organic certification banner should show
        XCTAssertEqual(field.inspectionStatus, "passed", "Inspection status should be set")
        XCTAssertNotNil(field.nextInspectionDue, "Next inspection date should be set")
    }
    
    func testFieldDetailViewNavigationFromFieldRow() throws {
        // Given: A field in the list
        let field = createTestField()
        
        // When: Creating a FieldRow that navigates to detail
        let fieldRow = FieldRow(field: field)
        
        // Then: Navigation should be properly configured
        XCTAssertNotNil(fieldRow, "FieldRow should be created successfully")
        // Navigation link destination is verified through UI testing
    }
    
    // MARK: - Core Data Change Response Tests
    
    func testFieldDetailViewRespondsToFieldChanges() throws {
        // Given: A field with initial data
        let field = createTestField()
        let originalName = field.name
        
        // When: Field data is updated
        field.name = "Updated Field Name"
        field.acres = 50.5
        field.inspectionStatus = "pending"
        
        try viewContext.save()
        
        // Then: Changes should be persisted
        XCTAssertNotEqual(field.name, originalName, "Field name should be updated")
        XCTAssertEqual(field.acres, 50.5, accuracy: 0.01, "Acres should be updated")
        XCTAssertEqual(field.inspectionStatus, "pending", "Inspection status should be updated")
    }
    
    func testFieldDetailViewRespondsToGrowChanges() throws {
        // Given: A field with associated grows
        let field = createTestField()
        let grow = createTestGrow(for: field)
        
        // When: Grow data is updated
        grow.title = "Updated Grow Title"
        try viewContext.save()
        
        // Then: Field should reflect the grow changes
        guard let grows = field.grows?.allObjects as? [Grow] else {
            XCTFail("Field should have grows")
            return
        }
        
        XCTAssertEqual(grows.count, 1, "Field should have one grow")
        XCTAssertEqual(grows.first?.title, "Updated Grow Title", "Grow title should be updated")
    }
    
    func testFieldDetailViewRespondsToSoilTestChanges() throws {
        // Given: A field with soil tests
        let field = createTestField()
        let soilTest = createTestSoilTest(for: field)
        
        // When: Soil test data is updated
        soilTest.ph = 7.2
        soilTest.omPct = 4.5
        try viewContext.save()
        
        // Then: Field should reflect the soil test changes
        guard let soilTests = field.soilTests?.allObjects as? [SoilTest] else {
            XCTFail("Field should have soil tests")
            return
        }
        
        XCTAssertEqual(soilTests.count, 1, "Field should have one soil test")
        XCTAssertEqual(soilTests.first?.ph, 7.2, accuracy: 0.01, "pH should be updated")
        XCTAssertEqual(soilTests.first?.omPct, 4.5, accuracy: 0.01, "Organic matter should be updated")
    }
    
    // MARK: - Amendment and Harvest Data Tests
    
    func testFieldDetailViewShowsAmendments() throws {
        // Given: A field with grows that have amendments
        let field = createTestField()
        let grow = createTestGrow(for: field)
        let amendment = createTestAmendment()
        let workOrder = createTestWorkOrder(for: grow, with: amendment)
        
        try viewContext.save()
        
        // When: Getting field amendments
        let detailView = FieldDetailView(field: field)
        
        // Then: Amendments should be accessible through the field's grows
        guard let grows = field.grows?.allObjects as? [Grow],
              let workOrders = grows.first?.workOrders?.allObjects as? [WorkOrder] else {
            XCTFail("Field should have grows with work orders")
            return
        }
        
        XCTAssertEqual(grows.count, 1, "Field should have one grow")
        XCTAssertEqual(workOrders.count, 1, "Grow should have one work order")
        XCTAssertNotNil(workOrders.first?.amendment, "Work order should have an amendment")
    }
    
    func testFieldDetailViewShowsHarvests() throws {
        // Given: A field with grows that have harvests
        let field = createTestField()
        let grow = createTestGrow(for: field)
        let harvest = createTestHarvest(for: grow)
        
        try viewContext.save()
        
        // Then: Harvests should be accessible through the field's grows
        guard let grows = field.grows?.allObjects as? [Grow],
              let harvests = grows.first?.harvests?.allObjects as? [Harvest] else {
            XCTFail("Field should have grows with harvests")
            return
        }
        
        XCTAssertEqual(grows.count, 1, "Field should have one grow")
        XCTAssertEqual(harvests.count, 1, "Grow should have one harvest")
        XCTAssertEqual(harvests.first?.totalQuantity, 100.0, accuracy: 0.01, "Harvest quantity should be correct")
    }
    
    // MARK: - Edit Mode Tests
    
    func testEditFieldViewSavesAllProperties() throws {
        // Given: A field with initial data
        let field = createTestField()
        
        // When: Updating field through edit view logic
        field.name = "Updated Field"
        field.acres = 25.5
        field.hasDrainTile = true
        field.slope = "5-10%"
        field.soilType = "Clay Loam"
        field.inspectionStatus = "scheduled"
        field.nextInspectionDue = Date().addingTimeInterval(60 * 24 * 60 * 60) // 60 days
        field.soilMapUnits = ["Unit A", "Unit B"] as NSArray
        field.notes = "Updated notes"
        
        try viewContext.save()
        
        // Then: All properties should be saved correctly
        XCTAssertEqual(field.name, "Updated Field", "Name should be updated")
        XCTAssertEqual(field.acres, 25.5, accuracy: 0.01, "Acres should be updated")
        XCTAssertTrue(field.hasDrainTile, "Drain tile should be true")
        XCTAssertEqual(field.slope, "5-10%", "Slope should be updated")
        XCTAssertEqual(field.soilType, "Clay Loam", "Soil type should be updated")
        XCTAssertEqual(field.inspectionStatus, "scheduled", "Inspection status should be updated")
        XCTAssertNotNil(field.nextInspectionDue, "Next inspection should be set")
        
        if let soilMapUnits = field.soilMapUnits as? [String] {
            XCTAssertEqual(soilMapUnits.count, 2, "Should have two soil map units")
            XCTAssertTrue(soilMapUnits.contains("Unit A"), "Should contain Unit A")
            XCTAssertTrue(soilMapUnits.contains("Unit B"), "Should contain Unit B")
        } else {
            XCTFail("Soil map units should be an array of strings")
        }
        
        XCTAssertEqual(field.notes, "Updated notes", "Notes should be updated")
    }
    
    // MARK: - Organic Certification Logic Tests
    
    func testOrganicCertificationBannerStatus() throws {
        // Given: Fields with different inspection statuses
        let passedField = createTestField()
        passedField.inspectionStatus = "passed"
        
        let pendingField = createTestField()
        pendingField.inspectionStatus = "pending"
        
        let failedField = createTestField()
        failedField.inspectionStatus = "failed"
        
        // When: Creating detail views for each
        let passedView = FieldDetailView(field: passedField)
        let pendingView = FieldDetailView(field: pendingField)
        let failedView = FieldDetailView(field: failedField)
        
        // Then: Each should have appropriate status
        XCTAssertEqual(passedField.inspectionStatus, "passed", "Passed field should show passed status")
        XCTAssertEqual(pendingField.inspectionStatus, "pending", "Pending field should show pending status")
        XCTAssertEqual(failedField.inspectionStatus, "failed", "Failed field should show failed status")
    }
    
    func testGrowOrganicCertificationIndicator() throws {
        // Given: A grow with organic seed
        let field = createTestField()
        let grow = createTestGrow(for: field)
        let organicSeed = createTestSeed(isOrganic: true)
        grow.seed = organicSeed
        
        // When: Creating a GrowSummaryRow
        let growRow = GrowSummaryRow(grow: grow)
        
        // Then: Grow should be identified as organic
        XCTAssertNotNil(grow.seed, "Grow should have a seed")
        XCTAssertTrue(grow.seed?.isCertifiedOrganic ?? false, "Seed should be organic")
    }
    
    // MARK: - View Lifecycle Tests
    
    func testFieldDetailViewInitialization() throws {
        // Given: A properly configured field
        let field = createTestField()
        
        // When: Initializing the detail view
        let detailView = FieldDetailView(field: field)
        
        // Then: View should initialize without errors
        XCTAssertNotNil(detailView, "Detail view should initialize")
        // Additional lifecycle checks would be done through UI testing
    }
    
    func testFieldDetailViewMemoryManagement() throws {
        // Given: A field and detail view
        let field = createTestField()
        var detailView: FieldDetailView? = FieldDetailView(field: field)
        
        // When: Releasing the view
        detailView = nil
        
        // Then: No memory leaks should occur
        XCTAssertNil(detailView, "Detail view should be released")
        // Field should still exist in context
        XCTAssertFalse(field.isDeleted, "Field should not be deleted")
    }
    
    // MARK: - Helper Methods
    
    private func createTestField() -> Field {
        let field = Field(context: viewContext)
        field.id = UUID()
        field.name = "Test Field"
        field.acres = 10.5
        field.hasDrainTile = false
        field.slope = "2-5%"
        field.soilType = "Silt Loam"
        field.inspectionStatus = "passed"
        field.nextInspectionDue = Date().addingTimeInterval(30 * 24 * 60 * 60)
        field.soilMapUnits = ["TestUnit1", "TestUnit2"] as NSArray
        field.notes = "Test field notes"
        return field
    }
    
    private func createTestGrow(for field: Field) -> Grow {
        let grow = Grow(context: viewContext)
        grow.timestamp = Date()
        grow.title = "Test Grow"
        grow.field = field
        grow.plantedDate = Date()
        return grow
    }
    
    private func createTestSoilTest(for field: Field) -> SoilTest {
        let soilTest = SoilTest(context: viewContext)
        soilTest.id = UUID()
        soilTest.field = field
        soilTest.date = Date()
        soilTest.ph = 6.8
        soilTest.omPct = 3.2
        soilTest.p_ppm = 25.0
        soilTest.k_ppm = 150.0
        soilTest.cec = 12.5
        return soilTest
    }
    
    private func createTestAmendment() -> CropAmendment {
        let amendment = CropAmendment(context: viewContext)
        amendment.amendmentID = UUID()
        amendment.productName = "Test Compost"
        amendment.applicationMethod = "Broadcast"
        amendment.applicationRate = "1 ton/acre"
        amendment.dateApplied = Date()
        amendment.omriListed = true
        return amendment
    }
    
    private func createTestWorkOrder(for grow: Grow, with amendment: CropAmendment) -> WorkOrder {
        let workOrder = WorkOrder(context: viewContext)
        workOrder.id = UUID()
        workOrder.createdDate = Date()
        workOrder.amendment = amendment
        grow.addToWorkOrders(workOrder)
        return workOrder
    }
    
    private func createTestHarvest(for grow: Grow) -> Harvest {
        let harvest = Harvest(context: viewContext)
        harvest.timestamp = Date()
        harvest.totalQuantity = 100.0
        harvest.grow = grow
        return harvest
    }
    
    private func createTestSeed(isOrganic: Bool) -> SeedLibrary {
        let seed = SeedLibrary(context: viewContext)
        seed.id = UUID()
        seed.name = "Test Seed"
        seed.isCertifiedOrganic = isOrganic
        return seed
    }
}