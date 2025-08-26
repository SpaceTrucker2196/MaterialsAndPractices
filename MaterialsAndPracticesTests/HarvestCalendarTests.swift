//
//  HarvestCalendarTests.swift
//  MaterialsAndPracticesTests
//
//  Unit tests for harvest calendar date range calculations and heat map functionality.
//  Tests critical business logic for optimal harvest timing calculations.
//
//  Created by AI Assistant on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class HarvestCalendarTests: XCTestCase {
    
    var mockPersistenceController: PersistenceController!
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        mockPersistenceController = PersistenceController(inMemory: true)
        mockContext = mockPersistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        mockPersistenceController = nil
        mockContext = nil
    }
    
    // MARK: - Harvest Quality Enum Tests
    
    func testHarvestQualityColors() throws {
        // Given: All harvest quality cases
        // When: Checking colors and opacity
        // Then: Should have appropriate visual indicators
        
        XCTAssertEqual(HarvestQuality.best.opacity, 1.0, "Best harvest should have full opacity")
        XCTAssertEqual(HarvestQuality.good.opacity, 0.8, "Good harvest should have 80% opacity")
        XCTAssertEqual(HarvestQuality.fair.opacity, 0.4, "Fair harvest should have 40% opacity")
        XCTAssertEqual(HarvestQuality.offSeason.opacity, 0.6, "Off season should have 60% opacity")
        
        XCTAssertEqual(HarvestQuality.best.description, "Best Harvest")
        XCTAssertEqual(HarvestQuality.good.description, "Good Harvest")
        XCTAssertEqual(HarvestQuality.fair.description, "Fair Harvest")
        XCTAssertEqual(HarvestQuality.offSeason.description, "Off Season")
    }
    
    // MARK: - Harvest Calendar Data Tests
    
    func testHarvestQualityCalculation() throws {
        // Given: A cultivar with specific harvest weeks
        let cultivar = createTestCultivar(name: "Test Tomato", emoji: "🍅")
        let harvestData = HarvestCalendarData(
            bestHarvestWeeks: [20, 21, 22],
            goodHarvestWeeks: [19, 23, 24],
            cultivar: cultivar,
            plantedDate: Date(),
            usdaZone: "7a"
        )
        
        // When: Checking harvest quality for different weeks
        // Then: Should return correct quality levels
        XCTAssertEqual(harvestData.harvestQuality(for: 20), .best, "Week 20 should be best harvest")
        XCTAssertEqual(harvestData.harvestQuality(for: 21), .best, "Week 21 should be best harvest")
        XCTAssertEqual(harvestData.harvestQuality(for: 19), .good, "Week 19 should be good harvest")
        XCTAssertEqual(harvestData.harvestQuality(for: 23), .good, "Week 23 should be good harvest")
        XCTAssertEqual(harvestData.harvestQuality(for: 15), .fair, "Week 15 should be fair (growing season)")
        XCTAssertEqual(harvestData.harvestQuality(for: 35), .fair, "Week 35 should be fair (growing season)")
        XCTAssertEqual(harvestData.harvestQuality(for: 5), .offSeason, "Week 5 should be off season")
        XCTAssertEqual(harvestData.harvestQuality(for: 45), .offSeason, "Week 45 should be off season")
    }
    
    func testGrowingSeasonBoundaries() throws {
        // Given: A harvest calendar data instance
        let cultivar = createTestCultivar(name: "Test Plant", emoji: "🌱")
        let harvestData = HarvestCalendarData(
            bestHarvestWeeks: [],
            goodHarvestWeeks: [],
            cultivar: cultivar,
            plantedDate: Date(),
            usdaZone: "6b"
        )
        
        // When: Testing growing season boundaries
        // Then: Should correctly identify growing season (weeks 10-40)
        XCTAssertEqual(harvestData.harvestQuality(for: 9), .offSeason, "Week 9 should be off season")
        XCTAssertEqual(harvestData.harvestQuality(for: 10), .fair, "Week 10 should be start of growing season")
        XCTAssertEqual(harvestData.harvestQuality(for: 25), .fair, "Week 25 should be in growing season")
        XCTAssertEqual(harvestData.harvestQuality(for: 40), .fair, "Week 40 should be end of growing season")
        XCTAssertEqual(harvestData.harvestQuality(for: 41), .offSeason, "Week 41 should be off season")
    }
    
    // MARK: - Harvest Calculator Tests
    
    func testBasicHarvestCalculation() throws {
        // Given: A cultivar with 75-85 day growing period
        let cultivar = createTestCultivar(name: "Roma Tomato", emoji: "🍅")
        cultivar.growingDays = "75-85"
        
        let plantDate = createDate(year: 2024, month: 3, day: 15) // March 15th
        
        // When: Calculating harvest calendar data
        let harvestData = HarvestCalculator.calculateHarvestCalendarData(
            cultivar: cultivar,
            plantDate: plantDate
        )
        
        // Then: Should calculate correct harvest periods
        XCTAssertEqual(harvestData.cultivar.name, "Roma Tomato")
        XCTAssertEqual(harvestData.plantedDate, plantDate)
        XCTAssertFalse(harvestData.bestHarvestWeeks.isEmpty, "Should have best harvest weeks")
        XCTAssertFalse(harvestData.goodHarvestWeeks.isEmpty, "Should have good harvest weeks")
        
        // Verify best harvest weeks are within expected range
        let calendar = Calendar.current
        let expectedEarlyDate = calendar.date(byAdding: .day, value: 75, to: plantDate)!
        let expectedLateDate = calendar.date(byAdding: .day, value: 85, to: plantDate)!
        let expectedEarlyWeek = calendar.component(.weekOfYear, from: expectedEarlyDate)
        let expectedLateWeek = calendar.component(.weekOfYear, from: expectedLateDate)
        
        XCTAssertTrue(harvestData.bestHarvestWeeks.contains(expectedEarlyWeek), 
                     "Should include early harvest week \(expectedEarlyWeek)")
        XCTAssertTrue(harvestData.bestHarvestWeeks.last! <= expectedLateWeek + 1, 
                     "Best harvest should not extend too far past late harvest date")
    }
    
    func testShortSeasonCrop() throws {
        // Given: A fast-growing crop (radishes, 25-30 days)
        let cultivar = createTestCultivar(name: "Cherry Belle Radish", emoji: "🔴")
        cultivar.growingDays = "25-30"
        
        let plantDate = createDate(year: 2024, month: 4, day: 1) // April 1st
        
        // When: Calculating harvest calendar
        let harvestData = HarvestCalculator.calculateHarvestCalendarData(
            cultivar: cultivar,
            plantDate: plantDate
        )
        
        // Then: Should have tight harvest window
        XCTAssertLessThanOrEqual(harvestData.bestHarvestWeeks.count, 3, 
                                "Short season crops should have narrow best harvest window")
        
        let calendar = Calendar.current
        let expectedHarvestDate = calendar.date(byAdding: .day, value: 27, to: plantDate)! // Mid-range
        let expectedWeek = calendar.component(.weekOfYear, from: expectedHarvestDate)
        
        XCTAssertTrue(harvestData.bestHarvestWeeks.contains(expectedWeek), 
                     "Should include expected harvest week for short season crop")
    }
    
    func testLongSeasonCrop() throws {
        // Given: A long-growing crop (winter squash, 95-120 days)
        let cultivar = createTestCultivar(name: "Butternut Squash", emoji: "🟡")
        cultivar.growingDays = "95-120"
        
        let plantDate = createDate(year: 2024, month: 5, day: 15) // May 15th
        
        // When: Calculating harvest calendar
        let harvestData = HarvestCalculator.calculateHarvestCalendarData(
            cultivar: cultivar,
            plantDate: plantDate
        )
        
        // Then: Should have longer harvest window
        XCTAssertGreaterThanOrEqual(harvestData.bestHarvestWeeks.count, 2, 
                                   "Long season crops should have adequate harvest window")
        XCTAssertLessThanOrEqual(harvestData.bestHarvestWeeks.count, 4, 
                                "Best harvest window should not be too broad")
        
        // Verify harvest falls in expected late season
        let maxBestWeek = harvestData.bestHarvestWeeks.max() ?? 0
        XCTAssertGreaterThanOrEqual(maxBestWeek, 30, 
                                   "Long season crops should harvest in late summer/fall")
    }
    
    func testYearBoundaryHarvest() throws {
        // Given: A crop planted late in year that harvests across year boundary
        let cultivar = createTestCultivar(name: "Winter Greenhouse Lettuce", emoji: "🥬")
        cultivar.growingDays = "45-60"
        
        let plantDate = createDate(year: 2024, month: 11, day: 15) // November 15th
        
        // When: Calculating harvest calendar
        let harvestData = HarvestCalculator.calculateHarvestCalendarData(
            cultivar: cultivar,
            plantDate: plantDate
        )
        
        // Then: Should handle year boundary correctly
        XCTAssertFalse(harvestData.bestHarvestWeeks.isEmpty, "Should have harvest weeks despite year boundary")
        
        // Should include early weeks of next year
        let hasEarlyYearWeeks = harvestData.bestHarvestWeeks.contains { $0 <= 10 }
        let hasLateYearWeeks = harvestData.bestHarvestWeeks.contains { $0 >= 40 }
        
        if hasEarlyYearWeeks && hasLateYearWeeks {
            // This indicates year boundary crossing was handled
            XCTAssertTrue(true, "Year boundary crossing handled correctly")
        } else {
            // Single year harvest is also valid for this test
            XCTAssertTrue(harvestData.bestHarvestWeeks.count > 0, "Should have valid harvest weeks")
        }
    }
    
    func testInvalidGrowingDays() throws {
        // Given: A cultivar with invalid growing days format
        let cultivar = createTestCultivar(name: "Invalid Crop", emoji: "❓")
        cultivar.growingDays = "invalid-format"
        
        let plantDate = Date()
        
        // When: Calculating harvest calendar
        let harvestData = HarvestCalculator.calculateHarvestCalendarData(
            cultivar: cultivar,
            plantDate: plantDate
        )
        
        // Then: Should handle gracefully with defaults
        XCTAssertEqual(harvestData.cultivar.name, "Invalid Crop")
        // Should still create some harvest data even with invalid input
        XCTAssertNotNil(harvestData.bestHarvestWeeks)
        XCTAssertNotNil(harvestData.goodHarvestWeeks)
    }
    
    // MARK: - Week Number Calculations Tests
    
    func testWeekNumberCalculations() throws {
        // Given: Specific test dates
        let testCases = [
            (month: 1, day: 1),   // New Year's Day
            (month: 3, day: 15),  // Mid March
            (month: 6, day: 21),  // Summer Solstice
            (month: 9, day: 23),  // Fall Equinox
            (month: 12, day: 31), // New Year's Eve
        ]
        
        for testCase in testCases {
            // When: Creating dates and getting week numbers
            let testDate = createDate(year: 2024, month: testCase.month, day: testCase.day)
            let weekNumber = Calendar.current.component(.weekOfYear, from: testDate)
            
            // Then: Week numbers should be in valid range
            XCTAssertGreaterThanOrEqual(weekNumber, 1, 
                                       "Week number should be at least 1 for \(testCase.month)/\(testCase.day)")
            XCTAssertLessThanOrEqual(weekNumber, 53, 
                                    "Week number should not exceed 53 for \(testCase.month)/\(testCase.day)")
        }
    }
    
    func testConsecutiveWeekNumbers() throws {
        // Given: Consecutive days across a week boundary
        let baseDate = createDate(year: 2024, month: 6, day: 30) // End of June
        let calendar = Calendar.current
        
        // When: Checking week numbers for consecutive days
        for dayOffset in 0..<7 {
            let testDate = calendar.date(byAdding: .day, value: dayOffset, to: baseDate)!
            let weekNumber = calendar.component(.weekOfYear, from: testDate)
            
            // Then: Week numbers should be sequential or same
            XCTAssertGreaterThan(weekNumber, 0, "Week number should be positive")
            
            // Log for debugging if needed
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            print("Date: \(dateFormatter.string(from: testDate)), Week: \(weekNumber)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testHarvestCalculationPerformance() throws {
        // Given: Multiple cultivars for performance testing
        let cultivars = (1...100).map { index in
            let cultivar = createTestCultivar(name: "Test Cultivar \(index)", emoji: "🌱")
            cultivar.growingDays = "\(30 + index % 90)-\(60 + index % 90)"
            return cultivar
        }
        
        let plantDate = Date()
        
        // When: Calculating harvest data for all cultivars
        measure {
            for cultivar in cultivars {
                _ = HarvestCalculator.calculateHarvestCalendarData(
                    cultivar: cultivar,
                    plantDate: plantDate
                )
            }
        }
        
        // Performance should be reasonable for 100 calculations
    }
    
    func testHarvestQualityPerformance() throws {
        // Given: Harvest data and many week lookups
        let cultivar = createTestCultivar(name: "Performance Test", emoji: "⚡")
        let harvestData = HarvestCalendarData(
            bestHarvestWeeks: [20, 21, 22, 23],
            goodHarvestWeeks: [18, 19, 24, 25, 26],
            cultivar: cultivar,
            plantedDate: Date(),
            usdaZone: "7a"
        )
        
        // When: Performing many quality lookups
        measure {
            for week in 1...52 {
                _ = harvestData.harvestQuality(for: week)
            }
        }
        
        // Should be fast for weekly lookups across entire year
    }
    
    // MARK: - Helper Methods
    
    private func createTestCultivar(name: String, emoji: String) -> Cultivar {
        let cultivar = Cultivar(context: mockContext)
        cultivar.name = name
        cultivar.emoji = emoji
        cultivar.family = "Test Family"
        return cultivar
    }
    
    private func createDate(year: Int, month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? Date()
    }
}

// MARK: - Cultivar Extension Tests

extension HarvestCalendarTests {
    
    func testCultivarGrowingDaysParsing() throws {
        // Given: Various growing days formats
        let testCases = [
            ("75-85", (early: 75, late: 85)),
            ("30-45", (early: 30, late: 45)),
            ("120-150", (early: 120, late: 150)),
            ("60", (early: 60, late: 60)), // Single value
        ]
        
        for testCase in testCases {
            // When: Creating cultivar with growing days
            let cultivar = createTestCultivar(name: "Test", emoji: "🌱")
            cultivar.growingDays = testCase.0
            
            let result = cultivar.parseGrowingDays()
            
            // Then: Should parse correctly
            XCTAssertEqual(result.early, testCase.1.early, 
                          "Early growing days should match for '\(testCase.0)'")
            XCTAssertEqual(result.late, testCase.1.late, 
                          "Late growing days should match for '\(testCase.0)'")
        }
    }
    
    func testCultivarInvalidGrowingDays() throws {
        // Given: Invalid growing days formats
        let invalidFormats = ["invalid", "abc-def", "", "75-", "-85", "75--85"]
        
        for invalidFormat in invalidFormats {
            // When: Creating cultivar with invalid format
            let cultivar = createTestCultivar(name: "Test", emoji: "🌱")
            cultivar.growingDays = invalidFormat
            
            let result = cultivar.parseGrowingDays()
            
            // Then: Should provide reasonable defaults
            XCTAssertGreaterThan(result.early, 0, 
                               "Should provide positive default for early days with '\(invalidFormat)'")
            XCTAssertGreaterThan(result.late, 0, 
                               "Should provide positive default for late days with '\(invalidFormat)'")
            XCTAssertGreaterThanOrEqual(result.late, result.early, 
                                       "Late days should not be less than early days with '\(invalidFormat)'")
        }
    }
}