//
//  CoreDataNotificationCenter.swift
//  MaterialsAndPractices
//
//  Provides Swift standard notification architecture for Core Data changes.
//  Ensures all views update properly when data changes throughout the app.
//  Implements observer pattern for real-time data synchronization.
//
//  Created by GitHub Copilot on 12/19/24.
//

import Foundation
import CoreData
import Combine

/// Core Data notification center for real-time view updates
/// Provides standardized notifications for entity changes across the app
class CoreDataNotificationCenter: ObservableObject {
    // MARK: - Singleton
    
    static let shared = CoreDataNotificationCenter()
    
    // MARK: - Notification Names
    
    extension Notification.Name {
        static let workOrderCreated = Notification.Name("workOrderCreated")
        static let workOrderUpdated = Notification.Name("workOrderUpdated")
        static let workOrderDeleted = Notification.Name("workOrderDeleted")
        
        static let infrastructureCreated = Notification.Name("infrastructureCreated")
        static let infrastructureUpdated = Notification.Name("infrastructureUpdated")
        static let infrastructureDeleted = Notification.Name("infrastructureDeleted")
        
        static let workerCreated = Notification.Name("workerCreated")
        static let workerUpdated = Notification.Name("workerUpdated")
        static let workerDeleted = Notification.Name("workerDeleted")
        
        static let teamCreated = Notification.Name("teamCreated")
        static let teamUpdated = Notification.Name("teamUpdated")
        static let teamDeleted = Notification.Name("teamDeleted")
        
        static let growCreated = Notification.Name("growCreated")
        static let growUpdated = Notification.Name("growUpdated")
        static let growDeleted = Notification.Name("growDeleted")
        
        static let farmCreated = Notification.Name("farmCreated")
        static let farmUpdated = Notification.Name("farmUpdated")
        static let farmDeleted = Notification.Name("farmDeleted")
    }
    
    // MARK: - Published Properties for Combine
    
    @Published var lastWorkOrderUpdate = Date()
    @Published var lastInfrastructureUpdate = Date()
    @Published var lastWorkerUpdate = Date()
    @Published var lastTeamUpdate = Date()
    @Published var lastGrowUpdate = Date()
    @Published var lastFarmUpdate = Date()
    
    // MARK: - Private Properties
    
