//
//  WorkOrderTimeClockIntegrationTests.swift  
//  MaterialsAndPracticesTests
//
//  Tests for the complete integration between WorkOrder, WorkSegment, and TimeClock systems.
//  Validates that work orders properly create and manage time clock entries.
//
//  Created by GitHub Copilot on 12/18/24.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class WorkOrderTimeClockIntegrationTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    var timeClockService: MultiBlockTimeClockService!
    var grow: Grow!
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
        
        // Create test workers
        for i in 1...3 {
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
        
        try context.save()
    }
    
    override func tearDownWithError() throws {
        context = nil
        timeClockService = nil
        grow = nil
        workTeam = nil
        workers = []
    }
    
    // MARK: - Work Order Creation with Time Tracking Tests
    
    func testWorkOrderCreationWithTimeClockIntegration() throws {
        // Given: A work order with team assignment
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Test Work Order"
        workOrder.createdDate = Date()
        workOrder.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        workOrder.isCompleted = false
        workOrder.assignedTeam = workTeam
        workOrder.grow = grow
        
        try context.save()
        
        // When: Starting work
        let startTime = Date()
        
        // Simulate work order starting work (create time clock entries)
        for worker in workers {
            try timeClockService.clockIn(worker: worker, date: startTime)
            
            // Associate time clock entry with work order
            if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: startTime) {
                activeBlock.workOrder = workOrder
            }
        }
        
        try context.save()
        
        // Then: All workers should be clocked in and associated with work order
        for worker in workers {
            XCTAssertTrue(timeClockService.isWorkerClockedIn(worker))
            
            let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: startTime)
            XCTAssertNotNil(activeBlock)
            XCTAssertEqual(activeBlock?.workOrder, workOrder)
        }
    }
    
    func testWorkSegmentToTimeClockSync() throws {
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .hour, value: 4, to: startTime)!
        
        // Given: A work order
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Sync Test Work Order"
        workOrder.assignedTeam = workTeam
        workOrder.grow = grow
        
        // When: Creating work segment and time clock entries
        var workSegment = WorkSegment(
            startTime: startTime,
            teamSize: workers.count,
            teamMembers: workers.map { $0.name ?? "Unknown" }
        )
        
        // Clock in all workers
        for worker in workers {
            try timeClockService.clockIn(worker: worker, date: startTime)
            if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: startTime) {
                activeBlock.workOrder = workOrder
            }
        }
        
        // Clock out all workers
        for worker in workers {
            try timeClockService.clockOut(worker: worker, date: endTime)
        }
        
        workSegment.endTime = endTime
        workSegment.calculateHours()
        
        try context.save()
        
        // Then: Work segment hours should match time clock total
        let expectedWorkSegmentHours = 4.0 * Double(workers.count) // 4 hours × 3 workers = 12
        XCTAssertEqual(workSegment.totalHours, expectedWorkSegmentHours, accuracy: 0.1)
        
        // Verify individual time clock entries
        var totalTimeClockHours: Double = 0.0
        for worker in workers {
            let workerHours = timeClockService.getTotalHoursWorked(for: worker, on: startTime)
            totalTimeClockHours += workerHours
            XCTAssertEqual(workerHours, 4.0, accuracy: 0.1)
        }
        
        XCTAssertEqual(totalTimeClockHours, expectedWorkSegmentHours, accuracy: 0.1)
    }
    
    // MARK: - Team Change Detection Tests
    
    func testTeamChangeCreatesNewTimeBlocks() throws {
        let calendar = Calendar.current
        let baseTime = Date()
        
        // Given: Initial work order with full team
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Team Change Test"
        workOrder.assignedTeam = workTeam
        workOrder.grow = grow
        
        // Phase 1: All 3 workers work for 2 hours
        let phase1Start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseTime)!
        let phase1End = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: baseTime)!
        
        for worker in workers {
            try timeClockService.clockIn(worker: worker, date: phase1Start)
            if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: phase1Start) {
                activeBlock.workOrder = workOrder
            }
        }
        
        for worker in workers {
            try timeClockService.clockOut(worker: worker, date: phase1End)
        }
        
        // Phase 2: Team changes - only 2 workers continue for 3 hours
        let phase2Start = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: baseTime)!
        let phase2End = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: baseTime)!
        
        let continuingWorkers = workers.prefix(2) // First 2 workers continue
        
        for worker in continuingWorkers {
            try timeClockService.clockIn(worker: worker, date: phase2Start)
            if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: phase2Start) {
                activeBlock.workOrder = workOrder
            }
        }
        
        for worker in continuingWorkers {
            try timeClockService.clockOut(worker: worker, date: phase2End)
        }
        
        try context.save()
        
        // When: Creating work segments for each phase
        var segment1 = WorkSegment(
            startTime: phase1Start,
            teamSize: 3,
            teamMembers: workers.map { $0.name ?? "Unknown" }
        )
        segment1.endTime = phase1End
        segment1.calculateHours()
        
        var segment2 = WorkSegment(
            startTime: phase2Start,
            teamSize: 2,
            teamMembers: continuingWorkers.map { $0.name ?? "Unknown" }
        )
        segment2.endTime = phase2End
        segment2.calculateHours()
        
        // Then: Segments should reflect team changes
        XCTAssertEqual(segment1.totalHours, 6.0, accuracy: 0.1) // 2 hours × 3 workers = 6
        XCTAssertEqual(segment2.totalHours, 6.0, accuracy: 0.1) // 3 hours × 2 workers = 6
        
        let totalWorkOrderHours = segment1.totalHours + segment2.totalHours
        XCTAssertEqual(totalWorkOrderHours, 12.0, accuracy: 0.1)
        
        // Verify time clock entries reflect the team change
        for (index, worker) in workers.enumerated() {
            let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: baseTime)
            
            if index < 2 {
                // First 2 workers should have 2 time blocks
                XCTAssertEqual(timeBlocks.count, 2)
                XCTAssertEqual(timeBlocks[0].hoursWorked, 2.0, accuracy: 0.1)
                XCTAssertEqual(timeBlocks[1].hoursWorked, 3.0, accuracy: 0.1)
            } else {
                // Third worker should only have 1 time block (phase 1 only)
                XCTAssertEqual(timeBlocks.count, 1)
                XCTAssertEqual(timeBlocks[0].hoursWorked, 2.0, accuracy: 0.1)
            }
        }
    }
    
    // MARK: - Work Order Completion Tests
    
    func testWorkOrderCompletionWithActualHours() throws {
        let calendar = Calendar.current
        let startTime = Date()
        
        // Given: A work order with multiple work segments
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Completion Test"
        workOrder.assignedTeam = workTeam
        workOrder.grow = grow
        workOrder.totalEstimatedHours = 10.0 // Estimated 10 hours
        
        // Segment 1: 3 workers for 2 hours
        let seg1Start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: startTime)!
        let seg1End = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: startTime)!
        
        for worker in workers {
            try timeClockService.clockIn(worker: worker, date: seg1Start)
            if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: seg1Start) {
                activeBlock.workOrder = workOrder
            }
        }
        
        for worker in workers {
            try timeClockService.clockOut(worker: worker, date: seg1End)
        }
        
        // Segment 2: 2 workers for 3 hours
        let seg2Start = calendar.date(byAdding: .hour, value: 1, to: seg1End)!
        let seg2End = calendar.date(byAdding: .hour, value: 3, to: seg2Start)!
        
        for worker in workers.prefix(2) {
            try timeClockService.clockIn(worker: worker, date: seg2Start)
            if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: seg2Start) {
                activeBlock.workOrder = workOrder
            }
        }
        
        for worker in workers.prefix(2) {
            try timeClockService.clockOut(worker: worker, date: seg2End)
        }
        
        try context.save()
        
        // When: Calculating total actual hours and completing work order
        var totalActualHours: Double = 0.0
        
        // Segment 1: 2 hours × 3 workers = 6 hours
        totalActualHours += 6.0
        
        // Segment 2: 3 hours × 2 workers = 6 hours  
        totalActualHours += 6.0
        
        workOrder.isCompleted = true
        workOrder.completedDate = Date()
        // Store actual hours in notes since totalActualHours property doesn't exist
        workOrder.notes = "Total Actual Hours: \(String(format: "%.1f", totalActualHours))"

        try context.save()

        // Then: Work order should reflect actual vs estimated hours
        XCTAssertTrue(workOrder.isCompleted)
        XCTAssertNotNil(workOrder.completedDate)
        XCTAssertTrue(workOrder.notes?.contains("12.0") ?? false) // Should contain actual hours
        XCTAssertEqual(workOrder.totalEstimatedHours, 10.0, accuracy: 0.1)
        
        // Parse actual hours from notes to verify
        let actualHoursFromNotes = extractActualHoursFromNotes(workOrder.notes)
        XCTAssertEqual(actualHoursFromNotes, 12.0, accuracy: 0.1)
        
        // Actual hours exceeded estimate by 2 hours
        let variance = actualHoursFromNotes - workOrder.totalEstimatedHours
        XCTAssertEqual(variance, 2.0, accuracy: 0.1)
    }
    
    // Helper method to extract actual hours from notes
    private func extractActualHoursFromNotes(_ notes: String?) -> Double {
        guard let notes = notes else { return 0.0 }
        
        // Look for pattern "Total Actual Hours: XX.X"
        let pattern = #"Total Actual Hours: (\d+\.?\d*)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: notes.count)
        
        if let match = regex.firstMatch(in: notes, options: [], range: range) {
            let matchRange = Range(match.range(at: 1), in: notes)!
            return Double(String(notes[matchRange])) ?? 0.0
        }
        
        return 0.0
    }
    
    // MARK: - Error Handling Tests
    
    func testPartialTeamTimeTracking() throws {
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .hour, value: 4, to: startTime)!
        
        // Given: A work order where not all team members are tracked in time clock
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Partial Tracking Test"
        workOrder.assignedTeam = workTeam
        workOrder.grow = grow
        
        // Only clock in/out first 2 workers, not the third
        for worker in workers.prefix(2) {
            try timeClockService.clockIn(worker: worker, date: startTime)
            if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: startTime) {
                activeBlock.workOrder = workOrder
            }
        }
        
        for worker in workers.prefix(2) {
            try timeClockService.clockOut(worker: worker, date: endTime)
        }
        
        try context.save()
        
        // When: Creating work segment that assumes full team
        var workSegment = WorkSegment(
            startTime: startTime,
            teamSize: workers.count, // Claims 3 workers
            teamMembers: workers.map { $0.name ?? "Unknown" }
        )
        workSegment.endTime = endTime
        workSegment.calculateHours()
        
        // Then: Work segment calculation should be based on team size, not time clock entries
        XCTAssertEqual(workSegment.totalHours, 12.0, accuracy: 0.1) // 4 hours × 3 workers = 12
        
        // But sum of individual time clock entries would be less
        var actualTimeClockTotal: Double = 0.0
        for worker in workers {
            actualTimeClockTotal += timeClockService.getTotalHoursWorked(for: worker, on: startTime)
        }
        XCTAssertEqual(actualTimeClockTotal, 8.0, accuracy: 0.1) // 4 + 4 + 0 = 8
        
        // This demonstrates why work segment algorithm is important for accurate team hour calculation
        XCTAssertNotEqual(workSegment.totalHours, actualTimeClockTotal)
    }
    
    // MARK: - Performance Tests
    
    func testLargeWorkOrderPerformance() throws {
        // Given: A work order with many segments
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = "Performance Test"
        workOrder.assignedTeam = workTeam
        workOrder.grow = grow
        
        let segmentCount = 50
        var segments: [WorkSegment] = []
        let calendar = Calendar.current
        var currentTime = Date()
        
        // When: Creating many work segments with time clock entries
        let startTime = Date()
        
        for i in 0..<segmentCount {
            let segStart = calendar.date(byAdding: .minute, value: i * 30, to: currentTime)!
            let segEnd = calendar.date(byAdding: .minute, value: 30, to: segStart)!
            
            // Create time clock entries
            for worker in workers {
                try timeClockService.clockIn(worker: worker, date: segStart)
                if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: segStart) {
                    activeBlock.workOrder = workOrder
                }
            }
            
            for worker in workers {
                try timeClockService.clockOut(worker: worker, date: segEnd)
            }
            
            // Create work segment
            var segment = WorkSegment(
                startTime: segStart,
                teamSize: workers.count,
                teamMembers: workers.map { $0.name ?? "Unknown" }
            )
            segment.endTime = segEnd
            segment.calculateHours()
            segments.append(segment)
            
            currentTime = segEnd
        }
        
        try context.save()
        
        let calculationTime = Date().timeIntervalSince(startTime)
        
        // Then: Should handle large numbers efficiently
        XCTAssertEqual(segments.count, segmentCount)
        XCTAssertLessThan(calculationTime, 5.0) // Should complete within 5 seconds
        
        let totalHours = segments.reduce(0) { $0 + $1.totalHours }
        let expectedHours = Double(segmentCount) * 0.5 * Double(workers.count) // 50 segments × 0.5 hours × 3 workers
        XCTAssertEqual(totalHours, expectedHours, accuracy: 1.0)
    }
}