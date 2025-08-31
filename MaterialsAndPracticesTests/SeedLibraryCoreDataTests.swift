//
//  SeedLibraryCoreDataTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for SeedLibrary Core Data functionality including context initialization,
//  property validation, and view update notifications. Ensures proper Core Data
//  managed object context handling and seed library management features.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
import SwiftUI
import Combine
@testable import MaterialsAndPractices

class SeedLibraryCoreDataTests: XCTestCase {
    
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
    
    // MARK: - Core Data Context Tests
    
    func testSeedLibraryContextInitialization() throws {
        // Test that SeedLibrary can be properly initialized with context
        let seed = SeedLibrary(context: viewContext)
        XCTAssertNotNil(seed.managedObjectContext, "SeedLibrary should have managed object context")
        XCTAssertEqual(seed.managedObjectContext, viewContext, "SeedLibrary should use provided context")
    }
    
    func testCultivarContextInitialization() throws {
        // Test that Cultivar can be properly initialized with context
        let cultivar = Cultivar(context: viewContext)
        XCTAssertNotNil(cultivar.managedObjectContext, "Cultivar should have managed object context")
        XCTAssertEqual(cultivar.managedObjectContext, viewContext, "Cultivar should use provided context")
    }
    
    func testGrowContextInitialization() throws {
        // Test that Grow can be properly initialized with context
        let grow = Grow(context: viewContext)
        XCTAssertNotNil(grow.managedObjectContext, "Grow should have managed object context")
        XCTAssertEqual(grow.managedObjectContext, viewContext, "Grow should use provided context")
    }
    
    // MARK: - SeedLibrary Functionality Tests
    
    func testCreateSeedFromCultivar() throws {
        // Given
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Tomato"
        cultivar.family = "Solanaceae"
        cultivar.isOrganicCertified = true
        
        // When
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        
        // Then
        XCTAssertNotNil(seed.managedObjectContext, "Created seed should have context")
        XCTAssertEqual(seed.cultivar, cultivar, "Seed should be linked to cultivar")
        XCTAssertEqual(seed.seedName, cultivar.displayName, "Seed name should match cultivar")
        XCTAssertEqual(seed.isCertifiedOrganic, cultivar.isOrganicCertified, "Organic status should match")
        XCTAssertNotNil(seed.createdDate, "Created date should be set")
        XCTAssertNotNil(seed.lastModifiedDate, "Modified date should be set")
    }
    
    func testSeedLibraryComputedProperties() throws {
        // Given
        let seed = SeedLibrary(context: viewContext)
        seed.seedName = "Test Seeds"
        seed.quantity = 10.5
        seed.unit = "packets"
        seed.isCertifiedOrganic = true
        seed.isGMO = false
        seed.isUntreated = true
        
        // Test display properties
        XCTAssertEqual(seed.displayName, "Test Seeds", "Display name should use seed name")
        XCTAssertEqual(seed.quantityDisplay, "10.5 packets", "Quantity display should include units")
        XCTAssertTrue(seed.meetsOrganicCompliance, "Should meet organic compliance")
        XCTAssertEqual(seed.complianceStatus, "Organic Compliant", "Compliance status should be correct")
        
        // Test with non-compliant seed
        seed.isGMO = true
        XCTAssertFalse(seed.meetsOrganicCompliance, "Should not meet organic compliance with GMO")
        XCTAssertTrue(seed.complianceStatus.contains("Contains GMO"), "Status should mention GMO")
    }
    
    func testSeedLibraryRelationships() throws {
        // Given
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Cultivar"
        
        let supplier = SupplierSource(context: viewContext)
        supplier.name = "Test Supplier"
        supplier.supplierType = SupplierKind.seed.rawValue
        
        let seed = SeedLibrary(context: viewContext)
        seed.seedName = "Test Seeds"
        
        // When
        seed.cultivar = cultivar
        seed.supplierSource = supplier
        
        // Then
        XCTAssertEqual(seed.cultivar, cultivar, "Seed should be linked to cultivar")
        XCTAssertEqual(seed.supplierSource, supplier, "Seed should be linked to supplier")
        
        // Test reverse relationships
        XCTAssertEqual(cultivar.seedLibrary, seed, "Cultivar should link back to seed")
        XCTAssertTrue(supplier.seed?.contains(seed) ?? false, "Supplier should contain seed")
    }
    
