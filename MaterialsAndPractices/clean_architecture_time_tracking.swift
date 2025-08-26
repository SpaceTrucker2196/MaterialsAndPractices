//
//  clean_architecture_time_tracking.swift
//  MaterialsAndPractices
//
//  Clean Architecture implementation for time tracking with proper dependency inversion.
//  Implements the Dependency Rule: source code dependencies point inward toward higher-level policies.
//  
//  Architecture Layers (following Uncle Bob's Clean Architecture):
//  1. Entities (innermost): Business objects and rules
//  2. Use Cases: Application business rules
//  3. Interface Adapters: Controllers, Gateways, Presenters
//  4. Frameworks & Drivers: Database, UI, External interfaces
//
//  Created by AI Assistant following Clean Architecture principles.
//

import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - Entities Layer (Business Objects)

/// Core business entity for time tracking
/// Contains enterprise-wide business rules
struct TimeTrackingEntity {
    let identifier: UUID
    let workerIdentifier: UUID
    let workDate: Date
    let startTime: Date?
    let endTime: Date?
    let totalHours: Double
    let isCurrentlyActive: Bool
    let weekOfYear: Int
    let calendarYear: Int
    
    /// Business rule: Maximum daily hours before overtime
    private static let maxRegularHours: Double = 8.0
    
    /// Business rule: Maximum weekly hours before overtime
    private static let maxWeeklyHours: Double = 40.0
    
    /// Enterprise business rule: Check if daily overtime applies
    var isDailyOvertime: Bool {
        return totalHours > Self.maxRegularHours
    }
    
    /// Enterprise business rule: Calculate overtime hours for the day
    var dailyOvertimeHours: Double {
        return max(0, totalHours - Self.maxRegularHours)
    }
    
    /// Enterprise business rule: Validate time entry consistency
    var isValid: Bool {
        guard let start = startTime, let end = endTime else {
            return isCurrentlyActive ? startTime != nil : false
        }
        return end > start && totalHours >= 0
    }
}

// MARK: - Use Cases Layer (Application Business Rules)

/// Input data for clocking in
struct ClockInRequest {
    let workerIdentifier: UUID
    let timestamp: Date
}

/// Input data for clocking out
struct ClockOutRequest {
    let workerIdentifier: UUID
    let timestamp: Date
}

/// Output data for time tracking operations
struct TimeTrackingResponse {
    let success: Bool
    let timeEntry: TimeTrackingEntity?
    let message: String
    let weeklyTotal: Double?
}

/// Use case for managing worker time clock operations
/// Application-specific business rules for time tracking
protocol TimeClockManagementUseCase {
    func executeClockIn(_ request: ClockInRequest) async -> TimeTrackingResponse
    func executeClockOut(_ request: ClockOutRequest) async -> TimeTrackingResponse
    func getCurrentActiveEntry(for workerID: UUID) async -> TimeTrackingEntity?
}

/// Use case for time reporting and analytics
/// Application business rules for generating time reports
protocol TimeReportingAnalyticsUseCase {
    func generateWeeklyReport(for workerID: UUID, week: Date) async -> WeeklyTimeReport
    func generateOvertimeReport(for week: Date) async -> OvertimeReport
    func calculatePayrollData(for workerID: UUID, period: DateInterval) async -> PayrollData
}

/// Weekly time report structure
struct WeeklyTimeReport {
    let workerIdentifier: UUID
    let weekStartDate: Date
    let dailyEntries: [TimeTrackingEntity]
    let totalRegularHours: Double
    let totalOvertimeHours: Double
    let weeklyTotal: Double
    
    /// Business rule: Check if weekly overtime applies
    var isWeeklyOvertime: Bool {
        return weeklyTotal > 40.0
    }
}

/// Overtime report for management
struct OvertimeReport {
    let reportDate: Date
    let weekStartDate: Date
    let overtimeWorkers: [OvertimeWorkerData]
    let totalOvertimeHours: Double
    let estimatedOvertimeCost: Double
}

struct OvertimeWorkerData {
    let workerIdentifier: UUID
    let workerName: String
    let regularHours: Double
    let overtimeHours: Double
    let dailyOvertimeBreakdown: [Date: Double]
}

/// Payroll calculation data
struct PayrollData {
    let workerIdentifier: UUID
    let payPeriodStart: Date
    let payPeriodEnd: Date
    let regularHours: Double
    let overtimeHours: Double
    let totalHours: Double
    let estimatedRegularPay: Double
    let estimatedOvertimePay: Double
    let estimatedTotalPay: Double
}

// MARK: - Interface Adapters Layer (Controllers, Gateways, Presenters)

