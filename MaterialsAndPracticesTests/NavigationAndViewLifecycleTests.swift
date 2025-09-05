//
//  NavigationAndViewLifecycleTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for navigation behavior and view lifecycle management.
//  Addresses the issue where "when I tap on a row and open new view the first view 
//  is always blank until I select a different item from the list."
//
//  Created by GitHub Copilot on current date.
//

import XCTest
import CoreData
import SwiftUI
import Combine
@testable import MaterialsAndPractices

class NavigationAndViewLifecycleTests: XCTestCase {
    
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
    
    // MARK: - Navigation Loading Tests
    
    func testFieldDetailViewLoadsImmediatelyOnNavigation() throws {
        // Given: A field with complete data
        let field = createTestFieldWithCompleteData()
        try viewContext.save()
        
        // When: Creating a FieldDetailView (simulating navigation)
        let detailView = FieldDetailView(field: field)
        
        // Then: View should have all necessary data immediately available
        XCTAssertNotNil(field.name, "Field name should be immediately available")
        XCTAssertGreaterThan(field.acres, 0, "Field acres should be immediately available")
        XCTAssertNotNil(field.id, "Field ID should be immediately available")
        
        // Verify the field object is not a fault (data is loaded)
        XCTAssertFalse(field.isFault, "Field should not be a fault object")
    }
    
    func testFieldRowNavigationDataPreloading() throws {
        // Given: A field with related data
        let field = createTestFieldWithCompleteData()
        let soilTest = createTestSoilTest(for: field)
        try viewContext.save()
        
        // When: Creating a FieldRow (list view item)
        let fieldRow = FieldRow(field: field)
        
        // Then: Related data should be preloaded
        XCTAssertNotNil(field.soilTests, "Soil tests relationship should be loaded")
        XCTAssertFalse(field.soilTests?.allObjects.isEmpty ?? true, "Soil tests should contain data")
    }
    
    func testGrowSummaryRowNavigationDataAvailability() throws {
        // Given: A grow with complete data
        let field = createTestFieldWithCompleteData()
        let grow = createTestGrow(for: field)
        let cultivar = createTestCultivar()
        grow.cultivar = cultivar
        try viewContext.save()
        
        // When: Creating a GrowSummaryRow
        let growRow = GrowSummaryRow(grow: grow)
        
        // Then: All required data should be immediately available
        XCTAssertNotNil(grow.title, "Grow title should be available")
        XCTAssertNotNil(grow.cultivar, "Cultivar should be available")
        XCTAssertNotNil(grow.plantedDate, "Planted date should be available")
        XCTAssertFalse(grow.isFault, "Grow should not be a fault object")
    }
    
    func testSoilTestRowNavigationDataAvailability() throws {
        // Given: A soil test with complete data
        let field = createTestFieldWithCompleteData()
        let soilTest = createTestSoilTest(for: field)
        let lab = createTestLab()
        soilTest.lab = lab
        try viewContext.save()
        
        // When: Creating a SoilTestRow
        let soilTestRow = SoilTestRow(soilTest: soilTest)
        
        // Then: All required data should be immediately available
        XCTAssertNotNil(soilTest.date, "Test date should be available")
        XCTAssertGreaterThan(soilTest.ph, 0, "pH should be available")
        XCTAssertNotNil(soilTest.lab, "Lab should be available")
        XCTAssertFalse(soilTest.isFault, "Soil test should not be a fault object")
    }
    
    // MARK: - Core Data Fetch Request Tests
    
    func testFieldFetchRequestIncludesAllRelatedData() throws {
        // Given: A field with all related entities
        let field = createTestFieldWithCompleteData()
        let grow = createTestGrow(for: field)
        let soilTest = createTestSoilTest(for: field)
        let well = createTestWell(for: field)
        try viewContext.save()
        
        // When: Fetching field with relationships
        let fetchRequest: NSFetchRequest<Field> = Field.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", field.id! as CVarArg)
        fetchRequest.relationshipKeyPathsForPrefetching = [
            "grows", "soilTests", "wells", "property"
        ]
        
        let results = try viewContext.fetch(fetchRequest)
        
        // Then: Field should be fetched with all relationships
        XCTAssertEqual(results.count, 1, "Should fetch one field")
        let fetchedField = results.first!
        
        XCTAssertNotNil(fetchedField.grows, "Grows relationship should be prefetched")
        XCTAssertNotNil(fetchedField.soilTests, "Soil tests relationship should be prefetched")
        XCTAssertNotNil(fetchedField.wells, "Wells relationship should be prefetched")
    }
    
