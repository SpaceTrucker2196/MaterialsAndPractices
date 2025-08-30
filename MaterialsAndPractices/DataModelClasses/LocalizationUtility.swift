//
//  LocalizationUtility.swift
//  MaterialsAndPractices
//
//  Utility for validating and managing localization throughout the app.
//  Provides development tools for ensuring proper string externalization.
//
//  Created by AI Assistant on current date.
//

import Foundation
import SwiftUI

/// Utility class for localization management and validation
/// Provides tools for developers to ensure proper string localization
enum LocalizationUtility {
    
    // MARK: - Localization Helpers
    
    /// Creates a localized string with validation in debug builds
    /// - Parameters:
    ///   - key: The localization key
    ///   - comment: Developer comment explaining the string's context
    ///   - fallback: Fallback value if localization fails
    /// - Returns: Localized string
    static func localizedString(_ key: String, comment: String, fallback: String? = nil) -> String {
        let localizedString = NSLocalizedString(key, comment: comment)
        
        #if DEBUG
        validateLocalizationKey(key, comment: comment, result: localizedString)
        #endif
        
        // If localization failed (key == result), use fallback or key
        if localizedString == key {
            return fallback ?? key
        }
        
        return localizedString
    }
    
    /// Creates a localized string with format arguments
    /// - Parameters:
    ///   - key: The localization key
    ///   - comment: Developer comment explaining the string's context
    ///   - arguments: Format arguments to substitute
    /// - Returns: Formatted localized string
    static func localizedStringWithFormat(_ key: String, comment: String, _ arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: comment)
        return String(format: format, arguments: arguments)
    }
    
    // MARK: - Development Validation
    
    #if DEBUG
    /// Validates localization in debug builds and logs issues
    /// - Parameters:
    ///   - key: The localization key
    ///   - comment: The developer comment
    ///   - result: The localization result
    private static func validateLocalizationKey(_ key: String, comment: String, result: String) {
        var issues: [String] = []
        
        // Check if localization actually occurred
        if result == key {
            issues.append("⚠️ No localization found for key: '\(key)'")
        }
        
        // Check if comment is meaningful
        if comment.isEmpty || comment == "TODO" || comment == "FIXME" {
            issues.append("⚠️ Missing or placeholder comment for key: '\(key)'")
        }
        
        // Check for common formatting issues
        if result.contains("%%") {
            issues.append("⚠️ Double percent signs in localized string for key: '\(key)'")
        }
        
        // Log issues to console in debug builds
        if !issues.isEmpty {
            print("🌐 Localization Issues:")
            issues.forEach { print("   \($0)") }
        }
    }
    #endif
    
    // MARK: - App-Specific Localization
    
    /// Common UI element localizations
    enum CommonUI {
        static let done = localizedString("Done", comment: "Done button text")
        static let cancel = localizedString("Cancel", comment: "Cancel button text")
        static let save = localizedString("Save", comment: "Save button text")
        static let delete = localizedString("Delete", comment: "Delete button text")
        static let edit = localizedString("Edit", comment: "Edit button text")
        static let add = localizedString("Add", comment: "Add button text")
        static let close = localizedString("Close", comment: "Close button text")
    }
    
    /// Help system specific localizations
    enum HelpSystem {
        static let helpTitle = localizedString("Help", comment: "Help view title")
        static let overview = localizedString("Overview", comment: "Help overview section")
        static let workOrders = localizedString("Work Orders", comment: "Work orders help section")
        static let timeTracking = localizedString("Time Tracking", comment: "Time tracking help section")
        static let teamManagement = localizedString("Team Management", comment: "Team management help section")
        static let weeklyReports = localizedString("Weekly Reports", comment: "Weekly reports help section")
        static let troubleshooting = localizedString("Troubleshooting", comment: "Troubleshooting help section")
    }
    
    /// Settings and configuration localizations
    enum Settings {
        static let configuration = localizedString("Configuration", comment: "Configuration section title")
        static let advancedMode = localizedString("Advanced Mode", comment: "Advanced mode setting label")
        static let helpSystem = localizedString("Help System", comment: "Help system setting label")
        
        static let advancedModeDescription = localizedString(
            "Advanced mode provides access to detailed farm management features including fields, leases, payments, and compliance tracking.",
            comment: "Description of advanced mode setting"
        )
        
        static let helpSystemDescription = localizedString(
            "Enable or disable the in-app help system and documentation features.",
            comment: "Description of help system setting"
        )
    }
    
    // MARK: - Accessibility Localizations
    
    /// Accessibility-specific localizations
    enum Accessibility {
        static let helpButton = localizedString("Help button", comment: "Accessibility label for help button")
        static let closeButton = localizedString("Close button", comment: "Accessibility label for close button")
        static let settingsToggle = localizedString("Settings toggle", comment: "Accessibility label for settings toggle")
    }
    
    // MARK: - Validation Utilities
    
    /// Checks if the current locale is supported by the app
    /// - Returns: True if current locale is supported
    static func isCurrentLocaleSupported() -> Bool {
        let supportedLocales = ["en", "es"]
        let currentLocale = Locale.current.languageCode ?? "en"
        return supportedLocales.contains(currentLocale)
    }
    
    /// Gets the current app language
    /// - Returns: Current language code
    static func getCurrentLanguage() -> String {
        return Locale.current.languageCode ?? "en"
    }
    
    /// Forces a specific locale for testing purposes
    /// - Parameter locale: Locale to force (for testing only)
    static func setTestLocale(_ locale: Locale) {
        #if DEBUG
        // This would typically involve setting user defaults
        // Implementation depends on specific app architecture
        UserDefaults.standard.set([locale.identifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        #endif
    }
}

// MARK: - SwiftUI Extensions for Localization

extension Text {
    /// Creates a Text view with localized string and validation
    /// - Parameters:
    ///   - key: Localization key
    ///   - comment: Developer comment
    /// - Returns: Text view with localized content
    static func localized(_ key: String, comment: String) -> Text {
        return Text(LocalizationUtility.localizedString(key, comment: comment))
    }
    
    /// Creates a Text view with localized format string
    /// - Parameters:
    ///   - key: Localization key for format string
    ///   - comment: Developer comment
    ///   - arguments: Format arguments
    /// - Returns: Text view with formatted localized content
    static func localizedFormat(_ key: String, comment: String, _ arguments: CVarArg...) -> Text {
        let format = NSLocalizedString(key, comment: comment)
        return Text(String(format: format, arguments: arguments))
    }
}

//extension Button {
//    static func localizedLabel(
//        _ titleKey: String,
//        comment: String,
//        systemImage: String,
//        action: @escaping () -> Void
//    ) -> some View {
//        Button(action: action) {
//            SwiftUI.Label<Text, Image>(
//                title: { Text(LocalizedStringKey(titleKey)) },
//                icon: { Image(systemName: systemImage) }
//            )
//        }
//    }
//}

// MARK: - Development Helper Views

#if DEBUG
/// A development view that shows localization status
struct LocalizationDebugView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Current Locale") {
                    Text("Language: \(LocalizationUtility.getCurrentLanguage())")
                    Text("Supported: \(LocalizationUtility.isCurrentLocaleSupported() ? "Yes" : "No")")
                }
                
                Section("Common Strings Test") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Done: \(LocalizationUtility.CommonUI.done)")
                        Text("Cancel: \(LocalizationUtility.CommonUI.cancel)")
                        Text("Save: \(LocalizationUtility.CommonUI.save)")
                    }
                    .font(.caption)
                }
                
                Section("Help System Test") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Help: \(LocalizationUtility.HelpSystem.helpTitle)")
                        Text("Overview: \(LocalizationUtility.HelpSystem.overview)")
                        Text("Work Orders: \(LocalizationUtility.HelpSystem.workOrders)")
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Localization Debug")
        }
    }
}

struct LocalizationDebugView_Previews: PreviewProvider {
    static var previews: some View {
        LocalizationDebugView()
    }
}
#endif