/// Gateway interface for time tracking data persistence
/// Implements the Repository pattern to abstract data access
protocol TimeTrackingDataGateway {
    func saveTimeEntry(_ entity: TimeTrackingEntity) async throws
    func findActiveTimeEntry(workerID: UUID) async throws -> TimeTrackingEntity?
    func findTimeEntries(workerID: UUID, dateRange: DateInterval) async throws -> [TimeTrackingEntity]
    func updateTimeEntry(_ entity: TimeTrackingEntity) async throws
    func deleteTimeEntry(identifier: UUID) async throws
    func findAllWorkersWithActiveEntries() async throws -> [UUID]
}

/// Controller for handling time clock UI interactions
/// Converts UI events to use case calls
class TimeClockController: ObservableObject {
    private let clockUseCase: TimeClockManagementUseCase
    private let reportingUseCase: TimeReportingAnalyticsUseCase
    
    @Published var currentState: TimeClockState = .clockedOut
    @Published var weeklyHours: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init(clockUseCase: TimeClockManagementUseCase, reportingUseCase: TimeReportingAnalyticsUseCase) {
        self.clockUseCase = clockUseCase
        self.reportingUseCase = reportingUseCase
    }
    
    /// Handle clock in button tap
    @MainActor
    func handleClockInTapped(workerID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        let request = ClockInRequest(workerIdentifier: workerID, timestamp: Date())
        let response = await clockUseCase.executeClockIn(request)
        
        if response.success {
            currentState = .clockedIn(startTime: Date())
            if let weeklyTotal = response.weeklyTotal {
                weeklyHours = weeklyTotal
            }
        } else {
            errorMessage = response.message
        }
        
        isLoading = false
    }
    
    /// Handle clock out button tap
    @MainActor
    func handleClockOutTapped(workerID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        let request = ClockOutRequest(workerIdentifier: workerID, timestamp: Date())
        let response = await clockUseCase.executeClockOut(request)
        
        if response.success {
            currentState = .clockedOut
            if let timeEntry = response.timeEntry {
                // Update weekly hours with the completed entry
                let report = await reportingUseCase.generateWeeklyReport(for: workerID, week: Date())
                weeklyHours = report.weeklyTotal
            }
        } else {
            errorMessage = response.message
        }
        
        isLoading = false
    }
    
    /// Load current state for worker
    @MainActor
    func loadCurrentState(for workerID: UUID) async {
        if let activeEntry = await clockUseCase.getCurrentActiveEntry(for: workerID) {
            currentState = .clockedIn(startTime: activeEntry.startTime ?? Date())
        } else {
            currentState = .clockedOut
        }
        
        // Load weekly hours
        let report = await reportingUseCase.generateWeeklyReport(for: workerID, week: Date())
        weeklyHours = report.weeklyTotal
    }
}

/// Presenter for formatting time tracking data for display
/// Converts use case outputs to view-friendly formats
struct TimeTrackingPresenter {
    
    /// Format hours as HH:MM string
    static func formatHours(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        return String(format: "%d:%02d", wholeHours, minutes)
    }
    
    /// Format weekly time report for display
    static func formatWeeklyReport(_ report: WeeklyTimeReport) -> WeeklyReportViewModel {
        return WeeklyReportViewModel(
            weekStarting: report.weekStartDate,
            totalHours: formatHours(report.weeklyTotal),
            regularHours: formatHours(report.totalRegularHours),
            overtimeHours: formatHours(report.totalOvertimeHours),
            isOvertime: report.isWeeklyOvertime,
            dailyBreakdown: report.dailyEntries.map { entry in
                DailyEntryViewModel(
                    date: entry.workDate,
                    hours: formatHours(entry.totalHours),
                    isOvertime: entry.isDailyOvertime,
                    clockIn: entry.startTime,
                    clockOut: entry.endTime
                )
            }
        )
    }
    
    /// Format payroll data for display
    static func formatPayrollData(_ payroll: PayrollData, hourlyRate: Double) -> PayrollViewModel {
        return PayrollViewModel(
            payPeriod: "\(payroll.payPeriodStart.formatted(date: .abbreviated, time: .omitted)) - \(payroll.payPeriodEnd.formatted(date: .abbreviated, time: .omitted))",
            regularHours: formatHours(payroll.regularHours),
            overtimeHours: formatHours(payroll.overtimeHours),
            totalHours: formatHours(payroll.totalHours),
            estimatedPay: String(format: "$%.2f", payroll.estimatedTotalPay)
        )
    }
}

// MARK: - View Models (Presentation Layer)

enum TimeClockState {
    case clockedIn(startTime: Date)
    case clockedOut
    
