//
//  WorkerManagementTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for worker management functionality including job completion tracking
//  and worker creation workflow.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class WorkerManagementTests: XCTestCase {
    
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "MaterialsAndPractices")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load store: \(error)")
            }
        }
        
        mockContext = persistentContainer.viewContext
    }
    
    override func tearDownWithError() throws {
        mockContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Worker Creation Tests
    
    func testWorkerCreation() throws {
        // Given: A new worker with all required fields
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.position = "Farm Hand"
        worker.email = "test@farm.com"
        worker.phone = "555-123-4567"
        worker.hireDate = Date()
        worker.isActive = true
        
        // When: Saving the worker
        try mockContext.save()
        
        // Then: Worker should be saved successfully
        let fetchRequest: NSFetchRequest<Worker> = Worker.fetchRequest()
        let workers = try mockContext.fetch(fetchRequest)
        
        XCTAssertEqual(workers.count, 1, "Should have one worker")
        XCTAssertEqual(workers.first?.name, "Test Worker")
        XCTAssertEqual(workers.first?.isActive, true)
    }
    
    func testWorkerPhotoDataStorage() throws {
        // Given: A worker with profile photo data
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Photo Test Worker"
        
        // Create sample image data
        let testImageData = "test image data".data(using: .utf8)
        worker.profilePhotoData = testImageData
        
        // When: Saving the worker
        try mockContext.save()
        
        // Then: Photo data should be preserved
        let fetchRequest: NSFetchRequest<Worker> = Worker.fetchRequest()
        let workers = try mockContext.fetch(fetchRequest)
        
        XCTAssertEqual(workers.count, 1)
        XCTAssertEqual(workers.first?.profilePhotoData, testImageData)
    }
    
    // MARK: - Job Completion Tests
    
    func testJobCompletionTracking() throws {
        // Given: A work practice
        let work = Work(context: mockContext)
        work.name = "Test Practice"
        work.practice = "Weeding"
        work.jobCompleted = false
        
        let beforeTimestamp = Date()
        
        // When: Marking job as completed
        work.jobCompleted = true
        work.jobCompleteTimestamp = Date()
        
        try mockContext.save()
        
        // Then: Job completion should be tracked with timestamp
        let fetchRequest: NSFetchRequest<Work> = Work.fetchRequest()
        let workItems = try mockContext.fetch(fetchRequest)
        
        XCTAssertEqual(workItems.count, 1)
        XCTAssertTrue(workItems.first?.jobCompleted == true)
        XCTAssertNotNil(workItems.first?.jobCompleteTimestamp)
        
        if let timestamp = workItems.first?.jobCompleteTimestamp {
            XCTAssertGreaterThanOrEqualTo(timestamp, beforeTimestamp)
        }
    }
    
    func testJobCompletionToggle() throws {
        // Given: A completed job
        let work = Work(context: mockContext)
        work.name = "Completed Practice"
        work.practice = "Planting"
        work.jobCompleted = true
        work.jobCompleteTimestamp = Date()
        
        try mockContext.save()
        
        // When: Unmarking job as completed
        work.jobCompleted = false
        work.jobCompleteTimestamp = nil
        
        try mockContext.save()
        
        // Then: Completion should be cleared
        let fetchRequest: NSFetchRequest<Work> = Work.fetchRequest()
        let workItems = try mockContext.fetch(fetchRequest)
        
        XCTAssertEqual(workItems.count, 1)
        XCTAssertFalse(workItems.first?.jobCompleted == true)
        XCTAssertNil(workItems.first?.jobCompleteTimestamp)
    }
    
    // MARK: - Worker Time Clock Integration
    
    func testWorkerTimeClockAssociation() throws {
        // Given: A worker with time clock entries
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Time Clock Worker"
        worker.isActive = true
        
        let timeClock = TimeClock(context: mockContext)
        timeClock.id = UUID()
        timeClock.date = Date()
        timeClock.clockInTime = Date()
        timeClock.isActive = true
        timeClock.worker = worker
        
        // When: Saving both entities
        try mockContext.save()
        
        // Then: Association should be maintained
        let workerFetch: NSFetchRequest<Worker> = Worker.fetchRequest()
        let workers = try mockContext.fetch(workerFetch)
        
        XCTAssertEqual(workers.count, 1)
        
        if let timeEntries = workers.first?.timeClockEntries?.allObjects as? [TimeClock] {
            XCTAssertEqual(timeEntries.count, 1)
            XCTAssertEqual(timeEntries.first?.worker, workers.first)
        } else {
            XCTFail("Time clock entries should be associated with worker")
        }
    }
    
    func testActiveWorkerFiltering() throws {
        // Given: Mix of active and inactive workers
        let activeWorker = Worker(context: mockContext)
        activeWorker.id = UUID()
        activeWorker.name = "Active Worker"
        activeWorker.isActive = true
        
        let inactiveWorker = Worker(context: mockContext)
        inactiveWorker.id = UUID()
        inactiveWorker.name = "Inactive Worker"
        inactiveWorker.isActive = false
        
        try mockContext.save()
        
        // When: Fetching workers
        let fetchRequest: NSFetchRequest<Worker> = Worker.fetchRequest()
        let allWorkers = try mockContext.fetch(fetchRequest)
        let activeWorkers = allWorkers.filter { $0.isActive }
        
        // Then: Should correctly filter active workers
        XCTAssertEqual(allWorkers.count, 2)
        XCTAssertEqual(activeWorkers.count, 1)
        XCTAssertEqual(activeWorkers.first?.name, "Active Worker")
    }
}