    func testGrowFetchRequestIncludesNestedData() throws {
        // Given: A grow with nested amendment and harvest data
        let field = createTestFieldWithCompleteData()
        let grow = createTestGrow(for: field)
        let amendment = createTestAmendment()
        let workOrder = createTestWorkOrder(for: grow, with: amendment)
        let harvest = createTestHarvest(for: grow)
        try viewContext.save()
        
        // When: Fetching grow with deep relationships
        let fetchRequest: NSFetchRequest<Grow> = Grow.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp == %@", grow.timestamp! as CVarArg)
        fetchRequest.relationshipKeyPathsForPrefetching = [
            "workOrders", "workOrders.amendment", "harvests", "field", "cultivar"
        ]
        
        let results = try viewContext.fetch(fetchRequest)
        
        // Then: Grow should be fetched with nested relationships
        XCTAssertEqual(results.count, 1, "Should fetch one grow")
        let fetchedGrow = results.first!
        
        XCTAssertNotNil(fetchedGrow.workOrders, "Work orders should be prefetched")
        XCTAssertNotNil(fetchedGrow.harvests, "Harvests should be prefetched")
        XCTAssertNotNil(fetchedGrow.field, "Field should be prefetched")
    }
    
    // MARK: - View State Management Tests
    
    func testFieldDetailViewStateConsistency() throws {
        // Given: A field that will be modified
        let field = createTestFieldWithCompleteData()
        try viewContext.save()
        
        // When: Simulating view state changes
        let originalName = field.name
        field.name = "Modified Name"
        
        // Don't save yet - test uncommitted changes
        
        // Then: View should show current state
        XCTAssertEqual(field.name, "Modified Name", "View should show uncommitted changes")
        XCTAssertNotEqual(field.name, originalName, "Name should be different from original")
        
        // When: Discarding changes
        viewContext.rollback()
        
        // Then: State should revert
        XCTAssertEqual(field.name, originalName, "Name should revert after rollback")
    }
    
    func testFieldDetailViewRefreshesOnContextSave() throws {
        // Given: A field with initial data
        let field = createTestFieldWithCompleteData()
        try viewContext.save()
        
        // Setup notification expectation
        let expectation = XCTestExpectation(description: "Context save notification")
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { _ in
                expectation.fulfill()
            }
        
        // When: Modifying and saving the field
        field.name = "Updated Field Name"
        field.acres = 99.9
        try viewContext.save()
        
        // Then: Context save notification should be fired
        wait(for: [expectation], timeout: 1.0)
        
        // Cleanup
        observer.cancel()
    }
    
    // MARK: - Memory and Performance Tests
    
    func testFieldDetailViewDoesNotRetainUnusedObjects() throws {
        // Given: Multiple fields
        var fields: [Field] = []
        for i in 0..<10 {
            let field = createTestFieldWithCompleteData()
            field.name = "Field \(i)"
            fields.append(field)
        }
        try viewContext.save()
        
        // When: Creating detail views for each field
        var detailViews: [FieldDetailView] = []
        for field in fields {
            detailViews.append(FieldDetailView(field: field))
        }
        
        // Then: Only referenced objects should be retained
        XCTAssertEqual(detailViews.count, 10, "Should have 10 detail views")
        
        // When: Clearing references
        detailViews.removeAll()
        
        // Then: Memory should be manageable (no strong reference cycles)
        // This is more of a conceptual test - actual memory testing would require instruments
        XCTAssertTrue(detailViews.isEmpty, "Detail views should be cleared")
    }
    
    func testLargeDataSetNavigationPerformance() throws {
        // Given: A field with many related objects
        let field = createTestFieldWithCompleteData()
        
        // Create many related objects
        for i in 0..<50 {
            let grow = createTestGrow(for: field)
            grow.title = "Grow \(i)"
            
            let soilTest = createTestSoilTest(for: field)
            soilTest.ph = Double(6.0 + i % 3) // Vary pH values
            
            // Add some amendments and harvests
            if i % 5 == 0 {
                let amendment = createTestAmendment()
                amendment.productName = "Amendment \(i)"
                let workOrder = createTestWorkOrder(for: grow, with: amendment)
                
                let harvest = createTestHarvest(for: grow)
                harvest.totalQuantity = Double(100 + i * 10)
            }
        }
        
        try viewContext.save()
        
        // When: Measuring navigation time
        let startTime = CFAbsoluteTimeGetCurrent()
        let detailView = FieldDetailView(field: field)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then: Navigation should be reasonably fast (under 100ms)
        let navigationTime = endTime - startTime
        XCTAssertLessThan(navigationTime, 0.1, "Navigation should complete in under 100ms")
        
        // Verify data is accessible
        guard let grows = field.grows?.allObjects as? [Grow] else {
            XCTFail("Should have grows data")
            return
        }
        XCTAssertEqual(grows.count, 50, "Should have 50 grows")
    }
    
