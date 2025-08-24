//
//  TimeClockTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for the worker time clock system functionality.
//  Validates time tracking, weekly calculations, and Monday-Sunday work week logic.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class TimeClockTests: XCTestCase {
    
    var mockPersistenceController: PersistenceController!
    var mockContext: NSManagedObjectContext!
    var testWorker: Worker!
    
    override func setUpWithError() throws {
        mockPersistenceController = PersistenceController(inMemory: true)
        mockContext = mockPersistenceController.container.viewContext
        
        // Create test worker
        testWorker = Worker(context: mockContext)
        testWorker.id = UUID()
        testWorker.name = "Test Worker"
        testWorker.isActive = true
        
        try mockContext.save()
    }
    
    override func tearDownWithError() throws {
        mockPersistenceController = nil
        mockContext = nil
        testWorker = nil
    }
    
    // MARK: - Basic Time Clock Tests
    
    func testCreateTimeClockEntry() throws {
        // Given: A new time clock entry
        let timeClock = TimeClock(context: mockContext)
        timeClock.id = UUID()
        timeClock.worker = testWorker
        timeClock.date = Date()
        timeClock.isActive = true
        
        // When: Saving the entry
        try mockContext.save()
        
        // Then: Entry should be created with correct relationships
        XCTAssertNotNil(timeClock.id, "Time clock entry should have an ID")
        XCTAssertEqual(timeClock.worker, testWorker, "Time clock should be associated with worker")
        XCTAssertTrue(timeClock.isActive, "New entry should be active (clocked in)")
    }
    
    func testClockInClockOut() throws {
        // Given: A time clock entry
        let timeClock = TimeClock(context: mockContext)
        timeClock.id = UUID()
        timeClock.worker = testWorker
        timeClock.date = Calendar.current.startOfDay(for: Date())
        
        let clockInTime = Date()
        timeClock.clockInTime = clockInTime
        timeClock.isActive = true
        
        // When: Clocking out after 8 hours
        let clockOutTime = Calendar.current.date(byAdding: .hour, value: 8, to: clockInTime)!
        timeClock.clockOutTime = clockOutTime
        timeClock.isActive = false
        
        // Calculate hours worked
        let interval = clockOutTime.timeIntervalSince(clockInTime)
        timeClock.hoursWorked = interval / 3600
        
        try mockContext.save()
        
        // Then: Hours should be calculated correctly
        XCTAssertEqual(timeClock.hoursWorked, 8.0, accuracy: 0.1, "Should calculate 8 hours worked")
        XCTAssertFalse(timeClock.isActive, "Should be clocked out")
        XCTAssertNotNil(timeClock.clockOutTime, "Should have clock out time")
    }
    
    // MARK: - Weekly Hours Calculation Tests
    
    func testWeeklyHoursCalculation() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Get Monday of current week
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: now))!
        
        // Given: Multiple time clock entries across the week
        var totalExpectedHours: Double = 0
        
        // Monday - 8 hours
        let mondayEntry = createTimeEntry(date: monday, hours: 8.0)
        totalExpectedHours += 8.0
        
        // Tuesday - 7.5 hours
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let tuesdayEntry = createTimeEntry(date: tuesday, hours: 7.5)
        totalExpectedHours += 7.5
        
        // Wednesday - 8.5 hours
        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!
        let wednesdayEntry = createTimeEntry(date: wednesday, hours: 8.5)
        totalExpectedHours += 8.5
        
        // Thursday - 8 hours
        let thursday = calendar.date(byAdding: .day, value: 3, to: monday)!
        let thursdayEntry = createTimeEntry(date: thursday, hours: 8.0)
        totalExpectedHours += 8.0
        
        // Friday - 6 hours
        let friday = calendar.date(byAdding: .day, value: 4, to: monday)!
        let fridayEntry = createTimeEntry(date: friday, hours: 6.0)
        totalExpectedHours += 6.0
        
        try mockContext.save()
        
        // When: Calculating weekly hours
        let weeklyHours = calculateWeeklyHours(for: testWorker, weekStarting: monday)
        
        // Then: Should total correctly
        XCTAssertEqual(weeklyHours, totalExpectedHours, accuracy: 0.1, 
                      "Weekly hours should total \(totalExpectedHours)")
        XCTAssertEqual(weeklyHours, 38.0, accuracy: 0.1, 
                      "Specific test case should equal 38 hours")
    }
    
    func testOvertimeDetection() throws {
        let calendar = Calendar.current
        let now = Date()
        let monday = getMondayOfWeek(containing: now)
        
        // Given: Overtime hours (over 40)
        var totalHours: Double = 0
        
        // Create 5 days of 8.5 hours each (42.5 total)
        for dayOffset in 0..<5 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: monday)!
            _ = createTimeEntry(date: date, hours: 8.5)
            totalHours += 8.5
        }
        
        try mockContext.save()
        
        // When: Calculating weekly hours
        let weeklyHours = calculateWeeklyHours(for: testWorker, weekStarting: monday)
        
        // Then: Should detect overtime
        XCTAssertEqual(weeklyHours, 42.5, accuracy: 0.1, "Should calculate correct total hours")
        XCTAssertGreaterThan(weeklyHours, 40.0, "Should detect overtime hours")
        
        let overtimeHours = weeklyHours - 40.0
        XCTAssertEqual(overtimeHours, 2.5, accuracy: 0.1, "Should calculate 2.5 overtime hours")
    }
    
    func testWeekBoundaryCalculation() throws {
        let calendar = Calendar.current
        let now = Date()
        let monday = getMondayOfWeek(containing: now)
        
        // Given: Entries on Sunday (end of week) and Monday (start of new week)
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday)!
        
        _ = createTimeEntry(date: sunday, hours: 8.0)
        _ = createTimeEntry(date: nextMonday, hours: 8.0)
        
        try mockContext.save()
        
        // When: Calculating hours for each week
        let thisWeekHours = calculateWeeklyHours(for: testWorker, weekStarting: monday)
        let nextWeekHours = calculateWeeklyHours(for: testWorker, weekStarting: nextMonday)
        
        // Then: Should separate weeks correctly
        XCTAssertEqual(thisWeekHours, 8.0, accuracy: 0.1, "This week should have 8 hours (Sunday)")
        XCTAssertEqual(nextWeekHours, 8.0, accuracy: 0.1, "Next week should have 8 hours (Monday)")
    }
    
    func testYearAndWeekNumberTracking() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Given: A time entry
        let timeClock = createTimeEntry(date: now, hours: 8.0)
        
        // When: Setting year and week number
        timeClock.year = Int16(calendar.component(.yearForWeekOfYear, from: now))
        timeClock.weekNumber = Int16(calendar.component(.weekOfYear, from: now))
        
        try mockContext.save()
        
        // Then: Should track year and week correctly
        let expectedYear = calendar.component(.yearForWeekOfYear, from: now)
        let expectedWeek = calendar.component(.weekOfYear, from: now)
        
        XCTAssertEqual(Int(timeClock.year), expectedYear, "Should track correct year")
        XCTAssertEqual(Int(timeClock.weekNumber), expectedWeek, "Should track correct week number")
    }
    
    // MARK: - Edge Cases Tests
    
    func testMultipleWorkersTimeTracking() throws {
        // Given: Multiple workers
        let worker2 = Worker(context: mockContext)
        worker2.id = UUID()
        worker2.name = "Second Worker"
        worker2.isActive = true
        
        let now = Date()
        let monday = getMondayOfWeek(containing: now)
        
        // When: Adding time entries for different workers
        _ = createTimeEntry(date: monday, hours: 8.0, worker: testWorker)
        _ = createTimeEntry(date: monday, hours: 6.0, worker: worker2)
        
        try mockContext.save()
        
        // Then: Should track hours separately
        let worker1Hours = calculateWeeklyHours(for: testWorker, weekStarting: monday)
        let worker2Hours = calculateWeeklyHours(for: worker2, weekStarting: monday)
        
        XCTAssertEqual(worker1Hours, 8.0, accuracy: 0.1, "Worker 1 should have 8 hours")
        XCTAssertEqual(worker2Hours, 6.0, accuracy: 0.1, "Worker 2 should have 6 hours")
    }
    
    func testIncompleteTimeEntry() throws {
        // Given: A time entry without clock out (still active)
        let timeClock = TimeClock(context: mockContext)
        timeClock.id = UUID()
        timeClock.worker = testWorker
        timeClock.date = Calendar.current.startOfDay(for: Date())
        timeClock.clockInTime = Date()
        timeClock.isActive = true
        timeClock.hoursWorked = 0.0 // No hours calculated yet
        
        try mockContext.save()
        
        // When: Calculating weekly hours
        let monday = getMondayOfWeek(containing: Date())
        let weeklyHours = calculateWeeklyHours(for: testWorker, weekStarting: monday)
        
        // Then: Should not count incomplete entries
        XCTAssertEqual(weeklyHours, 0.0, accuracy: 0.1, 
                      "Incomplete entries should not contribute to weekly hours")
    }
    
    // MARK: - Helper Methods
    
    @discardableResult
    private func createTimeEntry(date: Date, hours: Double, worker: Worker? = nil) -> TimeClock {
        let timeClock = TimeClock(context: mockContext)
        timeClock.id = UUID()
        timeClock.worker = worker ?? testWorker
        timeClock.date = Calendar.current.startOfDay(for: date)
        timeClock.hoursWorked = hours
        timeClock.isActive = false // Completed entry
        
        // Set clock in/out times based on hours
        let clockInTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        timeClock.clockInTime = clockInTime
        timeClock.clockOutTime = Calendar.current.date(byAdding: .hour, value: Int(hours), to: clockInTime)
        
        return timeClock
    }
    
    private func calculateWeeklyHours(for worker: Worker, weekStarting monday: Date) -> Double {
        let calendar = Calendar.current
        let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday)!
        
        guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else {
            return 0.0
        }
        
        return timeEntries
            .filter { entry in
                guard let entryDate = entry.date else { return false }
                return entryDate >= monday && entryDate < nextMonday
            }
            .reduce(0) { $0 + $1.hoursWorked }
    }
    
    private func getMondayOfWeek(containing date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: date))!
    }
}