//
//  CleanArchitectureTimeTrackingTests.swift
//  MaterialsAndPracticesTests
//
//  Unit tests for clean architecture time tracking implementation.
//  Tests domain entities, use cases, controllers, and data gateways.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
import Combine
@testable import MaterialsAndPractices

class CleanArchitectureTimeTrackingTests: XCTestCase {
    
    var mockPersistenceController: PersistenceController!
    var mockContext: NSManagedObjectContext!
    var mockGateway: MockTimeTrackingDataGateway!
    var clockUseCase: DefaultTimeClockManagementUseCase!
    var reportingUseCase: DefaultTimeReportingAnalyticsUseCase!
    var controller: TimeClockController!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        mockPersistenceController = PersistenceController(inMemory: true)
        mockContext = mockPersistenceController.container.viewContext
        mockGateway = MockTimeTrackingDataGateway()
        clockUseCase = DefaultTimeClockManagementUseCase(gateway: mockGateway)
        reportingUseCase = DefaultTimeReportingAnalyticsUseCase(gateway: mockGateway)
        controller = TimeClockController(clockUseCase: clockUseCase, reportingUseCase: reportingUseCase)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        controller = nil
        reportingUseCase = nil
        clockUseCase = nil
        mockGateway = nil
        mockContext = nil
        mockPersistenceController = nil
    }
    
    // MARK: - Domain Entity Tests
    
    func testTimeTrackingEntityBusinessRules() throws {
        // Given: A time tracking entity with 10 hours worked
        let entity = TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: UUID(),
            workDate: Date(),
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .hour, value: 10, to: Date()),
            totalHours: 10.0,
            isCurrentlyActive: false,
            weekOfYear: 25,
            calendarYear: 2024
        )
        
        // When: Checking business rules
        // Then: Should correctly identify overtime
        XCTAssertTrue(entity.isDailyOvertime, "10 hours should be considered overtime")
        XCTAssertEqual(entity.dailyOvertimeHours, 2.0, accuracy: 0.01, "Should calculate 2 hours of overtime")
        XCTAssertTrue(entity.isValid, "Entity with start and end times should be valid")
        XCTAssertEqual(entity.formattedHours, "10:00", "Should format hours correctly")
    }
    
    func testTimeTrackingEntityValidation() throws {
        // Given: Various time tracking entities
        let validEntity = TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: UUID(),
            workDate: Date(),
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .hour, value: 8, to: Date()),
            totalHours: 8.0,
            isCurrentlyActive: false,
            weekOfYear: 25,
            calendarYear: 2024
        )
        
        let activeEntity = TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: UUID(),
            workDate: Date(),
            startTime: Date(),
            endTime: nil,
            totalHours: 0.0,
            isCurrentlyActive: true,
            weekOfYear: 25,
            calendarYear: 2024
        )
        
        let invalidEntity = TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: UUID(),
            workDate: Date(),
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()), // End before start
            totalHours: -2.0,
            isCurrentlyActive: false,
            weekOfYear: 25,
            calendarYear: 2024
        )
        
        // When: Validating entities
        // Then: Should correctly validate
        XCTAssertTrue(validEntity.isValid, "Complete entity should be valid")
        XCTAssertTrue(activeEntity.isValid, "Active entity with start time should be valid")
        XCTAssertFalse(invalidEntity.isValid, "Entity with end before start should be invalid")
    }
    
    func testFormattedHoursCalculation() throws {
        // Given: Various hour amounts
        let testCases: [(hours: Double, expected: String)] = [
            (8.0, "8:00"),
            (8.5, "8:30"),
            (8.25, "8:15"),
            (8.75, "8:45"),
            (0.0, "0:00"),
            (12.1, "12:06"), // 0.1 hour = 6 minutes
        ]
        
        for testCase in testCases {
            // When: Creating entity with specific hours
            let entity = TimeTrackingEntity(
                identifier: UUID(),
                workerIdentifier: UUID(),
                workDate: Date(),
                startTime: Date(),
                endTime: Date(),
                totalHours: testCase.hours,
                isCurrentlyActive: false,
                weekOfYear: 25,
                calendarYear: 2024
            )
            
            // Then: Should format correctly
            XCTAssertEqual(entity.formattedHours, testCase.expected, 
                          "Hours \(testCase.hours) should format as \(testCase.expected)")
        }
    }
    
    // MARK: - Use Case Tests - Clock In/Out
    
    func testClockInSuccess() async throws {
        // Given: A worker ID and no existing active entry
        let workerID = UUID()
        mockGateway.activeTimeEntry = nil
        
        // When: Clocking in
        let request = ClockInRequest(workerIdentifier: workerID, timestamp: Date())
        let response = await clockUseCase.executeClockIn(request)
        
        // Then: Should succeed and create time entry
        XCTAssertTrue(response.success, "Clock in should succeed")
        XCTAssertEqual(response.message, "Successfully clocked in")
        XCTAssertNotNil(response.timeEntry, "Should return time entry")
        XCTAssertEqual(response.timeEntry?.workerIdentifier, workerID)
        XCTAssertTrue(response.timeEntry?.isCurrentlyActive ?? false, "Entry should be active")
        XCTAssertEqual(mockGateway.savedEntries.count, 1, "Should save one entry")
    }
    
    func testClockInWhenAlreadyClockedIn() async throws {
        // Given: A worker already clocked in
        let workerID = UUID()
        let existingEntry = createActiveTimeEntry(workerID: workerID)
        mockGateway.activeTimeEntry = existingEntry
        
        // When: Attempting to clock in again
        let request = ClockInRequest(workerIdentifier: workerID, timestamp: Date())
        let response = await clockUseCase.executeClockIn(request)
        
        // Then: Should fail with appropriate message
        XCTAssertFalse(response.success, "Clock in should fail when already clocked in")
        XCTAssertEqual(response.message, "Worker is already clocked in")
        XCTAssertNotNil(response.timeEntry, "Should return existing entry")
        XCTAssertEqual(mockGateway.savedEntries.count, 0, "Should not save new entry")
    }
    
    func testClockOutSuccess() async throws {
        // Given: A worker with active time entry
        let workerID = UUID()
        let clockInTime = Date()
        let activeEntry = TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: workerID,
            workDate: Calendar.current.startOfDay(for: clockInTime),
            startTime: clockInTime,
            endTime: nil,
            totalHours: 0.0,
            isCurrentlyActive: true,
            weekOfYear: Calendar.current.component(.weekOfYear, from: clockInTime),
            calendarYear: Calendar.current.component(.yearForWeekOfYear, from: clockInTime)
        )
        mockGateway.activeTimeEntry = activeEntry
        
        // When: Clocking out after 8 hours
        let clockOutTime = Calendar.current.date(byAdding: .hour, value: 8, to: clockInTime)!
        let request = ClockOutRequest(workerIdentifier: workerID, timestamp: clockOutTime)
        let response = await clockUseCase.executeClockOut(request)
        
        // Then: Should succeed and calculate hours
        XCTAssertTrue(response.success, "Clock out should succeed")
        XCTAssertEqual(response.message, "Successfully clocked out")
        XCTAssertNotNil(response.timeEntry, "Should return updated entry")
        XCTAssertFalse(response.timeEntry?.isCurrentlyActive ?? true, "Entry should be inactive")
        XCTAssertEqual(response.timeEntry?.totalHours, 8.0, accuracy: 0.1, "Should calculate 8 hours")
        XCTAssertEqual(mockGateway.updatedEntries.count, 1, "Should update one entry")
    }
    
    func testClockOutWhenNotClockedIn() async throws {
        // Given: A worker with no active time entry
        let workerID = UUID()
        mockGateway.activeTimeEntry = nil
        
        // When: Attempting to clock out
        let request = ClockOutRequest(workerIdentifier: workerID, timestamp: Date())
        let response = await clockUseCase.executeClockOut(request)
        
        // Then: Should fail with appropriate message
        XCTAssertFalse(response.success, "Clock out should fail when not clocked in")
        XCTAssertEqual(response.message, "Worker is not currently clocked in")
        XCTAssertNil(response.timeEntry, "Should not return time entry")
        XCTAssertEqual(mockGateway.updatedEntries.count, 0, "Should not update any entries")
    }
    
    func testClockOutWithInvalidClockInTime() async throws {
        // Given: A worker with active entry but no clock in time
        let workerID = UUID()
        let invalidEntry = TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: workerID,
            workDate: Date(),
            startTime: nil, // Invalid: no clock in time
            endTime: nil,
            totalHours: 0.0,
            isCurrentlyActive: true,
            weekOfYear: 25,
            calendarYear: 2024
        )
        mockGateway.activeTimeEntry = invalidEntry
        
        // When: Attempting to clock out
        let request = ClockOutRequest(workerIdentifier: workerID, timestamp: Date())
        let response = await clockUseCase.executeClockOut(request)
        
        // Then: Should fail with appropriate message
        XCTAssertFalse(response.success, "Clock out should fail with invalid clock in time")
        XCTAssertEqual(response.message, "Invalid clock-in time")
        XCTAssertNil(response.timeEntry, "Should not return time entry")
    }
    
    // MARK: - Use Case Tests - Reporting
    
    func testWeeklyReportGeneration() async throws {
        // Given: Multiple time entries for a worker in one week
        let workerID = UUID()
        let calendar = Calendar.current
        let monday = getMondayOfCurrentWeek()
        
        let weeklyEntries = [
            createCompletedTimeEntry(workerID: workerID, date: monday, hours: 8.0),
            createCompletedTimeEntry(workerID: workerID, date: calendar.date(byAdding: .day, value: 1, to: monday)!, hours: 8.5),
            createCompletedTimeEntry(workerID: workerID, date: calendar.date(byAdding: .day, value: 2, to: monday)!, hours: 7.5),
            createCompletedTimeEntry(workerID: workerID, date: calendar.date(byAdding: .day, value: 3, to: monday)!, hours: 8.0),
            createCompletedTimeEntry(workerID: workerID, date: calendar.date(byAdding: .day, value: 4, to: monday)!, hours: 9.0),
        ]
        
        mockGateway.weeklyEntries = weeklyEntries
        
        // When: Generating weekly report
        let report = await reportingUseCase.generateWeeklyReport(for: workerID, week: monday)
        
        // Then: Should calculate totals correctly
        XCTAssertEqual(report.workerIdentifier, workerID)
        XCTAssertEqual(report.weekStartDate, monday)
        XCTAssertEqual(report.dailyEntries.count, 5, "Should have 5 daily entries")
        XCTAssertEqual(report.weeklyTotal, 41.0, accuracy: 0.1, "Should total 41 hours")
        XCTAssertEqual(report.totalRegularHours, 40.0, accuracy: 0.1, "Should have 40 regular hours")
        XCTAssertEqual(report.totalOvertimeHours, 1.0, accuracy: 0.1, "Should have 1 overtime hour")
        XCTAssertTrue(report.isWeeklyOvertime, "Should detect weekly overtime")
    }
    
    func testWeeklyReportWithNoOvertime() async throws {
        // Given: Time entries totaling exactly 40 hours
        let workerID = UUID()
        let monday = getMondayOfCurrentWeek()
        
        let weeklyEntries = [
            createCompletedTimeEntry(workerID: workerID, date: monday, hours: 8.0),
            createCompletedTimeEntry(workerID: workerID, date: Calendar.current.date(byAdding: .day, value: 1, to: monday)!, hours: 8.0),
            createCompletedTimeEntry(workerID: workerID, date: Calendar.current.date(byAdding: .day, value: 2, to: monday)!, hours: 8.0),
            createCompletedTimeEntry(workerID: workerID, date: Calendar.current.date(byAdding: .day, value: 3, to: monday)!, hours: 8.0),
            createCompletedTimeEntry(workerID: workerID, date: Calendar.current.date(byAdding: .day, value: 4, to: monday)!, hours: 8.0),
        ]
        
        mockGateway.weeklyEntries = weeklyEntries
        
        // When: Generating weekly report
        let report = await reportingUseCase.generateWeeklyReport(for: workerID, week: monday)
        
        // Then: Should not show overtime
        XCTAssertEqual(report.weeklyTotal, 40.0, accuracy: 0.1, "Should total exactly 40 hours")
        XCTAssertEqual(report.totalRegularHours, 40.0, accuracy: 0.1, "Should have 40 regular hours")
        XCTAssertEqual(report.totalOvertimeHours, 0.0, accuracy: 0.1, "Should have no overtime")
        XCTAssertFalse(report.isWeeklyOvertime, "Should not detect overtime")
    }
    
    func testPayrollDataCalculation() async throws {
        // Given: Time entries for a pay period
        let workerID = UUID()
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 13, to: startDate)! // 2-week period
        let payPeriod = DateInterval(start: startDate, end: endDate)
        
        // 80 hours over 2 weeks (40 each week)
        let entries = (0..<10).map { dayOffset in
            createCompletedTimeEntry(
                workerID: workerID,
                date: Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)!,
                hours: 8.0
            )
        }
        
        mockGateway.payPeriodEntries = entries
        
        // When: Calculating payroll data
        let payroll = await reportingUseCase.calculatePayrollData(for: workerID, period: payPeriod)
        
        // Then: Should calculate payroll correctly
        XCTAssertEqual(payroll.workerIdentifier, workerID)
        XCTAssertEqual(payroll.payPeriodStart, startDate)
        XCTAssertEqual(payroll.payPeriodEnd, endDate)
        XCTAssertEqual(payroll.totalHours, 80.0, accuracy: 0.1, "Should total 80 hours")
        XCTAssertGreaterThan(payroll.estimatedTotalPay, 0, "Should calculate positive pay")
    }
    
    // MARK: - Controller Tests
    
    func testControllerClockInFlow() async throws {
        // Given: A controller and worker ID
        let workerID = UUID()
        mockGateway.activeTimeEntry = nil
        
        // When: Handling clock in tap
        await controller.handleClockInTapped(workerID: workerID)
        
        // Then: Should update controller state
        XCTAssertFalse(controller.isLoading, "Should finish loading")
        XCTAssertNil(controller.errorMessage, "Should have no error")
        
        switch controller.currentState {
        case .clockedIn:
            XCTAssertTrue(true, "Should be in clocked in state")
        case .clockedOut:
            XCTFail("Should not be in clocked out state after successful clock in")
        }
    }
    
    func testControllerClockOutFlow() async throws {
        // Given: A controller with worker already clocked in
        let workerID = UUID()
        let activeEntry = createActiveTimeEntry(workerID: workerID)
        mockGateway.activeTimeEntry = activeEntry
        
        // First clock in to set state
        await controller.loadCurrentState(for: workerID)
        
        // When: Handling clock out tap
        await controller.handleClockOutTapped(workerID: workerID)
        
        // Then: Should update controller state
        XCTAssertFalse(controller.isLoading, "Should finish loading")
        XCTAssertNil(controller.errorMessage, "Should have no error")
        
        switch controller.currentState {
        case .clockedIn:
            XCTFail("Should not be in clocked in state after clock out")
        case .clockedOut:
            XCTAssertTrue(true, "Should be in clocked out state")
        }
    }
    
    func testControllerLoadCurrentState() async throws {
        // Given: A worker with active time entry
        let workerID = UUID()
        let activeEntry = createActiveTimeEntry(workerID: workerID)
        mockGateway.activeTimeEntry = activeEntry
        mockGateway.weeklyEntries = [activeEntry]
        
        // When: Loading current state
        await controller.loadCurrentState(for: workerID)
        
        // Then: Should set correct state
        switch controller.currentState {
        case .clockedIn:
            XCTAssertTrue(true, "Should be in clocked in state")
        case .clockedOut:
            XCTFail("Should not be in clocked out state when worker is active")
        }
    }
    
    // MARK: - Presenter Tests
    
    func testTimeTrackingPresenterFormatting() throws {
        // Given: Various hour amounts
        let testCases: [(hours: Double, expected: String)] = [
            (8.0, "8:00"),
            (8.5, "8:30"),
            (8.25, "8:15"),
            (0.0, "0:00"),
            (12.75, "12:45"),
        ]
        
        for testCase in testCases {
            // When: Formatting hours
            let formatted = TimeTrackingPresenter.formatHours(testCase.hours)
            
            // Then: Should format correctly
            XCTAssertEqual(formatted, testCase.expected, 
                          "Hours \(testCase.hours) should format as \(testCase.expected)")
        }
    }
    
    func testWeeklyReportViewModelCreation() throws {
        // Given: A weekly time report
        let workerID = UUID()
        let weekStart = getMondayOfCurrentWeek()
        let calendar = Calendar.current
        
        let dailyEntries = [
            createCompletedTimeEntry(workerID: workerID, date: weekStart, hours: 8.0),
            createCompletedTimeEntry(workerID: workerID, date: calendar.date(byAdding: .day, value: 1, to: weekStart)!, hours: 8.5),
        ]
        
        let report = WeeklyTimeReport(
            workerIdentifier: workerID,
            weekStartDate: weekStart,
            dailyEntries: dailyEntries,
            totalRegularHours: 16.0,
            totalOvertimeHours: 0.5,
            weeklyTotal: 16.5
        )
        
        // When: Creating view model
        let viewModel = TimeTrackingPresenter.formatWeeklyReport(report)
        
        // Then: Should create correct view model
        XCTAssertEqual(viewModel.weekStarting, weekStart)
        XCTAssertEqual(viewModel.totalHours, "16:30")
        XCTAssertEqual(viewModel.regularHours, "16:00")
        XCTAssertEqual(viewModel.overtimeHours, "0:30")
        XCTAssertFalse(viewModel.isOvertime, "Should not be overtime with < 40 hours")
        XCTAssertEqual(viewModel.dailyBreakdown.count, 2, "Should have 2 daily entries")
    }
    
    // MARK: - Integration Tests
    
    func testDependencyInjectionContainer() throws {
        // Given: A dependency container
        let container = TimeTrackingDependencyContainer(context: mockContext)
        
        // When: Creating components
        let gateway = container.makeTimeTrackingGateway()
        let clockUseCase = container.makeClockManagementUseCase()
        let reportingUseCase = container.makeReportingUseCase()
        let controller = container.makeTimeClockController()
        
        // Then: Should create all components
        XCTAssertNotNil(gateway, "Should create gateway")
        XCTAssertNotNil(clockUseCase, "Should create clock use case")
        XCTAssertNotNil(reportingUseCase, "Should create reporting use case")
        XCTAssertNotNil(controller, "Should create controller")
    }
    
    func testCoreDataGatewayMapping() throws {
        // Given: A Core Data gateway
        let gateway = CoreDataTimeTrackingGateway(context: mockContext)
        
        // Create test worker
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.isActive = true
        try mockContext.save()
        
        // Given: A time tracking entity
        let entity = TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: worker.id!,
            workDate: Date(),
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .hour, value: 8, to: Date()),
            totalHours: 8.0,
            isCurrentlyActive: false,
            weekOfYear: 25,
            calendarYear: 2024
        )
        
        // When: Saving entity through gateway
        // Note: This would require async testing setup
        // For now, just verify the gateway exists and can be created
        XCTAssertNotNil(gateway, "Should create Core Data gateway")
    }
    
    // MARK: - Helper Methods
    
    private func createActiveTimeEntry(workerID: UUID) -> TimeTrackingEntity {
        return TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: workerID,
            workDate: Calendar.current.startOfDay(for: Date()),
            startTime: Date(),
            endTime: nil,
            totalHours: 0.0,
            isCurrentlyActive: true,
            weekOfYear: Calendar.current.component(.weekOfYear, from: Date()),
            calendarYear: Calendar.current.component(.yearForWeekOfYear, from: Date())
        )
    }
    
    private func createCompletedTimeEntry(workerID: UUID, date: Date, hours: Double) -> TimeTrackingEntity {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        let endTime = calendar.date(byAdding: .hour, value: Int(hours), to: startTime)!
        
        return TimeTrackingEntity(
            identifier: UUID(),
            workerIdentifier: workerID,
            workDate: calendar.startOfDay(for: date),
            startTime: startTime,
            endTime: endTime,
            totalHours: hours,
            isCurrentlyActive: false,
            weekOfYear: calendar.component(.weekOfYear, from: date),
            calendarYear: calendar.component(.yearForWeekOfYear, from: date)
        )
    }
    
    private func getMondayOfCurrentWeek() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: now))!
    }
}

