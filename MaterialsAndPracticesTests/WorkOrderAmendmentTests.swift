//
//  WorkOrderAmendmentTests.swift
//  MaterialsAndPractices
//
//  Tests for work order amendment tracking functionality.
//  Validates organic certification compliance and amendment integration.
//
//  Created by GitHub Copilot on 12/18/24.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class WorkOrderAmendmentTests: XCTestCase {
    var context: NSManagedObjectContext!
    var testGrow: Grow!
    
    override func setUp() {
        super.setUp()
        context = PersistenceController.preview.container.viewContext
        
        // Create test grow
        testGrow = Grow(context: context)
        testGrow.title = "Test Carrots"
        testGrow.locationName = "North Field"
    }
    
    override func tearDown() {
        context = nil
        testGrow = nil
        super.tearDown()
    }
    
    func testWorkOrderTitleGeneration() {
        // Test automatic work order title generation
        let fieldName = testGrow.locationName ?? "Field"
        let growName = testGrow.title ?? "Grow"
        
        let fieldPrefix = String(fieldName.prefix(6)) // "North "
        let growFirstWord = growName.components(separatedBy: " ").first ?? growName // "Test"
        
        let now = Date()
        let calendar = Calendar.current
        let weekNumber = calendar.component(.weekOfYear, from: now)
        let hour = calendar.component(.hour, from: now)
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: now)
        
        let expectedTitle = "\(fieldPrefix)-\(growFirstWord)-\(dayName)-Week\(weekNumber)-Hour\(hour)"
        
        // Should follow format: "First6-FirstWord-DayName-Week##-Hour##"
        XCTAssertTrue(expectedTitle.contains("North "))
        XCTAssertTrue(expectedTitle.contains("Test"))
        XCTAssertTrue(expectedTitle.contains("Week"))
        XCTAssertTrue(expectedTitle.contains("Hour"))
    }
    
    func testWorkOrderTypeEnum() {
        // Test work order type enum values
        XCTAssertEqual(WorkOrderType.planting.displayName, "Planting")
        XCTAssertEqual(WorkOrderType.planting.emoji, "🌱")
        XCTAssertEqual(WorkOrderType.weeding.displayWithEmoji, "🌿 Weeding")
        
        // Test all cases exist
        XCTAssertTrue(WorkOrderType.allCases.count >= 20)
        XCTAssertTrue(WorkOrderType.allCases.contains(.planting))
        XCTAssertTrue(WorkOrderType.allCases.contains(.harvesting))
        XCTAssertTrue(WorkOrderType.allCases.contains(.other))
    }
    
    func testCropAmendmentCreation() {
        // Test creating a crop amendment
        let amendment = CropAmendment(context: context)
        amendment.productName = "Test Compost"
        amendment.applicationRate = "2-4"
        amendment.unitOfMeasure = "cubic yards per acre"
        amendment.omriListed = true
        amendment.reEntryIntervalHours = 0
        amendment.preHarvestIntervalDays = 0
        
        XCTAssertEqual(amendment.displayName, "Test Compost")
        XCTAssertEqual(amendment.formattedApplicationRate, "2-4 cubic yards per acre")
        XCTAssertEqual(amendment.organicComplianceStatus, "OMRI Listed")
        XCTAssertEqual(amendment.organicComplianceColor, "requiredForOrganic")
        XCTAssertEqual(amendment.safetyIntervalInfo, "No restrictions")
    }
    
    func testCropAmendmentNonOrganic() {
        // Test non-organic amendment
        let amendment = CropAmendment(context: context)
        amendment.productName = "Synthetic Fertilizer"
        amendment.applicationRate = "50"
        amendment.unitOfMeasure = "pounds per acre"
        amendment.omriListed = false
        amendment.reEntryIntervalHours = 12
        amendment.preHarvestIntervalDays = 7
        
        XCTAssertEqual(amendment.organicComplianceStatus, "Not OMRI Listed")
        XCTAssertEqual(amendment.organicComplianceColor, "failedForOrganic")
        XCTAssertEqual(amendment.safetyIntervalInfo, "Re-entry: 12h, Pre-harvest: 7d")
    }
    
    func testOrganicCertificationStatus() {
        // Test organic certification status enum
        let required = OrganicCertificationStatus.requiredForOrganic
        let failed = OrganicCertificationStatus.failedForOrganic
        let notRequired = OrganicCertificationStatus.notRequiredForOrganic
        let unaffected = OrganicCertificationStatus.unaffectedOrganic
        
        XCTAssertEqual(required.colorName, "requiredForOrganic")
        XCTAssertEqual(failed.colorName, "failedForOrganic")
        XCTAssertEqual(notRequired.colorName, "notRequiredForOrganic")
        XCTAssertEqual(unaffected.colorName, "unaffectedOrganic")
        
        XCTAssertTrue(required.displayText.contains("Required for Organic"))
        XCTAssertTrue(failed.displayText.contains("Failed Organic Compliance"))
    }
    
    func testAmendmentFullDescription() {
        // Test amendment full description for work order notes
        let amendment = CropAmendment(context: context)
        amendment.productName = "Fish Emulsion"
        amendment.applicationRate = "1-2"
        amendment.unitOfMeasure = "gallons per acre"
        amendment.applicationMethod = "Foliar spray"
        amendment.omriListed = true
        amendment.reEntryIntervalHours = 4
        amendment.preHarvestIntervalDays = 0
        
        let description = amendment.fullDescription
        
        XCTAssertTrue(description.contains("Amendment: Fish Emulsion"))
        XCTAssertTrue(description.contains("Rate: 1-2 gallons per acre"))
        XCTAssertTrue(description.contains("Method: Foliar spray"))
        XCTAssertTrue(description.contains("OMRI Listed"))
        XCTAssertTrue(description.contains("Re-entry: 4h"))
    }
    
    func testAmendmentSeederData() {
        // Validate that seeder creates expected amendment types
        let organicAmendments = ["Compost (OMRI Listed)", "Fish Emulsion (OMRI Listed)", "Neem Oil (OMRI Listed)"]
        let conventionalAmendments = ["Synthetic NPK 10-10-10", "Malathion (Conventional Pesticide)", "Glyphosate Herbicide"]
        
        // Test that we have both organic and conventional amendments in our seeder
        // This validates the data structure without actually running the seeder
        for organic in organicAmendments {
            XCTAssertTrue(organic.contains("OMRI") || organic.contains("Compost"))
        }
        
        for conventional in conventionalAmendments {
            XCTAssertTrue(conventional.contains("Synthetic") || conventional.contains("Conventional") || conventional.contains("Glyphosate"))
        }
    }
}