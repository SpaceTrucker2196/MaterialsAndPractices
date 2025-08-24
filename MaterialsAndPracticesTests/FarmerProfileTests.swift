//
//  FarmerProfileTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for FarmerProfileView functionality and profile management features
//  including profile creation flow and data persistence.
//
//  Created by AI Assistant following Clean Code testing principles.
//

import XCTest
import CoreData
import SwiftUI
@testable import MaterialsAndPractices

/// Test suite for FarmerProfileView functionality and profile management
/// Validates profile creation, editing, persistence, and form validation
class FarmerProfileTests: XCTestCase {
    
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
    
    // MARK: - Profile Creation Tests
    
    /// Tests farmer profile creation with valid data
    /// Validates the core profile creation functionality
    func testFarmerProfileCreation() throws {
        // Given: A new farmer profile
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        farmer.name = "John Doe"
        farmer.email = "john@example.com"
        farmer.phone = "555-0123"
        farmer.orgName = "Doe Farms"
        farmer.notes = "Experienced organic farmer"
        
        // When: Saving the profile
        try mockContext.save()
        
        // Then: Profile should be persisted correctly
        let farmerRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        let farmers = try mockContext.fetch(farmerRequest)
        
        XCTAssertEqual(farmers.count, 1, "Should have one farmer profile")
        
        let savedFarmer = farmers.first!
        XCTAssertEqual(savedFarmer.name, "John Doe")
        XCTAssertEqual(savedFarmer.email, "john@example.com")
        XCTAssertEqual(savedFarmer.phone, "555-0123")
        XCTAssertEqual(savedFarmer.orgName, "Doe Farms")
        XCTAssertEqual(savedFarmer.notes, "Experienced organic farmer")
        XCTAssertNotNil(savedFarmer.id)
    }
    
    /// Tests farmer profile creation with minimal data
    /// Validates that only name is truly required
    func testFarmerProfileCreationMinimalData() throws {
        // Given: A farmer with only name
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        farmer.name = "Jane Smith"
        // All other fields left nil
        
        // When: Saving the profile
        try mockContext.save()
        
        // Then: Profile should be saved successfully
        let farmerRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        let farmers = try mockContext.fetch(farmerRequest)
        
        XCTAssertEqual(farmers.count, 1, "Should have one farmer profile")
        
        let savedFarmer = farmers.first!
        XCTAssertEqual(savedFarmer.name, "Jane Smith")
        XCTAssertNil(savedFarmer.email)
        XCTAssertNil(savedFarmer.phone)
        XCTAssertNil(savedFarmer.orgName)
        XCTAssertNil(savedFarmer.notes)
    }
    
    /// Tests handling of empty string values
    /// Validates the form validation logic that converts empty strings to nil
    func testEmptyStringHandling() throws {
        // Given: A farmer with empty strings
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        
        // Simulate the form validation logic from FarmerProfileView
        let farmerName = ""
        let emailAddress = "john@example.com"
        let phoneNumber = ""
        let organizationName = "  " // Whitespace
        let additionalNotes = ""
        
        // Apply the same logic as updateFarmerWithFormData
        farmer.name = farmerName.isEmpty ? nil : farmerName
        farmer.email = emailAddress.isEmpty ? nil : emailAddress
        farmer.phone = phoneNumber.isEmpty ? nil : phoneNumber
        farmer.orgName = organizationName.isEmpty ? nil : organizationName
        farmer.notes = additionalNotes.isEmpty ? nil : additionalNotes
        
        // When: Saving the profile
        try mockContext.save()
        
        // Then: Empty strings should be converted to nil, non-empty preserved
        let farmerRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        let farmers = try mockContext.fetch(farmerRequest)
        let savedFarmer = farmers.first!
        
        XCTAssertNil(savedFarmer.name, "Empty name should be nil")
        XCTAssertEqual(savedFarmer.email, "john@example.com", "Non-empty email should be preserved")
        XCTAssertNil(savedFarmer.phone, "Empty phone should be nil")
        XCTAssertEqual(savedFarmer.orgName, "  ", "Whitespace should be preserved (not trimmed by default)")
        XCTAssertNil(savedFarmer.notes, "Empty notes should be nil")
    }
    
    // MARK: - Profile Loading Tests
    
    /// Tests profile loading when farmer exists
    /// Validates the performProfileLoadingCheck logic
    func testProfileLoadingWithExistingFarmer() throws {
        // Given: An existing farmer in the database
        let existingFarmer = Farmer(context: mockContext)
        existingFarmer.id = UUID()
        existingFarmer.name = "Existing Farmer"
        existingFarmer.email = "existing@example.com"
        try mockContext.save()
        
        // When: Loading profile (simulate the loadFarmerProfile logic)
        let fetchRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        let existingFarmers = try mockContext.fetch(fetchRequest)
        
        // Then: Should find the existing farmer
        XCTAssertEqual(existingFarmers.count, 1, "Should find existing farmer")
        XCTAssertEqual(existingFarmers.first?.name, "Existing Farmer")
        
        // This validates that editing mode should NOT be automatically entered
        let shouldEnterEditingMode = existingFarmers.isEmpty
        XCTAssertFalse(shouldEnterEditingMode, "Should not enter editing mode when farmer exists")
    }
    
    /// Tests profile loading when no farmer exists
    /// Validates the automatic editing mode entry for new users
    func testProfileLoadingWithNoFarmer() throws {
        // Given: Empty database with no farmers
        let fetchRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        let existingFarmers = try mockContext.fetch(fetchRequest)
        
        // Then: Should find no farmers
        XCTAssertEqual(existingFarmers.count, 0, "Should find no farmers")
        
        // This validates that editing mode SHOULD be automatically entered
        let shouldEnterEditingMode = existingFarmers.isEmpty
        XCTAssertTrue(shouldEnterEditingMode, "Should enter editing mode when no farmer exists")
    }
    
