//
//  WorkOrder+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Core Data class for WorkOrder entity.
//  Provides business logic for task management with team assignment and completion tracking.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

@objc(WorkOrder)
public class WorkOrder: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Display name for the work order
    var displayName: String {
        return title ?? "Untitled Work Order"
    }
    
    /// Check if work order is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return Date() > dueDate
    }
    
    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard let workItems = workItems?.allObjects as? [Work] else { return 0.0 }
        guard !workItems.isEmpty else { return 0.0 }
        
        let completedItems = workItems.filter { $0.isCompleted }
        return Double(completedItems.count) / Double(workItems.count)
    }
    
    /// Array of assigned workers (from team)
    func assignedWorkers() -> Set<Worker> {
        guard let team = assignedTeam,
              let members = team.members as? Set<Worker> else {
            return Set<Worker>()
        }
        return members
    }
    
    /// Priority level as enum
    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium" 
        case high = "High"
        case urgent = "Urgent"
        
        var sortOrder: Int {
            switch self {
            case .urgent: return 0
            case .high: return 1
            case .medium: return 2
            case .low: return 3
            }
        }
    }
    
    var priorityLevel: Priority {
        get { Priority(rawValue: priority ?? "Medium") ?? .medium }
        set { priority = newValue.rawValue }
    }
    
    /// Status as enum
    enum Status: String, CaseIterable {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
    
    var statusLevel: Status {
        get { Status(rawValue: status ?? "Pending") ?? .pending }
        set { status = newValue.rawValue }
    }
    
    // MARK: - Factory Methods
    
    /// Creates a new work order with default values
    /// - Parameters:
    ///   - title: Work order title
    ///   - context: Core Data managed object context
    /// - Returns: New WorkOrder instance
    static func create(title: String, in context: NSManagedObjectContext) -> WorkOrder {
        let workOrder = WorkOrder(context: context)
        workOrder.id = UUID()
        workOrder.title = title
        workOrder.createdDate = Date()
        workOrder.isCompleted = false
        workOrder.priorityLevel = .medium
        workOrder.statusLevel = .pending
        return workOrder
    }
    
    /// Creates a work order for harvest operations
    /// - Parameters:
    ///   - grow: The grow being harvested
    ///   - context: Core Data managed object context
    /// - Returns: New WorkOrder for harvest
    static func createForHarvest(_ grow: Grow, in context: NSManagedObjectContext) -> WorkOrder {
        let workOrder = create(title: "Harvest \(grow.displayName)", in: context)
        workOrder.grow = grow
        workOrder.priorityLevel = .high
        workOrder.notes = "Harvest operations for \(grow.displayName)"
        
        if let estimatedDate = grow.estimatedHarvestDate {
            workOrder.dueDate = estimatedDate
        }
        
        return workOrder
    }
    
    // MARK: - Fetch Requests
    
    /// Fetch request sorted by priority and due date
    static func fetchRequestSortedByPriority() -> NSFetchRequest<WorkOrder> {
        let request: NSFetchRequest<WorkOrder> = fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WorkOrder.priority, ascending: true),
            NSSortDescriptor(keyPath: \WorkOrder.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \WorkOrder.createdDate, ascending: false)
        ]
        return request
    }
    
    /// Fetch request for active work orders (not completed)
    static func fetchRequestActiveOnly() -> NSFetchRequest<WorkOrder> {
        let request = fetchRequestSortedByPriority()
        request.predicate = NSPredicate(format: "isCompleted == false")
        return request
    }
    
    /// Fetch request for work orders created in the last 3 years
    static func fetchRequestRecentThreeYears() -> NSFetchRequest<WorkOrder> {
        let request = fetchRequestSortedByPriority()
        let threeYearsAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "createdDate >= %@", threeYearsAgo as NSDate)
        return request
    }
    
    /// Fetch request for work orders with amendments
    static func fetchRequestWithAmendments() -> NSFetchRequest<WorkOrder> {
        let request = fetchRequestSortedByPriority()
        request.predicate = NSPredicate(format: "amendment != nil")
        return request
    }
}