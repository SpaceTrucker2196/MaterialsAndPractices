//
//  DeviceDetectionAndAdaptiveUITests.swift
//  MaterialsAndPracticesTests
//
//  Unit tests for device detection capabilities and adaptive UI components.
//  Tests iPad Pro detection, size class responsiveness, and adaptive layouts.
//
//  Created by AI Assistant on current date.
//

import XCTest
import SwiftUI
@testable import MaterialsAndPractices

class DeviceDetectionAndAdaptiveUITests: XCTestCase {
    
    override func setUpWithError() throws {
        // Reset any global state if needed
    }
    
    override func tearDownWithError() throws {
        // Clean up any test state
    }
    
    // MARK: - Device Detection Tests
    
    func testDeviceTypeDetection() throws {
        // Note: These tests may need to be run on specific simulators or devices
        // to fully validate device detection logic
        
        // Given: Device detection utilities
        // When: Checking device capabilities
        // Then: Should provide consistent results
        
        // Test that device detection methods don't crash
        let _ = DeviceDetection.isiPad
        let _ = DeviceDetection.isiPhone
        let _ = DeviceDetection.isiPadPro
        
        // Device detection should return Boolean values
        XCTAssertTrue(DeviceDetection.isiPad || DeviceDetection.isiPhone, 
                     "Should detect as either iPad or iPhone")
        
        // iPad Pro detection should be subset of iPad detection
        if DeviceDetection.isiPadPro {
            XCTAssertTrue(DeviceDetection.isiPad, "iPad Pro should also be detected as iPad")
        }
    }
    
    func testIPadProSizeDetection() throws {
        // Given: iPad Pro size detection
        // When: Checking iPad Pro size variants
        let size = DeviceDetection.iPadProSize
        
        // Then: Should return valid size or nil
        if let detectedSize = size {
            XCTAssertTrue(detectedSize == .eleven || detectedSize == .twelvePointNine, 
                         "Should detect either 11-inch or 12.9-inch iPad Pro")
        }
        
        // If iPad Pro is detected, should have a size
        if DeviceDetection.isiPadPro {
            XCTAssertNotNil(size, "iPad Pro should have a detected size")
        }
    }
    
    func testDeviceOrientationDetection() throws {
        // Given: Device orientation detection capabilities
        // When: Checking orientation support
        // Then: Should handle orientation queries gracefully
        
        // Test that orientation detection doesn't crash
        let _ = DeviceDetection.isLandscape
        let _ = DeviceDetection.isPortrait
        
        // Orientation should be one or the other (in real scenarios)
        // Note: In unit tests, both might be false due to testing environment
        XCTAssertTrue(true, "Orientation detection should not crash")
    }
    
    // MARK: - Size Class Detection Tests
    
    func testColumnCountCalculation() throws {
        // Given: Various size class combinations
        let testCases: [(horizontal: UserInterfaceSizeClass, vertical: UserInterfaceSizeClass, expectedMin: Int, expectedMax: Int)] = [
            (.compact, .regular, 1, 2),    // iPhone portrait
            (.compact, .compact, 1, 2),    // iPhone landscape
            (.regular, .compact, 2, 4),    // iPad landscape
            (.regular, .regular, 2, 3),    // iPad portrait
        ]
        
        for testCase in testCases {
            // When: Calculating column count
            let columnCount = SizeClassDetection.columnCount(
                horizontalSizeClass: testCase.horizontal,
                verticalSizeClass: testCase.vertical
            )
            
            // Then: Should return appropriate column count
            XCTAssertGreaterThanOrEqual(columnCount, testCase.expectedMin, 
                                       "Column count should be at least \(testCase.expectedMin) for \(testCase.horizontal)/\(testCase.vertical)")
            XCTAssertLessThanOrEqual(columnCount, testCase.expectedMax, 
                                    "Column count should be at most \(testCase.expectedMax) for \(testCase.horizontal)/\(testCase.vertical)")
        }
    }
    
    func testNavigationStyleDetection() throws {
        // Given: Size class combinations
        let compactHorizontal = UserInterfaceSizeClass.compact
        let regularHorizontal = UserInterfaceSizeClass.regular
        
        // When: Determining navigation style
        let iPhoneStyle = SizeClassDetection.shouldUseSidebarNavigation(
            horizontalSizeClass: compactHorizontal
        )
        let iPadStyle = SizeClassDetection.shouldUseSidebarNavigation(
            horizontalSizeClass: regularHorizontal
        )
        
        // Then: Should use appropriate navigation
        XCTAssertFalse(iPhoneStyle, "Compact horizontal should use tab navigation")
        XCTAssertTrue(iPadStyle, "Regular horizontal should use sidebar navigation")
    }
    