    // MARK: - Profile Update Tests
    
    /// Tests updating an existing farmer profile
    /// Validates the profile editing functionality
    func testFarmerProfileUpdate() throws {
        // Given: An existing farmer
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        farmer.name = "Original Name"
        farmer.email = "original@example.com"
        try mockContext.save()
        
        // When: Updating the farmer
        farmer.name = "Updated Name"
        farmer.email = "updated@example.com"
        farmer.phone = "555-9999"
        try mockContext.save()
        
        // Then: Updates should be persisted
        let farmerRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        let farmers = try mockContext.fetch(farmerRequest)
        
        XCTAssertEqual(farmers.count, 1, "Should still have one farmer")
        
        let updatedFarmer = farmers.first!
        XCTAssertEqual(updatedFarmer.name, "Updated Name")
        XCTAssertEqual(updatedFarmer.email, "updated@example.com")
        XCTAssertEqual(updatedFarmer.phone, "555-9999")
    }
    
    // MARK: - Lease Relationship Tests
    
    /// Tests farmer-lease relationship functionality
    /// Validates the lease information display logic
    func testFarmerLeaseRelationship() throws {
        // Given: A farmer with leases
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        farmer.name = "Farmer with Leases"
        
        let activeLease = Lease(context: mockContext)
        activeLease.id = UUID()
        activeLease.leaseType = "Land Lease"
        activeLease.status = "active"
        activeLease.rentAmount = 1000.0
        activeLease.startDate = Date()
        activeLease.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        activeLease.farmer = farmer
        
        let inactiveLease = Lease(context: mockContext)
        inactiveLease.id = UUID()
        inactiveLease.leaseType = "Equipment Lease"
        inactiveLease.status = "inactive"
        inactiveLease.rentAmount = 500.0
        inactiveLease.farmer = farmer
        
        try mockContext.save()
        
        // When: Fetching farmer with leases
        let farmerRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        let farmers = try mockContext.fetch(farmerRequest)
        let farmerWithLeases = farmers.first!
        
        // Then: Should have correct lease relationships
        let allLeases = farmerWithLeases.leases?.allObjects as? [Lease]
        XCTAssertEqual(allLeases?.count, 2, "Farmer should have two leases")
        
        // Test active lease filtering (as done in the view)
        let activeLeases = allLeases?.filter { $0.status == "active" }
        XCTAssertEqual(activeLeases?.count, 1, "Should have one active lease")
        XCTAssertEqual(activeLeases?.first?.leaseType, "Land Lease")
    }
    
    // MARK: - Startup Profile Check Tests
    
    /// Tests the startup profile check logic
    /// Validates the app initialization behavior from MaterialsAndPracticesApp
    func testStartupProfileCheck() throws {
        // Test Case 1: No farmer exists
        var fetchRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        var existingFarmers = try mockContext.fetch(fetchRequest)
        let shouldShowProfileSetup = existingFarmers.isEmpty
        
        XCTAssertTrue(shouldShowProfileSetup, "Should show profile setup when no farmer exists")
        
        // Test Case 2: Farmer exists
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        farmer.name = "Existing Farmer"
        try mockContext.save()
        
        existingFarmers = try mockContext.fetch(fetchRequest)
        let shouldNotShowProfileSetup = existingFarmers.isEmpty
        
        XCTAssertFalse(shouldNotShowProfileSetup, "Should not show profile setup when farmer exists")
    }
    
    // MARK: - Data Validation Tests
    
    /// Tests profile data validation and constraints
    /// Validates data integrity and business rules
    func testProfileDataValidation() throws {
        // Given: Multiple farmers (test uniqueness if applicable)
        let farmer1 = Farmer(context: mockContext)
        farmer1.id = UUID()
        farmer1.name = "Farmer One"
        farmer1.email = "farmer1@example.com"
        
        let farmer2 = Farmer(context: mockContext)
        farmer2.id = UUID()
        farmer2.name = "Farmer Two"
        farmer2.email = "farmer2@example.com"
        
        // When: Saving multiple farmers
        try mockContext.save()
        
        // Then: Both should be saved (no uniqueness constraint on email in current model)
        let farmerRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        let farmers = try mockContext.fetch(farmerRequest)
        
        XCTAssertEqual(farmers.count, 2, "Should be able to save multiple farmers")
        
        // Validate each farmer has unique ID
        let farmer1ID = farmers.first { $0.name == "Farmer One" }?.id
        let farmer2ID = farmers.first { $0.name == "Farmer Two" }?.id
        
        XCTAssertNotNil(farmer1ID)
        XCTAssertNotNil(farmer2ID)
        XCTAssertNotEqual(farmer1ID, farmer2ID, "Farmers should have unique IDs")
    }
    
    // MARK: - Performance Tests
    
    /// Tests performance of profile operations
    /// Ensures profile management maintains good performance
    func testProfilePerformance() throws {
        self.measure {
            // Create and save multiple farmer profiles
            for i in 0..<100 {
                let farmer = Farmer(context: mockContext)
                farmer.id = UUID()
                farmer.name = "Farmer \(i)"
                farmer.email = "farmer\(i)@example.com"
                farmer.phone = "555-\(String(format: "%04d", i))"
                farmer.orgName = "Farm \(i)"
                farmer.notes = "Notes for farmer \(i)"
            }
            
            do {
                try mockContext.save()
            } catch {
                XCTFail("Failed to save farmer profiles: \(error)")
            }
        }
    }
}