    var isClockedIn: Bool {
        switch self {
        case .clockedIn: return true
        case .clockedOut: return false
        }
    }
}

struct WeeklyReportViewModel {
    let weekStarting: Date
    let totalHours: String
    let regularHours: String
    let overtimeHours: String
    let isOvertime: Bool
    let dailyBreakdown: [DailyEntryViewModel]
}

struct DailyEntryViewModel {
    let date: Date
    let hours: String
    let isOvertime: Bool
    let clockIn: Date?
    let clockOut: Date?
}

struct PayrollViewModel {
    let payPeriod: String
    let regularHours: String
    let overtimeHours: String
    let totalHours: String
    let estimatedPay: String
}

// MARK: - Frameworks Layer (Implementation Details)

/// Core Data implementation of TimeTrackingDataGateway
/// Adapter between Core Data and the clean architecture
class CoreDataTimeTrackingGateway: TimeTrackingDataGateway {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func saveTimeEntry(_ entity: TimeTrackingEntity) async throws {
        let timeClock = TimeClock(context: context)
        timeClock.id = entity.identifier
        timeClock.date = entity.workDate
        timeClock.clockInTime = entity.startTime
        timeClock.clockOutTime = entity.endTime
        timeClock.hoursWorked = entity.totalHours
        timeClock.isActive = entity.isCurrentlyActive
        timeClock.weekNumber = Int16(entity.weekOfYear)
        timeClock.year = Int16(entity.calendarYear)
        
        // Find and associate worker
        let workerRequest: NSFetchRequest<Worker> = Worker.fetchRequest()
        workerRequest.predicate = NSPredicate(format: "id == %@", entity.workerIdentifier as CVarArg)
        
        if let worker = try context.fetch(workerRequest).first {
            timeClock.worker = worker
        }
        
        try context.save()
    }
    
    func findActiveTimeEntry(workerID: UUID) async throws -> TimeTrackingEntity? {
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(format: "worker.id == %@ AND isActive == YES", workerID as CVarArg)
        request.fetchLimit = 1
        
        guard let timeClock = try context.fetch(request).first else {
            return nil
        }
        
        return mapToEntity(timeClock)
    }
    
    func findTimeEntries(workerID: UUID, dateRange: DateInterval) async throws -> [TimeTrackingEntity] {
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(
            format: "worker.id == %@ AND date >= %@ AND date <= %@",
            workerID as CVarArg,
            dateRange.start as NSDate,
            dateRange.end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeClock.date, ascending: true)]
        
        let timeClocks = try context.fetch(request)
        return timeClocks.compactMap { mapToEntity($0) }
    }
    
    func updateTimeEntry(_ entity: TimeTrackingEntity) async throws {
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entity.identifier as CVarArg)
        request.fetchLimit = 1
        
        guard let timeClock = try context.fetch(request).first else {
            throw TimeTrackingDataError.entryNotFound
        }
        
        timeClock.clockOutTime = entity.endTime
        timeClock.hoursWorked = entity.totalHours
        timeClock.isActive = entity.isCurrentlyActive
        
        try context.save()
    }
    
    func deleteTimeEntry(identifier: UUID) async throws {
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", identifier as CVarArg)
        request.fetchLimit = 1
        
        guard let timeClock = try context.fetch(request).first else {
            throw TimeTrackingDataError.entryNotFound
        }
        
        context.delete(timeClock)
        try context.save()
    }
    
    func findAllWorkersWithActiveEntries() async throws -> [UUID] {
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.relationshipKeyPathsForPrefetching = ["worker"]
        
        let activeEntries = try context.fetch(request)
        return activeEntries.compactMap { $0.worker?.id }
    }
    
    /// Helper method to map Core Data entity to domain entity
    private func mapToEntity(_ timeClock: TimeClock) -> TimeTrackingEntity? {
        guard let id = timeClock.id,
              let workerID = timeClock.worker?.id,
              let date = timeClock.date else {
            return nil
        }
        
        return TimeTrackingEntity(
            identifier: id,
            workerIdentifier: workerID,
            workDate: date,
            startTime: timeClock.clockInTime,
            endTime: timeClock.clockOutTime,
            totalHours: timeClock.hoursWorked,
            isCurrentlyActive: timeClock.isActive,
            weekOfYear: Int(timeClock.weekNumber),
            calendarYear: Int(timeClock.year)
        )
    }
}

enum TimeTrackingDataError: Error {
    case entryNotFound
    case workerNotFound
    case invalidData
    case saveFailure(String)
}

// MARK: - Use Case Implementations

