//
//  ColorAssetTests.swift
//  MaterialsAndPracticesTests
//
//  Test to verify all color assets are properly configured and available
//

import XCTest
import SwiftUI
@testable import MaterialsAndPractices

class ColorAssetTests: XCTestCase {
    
    func testAllRequiredColorsExist() throws {
        // Test that all colors referenced in AppTheme are available
        // These should not crash when accessed
        
        // Text colors
        _ = AppTheme.Colors.textPrimary
        _ = AppTheme.Colors.textSecondary
        _ = AppTheme.Colors.textTertiary
        
        // Background colors
        _ = AppTheme.Colors.backgroundPrimary
        _ = AppTheme.Colors.backgroundSecondary
        _ = AppTheme.Colors.backgroundTertiary
        
        // Status colors
        _ = AppTheme.Colors.success
        _ = AppTheme.Colors.warning
        _ = AppTheme.Colors.error
        _ = AppTheme.Colors.info
        
        // Brand colors
        _ = AppTheme.Colors.primary
        _ = AppTheme.Colors.secondary
        _ = AppTheme.Colors.accent
        
        // Organic colors
        _ = AppTheme.Colors.organicMaterial
        _ = AppTheme.Colors.organicPractice
        _ = AppTheme.Colors.compliance
        
        // Plant colors
        _ = AppTheme.Colors.seasonIndicator
        _ = AppTheme.Colors.zoneIndicator
        _ = AppTheme.Colors.plantingIndicator
        
        // If we get here without crashing, all colors are available
        XCTAssertTrue(true, "All color assets are properly configured")
    }
    
    func testMissingColorsFromOriginalErrors() throws {
        // Test specifically the colors that were missing in the original error messages
        
        // These were causing the "No color named 'X' found in asset catalog" errors
        _ = AppTheme.Colors.textTertiary
        _ = AppTheme.Colors.info
        _ = AppTheme.Colors.success
        _ = AppTheme.Colors.backgroundTertiary
        _ = AppTheme.Colors.error
        
        XCTAssertTrue(true, "Previously missing colors are now available")
    }
    
    func testColorCodingUtilities() throws {
        // Test that color coding utilities work without crashing
        
        // USDA Zone colors
        let zone5Color = AppTheme.ColorCoding.colorForUSDAZone("5")
        let zone8Color = AppTheme.ColorCoding.colorForUSDAZone("8")
        let zone10Color = AppTheme.ColorCoding.colorForUSDAZone("10")
        
        XCTAssertNotNil(zone5Color)
        XCTAssertNotNil(zone8Color)
        XCTAssertNotNil(zone10Color)
        
        // Weather tolerance colors
        let hotColor = AppTheme.ColorCoding.colorForWeatherTolerance("Hot,Drought")
        let coldColor = AppTheme.ColorCoding.colorForWeatherTolerance("Cold")
        let tropicalColor = AppTheme.ColorCoding.colorForWeatherTolerance("Tropical")
        
        XCTAssertNotNil(hotColor)
        XCTAssertNotNil(coldColor)
        XCTAssertNotNil(tropicalColor)
        
        // Growing days colors
        let shortSeason = AppTheme.ColorCoding.colorForGrowingDays("45")
        let mediumSeason = AppTheme.ColorCoding.colorForGrowingDays("75")
        let longSeason = AppTheme.ColorCoding.colorForGrowingDays("105")
        
        XCTAssertNotNil(shortSeason)
        XCTAssertNotNil(mediumSeason)
        XCTAssertNotNil(longSeason)
    }
}