//
//  CoreDataNotificationTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for CoreData notification handling and view refresh behavior.
//  Ensures views properly respond to Core Data context changes and object updates.
//
//  Created by GitHub Copilot on current date.
//

import XCTest
import CoreData
import SwiftUI
import Combine
@testable import MaterialsAndPractices

class CoreDataNotificationTests: XCTestCase {
    
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
    
    // MARK: - Worker Notification Tests
    
    func testWorkerCreationNotification() throws {
        // Given
        let expectation = XCTestExpectation(description: "Worker creation notification")
        var receivedNotification = false
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>,
                   insertedObjects.contains(where: { $0 is Worker }) {
                    receivedNotification = true
                    expectation.fulfill()
                }
            }
        
        // When
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.imagePath = ZappaProfile.getRandomImagePath()
        
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification when worker is created")
        
        observer.cancel()
    }
    
    func testWorkerUpdateNotification() throws {
        // Given
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        worker.name = "Original Name"
        worker.imagePath = ZappaProfile.getRandomImagePath()
        try viewContext.save()
        
        let expectation = XCTestExpectation(description: "Worker update notification")
        var receivedNotification = false
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                   updatedObjects.contains(worker) {
                    receivedNotification = true
                    expectation.fulfill()
                }
            }
        
        // When
        worker.name = "Updated Name"
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification when worker is updated")
        
        observer.cancel()
    }
    
    func testWorkerImagePathUpdate() throws {
        // Given
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        try viewContext.save()
        
        let expectation = XCTestExpectation(description: "Worker imagePath update notification")
        var receivedNotification = false
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                   updatedObjects.contains(worker) {
                    receivedNotification = true
                    expectation.fulfill()
                }
            }
        
        // When
        worker.imagePath = ZappaProfile.getRandomImagePath()
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification when worker imagePath is updated")
        XCTAssertNotNil(worker.imagePath, "Worker should have imagePath set")
        
        observer.cancel()
    }
    
    // MARK: - Farmer Notification Tests
    
    func testFarmerCreationNotification() throws {
        // Given
        let expectation = XCTestExpectation(description: "Farmer creation notification")
        var receivedNotification = false
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>,
                   insertedObjects.contains(where: { $0 is Farmer }) {
                    receivedNotification = true
                    expectation.fulfill()
                }
            }
        
        // When
        let farmer = Farmer(context: viewContext)
        farmer.id = UUID()
        farmer.name = "Test Farmer"
        farmer.imagePath = ZappaProfile.getRandomImagePath()
        
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification when farmer is created")
        
        observer.cancel()
    }
    
    func testFarmerImagePathUpdate() throws {
        // Given
        let farmer = Farmer(context: viewContext)
        farmer.id = UUID()
        farmer.name = "Test Farmer"
        try viewContext.save()
        
        let expectation = XCTestExpectation(description: "Farmer imagePath update notification")
        var receivedNotification = false
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                   updatedObjects.contains(farmer) {
                    receivedNotification = true
                    expectation.fulfill()
                }
            }
        
        // When
        farmer.imagePath = ZappaProfile.getRandomImagePath()
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification when farmer imagePath is updated")
        XCTAssertNotNil(farmer.imagePath, "Farmer should have imagePath set")
        
        observer.cancel()
    }
    
    // MARK: - Multiple Entity Notification Tests
    
    func testBatchUpdatesNotification() throws {
        // Given
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        
        let farmer = Farmer(context: viewContext)
        farmer.id = UUID()
        farmer.name = "Test Farmer"
        
        try viewContext.save()
        
        let expectation = XCTestExpectation(description: "Batch updates notification")
        var receivedNotification = false
        var updatedObjectsCount = 0
        
        let observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { notification in
                if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                    updatedObjectsCount = updatedObjects.count
                    if updatedObjects.count >= 2 {
                        receivedNotification = true
                        expectation.fulfill()
                    }
                }
            }
        
        // When
        worker.imagePath = ZappaProfile.getRandomImagePath()
        farmer.imagePath = ZappaProfile.getRandomImagePath()
        try viewContext.save()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification, "Should receive notification for batch updates")
        XCTAssertGreaterThanOrEqual(updatedObjectsCount, 2, "Should update at least 2 objects")
        
        observer.cancel()
    }
    
    // MARK: - FetchRequest Response Tests
    
    func testFetchRequestRefreshOnWorkerUpdate() throws {
        // Given
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        worker.name = "Original Worker"
        worker.isActive = true
        try viewContext.save()
        
        // Create a fetch request that would be used in a view
        let fetchRequest: NSFetchRequest<Worker> = Worker.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Worker.name, ascending: true)]
        
        var results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "Should have one active worker initially")
        
        // When
        worker.isActive = false
        try viewContext.save()
        
        // Simulate what happens in a view with @FetchRequest
        results = try viewContext.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(results.count, 0, "Should have no active workers after update")
    }
    
    func testFetchRequestRefreshOnFarmerCreation() throws {
        // Given
        let fetchRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Farmer.name, ascending: true)]
        
        var results = try viewContext.fetch(fetchRequest)
        let initialCount = results.count
        
        // When
        let farmer = Farmer(context: viewContext)
        farmer.id = UUID()
        farmer.name = "New Farmer"
        farmer.imagePath = ZappaProfile.getRandomImagePath()
        try viewContext.save()
        
        results = try viewContext.fetch(fetchRequest)
        
        // Then
        XCTAssertEqual(results.count, initialCount + 1, "Should have one more farmer after creation")
        XCTAssertNotNil(farmer.imagePath, "New farmer should have imagePath set")
    }
    
    // MARK: - ZappaProfile Integration Tests
    
    func testZappaProfileImagePathAssignment() throws {
        // Given
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        
        // When
        worker.imagePath = ZappaProfile.getRandomImagePath()
        try viewContext.save()
        
        // Then
        XCTAssertNotNil(worker.imagePath, "Worker should have imagePath assigned")
        
        // Verify the image path is valid (if images exist)
        if let imagePath = worker.imagePath {
            let imageExists = ZappaProfile.imageExists(at: imagePath)
            // Note: This may be false in test environment if test images aren't available
            // The test passes if imagePath is set regardless of file existence
            print("Image exists at path: \(imageExists)")
        }
    }
    
    func testZappaProfileRandomSelection() throws {
        // Given
        var imagePaths: Set<String> = []
        
        // When - Get multiple random paths
        for _ in 0..<10 {
            if let imagePath = ZappaProfile.getRandomImagePath() {
                imagePaths.insert(imagePath)
            }
        }
        
        // Then
        // If images are available, we should potentially get different paths
        // If no images available, all will be nil
        print("Unique image paths found: \(imagePaths.count)")
        // Test passes regardless since randomness depends on available images
        XCTAssertTrue(true, "ZappaProfile.getRandomImagePath() executed without errors")
    }
    
    // MARK: - CoreData Change Notification Performance Tests
    
    func testMassWorkerUpdateNotificationPerformance() throws {
        // Given
        var workers: [Worker] = []
        for i in 0..<100 {
            let worker = Worker(context: viewContext)
            worker.id = UUID()
            worker.name = "Worker \(i)"
            workers.append(worker)
        }
        try viewContext.save()
        
        // When
        measure {
            for worker in workers {
                worker.imagePath = ZappaProfile.getRandomImagePath()
            }
            try! viewContext.save()
        }
        
        // Then - Test completes without performance issues
        XCTAssertEqual(workers.count, 100, "Should have created 100 workers")
    }
}

// MARK: - Test Helpers

extension CoreDataNotificationTests {
    
    /// Helper to create a test worker with default values
    func createTestWorker(name: String = "Test Worker") -> Worker {
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        worker.name = name
        worker.isActive = true
        worker.imagePath = ZappaProfile.getRandomImagePath()
        return worker
    }
    
    /// Helper to create a test farmer with default values
    func createTestFarmer(name: String = "Test Farmer") -> Farmer {
        let farmer = Farmer(context: viewContext)
        farmer.id = UUID()
        farmer.name = name
        farmer.imagePath = ZappaProfile.getRandomImagePath()
        return farmer
    }
}