//
//  WorkSegmentTests.swift
//  MaterialsAndPracticesTests
//
//  Comprehensive tests for WorkSegment functionality including team tracking,
//  time calculations, and work order integration.
//  
//  Tests the critical algorithm for team-multiplied time tracking.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class WorkSegmentTests: XCTestCase {
    
    var context: NSManagedObjectContext!
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
        for i in 1...5 {
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
        for worker in workers.prefix(3) { // First 3 workers
            workTeam.addToMembers(worker)
        }
        
        workOrder.assignedTeam = workTeam
        
        try context.save()
    }
    
    override func tearDownWithError() throws {
        context = nil
        grow = nil
        workOrder = nil
        workTeam = nil
        workers = []
    }
    
    // MARK: - WorkSegment Structure Tests
    
    func testWorkSegmentCreation() throws {
        // Given: Initial parameters for a work segment
        let startTime = Date()
        let teamSize = 3
        let teamMembers = ["Worker 1", "Worker 2", "Worker 3"]
        
        // When: Creating a work segment
        let segment = WorkSegment(
            startTime: startTime,
            teamSize: teamSize,
            teamMembers: teamMembers
        )
        
        // Then: Should have correct initial values
        XCTAssertEqual(segment.startTime, startTime)
        XCTAssertNil(segment.endTime)
        XCTAssertEqual(segment.teamSize, 3)
        XCTAssertEqual(segment.teamMembers.count, 3)
        XCTAssertEqual(segment.teamMembers, teamMembers)
        XCTAssertEqual(segment.totalHours, 0.0)
        XCTAssertTrue(segment.isActive)
    }
    
    func testWorkSegmentActiveState() throws {
        // Given: A work segment
        var segment = WorkSegment(
            startTime: Date(),
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3"]
        )
        
        // When: Initially created
        // Then: Should be active
        XCTAssertTrue(segment.isActive)
        XCTAssertNil(segment.endTime)
        
        // When: End time is set
        segment.endTime = Date()
        
        // Then: Should not be active
        XCTAssertFalse(segment.isActive)
        XCTAssertNotNil(segment.endTime)
    }
    
    // MARK: - Team Multiplier Algorithm Tests
    
    func testTeamMultiplierCalculation() throws {
        // Given: A work segment with 3 team members working for 2 hours
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime)!
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3"]
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should multiply duration by team size (2 hours × 3 workers = 6 total hours)
        XCTAssertEqual(segment.totalHours, 6.0, accuracy: 0.1)
    }
    
    func testSingleWorkerHours() throws {
        // Given: A work segment with 1 team member working for 8 hours
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 8, to: startTime)!
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 1,
            teamMembers: ["Worker 1"]
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should equal actual work time (8 hours × 1 worker = 8 total hours)
        XCTAssertEqual(segment.totalHours, 8.0, accuracy: 0.1)
    }
    
    func testLargeTeamMultiplier() throws {
        // Given: A work segment with 5 team members working for 4 hours
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 4, to: startTime)!
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 5,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3", "Worker 4", "Worker 5"]
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should multiply correctly (4 hours × 5 workers = 20 total hours)
        XCTAssertEqual(segment.totalHours, 20.0, accuracy: 0.1)
    }
    
    func testPartialHourCalculation() throws {
        // Given: A work segment with 2 team members working for 1.5 hours
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: 90, to: startTime)! // 1.5 hours
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 2,
            teamMembers: ["Worker 1", "Worker 2"]
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should handle fractional hours (1.5 hours × 2 workers = 3.0 total hours)
        XCTAssertEqual(segment.totalHours, 3.0, accuracy: 0.1)
    }
    
    func testCalculateHoursWithoutEndTime() throws {
        // Given: A work segment without an end time
        var segment = WorkSegment(
            startTime: Date(),
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3"]
        )
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should remain 0 (cannot calculate without end time)
        XCTAssertEqual(segment.totalHours, 0.0)
    }
    
    // MARK: - Multiple Work Segments Tests
    
    func testMultipleWorkSegments() throws {
        // Given: Multiple work segments for a single work order
        let segments = createMultipleWorkSegments()
        
        // When: Calculating total hours across all segments
        let totalHours = segments.reduce(0) { $0 + $1.totalHours }
        
        // Then: Should sum all segment hours correctly
        // Segment 1: 3 workers × 2 hours = 6 hours
        // Segment 2: 2 workers × 3 hours = 6 hours  
        // Segment 3: 4 workers × 1 hour = 4 hours
        // Total: 16 hours
        XCTAssertEqual(totalHours, 16.0, accuracy: 0.1)
    }
    
    func testTeamChangeDetection() throws {
        // Given: Initial work segment with 3 workers
        let segment1 = WorkSegment(
            startTime: Date(),
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3"]
        )
        
        // When: Team composition changes (different member count)
        let segment2 = WorkSegment(
            startTime: Date(),
            teamSize: 2,
            teamMembers: ["Worker 1", "Worker 2"]
        )
        
        // Then: Should detect team change
        XCTAssertNotEqual(segment1.teamSize, segment2.teamSize)
        XCTAssertNotEqual(segment1.teamMembers, segment2.teamMembers)
    }
    
    func testTeamMemberChangeDetection() throws {
        // Given: Initial work segment
        let segment1 = WorkSegment(
            startTime: Date(),
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3"]
        )
        
        // When: Same team size but different members
        let segment2 = WorkSegment(
            startTime: Date(),
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 4"] // Worker 3 replaced by Worker 4
        )
        
        // Then: Should detect member change
        XCTAssertEqual(segment1.teamSize, segment2.teamSize)
        XCTAssertNotEqual(segment1.teamMembers, segment2.teamMembers)
        XCTAssertTrue(segment2.teamMembers.contains("Worker 4"))
        XCTAssertFalse(segment2.teamMembers.contains("Worker 3"))
    }
    
    // MARK: - Time Accuracy Tests
    
    func testLongDurationAccuracy() throws {
        // Given: A work segment spanning multiple days
        let calendar = Calendar.current
        let startTime = Date()
        let endTime = calendar.date(byAdding: .day, value: 2, to: startTime)! // 48 hours
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 2,
            teamMembers: ["Worker 1", "Worker 2"]
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should handle long durations correctly (48 hours × 2 workers = 96 total hours)
        XCTAssertEqual(segment.totalHours, 96.0, accuracy: 0.1)
    }
    
    func testShortDurationAccuracy() throws {
        // Given: A work segment spanning only minutes
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime)! // 0.5 hours
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 4,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3", "Worker 4"]
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should handle short durations accurately (0.5 hours × 4 workers = 2.0 total hours)
        XCTAssertEqual(segment.totalHours, 2.0, accuracy: 0.1)
    }
    
    // MARK: - Work Order Integration Tests
    
    func testWorkOrderWithWorkSegments() throws {
        // Given: A work order with multiple work segments
        let segments = createMultipleWorkSegments()
        
        // When: Simulating work order completion with these segments
        let totalWorkOrderHours = segments.reduce(0) { $0 + $1.totalHours }
        
        // Update work order with total hours (stored in notes since totalActualHours doesn't exist)
        let hoursInfo = "Total Hours: \(String(format: "%.1f", totalWorkOrderHours))"
        workOrder.notes = hoursInfo
        workOrder.isCompleted = true
        workOrder.completedDate = Date()

        try context.save()

        // Then: Work order should reflect completion
        XCTAssertTrue(workOrder.isCompleted)
        XCTAssertNotNil(workOrder.completedDate)
        XCTAssertTrue(workOrder.notes?.contains("16.0") ?? false) // Should contain total hours
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testZeroTeamSize() throws {
        // Given: A work segment with zero team size (edge case)
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: 8, to: startTime)!
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 0,
            teamMembers: []
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should result in zero hours (8 hours × 0 workers = 0 total hours)
        XCTAssertEqual(segment.totalHours, 0.0)
    }
    
    func testNegativeTimeInterval() throws {
        // Given: A work segment with end time before start time (error case)
        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: -2, to: startTime)! // 2 hours before start
        
        var segment = WorkSegment(
            startTime: startTime,
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3"]
        )
        segment.endTime = endTime
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should handle negative interval gracefully (may result in negative hours)
        // This tests the robustness of the algorithm
        XCTAssertLessThan(segment.totalHours, 0.0)
    }
    
    func testMismatchedTeamSizeAndMembers() throws {
        // Given: A work segment where team size doesn't match member count
        var segment = WorkSegment(
            startTime: Date(),
            teamSize: 5, // Says 5 workers
            teamMembers: ["Worker 1", "Worker 2"] // But only 2 names provided
        )
        segment.endTime = Calendar.current.date(byAdding: .hour, value: 4, to: segment.startTime)
        
        // When: Calculating hours
        segment.calculateHours()
        
        // Then: Should use teamSize for calculation (algorithm specification)
        // 4 hours × 5 workers = 20 total hours (not 4 × 2 = 8)
        XCTAssertEqual(segment.totalHours, 20.0, accuracy: 0.1)
    }
    
    // MARK: - Performance Tests
    
    func testLargeNumberOfSegments() throws {
        // Given: A large number of work segments
        let segmentCount = 1000
        var segments: [WorkSegment] = []
        
        let startTime = Date()
        
        // When: Creating many segments
        for i in 0..<segmentCount {
            let segmentStart = Calendar.current.date(byAdding: .minute, value: i * 30, to: startTime)!
            let segmentEnd = Calendar.current.date(byAdding: .minute, value: 30, to: segmentStart)!
            
            var segment = WorkSegment(
                startTime: segmentStart,
                teamSize: (i % 5) + 1, // Team size 1-5
                teamMembers: ["Worker \(i % 3 + 1)"] // Cycle through workers
            )
            segment.endTime = segmentEnd
            segment.calculateHours()
            
            segments.append(segment)
        }
        
        // Then: Should handle large numbers efficiently
        XCTAssertEqual(segments.count, segmentCount)
        
        let totalHours = segments.reduce(0) { $0 + $1.totalHours }
        XCTAssertGreaterThan(totalHours, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createMultipleWorkSegments() -> [WorkSegment] {
        let calendar = Calendar.current
        var segments: [WorkSegment] = []
        
        // Segment 1: 3 workers for 2 hours
        let start1 = Date()
        let end1 = calendar.date(byAdding: .hour, value: 2, to: start1)!
        var segment1 = WorkSegment(
            startTime: start1,
            teamSize: 3,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3"]
        )
        segment1.endTime = end1
        segment1.calculateHours()
        segments.append(segment1)
        
        // Segment 2: 2 workers for 3 hours (team change)
        let start2 = calendar.date(byAdding: .hour, value: 1, to: end1)! // 1 hour break
        let end2 = calendar.date(byAdding: .hour, value: 3, to: start2)!
        var segment2 = WorkSegment(
            startTime: start2,
            teamSize: 2,
            teamMembers: ["Worker 1", "Worker 4"]
        )
        segment2.endTime = end2
        segment2.calculateHours()
        segments.append(segment2)
        
        // Segment 3: 4 workers for 1 hour (team change)
        let start3 = calendar.date(byAdding: .minute, value: 30, to: end2)! // 30 minute break
        let end3 = calendar.date(byAdding: .hour, value: 1, to: start3)!
        var segment3 = WorkSegment(
            startTime: start3,
            teamSize: 4,
            teamMembers: ["Worker 1", "Worker 2", "Worker 3", "Worker 5"]
        )
        segment3.endTime = end3
        segment3.calculateHours()
        segments.append(segment3)
        
        return segments
    }
}