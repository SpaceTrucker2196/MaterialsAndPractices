//
//  HarvestCreationTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for harvest creation functionality and work order generation
//  Validates harvest creation flow, data validation, and work order integration.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class HarvestCreationTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.preview
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
        persistenceController = nil
    }
    
    // MARK: - Harvest Creation Tests
    
    func testHarvestCreationWithMinimalData() throws {
        let harvest = Harvest(context: viewContext)
        harvest.id = UUID()
        harvest.harvestDate = Date()
        harvest.quantityValue = 50.0
        harvest.quantityUnit = .pounds
        
        try viewContext.save()
        
        XCTAssertNotNil(harvest.id)
        XCTAssertEqual(harvest.quantityValue, 50.0)
        XCTAssertEqual(harvest.quantityUnit, .pounds)
        XCTAssertEqual(harvest.quantityDisplay, "50.00 lb")
    }
    
    func testHarvestCreationWithCompleteData() throws {
        let harvest = Harvest(context: viewContext)
        harvest.id = UUID()
        harvest.harvestDate = Date()
        harvest.harvestDateEnd = Date()
        harvest.quantityValue = 100.0
        harvest.netQuantityValue = 95.0
        harvest.quantityUnit = .pounds
        harvest.containerCount = 5
        harvest.harvestDestination = .packhouse
        harvest.notes = "First harvest of the season"
        harvest.buyer = "Local Market"
        harvest.isCertifiedOrganic = true
        harvest.sanitationVerified = .yes
        harvest.comminglingRisk = .no
        harvest.contaminationRisk = .no
        harvest.complianceHold = false
        harvest.bufferZoneObserved = true
        
        try viewContext.save()
        
        XCTAssertTrue(harvest.isCompliant)
        XCTAssertEqual(harvest.containerCount, 5)
        XCTAssertEqual(harvest.harvestDestination, .packhouse)
        XCTAssertEqual(harvest.notes, "First harvest of the season")
        XCTAssertEqual(harvest.buyer, "Local Market")
        XCTAssertTrue(harvest.isCertifiedOrganic)
        XCTAssertTrue(harvest.bufferZoneObserved)
    }
    
    func testHarvestWithWorkOrderCreation() throws {
        // Create a grow
        let grow = Grow(context: viewContext)
        grow.title = "Test Tomato Grow"
        grow.plantedDate = Date()
        
        // Create a harvest
        let harvest = Harvest(context: viewContext)
        harvest.id = UUID()
        harvest.harvestDate = Date()
        harvest.quantityValue = 75.0
        harvest.quantityUnit = .pounds
        
        // Create work order for harvest
        let workOrder = WorkOrder.createForHarvest(grow, in: viewContext)
        workOrder.totalEstimatedHours = 6.0
        workOrder.priorityLevel = .high
        
        try viewContext.save()
        
        XCTAssertEqual(workOrder.title, "Harvest Test Tomato Grow")
        XCTAssertEqual(workOrder.grow, grow)
        XCTAssertEqual(workOrder.totalEstimatedHours, 6.0)
        XCTAssertEqual(workOrder.priorityLevel, .high)
        XCTAssertNotNil(workOrder.dueDate)
    }
    
    func testHarvestComplianceValidation() throws {
        let harvest = Harvest(context: viewContext)
        
        // Test all compliant
        harvest.sanitationVerified = .yes
        harvest.comminglingRisk = .no
        harvest.contaminationRisk = .no
        harvest.complianceHold = false
        harvest.isCertifiedOrganic = true
        
        XCTAssertTrue(harvest.isCompliant)
        
        // Test sanitation failure
        harvest.sanitationVerified = .no
        XCTAssertFalse(harvest.isCompliant)
        
        // Reset and test commingling risk
        harvest.sanitationVerified = .yes
        harvest.comminglingRisk = .yes
        XCTAssertFalse(harvest.isCompliant)
        
        // Reset and test contamination risk
        harvest.comminglingRisk = .no
        harvest.contaminationRisk = .yes
        XCTAssertFalse(harvest.isCompliant)
        
        // Reset and test compliance hold
        harvest.contaminationRisk = .no
        harvest.complianceHold = true
        XCTAssertFalse(harvest.isCompliant)
        
        // Reset and test organic certification
        harvest.complianceHold = false
        harvest.isCertifiedOrganic = false
        XCTAssertFalse(harvest.isCompliant)
    }
    
    func testHarvestUnitConversions() throws {
        let harvest = Harvest(context: viewContext)
        harvest.quantityValue = 100.0
        
        // Test pounds
        harvest.quantityUnit = .pounds
        XCTAssertEqual(harvest.quantityDisplay, "100.00 lb")
        
        // Test kilograms
        harvest.quantityUnit = .kilograms
        XCTAssertEqual(harvest.quantityDisplay, "100.00 kg")
        
        // Test each
        harvest.quantityUnit = .each
        XCTAssertEqual(harvest.quantityDisplay, "100.00 ea")
        
        // Test cases
        harvest.quantityUnit = .cases
        XCTAssertEqual(harvest.quantityDisplay, "100.00 cs")
        
        // Test bunches
        harvest.quantityUnit = .bunches
        XCTAssertEqual(harvest.quantityDisplay, "100.00 bn")
    }
    
    func testHarvestDestinationOptions() throws {
        let harvest = Harvest(context: viewContext)
        
        // Test all destination options
        let destinations: [Harvest.HarvestDestination] = [.cooler, .packhouse, .washArea, .directSale, .compost, .other]
        
        for destination in destinations {
            harvest.harvestDestination = destination
            XCTAssertEqual(harvest.harvestDestination, destination)
        }
    }
    
    // MARK: - Work Order Integration Tests
    
    func testWorkOrderStatusProgression() throws {
        let workOrder = WorkOrder(context: viewContext)
        workOrder.id = UUID()
        workOrder.title = "Test Work Order"
        
        // Test initial state
        XCTAssertEqual(workOrder.statusLevel, .pending)
        XCTAssertFalse(workOrder.isCompleted)
        
        // Test progression
        workOrder.statusLevel = .inProgress
        XCTAssertEqual(workOrder.statusLevel, .inProgress)
        
        workOrder.statusLevel = .completed
        workOrder.isCompleted = true
        workOrder.completedDate = Date()
        XCTAssertEqual(workOrder.statusLevel, .completed)
        XCTAssertTrue(workOrder.isCompleted)
        XCTAssertNotNil(workOrder.completedDate)
    }
    
    func testWorkOrderPriorityHandling() throws {
        let workOrder = WorkOrder(context: viewContext)
        
        // Test priority setting and sort order
        workOrder.priorityLevel = .urgent
        XCTAssertEqual(workOrder.priorityLevel.sortOrder, 0)
        
        workOrder.priorityLevel = .high
        XCTAssertEqual(workOrder.priorityLevel.sortOrder, 1)
        
        workOrder.priorityLevel = .medium
        XCTAssertEqual(workOrder.priorityLevel.sortOrder, 2)
        
        workOrder.priorityLevel = .low
        XCTAssertEqual(workOrder.priorityLevel.sortOrder, 3)
    }
    
    func testWorkOrderTeamAssignment() throws {
        let workOrder = WorkOrder(context: viewContext)
        let team = WorkTeam(context: viewContext)
        team.name = "Harvest Team"
        
        let worker1 = Worker(context: viewContext)
        worker1.name = "John Doe"
        let worker2 = Worker(context: viewContext)
        worker2.name = "Jane Smith"
        
        team.addToMembers(worker1)
        team.addToMembers(worker2)
        
        workOrder.assignedTeam = team
        
        let assignedWorkers = workOrder.assignedWorkers()
        XCTAssertEqual(assignedWorkers.count, 2)
        XCTAssertTrue(assignedWorkers.contains(worker1))
        XCTAssertTrue(assignedWorkers.contains(worker2))
    }
    
    func testWorkOrderProgressCalculation() throws {
        let workOrder = WorkOrder(context: viewContext)
        
        // Create work items
        let workItem1 = Work(context: viewContext)
        workItem1.isCompleted = true
        let workItem2 = Work(context: viewContext)
        workItem2.isCompleted = false
        let workItem3 = Work(context: viewContext)
        workItem3.isCompleted = true
        
        workOrder.addToWorkItems(workItem1)
        workOrder.addToWorkItems(workItem2)
        workOrder.addToWorkItems(workItem3)
        
        // Test progress calculation (2 out of 3 completed)
        let expectedProgress = 2.0 / 3.0
        XCTAssertEqual(workOrder.progressPercentage, expectedProgress, accuracy: 0.001)
        
        // Test with no work items
        let emptyWorkOrder = WorkOrder(context: viewContext)
        XCTAssertEqual(emptyWorkOrder.progressPercentage, 0.0)
    }
    
    // MARK: - Validation and Edge Cases
    
    func testHarvestWithNegativeQuantities() throws {
        let harvest = Harvest(context: viewContext)
        harvest.quantityValue = -10.0
        harvest.netQuantityValue = -5.0
        
        // Display should handle negative values gracefully
        XCTAssertTrue(harvest.quantityDisplay.contains("0.00"))
        XCTAssertTrue(harvest.netQuantityDisplay.contains("0.00"))
    }
    
    func testHarvestWithZeroQuantities() throws {
        let harvest = Harvest(context: viewContext)
        harvest.quantityValue = 0.0
        harvest.netQuantityValue = 0.0
        harvest.quantityUnit = .pounds
        
        XCTAssertEqual(harvest.quantityDisplay, "0.00 lb")
        XCTAssertEqual(harvest.netQuantityDisplay, "0.00 lb")
    }
    
    func testWorkOrderOverdueDetection() throws {
        let workOrder = WorkOrder(context: viewContext)
        workOrder.isCompleted = false
        
        // Test future due date (not overdue)
        workOrder.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        XCTAssertFalse(workOrder.isOverdue)
        
        // Test past due date (overdue)
        workOrder.dueDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        XCTAssertTrue(workOrder.isOverdue)
        
        // Test completed work order (not overdue regardless of date)
        workOrder.isCompleted = true
        XCTAssertFalse(workOrder.isOverdue)
        
        // Test no due date
        workOrder.isCompleted = false
        workOrder.dueDate = nil
        XCTAssertFalse(workOrder.isOverdue)
    }
    
    // MARK: - Performance Tests
    
    func testHarvestCreationPerformance() throws {
        measure {
            for i in 0..<100 {
                let harvest = Harvest(context: viewContext)
                harvest.id = UUID()
                harvest.harvestDate = Date()
                harvest.quantityValue = Double(i)
                harvest.quantityUnit = .pounds
                harvest.notes = "Performance test harvest \(i)"
                harvest.isCertifiedOrganic = i % 2 == 0
            }
            
            try! viewContext.save()
        }
    }
    
    func testWorkOrderCreationPerformance() throws {
        let grow = Grow(context: viewContext)
        grow.title = "Performance Test Grow"
        
        measure {
            for i in 0..<50 {
                let workOrder = WorkOrder.createForHarvest(grow, in: viewContext)
                workOrder.totalEstimatedHours = Double(i)
                workOrder.notes = "Performance test work order \(i)"
            }
            
            try! viewContext.save()
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testHarvestDataPersistence() throws {
        let harvestId = UUID()
        let harvestDate = Date()
        let quantity = 123.45
        let notes = "Test harvest persistence"
        
        // Create and save harvest
        let harvest = Harvest(context: viewContext)
        harvest.id = harvestId
        harvest.harvestDate = harvestDate
        harvest.quantityValue = quantity
        harvest.notes = notes
        harvest.quantityUnit = .kilograms
        harvest.isCertifiedOrganic = true
        
        try viewContext.save()
        
        // Clear context and refetch
        viewContext.reset()
        
        let fetchRequest: NSFetchRequest<Harvest> = Harvest.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", harvestId as CVarArg)
        
        let results = try viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1)
        
        let persistedHarvest = results.first!
        XCTAssertEqual(persistedHarvest.id, harvestId)
        XCTAssertEqual(persistedHarvest.harvestDate, harvestDate)
        XCTAssertEqual(persistedHarvest.quantityValue, quantity, accuracy: 0.01)
        XCTAssertEqual(persistedHarvest.notes, notes)
        XCTAssertEqual(persistedHarvest.quantityUnit, .kilograms)
        XCTAssertTrue(persistedHarvest.isCertifiedOrganic)
    }
}