/// Default implementation of time clock management use case
class DefaultTimeClockManagementUseCase: TimeClockManagementUseCase {
    private let gateway: TimeTrackingDataGateway
    
    init(gateway: TimeTrackingDataGateway) {
        self.gateway = gateway
    }
    
    func executeClockIn(_ request: ClockInRequest) async -> TimeTrackingResponse {
        do {
            // Business rule: Check if already clocked in
            if let existingEntry = try await gateway.findActiveTimeEntry(workerID: request.workerIdentifier) {
                return TimeTrackingResponse(
                    success: false,
                    timeEntry: existingEntry,
                    message: "Worker is already clocked in",
                    weeklyTotal: nil
                )
            }
            
            let calendar = Calendar.current
            let timeEntry = TimeTrackingEntity(
                identifier: UUID(),
                workerIdentifier: request.workerIdentifier,
                workDate: calendar.startOfDay(for: request.timestamp),
                startTime: request.timestamp,
                endTime: nil,
                totalHours: 0.0,
                isCurrentlyActive: true,
                weekOfYear: calendar.component(.weekOfYear, from: request.timestamp),
                calendarYear: calendar.component(.yearForWeekOfYear, from: request.timestamp)
            )
            
            try await gateway.saveTimeEntry(timeEntry)
            
            return TimeTrackingResponse(
                success: true,
                timeEntry: timeEntry,
                message: "Successfully clocked in",
                weeklyTotal: nil
            )
            
        } catch {
            return TimeTrackingResponse(
                success: false,
                timeEntry: nil,
                message: "Failed to clock in: \(error.localizedDescription)",
                weeklyTotal: nil
            )
        }
    }
    
    func executeClockOut(_ request: ClockOutRequest) async -> TimeTrackingResponse {
        do {
            guard var activeEntry = try await gateway.findActiveTimeEntry(workerID: request.workerIdentifier) else {
                return TimeTrackingResponse(
                    success: false,
                    timeEntry: nil,
                    message: "Worker is not currently clocked in",
                    weeklyTotal: nil
                )
            }
            
            guard let clockInTime = activeEntry.startTime else {
                return TimeTrackingResponse(
                    success: false,
                    timeEntry: nil,
                    message: "Invalid clock-in time",
                    weeklyTotal: nil
                )
            }
            
            let hoursWorked = request.timestamp.timeIntervalSince(clockInTime) / 3600.0
            
            let updatedEntry = TimeTrackingEntity(
                identifier: activeEntry.identifier,
                workerIdentifier: activeEntry.workerIdentifier,
                workDate: activeEntry.workDate,
                startTime: activeEntry.startTime,
                endTime: request.timestamp,
                totalHours: hoursWorked,
                isCurrentlyActive: false,
                weekOfYear: activeEntry.weekOfYear,
                calendarYear: activeEntry.calendarYear
            )
            
            try await gateway.updateTimeEntry(updatedEntry)
            
            return TimeTrackingResponse(
                success: true,
                timeEntry: updatedEntry,
                message: "Successfully clocked out",
                weeklyTotal: nil
            )
            
        } catch {
            return TimeTrackingResponse(
                success: false,
                timeEntry: nil,
                message: "Failed to clock out: \(error.localizedDescription)",
                weeklyTotal: nil
            )
        }
    }
    
    func getCurrentActiveEntry(for workerID: UUID) async -> TimeTrackingEntity? {
        do {
            return try await gateway.findActiveTimeEntry(workerID: workerID)
        } catch {
            return nil
        }
    }
}

/// Default implementation of time reporting analytics use case
class DefaultTimeReportingAnalyticsUseCase: TimeReportingAnalyticsUseCase {
    private let gateway: TimeTrackingDataGateway
    
    init(gateway: TimeTrackingDataGateway) {
        self.gateway = gateway
    }
    
    func generateWeeklyReport(for workerID: UUID, week: Date) async -> WeeklyTimeReport {
        let calendar = Calendar.current
        
        // Calculate Monday to Sunday range
        let weekday = calendar.component(.weekday, from: week)
        let daysFromMonday = (weekday + 5) % 7
        let mondayDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: week)!
        let sundayDate = calendar.date(byAdding: .day, value: 6, to: mondayDate)!
        
        let dateRange = DateInterval(start: mondayDate, end: sundayDate)
        
