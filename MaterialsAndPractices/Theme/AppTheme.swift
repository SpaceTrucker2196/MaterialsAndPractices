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