    private var notificationObservers: [NSObjectProtocol] = []
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        removeNotificationObservers()
    }
    
    // MARK: - Notification Setup
    
    /// Set up observers for all Core Data entity notifications
    private func setupNotificationObservers() {
        // Work Order notifications
        let workOrderCreatedObserver = NotificationCenter.default.addObserver(
            forName: .workOrderCreated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWorkOrderUpdate = Date()
        }
        notificationObservers.append(workOrderCreatedObserver)
        
        let workOrderUpdatedObserver = NotificationCenter.default.addObserver(
            forName: .workOrderUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWorkOrderUpdate = Date()
        }
        notificationObservers.append(workOrderUpdatedObserver)
        
        let workOrderDeletedObserver = NotificationCenter.default.addObserver(
            forName: .workOrderDeleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWorkOrderUpdate = Date()
        }
        notificationObservers.append(workOrderDeletedObserver)
        
        // Infrastructure notifications
        let infrastructureCreatedObserver = NotificationCenter.default.addObserver(
            forName: .infrastructureCreated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastInfrastructureUpdate = Date()
        }
        notificationObservers.append(infrastructureCreatedObserver)
        
        let infrastructureUpdatedObserver = NotificationCenter.default.addObserver(
            forName: .infrastructureUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastInfrastructureUpdate = Date()
        }
        notificationObservers.append(infrastructureUpdatedObserver)
        
        let infrastructureDeletedObserver = NotificationCenter.default.addObserver(
            forName: .infrastructureDeleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastInfrastructureUpdate = Date()
        }
        notificationObservers.append(infrastructureDeletedObserver)
        
        // Worker notifications
        let workerCreatedObserver = NotificationCenter.default.addObserver(
            forName: .workerCreated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWorkerUpdate = Date()
        }
        notificationObservers.append(workerCreatedObserver)
        
        let workerUpdatedObserver = NotificationCenter.default.addObserver(
            forName: .workerUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWorkerUpdate = Date()
        }
        notificationObservers.append(workerUpdatedObserver)
        
        let workerDeletedObserver = NotificationCenter.default.addObserver(
            forName: .workerDeleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastWorkerUpdate = Date()
        }
        notificationObservers.append(workerDeletedObserver)
        
        // Team notifications
        let teamCreatedObserver = NotificationCenter.default.addObserver(
            forName: .teamCreated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastTeamUpdate = Date()
        }
        notificationObservers.append(teamCreatedObserver)
        
        let teamUpdatedObserver = NotificationCenter.default.addObserver(
            forName: .teamUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastTeamUpdate = Date()
        }
        notificationObservers.append(teamUpdatedObserver)
        
        let teamDeletedObserver = NotificationCenter.default.addObserver(
            forName: .teamDeleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastTeamUpdate = Date()
        }
        notificationObservers.append(teamDeletedObserver)
        
        // Grow notifications
        let growCreatedObserver = NotificationCenter.default.addObserver(
            forName: .growCreated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastGrowUpdate = Date()
        }
        notificationObservers.append(growCreatedObserver)
        
        let growUpdatedObserver = NotificationCenter.default.addObserver(
            forName: .growUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastGrowUpdate = Date()
        }
        notificationObservers.append(growUpdatedObserver)
        
        let growDeletedObserver = NotificationCenter.default.addObserver(
            forName: .growDeleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastGrowUpdate = Date()
        }
        notificationObservers.append(growDeletedObserver)
        
        // Farm notifications
        let farmCreatedObserver = NotificationCenter.default.addObserver(
            forName: .farmCreated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastFarmUpdate = Date()
        }
        notificationObservers.append(farmCreatedObserver)
        
        let farmUpdatedObserver = NotificationCenter.default.addObserver(
            forName: .farmUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastFarmUpdate = Date()
        }
        notificationObservers.append(farmUpdatedObserver)
        
        let farmDeletedObserver = NotificationCenter.default.addObserver(
            forName: .farmDeleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.lastFarmUpdate = Date()
        }
        notificationObservers.append(farmDeletedObserver)
    }
    
    /// Remove all notification observers
    private func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
    
    // MARK: - Notification Helper Methods
    
    /// Post notification for work order changes
    static func postWorkOrderNotification(type: EntityChangeType, workOrder: WorkOrder) {
        let notificationName: Notification.Name
        switch type {
        case .created:
            notificationName = .workOrderCreated
        case .updated:
            notificationName = .workOrderUpdated
        case .deleted:
            notificationName = .workOrderDeleted
        }
        
        NotificationCenter.default.post(
            name: notificationName,
            object: workOrder
        )
    }
    
    /// Post notification for infrastructure changes
    static func postInfrastructureNotification(type: EntityChangeType, infrastructure: Infrastructure) {
        let notificationName: Notification.Name
        switch type {
        case .created:
            notificationName = .infrastructureCreated
        case .updated:
            notificationName = .infrastructureUpdated
        case .deleted:
            notificationName = .infrastructureDeleted
        }
        
        NotificationCenter.default.post(
            name: notificationName,
            object: infrastructure
        )
    }
    
    /// Post notification for worker changes
    static func postWorkerNotification(type: EntityChangeType, worker: Worker) {
        let notificationName: Notification.Name
        switch type {
        case .created:
            notificationName = .workerCreated
        case .updated:
            notificationName = .workerUpdated
        case .deleted:
            notificationName = .workerDeleted
        }
        
        NotificationCenter.default.post(
            name: notificationName,
            object: worker
        )
    }
    
    /// Post notification for team changes
    static func postTeamNotification(type: EntityChangeType, team: WorkTeam) {
        let notificationName: Notification.Name
        switch type {
        case .created:
            notificationName = .teamCreated
        case .updated:
            notificationName = .teamUpdated
        case .deleted:
            notificationName = .teamDeleted
        }
        
        NotificationCenter.default.post(
            name: notificationName,
            object: team
        )
    }
    
    /// Post notification for grow changes
    static func postGrowNotification(type: EntityChangeType, grow: Grow) {
        let notificationName: Notification.Name
        switch type {
        case .created:
            notificationName = .growCreated
        case .updated:
            notificationName = .growUpdated
        case .deleted:
            notificationName = .growDeleted
        }
        
        NotificationCenter.default.post(
            name: notificationName,
            object: grow
        )
    }
    
    /// Post notification for farm changes
    static func postFarmNotification(type: EntityChangeType, farm: Property) {
        let notificationName: Notification.Name
        switch type {
        case .created:
            notificationName = .farmCreated
        case .updated:
            notificationName = .farmUpdated
        case .deleted:
            notificationName = .farmDeleted
        }
        
        NotificationCenter.default.post(
            name: notificationName,
            object: farm
        )
    }
}

// MARK: - Entity Change Type

/// Enumeration of entity change types for notification system
enum EntityChangeType {
    case created
    case updated
    case deleted
}

// MARK: - SwiftUI View Extension

/// Extension to add notification observation capabilities to SwiftUI views
extension View {
    /// Observe Core Data changes for automatic view updates
    func observeCoreDataChanges() -> some View {
        self.environmentObject(CoreDataNotificationCenter.shared)
    }
}