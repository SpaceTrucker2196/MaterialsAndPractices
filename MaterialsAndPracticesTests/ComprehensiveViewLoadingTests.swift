//
//  ComprehensiveViewLoadingTests.swift
//  MaterialsAndPracticesTests
//
//  Comprehensive test suite that validates all views in the app load properly
//  and respond to Core Data updates. Addresses navigation and data loading issues
//  reported in field detail view and other views.
//

import XCTest
import SwiftUI
import CoreData
@testable import MaterialsAndPractices

class ComprehensiveViewLoadingTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    var testProperty: Property!
    var testField: Field!
    var testWorker: Worker!
    var testGrow: Grow!
    var testWorkOrder: WorkOrder!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Set up in-memory Core Data stack for testing
        viewContext = PersistenceController.preview.container.viewContext
        
        // Create test data for comprehensive testing
        createTestData()
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        cleanupTestData()
        viewContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Data Setup
    
    private func createTestData() {
        // Create test property
        testProperty = Property(context: viewContext)
        testProperty.id = UUID()
        testProperty.displayName = "Test Farm Property"
        testProperty.totalAcres = 100.0
        testProperty.tillableAcres = 80.0
        testProperty.county = "Test County"
        testProperty.state = "IA"
        testProperty.hasIrrigation = true
        
        // Create test field with all properties
        testField = Field(context: viewContext)
        testField.id = UUID()
        testField.name = "Test Field"
        testField.acres = 25.0
        testField.hasDrainTile = true
        testField.slope = "2-5%"
        testField.soilType = "Clay Loam"
        testField.notes = "Test field for comprehensive testing"
        testField.inspectionStatus = "passed"
        testField.nextInspectionDue = Calendar.current.date(byAdding: .month, value: 6, to: Date())
        testField.property = testProperty
        
        // Add soil map units (array support test)
        testField.soilMapUnits = ["123A", "124B", "125C"]
        
        // Create test worker
        testWorker = Worker(context: viewContext)
        testWorker.id = UUID()
        testWorker.name = "Test Worker"
        testWorker.position = "Farm Hand"
        testWorker.isActive = true
        
        // Create test grow
        testGrow = Grow(context: viewContext)
        testGrow.id = UUID()
        testGrow.field = testField
        testGrow.cropType = "Corn"
        testGrow.plantingDate = Date()
        
        // Create test work order
        testWorkOrder = WorkOrder(context: viewContext)
        testWorkOrder.id = UUID()
        testWorkOrder.grow = testGrow
        testWorkOrder.orderType = "cultivation"
        testWorkOrder.isCompleted = false
        
        // Save context
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save test data: \(error)")
        }
    }
    
    private func cleanupTestData() {
        guard let context = viewContext else { return }
        
        [testWorkOrder, testGrow, testField, testProperty, testWorker].compactMap { $0 }.forEach { object in
            context.delete(object)
        }
        
        do {
            try context.save()
        } catch {
            print("Error cleaning up test data: \(error)")
        }
    }
    
    // MARK: - Farm Dashboard View Tests
    
    func testFarmDashboardViewLoadsWithData() throws {
        let view = FarmDashboardView()
            .environment(\.managedObjectContext, viewContext)
        
        // Test that view renders without crashing
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Verify view responds to data changes
        let initialPropertyCount = fetchPropertyCount()
        
        // Add another property
        let newProperty = Property(context: viewContext)
        newProperty.id = UUID()
        newProperty.displayName = "Second Test Farm"
        newProperty.totalAcres = 50.0
        
        try viewContext.save()
        
        // The view should automatically update with the new property
        let updatedPropertyCount = fetchPropertyCount()
        XCTAssertEqual(updatedPropertyCount, initialPropertyCount + 1)
        
        // Clean up
        viewContext.delete(newProperty)
        try viewContext.save()
    }
    
    func testFarmDashboardHandlesEmptyState() throws {
        // Remove all properties
        let fetchRequest: NSFetchRequest<Property> = Property.fetchRequest()
        let properties = try viewContext.fetch(fetchRequest)
        properties.forEach { viewContext.delete($0) }
        try viewContext.save()
        
        let view = FarmDashboardView()
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Restore test data
        createTestData()
    }
    
    // MARK: - Property Detail View Tests
    
    func testPropertyDetailViewLoadsWithValidData() throws {
        // Ensure property has related data
        XCTAssertNotNil(testProperty.fields)
        XCTAssertGreaterThan(testProperty.fields?.count ?? 0, 0)
        
        let view = PropertyDetailView(property: testProperty, isAdvancedMode: true)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Test data availability immediately
        XCTAssertEqual(testProperty.displayName, "Test Farm Property")
        XCTAssertEqual(testProperty.totalAcres, 100.0)
        XCTAssertTrue(testProperty.hasIrrigation)
    }
    
    func testPropertyDetailViewRespondsToFieldChanges() throws {
        let view = PropertyDetailView(property: testProperty, isAdvancedMode: true)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Add a new field to the property
        let newField = Field(context: viewContext)
        newField.id = UUID()
        newField.name = "New Test Field"
        newField.acres = 15.0
        newField.property = testProperty
        
        try viewContext.save()
        
        // Verify the field was added to the property
        let updatedFields = testProperty.fields?.allObjects as? [Field]
        XCTAssertEqual(updatedFields?.count, 2)
        
        // Clean up
        viewContext.delete(newField)
        try viewContext.save()
    }
    
    // MARK: - Field Detail View Tests
    
    func testFieldDetailViewLoadsImmediately() throws {
        // Ensure field has all required data
        XCTAssertNotNil(testField.property)
        XCTAssertNotNil(testField.name)
        XCTAssertNotNil(testField.soilMapUnits)
        
        let view = FieldDetailView(field: testField)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Test that field data is immediately available (not a fault)
        XCTAssertEqual(testField.name, "Test Field")
        XCTAssertEqual(testField.acres, 25.0)
        XCTAssertTrue(testField.hasDrainTile)
        XCTAssertEqual(testField.slope, "2-5%")
        XCTAssertEqual(testField.soilType, "Clay Loam")
        XCTAssertEqual(testField.soilMapUnits, ["123A", "124B", "125C"])
        XCTAssertEqual(testField.inspectionStatus, "passed")
        XCTAssertNotNil(testField.nextInspectionDue)
    }
    
    func testFieldDetailViewHandlesRelationshipData() throws {
        // Ensure relationships are properly loaded
        XCTAssertNotNil(testField.property)
        XCTAssertNotNil(testField.grows)
        
        let view = FieldDetailView(field: testField)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Test relationship data availability
        XCTAssertEqual(testField.property, testProperty)
        
        let grows = testField.grows?.allObjects as? [Grow]
        XCTAssertNotNil(grows)
        XCTAssertGreaterThan(grows?.count ?? 0, 0)
        
        // Test deep relationships (field -> grow -> work orders)
        if let firstGrow = grows?.first {
            let workOrders = firstGrow.workOrders?.allObjects as? [WorkOrder]
            XCTAssertNotNil(workOrders)
            XCTAssertGreaterThan(workOrders?.count ?? 0, 0)
        }
    }
    
    func testFieldDetailViewRespondsToDataUpdates() throws {
        let view = FieldDetailView(field: testField)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Update field data
        let originalName = testField.name
        testField.name = "Updated Field Name"
        testField.acres = 30.0
        
        try viewContext.save()
        
        // Verify updates are reflected
        XCTAssertEqual(testField.name, "Updated Field Name")
        XCTAssertEqual(testField.acres, 30.0)
        
        // Restore original data
        testField.name = originalName
        testField.acres = 25.0
        try viewContext.save()
    }
    
    // MARK: - Worker Management View Tests
    
    func testWorkerViewsLoadCorrectly() throws {
        let farmStaffView = FarmStaffView()
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: farmStaffView)
        XCTAssertNotNil(hostingController.view)
        
        // Test worker detail view
        let workerDetailView = WorkerDetailView(worker: testWorker)
            .environment(\.managedObjectContext, viewContext)
        
        let detailHostingController = UIHostingController(rootView: workerDetailView)
        XCTAssertNotNil(detailHostingController.view)
        
        // Verify worker data is immediately available
        XCTAssertEqual(testWorker.name, "Test Worker")
        XCTAssertEqual(testWorker.position, "Farm Hand")
        XCTAssertTrue(testWorker.isActive)
    }
    
    // MARK: - Navigation Performance Tests
    
    func testNavigationPerformance() throws {
        let measure = expectation(description: "Navigation performance")
        
        DispatchQueue.main.async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Simulate the full navigation path
            let dashboardView = FarmDashboardView()
                .environment(\.managedObjectContext, self.viewContext)
            
            let propertyDetailView = PropertyDetailView(property: self.testProperty, isAdvancedMode: true)
                .environment(\.managedObjectContext, self.viewContext)
            
            let fieldDetailView = FieldDetailView(field: self.testField)
                .environment(\.managedObjectContext, self.viewContext)
            
            // Create hosting controllers to ensure views are rendered
            let dashboardController = UIHostingController(rootView: dashboardView)
            let propertyController = UIHostingController(rootView: propertyDetailView)
            let fieldController = UIHostingController(rootView: fieldDetailView)
            
            XCTAssertNotNil(dashboardController.view)
            XCTAssertNotNil(propertyController.view)
            XCTAssertNotNil(fieldController.view)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let timeElapsed = endTime - startTime
            
            // Navigation should complete within 100ms for good user experience
            XCTAssertLessThan(timeElapsed, 0.1, "Navigation took too long: \(timeElapsed)s")
            
            measure.fulfill()
        }
        
        wait(for: [measure], timeout: 1.0)
    }
    
    // MARK: - Core Data Relationship Tests
    
    func testCoreDataRelationshipIntegrity() throws {
        // Test that all relationships are properly established
        XCTAssertEqual(testField.property, testProperty)
        XCTAssertTrue(testProperty.fields?.contains(testField) == true)
        
        XCTAssertEqual(testGrow.field, testField)
        XCTAssertTrue(testField.grows?.contains(testGrow) == true)
        
        XCTAssertEqual(testWorkOrder.grow, testGrow)
        XCTAssertTrue(testGrow.workOrders?.contains(testWorkOrder) == true)
    }
    
    func testCoreDataFaultHandling() throws {
        // Force field to become a fault
        viewContext.refresh(testField, mergeChanges: false)
        
        // Access field properties to ensure they're loaded properly
        let fieldName = testField.name
        let fieldAcres = testField.acres
        let fieldProperty = testField.property
        
        XCTAssertNotNil(fieldName)
        XCTAssertNotNil(fieldProperty)
        XCTAssertGreaterThan(fieldAcres, 0)
        
        // Test that relationships can be accessed after becoming a fault
        let grows = testField.grows?.allObjects as? [Grow]
        XCTAssertNotNil(grows)
        XCTAssertGreaterThan(grows?.count ?? 0, 0)
    }
    
    // MARK: - Edge Case Tests
    
    func testViewsHandleNilData() throws {
        // Test field detail view with minimal data
        let minimalField = Field(context: viewContext)
        minimalField.id = UUID()
        // Don't set name, acres, or other properties
        
        let view = FieldDetailView(field: minimalField)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Clean up
        viewContext.delete(minimalField)
        try viewContext.save()
    }
    
    func testViewsHandleCorruptedData() throws {
        // Test with field that has invalid relationships
        let orphanField = Field(context: viewContext)
        orphanField.id = UUID()
        orphanField.name = "Orphan Field"
        orphanField.acres = -1.0 // Invalid acres
        // Don't set property relationship
        
        let view = FieldDetailView(field: orphanField)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        // Clean up
        viewContext.delete(orphanField)
        try viewContext.save()
    }
    
    // MARK: - Large Dataset Performance Tests
    
    func testPerformanceWithLargeDataset() throws {
        // Create a large number of fields to test performance
        var createdFields: [Field] = []
        
        for i in 0..<50 {
            let field = Field(context: viewContext)
            field.id = UUID()
            field.name = "Performance Test Field \(i)"
            field.acres = Double(i) + 1.0
            field.property = testProperty
            createdFields.append(field)
        }
        
        try viewContext.save()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test property detail view with many fields
        let view = PropertyDetailView(property: testProperty, isAdvancedMode: true)
            .environment(\.managedObjectContext, viewContext)
        
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        // Should handle 50 fields quickly
        XCTAssertLessThan(timeElapsed, 0.5, "View loading with 50 fields took too long: \(timeElapsed)s")
        
        // Clean up large dataset
        createdFields.forEach { viewContext.delete($0) }
        try viewContext.save()
    }
    
    // MARK: - Helper Methods
    
    private func fetchPropertyCount() -> Int {
        let fetchRequest: NSFetchRequest<Property> = Property.fetchRequest()
        do {
            return try viewContext.fetch(fetchRequest).count
        } catch {
            XCTFail("Failed to fetch property count: \(error)")
            return 0
        }
    }
}