//
//  LeaseWorkflowTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for the lease workflow system including directory management,
//  template seeding, and payment tracking functionality.
//
//  Created by GitHub Copilot on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class LeaseWorkflowTests: XCTestCase {
    
    var mockContext: NSManagedObjectContext!
    var leaseDirectoryManager: LeaseDirectoryManager!
    var leaseTemplateSeeder: LeaseTemplateSeeder!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack
        let persistentContainer = NSPersistentContainer(name: "MaterialsAndPractices")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        mockContext = persistentContainer.viewContext
        leaseDirectoryManager = LeaseDirectoryManager.shared
        leaseTemplateSeeder = LeaseTemplateSeeder()
    }
    
    override func tearDownWithError() throws {
        mockContext = nil
        leaseDirectoryManager = nil
        leaseTemplateSeeder = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Directory Management Tests
    
    /// Tests that lease directory structure is created properly
    func testLeaseDirectoryCreation() throws {
        // Given: A fresh directory manager
        let directoryManager = LeaseDirectoryManager.shared
        
        // When: Accessing directory URLs
        let templatesURL = directoryManager.directoryURL(for: .templates)
        let workingURL = directoryManager.directoryURL(for: .working)
        let completedURL = directoryManager.directoryURL(for: .completed)
        
        // Then: All directories should exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: templatesURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: workingURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: completedURL.path))
    }
    
    /// Tests template seeding functionality
    func testTemplateSeeding() throws {
        // Given: A fresh template seeder
        leaseTemplateSeeder.seedTemplatesIfNeeded()
        
        // When: Listing available templates
        let availableTemplates = leaseDirectoryManager.listFiles(in: .templates)
        
        // Then: Should have the expected templates
        XCTAssertGreaterThan(availableTemplates.count, 0, "Should have seeded templates")
        XCTAssertTrue(availableTemplates.contains("Cash_Rent_Agricultural_Lease"))
        XCTAssertTrue(availableTemplates.contains("Crop_Share_Agricultural_Lease"))
        XCTAssertTrue(availableTemplates.contains("Pasture_Grazing_Lease"))
    }
    
    // MARK: - Lease Creation Tests
    
    /// Tests lease creation workflow
    func testLeaseCreationWorkflow() throws {
        // Given: Seeded templates and sample data
        leaseTemplateSeeder.seedTemplatesIfNeeded()
        
        let property = Property(context: mockContext)
        property.id = UUID()
        property.displayName = "Test Farm"
        
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        farmer.name = "Test Farmer"
        
        try mockContext.save()
        
        // When: Creating lease data
        let leaseData = LeaseCreationData(
            leaseId: UUID(),
            propertyName: "Test Farm",
            farmerName: "Test Farmer",
            growingYear: 2024,
            leaseType: "cash",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            rentAmount: NSDecimalNumber(value: 5000.0).decimalValue,
            rentFrequency: "annual"
        )
        
        // Then: Should be able to create lease data structure
        XCTAssertEqual(leaseData.propertyName, "Test Farm")
        XCTAssertEqual(leaseData.farmerName, "Test Farmer")
        XCTAssertEqual(leaseData.growingYear, 2024)
        XCTAssertEqual(leaseData.leaseType, "cash")
    }
    
    // MARK: - Payment Tracking Tests
    
    /// Tests payment calculation for different frequencies
    func testPaymentCalculation() throws {
        // Given: A lease with monthly payments
        let lease = Lease(context: mockContext)
        lease.id = UUID()
        lease.rentAmount = NSDecimalNumber(value: 12000.0) // $12,000 annual
        lease.rentFrequency = "monthly"
        lease.startDate = Date()
        lease.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        lease.status = "active"
        
        try mockContext.save()
        
        // When: Calculating upcoming payments
        let upcomingPayments = LeasePaymentTracker.upcomingPayments(for: [lease], within: 365)
        
        // Then: Should calculate monthly payments correctly
        XCTAssertGreaterThan(upcomingPayments.count, 0, "Should have upcoming payments")
        
        // Check that monthly payments are $1,000 each
        let monthlyPayments = upcomingPayments.filter { $0.frequency == .monthly }
        for payment in monthlyPayments.prefix(3) {
            XCTAssertEqual(payment.amount.doubleValue, 1000.0, accuracy: 0.01)
        }
    }
    
    /// Tests lease coverage checking for properties
    func testLeaseCoverageDetection() throws {
        // Given: A property with an active lease
        let property = Property(context: mockContext)
        property.id = UUID()
        property.displayName = "Covered Property"
        
        let lease = Lease(context: mockContext)
        lease.id = UUID()
        lease.property = property
        lease.status = "active"
        lease.startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())
        lease.endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())
        
        try mockContext.save()
        
        // When: Checking lease coverage
        let hasCoverage = LeasePaymentTracker.hasActiveLeaseCoverage(property: property, context: mockContext)
        
        // Then: Should detect active coverage
        XCTAssertTrue(hasCoverage, "Property should have active lease coverage")
    }
    
    /// Tests lease coverage checking for properties without leases
    func testNoLeaseCoverageDetection() throws {
        // Given: A property without active leases
        let property = Property(context: mockContext)
        property.id = UUID()
        property.displayName = "Uncovered Property"
        
        try mockContext.save()
        
        // When: Checking lease coverage
        let hasCoverage = LeasePaymentTracker.hasActiveLeaseCoverage(property: property, context: mockContext)
        
        // Then: Should detect no coverage
        XCTAssertFalse(hasCoverage, "Property should not have active lease coverage")
    }
    
    // MARK: - Template Content Tests
    
    /// Tests that cash rent template contains expected sections
    func testCashRentTemplateContent() throws {
        // Given: Seeded templates
        leaseTemplateSeeder.seedTemplatesIfNeeded()
        
        // When: Reading cash rent template
        let templateURL = leaseDirectoryManager.directoryURL(for: .templates)
            .appendingPathComponent("Cash_Rent_Agricultural_Lease.md")
        
        guard FileManager.default.fileExists(atPath: templateURL.path) else {
            XCTFail("Cash rent template should exist")
            return
        }
        
        let templateContent = try String(contentsOf: templateURL)
        
        // Then: Should contain expected sections
        XCTAssertTrue(templateContent.contains("# Cash Rent Agricultural Lease Agreement"))
        XCTAssertTrue(templateContent.contains("## Section 1: Parties and Property"))
        XCTAssertTrue(templateContent.contains("## Section 2: Lease Terms"))
        XCTAssertTrue(templateContent.contains("Payment Schedule Tracking"))
        XCTAssertTrue(templateContent.contains("{{growing_year}}"))
        XCTAssertTrue(templateContent.contains("{{property_name}}"))
        XCTAssertTrue(templateContent.contains("{{farmer_name}}"))
    }
    
    /// Tests payment frequency enumeration
    func testPaymentFrequencyTypes() throws {
        // Given: Payment frequency enum
        let frequencies: [PaymentFrequency] = [.monthly, .quarterly, .semiAnnual, .annual]
        
        // When: Getting display names
        let displayNames = frequencies.map { $0.displayName }
        
        // Then: Should have proper display names
        XCTAssertEqual(displayNames, ["Monthly", "Quarterly", "Semi-Annual", "Annual"])
    }
    
    // MARK: - Error Handling Tests
    
    /// Tests error handling for missing templates
    func testMissingTemplateError() throws {
        // Given: A template name that doesn't exist
        let nonExistentTemplate = "NonExistent_Template"
        
        // When/Then: Should throw appropriate error
        XCTAssertThrowsError(try leaseDirectoryManager.copyTemplateToWorking(
            templateName: nonExistentTemplate,
            workingName: "Working_Test"
        )) { error in
            if case LeaseError.templateNotFound(let name) = error {
                XCTAssertEqual(name, nonExistentTemplate)
            } else {
                XCTFail("Should throw templateNotFound error")
            }
        }
    }
}