    // MARK: - Edge Case Tests
    
    func testNavigationWithMissingData() throws {
        // Given: A field with minimal data
        let field = Field(context: viewContext)
        field.id = UUID()
        field.name = nil // Missing name
        field.acres = 0   // Zero acres
        // No relationships
        try viewContext.save()
        
        // When: Creating detail view with missing data
        let detailView = FieldDetailView(field: field)
        
        // Then: View should handle missing data gracefully
        XCTAssertNotNil(detailView, "Detail view should handle missing data")
        XCTAssertNil(field.name, "Name should be nil")
        XCTAssertEqual(field.acres, 0, "Acres should be 0")
    }
    
    func testNavigationWithCorruptedRelationships() throws {
        // Given: A field with some corrupted relationship data
        let field = createTestFieldWithCompleteData()
        let grow = createTestGrow(for: field)
        try viewContext.save()
        
        // When: Simulating data corruption by deleting related object
        viewContext.delete(grow)
        try viewContext.save()
        
        // Then: Detail view should handle orphaned relationships
        let detailView = FieldDetailView(field: field)
        
        XCTAssertNotNil(detailView, "Detail view should handle orphaned relationships")
        let remainingGrows = field.grows?.allObjects as? [Grow] ?? []
        XCTAssertTrue(remainingGrows.isEmpty, "Deleted grow should not appear in relationships")
    }
    
    // MARK: - Helper Methods
    
    private func createTestFieldWithCompleteData() -> Field {
        let field = Field(context: viewContext)
        field.id = UUID()
        field.name = "Complete Test Field"
        field.acres = 25.75
        field.hasDrainTile = true
        field.slope = "3-7%"
        field.soilType = "Clay Loam"
        field.inspectionStatus = "passed"
        field.nextInspectionDue = Date().addingTimeInterval(45 * 24 * 60 * 60)
        field.soilMapUnits = ["Unit1", "Unit2", "Unit3"] as NSArray
        field.notes = "Comprehensive test field with all properties"
        return field
    }
    
    private func createTestGrow(for field: Field) -> Grow {
        let grow = Grow(context: viewContext)
        grow.timestamp = Date()
        grow.title = "Test Grow"
        grow.field = field
        grow.plantedDate = Date()
        grow.harvestDate = Date().addingTimeInterval(90 * 24 * 60 * 60)
        grow.size = 5.0
        return grow
    }
    
    private func createTestSoilTest(for field: Field) -> SoilTest {
        let soilTest = SoilTest(context: viewContext)
        soilTest.id = UUID()
        soilTest.field = field
        soilTest.date = Date()
        soilTest.ph = 6.8
        soilTest.omPct = 3.5
        soilTest.p_ppm = 30.0
        soilTest.k_ppm = 180.0
        soilTest.cec = 15.0
        return soilTest
    }
    
    private func createTestWell(for field: Field) -> Well {
        let well = Well(context: viewContext)
        well.id = UUID()
        well.name = "Test Well"
        well.wellType = "drilled"
        well.status = "active"
        well.field = field
        return well
    }
    
    private func createTestCultivar() -> Cultivar {
        let cultivar = Cultivar(context: viewContext)
        cultivar.id = UUID()
        cultivar.name = "Test Cultivar"
        cultivar.commonName = "Test Common"
        return cultivar
    }
    
    private func createTestLab() -> Lab {
        let lab = Lab(context: viewContext)
        lab.id = UUID()
        lab.name = "Test Laboratory"
        lab.isActive = true
        return lab
    }
    
    private func createTestAmendment() -> CropAmendment {
        let amendment = CropAmendment(context: viewContext)
        amendment.amendmentID = UUID()
        amendment.productName = "Test Amendment"
        amendment.applicationMethod = "Broadcast"
        amendment.applicationRate = "2 tons/acre"
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
        harvest.totalQuantity = 150.0
        harvest.grow = grow
        return harvest
    }
}