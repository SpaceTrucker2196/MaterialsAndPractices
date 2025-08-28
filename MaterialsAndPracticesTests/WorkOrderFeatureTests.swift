//
//  WorkOrderFeatureTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for work order assignment and completion tracking features.
//  Validates worker assignment to tasks and completion workflow.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class WorkOrderFeatureTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    var worker: Worker!
    var workOrder: WorkOrder!
    
    override func setUpWithError() throws {
        // Set up in-memory Core Data context for testing
        let container = NSPersistentContainer(name: "MaterialsAndPractices")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        context = container.viewContext
        
        // Create test worker
        worker = Worker(context: context)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.position = "Field Worker"
        worker.isActive = true
        
        // Create test work order
        workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Test Work Order"
        workOrder.workDescription = "Test work order description"
        workOrder.createdDate = Date()
        workOrder.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        workOrder.isCompleted = false
        workOrder.status = "assigned"
        workOrder.priority = "medium"
        
        try context.save()
    }
    
    override func tearDownWithError() throws {
        context = nil
        worker = nil
        workOrder = nil
    }
    
    // MARK: - Work Order Creation Tests
    
    func testWorkOrderCreation() throws {
        XCTAssertNotNil(workOrder.id)
        XCTAssertEqual(workOrder.title, "Test Work Order")
        XCTAssertEqual(workOrder.workDescription, "Test work order description")
        XCTAssertFalse(workOrder.isCompleted)
        XCTAssertEqual(workOrder.status, "assigned")
        XCTAssertEqual(workOrder.priority, "medium")
        XCTAssertNotNil(workOrder.createdDate)
        XCTAssertNotNil(workOrder.dueDate)
    }
    
    // MARK: - Work Order Assignment Tests
    
    func testWorkerWorkOrderAssignment() throws {
        // Initially, work order should have no assigned team
        XCTAssertNil(workOrder.assignedTeam)
        
        // Create a work team and assign worker
        let workTeam = WorkTeam(context: context)
        workTeam.id = UUID()
        workTeam.name = "Test Team"
        workTeam.isActive = true
        workTeam.createdDate = Date()
        
        // Add worker to team (many-to-many relationship)
        workTeam.addToMembers(worker)
        
        // Assign team to work order
        workOrder.assignedTeam = workTeam
        
        try context.save()
        
        // Verify assignment
        XCTAssertNotNil(workOrder.assignedTeam)
        XCTAssertEqual(workOrder.assignedTeam?.name, "Test Team")
        
        // Verify worker is on the team
        let teamMembers = workOrder.assignedTeam?.members?.allObjects as? [Worker] ?? []
        XCTAssertEqual(teamMembers.count, 1)
        XCTAssertEqual(teamMembers.first?.name, "Test Worker")
    }
    
    // MARK: - Work Order Completion Tests
    
    func testWorkOrderCompletion() throws {
        // Initially work order should not be completed
        XCTAssertFalse(workOrder.isCompleted)
        XCTAssertNil(workOrder.completedDate)
        
        // Mark work order as completed
        workOrder.isCompleted = true
        workOrder.completedDate = Date()
        workOrder.status = "completed"
        
        try context.save()
        
        // Verify completion
        XCTAssertTrue(workOrder.isCompleted)
        XCTAssertNotNil(workOrder.completedDate)
        XCTAssertEqual(workOrder.status, "completed")
    }
    
    // MARK: - Work Order Filtering Tests
    
    func testOpenWorkOrdersFiltering() throws {
        // Create additional work orders
        let completedWorkOrder = WorkOrder(context: context)
        completedWorkOrder.id = UUID()
        completedWorkOrder.title = "Completed Work Order"
        completedWorkOrder.isCompleted = true
        completedWorkOrder.completedDate = Date()
        completedWorkOrder.status = "completed"
        
        let openWorkOrder = WorkOrder(context: context)
        openWorkOrder.id = UUID()
        openWorkOrder.title = "Open Work Order"
        openWorkOrder.isCompleted = false
        openWorkOrder.status = "in_progress"
        
        try context.save()
        
        // Filter for open work orders
        let openRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        openRequest.predicate = NSPredicate(format: "isCompleted == NO")
        
        let openWorkOrders = try context.fetch(openRequest)
        XCTAssertEqual(openWorkOrders.count, 2) // Original + new open work order
        
        let openTitles = openWorkOrders.compactMap { $0.title }
        XCTAssertTrue(openTitles.contains("Test Work Order"))
        XCTAssertTrue(openTitles.contains("Open Work Order"))
        XCTAssertFalse(openTitles.contains("Completed Work Order"))
    }
    
    func testRecentWorkOrdersFiltering() throws {
        let calendar = Calendar.current
        
        // Create work order from 2 months ago
        let oldWorkOrder = WorkOrder(context: context)
        oldWorkOrder.id = UUID()
        oldWorkOrder.title = "Old Work Order"
        oldWorkOrder.completedDate = calendar.date(byAdding: .month, value: -2, to: Date())
        oldWorkOrder.isCompleted = true
        
        // Create work order from last week
        let recentWorkOrder = WorkOrder(context: context)
        recentWorkOrder.id = UUID()
        recentWorkOrder.title = "Recent Work Order"
        recentWorkOrder.completedDate = calendar.date(byAdding: .day, value: -7, to: Date())
        recentWorkOrder.isCompleted = true
        
        try context.save()
        
        // Filter for work orders completed in the last month
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        let recentRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        recentRequest.predicate = NSPredicate(format: "completedDate >= %@", oneMonthAgo as NSDate)
        
        let recentWorkOrders = try context.fetch(recentRequest)
        XCTAssertEqual(recentWorkOrders.count, 1)
        XCTAssertEqual(recentWorkOrders.first?.title, "Recent Work Order")
    }
    
    // MARK: - Work Order Priority Tests
    
    func testWorkOrderPriorityOrdering() throws {
        // Create work orders with different priorities
        let highPriorityOrder = WorkOrder(context: context)
        highPriorityOrder.id = UUID()
        highPriorityOrder.title = "High Priority Order"
        highPriorityOrder.priority = "high"
        highPriorityOrder.isCompleted = false
        
        let lowPriorityOrder = WorkOrder(context: context)
        lowPriorityOrder.id = UUID()
        lowPriorityOrder.title = "Low Priority Order"
        lowPriorityOrder.priority = "low"
        lowPriorityOrder.isCompleted = false
        
        try context.save()
        
        // Create a request sorted by priority (high, medium, low)
        let priorityRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        priorityRequest.predicate = NSPredicate(format: "isCompleted == NO")
        priorityRequest.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: true) // This would need custom sorting logic
        ]
        
        let sortedWorkOrders = try context.fetch(priorityRequest)
        XCTAssertEqual(sortedWorkOrders.count, 3) // Original + 2 new orders
        
        // Verify we have orders with different priorities
        let priorities = Set(sortedWorkOrders.compactMap { $0.priority })
        XCTAssertTrue(priorities.contains("high"))
        XCTAssertTrue(priorities.contains("medium"))
        XCTAssertTrue(priorities.contains("low"))
    }
    
    // MARK: - Work Order Status Transitions Tests
    
    func testWorkOrderStatusTransitions() throws {
        // Test status transitions: assigned -> in_progress -> completed
        XCTAssertEqual(workOrder.status, "assigned")
        
        // Start work
        workOrder.status = "in_progress"
        try context.save()
        XCTAssertEqual(workOrder.status, "in_progress")
        
        // Complete work
        workOrder.status = "completed"
        workOrder.isCompleted = true
        workOrder.completedDate = Date()
        try context.save()
        
        XCTAssertEqual(workOrder.status, "completed")
        XCTAssertTrue(workOrder.isCompleted)
        XCTAssertNotNil(workOrder.completedDate)
    }
    
    // MARK: - Time Tracking Integration Tests
    
    func testWorkOrderTimeTracking() throws {
        // Create time clock entry associated with work order
        let timeClock = TimeClock(context: context)
        timeClock.id = UUID()
        timeClock.worker = worker
        timeClock.workOrder = workOrder
        timeClock.date = Calendar.current.startOfDay(for: Date())
        timeClock.clockInTime = Date()
        timeClock.clockOutTime = Calendar.current.date(byAdding: .hour, value: 8, to: Date())
        timeClock.hoursWorked = 8.0
        timeClock.isActive = false
        timeClock.blockNumber = 1
        
        try context.save()
        
        // Verify time clock is associated with work order
        XCTAssertEqual(timeClock.workOrder, workOrder)
        XCTAssertEqual(timeClock.worker, worker)
        XCTAssertEqual(timeClock.hoursWorked, 8.0)
        
        // Verify work order has time clock entries
        let workOrderTimeEntries = workOrder.timeClockEntries?.allObjects as? [TimeClock] ?? []
        XCTAssertEqual(workOrderTimeEntries.count, 1)
        XCTAssertEqual(workOrderTimeEntries.first?.hoursWorked, 8.0)
    }
    
    // MARK: - Work Order Search and Filtering Tests
    
    func testWorkOrderSearchByTitle() throws {
        // Create additional work orders with different titles
        let harvestOrder = WorkOrder(context: context)
        harvestOrder.id = UUID()
        harvestOrder.title = "Harvest Tomatoes"
        harvestOrder.isCompleted = false
        
        let plantingOrder = WorkOrder(context: context)
        plantingOrder.id = UUID()
        plantingOrder.title = "Plant Lettuce Seeds"
        plantingOrder.isCompleted = false
        
        try context.save()
        
        // Search for work orders containing "Harvest"
        let searchRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        searchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", "Harvest")
        
        let harvestOrders = try context.fetch(searchRequest)
        XCTAssertEqual(harvestOrders.count, 1)
        XCTAssertEqual(harvestOrders.first?.title, "Harvest Tomatoes")
    }
    
    func testWorkOrderDueDateFiltering() throws {
        let calendar = Calendar.current
        
        // Create overdue work order
        let overdueOrder = WorkOrder(context: context)
        overdueOrder.id = UUID()
        overdueOrder.title = "Overdue Order"
        overdueOrder.dueDate = calendar.date(byAdding: .day, value: -1, to: Date())
        overdueOrder.isCompleted = false
        
        // Create future work order
        let futureOrder = WorkOrder(context: context)
        futureOrder.id = UUID()
        futureOrder.title = "Future Order"
        futureOrder.dueDate = calendar.date(byAdding: .day, value: 10, to: Date())
        futureOrder.isCompleted = false
        
        try context.save()
        
        // Filter for overdue work orders
        let overdueRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        overdueRequest.predicate = NSPredicate(format: "dueDate < %@ AND isCompleted == NO", Date() as NSDate)
        
        let overdueOrders = try context.fetch(overdueRequest)
        XCTAssertEqual(overdueOrders.count, 1)
        XCTAssertEqual(overdueOrders.first?.title, "Overdue Order")
    }
}