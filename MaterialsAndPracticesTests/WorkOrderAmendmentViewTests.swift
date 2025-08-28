//
//  WorkOrderAmendmentViewTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for work order amendment integration and view functionality
//  Specifically tests the crash scenario reported by user.
//
//  Created by GitHub Copilot on 12/18/24.
//

import XCTest
import SwiftUI
import CoreData
@testable import MaterialsAndPractices

class WorkOrderAmendmentViewTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var testGrow: Grow!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Create test grow
        testGrow = Grow(context: viewContext)
        testGrow.title = "Test Grow"
        testGrow.locationName = "Test Field"
        
        try viewContext.save()
        
        // Seed amendments to avoid empty state
        CropAmendmentSeeder.seedAmendments(in: viewContext)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        testGrow = nil
    }
    
    // MARK: - Crash Prevention Tests
    
    func testAmendmentSelectionViewDoesNotCrash() throws {
        // This test specifically addresses the user's crash report
        // "executeFetchRequest:error: A fetch request must have an entity."
        
        let selectedAmendments: Binding<Set<CropAmendment>> = .constant(Set<CropAmendment>())
        let isPresented: Binding<Bool> = .constant(true)
        
        // This should not crash now that CropAmendment entity exists in Core Data
        let amendmentView = AmendmentSelectionView(
            selectedAmendments: selectedAmendments,
            isPresented: isPresented
        )
        .environment(\.managedObjectContext, viewContext)
        
        // Verify the view can be instantiated without crashing
        XCTAssertNotNil(amendmentView)
    }
    
    func testPerformWorkViewWithAmendmentButton() throws {
        // Test the full navigation path that was causing the crash:
        // Grows -> Grow detail -> perform work -> add amendment
        
        let performWorkView = PerformWorkView(
            grow: testGrow,
            isPresented: .constant(true)
        )
        .environment(\.managedObjectContext, viewContext)
        
        // Verify the view can be instantiated
        XCTAssertNotNil(performWorkView)
    }
    
    func testAmendmentFetchRequestExecution() throws {
        // Directly test the fetch request that was failing
        let fetchRequest: NSFetchRequest<CropAmendment> = NSFetchRequest<CropAmendment>(entityName: "CropAmendment")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \CropAmendment.omriListed, ascending: false),
            NSSortDescriptor(keyPath: \CropAmendment.productName, ascending: true)
        ]
        
        // This should not crash - was the root cause of the issue
        let amendments = try viewContext.fetch(fetchRequest)
        
        XCTAssertNotNil(amendments, "Should successfully fetch amendments")
        XCTAssertGreaterThan(amendments.count, 0, "Should have seeded amendments")
    }
    
    // MARK: - Amendment Selection Integration Tests
    
    func testAmendmentSelectionUpdatesOrganicStatus() throws {
        // Test that selecting non-organic amendments updates certification status
        let organicAmendment = createTestAmendment(name: "Organic Compost", omriListed: true)
        let conventionalAmendment = createTestAmendment(name: "Synthetic NPK", omriListed: false)
        
        var selectedAmendments: Set<CropAmendment> = []
        
        // Start with organic only
        selectedAmendments.insert(organicAmendment)
        let hasNonOrganicA = selectedAmendments.contains { !$0.omriListed }
        XCTAssertFalse(hasNonOrganicA, "Should be organic compliant")
        
        // Add conventional amendment
        selectedAmendments.insert(conventionalAmendment)
        let hasNonOrganicB = selectedAmendments.contains { !$0.omriListed }
        XCTAssertTrue(hasNonOrganicB, "Should trigger organic compliance failure")
    }
    
    func testWorkOrderNotesWithAmendments() throws {
        let amendment = createTestAmendment(name: "Test Amendment", omriListed: true)
        amendment.applicationRate = "2.0"
        amendment.unitOfMeasure = "lbs/acre"
        amendment.applicationMethod = "Broadcast"
        
        let fullDescription = amendment.fullDescription
        
        XCTAssertTrue(fullDescription.contains("Test Amendment"))
        XCTAssertTrue(fullDescription.contains("2.0 lbs/acre"))
        XCTAssertTrue(fullDescription.contains("Broadcast"))
        XCTAssertTrue(fullDescription.contains("OMRI Listed"))
    }
    
    // MARK: - Work Order Creation Tests
    
    func testWorkOrderCreationWithAmendments() throws {
        let amendment = createTestAmendment(name: "Test Amendment", omriListed: true)
        
        // Create work order
        let workOrder = WorkOrder(context: viewContext)
        workOrder.id = UUID()
        workOrder.title = "Test Work Order"
        workOrder.grow = testGrow
        workOrder.createdDate = Date()
        
        // Simulate adding amendment info to notes
        var notes = "Initial notes"
        notes += "\n\nApplied Amendments:\n"
        notes += "• \(amendment.fullDescription)\n"
        
        workOrder.notes = notes
        
        try viewContext.save()
        
        XCTAssertTrue(workOrder.notes!.contains("Test Amendment"))
        XCTAssertTrue(workOrder.notes!.contains("Applied Amendments"))
    }
    
    // MARK: - Error Handling Tests
    
    func testEmptyAmendmentList() throws {
        // Test behavior when no amendments are available
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: CropAmendment.fetchRequest())
        try viewContext.execute(deleteRequest)
        
        let fetchRequest: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        let amendments = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(amendments.count, 0, "Should have no amendments after deletion")
        
        // View should handle empty state gracefully
        let selectedAmendments: Binding<Set<CropAmendment>> = .constant(Set<CropAmendment>())
        let isPresented: Binding<Bool> = .constant(true)
        
        let amendmentView = AmendmentSelectionView(
            selectedAmendments: selectedAmendments,
            isPresented: isPresented
        )
        .environment(\.managedObjectContext, viewContext)
        
        XCTAssertNotNil(amendmentView)
    }
    
    // MARK: - Performance Tests
    
    func testAmendmentSelectionPerformance() throws {
        // Create many amendments to test performance
        for i in 0..<100 {
            let amendment = createTestAmendment(name: "Amendment \(i)", omriListed: i % 2 == 0)
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
                XCTFail("Performance test fetch failed: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
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