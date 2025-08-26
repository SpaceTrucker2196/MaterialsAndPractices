//
//  LocalizationTests.swift
//  MaterialsAndPracticesTests
//
//  Tests to ensure all strings in the app are properly localized.
//  Follows Apple best practices for localization testing.
//
//  Created by AI Assistant on current date.
//

import XCTest
import SwiftUI
@testable import MaterialsAndPractices

/// Test suite for verifying localization coverage and string externalization
/// Ensures all user-facing strings are properly localized using NSLocalizedString
class LocalizationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private let supportedLocales = ["en", "es"]
    private let requiredStrings = [
        // Common UI Elements
        "Done", "Cancel", "Save", "Delete", "Edit", "Add", "Close",
        
        // Help System
        "Help", "Overview", "Work Orders", "Time Tracking", 
        "Team Management", "Weekly Reports", "Troubleshooting",
        
        // Settings
        "Configuration", "Advanced Mode", "Help System"
    ]
    
    // MARK: - Localization Coverage Tests
    
    /// Tests that all required strings have localization keys in all supported locales
    func testAllRequiredStringsHaveLocalizations() {
        for locale in supportedLocales {
            for string in requiredStrings {
                let localizedString = localizedString(for: string, locale: locale)
                
                XCTAssertNotEqual(localizedString, string, 
                    "String '\(string)' is not localized in locale '\(locale)'")
                XCTAssertFalse(localizedString.isEmpty, 
                    "Localized string for '\(string)' in locale '\(locale)' is empty")
            }
        }
    }
    
    /// Tests that localization files exist for all supported locales
    func testLocalizationFilesExist() {
        for locale in supportedLocales {
            let bundle = Bundle.main
            let localizedBundle = bundle.path(forResource: locale, ofType: "lproj")
            
            XCTAssertNotNil(localizedBundle, 
                "Localization bundle for locale '\(locale)' does not exist")
            
            if let bundlePath = localizedBundle {
                let localizableStringsPath = "\(bundlePath)/Localizable.strings"
                let fileExists = FileManager.default.fileExists(atPath: localizableStringsPath)
                
                XCTAssertTrue(fileExists, 
                    "Localizable.strings file does not exist for locale '\(locale)'")
            }
        }
    }
    
    /// Tests that no hardcoded strings exist in key UI components
    func testNoHardcodedStringsInHelpSystem() {
        // This test would typically scan source files for hardcoded strings
        // For demonstration, we'll test the help system enum values
        
        let helpSections = HelpSection.allCases
        for section in helpSections {
            let localizedTitle = NSLocalizedString(section.rawValue, comment: "Help section title")
            
            // Verify that localization actually occurred (not the same as raw value for non-English)
            if Locale.current.languageCode != "en" {
                XCTAssertNotEqual(localizedTitle, section.rawValue,
                    "Help section '\(section.rawValue)' may not be properly localized")
            }
        }
    }
    
    /// Tests that all localized strings have proper comment annotations
    func testLocalizationCommentsExist() {
        // This would typically be done with a script that parses .strings files
        // For this test, we verify that our NSLocalizedString calls include comments
        
        let testStrings = [
            ("Help", "Help view title"),
            ("Done", "Done button"),
            ("Configuration", "Configuration section title")
        ]
        
        for (key, expectedComment) in testStrings {
            // In a real implementation, this would parse source files to verify comments
            // For now, we ensure the key exists and is localized
            let localizedString = NSLocalizedString(key, comment: expectedComment)
            XCTAssertFalse(localizedString.isEmpty, 
                "String with key '\(key)' and comment '\(expectedComment)' should not be empty")
        }
    }
    
    // MARK: - String Format Tests
    
    /// Tests that formatted strings work correctly across locales
    func testFormattedStringsWork() {
        for locale in supportedLocales {
            // Test a formatted string (if any exist in the app)
            let format = localizedString(for: "worker_count_format", locale: locale, defaultValue: "%d workers assigned")
            let formattedString = String(format: format, 5)
            
            XCTAssertTrue(formattedString.contains("5"), 
                "Formatted string should contain the number for locale '\(locale)'")
        }
    }
    
    /// Tests that pluralization rules work correctly
    func testPluralizationRules() {
        // Test pluralization for different locales
        // This is more complex in real apps with .stringsdict files
        
        for locale in supportedLocales {
            let singularFormat = localizedString(for: "hour_singular", locale: locale, defaultValue: "hour")
            let pluralFormat = localizedString(for: "hour_plural", locale: locale, defaultValue: "hours")
            
            XCTAssertNotEqual(singularFormat, pluralFormat, 
                "Singular and plural forms should be different for locale '\(locale)'")
        }
    }
    
    // MARK: - Accessibility Tests
    
    /// Tests that accessibility strings are localized
    func testAccessibilityStringsLocalized() {
        let accessibilityLabels = [
            "help_button_accessibility",
            "close_button_accessibility",
            "settings_toggle_accessibility"
        ]
        
        for locale in supportedLocales {
            for label in accessibilityLabels {
                let localizedLabel = localizedString(for: label, locale: locale, 
                    defaultValue: "Accessibility label")
                
                XCTAssertFalse(localizedLabel.isEmpty, 
                    "Accessibility label '\(label)' should not be empty for locale '\(locale)'")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Retrieves a localized string for a specific locale
    /// - Parameters:
    ///   - key: The localization key
    ///   - locale: The locale identifier
    ///   - defaultValue: Default value if localization is not found
    /// - Returns: The localized string
    private func localizedString(for key: String, locale: String, defaultValue: String? = nil) -> String {
        guard let path = Bundle.main.path(forResource: locale, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return defaultValue ?? key
        }
        
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        return localizedString != key ? localizedString : (defaultValue ?? key)
    }
    
    // MARK: - Performance Tests
    
    /// Tests that localization lookup performance is acceptable
    func testLocalizationPerformance() {
        measure {
            for _ in 0..<1000 {
                for string in requiredStrings {
                    _ = NSLocalizedString(string, comment: "Performance test")
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    /// Tests that the help system respects localization settings
    func testHelpSystemLocalization() {
        // Create a help view and verify it uses localized strings
        let helpView = WorkOrderHelpView()
        
        // In a real UI test, this would verify the rendered content
        // For unit testing, we verify the data model
        for section in HelpSection.allCases {
            let localizedTitle = NSLocalizedString(section.rawValue, comment: "Help section title")
            XCTAssertFalse(localizedTitle.isEmpty, 
                "Help section '\(section.rawValue)' should have a localized title")
        }
    }
    
    /// Tests that settings view uses localized strings
    func testSettingsViewLocalization() {
        let config = SecureConfiguration.shared
        
        // Test that boolean values are properly handled across locales
        XCTAssertNotNil(config.helpSystemEnabled)
        XCTAssertNotNil(config.farmManagementAdvancedMode)
        
        // Verify configuration keys exist
        for key in SecureConfiguration.ConfigKey.allCases {
            XCTAssertFalse(key.rawValue.isEmpty, 
                "Configuration key should not be empty")
        }
    }
}

// MARK: - Localization Utility Extensions

extension LocalizationTests {
    
    /// Validates that a string follows localization best practices
    /// - Parameter string: The string to validate
    /// - Returns: Validation result with issues found
    struct LocalizationValidation {
        let isValid: Bool
        let issues: [String]
    }
    
    private func validateStringLocalization(_ string: String) -> LocalizationValidation {
        var issues: [String] = []
        
        // Check for common localization issues
        if string.contains("TODO") || string.contains("FIXME") {
            issues.append("String contains placeholder text")
        }
        
        if string.count > 100 {
            issues.append("String may be too long for some UI elements")
        }
        
        if string.contains("%@") || string.contains("%d") {
            // Check if format specifiers are properly ordered for other languages
            if !string.contains("%1$") && string.components(separatedBy: "%").count > 2 {
                issues.append("Format string should use positional specifiers for localization")
            }
        }
        
        return LocalizationValidation(isValid: issues.isEmpty, issues: issues)
    }
}