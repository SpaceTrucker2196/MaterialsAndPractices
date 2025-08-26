//
//  WorkOrderSystem.swift
//  MaterialsAndPractices
//
//  Provides work order management functionality including status tracking,
//  team management, and agricultural work coordination for farm operations.
//  Supports comprehensive time tracking and worker assignment.
//
//  Created by GitHub Copilot on 12/18/24.
//

import Foundation
import CoreData

// MARK: - Agriculture Work Status

/// Enumeration for common agriculture work statuses with appropriate text and emoji
enum AgricultureWorkStatus: String, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case onHold = "on_hold"
    case cancelled = "cancelled"
    case weatherDelay = "weather_delay"
    case tooWet = "too_wet"
    case equipmentIssue = "equipment_issue"
    case waitingForMaterials = "waiting_materials"
    case waitingForInspection = "waiting_inspection"
    
    /// User-friendly display text
    var displayText: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        case .cancelled: return "Cancelled"
        case .weatherDelay: return "Weather Delay"
        case .tooWet: return "Too Wet"
        case .equipmentIssue: return "Equipment Issue"
        case .waitingForMaterials: return "Waiting for Materials"
        case .waitingForInspection: return "Waiting for Inspection"
        }
    }
    
    /// Appropriate emoji for the status
    var emoji: String {
        switch self {
        case .notStarted: return "⏹️"
        case .inProgress: return "🔄"
        case .completed: return "✅"
        case .onHold: return "⏸️"
        case .cancelled: return "❌"
        case .weatherDelay: return "🌧️"
        case .tooWet: return "💧"
        case .equipmentIssue: return "🔧"
        case .waitingForMaterials: return "📦"
        case .waitingForInspection: return "🔍"
        }
    }
    
    /// Combined display with emoji and text
    var displayWithEmoji: String {
        return "\(emoji) \(displayText)"
    }
    
    /// Color coding for status
    var statusColor: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .onHold: return "yellow"
        case .cancelled: return "red"
        case .weatherDelay: return "purple"
        case .tooWet: return "cyan"
        case .equipmentIssue: return "orange"
        case .waitingForMaterials: return "brown"
        case .waitingForInspection: return "indigo"
        }
    }
}

// MARK: - Work Order Priority

/// Enumeration for work order priority levels
enum WorkOrderPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayText: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var emoji: String {
        switch self {
        case .low: return "⬇️"
        case .medium: return "➡️"
        case .high: return "⬆️"
        case .urgent: return "🚨"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        }
    }
}

// MARK: - Work Order Extensions

extension WorkOrder {
    /// Computed property for agriculture work status
    var agricultureStatus: AgricultureWorkStatus {
        get {
            return AgricultureWorkStatus(rawValue: self.status ?? "not_started") ?? .notStarted
        }
        set {
            self.status = newValue.rawValue
        }
    }
    
    /// Computed property for work order priority
    var workPriority: WorkOrderPriority {
        get {
            return WorkOrderPriority(rawValue: self.priority ?? "medium") ?? .medium
        }
        set {
            self.priority = newValue.rawValue
        }
    }
    
    /// Calculate total hours worked on this work order
    func totalHoursWorked() -> Double {
        guard let timeEntries = self.timeClockEntries?.allObjects as? [TimeClock] else {
            return 0.0
        }
        
        return timeEntries.reduce(0.0) { total, entry in
            total + entry.hoursWorked
        }
    }
    
    /// Get list of workers assigned to this work order
    func assignedWorkers() -> [Worker] {
        guard let team = self.assignedTeam,
              let members = team.members?.allObjects as? [Worker] else {
            return []
        }
        
        return members.filter { $0.isActive }
    }
    
    /// Check if work order is overdue
    func isOverdue() -> Bool {
        guard let dueDate = self.dueDate else { return false }
        return Date() > dueDate && !isCompleted
    }
    
    /// Progress percentage (0.0 to 1.0)
    func progressPercentage() -> Double {
        switch agricultureStatus {
        case .notStarted: return 0.0
        case .inProgress: return 0.5
        case .completed: return 1.0
        case .onHold, .weatherDelay, .tooWet, .equipmentIssue, .waitingForMaterials, .waitingForInspection: return 0.3
        case .cancelled: return 0.0
        }
    }
}

// MARK: - Work Team Extensions

extension WorkTeam {
    /// Get active members of the team
    func activeMembers() -> [Worker] {
        guard let members = self.members?.allObjects as? [Worker] else {
            return []
        }
        
        return members.filter { $0.isActive }
    }
    
    /// Get currently clocked-in members
    func clockedInMembers() -> [Worker] {
        return activeMembers().filter { worker in
            // Check if worker has an active time clock entry
            guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else {
                return false
            }
            
            return timeEntries.contains { $0.isActive }
        }
    }
    
