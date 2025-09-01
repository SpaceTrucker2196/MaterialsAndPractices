//
//  ActivePracticesTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for the Active Practices tile-based implementation
//  Validates Core Data integration, tile functionality, and navigation.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class ActivePracticesTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController.preview
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
        persistenceController = nil
    }
    
    // MARK: - Core Data Model Tests
    
    func testSeedLibraryDisplayName() throws {
        let seed = SeedLibrary(context: viewContext)
        seed.seedName = "Test Tomato Seeds"
        
        XCTAssertEqual(seed.displayName, "Test Tomato Seeds")
        
        // Test with nil seedName but cultivar
        seed.seedName = nil
        let cultivar = Cultivar(context: viewContext)
        cultivar.name = "Roma Tomato"
        seed.cultivar = cultivar
        
        XCTAssertEqual(seed.displayName, "Seeds: Roma Tomato")
        
        // Test with no data
        seed.cultivar = nil
        XCTAssertEqual(seed.displayName, "Unnamed Seed")
    }
    
    func testSeedLibraryActiveGrowsRelationship() throws {
        let seed = SeedLibrary(context: viewContext)
        seed.seedName = "Test Seeds"
        
        let grow1 = Grow(context: viewContext)
        grow1.title = "Active Grow"
        grow1.addToSeed(seed)
        
        let grow2 = Grow(context: viewContext)
        grow2.title = "Harvested Grow"
        grow2.harvestDate = Date()
        grow2.addToSeed(seed)
        
        try viewContext.save()
        
        XCTAssertEqual(seed.growsArray.count, 2)
        XCTAssertTrue(seed.growsArray.contains(grow1))
        XCTAssertTrue(seed.growsArray.contains(grow2))
    }
    
    func testHarvestDisplayName() throws {
        let harvest = Harvest(context: viewContext)
        
        // Test with notes
        harvest.notes = "First harvest of tomatoes"
        XCTAssertEqual(harvest.displayName, "First harvest of tomatoes")
        
        // Test with harvest date
        harvest.notes = nil
        harvest.harvestDate = Date()
        XCTAssertTrue(harvest.displayName.contains("Harvest"))
        
        // Test with no data
        harvest.harvestDate = nil
        XCTAssertEqual(harvest.displayName, "Harvest")
    }
    
    func testHarvestComplianceCalculation() throws {
        let harvest = Harvest(context: viewContext)
        
        // Set up compliant harvest
        harvest.sanitationVerified = .yes
        harvest.comminglingRisk = .no
        harvest.contaminationRisk = .no
        harvest.complianceHold = false
        harvest.isCertifiedOrganic = true
        
        XCTAssertTrue(harvest.isCompliant)
        
        // Test non-compliant scenarios
        harvest.sanitationVerified = .no
        XCTAssertFalse(harvest.isCompliant)
        
        harvest.sanitationVerified = .yes
        harvest.complianceHold = true
        XCTAssertFalse(harvest.isCompliant)
    }
    
    func testWorkOrderCreationForHarvest() throws {
        let grow = Grow(context: viewContext)
        grow.title = "Test Grow"
        grow.plantedDate = Date()
        
        let workOrder = WorkOrder.createForHarvest(grow, in: viewContext)
        
        XCTAssertEqual(workOrder.title, "Harvest Test Grow")
        XCTAssertEqual(workOrder.grow, grow)
        XCTAssertEqual(workOrder.priorityLevel, .high)
        XCTAssertNotNil(workOrder.notes)
        XCTAssertTrue(workOrder.notes!.contains("Harvest operations"))
    }
    
    func testWorkOrderPriorityEnum() throws {
        let workOrder = WorkOrder(context: viewContext)
        
        workOrder.priorityLevel = .urgent
        XCTAssertEqual(workOrder.priority, "Urgent")
        XCTAssertEqual(workOrder.priorityLevel.sortOrder, 0)
        
        workOrder.priorityLevel = .low
        XCTAssertEqual(workOrder.priority, "Low")
        XCTAssertEqual(workOrder.priorityLevel.sortOrder, 3)
    }
    
    // MARK: - Fetch Request Tests
    
    func testActiveSeedsFetchRequest() throws {
        // Create test data
        let seed1 = SeedLibrary(context: viewContext)
        seed1.seedName = "Active Seed"
        
        let seed2 = SeedLibrary(context: viewContext)
        seed2.seedName = "Inactive Seed"
        
        let activeGrow = Grow(context: viewContext)
        activeGrow.title = "Active Grow"
        activeGrow.addToSeed(seed1)
        
        let inactiveGrow = Grow(context: viewContext)
        inactiveGrow.title = "Harvested Grow"
        inactiveGrow.harvestDate = Date()
        inactiveGrow.addToSeed(seed2)
        
        try viewContext.save()
        
        // Test fetch request
        let request = SeedLibrary.fetchRequestWithActiveGrows()
        let results = try viewContext.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.seedName, "Active Seed")
    }
    
    func testWorkOrderAmendmentsFetchRequest() throws {
        // Create test data
        let amendment = CropAmendment(context: viewContext)
        amendment.productName = "Test Amendment"
        
        let workOrder = WorkOrder(context: viewContext)
        workOrder.title = "Amendment Application"
        workOrder.amendment = amendment
        workOrder.createdDate = Date()
        
        try viewContext.save()
        
        // Test fetch request
        let request = WorkOrder.fetchRequestWithAmendments()
        let results = try viewContext.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Amendment Application")
    }
    
    func testRecentAmendmentsFetchRequest() throws {
        let amendment1 = CropAmendment(context: viewContext)
        amendment1.productName = "Recent Amendment"
        
        let amendment2 = CropAmendment(context: viewContext)
        amendment2.productName = "Old Amendment"
        
        let recentWorkOrder = WorkOrder(context: viewContext)
        recentWorkOrder.amendment = amendment1
        recentWorkOrder.createdDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        
        let oldWorkOrder = WorkOrder(context: viewContext)
        oldWorkOrder.amendment = amendment2
        oldWorkOrder.createdDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())
        
        try viewContext.save()
        
        // Test three year filter
        let request = WorkOrder.fetchRequestRecentThreeYears()
        let results = try viewContext.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.amendment?.productName, "Recent Amendment")
    }
    
    // MARK: - Amendment Timing Color Tests
    
    func testAmendmentTimingColors() throws {
        let now = Date()
        
        // Test recent (0-7 days)
        let recentDate = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let recentColor = AppTheme.ColorCoding.colorForAmendmentTiming(recentDate)
        XCTAssertEqual(recentColor, AppTheme.Colors.amendmentRecent)
        
        // Test weekly (8-28 days)
        let weeklyDate = Calendar.current.date(byAdding: .day, value: -14, to: now)!
        let weeklyColor = AppTheme.ColorCoding.colorForAmendmentTiming(weeklyDate)
        XCTAssertEqual(weeklyColor, AppTheme.Colors.amendmentWeekly)
        
        // Test monthly (29-365 days)
        let monthlyDate = Calendar.current.date(byAdding: .month, value: -6, to: now)!
        let monthlyColor = AppTheme.ColorCoding.colorForAmendmentTiming(monthlyDate)
        XCTAssertEqual(monthlyColor, AppTheme.Colors.amendmentMonthly)
        
        // Test yearly (366-1095 days)
        let yearlyDate = Calendar.current.date(byAdding: .year, value: -2, to: now)!
        let yearlyColor = AppTheme.ColorCoding.colorForAmendmentTiming(yearlyDate)
        XCTAssertEqual(yearlyColor, AppTheme.Colors.amendmentYearly)
        
        // Test old (3+ years)
        let oldDate = Calendar.current.date(byAdding: .year, value: -5, to: now)!
        let oldColor = AppTheme.ColorCoding.colorForAmendmentTiming(oldDate)
        XCTAssertEqual(oldColor, AppTheme.Colors.amendmentOld)
    }
    
    // MARK: - Performance Tests
    
    func testActivePracticesDataPerformance() throws {
        measure {
            // Create realistic test data
            for i in 0..<100 {
                let seed = SeedLibrary(context: viewContext)
                seed.seedName = "Seed \(i)"
                
                let grow = Grow(context: viewContext)
                grow.title = "Grow \(i)"
                if i < 50 {
                    grow.addToSeed(seed) // Only half have active grows
                }
                
                let amendment = CropAmendment(context: viewContext)
                amendment.productName = "Amendment \(i)"
                
                let workOrder = WorkOrder(context: viewContext)
                workOrder.amendment = amendment
                workOrder.createdDate = Calendar.current.date(byAdding: .month, value: -i, to: Date())
            }
            
            try! viewContext.save()
            
            // Test fetch performance
            let seedRequest = SeedLibrary.fetchRequestWithActiveGrows()
            let amendmentRequest = WorkOrder.fetchRequestRecentThreeYears()
            
            _ = try! viewContext.fetch(seedRequest)
            _ = try! viewContext.fetch(amendmentRequest)
        }
    }
    
    // MARK: - Validation Tests
    
    func testHarvestValidation() throws {
        let harvest = Harvest(context: viewContext)
        harvest.quantityValue = 100.0
        harvest.netQuantityValue = 95.0
        harvest.quantityUnit = .pounds
        
        XCTAssertEqual(harvest.quantityDisplay, "100.00 lb")
        XCTAssertEqual(harvest.netQuantityDisplay, "95.00 lb")
        
        harvest.quantityUnit = .kilograms
        XCTAssertEqual(harvest.quantityDisplay, "100.00 kg")
    }
    
    func testSeedLibraryExpiration() throws {
        let seed = SeedLibrary(context: viewContext)
        seed.productionYear = Int16(Calendar.current.component(.year, from: Date()) - 6)
        
        XCTAssertTrue(seed.isExpired, "Seed should be expired after 5 years")
        
        seed.productionYear = Int16(Calendar.current.component(.year, from: Date()) - 2)
        XCTAssertFalse(seed.isExpired, "Seed should not be expired within 5 years")
    }
    
    func testGerminationTestCurrency() throws {
        let seed = SeedLibrary(context: viewContext)
        
        // Test current test
        seed.germinationTestDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())
        XCTAssertTrue(seed.isGerminationTestCurrent)
        
        // Test expired test
        seed.germinationTestDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())
        XCTAssertFalse(seed.isGerminationTestCurrent)
        
        // Test no test date
        seed.germinationTestDate = nil
        XCTAssertFalse(seed.isGerminationTestCurrent)
    }
}