    // MARK: - Grow and SeedLibrary Relationship Tests
    
    func testGrowSeedRelationship() throws {
        // Given
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Tomato"
        
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        seed.seedName = "Tomato Seeds"
        
        let grow = Grow(context: viewContext)
        grow.title = "Test Grow"
        
        // When
        grow.addToSeed(seed)
        
        // Then
        XCTAssertTrue(grow.seedArray.contains(seed), "Grow should contain the seed")
        XCTAssertEqual(grow.primarySeed, seed, "Primary seed should be the added seed")
        XCTAssertTrue(seed.growsArray.contains(grow), "Seed should link back to grow")
    }
    
    func testGrowComputedProperties() throws {
        // Given
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Tomato"
        cultivar.growingDays = "75-85"
        
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        
        let grow = Grow(context: viewContext)
        grow.title = "Test Grow"
        grow.plantedDate = Date()
        grow.addToSeed(seed)
        
        // Test computed properties
        XCTAssertEqual(grow.displayName, "Test Grow", "Display name should use title")
        XCTAssertTrue(grow.isActive, "Grow should be active without harvest date")
        XCTAssertNotNil(grow.daysSincePlanting, "Days since planting should be calculated")
        XCTAssertNotNil(grow.estimatedHarvestDate, "Estimated harvest date should be calculated")
        
        // Test with harvest
        grow.harvestDate = Date()
        XCTAssertFalse(grow.isActive, "Grow should not be active with harvest date")
    }
    
    // MARK: - Core Data Notification Tests
    