    /// Count of clocked-in members
    func clockedInCount() -> Int {
        return clockedInMembers().count
    }
}

// MARK: - Worker Extensions for Work Orders

extension Worker {
    /// Get current active time clock entry
    func currentTimeClockEntry() -> TimeClock? {
        guard let timeEntries = self.timeClockEntries?.allObjects as? [TimeClock] else {
            return nil
        }
        
        return timeEntries.first { $0.isActive }
    }
    
    /// Check if worker is currently clocked in
    func isClockedIn() -> Bool {
        return currentTimeClockEntry() != nil
    }
    
    /// Get work orders for current week
    func workOrdersForCurrentWeek() -> [WorkOrder] {
        let calendar = Calendar.current
        let now = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let year = calendar.component(.year, from: now)
        
        guard let timeEntries = self.timeClockEntries?.allObjects as? [TimeClock] else {
            return []
        }
        
        let weekEntries = timeEntries.filter { entry in
            entry.weekNumber == weekOfYear && entry.year == year
        }
        
        var workOrders: Set<WorkOrder> = []
        for entry in weekEntries {
            if let workOrder = entry.workOrder {
                workOrders.insert(workOrder)
            }
        }
        
        return Array(workOrders).sorted { order1, order2 in
            (order1.createdDate ?? Date.distantPast) < (order2.createdDate ?? Date.distantPast)
        }
    }
    
    /// Calculate total hours worked in current week
    func hoursWorkedCurrentWeek() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let year = calendar.component(.year, from: now)
        
        guard let timeEntries = self.timeClockEntries?.allObjects as? [TimeClock] else {
            return 0.0
        }
        
        return timeEntries
            .filter { entry in
                entry.weekNumber == weekOfYear && entry.year == year
            }
            .reduce(0.0) { total, entry in
                total + entry.hoursWorked
            }
    }
}

// MARK: - Weekly Summary Structure

/// Structure for worker weekly summary data
struct WorkerWeeklySummary {
    let worker: Worker
    let totalHours: Double
    let workOrders: [WorkOrderSummary]
    let isOvertime: Bool
    let currentWorkOrder: WorkOrder?
    
    var overtimeHours: Double {
        return max(0, totalHours - 40.0)
    }
    
    var regularHours: Double {
        return min(totalHours, 40.0)
    }
}

/// Structure for work order summary data
struct WorkOrderSummary {
    let workOrder: WorkOrder
    let hoursWorked: Double
    let isActive: Bool
    let status: AgricultureWorkStatus
}

// MARK: - Work Order Manager

/// Manager class for work order operations and calculations
class WorkOrderManager {
    
    /// Generate weekly summary for a worker
    static func weeklySummary(for worker: Worker) -> WorkerWeeklySummary {
        let totalHours = worker.hoursWorkedCurrentWeek()
        let workOrders = worker.workOrdersForCurrentWeek()
        let currentWorkOrder = worker.currentTimeClockEntry()?.workOrder
        
        let workOrderSummaries = workOrders.map { workOrder in
            let hoursForThisOrder = calculateHoursForWorkOrder(workOrder, worker: worker)
            return WorkOrderSummary(
                workOrder: workOrder,
                hoursWorked: hoursForThisOrder,
                isActive: currentWorkOrder?.id == workOrder.id,
                status: workOrder.agricultureStatus
            )
        }
        
        return WorkerWeeklySummary(
            worker: worker,
            totalHours: totalHours,
            workOrders: workOrderSummaries,
            isOvertime: totalHours > 40.0,
            currentWorkOrder: currentWorkOrder
        )
    }
    
    /// Calculate hours worked by a specific worker on a specific work order for current week
    private static func calculateHoursForWorkOrder(_ workOrder: WorkOrder, worker: Worker) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let year = calendar.component(.year, from: now)
        
        guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else {
            return 0.0
        }
        
        return timeEntries
            .filter { entry in
                entry.weekNumber == weekOfYear && 
                entry.year == year && 
                entry.workOrder?.id == workOrder.id
            }
            .reduce(0.0) { total, entry in
                total + entry.hoursWorked
            }
    }
    
    /// Get all workers with their weekly summaries
    static func allWorkerWeeklySummaries(context: NSManagedObjectContext) -> [WorkerWeeklySummary] {
        let request: NSFetchRequest<Worker> = Worker.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Worker.name, ascending: true)]
        
        do {
            let workers = try context.fetch(request)
            return workers.map { weeklySummary(for: $0) }
        } catch {
            print("Error fetching workers for weekly summary: \(error)")
            return []
        }
    }
}