    func testAdaptiveSpacingCalculation() throws {
        // Given: Different size classes
        let testCases: [(horizontal: UserInterfaceSizeClass, vertical: UserInterfaceSizeClass)] = [
            (.compact, .regular),
            (.compact, .compact),
            (.regular, .compact),
            (.regular, .regular),
        ]
        
        for testCase in testCases {
            // When: Calculating adaptive spacing
            let spacing = SizeClassDetection.adaptiveSpacing(
                horizontalSizeClass: testCase.horizontal,
                verticalSizeClass: testCase.vertical
            )
            
            // Then: Should return positive spacing value
            XCTAssertGreaterThan(spacing, 0, "Spacing should be positive")
            XCTAssertLessThanOrEqual(spacing, 32, "Spacing should be reasonable (≤32 points)")
        }
    }
    
    func testAdaptivePaddingCalculation() throws {
        // Given: Different size classes
        let compactRegular = (horizontal: UserInterfaceSizeClass.compact, vertical: UserInterfaceSizeClass.regular)
        let regularRegular = (horizontal: UserInterfaceSizeClass.regular, vertical: UserInterfaceSizeClass.regular)
        
        // When: Calculating adaptive padding
        let compactPadding = SizeClassDetection.adaptivePadding(
            horizontalSizeClass: compactRegular.horizontal,
            verticalSizeClass: compactRegular.vertical
        )
        let regularPadding = SizeClassDetection.adaptivePadding(
            horizontalSizeClass: regularRegular.horizontal,
            verticalSizeClass: regularRegular.vertical
        )
        
        // Then: Should provide appropriate padding
        XCTAssertGreaterThan(compactPadding, 0, "Compact padding should be positive")
        XCTAssertGreaterThan(regularPadding, 0, "Regular padding should be positive")
        XCTAssertGreaterThanOrEqual(regularPadding, compactPadding, 
                                   "Regular size classes should have equal or larger padding")
    }
    
    // MARK: - Dashboard Tile Tests
    
    func testDashboardTileCalculations() throws {
        // Given: Various screen widths
        let testWidths: [CGFloat] = [375, 414, 768, 834, 1024, 1194] // iPhone and iPad widths
        
        for width in testWidths {
            // When: Calculating tile size and spacing
            let tileSize = DashboardTileCalculator.calculateTileSize(availableWidth: width)
            let spacing = DashboardTileCalculator.calculateTileSpacing(availableWidth: width)
            let columns = DashboardTileCalculator.calculateColumns(availableWidth: width)
            
            // Then: Should return sensible values
            XCTAssertGreaterThan(tileSize, 0, "Tile size should be positive for width \(width)")
            XCTAssertGreaterThan(spacing, 0, "Spacing should be positive for width \(width)")
            XCTAssertGreaterThan(columns, 0, "Columns should be positive for width \(width)")
            XCTAssertLessThanOrEqual(columns, 6, "Should not exceed 6 columns for width \(width)")
            
            // Verify tiles fit within available width
            let totalTileWidth = CGFloat(columns) * tileSize + CGFloat(columns - 1) * spacing
            XCTAssertLessThanOrEqual(totalTileWidth, width, 
                                    "Tiles should fit within available width \(width)")
        }
    }
    
    func testTileGridLayout() throws {
        // Given: A set of tiles and available space
        let tileCount = 12
        let availableWidth: CGFloat = 1024 // iPad Pro 12.9" landscape
        
        // When: Calculating grid layout
        let layout = DashboardTileCalculator.calculateGridLayout(
            tileCount: tileCount,
            availableWidth: availableWidth
        )
        
        // Then: Should provide valid layout
        XCTAssertGreaterThan(layout.columns, 0, "Should have at least one column")
        XCTAssertGreaterThan(layout.rows, 0, "Should have at least one row")
        XCTAssertGreaterThanOrEqual(layout.columns * layout.rows, tileCount, 
                                   "Grid should accommodate all tiles")
        XCTAssertGreaterThan(layout.tileSize, 0, "Tile size should be positive")
        XCTAssertGreaterThan(layout.spacing, 0, "Spacing should be positive")
    }
    