        do {
            let entries = try await gateway.findTimeEntries(workerID: workerID, dateRange: dateRange)
            
            let totalHours = entries.reduce(0) { $0 + $1.totalHours }
            let regularHours = min(totalHours, 40.0)
            let overtimeHours = max(0, totalHours - 40.0)
            
            return WeeklyTimeReport(
                workerIdentifier: workerID,
                weekStartDate: mondayDate,
                dailyEntries: entries,
                totalRegularHours: regularHours,
                totalOvertimeHours: overtimeHours,
                weeklyTotal: totalHours
            )
        } catch {
            // Return empty report on error
            return WeeklyTimeReport(
                workerIdentifier: workerID,
                weekStartDate: mondayDate,
                dailyEntries: [],
                totalRegularHours: 0,
                totalOvertimeHours: 0,
                weeklyTotal: 0
            )
        }
    }
    
    func generateOvertimeReport(for week: Date) async -> OvertimeReport {
        // TODO: Implement comprehensive overtime reporting
        // This would require gateway methods to fetch all workers and their time entries
        return OvertimeReport(
            reportDate: Date(),
            weekStartDate: week,
            overtimeWorkers: [],
            totalOvertimeHours: 0,
            estimatedOvertimeCost: 0
        )
    }
    
    func calculatePayrollData(for workerID: UUID, period: DateInterval) async -> PayrollData {
        do {
            let entries = try await gateway.findTimeEntries(workerID: workerID, dateRange: period)
            
            let totalHours = entries.reduce(0) { $0 + $1.totalHours }
            let regularHours = min(totalHours, 40.0 * (period.duration / (7 * 24 * 3600))) // Assuming 40-hour weeks
            let overtimeHours = max(0, totalHours - regularHours)
            
            // TODO: Get actual hourly rates from worker data
            let baseRate = 15.0 // Placeholder
            let overtimeRate = baseRate * 1.5
            
            return PayrollData(
                workerIdentifier: workerID,
                payPeriodStart: period.start,
                payPeriodEnd: period.end,
                regularHours: regularHours,
                overtimeHours: overtimeHours,
                totalHours: totalHours,
                estimatedRegularPay: regularHours * baseRate,
                estimatedOvertimePay: overtimeHours * overtimeRate,
                estimatedTotalPay: (regularHours * baseRate) + (overtimeHours * overtimeRate)
            )
        } catch {
            // Return zero payroll data on error
            return PayrollData(
                workerIdentifier: workerID,
                payPeriodStart: period.start,
                payPeriodEnd: period.end,
                regularHours: 0,
                overtimeHours: 0,
                totalHours: 0,
                estimatedRegularPay: 0,
                estimatedOvertimePay: 0,
                estimatedTotalPay: 0
            )
        }
    }
}

// MARK: - Dependency Injection Container

/// Simple dependency injection container for clean architecture
class TimeTrackingDependencyContainer {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Create configured time tracking gateway
    func makeTimeTrackingGateway() -> TimeTrackingDataGateway {
        return CoreDataTimeTrackingGateway(context: context)
    }
    
    /// Create configured clock management use case
    func makeClockManagementUseCase() -> TimeClockManagementUseCase {
        return DefaultTimeClockManagementUseCase(gateway: makeTimeTrackingGateway())
    }
    
    /// Create configured reporting use case
    func makeReportingUseCase() -> TimeReportingAnalyticsUseCase {
        return DefaultTimeReportingAnalyticsUseCase(gateway: makeTimeTrackingGateway())
    }
    
    /// Create configured controller
    func makeTimeClockController() -> TimeClockController {
        return TimeClockController(
            clockUseCase: makeClockManagementUseCase(),
            reportingUseCase: makeReportingUseCase()
        )
    }
}

/*
 ARCHITECTURAL ANALYSIS OF EXISTING CODE:
 
 The existing codebase has time tracking functionality but lacks proper Clean Architecture separation.
 
 ISSUES IDENTIFIED:
 
 1. WorkOrderSystem.swift - Mixed Concerns:
    - TimeClock extensions contain business logic that should be in use cases
    - UI formatting logic mixed with domain logic
    - Direct Core Data access without repository abstraction
    
 2. WorkerManagementViews.swift - UI Handling Business Logic:
    - clockIn() and clockOut() methods contain business rules
    - Direct Core Data manipulation in view controllers
    - Calculation logic mixed with presentation logic
    
 3. FarmDashboardView.swift - Tight Coupling:
    - Direct @FetchRequest usage creates tight coupling to Core Data
    - Business logic embedded in view layer
    - No separation between data access and presentation
 
 RECOMMENDED REFACTORING:
 
 1. Extract time tracking business logic into use cases
 2. Create repository interfaces for data access
 3. Implement dependency injection for testability
 4. Separate presentation logic from business logic
 5. Use controllers/view models to mediate between UI and use cases
 
 This clean architecture implementation provides a blueprint for refactoring
 the existing code to follow proper separation of concerns.
 */