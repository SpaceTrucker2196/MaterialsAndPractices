//
//  MultiBlockTimeClockTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for multi-block time clock functionality.
//  Validates that workers can clock in and out multiple times per day.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class MultiBlockTimeClockTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    var timeClockService: MultiBlockTimeClockService!
    var worker: Worker!
    
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
        
        // Create test worker
        worker = Worker(context: context)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.isActive = true
        
        try context.save()
    }
    
    override func tearDownWithError() throws {
        context = nil
        timeClockService = nil
        worker = nil
    }
    
    // MARK: - Single Block Tests
    
    func testSingleTimeBlock() throws {
        let testDate = Date()
        
        // Clock in
        try timeClockService.clockIn(worker: worker, date: testDate)
        
        // Verify worker is clocked in
        XCTAssertTrue(timeClockService.isWorkerClockedIn(worker))
        
        // Verify active time block exists
        let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: testDate)
        XCTAssertNotNil(activeBlock)
        XCTAssertEqual(activeBlock?.blockNumber, 1)
        XCTAssertTrue(activeBlock?.isActive ?? false)
        
        // Clock out
        let clockOutTime = Calendar.current.date(byAdding: .hour, value: 8, to: testDate)!
        try timeClockService.clockOut(worker: worker, date: clockOutTime)
        
        // Verify worker is clocked out
        XCTAssertFalse(timeClockService.isWorkerClockedIn(worker))
        
        // Verify time block is completed
        let completedBlock = timeClockService.getActiveTimeBlock(for: worker, on: testDate)
        XCTAssertNil(completedBlock) // Should be no active block
        
        let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: testDate)
        XCTAssertEqual(timeBlocks.count, 1)
        XCTAssertFalse(timeBlocks[0].isActive)
        XCTAssertEqual(timeBlocks[0].hoursWorked, 8.0, accuracy: 0.1)
    }
    
    // MARK: - Multiple Block Tests
    
    func testMultipleTimeBlocksSameDay() throws {
        let testDate = Date()
        let calendar = Calendar.current
        
        // First time block: 7:00 AM - 10:00 AM (3 hours)
        let firstClockIn = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: testDate)!
        let firstClockOut = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: testDate)!
        
        try timeClockService.clockIn(worker: worker, date: firstClockIn)
        try timeClockService.clockOut(worker: worker, date: firstClockOut)
        
        // Second time block: 1:00 PM - 5:00 PM (4 hours) 
        let secondClockIn = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: testDate)!
        let secondClockOut = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: testDate)!
        
        try timeClockService.clockIn(worker: worker, date: secondClockIn)
        try timeClockService.clockOut(worker: worker, date: secondClockOut)
        
        // Verify two time blocks exist
        let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: testDate)
        XCTAssertEqual(timeBlocks.count, 2)
        
        // Verify block numbers
        let sortedBlocks = timeBlocks.sorted { $0.blockNumber < $1.blockNumber }
        XCTAssertEqual(sortedBlocks[0].blockNumber, 1)
        XCTAssertEqual(sortedBlocks[1].blockNumber, 2)
        
        // Verify hours worked
        XCTAssertEqual(sortedBlocks[0].hoursWorked, 3.0, accuracy: 0.1)
        XCTAssertEqual(sortedBlocks[1].hoursWorked, 4.0, accuracy: 0.1)
        
        // Verify total hours
        let totalHours = timeClockService.getTotalHoursWorked(for: worker, on: testDate)
        XCTAssertEqual(totalHours, 7.0, accuracy: 0.1)
    }
    
    func testThreeTimeBlocksSameDay() throws {
        let testDate = Date()
        let calendar = Calendar.current
        
        // Block 1: 7:00 AM - 10:00 AM (3 hours)
        try timeClockService.clockIn(worker: worker, date: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: testDate)!)
        try timeClockService.clockOut(worker: worker, date: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: testDate)!)
        
        // Block 2: 1:00 PM - 3:00 PM (2 hours)
        try timeClockService.clockIn(worker: worker, date: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: testDate)!)
        try timeClockService.clockOut(worker: worker, date: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: testDate)!)
        
        // Block 3: 7:00 PM - 9:00 PM (2 hours)
        try timeClockService.clockIn(worker: worker, date: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: testDate)!)
        try timeClockService.clockOut(worker: worker, date: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: testDate)!)
        
        // Verify three time blocks exist
        let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: testDate)
        XCTAssertEqual(timeBlocks.count, 3)
        
        // Verify block numbers are sequential
        let sortedBlocks = timeBlocks.sorted { $0.blockNumber < $1.blockNumber }
        XCTAssertEqual(sortedBlocks[0].blockNumber, 1)
        XCTAssertEqual(sortedBlocks[1].blockNumber, 2)
        XCTAssertEqual(sortedBlocks[2].blockNumber, 3)
        
        // Verify total hours (3 + 2 + 2 = 7 hours)
        let totalHours = timeClockService.getTotalHoursWorked(for: worker, on: testDate)
        XCTAssertEqual(totalHours, 7.0, accuracy: 0.1)
    }
    
    // MARK: - Error Handling Tests
    
    func testCannotClockInWhenAlreadyClockedIn() throws {
        let testDate = Date()
        
        // Clock in
        try timeClockService.clockIn(worker: worker, date: testDate)
        
        // Try to clock in again - should throw error
        XCTAssertThrowsError(try timeClockService.clockIn(worker: worker, date: testDate)) { error in
            XCTAssertTrue(error is TimeClockError)
            XCTAssertEqual(error as? TimeClockError, .alreadyClockedIn)
        }
    }
    
    func testCannotClockOutWhenNotClockedIn() throws {
        let testDate = Date()
        
        // Try to clock out without clocking in - should throw error
        XCTAssertThrowsError(try timeClockService.clockOut(worker: worker, date: testDate)) { error in
            XCTAssertTrue(error is TimeClockError)
            XCTAssertEqual(error as? TimeClockError, .notClockedIn)
        }
    }
    
    // MARK: - Active Block Tests
    
    func testActiveTimeBlockCalculation() throws {
        let testDate = Date()
        let clockInTime = Calendar.current.date(byAdding: .hour, value: -2, to: testDate)! // 2 hours ago
        
        // Clock in 2 hours ago
        try timeClockService.clockIn(worker: worker, date: clockInTime)
        
        // Get total hours (should be approximately 2 hours)
        let totalHours = timeClockService.getTotalHoursWorked(for: worker, on: testDate)
        XCTAssertEqual(totalHours, 2.0, accuracy: 0.2) // Allow some margin for test execution time
    }
    
    // MARK: - Different Days Tests
    
    func testTimeBlocksSeparatedByDay() throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Create time block for yesterday
        try timeClockService.clockIn(worker: worker, date: yesterday)
        try timeClockService.clockOut(worker: worker, date: calendar.date(byAdding: .hour, value: 8, to: yesterday)!)
        
        // Create time block for today
        try timeClockService.clockIn(worker: worker, date: today)
        try timeClockService.clockOut(worker: worker, date: calendar.date(byAdding: .hour, value: 6, to: today)!)
        
        // Verify yesterday has 1 block
        let yesterdayBlocks = timeClockService.getTimeBlocks(for: worker, on: yesterday)
        XCTAssertEqual(yesterdayBlocks.count, 1)
        XCTAssertEqual(yesterdayBlocks[0].blockNumber, 1)
        
        // Verify today has 1 block  
        let todayBlocks = timeClockService.getTimeBlocks(for: worker, on: today)
        XCTAssertEqual(todayBlocks.count, 1)
        XCTAssertEqual(todayBlocks[0].blockNumber, 1) // Block numbers reset each day
        
        // Verify hours are calculated correctly for each day
        XCTAssertEqual(timeClockService.getTotalHoursWorked(for: worker, on: yesterday), 8.0, accuracy: 0.1)
        XCTAssertEqual(timeClockService.getTotalHoursWorked(for: worker, on: today), 6.0, accuracy: 0.1)
    }
    
    // MARK: - TimeClock Extension Tests
    
    func testTimeBlockFormatting() throws {
        let testDate = Date()
        let calendar = Calendar.current
        
        let clockInTime = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: testDate)!
        let clockOutTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: testDate)!
        
        try timeClockService.clockIn(worker: worker, date: clockInTime)
        try timeClockService.clockOut(worker: worker, date: clockOutTime)
        
        let timeBlocks = timeClockService.getTimeBlocks(for: worker, on: testDate)
        XCTAssertEqual(timeBlocks.count, 1)
        
        let block = timeBlocks[0]
        
        // Test formatted time block string
        let formattedBlock = block.formattedTimeBlock
        XCTAssertTrue(formattedBlock.contains("Block 1"))
        XCTAssertTrue(formattedBlock.contains("9:30"))
        XCTAssertTrue(formattedBlock.contains("5:00"))
        
        // Test formatted duration
        let formattedDuration = block.formattedDuration
        XCTAssertTrue(formattedDuration.contains("7.5 hours"))
    }
}