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

        // MARK: - Fira Code wiring

        enum FiraWeight: String {
            case light = "Light"
            case regular = "Regular"
            case medium = "Medium"
            case semibold = "SemiBold"
            case bold = "Bold"

            var uiFontWeight: UIFont.Weight {
                switch self {
                case .light:     return .light
                case .regular:   return .regular
                case .medium:    return .medium
                case .semibold:  return .semibold
                case .bold:      return .bold
                }
            }
        }

        /// Returns Fira Code at Dynamic Type size for a given text style.
        /// Falls back to the system monospaced font if Fira Code isn’t available.
        static func firaCode(relativeTo style: Font.TextStyle,
                             weight: FiraWeight = .regular) -> Font {
            let pointSize = UIFont.preferredFont(forTextStyle: style.uiTextStyle).pointSize
            let firaName = "FiraCode-\(weight.rawValue)"

            // Validate the font exists to avoid rendering with an unknown name
            if UIFont(name: firaName, size: pointSize) != nil {
                return Font.custom(firaName, size: pointSize, relativeTo: style)
            } else {
                // Monospaced fallback keeps the aesthetic consistent
                return .system(style, design: .monospaced).weight(Font.Weight.medium)
            }
        }

        // MARK: - Display (Large headings)

        static let emojiLarge     = firaCode(relativeTo: .largeTitle, weight: .bold)
        static let displayLarge   = firaCode(relativeTo: .largeTitle,  weight: .bold)
        static let displayMedium  = firaCode(relativeTo: .title,       weight: .semibold)
        static let displaySmall   = firaCode(relativeTo: .title2,      weight: .medium)

        // MARK: - Headlines

        static let headlineLarge  = firaCode(relativeTo: .headline,    weight: .bold)
        static let headlineMedium = firaCode(relativeTo: .headline,    weight: .semibold)
        static let headlineSmall  = firaCode(relativeTo: .subheadline, weight: .medium)

        // MARK: - Body

        static let bodyLarge      = firaCode(relativeTo: .body,        weight: .medium)
        static let bodyMedium     = firaCode(relativeTo: .callout,     weight: .regular)
        static let bodySmall      = firaCode(relativeTo: .caption,     weight: .regular)

        // MARK: - Labels

        static let labelLarge     = firaCode(relativeTo: .callout,     weight: .bold)
        static let labelMedium    = firaCode(relativeTo: .caption,     weight: .bold)
        static let labelSmall     = firaCode(relativeTo: .caption2,    weight: .bold)

        // MARK: - Direct weight accessors (optional sugar)

        static func firaLight(relativeTo style: Font.TextStyle)    -> Font { firaCode(relativeTo: style, weight: .regular) }
        static func firaRegular(relativeTo style: Font.TextStyle)  -> Font { firaCode(relativeTo: style, weight: .medium) }
        static func firaMedium(relativeTo style: Font.TextStyle)   -> Font { firaCode(relativeTo: style, weight: .semibold) }
        static func firaSemibold(relativeTo style: Font.TextStyle) -> Font { firaCode(relativeTo: style, weight: .bold) }
        static func firaBold(relativeTo style: Font.TextStyle)     -> Font { firaCode(relativeTo: style, weight: .bold) }
    }

    
    // MARK: - Spacing System
    
    /// Consistent spacing scale for layout and padding
    enum Spacing {
        static let tiny: CGFloat = 2
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let extraLarge: CGFloat = 18
        static let huge: CGFloat = 28
        static let massive: CGFloat = 32
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