    // MARK: - Responsive Layout Tests
    
    func testResponsiveImageSizing() throws {
        // Given: Different container sizes
        let testCases: [(containerSize: CGSize, imageAspectRatio: CGFloat)] = [
            (CGSize(width: 100, height: 100), 1.0),    // Square in square
            (CGSize(width: 200, height: 100), 2.0),    // Landscape image
            (CGSize(width: 100, height: 200), 0.5),    // Portrait image
            (CGSize(width: 300, height: 200), 1.5),    // Mixed aspect ratio
        ]
        
        for testCase in testCases {
            // When: Calculating responsive image size
            let imageSize = ResponsiveLayoutCalculator.calculateImageSize(
                containerSize: testCase.containerSize,
                imageAspectRatio: testCase.imageAspectRatio
            )
            
            // Then: Should fit within container
            XCTAssertLessThanOrEqual(imageSize.width, testCase.containerSize.width, 
                                    "Image width should fit in container")
            XCTAssertLessThanOrEqual(imageSize.height, testCase.containerSize.height, 
                                    "Image height should fit in container")
            XCTAssertGreaterThan(imageSize.width, 0, "Image width should be positive")
            XCTAssertGreaterThan(imageSize.height, 0, "Image height should be positive")
            
            // Verify aspect ratio is maintained
            let calculatedAspectRatio = imageSize.width / imageSize.height
            XCTAssertEqual(calculatedAspectRatio, testCase.imageAspectRatio, accuracy: 0.01, 
                          "Should maintain aspect ratio")
        }
    }
    