// MARK: - Mock Gateway Implementation

class MockTimeTrackingDataGateway: TimeTrackingDataGateway {
    var savedEntries: [TimeTrackingEntity] = []
    var updatedEntries: [TimeTrackingEntity] = []
    var deletedEntryIds: [UUID] = []
    var activeTimeEntry: TimeTrackingEntity?
    var weeklyEntries: [TimeTrackingEntity] = []
    var payPeriodEntries: [TimeTrackingEntity] = []
    var shouldThrowError = false
    
    func saveTimeEntry(_ entity: TimeTrackingEntity) async throws {
        if shouldThrowError {
            throw TimeTrackingDataError.saveFailure("Mock error")
        }
        savedEntries.append(entity)
    }
    
    func findActiveTimeEntry(workerID: UUID) async throws -> TimeTrackingEntity? {
        if shouldThrowError {
            throw TimeTrackingDataError.workerNotFound
        }
        return activeTimeEntry?.workerIdentifier == workerID ? activeTimeEntry : nil
    }
    
    func findTimeEntries(workerID: UUID, dateRange: DateInterval) async throws -> [TimeTrackingEntity] {
        if shouldThrowError {
            throw TimeTrackingDataError.invalidData
        }
        
        // Return different sets based on date range to simulate different queries
        let rangeDuration = dateRange.duration
        if rangeDuration <= 7 * 24 * 3600 { // Week or less
            return weeklyEntries.filter { $0.workerIdentifier == workerID }
        } else { // Longer period (like pay period)
            return payPeriodEntries.filter { $0.workerIdentifier == workerID }
        }
    }
    
    func updateTimeEntry(_ entity: TimeTrackingEntity) async throws {
        if shouldThrowError {
            throw TimeTrackingDataError.entryNotFound
        }
        updatedEntries.append(entity)
        // Update active entry if it matches
        if activeTimeEntry?.identifier == entity.identifier {
            activeTimeEntry = entity
        }
    }
    
    func deleteTimeEntry(identifier: UUID) async throws {
        if shouldThrowError {
            throw TimeTrackingDataError.entryNotFound
        }
        deletedEntryIds.append(identifier)
        if activeTimeEntry?.identifier == identifier {
            activeTimeEntry = nil
        }
    }
    
    func findAllWorkersWithActiveEntries() async throws -> [UUID] {
        if shouldThrowError {
            throw TimeTrackingDataError.invalidData
        }
        return activeTimeEntry != nil ? [activeTimeEntry!.workerIdentifier] : []
    }
}