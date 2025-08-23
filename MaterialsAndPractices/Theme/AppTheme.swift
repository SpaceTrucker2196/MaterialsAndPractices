//
//  AppTheme.swift
//  MaterialsAndPractices
//
//  A comprehensive theming system providing centralized color and typography management
//  supporting both light and dark appearance modes following Apple design guidelines.
//

import SwiftUI

/// Central theme manager providing consistent design tokens across the application
/// Implements semantic color naming and typography scales following Apple's design principles
enum AppTheme {
    
    // MARK: - Color System
    
    /// Primary color palette with green as the central theme
    /// Uses darker tones for light mode and phosphorescent tones for dark mode
    enum Colors {
        
        // MARK: - Primary Colors
        
        /// Primary brand color - forest green for light mode, bright green for dark mode
        static let primary = Color("PrimaryColor")
        
        /// Secondary brand color - sage green variations
        static let secondary = Color("SecondaryColor")
        
        /// Accent color for interactive elements
        static let accent = Color("AccentColor")
        
        // MARK: - Semantic Colors
        
        /// Background colors for different surface levels
        static let backgroundPrimary = Color("BackgroundPrimary")
        static let backgroundSecondary = Color("BackgroundSecondary")
        static let backgroundTertiary = Color("BackgroundTertiary")
        
        /// Text colors for different hierarchy levels
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textTertiary = Color("TextTertiary")
        
        /// Status colors for different states
        static let success = Color("SuccessColor")
        static let warning = Color("WarningColor")
        static let error = Color("ErrorColor")
        static let info = Color("InfoColor")
        
        // MARK: - Organic Certification Specific Colors
        
        /// Color for organic material indicators
        static let organicMaterial = Color("OrganicMaterialColor")
        
        /// Color for organic practice indicators
        static let organicPractice = Color("OrganicPracticeColor")
        
        /// Color for certification compliance indicators
        static let compliance = Color("ComplianceColor")
        
        // MARK: - Plant Cultivar Colors
        
        /// Color for seasonal indicators
        static let seasonIndicator = Color("SeasonIndicatorColor")
        
        /// Color for zone indicators
        static let zoneIndicator = Color("ZoneIndicatorColor")
        
        /// Color for planting week indicators
        static let plantingIndicator = Color("PlantingIndicatorColor")
        
        // MARK: - USDA Zone Color Coding (Cold to Warm)
        
        /// USDA Zone 1-2 (Coldest) - Deep blue/purple
        static let zone1to2 = Color(red: 0.2, green: 0.3, blue: 0.8)
        
        /// USDA Zone 3-4 (Very Cold) - Medium blue
        static let zone3to4 = Color(red: 0.3, green: 0.5, blue: 0.9)
        
        /// USDA Zone 5-6 (Cold) - Light blue
        static let zone5to6 = Color(red: 0.4, green: 0.7, blue: 1.0)
        
        /// USDA Zone 7-8 (Moderate) - Green
        static let zone7to8 = Color(red: 0.3, green: 0.8, blue: 0.4)
        
        /// USDA Zone 9-10 (Warm) - Yellow/Orange
        static let zone9to10 = Color(red: 0.9, green: 0.7, blue: 0.3)
        
        /// USDA Zone 11+ (Warmest) - Red/Orange
        static let zone11plus = Color(red: 0.9, green: 0.4, blue: 0.3)
        
        // MARK: - Weather Tolerance Color Coding
        
        /// Hot/Drought tolerant - Red/Orange tones
        static let hotTolerant = Color(red: 0.9, green: 0.4, blue: 0.2)
        
        /// Cold tolerant - Blue tones
        static let coldTolerant = Color(red: 0.2, green: 0.5, blue: 0.8)
        
        /// Tropical - Deep green
        static let tropicalTolerant = Color(red: 0.1, green: 0.6, blue: 0.3)
        
        /// Dry tolerant - Brown/tan
        static let dryTolerant = Color(red: 0.7, green: 0.5, blue: 0.3)
        
        /// Wet tolerant - Deep blue
        static let wetTolerant = Color(red: 0.1, green: 0.4, blue: 0.7)
        
        // MARK: - Growing Days Color Coding
        
        /// Short season (< 60 days) - Light green
        static let shortSeason = Color(red: 0.6, green: 0.9, blue: 0.6)
        
        /// Medium season (60-90 days) - Medium green  
        static let mediumSeason = Color(red: 0.4, green: 0.8, blue: 0.4)
        
        /// Long season (90-120 days) - Dark green
        static let longSeason = Color(red: 0.2, green: 0.7, blue: 0.2)
        
        /// Extra long season (120+ days) - Deep forest green
        static let extraLongSeason = Color(red: 0.1, green: 0.5, blue: 0.1)
        
        // MARK: - Heat Map Colors
        
        /// Best harvest weeks - Bright green
        static let bestHarvest = Color(red: 0.2, green: 0.8, blue: 0.2)
        
        /// Good harvest weeks - Light green
        static let goodHarvest = Color(red: 0.6, green: 0.9, blue: 0.6)
        
        /// Default harvest weeks - Very light green
        static let defaultHarvest = Color(red: 0.9, green: 0.95, blue: 0.9)
    }
    
    // MARK: - Typography System
    
    /// Typography scale following Apple's type system with custom font support
    /// Provides semantic naming for consistent text styling across the application
    enum Typography {
        
        // MARK: - Display Text
        
        /// Large display text - for main headlines
        static let displayLarge = Font.largeTitle.weight(.bold)
        
