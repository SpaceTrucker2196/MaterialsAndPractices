
import Foundation
import CoreData
import Combine
import SwiftUI

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

// MARK: - Entity Change Type

/// Represents the type of Core Data change (create, update, delete)
enum EntityChangeType {
    case created, updated, deleted
    
    func notificationName(prefix: String) -> Notification.Name {
        switch self {
        case .created: return Notification.Name("\(prefix)Created")
        case .updated: return Notification.Name("\(prefix)Updated")
        case .deleted: return Notification.Name("\(prefix)Deleted")
        }
    }
}

// MARK: - CoreDataNotificationCenter

/// Centralized Core Data event broadcaster with Notification and Combine support.
class CoreDataNotificationCenter: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CoreDataNotificationCenter()
    
    // MARK: - Published update timestamps (for SwiftUI Views)
    
    @Published var lastWorkOrderUpdate = Date()
    @Published var lastInfrastructureUpdate = Date()
    @Published var lastWorkerUpdate = Date()
    @Published var lastTeamUpdate = Date()
    @Published var lastGrowUpdate = Date()
    @Published var lastFarmUpdate = Date()
    
    // MARK: - Combine Subjects for Real-Time Streaming
    
    /// Publisher for WorkOrder changes (type, instance)
    let workOrderPublisher = PassthroughSubject<(EntityChangeType, WorkOrder), Never>()
    
    /// Publisher for Infrastructure changes (type, instance)
    let infrastructurePublisher = PassthroughSubject<(EntityChangeType, Infrastructure), Never>()
    
    /// Publisher for Worker changes
    let workerPublisher = PassthroughSubject<(EntityChangeType, Worker), Never>()
    
    /// Publisher for Team changes
    let teamPublisher = PassthroughSubject<(EntityChangeType, WorkTeam), Never>()
    
    /// Publisher for Grow changes
    let growPublisher = PassthroughSubject<(EntityChangeType, Grow), Never>()
    
    /// Publisher for Farm changes
    let farmPublisher = PassthroughSubject<(EntityChangeType, Property), Never>()
    
    // MARK: - Private
    
    private var notificationObservers: [NSObjectProtocol] = []
    
    // MARK: - Init
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        removeNotificationObservers()
    }
    
    // MARK: - Notification Observation Setup
    
    private func setupNotificationObservers() {
        observe(name: .workOrderCreated) { self.lastWorkOrderUpdate = Date() }
        observe(name: .workOrderUpdated) { self.lastWorkOrderUpdate = Date() }
        observe(name: .workOrderDeleted) { self.lastWorkOrderUpdate = Date() }
        
        observe(name: .infrastructureCreated) { self.lastInfrastructureUpdate = Date() }
        observe(name: .infrastructureUpdated) { self.lastInfrastructureUpdate = Date() }
        observe(name: .infrastructureDeleted) { self.lastInfrastructureUpdate = Date() }
        
        observe(name: .workerCreated) { self.lastWorkerUpdate = Date() }
        observe(name: .workerUpdated) { self.lastWorkerUpdate = Date() }
        observe(name: .workerDeleted) { self.lastWorkerUpdate = Date() }
        
        observe(name: .teamCreated) { self.lastTeamUpdate = Date() }
        observe(name: .teamUpdated) { self.lastTeamUpdate = Date() }
        observe(name: .teamDeleted) { self.lastTeamUpdate = Date() }
        
        observe(name: .growCreated) { self.lastGrowUpdate = Date() }
        observe(name: .growUpdated) { self.lastGrowUpdate = Date() }
        observe(name: .growDeleted) { self.lastGrowUpdate = Date() }
        
        observe(name: .farmCreated) { self.lastFarmUpdate = Date() }
        observe(name: .farmUpdated) { self.lastFarmUpdate = Date() }
        observe(name: .farmDeleted) { self.lastFarmUpdate = Date() }
    }
    
    private func observe(name: Notification.Name, handler: @escaping () -> Void) {
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
            handler()
        }
        notificationObservers.append(observer)
    }
    
    private func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
    
    // MARK: - Posting Notifications (w/ Publishers)
    
    static func postWorkOrderNotification(type: EntityChangeType, workOrder: WorkOrder) {
        NotificationCenter.default.post(name: type.notificationName(prefix: "workOrder"), object: workOrder)
        shared.workOrderPublisher.send((type, workOrder))
    }
    
    static func postInfrastructureNotification(type: EntityChangeType, infrastructure: Infrastructure) {
        NotificationCenter.default.post(name: type.notificationName(prefix: "infrastructure"), object: infrastructure)
        shared.infrastructurePublisher.send((type, infrastructure))
    }
    
    static func postWorkerNotification(type: EntityChangeType, worker: Worker) {
        NotificationCenter.default.post(name: type.notificationName(prefix: "worker"), object: worker)
        shared.workerPublisher.send((type, worker))
    }
    
    static func postTeamNotification(type: EntityChangeType, team: WorkTeam) {
        NotificationCenter.default.post(name: type.notificationName(prefix: "team"), object: team)
        shared.teamPublisher.send((type, team))
    }
    
    static func postGrowNotification(type: EntityChangeType, grow: Grow) {
        NotificationCenter.default.post(name: type.notificationName(prefix: "grow"), object: grow)
        shared.growPublisher.send((type, grow))
    }
    
    static func postFarmNotification(type: EntityChangeType, farm: Property) {
        NotificationCenter.default.post(name: type.notificationName(prefix: "farm"), object: farm)
        shared.farmPublisher.send((type, farm))
    }
}

// MARK: - SwiftUI Extension for Observability

extension View {
    /// Attach Core Data updates to this view via environment
    func observeCoreDataChanges() -> some View {
        self.environmentObject(CoreDataNotificationCenter.shared)
    }
}
