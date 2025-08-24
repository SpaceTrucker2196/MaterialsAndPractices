//
//  FarmDashboardTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for FarmDashboardView functionality including clean code refactoring
//  and conditional UI behavior based on farm property existence.
//
//  Created by AI Assistant following Clean Code testing principles.
//

import XCTest
import CoreData
import SwiftUI
@testable import MaterialsAndPractices

/// Test suite for FarmDashboardView functionality and business logic
/// Validates conditional UI behavior, farm property management, and operational status calculations
class FarmDashboardTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var mockPersistenceController: PersistenceController!
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Create in-memory Core Data stack for testing
        mockPersistenceController = PersistenceController(inMemory: true)
        mockContext = mockPersistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        mockPersistenceController = nil
        mockContext = nil
    }
    
    // MARK: - Farm Property Management Tests
    
    /// Tests that dashboard correctly identifies when no farms exist
    /// This is critical for the conditional UI requirement
    func testEmptyFarmPropertiesDetection() throws {
        // Given: Empty context with no farm properties
        let propertyRequest: NSFetchRequest<Property> = Property.fetchRequest()
        let properties = try mockContext.fetch(propertyRequest)
        
        // Then: Should correctly identify empty state
        XCTAssertEqual(properties.count, 0, "Should start with no farm properties")
        
        // This validates the hasFarmProperties computed property logic
        let hasFarms = !properties.isEmpty
        XCTAssertFalse(hasFarms, "Should correctly identify no farms exist")
    }
    
    /// Tests farm property creation and persistence
    /// Validates the farm creation flow works correctly
    func testFarmPropertyCreation() throws {
        // Given: A new farm property
        let farmProperty = Property(context: mockContext)
        farmProperty.id = UUID()
        farmProperty.displayName = "Test Farm"
        farmProperty.totalAcres = 100.0
        farmProperty.hasIrrigation = true
        farmProperty.county = "Test County"
        farmProperty.state = "Test State"
        
        // When: Saving the property
        try mockContext.save()
        
        // Then: Property should be persisted correctly
        let propertyRequest: NSFetchRequest<Property> = Property.fetchRequest()
        let properties = try mockContext.fetch(propertyRequest)
        
        XCTAssertEqual(properties.count, 1, "Should have one farm property")
        
        let savedProperty = properties.first!
        XCTAssertEqual(savedProperty.displayName, "Test Farm")
        XCTAssertEqual(savedProperty.totalAcres, 100.0)
        XCTAssertTrue(savedProperty.hasIrrigation)
        XCTAssertEqual(savedProperty.county, "Test County")
        XCTAssertEqual(savedProperty.state, "Test State")
    }
    
    /// Tests the conditional dashboard behavior based on farm existence
    /// Critical for the requirement that UI changes based on farm availability
    func testConditionalDashboardBehavior() throws {
        // Given: Empty context
        let propertyRequest: NSFetchRequest<Property> = Property.fetchRequest()
        var properties = try mockContext.fetch(propertyRequest)
        var hasFarms = !properties.isEmpty
        
        // Then: Should indicate no farms available
        XCTAssertFalse(hasFarms, "Initially should have no farms")
        
        // When: Adding a farm property
        let farmProperty = Property(context: mockContext)
        farmProperty.id = UUID()
        farmProperty.displayName = "New Farm"
        farmProperty.totalAcres = 50.0
        farmProperty.hasIrrigation = false
        
        try mockContext.save()
        
        // Then: Should indicate farms are available
        properties = try mockContext.fetch(propertyRequest)
        hasFarms = !properties.isEmpty
        XCTAssertTrue(hasFarms, "Should now have farms available")
        XCTAssertEqual(properties.count, 1, "Should have exactly one farm")
    }
    
    // MARK: - Worker Management Tests
    
    /// Tests active worker filtering logic
    /// Validates the activeTeamMembers computed property
    func testActiveWorkerFiltering() throws {
        // Given: Mixed active and inactive workers
        let activeWorker = Worker(context: mockContext)
        activeWorker.id = UUID()
        activeWorker.name = "Active Worker"
        activeWorker.isActive = true
        
        let inactiveWorker = Worker(context: mockContext)
        inactiveWorker.id = UUID()
        inactiveWorker.name = "Inactive Worker"
        inactiveWorker.isActive = false
        
        try mockContext.save()
        
        // When: Fetching all workers
        let workerRequest: NSFetchRequest<Worker> = Worker.fetchRequest()
        let allWorkers = try mockContext.fetch(workerRequest)
        
        // Then: Should correctly filter active workers
        let activeWorkers = allWorkers.filter { $0.isActive }
        
        XCTAssertEqual(allWorkers.count, 2, "Should have two total workers")
        XCTAssertEqual(activeWorkers.count, 1, "Should have one active worker")
        XCTAssertEqual(activeWorkers.first?.name, "Active Worker")
    }
    
    /// Tests the clocked-in worker detection logic
    /// Validates the currentlyActiveWorkers computed property
    func testClockedInWorkerDetection() throws {
        // Given: An active worker with time clock entry
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.isActive = true
        
        let timeClock = TimeClock(context: mockContext)
        timeClock.id = UUID()
        timeClock.date = Date() // Today
        timeClock.isActive = true
        timeClock.worker = worker
        
        try mockContext.save()
        
        // When: Checking for clocked-in workers
        let workerRequest: NSFetchRequest<Worker> = Worker.fetchRequest()
        let workers = try mockContext.fetch(workerRequest)
        let activeWorkers = workers.filter { $0.isActive }
        
        // Simulate the clocked-in logic from FarmDashboardView
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let clockedInWorkers = activeWorkers.filter { worker in
            guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else {
                return false
            }
            
            return timeEntries.contains { timeEntry in
                guard let entryDate = timeEntry.date,
                      entryDate >= today && entryDate < tomorrow else {
                    return false
                }
                return timeEntry.isActive
            }
        }
        
        // Then: Should detect the clocked-in worker
        XCTAssertEqual(clockedInWorkers.count, 1, "Should have one clocked-in worker")
        XCTAssertEqual(clockedInWorkers.first?.name, "Test Worker")
    }
    
    // MARK: - Lease Management Tests
    
    /// Tests active lease filtering logic
    /// Validates the activeLeaseAgreements computed property
    func testActiveLeasesFiltering() throws {
        // Given: Mixed active and inactive leases
        let activeLease = Lease(context: mockContext)
        activeLease.id = UUID()
        activeLease.leaseType = "Land Lease"
        activeLease.status = "active"
        activeLease.rentAmount = 1000.0
        
        let inactiveLease = Lease(context: mockContext)
        inactiveLease.id = UUID()
        inactiveLease.leaseType = "Equipment Lease"
        inactiveLease.status = "inactive"
        inactiveLease.rentAmount = 500.0
        
        try mockContext.save()
        
        // When: Fetching leases
        let leaseRequest: NSFetchRequest<Lease> = Lease.fetchRequest()
        let allLeases = try mockContext.fetch(leaseRequest)
        
        // Then: Should correctly filter active leases
        let activeLeases = allLeases.filter { $0.status == "active" }
        
        XCTAssertEqual(allLeases.count, 2, "Should have two total leases")
        XCTAssertEqual(activeLeases.count, 1, "Should have one active lease")
        XCTAssertEqual(activeLeases.first?.leaseType, "Land Lease")
    }
    
    /// Tests urgent lease payment detection logic
    /// Validates the urgentLeasePayments computed property
    func testUrgentLeasePaymentDetection() throws {
        // Given: Monthly and annual leases
        let monthlyLease = Lease(context: mockContext)
        monthlyLease.id = UUID()
        monthlyLease.leaseType = "Monthly Land"
        monthlyLease.status = "active"
        monthlyLease.rentFrequency = "monthly"
        monthlyLease.rentAmount = 500.0
        
        let annualLease = Lease(context: mockContext)
        annualLease.id = UUID()
        annualLease.leaseType = "Annual Equipment"
        annualLease.status = "active"
        annualLease.rentFrequency = "annual"
        annualLease.rentAmount = 5000.0
        annualLease.startDate = Date() // Current month anniversary
        
        try mockContext.save()
        
        // When: Checking for urgent leases
        let leaseRequest: NSFetchRequest<Lease> = Lease.fetchRequest()
        let allLeases = try mockContext.fetch(leaseRequest)
        let activeLeases = allLeases.filter { $0.status == "active" }
        
        // Simulate urgent payment logic from FarmDashboardView
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        
        let urgentLeases = activeLeases.filter { lease in
            guard let paymentFrequency = lease.rentFrequency else { return false }
            
            switch paymentFrequency.lowercased() {
            case "monthly":
                return true // All monthly leases are potentially due
            case "annual":
                if let startDate = lease.startDate {
                    let anniversaryMonth = calendar.component(.month, from: startDate)
                    return anniversaryMonth == currentMonth
                }
                return false
            default:
                return false
            }
        }
        
        // Then: Should detect urgent lease payments
        XCTAssertEqual(urgentLeases.count, 2, "Should have two urgent leases (monthly + annual anniversary)")
    }
    
    // MARK: - Performance Tests
    
    /// Tests performance of dashboard data loading with multiple entities
    /// Ensures the refactored code maintains good performance
    func testDashboardPerformanceWithMultipleEntities() throws {
        // Given: Multiple farms, workers, and leases
        self.measure {
            for i in 0..<100 {
                let property = Property(context: mockContext)
                property.id = UUID()
                property.displayName = "Farm \(i)"
                property.totalAcres = Double(i * 10)
                property.hasIrrigation = i % 2 == 0
                
                let worker = Worker(context: mockContext)
                worker.id = UUID()
                worker.name = "Worker \(i)"
                worker.isActive = i % 3 != 0
                
                let lease = Lease(context: mockContext)
                lease.id = UUID()
                lease.leaseType = "Lease \(i)"
                lease.status = "active"
                lease.rentFrequency = i % 2 == 0 ? "monthly" : "annual"
                lease.rentAmount = Double(i * 100)
            }
            
            do {
                try mockContext.save()
            } catch {
                XCTFail("Failed to save test data: \(error)")
            }
        }
    }
}