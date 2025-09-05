//
//  NavigationFlowTests.swift
//  MaterialsAndPracticesTests
//
//  Tests specific navigation flows that the user reported as problematic.
//  Focuses on Farm Dashboard → Active Farms → PropertyDetailView → Field navigation
//

import XCTest
import SwiftUI
import CoreData
@testable import MaterialsAndPractices

class NavigationFlowTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    var testProperty: Property!
    var testField: Field!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        viewContext = PersistenceController.preview.container.viewContext
        createTestData()
    }
    
    override func tearDownWithError() throws {
        cleanupTestData()
        viewContext = nil
        try super.tearDownWithError()
    }
    
    private func createTestData() {
        // Create test property
        testProperty = Property(context: viewContext)
        testProperty.id = UUID()
        testProperty.displayName = "Navigation Test Farm"
        testProperty.totalAcres = 100.0
        testProperty.county = "Test County"
        testProperty.state = "IA"
        
        // Create test field with comprehensive data
        testField = Field(context: viewContext)
        testField.id = UUID()
        testField.name = "Navigation Test Field"
        testField.acres = 25.0
        testField.hasDrainTile = true
        testField.slope = "2-5%"
        testField.soilType = "Clay Loam"
        testField.soilMapUnits = ["123A", "124B"]
        testField.inspectionStatus = "passed"
        testField.nextInspectionDue = Calendar.current.date(byAdding: .month, value: 6, to: Date())
        testField.notes = "Test field for navigation testing"
        testField.property = testProperty
        
        // Save context
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save test data: \(error)")
        }
    }
    
    private func cleanupTestData() {
        [testField, testProperty].compactMap { $0 }.forEach { object in
            viewContext.delete(object)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error cleaning up test data: \(error)")
        }
    }
    
    // MARK: - Navigation Flow Tests
    
    func testFarmDashboardToPropertyDetailNavigation() throws {
        // Test Farm Dashboard loads properly
        let dashboardView = FarmDashboardView()
            .environment(\.managedObjectContext, viewContext)
        
        let dashboardController = UIHostingController(rootView: dashboardView)
        XCTAssertNotNil(dashboardController.view)
        
        // Test Property Detail View loads with field data
        let propertyDetailView = PropertyDetailView(property: testProperty, isAdvancedMode: true)
            .environment(\.managedObjectContext, viewContext)
        
        let propertyController = UIHostingController(rootView: propertyDetailView)
        XCTAssertNotNil(propertyController.view)
        
        // Verify property has fields available
        XCTAssertNotNil(testProperty.fields)
        let fields = testProperty.fields?.allObjects as? [Field]
        XCTAssertNotNil(fields)
        XCTAssertGreaterThan(fields?.count ?? 0, 0)
        XCTAssertEqual(fields?.first, testField)
    }
    
    func testPropertyDetailToFieldDetailNavigation() throws {
        // Test the specific navigation path: PropertyDetailView → FieldDetailView
        
        // First, ensure field data is properly loaded
        XCTAssertEqual(testField.name, "Navigation Test Field")
        XCTAssertEqual(testField.acres, 25.0)
        XCTAssertEqual(testField.property, testProperty)
        XCTAssertNotNil(testField.inspectionStatus)
        XCTAssertNotNil(testField.soilMapUnits)
        
        // Test FieldDetailView loads immediately with data
        let fieldDetailView = FieldDetailView(field: testField)
            .environment(\.managedObjectContext, viewContext)
        
        let fieldController = UIHostingController(rootView: fieldDetailView)
        XCTAssertNotNil(fieldController.view)
        
        // Verify field data is immediately accessible (not a fault)
        XCTAssertFalse(testField.isFault)
        XCTAssertEqual(testField.name, "Navigation Test Field")
        XCTAssertEqual(testField.acres, 25.0)
        XCTAssertTrue(testField.hasDrainTile)
        XCTAssertEqual(testField.slope, "2-5%")
        XCTAssertEqual(testField.soilType, "Clay Loam")
        
        // Test soil map units array support
        if let soilMapUnits = testField.soilMapUnits as? [String] {
            XCTAssertEqual(soilMapUnits, ["123A", "124B"])
        } else {
            XCTFail("Soil map units should be accessible as string array")
        }
        
        // Test certification data
        XCTAssertEqual(testField.inspectionStatus, "passed")
        XCTAssertNotNil(testField.nextInspectionDue)
        
        // Test property relationship
        XCTAssertEqual(testField.property, testProperty)
        XCTAssertEqual(testField.property?.displayName, "Navigation Test Farm")
    }
    
    func testFieldRowPrefetchNavigation() throws {
        // Test FieldRowWithPrefetch component
        let fieldRowView = FieldRowWithPrefetch(field: testField)
            .environment(\.managedObjectContext, viewContext)
        
        let rowController = UIHostingController(rootView: fieldRowView)
        XCTAssertNotNil(rowController.view)
        
        // Allow time for prefetching to complete
        let expectation = XCTestExpectation(description: "Prefetch completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify field data is still accessible after prefetch attempt
        XCTAssertEqual(testField.name, "Navigation Test Field")
        XCTAssertNotNil(testField.property)
    }
    
    func testCompleteNavigationFlow() throws {
        // Test the complete navigation flow that user reported
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1. Farm Dashboard
        let dashboardView = FarmDashboardView()
            .environment(\.managedObjectContext, viewContext)
        let dashboardController = UIHostingController(rootView: dashboardView)
        XCTAssertNotNil(dashboardController.view)
        
        // 2. Property Detail View (Active Farms → select property)
        let propertyDetailView = PropertyDetailView(property: testProperty, isAdvancedMode: true)
            .environment(\.managedObjectContext, viewContext)
        let propertyController = UIHostingController(rootView: propertyDetailView)
        XCTAssertNotNil(propertyController.view)
        
        // 3. Field Detail View (tap on field)
        let fieldDetailView = FieldDetailView(field: testField)
            .environment(\.managedObjectContext, viewContext)
        let fieldController = UIHostingController(rootView: fieldDetailView)
        XCTAssertNotNil(fieldController.view)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Navigation should be fast
        XCTAssertLessThan(totalTime, 0.5, "Complete navigation flow took too long: \(totalTime)s")
        
        // Verify all data is still accessible at the end
        XCTAssertEqual(testField.name, "Navigation Test Field")
        XCTAssertEqual(testProperty.displayName, "Navigation Test Farm")
        XCTAssertEqual(testField.property, testProperty)
    }
    
    func testDataPersistenceAcrossNavigation() throws {
        // Test that data remains accessible across multiple navigation operations
        
        // Initial state
        XCTAssertEqual(testField.name, "Navigation Test Field")
        XCTAssertEqual(testField.acres, 25.0)
        
        // Simulate navigation by creating multiple views
        for i in 0..<5 {
            let fieldDetailView = FieldDetailView(field: testField)
                .environment(\.managedObjectContext, viewContext)
            let controller = UIHostingController(rootView: fieldDetailView)
            XCTAssertNotNil(controller.view)
            
            // Data should remain consistent
            XCTAssertEqual(testField.name, "Navigation Test Field")
            XCTAssertEqual(testField.acres, 25.0)
            XCTAssertFalse(testField.isFault, "Field became a fault on iteration \(i)")
        }
    }
    
    func testFieldDetailViewDataRefresh() throws {
        // Test that FieldDetailView properly refreshes data
        let fieldDetailView = FieldDetailView(field: testField)
            .environment(\.managedObjectContext, viewContext)
        
        let controller = UIHostingController(rootView: fieldDetailView)
        XCTAssertNotNil(controller.view)
        
        // Update field data
        let originalName = testField.name
        testField.name = "Updated Field Name"
        try viewContext.save()
        
        // Field should reflect updates
        XCTAssertEqual(testField.name, "Updated Field Name")
        
        // Restore original name
        testField.name = originalName
        try viewContext.save()
        XCTAssertEqual(testField.name, "Navigation Test Field")
    }
    
    func testEmptyDataHandling() throws {
        // Test navigation with field that has minimal data
        let minimalField = Field(context: viewContext)
        minimalField.id = UUID()
        minimalField.name = nil // Test with nil name
        minimalField.acres = 0.0
        minimalField.property = testProperty
        
        try viewContext.save()
        
        let fieldDetailView = FieldDetailView(field: minimalField)
            .environment(\.managedObjectContext, viewContext)
        
        let controller = UIHostingController(rootView: fieldDetailView)
        XCTAssertNotNil(controller.view)
        
        // View should handle nil/empty data gracefully
        XCTAssertNotNil(controller.view)
        
        // Clean up
        viewContext.delete(minimalField)
        try viewContext.save()
    }
    
    func testCoreDataFaultHandling() throws {
        // Test that navigation works properly with Core Data faults
        
        // Force field to become a fault
        viewContext.refresh(testField, mergeChanges: false)
        XCTAssertTrue(testField.isFault)
        
        // Navigation should still work
        let fieldDetailView = FieldDetailView(field: testField)
            .environment(\.managedObjectContext, viewContext)
        
        let controller = UIHostingController(rootView: fieldDetailView)
        XCTAssertNotNil(controller.view)
        
        // Field should be loaded after accessing properties
        let fieldName = testField.name
        XCTAssertFalse(testField.isFault)
        XCTAssertEqual(fieldName, "Navigation Test Field")
    }
}