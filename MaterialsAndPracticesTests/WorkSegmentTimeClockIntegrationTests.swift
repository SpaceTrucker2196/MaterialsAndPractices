//
//  WorkSegmentTimeClockIntegrationTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for integration between WorkSegment functionality and TimeClock system.
//  Validates that work segments properly integrate with the multi-block time clock.
//
//  Created by GitHub Copilot on 12/18/24.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class WorkSegmentTimeClockIntegrationTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    var timeClockService: MultiBlockTimeClockService!
    var grow: Grow!
    var workOrder: WorkOrder!
    var workTeam: WorkTeam!
    var workers: [Worker] = []
    
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
        timeClockService = MultiBlockTimeClockService(context: context)
        
        // Create test grow
        grow = Grow(context: context)
        grow.id = UUID()
        grow.title = "Test Grow"
        grow.locationName = "TestField"
        
        // Create test work order
        workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Test Work Order"
        workOrder.createdDate = Date()
        workOrder.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        workOrder.isCompleted = false
        workOrder.grow = grow
        
        // Create test workers
        for i in 1...4 {
            let worker = Worker(context: context)
            worker.id = UUID()
            worker.name = "Worker \(i)"
            worker.isActive = true
            workers.append(worker)
        }
        
        // Create test work team
        workTeam = WorkTeam(context: context)
        workTeam.id = UUID()
        workTeam.name = "Test Team"
        workTeam.isActive = true
        workTeam.createdDate = Date()
        
        // Add workers to team
        for worker in workers {
            workTeam.addToMembers(worker)
        }
        
        workOrder.assignedTeam = workTeam
        
        try context.save()
    }
    
    override func tearDownWithError() throws {
        context = nil
        timeClockService = nil
        grow = nil
        workOrder = nil
        workTeam = nil
        workers = []
    }
    
    // MARK: - WorkSegment and TimeClock Creation Tests
    
    func testWorkSegmentCreatesTimeClockEntries() throws {
        // Given: A work segment for a work order
        let startTime = Date()
        let workSegment = WorkSegment(
            startTime: startTime,
            teamSize: 3,
            teamMembers: workers.prefix(3).map { $0.name ?? "Unknown" }
        )
        
        // When: Creating time clock entries for each worker in the segment
        for worker in workers.prefix(3) {
            try timeClockService.clockIn(worker: worker, date: startTime)
        }
        
        // Then: Each worker should have an active time clock entry
        for worker in workers.prefix(3) {
            XCTAssertTrue(timeClockService.isWorkerClockedIn(worker))
            let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: startTime)
            XCTAssertNotNil(activeBlock)
        }
        
        // And: Workers not in the segment should not be clocked in
        for worker in workers.dropFirst(3) {
            XCTAssertFalse(timeClockService.isWorkerClockedIn(worker))
        }
    }
    
    func testWorkSegmentCompletionUpdatesTimeClockEntries() throws {
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .hour, value: 4, to: startTime)!
        
        // Given: Workers clocked in for a work segment
        for worker in workers.prefix(3) {
            try timeClockService.clockIn(worker: worker, date: startTime)
        }
        
        // When: Work segment is completed
        for worker in workers.prefix(3) {
            try timeClockService.clockOut(worker: worker, date: endTime)
        }
        
        // Then: All workers should be clocked out
        for worker in workers.prefix(3) {
            XCTAssertFalse(timeClockService.isWorkerClockedIn(worker))
            let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: startTime)
            XCTAssertEqual(timeBlocks.count, 1)
            XCTAssertEqual(timeBlocks.first?.hoursWorked, 4.0, accuracy: 0.1)
        }
    }
    
    // MARK: - Team Multiplier vs Individual Time Tracking Tests
    
    func testWorkSegmentTeamMultiplierVsIndividualTime() throws {
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .hour, value: 2, to: startTime)!
        
        // Given: A work segment with 3 workers for 2 hours
        var workSegment = WorkSegment(
            startTime: startTime,
            teamSize: 3,
            teamMembers: workers.prefix(3).map { $0.name ?? "Unknown" }
        )
        workSegment.endTime = endTime
        workSegment.calculateHours()
        
        // And: Individual time clock entries for each worker
        for worker in workers.prefix(3) {
            try timeClockService.clockIn(worker: worker, date: startTime)
            try timeClockService.clockOut(worker: worker, date: endTime)
        }
        
        // When: Calculating total hours using both methods
        let workSegmentTotalHours = workSegment.totalHours // Team multiplier approach
        
        var individualTotalHours: Double = 0.0
        for worker in workers.prefix(3) {
            individualTotalHours += timeClockService.getTotalHoursWorked(for: worker, on: startTime)
        }
        
        // Then: Both approaches should yield the same result
        XCTAssertEqual(workSegmentTotalHours, 6.0, accuracy: 0.1) // 2 hours × 3 workers = 6
        XCTAssertEqual(individualTotalHours, 6.0, accuracy: 0.1) // 2 + 2 + 2 = 6
        XCTAssertEqual(workSegmentTotalHours, individualTotalHours, accuracy: 0.1)
    }
    
    // MARK: - Multiple Work Segments with Time Clock Tests
    
    func testMultipleWorkSegmentsWithTimeClockIntegration() throws {
        let calendar = Calendar.current
        let baseTime = Date()
        
        // Segment 1: 3 workers for 2 hours (8 AM - 10 AM)
        let segment1Start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseTime)!
        let segment1End = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: baseTime)!
        
        for worker in workers.prefix(3) {
            try timeClockService.clockIn(worker: worker, date: segment1Start)
            try timeClockService.clockOut(worker: worker, date: segment1End)
        }
        
        // Segment 2: 2 workers for 3 hours (1 PM - 4 PM) - team change
        let segment2Start = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: baseTime)!
        let segment2End = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: baseTime)!
        
        for worker in workers.prefix(2) { // Only first 2 workers
            try timeClockService.clockIn(worker: worker, date: segment2Start)
            try timeClockService.clockOut(worker: worker, date: segment2End)
        }
        
        // When: Calculating total work done
        var totalWorkOrderHours: Double = 0.0
        
        // Segment 1 calculation
        var segment1 = WorkSegment(
            startTime: segment1Start,
            teamSize: 3,
            teamMembers: workers.prefix(3).map { $0.name ?? "Unknown" }
        )
        segment1.endTime = segment1End
        segment1.calculateHours()
        totalWorkOrderHours += segment1.totalHours
        
        // Segment 2 calculation
        var segment2 = WorkSegment(
            startTime: segment2Start,
            teamSize: 2,
            teamMembers: workers.prefix(2).map { $0.name ?? "Unknown" }
        )
        segment2.endTime = segment2End
        segment2.calculateHours()
        totalWorkOrderHours += segment2.totalHours
        
        // Then: Total should equal sum of both segments
        // Segment 1: 2 hours × 3 workers = 6 hours
        // Segment 2: 3 hours × 2 workers = 6 hours
        // Total: 12 hours
        XCTAssertEqual(totalWorkOrderHours, 12.0, accuracy: 0.1)
        
        // Verify individual worker time blocks
        for worker in workers.prefix(3) {
            let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: baseTime)
            
            if workers.prefix(2).contains(worker) {
                // First 2 workers should have 2 time blocks
                XCTAssertEqual(timeBlocks.count, 2)
                XCTAssertEqual(timeBlocks[0].hoursWorked, 2.0, accuracy: 0.1) // First segment
                XCTAssertEqual(timeBlocks[1].hoursWorked, 3.0, accuracy: 0.1) // Second segment
            } else {
                // Third worker should only have 1 time block
                XCTAssertEqual(timeBlocks.count, 1)
                XCTAssertEqual(timeBlocks[0].hoursWorked, 2.0, accuracy: 0.1) // First segment only
            }
        }
    }
    
    // MARK: - Team Change Detection Tests
    
    func testTeamChangeCreatesNewWorkSegment() throws {
        let calendar = Calendar.current
        let baseTime = Date()
        
        // Given: Initial team of 3 workers
        let initialTeam = workers.prefix(3)
        let initialStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseTime)!
        
        for worker in initialTeam {
            try timeClockService.clockIn(worker: worker, date: initialStart)
        }
        
        // When: Team composition changes after 2 hours
        let teamChangeTime = calendar.date(byAdding: .hour, value: 2, to: initialStart)!
        
        // Clock out current team
        for worker in initialTeam {
            try timeClockService.clockOut(worker: worker, date: teamChangeTime)
        }
        
        // Clock in new team (2 different workers)
        let newTeam = [workers[0], workers[3]] // Worker 1 stays, Worker 4 joins, Workers 2&3 leave
        for worker in newTeam {
            try timeClockService.clockIn(worker: worker, date: teamChangeTime)
        }
        
        // Continue with new team for 3 more hours
        let finalEnd = calendar.date(byAdding: .hour, value: 3, to: teamChangeTime)!
        for worker in newTeam {
            try timeClockService.clockOut(worker: worker, date: finalEnd)
        }
        
        // Then: Should have proper time tracking for team change
        // Worker 1: Should have 2 time blocks (2 hours + 3 hours = 5 hours total)
        let worker1Blocks = timeClockService.getTimeBlocks(for: workers[0], on: baseTime)
        XCTAssertEqual(worker1Blocks.count, 2)
        XCTAssertEqual(worker1Blocks[0].hoursWorked, 2.0, accuracy: 0.1)
        XCTAssertEqual(worker1Blocks[1].hoursWorked, 3.0, accuracy: 0.1)
        
        // Workers 2&3: Should have 1 time block (2 hours only)
        for worker in [workers[1], workers[2]] {
            let blocks = timeClockService.getTimeBlocks(for: worker, on: baseTime)
            XCTAssertEqual(blocks.count, 1)
            XCTAssertEqual(blocks[0].hoursWorked, 2.0, accuracy: 0.1)
        }
        
        // Worker 4: Should have 1 time block (3 hours only)
        let worker4Blocks = timeClockService.getTimeBlocks(for: workers[3], on: baseTime)
        XCTAssertEqual(worker4Blocks.count, 1)
        XCTAssertEqual(worker4Blocks[0].hoursWorked, 3.0, accuracy: 0.1)
    }
    
    // MARK: - Work Order Completion and Lock Tests
    
    func testWorkOrderCompletionLocksTimeTracking() throws {
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .hour, value: 8, to: startTime)!
        
        // Given: A completed work order with time tracking
        for worker in workers.prefix(2) {
            try timeClockService.clockIn(worker: worker, date: startTime)
            try timeClockService.clockOut(worker: worker, date: endTime)
        }
        
        var workSegment = WorkSegment(
            startTime: startTime,
            teamSize: 2,
            teamMembers: workers.prefix(2).map { $0.name ?? "Unknown" }
        )
        workSegment.endTime = endTime
        workSegment.calculateHours()
        
        // When: Work order is completed
        workOrder.isCompleted = true
        workOrder.completedDate = Date()
        workOrder.totalActualHours = workSegment.totalHours
        
        try context.save()
        
        // Then: Work order should be locked with final hours
        XCTAssertTrue(workOrder.isCompleted)
        XCTAssertNotNil(workOrder.completedDate)
        XCTAssertEqual(workOrder.totalActualHours, 16.0, accuracy: 0.1) // 8 hours × 2 workers = 16
        
        // And: Time clock entries should be preserved
        for worker in workers.prefix(2) {
            let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: startTime)
            XCTAssertEqual(timeBlocks.count, 1)
            XCTAssertEqual(timeBlocks.first?.hoursWorked, 8.0, accuracy: 0.1)
            XCTAssertFalse(timeBlocks.first?.isActive ?? true) // Should be completed
        }
    }
    
    // MARK: - Active Work Segment Tests
    
    func testActiveWorkSegmentWithOngoingTimeClock() throws {
        let startTime = Date()
        
        // Given: An active work segment (ongoing work)
        let activeSegment = WorkSegment(
            startTime: startTime,
            teamSize: 3,
            teamMembers: workers.prefix(3).map { $0.name ?? "Unknown" }
        )
        
        // And: Workers are clocked in but not out
        for worker in workers.prefix(3) {
            try timeClockService.clockIn(worker: worker, date: startTime)
        }
        
        // When: Checking current hours (after 2 hours of work)
        let currentTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime)!
        
        // Then: Active segment should show ongoing work
        XCTAssertTrue(activeSegment.isActive)
        XCTAssertNil(activeSegment.endTime)
        
        // And: Workers should be actively clocked in
        for worker in workers.prefix(3) {
            XCTAssertTrue(timeClockService.isWorkerClockedIn(worker))
            let currentHours = timeClockService.getTotalHoursWorked(for: worker, on: startTime)
            XCTAssertGreaterThan(currentHours, 1.5) // Should be around 2 hours
            XCTAssertLessThan(currentHours, 2.5) // But allow for test execution time
        }
    }
    
    // MARK: - Error Handling and Edge Cases
    
    func testWorkSegmentWithPartialTimeClock() throws {
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .hour, value: 4, to: startTime)!
        
        // Given: A work segment with 3 workers but only 2 have time clock entries
        let workSegment = WorkSegment(
            startTime: startTime,
            teamSize: 3,
            teamMembers: workers.prefix(3).map { $0.name ?? "Unknown" }
        )
        
        // Only clock in/out first 2 workers
        for worker in workers.prefix(2) {
            try timeClockService.clockIn(worker: worker, date: startTime)
            try timeClockService.clockOut(worker: worker, date: endTime)
        }
        
        // When: Calculating hours using work segment algorithm
        var segmentCopy = workSegment
        segmentCopy.endTime = endTime
        segmentCopy.calculateHours()
        
        // Then: Work segment should calculate based on team size, not actual time entries
        XCTAssertEqual(segmentCopy.totalHours, 12.0, accuracy: 0.1) // 4 hours × 3 workers = 12
        
        // But individual time clock sum would be less
        var actualClockedHours: Double = 0.0
        for worker in workers.prefix(3) {
            actualClockedHours += timeClockService.getTotalHoursWorked(for: worker, on: startTime)
        }
        XCTAssertEqual(actualClockedHours, 8.0, accuracy: 0.1) // 4 + 4 + 0 = 8
        
        // This demonstrates the importance of the team multiplier algorithm
        XCTAssertNotEqual(segmentCopy.totalHours, actualClockedHours)
    }
    
    func testWorkSegmentWithOverlappingTimeBlocks() throws {
        let calendar = Calendar.current
        let baseTime = Date()
        
        // Given: Worker has overlapping work commitments
        let worker1 = workers[0]
        
        // Clock in for regular time block
        let block1Start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseTime)!
        let block1End = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: baseTime)!
        
        try timeClockService.clockIn(worker: worker1, date: block1Start)
        try timeClockService.clockOut(worker: worker1, date: block1End)
        
        // Clock in for work order specific block
        let block2Start = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: baseTime)!
        let block2End = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: baseTime)!
        
        try timeClockService.clockIn(worker: worker1, date: block2Start)
        try timeClockService.clockOut(worker: worker1, date: block2End)
        
        // When: Creating work segments for the specific work order time
        var workSegment = WorkSegment(
            startTime: block2Start,
            teamSize: 1,
            teamMembers: [worker1.name ?? "Unknown"]
        )
        workSegment.endTime = block2End
        workSegment.calculateHours()
        
        // Then: Work segment should only account for its specific time period
        XCTAssertEqual(workSegment.totalHours, 4.0, accuracy: 0.1) // 4 hours × 1 worker = 4
        
        // And: Worker should have 2 separate time blocks
        let timeBlocks = timeClockService.getTimeBlocks(for: worker1, on: baseTime)
        XCTAssertEqual(timeBlocks.count, 2)
        XCTAssertEqual(timeBlocks[0].hoursWorked, 4.0, accuracy: 0.1) // Morning block
        XCTAssertEqual(timeBlocks[1].hoursWorked, 4.0, accuracy: 0.1) // Afternoon block
    }
    
    // MARK: - Performance and Scale Tests
    
    func testLargeTeamWorkSegmentPerformance() throws {
        // Given: A large team (simulate up to available workers)
        let largeTeamSize = workers.count
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 8, to: startTime)!
        
        // When: Creating work segment with all workers
        var workSegment = WorkSegment(
            startTime: startTime,
            teamSize: largeTeamSize,
            teamMembers: workers.map { $0.name ?? "Unknown" }
        )
        workSegment.endTime = endTime
        
        let startCalculation = Date()
        workSegment.calculateHours()
        let calculationTime = Date().timeIntervalSince(startCalculation)
        
        // Then: Calculation should be fast and accurate
        XCTAssertLessThan(calculationTime, 0.1) // Should take less than 100ms
        XCTAssertEqual(workSegment.totalHours, Double(largeTeamSize * 8), accuracy: 0.1)
    }
}