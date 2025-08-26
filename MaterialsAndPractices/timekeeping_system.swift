//
//  timekeeping_system.swift
//  MaterialsAndPractices
//
//  Clean architecture implementation for time tracking system.
//  Follows Uncle Bob's Clean Architecture principles with clear separation of concerns.
//  
//  Architecture Layers:
//  - Domain: TimeEntry, Worker entities and business rules
//  - Use Cases: Time tracking operations and business logic
//  - Interface Adapters: Presenters and Controllers
//  - Frameworks: Core Data and SwiftUI integration
//
//  Created by AI Assistant following Clean Code principles.
//

import Foundation
import CoreData
import Combine

// MARK: - Domain Layer

/// Domain entity representing a time tracking entry
/// Pure business object with no framework dependencies
struct TimeEntry {
    let id: UUID
    let workerId: UUID
    let date: Date
    let clockInTime: Date?
    let clockOutTime: Date?
    let hoursWorked: Double
    let isActive: Bool
    let weekNumber: Int
    let year: Int
    
    /// Calculate if this entry represents overtime (> 8 hours)
    var isOvertime: Bool {
        return hoursWorked > 8.0
    }
    
    /// Get formatted hours in HH:MM format
    var formattedHours: String {
        let hours = Int(hoursWorked)
        let minutes = Int((hoursWorked - Double(hours)) * 60)
        return String(format: "%d:%02d", hours, minutes)
    }
}

/// Domain service for time calculations
/// Contains business rules for time tracking
protocol TimeCalculationService {
    func calculateHoursWorked(clockIn: Date, clockOut: Date) -> Double
    func calculateWeeklyHours(entries: [TimeEntry]) -> Double
    func isOvertimeWeek(totalHours: Double) -> Bool
    func roundToQuarterHour(_ hours: Double) -> Double
}

// MARK: - Use Cases Layer

/// Use case for clocking in/out operations
/// Contains application-specific business rules
protocol ClockInOutUseCase {
    func clockIn(workerId: UUID) async throws
    func clockOut(workerId: UUID) async throws
    func getCurrentTimeEntry(for workerId: UUID) async throws -> TimeEntry?
}

/// Use case for time reporting and calculations
/// Handles weekly summaries and overtime detection
protocol TimeReportingUseCase {
    func getWeeklyTimeEntries(for workerId: UUID, week: Date) async throws -> [TimeEntry]
    func calculateWeeklyTotal(for workerId: UUID, week: Date) async throws -> Double
    func getOvertimeWorkers() async throws -> [UUID]
}

// MARK: - Repository Interface (Port)

/// Repository interface for time tracking data
/// Defines contract for data access without implementation details
protocol TimeTrackingRepository {
    func save(_ timeEntry: TimeEntry) async throws
    func findActiveTimeEntry(for workerId: UUID) async throws -> TimeEntry?
    func findTimeEntries(for workerId: UUID, in dateRange: DateInterval) async throws -> [TimeEntry]
    func updateTimeEntry(_ timeEntry: TimeEntry) async throws
    func delete(_ timeEntryId: UUID) async throws
}

// MARK: - Implementation Classes

/// Default implementation of time calculation service
/// TODO: Consider renaming to TimeCalculationBusinessRules to better reflect Clean Architecture
class DefaultTimeCalculationService: TimeCalculationService {
    
    func calculateHoursWorked(clockIn: Date, clockOut: Date) -> Double {
        let interval = clockOut.timeIntervalSince(clockIn)
        return interval / 3600.0 // Convert seconds to hours
    }
    
    func calculateWeeklyHours(entries: [TimeEntry]) -> Double {
        return entries.reduce(0) { total, entry in
            total + entry.hoursWorked
        }
    }
    
    func isOvertimeWeek(totalHours: Double) -> Bool {
        return totalHours > 40.0 // Standard 40-hour work week
    }
    
    func roundToQuarterHour(_ hours: Double) -> Double {
        return round(hours * 4.0) / 4.0 // Round to nearest 15 minutes
    }
}

/// Implementation of clock in/out use case
/// TODO: Consider renaming to ClockInOutInteractor to follow Clean Architecture naming conventions
class DefaultClockInOutUseCase: ClockInOutUseCase {
    private let repository: TimeTrackingRepository
    private let calculationService: TimeCalculationService
    
    init(repository: TimeTrackingRepository, calculationService: TimeCalculationService) {
        self.repository = repository
        self.calculationService = calculationService
    }
    
