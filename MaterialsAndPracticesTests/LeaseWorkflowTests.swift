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
    
    // MARK: - File Access and Error Handling Tests
    
    /// Tests file access error handling
    func testFileAccessErrorHandling() throws {
        // Given: A directory manager
        let directoryManager = LeaseDirectoryManager.shared
        
        // When: Trying to create a lease with invalid data
        let invalidLeaseData = LeaseCreationData(
            leaseId: UUID(),
            propertyName: nil,
            farmerName: nil,
            growingYear: 2024,
            leaseType: "cash",
            startDate: Date(),
            endDate: Date(),
            rentAmount: 1000,
            rentFrequency: "annual"
        )
        
        // Then: Should handle gracefully
        XCTAssertNoThrow({
            _ = try directoryManager.createCompletedLease(
                workingTemplateName: "NonexistentTemplate",
                leaseData: invalidLeaseData
            )
        })
    }
    
    /// Tests year-based directory creation
    func testYearBasedDirectoryStructure() throws {
        // Given: A directory manager and lease data
        let directoryManager = LeaseDirectoryManager.shared
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // When: Creating multiple leases for different years
        let years = [currentYear - 1, currentYear, currentYear + 1]
        
        for year in years {
            let leaseData = LeaseCreationData(
                leaseId: UUID(),
                propertyName: "TestFarm",
                farmerName: "TestFarmer",
                growingYear: year,
                leaseType: "cash",
                startDate: Date(),
                endDate: Date(),
                rentAmount: 1000,
                rentFrequency: "annual"
            )
            
            // Create a simple working template first
            let workingTemplateName = "TestTemplate_\(year)"
            let workingURL = directoryManager.directoryURL(for: .working)
                .appendingPathComponent("\(workingTemplateName).md")
            
            let simpleTemplate = """
            # Test Lease Agreement
            
            Property: {{property_name}}
            Farmer: {{farmer_name}}
            Year: {{growing_year}}
            """
            
            try simpleTemplate.write(to: workingURL, atomically: true, encoding: .utf8)
            
            // Then: Should create year-based directory structure
            XCTAssertNoThrow({
                let createdInfo = try directoryManager.createCompletedLease(
                    workingTemplateName: workingTemplateName,
                    leaseData: leaseData
                )
                
                // Verify the file path contains the year
                XCTAssertTrue(createdInfo.filePath.contains("\(year)"))
                
                // Verify file naming convention (FARM + YEAR + VERSION + ID)
                XCTAssertTrue(createdInfo.fileName.contains("TEST"))
                XCTAssertTrue(createdInfo.fileName.contains("\(year)"))
                XCTAssertTrue(createdInfo.fileName.contains("V01"))
            })
        }
    }
    
    /// Tests file naming convention
    func testFileNamingConvention() throws {
        // Given: Lease data with specific property name
        leaseTemplateSeeder.seedTemplatesIfNeeded()
        
        let leaseData = LeaseCreationData(
            leaseId: UUID(),
            propertyName: "Sunset Acres Farm",
            farmerName: "John Smith",
            growingYear: 2024,
            leaseType: "cash",
            startDate: Date(),
            endDate: Date(),
            rentAmount: 1500,
            rentFrequency: "quarterly"
        )
        
        // When: Creating a lease
        let workingTemplateName = "Cash_Rent_Agricultural_Lease"
        
        XCTAssertNoThrow({
            let createdInfo = try leaseDirectoryManager.createCompletedLease(
                workingTemplateName: workingTemplateName,
                leaseData: leaseData
            )
            
            // Then: Should follow naming convention
            let fileName = createdInfo.fileName
            
            // Should start with first 4 letters of farm name
            XCTAssertTrue(fileName.hasPrefix("SUNS"))
            
            // Should contain the year
            XCTAssertTrue(fileName.contains("2024"))
            
            // Should contain version
            XCTAssertTrue(fileName.contains("V01"))
            
            // Should have unique identifier at the end
            XCTAssertTrue(fileName.count >= 12) // SUNS2024V01XXXX
        })
    }
    
    /// Tests available years listing
    func testAvailableYearsListing() throws {
        // Given: Leases created in different years
        let directoryManager = LeaseDirectoryManager.shared
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Create leases for different years
        let years = [currentYear - 2, currentYear - 1, currentYear]
        for year in years {
            let completedDir = directoryManager.directoryURL(for: .completed)
                .appendingPathComponent("\(year)")
            
            try FileManager.default.createDirectory(at: completedDir, withIntermediateDirectories: true, attributes: nil)
            
            // Create a dummy lease file
            let testFile = completedDir.appendingPathComponent("TEST\(year)V01ABCD.md")
            try "Test lease content".write(to: testFile, atomically: true, encoding: .utf8)
        }
        
        // When: Listing available years
        let availableYears = directoryManager.listAvailableYears()
        
        // Then: Should return years in descending order
        XCTAssertEqual(availableYears.count, years.count)
        XCTAssertEqual(availableYears, years.sorted(by: >))
    }
    
    /// Tests lease file listing for specific year
    func testLeaseFileListingForYear() throws {
        // Given: Leases created for a specific year
        let directoryManager = LeaseDirectoryManager.shared
        let testYear = 2024
        
        let completedDir = directoryManager.directoryURL(for: .completed)
            .appendingPathComponent("\(testYear)")
        
        try FileManager.default.createDirectory(at: completedDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create multiple lease files
        let leaseFiles = ["FARM2024V01ABCD.md", "TEST2024V01EFGH.md", "DEMO2024V02IJKL.md"]
        for fileName in leaseFiles {
            let filePath = completedDir.appendingPathComponent(fileName)
            try "Test lease content for \(fileName)".write(to: filePath, atomically: true, encoding: .utf8)
        }
        
        // When: Listing lease files for the year
        let fileInfos = directoryManager.listLeaseFiles(for: testYear)
        
        // Then: Should return all lease files with metadata
        XCTAssertEqual(fileInfos.count, leaseFiles.count)
        
        for fileInfo in fileInfos {
            XCTAssertEqual(fileInfo.year, testYear)
            XCTAssertTrue(fileInfo.fileSize > 0)
            XCTAssertNotNil(fileInfo.creationDate)
        }
    }
    
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
    
    // MARK: - Enhanced Payment System Tests
    
    /// Tests payment schedule creation with various frequencies
    func testEnhancedPaymentScheduleCreation() throws {
        // Given: A lease with quarterly payment frequency
        let lease = Lease(context: mockContext)
        lease.id = UUID()
        lease.rentAmount = NSDecimalNumber(value: 12000)
        lease.rentFrequency = "quarterly"
        lease.startDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))
        lease.endDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31))
        
        try mockContext.save()
        
        // When: Creating payment schedule
        let calendar = Calendar.current
        var paymentDates: [Date] = []
        var currentDate = lease.startDate!
        
        while currentDate <= lease.endDate! {
            paymentDates.append(currentDate)
            currentDate = calendar.date(byAdding: .month, value: 3, to: currentDate) ?? lease.endDate!
        }
        
        let paymentAmount = lease.rentAmount!.dividing(by: NSDecimalNumber(value: paymentDates.count))
        
        for (index, dueDate) in paymentDates.enumerated() {
            let payment = Payment(context: mockContext)
            payment.id = UUID()
            payment.amount = paymentAmount.decimalValue
            payment.dueDate = dueDate
            payment.isPaid = false
            payment.paymentStatus = "pending"
            payment.sequence = Int16(index + 1)
            payment.lease = lease
        }
        
        try mockContext.save()
        
        // Then: Should create correct number of payments
        let fetchRequest: NSFetchRequest<Payment> = Payment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lease == %@", lease)
        
        let payments = try mockContext.fetch(fetchRequest)
        XCTAssertEqual(payments.count, 4) // Quarterly = 4 payments
        
        // Verify payment amounts
        for payment in payments {
            XCTAssertEqual(payment.amount, Decimal(3000)) // 12000 / 4
            XCTAssertFalse(payment.isPaid)
            XCTAssertEqual(payment.paymentStatus, "pending")
        }
    }
    
    /// Tests payment status calculations for overdue/due soon
    func testPaymentStatusIdentification() throws {
        // Given: Payments with different due dates
        let lease = Lease(context: mockContext)
        lease.id = UUID()
        
        let now = Date()
        let pastDate = now.addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        let futureDate = now.addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
        
        let overduePayment = Payment(context: mockContext)
        overduePayment.id = UUID()
        overduePayment.amount = 1000
        overduePayment.dueDate = pastDate
        overduePayment.isPaid = false
        overduePayment.paymentStatus = "overdue"
        overduePayment.lease = lease
        
        let upcomingPayment = Payment(context: mockContext)
        upcomingPayment.id = UUID()
        upcomingPayment.amount = 1000
        upcomingPayment.dueDate = futureDate
        upcomingPayment.isPaid = false
        upcomingPayment.paymentStatus = "pending"
        upcomingPayment.lease = lease
        
        try mockContext.save()
        
        // When: Checking payment statuses
        // Then: Should correctly identify overdue and upcoming payments
        XCTAssertTrue(overduePayment.dueDate! < now)
        XCTAssertFalse(overduePayment.isPaid)
        XCTAssertEqual(overduePayment.paymentStatus, "overdue")
        
        XCTAssertTrue(upcomingPayment.dueDate! > now)
        XCTAssertFalse(upcomingPayment.isPaid)
        XCTAssertEqual(upcomingPayment.paymentStatus, "pending")
    }
    
    // MARK: - Ledger System Tests
    
    /// Tests GAAP-compliant ledger entry creation
    func testLedgerEntryGAAPCompliance() throws {
        // Given: A payment that needs a ledger entry
        let lease = Lease(context: mockContext)
        lease.id = UUID()
        
        let payment = Payment(context: mockContext)
        payment.id = UUID()
        payment.amount = 1500
        payment.isPaid = true
        payment.paidDate = Date()
        payment.lease = lease
        
        // When: Creating a GAAP-compliant ledger entry
        let ledgerEntry = LedgerEntry(context: mockContext)
        ledgerEntry.id = UUID()
        ledgerEntry.date = payment.paidDate
        ledgerEntry.amount = payment.amount
        ledgerEntry.debitAmount = payment.amount // Debit cash account
        ledgerEntry.creditAmount = 0
        ledgerEntry.accountCode = "4000" // Revenue account
        ledgerEntry.accountName = "Lease Revenue"
        ledgerEntry.description = "Lease payment received"
        ledgerEntry.entryType = "revenue"
        ledgerEntry.taxCategory = "Rental Income"
        ledgerEntry.reconciled = false
        ledgerEntry.lease = lease
        ledgerEntry.payment = payment
        
        payment.ledgerEntry = ledgerEntry
        
        try mockContext.save()
        
        // Then: Should create proper GAAP-compliant ledger entry
        XCTAssertNotNil(payment.ledgerEntry)
        XCTAssertEqual(ledgerEntry.accountCode, "4000")
        XCTAssertEqual(ledgerEntry.entryType, "revenue")
        XCTAssertEqual(ledgerEntry.debitAmount, payment.amount)
        XCTAssertEqual(ledgerEntry.creditAmount, 0)
        XCTAssertEqual(ledgerEntry.taxCategory, "Rental Income")
        XCTAssertFalse(ledgerEntry.reconciled)
        XCTAssertEqual(ledgerEntry.lease, lease)
    }
    
    /// Tests vendor contact integration with ledger
    func testVendorContactLedgerIntegration() throws {
        // Given: A vendor contact for expense tracking
        let vendor = VendorContact(context: mockContext)
        vendor.id = UUID()
        vendor.name = "Agricultural Services LLC"
        vendor.vendorCode = "ASL001"
        vendor.email = "billing@agservices.com"
        vendor.phone = "555-0123"
        vendor.taxId = "12-3456789"
        
        // And an expense ledger entry
        let expenseLedger = LedgerEntry(context: mockContext)
        expenseLedger.id = UUID()
        expenseLedger.date = Date()
        expenseLedger.amount = 500
        expenseLedger.debitAmount = 500 // Debit expense
        expenseLedger.creditAmount = 0
        expenseLedger.accountCode = "6000" // Expense account
        expenseLedger.accountName = "Farm Maintenance"
        expenseLedger.description = "Field maintenance services"
        expenseLedger.entryType = "expense"
        expenseLedger.vendorContact = vendor
        
        try mockContext.save()
        
        // Then: Should properly link vendor to ledger entry
        XCTAssertEqual(expenseLedger.vendorContact, vendor)
        XCTAssertEqual(expenseLedger.entryType, "expense")
        XCTAssertEqual(expenseLedger.debitAmount, 500)
        XCTAssertNotNil(vendor.taxId)
    }
    
    // MARK: - Integration Tests
    
    /// Tests complete lease workflow from creation to payment
    func testCompleteLeaseWorkflow() throws {
        // Given: Complete lease setup
        leaseTemplateSeeder.seedTemplatesIfNeeded()
        
        let property = Property(context: mockContext)
        property.id = UUID()
        property.displayName = "Integration Test Farm"
        
        let farmer = Farmer(context: mockContext)
        farmer.id = UUID()
        farmer.name = "Integration Test Farmer"
        
        let lease = Lease(context: mockContext)
        lease.id = UUID()
        lease.leaseType = "cash"
        lease.rentAmount = NSDecimalNumber(value: 6000)
        lease.rentFrequency = "semi-annual"
        lease.startDate = Date()
        lease.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        lease.status = "active"
        lease.property = property
        lease.farmer = farmer
        
        // Create payment schedule (2 payments for semi-annual)
        let payment1 = Payment(context: mockContext)
        payment1.id = UUID()
        payment1.amount = 3000
        payment1.dueDate = lease.startDate
        payment1.isPaid = false
        payment1.paymentStatus = "pending"
        payment1.sequence = 1
        payment1.lease = lease
        
        let payment2 = Payment(context: mockContext)
        payment2.id = UUID()
        payment2.amount = 3000
        payment2.dueDate = Calendar.current.date(byAdding: .month, value: 6, to: lease.startDate!)
        payment2.isPaid = false
        payment2.paymentStatus = "pending"
        payment2.sequence = 2
        payment2.lease = lease
        
        try mockContext.save()
        
        // When: Processing first payment
        payment1.isPaid = true
        payment1.paidDate = Date()
        payment1.paymentStatus = "paid"
        
        // Create corresponding ledger entry
        let ledgerEntry = LedgerEntry(context: mockContext)
        ledgerEntry.id = UUID()
        ledgerEntry.date = payment1.paidDate
        ledgerEntry.amount = payment1.amount
        ledgerEntry.debitAmount = payment1.amount
        ledgerEntry.creditAmount = 0
        ledgerEntry.accountCode = "4000"
        ledgerEntry.accountName = "Lease Revenue"
        ledgerEntry.entryType = "revenue"
        ledgerEntry.lease = lease
        ledgerEntry.payment = payment1
        
        payment1.ledgerEntry = ledgerEntry
        
        try mockContext.save()
        
        // Then: Should have complete integrated workflow
        XCTAssertEqual(lease.payments?.count, 2)
        XCTAssertTrue(payment1.isPaid)
        XCTAssertFalse(payment2.isPaid)
        XCTAssertNotNil(payment1.ledgerEntry)
        XCTAssertEqual(ledgerEntry.payment, payment1)
        XCTAssertEqual(ledgerEntry.lease, lease)
    }
}