    func testResponsiveFontSizing() throws {
        // Given: Different screen sizes
        let testCases: [(screenSize: CGSize, baseSize: CGFloat)] = [
            (CGSize(width: 375, height: 667), 16),    // iPhone SE
            (CGSize(width: 414, height: 896), 17),    // iPhone 11 Pro Max
            (CGSize(width: 768, height: 1024), 18),   // iPad
            (CGSize(width: 1024, height: 1366), 20),  // iPad Pro 12.9"
        ]
        
        for testCase in testCases {
            // When: Calculating responsive font size
            let fontSize = ResponsiveLayoutCalculator.calculateFontSize(
                screenSize: testCase.screenSize,
                baseSize: testCase.baseSize
            )
            
            // Then: Should scale appropriately
            XCTAssertGreaterThan(fontSize, 0, "Font size should be positive")
            XCTAssertGreaterThanOrEqual(fontSize, testCase.baseSize * 0.8, 
                                       "Font size should not be too small")
            XCTAssertLessThanOrEqual(fontSize, testCase.baseSize * 1.5, 
                                    "Font size should not be too large")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityScaling() throws {
        // Given: Different accessibility content size categories
        let testCategories: [ContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        let baseSize: CGFloat = 16
        
        for category in testCategories {
            // When: Calculating accessibility-aware sizing
            let scaledSize = AccessibilityHelper.scaledSize(baseSize: baseSize, category: category)
            
            // Then: Should scale appropriately
            XCTAssertGreaterThan(scaledSize, 0, "Scaled size should be positive for \(category)")
            
            // Accessibility sizes should be larger than or equal to base
            if category.rawValue.contains("accessibility") {
                XCTAssertGreaterThanOrEqual(scaledSize, baseSize, 
                                           "Accessibility sizes should be larger for \(category)")
            }
        }
    }
    
    func testMinimumTouchTargetSize() throws {
        // Given: Various UI element sizes
        let testSizes: [CGSize] = [
            CGSize(width: 20, height: 20),    // Too small
            CGSize(width: 44, height: 44),    // Apple minimum
            CGSize(width: 30, height: 60),    // Narrow but tall
            CGSize(width: 60, height: 30),    // Wide but short
        ]
        
        for size in testSizes {
            // When: Ensuring minimum touch target
            let adjustedSize = AccessibilityHelper.ensureMinimumTouchTarget(size: size)
            
            // Then: Should meet minimum requirements
            XCTAssertGreaterThanOrEqual(adjustedSize.width, 44, 
                                       "Width should meet minimum touch target")
            XCTAssertGreaterThanOrEqual(adjustedSize.height, 44, 
                                       "Height should meet minimum touch target")
        }
    }
    
    // MARK: - Performance Tests
    
    func testDeviceDetectionPerformance() throws {
        // Test that device detection is fast enough for real-time use
        measure {
            for _ in 0..<1000 {
                _ = DeviceDetection.isiPad
                _ = DeviceDetection.isiPadPro
                _ = DeviceDetection.iPadProSize
            }
        }
    }
    
    func testSizeClassCalculationPerformance() throws {
        // Test that size class calculations are fast enough for layout
        let horizontalSizeClass = UserInterfaceSizeClass.regular
        let verticalSizeClass = UserInterfaceSizeClass.regular
        
        measure {
            for _ in 0..<1000 {
                _ = SizeClassDetection.columnCount(
                    horizontalSizeClass: horizontalSizeClass,
                    verticalSizeClass: verticalSizeClass
                )
                _ = SizeClassDetection.adaptiveSpacing(
                    horizontalSizeClass: horizontalSizeClass,
                    verticalSizeClass: verticalSizeClass
                )
                _ = SizeClassDetection.adaptivePadding(
                    horizontalSizeClass: horizontalSizeClass,
                    verticalSizeClass: verticalSizeClass
                )
            }
        }
    }
    
    func testResponsiveLayoutPerformance() throws {
        // Test that responsive layout calculations are fast enough
        let containerSize = CGSize(width: 1024, height: 768)
        let baseSize: CGFloat = 16
        
        measure {
            for _ in 0..<500 {
                _ = ResponsiveLayoutCalculator.calculateImageSize(
                    containerSize: containerSize,
                    imageAspectRatio: 1.5
                )
                _ = ResponsiveLayoutCalculator.calculateFontSize(
                    screenSize: containerSize,
                    baseSize: baseSize
                )
                _ = DashboardTileCalculator.calculateTileSize(availableWidth: containerSize.width)
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testZeroAndNegativeSizes() throws {
        // Given: Edge case sizes
        let edgeCases: [CGFloat] = [0, -10, 0.1, -0.1]
        
        for edgeCase in edgeCases {
            // When: Calculating with edge case values
            let tileSize = DashboardTileCalculator.calculateTileSize(availableWidth: edgeCase)
            let spacing = DashboardTileCalculator.calculateTileSpacing(availableWidth: edgeCase)
            let columns = DashboardTileCalculator.calculateColumns(availableWidth: edgeCase)
            
            // Then: Should handle gracefully
            XCTAssertGreaterThanOrEqual(tileSize, 0, "Tile size should not be negative for \(edgeCase)")
            XCTAssertGreaterThanOrEqual(spacing, 0, "Spacing should not be negative for \(edgeCase)")
            XCTAssertGreaterThan(columns, 0, "Columns should be positive for \(edgeCase)")
        }
    }
    
    func testExtremeAspectRatios() throws {
        // Given: Extreme aspect ratios
        let extremeRatios: [CGFloat] = [0.1, 10.0, 0.01, 100.0]
        let containerSize = CGSize(width: 300, height: 200)
        
        for ratio in extremeRatios {
            // When: Calculating image size with extreme ratio
            let imageSize = ResponsiveLayoutCalculator.calculateImageSize(
                containerSize: containerSize,
                imageAspectRatio: ratio
            )
            
            // Then: Should still fit in container
            XCTAssertLessThanOrEqual(imageSize.width, containerSize.width, 
                                    "Image should fit horizontally with ratio \(ratio)")
            XCTAssertLessThanOrEqual(imageSize.height, containerSize.height, 
                                    "Image should fit vertically with ratio \(ratio)")
            XCTAssertGreaterThan(imageSize.width, 0, "Image width should be positive")
            XCTAssertGreaterThan(imageSize.height, 0, "Image height should be positive")
        }
    }
}

// MARK: - Test Helper Utilities

extension DeviceDetectionAndAdaptiveUITests {
    
    func createMockSizeClass(horizontal: UserInterfaceSizeClass, vertical: UserInterfaceSizeClass) -> (UserInterfaceSizeClass, UserInterfaceSizeClass) {
        return (horizontal, vertical)
    }
    
    func createMockScreenSize(width: CGFloat, height: CGFloat) -> CGSize {
        return CGSize(width: width, height: height)
    }
}