    func testSeedLibraryCreationNotification() throws {
        // Given
        let expectation = XCTestExpectation(description: "SeedLibrary creation notification")
        var receivedNotification = false
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                    if insertedObjects.contains(where: { $0 is SeedLibrary }) {
                        receivedNotification = true
                        expectation.fulfill()
                    }
                }
            }
        
        // When
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Cultivar"
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        seed.seedName = "Test Seeds"
        
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification for SeedLibrary creation")
        
        observer.cancel()
    }
    
    func testSeedLibraryUpdateNotification() throws {
        // Given
        let seed = SeedLibrary(context: viewContext)
        seed.seedName = "Original Name"
        try viewContext.save()
        
        let expectation = XCTestExpectation(description: "SeedLibrary update notification")
        var receivedNotification = false
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                    if updatedObjects.contains(where: { $0 is SeedLibrary }) {
                        receivedNotification = true
                        expectation.fulfill()
                    }
                }
            }
        
        // When
        seed.seedName = "Updated Name"
        seed.updateModificationDate()
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification for SeedLibrary update")
        XCTAssertEqual(seed.seedName, "Updated Name", "Seed name should be updated")
        
        observer.cancel()
    }
    
    // MARK: - Fetch Request Tests
    
    func testSeedLibraryFetchRequests() throws {
        // Given
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Cultivar"
        
        let organicSeed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        organicSeed.seedName = "Organic Seeds"
        organicSeed.isCertifiedOrganic = true
        
        let conventionalSeed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        conventionalSeed.seedName = "Conventional Seeds"
        conventionalSeed.isCertifiedOrganic = false
        
        try viewContext.save()
        
        // Test sorted fetch request
        let sortedRequest = SeedLibrary.fetchRequestSortedByName()
        let sortedResults = try viewContext.fetch(sortedRequest)
        XCTAssertEqual(sortedResults.count, 2, "Should fetch both seeds")
        XCTAssertEqual(sortedResults.first?.seedName, "Conventional Seeds", "Should be sorted by name")
        
        // Test organic only fetch request
        let organicRequest = SeedLibrary.fetchRequestOrganicOnly()
        let organicResults = try viewContext.fetch(organicRequest)
        XCTAssertEqual(organicResults.count, 1, "Should fetch only organic seed")
        XCTAssertEqual(organicResults.first?.seedName, "Organic Seeds", "Should be the organic seed")
    }
    
    // MARK: - View Context Error Handling Tests
    
    func testSeedLibraryWithoutContext() {
        // Test creating SeedLibrary without context should be handled gracefully
        // Note: This would typically crash in Core Data, but we're testing our error handling
        
        let seed = SeedLibrary()
        XCTAssertNil(seed.managedObjectContext, "Seed without context should have nil context")
        
        // Test that computed properties handle nil context gracefully
        let displayName = seed.displayName
        XCTAssertEqual(displayName, "Unknown Seed", "Should provide default display name")
    }
    
    func testGrowWithoutContext() {
        // Test creating Grow without context
        let grow = Grow()
        XCTAssertNil(grow.managedObjectContext, "Grow without context should have nil context")
        
        // Test that computed properties handle nil context gracefully
        let displayName = grow.displayName
        XCTAssertEqual(displayName, "Untitled Grow", "Should provide default display name")
    }
    
    // MARK: - Context Integration Tests
    
    func testViewContextProperlySetInViews() throws {
        // Test that Core Data managed object context is properly passed to views
        // This simulates the issue mentioned in the problem statement
        
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Cultivar"
        
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        seed.seedName = "Test Seeds"
        
        let grow = Grow(context: viewContext)
        grow.title = "Test Grow"
        grow.addToSeed(seed)
        
        // Verify contexts are properly set
        XCTAssertNotNil(cultivar.managedObjectContext, "Cultivar context should not be nil")
        XCTAssertNotNil(seed.managedObjectContext, "Seed context should not be nil")
        XCTAssertNotNil(grow.managedObjectContext, "Grow context should not be nil")
        
        // Verify they all use the same context
        XCTAssertEqual(cultivar.managedObjectContext, viewContext, "Cultivar should use view context")
        XCTAssertEqual(seed.managedObjectContext, viewContext, "Seed should use view context")
        XCTAssertEqual(grow.managedObjectContext, viewContext, "Grow should use view context")
        
        try viewContext.save()
        
        // Verify relationships persist
        XCTAssertEqual(grow.seedArray.count, 1, "Grow should have one seed")
        XCTAssertEqual(grow.primarySeed, seed, "Primary seed should be correct")
        XCTAssertEqual(grow.effectiveCultivar, cultivar, "Effective cultivar should work")
    }
    
    func testGrowCreationWithSeedLibraryWorkflow() throws {
        // Test the complete workflow of creating a grow from seed library
        // This addresses the requirement to modify grow creation to use SeedLibrary
        
        // Create cultivar
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Roma Tomato"
        cultivar.family = "Solanaceae"
        cultivar.growingDays = "75-85"
        cultivar.isOrganicCertified = true
        
        // Create supplier
        let supplier = SupplierSource(context: viewContext)
        supplier.name = "Organic Seeds Co"
        supplier.supplierType = SupplierKind.seed.rawValue
        supplier.isOrganicCertified = true
        
        // Create seed from cultivar
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        seed.seedName = "Roma Tomato Seeds"
        seed.quantity = 10
        seed.unit = "packets"
        seed.supplierSource = supplier
        
        // Create grow from seed (simulating CreateGrowFromSeedView workflow)
        let grow = Grow(context: viewContext)
        grow.title = "Roma Tomato Grow 2024"
        grow.plantedDate = Date()
        grow.addToSeed(seed)
        
        // The grow should not directly reference cultivar anymore
        // Instead it should access cultivar through seed
        grow.cultivar = nil  // Clear direct cultivar relationship
        
        // Verify the new workflow
        XCTAssertEqual(grow.effectiveCultivar, cultivar, "Should get cultivar through seed")
        XCTAssertEqual(grow.primarySeed, seed, "Should have correct primary seed")
        XCTAssertTrue(grow.seedArray.contains(seed), "Should contain the seed")
        
        // Update seed quantity to simulate usage
        let originalQuantity = seed.quantity
        let usedQuantity = 2.0
        seed.quantity -= usedQuantity
        seed.updateModificationDate()
        
        try viewContext.save()
        
        // Verify quantities updated
        XCTAssertEqual(seed.quantity, originalQuantity - usedQuantity, "Seed quantity should be reduced")
        XCTAssertNotNil(seed.lastModifiedDate, "Last modified date should be updated")
        
        // Verify grow can still access cultivar properties
        XCTAssertEqual(grow.effectiveCultivar?.name, "Roma Tomato", "Should access cultivar name through seed")
        XCTAssertEqual(grow.effectiveCultivar?.family, "Solanaceae", "Should access cultivar family through seed")
        XCTAssertEqual(grow.effectiveCultivar?.growingDays, "75-85", "Should access growing days through seed")
    }
    
    func testBackwardCompatibilityWithDirectCultivarRelationship() throws {
        // Test that old grows with direct cultivar relationships still work
        // This ensures backward compatibility
        
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Legacy Tomato"
        cultivar.family = "Solanaceae"
        
        // Create grow with direct cultivar relationship (old way)
        let grow = Grow(context: viewContext)
        grow.title = "Legacy Grow"
        grow.cultivar = cultivar
        // No seed relationship
        
        // Verify backward compatibility
        XCTAssertEqual(grow.effectiveCultivar, cultivar, "Should get cultivar directly when no seeds")
        XCTAssertNil(grow.primarySeed, "Should have no primary seed")
        XCTAssertTrue(grow.seedArray.isEmpty, "Should have no seeds")
        
        try viewContext.save()
        
        // Verify persistence
        viewContext.reset()
        let fetchRequest: NSFetchRequest<Grow> = Grow.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        
        XCTAssertEqual(results.count, 1, "Should persist one grow")
        let persistedGrow = results.first!
        XCTAssertEqual(persistedGrow.effectiveCultivar?.name, "Legacy Tomato", "Should maintain cultivar relationship")
    }
    
    func testSeedLibraryDataIntegrity() throws {
        // Given
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Cultivar"
        
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        seed.seedName = "Test Seeds"
        seed.quantity = 10
        seed.unit = "packets"
        
        // When
        try viewContext.save()
        
        // Clear context and refetch
        viewContext.reset()
        
        let fetchRequest: NSFetchRequest<SeedLibrary> = SeedLibrary.fetchRequest()
        let results = try viewContext.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(results.count, 1, "Should persist one seed")
        let persistedSeed = results.first!
        XCTAssertEqual(persistedSeed.seedName, "Test Seeds", "Name should persist")
        XCTAssertEqual(persistedSeed.quantity, 10, "Quantity should persist")
        XCTAssertEqual(persistedSeed.unit, "packets", "Unit should persist")
    }
    
    func testCascadeDeleteBehavior() throws {
        // Given
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Test Cultivar"
        
        let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
        seed.seedName = "Test Seeds"
        
        let grow = Grow(context: viewContext)
        grow.title = "Test Grow"
        grow.addToSeed(seed)
        
        try viewContext.save()
        
        // When deleting the seed
        viewContext.delete(seed)
        try viewContext.save()
        
        // Then
        let seedFetch: NSFetchRequest<SeedLibrary> = SeedLibrary.fetchRequest()
        let seedResults = try viewContext.fetch(seedFetch)
        XCTAssertEqual(seedResults.count, 0, "Seed should be deleted")
        
        let growFetch: NSFetchRequest<Grow> = Grow.fetchRequest()
        let growResults = try viewContext.fetch(growFetch)
        XCTAssertEqual(growResults.count, 1, "Grow should still exist")
        XCTAssertTrue(growResults.first!.seedArray.isEmpty, "Grow should have no seeds")
    }
}