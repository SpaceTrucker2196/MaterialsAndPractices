//
//  FarmPracticeTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for FarmPractice entity and related functionality
//  Validates Core Data relationships and business logic
//
//  Created by GitHub Copilot on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class FarmPracticeTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        context = nil
    }
    
    // MARK: - FarmPractice Entity Tests
    
    func testFarmPracticeCreation() throws {
        // Given
        let practice = FarmPractice(context: context)
        practice.practiceID = UUID()
        practice.name = "Test Practice"
        practice.descriptionText = "Test Description"
        practice.trainingRequired = "Test Training"
        practice.frequency = "Test Frequency"
        practice.certification = "Test Certification"
        practice.lastUpdated = Date()
        
        // When
        try context.save()
        
        // Then
        let request: NSFetchRequest<FarmPractice> = FarmPractice.fetchRequest()
        let practices = try context.fetch(request)
        
        XCTAssertEqual(practices.count, 1)
        XCTAssertEqual(practices.first?.name, "Test Practice")
        XCTAssertEqual(practices.first?.descriptionText, "Test Description")
    }
    
    func testFarmPracticeDefaultCreation() throws {
        // When
        let practice = FarmPractice.createDefault(in: context)
        try context.save()
        
        // Then
        XCTAssertEqual(practice.name, "New Practice")
        XCTAssertEqual(practice.descriptionText, "Describe the recordkeeping or food safety practice.")
        XCTAssertEqual(practice.trainingRequired, "Training details not yet provided.")
        XCTAssertEqual(practice.frequency, "As needed")
        XCTAssertEqual(practice.certification, "Unspecified")
        XCTAssertNotNil(practice.practiceID)
        XCTAssertNotNil(practice.lastUpdated)
    }
    
    func testPredefinedPracticesCreation() throws {
        // When
        let practices = FarmPractice.createPredefinedPractices(in: context)
        try context.save()
        
        // Then
        XCTAssertEqual(practices.count, 9)
        
        let practiceNames = practices.map { $0.name }
        XCTAssertTrue(practiceNames.contains("🧪 Soil Amendment Recordkeeping"))
        XCTAssertTrue(practiceNames.contains("🌱 Seed Source Documentation"))
        XCTAssertTrue(practiceNames.contains("🐞 Pest and Weed Management Log"))
        XCTAssertTrue(practiceNames.contains("🌾 Harvest Recordkeeping"))
        XCTAssertTrue(practiceNames.contains("🧼 Worker Hygiene and Food Safety Training"))
        XCTAssertTrue(practiceNames.contains("💧 Water Source and Quality Monitoring"))
        XCTAssertTrue(practiceNames.contains("♻️ Manure and Compost Application Log"))
        XCTAssertTrue(practiceNames.contains("🧽 Equipment Sanitation Log"))
        XCTAssertTrue(practiceNames.contains("🔍 Traceability Lot Codes and Product Flow"))
    }
    
    // MARK: - WorkOrder-FarmPractice Relationship Tests
    
    func testWorkOrderFarmPracticeRelationship() throws {
        // Given
        let practice1 = FarmPractice.createDefault(in: context)
        practice1.name = "Practice 1"
        
        let practice2 = FarmPractice.createDefault(in: context)
        practice2.name = "Practice 2"
        
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Test Work Order"
        workOrder.isCompleted = false
        
        // When
        workOrder.addToFarmPractices(practice1)
        workOrder.addToFarmPractices(practice2)
        try context.save()
        
        // Then
        XCTAssertEqual(workOrder.farmPractices?.count, 2)
        
        let workOrderPractices = workOrder.farmPractices?.allObjects as? [FarmPractice] ?? []
        let practiceNames = workOrderPractices.map { $0.name }
        XCTAssertTrue(practiceNames.contains("Practice 1"))
        XCTAssertTrue(practiceNames.contains("Practice 2"))
        
        // Test reverse relationship
        let practice1WorkOrders = practice1.workOrders?.allObjects as? [WorkOrder] ?? []
        XCTAssertEqual(practice1WorkOrders.count, 1)
        XCTAssertEqual(practice1WorkOrders.first?.title, "Test Work Order")
    }
    
    func testWorkOrderFarmPracticeRemoval() throws {
        // Given
        let practice = FarmPractice.createDefault(in: context)
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Test Work Order"
        workOrder.isCompleted = false
        
        workOrder.addToFarmPractices(practice)
        try context.save()
        
        // When
        workOrder.removeFromFarmPractices(practice)
        try context.save()
        
        // Then
        XCTAssertEqual(workOrder.farmPractices?.count, 0)
        XCTAssertEqual(practice.workOrders?.count, 0)
    }
    
    // MARK: - FarmPracticeSeeder Tests
    
    func testFarmPracticeSeederIfNeeded() throws {
        // Given - empty context
        
        // When
        FarmPracticeSeeder.seedDefaultPracticesIfNeeded(context: context)
        
        // Then
        let request: NSFetchRequest<FarmPractice> = FarmPractice.fetchRequest()
        let practices = try context.fetch(request)
        XCTAssertEqual(practices.count, 9)
    }
    
    func testFarmPracticeSeederSkipsIfExists() throws {
        // Given - create one practice
        _ = FarmPractice.createDefault(in: context)
        try context.save()
        
        // When
        FarmPracticeSeeder.seedDefaultPracticesIfNeeded(context: context)
        
        // Then - should not add more practices
        let request: NSFetchRequest<FarmPractice> = FarmPractice.fetchRequest()
        let practices = try context.fetch(request)
        XCTAssertEqual(practices.count, 1) // Only the one we created
    }
    
    func testFarmPracticeForceReseed() throws {
        // Given - create one practice
        _ = FarmPractice.createDefault(in: context)
        try context.save()
        
        // When
        FarmPracticeSeeder.forceReseedPractices(context: context)
        
        // Then - should replace with 9 default practices
        let request: NSFetchRequest<FarmPractice> = FarmPractice.fetchRequest()
        let practices = try context.fetch(request)
        XCTAssertEqual(practices.count, 9)
        
        // Verify they are the predefined practices, not our test one
        let practiceNames = practices.map { $0.name }
        XCTAssertFalse(practiceNames.contains("New Practice"))
        XCTAssertTrue(practiceNames.contains("🧪 Soil Amendment Recordkeeping"))
    }
    
    // MARK: - Data Validation Tests
    
    func testPracticeFieldValidation() throws {
        let practices = FarmPractice.createPredefinedPractices(in: context)
        
        for practice in practices {
            // All practices should have non-empty required fields
            XCTAssertFalse(practice.name.isEmpty, "Practice name should not be empty")
            XCTAssertFalse(practice.descriptionText.isEmpty, "Practice description should not be empty")
            XCTAssertFalse(practice.trainingRequired.isEmpty, "Training required should not be empty")
            XCTAssertFalse(practice.frequency.isEmpty, "Frequency should not be empty")
            XCTAssertFalse(practice.certification.isEmpty, "Certification should not be empty")
            XCTAssertNotNil(practice.practiceID, "Practice ID should not be nil")
            XCTAssertNotNil(practice.lastUpdated, "Last updated should not be nil")
        }
    }
}