        /// Medium display text - for section headers
        static let displayMedium = Font.title.weight(.semibold)
        
        /// Small display text - for subsection headers
        static let displaySmall = Font.title2.weight(.medium)
        
        // MARK: - Headline Text
        
        /// Large headlines - for main content titles
        static let headlineLarge = Font.headline.weight(.semibold)
        
        /// Medium headlines - for card titles
        static let headlineMedium = Font.headline.weight(.medium)
        
        /// Small headlines - for list item titles
        static let headlineSmall = Font.subheadline.weight(.medium)
        
        // MARK: - Body Text
        
        /// Large body text - for main content
        static let bodyLarge = Font.body
        
        /// Medium body text - for secondary content
        static let bodyMedium = Font.callout
        
        /// Small body text - for supporting content
        static let bodySmall = Font.caption
        
        // MARK: - Label Text
        
        /// Large labels - for form fields
        static let labelLarge = Font.callout.weight(.medium)
        
        /// Medium labels - for data fields
        static let labelMedium = Font.caption.weight(.medium)
        
        /// Small labels - for metadata
        static let labelSmall = Font.caption2.weight(.medium)
        
        // MARK: - Custom Font Support
        
        /// Creates a custom font with the specified name and size
        /// Falls back to system font if custom font is unavailable
        /// - Parameters:
        ///   - name: The custom font name
        ///   - size: The font size
        /// - Returns: A Font instance with custom or system fallback
        static func customFont(name: String, size: CGFloat) -> Font {
            return Font.custom(name, size: size)
        }
        
        /// Creates a custom font with relative sizing based on text style
        /// Maintains accessibility support for dynamic type
        /// - Parameters:
        ///   - name: The custom font name
        ///   - textStyle: The text style for relative sizing
        /// - Returns: A Font instance with custom font and relative sizing
        static func customFont(name: String, relativeTo textStyle: Font.TextStyle) -> Font {
            return Font.custom(name, size: UIFont.preferredFont(forTextStyle: textStyle.uiTextStyle).pointSize, relativeTo: textStyle)
        }
    }
    
    // MARK: - Spacing System
    
    /// Consistent spacing scale for layout and padding
    enum Spacing {
        static let tiny: CGFloat = 2
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let huge: CGFloat = 32
        static let massive: CGFloat = 48
    }
    
    // MARK: - Corner Radius System
    
    /// Consistent corner radius values for UI elements
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // MARK: - Color Coding Utilities
    
    /// Utility functions for determining colors based on data values
    enum ColorCoding {
        
        /// Returns color for USDA hardiness zone
        /// - Parameter zone: USDA zone string (e.g., "5-7", "3a", "10")
        /// - Returns: Color representing the climate zone
        static func colorForUSDAZone(_ zone: String) -> Color {
            let zoneNumber = extractZoneNumber(from: zone)
            
            switch zoneNumber {
            case 1...2:
                return Colors.zone1to2
            case 3...4:
                return Colors.zone3to4
            case 5...6:
                return Colors.zone5to6
            case 7...8:
                return Colors.zone7to8
            case 9...10:
                return Colors.zone9to10
            default:
                return Colors.zone11plus
            }
        }
        
        /// Returns color for weather tolerance characteristics
        /// - Parameter tolerance: Weather tolerance string (e.g., "Hot,Drought,Dry")
        /// - Returns: Primary color representing the tolerance type
        static func colorForWeatherTolerance(_ tolerance: String) -> Color {
            let toleranceLower = tolerance.lowercased()
            
            if toleranceLower.contains("hot") || toleranceLower.contains("drought") {
                return Colors.hotTolerant
            } else if toleranceLower.contains("cold") || toleranceLower.contains("frost") {
                return Colors.coldTolerant
            } else if toleranceLower.contains("tropical") {
                return Colors.tropicalTolerant
            } else if toleranceLower.contains("dry") {
                return Colors.dryTolerant
            } else if toleranceLower.contains("wet") || toleranceLower.contains("humid") {
                return Colors.wetTolerant
            } else {
                return Colors.secondary
            }
        }
        
        /// Returns color for growing days duration
        /// - Parameter days: Growing days string (e.g., "84-140", "60")
        /// - Returns: Color representing the season length
        static func colorForGrowingDays(_ days: String) -> Color {
            let dayNumber = extractDayNumber(from: days)
            
            switch dayNumber {
            case 0..<60:
                return Colors.shortSeason
            case 60..<90:
                return Colors.mediumSeason
            case 90..<120:
                return Colors.longSeason
            default:
                return Colors.extraLongSeason
            }
        }
        
        /// Extracts the primary zone number from a zone string
        /// - Parameter zone: Zone string like "5-7", "3a", "10b"
        /// - Returns: Primary zone number
        private static func extractZoneNumber(from zone: String) -> Int {
            let cleaned = zone.replacingOccurrences(of: "[^0-9-]", with: "", options: .regularExpression)
            let parts = cleaned.components(separatedBy: "-")
            return Int(parts.first ?? "0") ?? 0
        }
        
        /// Extracts the primary day number from a days string
        /// - Parameter days: Days string like "84-140", "60"
        /// - Returns: Primary day number
        private static func extractDayNumber(from days: String) -> Int {
            let cleaned = days.replacingOccurrences(of: "[^0-9-]", with: "", options: .regularExpression)
            let parts = cleaned.components(separatedBy: "-")
            return Int(parts.first ?? "0") ?? 0
        }
    }
}

// MARK: - Font.TextStyle Extension

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}