    func clockIn(workerId: UUID) async throws {
        // Business rule: Cannot clock in if already clocked in
        if let existingEntry = try await repository.findActiveTimeEntry(for: workerId) {
            throw TimeTrackingError.alreadyClockedIn
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let timeEntry = TimeEntry(
            id: UUID(),
            workerId: workerId,
            date: calendar.startOfDay(for: now),
            clockInTime: now,
            clockOutTime: nil,
            hoursWorked: 0.0,
            isActive: true,
            weekNumber: calendar.component(.weekOfYear, from: now),
            year: calendar.component(.yearForWeekOfYear, from: now)
        )
        
        try await repository.save(timeEntry)
    }
    
    func clockOut(workerId: UUID) async throws {
        guard var timeEntry = try await repository.findActiveTimeEntry(for: workerId) else {
            throw TimeTrackingError.notClockedIn
        }
        
        guard let clockInTime = timeEntry.clockInTime else {
            throw TimeTrackingError.invalidClockInTime
        }
        
        let clockOutTime = Date()
        let hoursWorked = calculationService.calculateHoursWorked(
            clockIn: clockInTime,
            clockOut: clockOutTime
        )
        
        // Create updated time entry
        let updatedEntry = TimeEntry(
            id: timeEntry.id,
            workerId: timeEntry.workerId,
            date: timeEntry.date,
            clockInTime: timeEntry.clockInTime,
            clockOutTime: clockOutTime,
            hoursWorked: hoursWorked,
            isActive: false,
            weekNumber: timeEntry.weekNumber,
            year: timeEntry.year
        )
        
        try await repository.updateTimeEntry(updatedEntry)
    }
    
    func getCurrentTimeEntry(for workerId: UUID) async throws -> TimeEntry? {
        return try await repository.findActiveTimeEntry(for: workerId)
    }
}

/// Implementation of time reporting use case
/// TODO: Consider renaming to TimeReportingInteractor for consistency with Clean Architecture
class DefaultTimeReportingUseCase: TimeReportingUseCase {
    private let repository: TimeTrackingRepository
    private let calculationService: TimeCalculationService
    
    init(repository: TimeTrackingRepository, calculationService: TimeCalculationService) {
        self.repository = repository
        self.calculationService = calculationService
    }
    
    func getWeeklyTimeEntries(for workerId: UUID, week: Date) async throws -> [TimeEntry] {
        let calendar = Calendar.current
        
        // Calculate Monday to Sunday range
        let weekday = calendar.component(.weekday, from: week)
        let daysFromMonday = (weekday + 5) % 7
        let mondayDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: week)!
        let sundayDate = calendar.date(byAdding: .day, value: 6, to: mondayDate)!
        
        let dateRange = DateInterval(start: mondayDate, end: sundayDate)
        return try await repository.findTimeEntries(for: workerId, in: dateRange)
    }
    
    func calculateWeeklyTotal(for workerId: UUID, week: Date) async throws -> Double {
        let entries = try await getWeeklyTimeEntries(for: workerId, week: week)
        return calculationService.calculateWeeklyHours(entries: entries)
    }
    
    func getOvertimeWorkers() async throws -> [UUID] {
        // TODO: Implement logic to find all workers with overtime hours this week
        // This would require a repository method to get all workers and their weekly totals
        return []
    }
}

// MARK: - Error Handling

enum TimeTrackingError: Error, LocalizedError {
    case alreadyClockedIn
    case notClockedIn
    case invalidClockInTime
    case workerNotFound
    case dataAccessError(String)
    
    var errorDescription: String? {
        switch self {
        case .alreadyClockedIn:
            return "Worker is already clocked in"
        case .notClockedIn:
            return "Worker is not currently clocked in"
        case .invalidClockInTime:
            return "Invalid clock-in time found"
        case .workerNotFound:
            return "Worker not found"
        case .dataAccessError(let message):
            return "Data access error: \(message)"
        }
    }
}

// MARK: - Architecture Comments for Existing Code

/*
 CLEAN ARCHITECTURE IMPROVEMENT RECOMMENDATIONS:
 
 1. WorkOrderSystem.swift:
    - TimeClock extension should be moved to a TimeClockEntity adapter
    - Business logic in extensions should be moved to use cases
    - Consider renaming clockedInMembers() to getClockedInWorkers() for clarity
    
 2. WorkerManagementViews.swift:
    - Clock in/out logic should be extracted to use cases
    - UI should only handle presentation, not business logic
    - Consider renaming WorkerTimeClockView to TimeClockPresenter
    - calculateCurrentWeekHours() should be moved to TimeReportingUseCase
    
 3. FarmDashboardView.swift:
    - Dashboard logic should be separated into a DashboardPresenter
    - Data fetching should be handled by repository pattern
    - Consider creating DashboardViewModel for state management
    
 4. Suggested Renamings for Better Architecture:
    - clockIn()/clockOut() methods → ClockInOutInteractor
    - calculateWeeklyHours() → WeeklyHoursCalculator (business rule)
    - TimeClock extensions → TimeClockEntityAdapter
    - Worker extensions → WorkerEntityAdapter
 */