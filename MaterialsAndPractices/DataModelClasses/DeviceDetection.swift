
import SwiftUI
import UIKit

// MARK: - Device Detection

/// Utility for detecting device types and screen characteristics
struct DeviceDetection {
    
    /// Current device type
    static var deviceType: DeviceType {
        let idiom = UIDevice.current.userInterfaceIdiom
        switch idiom {
        case .pad:
            return .iPad
        case .phone:
            return .iPhone
        case .mac:
            return .mac
        case .tv:
            return .appleTV
        case .carPlay:
            return .carPlay
        case .vision:
            return .visionPro
        default:
            return .unknown
        }
    }
    
    /// Check if current device is iPad
    static var isiPad: Bool {
        return deviceType == .iPad
    }
    
    /// Check if current device is iPhone
    static var isiPhone: Bool {
        return deviceType == .iPhone
    }
    
    /// Check if current device is iPad Pro (any size)
    static var isiPadPro: Bool {
        guard isiPad else { return false }
        
        let screen = UIScreen.main
        let screenSize = screen.bounds.size
        let scale = screen.scale
        
        // iPad Pro 12.9-inch dimensions
        let iPadPro129 = CGSize(width: 1024, height: 1366)
        // iPad Pro 11-inch dimensions  
        let iPadPro11 = CGSize(width: 834, height: 1194)
        
        let currentSize = CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
        
        return currentSize == iPadPro129 || currentSize == iPadPro11
    }
    
    /// Get iPad Pro size variant
    static var iPadProSize: iPadProSize? {
        guard isiPadPro else { return nil }
        
        let screen = UIScreen.main
        let screenSize = screen.bounds.size
        let scale = screen.scale
        let currentSize = CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
        
        // iPad Pro 12.9-inch
        if currentSize == CGSize(width: 1024, height: 1366) {
            return .twelvePointNine
        }
        // iPad Pro 11-inch
        else if currentSize == CGSize(width: 834, height: 1194) {
            return .eleven
        }
        
        return nil
    }
    
    /// Check if device supports multitasking
    static var supportsMultitasking: Bool {
        return isiPad
    }
    
    /// Check if device has external display support
    static var supportsExternalDisplay: Bool {
        return isiPad || deviceType == .mac
    }
    
    /// Check if device is in landscape orientation
    static var isLandscape: Bool {
        let orientation = UIDevice.current.orientation
        return orientation.isLandscape
    }
    
    /// Check if device is in portrait orientation
    static var isPortrait: Bool {
        let orientation = UIDevice.current.orientation
        return orientation.isPortrait
    }
}

/// Device type enumeration
enum DeviceType {
    case iPhone
    case iPad
    case mac
    case appleTV
    case carPlay
    case visionPro
    case unknown
}

/// iPad Pro size variants
enum iPadProSize {
    case eleven      // 11-inch
    case twelvePointNine // 12.9-inch
    
    var displayName: String {
        switch self {
        case .eleven:
            return "iPad Pro 11\""
        case .twelvePointNine:
            return "iPad Pro 12.9\""
        }
    }
}

// MARK: - Size Class Detection

/// Size class helper for adaptive layouts
struct SizeClassDetection {
    
    /// Check if current layout should use compact design
    static func isCompact(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    /// Check if current layout should use regular design
    static func isRegular(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        return horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    /// Determine optimal column count based on size class
    static func columnCount(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> Int {
        if isRegular(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass) {
            // iPad in landscape or large displays
            if DeviceDetection.isiPadPro {
                return 4 // iPad Pro can handle more columns
            } else {
                return 3 // Regular iPad
            }
        } else if horizontalSizeClass == .regular {
            // iPad in portrait or iPhone Plus in landscape
            return 2
        } else {
            // iPhone in portrait
            return 1
        }
    }
    
    /// Get appropriate grid spacing based on size class
    static func gridSpacing(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        if horizontalSizeClass == .regular {
            return DeviceDetection.isiPadPro ? 24 : 20
        } else {
            return 16
        }
    }
    
    /// Determine if sidebar navigation should be used
    static func shouldUseSidebarNavigation(horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        return horizontalSizeClass == .regular
    }
    
    /// Get adaptive spacing based on size classes
    static func adaptiveSpacing(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        if isRegular(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass) {
            return DeviceDetection.isiPadPro ? 24 : 20
        } else if horizontalSizeClass == .regular {
            return 18
        } else {
            return 16
        }
    }
    
    /// Get adaptive padding based on size classes
    static func adaptivePadding(horizontalSizeClass: UserInterfaceSizeClass?, verticalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        if isRegular(horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass) {
            return DeviceDetection.isiPadPro ? 32 : 24
        } else if horizontalSizeClass == .regular {
            return 20
        } else {
            return 16
        }
    }
}

// MARK: - Responsive Design Helpers

/// Helper for creating responsive layouts
struct ResponsiveDesign {
    
    /// Get appropriate font size based on device
    static func fontSize(base: CGFloat) -> CGFloat {
        if DeviceDetection.isiPadPro {
            return base * 1.1 // Slightly larger on iPad Pro
        } else if DeviceDetection.isiPad {
            return base * 1.05 // Slightly larger on regular iPad
        } else {
            return base // Standard size on iPhone
        }
    }
    
    /// Get appropriate padding based on device
    static func padding(base: CGFloat) -> CGFloat {
        if DeviceDetection.isiPadPro {
            return base * 1.5 // More padding on iPad Pro
        } else if DeviceDetection.isiPad {
            return base * 1.25 // More padding on regular iPad
        } else {
            return base // Standard padding on iPhone
        }
    }
    
    /// Get appropriate corner radius based on device
    static func cornerRadius(base: CGFloat) -> CGFloat {
        if DeviceDetection.isiPad {
            return base * 1.2 // Slightly more rounded on iPad
        } else {
            return base
        }
    }
    
    /// Get appropriate minimum touch target size
    static var minimumTouchTarget: CGFloat {
        return 44.0 // Apple's recommended minimum
    }
    
    /// Get appropriate navigation style for device
    static var preferredNavigationStyle: NavigationStyle {
        if DeviceDetection.isiPad {
            return .sidebar // iPad benefits from sidebar navigation
        } else {
            return .tabBar // iPhone uses tab bar navigation
        }
    }
}

/// Navigation style options
enum NavigationStyle {
    case tabBar
    case sidebar
    case hybrid
}

// MARK: - Orientation Detection

/// Orientation helper for layout decisions
struct OrientationDetection {
    
    /// Check if device is in landscape orientation
    static var isLandscape: Bool {
        let orientation = UIDevice.current.orientation
        return orientation.isLandscape
    }
    
    /// Check if device is in portrait orientation
    static var isPortrait: Bool {
        let orientation = UIDevice.current.orientation
        return orientation.isPortrait
    }
    
    /// Get optimal layout direction for current orientation
    static var layoutDirection: LayoutDirection {
        if isLandscape && DeviceDetection.isiPad {
            return .horizontal // iPad landscape benefits from horizontal layouts
        } else {
            return .vertical // Default to vertical layouts
        }
    }
}

/// Layout direction options
enum LayoutDirection {
    case horizontal
    case vertical
    case adaptive
}

// MARK: - SwiftUI Extensions

extension View {
    /// Apply device-specific styling
    func deviceAdaptive() -> some View {
        self.modifier(DeviceAdaptiveModifier())
    }
    
    /// Apply responsive padding
    func responsivePadding(_ base: CGFloat = 16) -> some View {
        self.padding(ResponsiveDesign.padding(base: base))
    }
    
    /// Apply responsive corner radius
    func responsiveCornerRadius(_ base: CGFloat = 8) -> some View {
        self.cornerRadius(ResponsiveDesign.cornerRadius(base: base))
    }
}

/// View modifier for device-adaptive styling
struct DeviceAdaptiveModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: ResponsiveDesign.fontSize(base: 16)))
            .responsivePadding()
    }
}

// MARK: - Environment Values

private struct DeviceTypeKey: EnvironmentKey {
    static let defaultValue: DeviceType = DeviceDetection.deviceType
}

private struct iPadProSizeKey: EnvironmentKey {
    static let defaultValue: iPadProSize? = DeviceDetection.iPadProSize
}

extension EnvironmentValues {
    var deviceType: DeviceType {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }
    
    var iPadProSize: iPadProSize? {
        get { self[iPadProSizeKey.self] }
        set { self[iPadProSizeKey.self] = newValue }
    }
}

// MARK: - Dashboard Tile Calculator

/// Calculator for dashboard tile layouts
struct DashboardTileCalculator {
    
    /// Calculate optimal tile size for available width
    static func calculateTileSize(availableWidth: CGFloat) -> CGFloat {
        guard availableWidth > 0 else { return 100 } // Default size
        
        let columns = calculateColumns(availableWidth: availableWidth)
        let spacing = calculateTileSpacing(availableWidth: availableWidth)
        let totalSpacing = CGFloat(columns - 1) * spacing
        let availableForTiles = availableWidth - totalSpacing - 32 // Account for padding
        
        return max(80, availableForTiles / CGFloat(columns))
    }
    
    /// Calculate optimal spacing between tiles
    static func calculateTileSpacing(availableWidth: CGFloat) -> CGFloat {
        guard availableWidth > 0 else { return 16 }
        
        if availableWidth > 1000 { // iPad Pro 12.9"
            return 20
        } else if availableWidth > 800 { // iPad
            return 16
        } else { // iPhone
            return 12
        }
    }
    
    /// Calculate optimal number of columns
    static func calculateColumns(availableWidth: CGFloat) -> Int {
        guard availableWidth > 0 else { return 1 }
        
        if availableWidth > 1100 { // iPad Pro 12.9" landscape
            return 5
        } else if availableWidth > 900 { // iPad Pro 11" landscape
            return 4
        } else if availableWidth > 700 { // iPad portrait
            return 3
        } else if availableWidth > 400 { // iPhone landscape
            return 2
        } else { // iPhone portrait
            return 1
        }
    }
    
    /// Calculate complete grid layout
    static func calculateGridLayout(tileCount: Int, availableWidth: CGFloat) -> GridLayout {
        let columns = calculateColumns(availableWidth: availableWidth)
        let rows = (tileCount + columns - 1) / columns // Ceiling division
        let tileSize = calculateTileSize(availableWidth: availableWidth)
        let spacing = calculateTileSpacing(availableWidth: availableWidth)
        
        return GridLayout(
            columns: columns,
            rows: rows,
            tileSize: tileSize,
            spacing: spacing
        )
    }
}

/// Grid layout configuration
struct GridLayout {
    let columns: Int
    let rows: Int
    let tileSize: CGFloat
    let spacing: CGFloat
}

// MARK: - Responsive Layout Calculator

/// Calculator for responsive layout sizing
struct ResponsiveLayoutCalculator {
    
    /// Calculate image size that fits within container while maintaining aspect ratio
    static func calculateImageSize(containerSize: CGSize, imageAspectRatio: CGFloat) -> CGSize {
        guard containerSize.width > 0 && containerSize.height > 0 && imageAspectRatio > 0 else {
            return CGSize(width: 100, height: 100) // Default size
        }
        
        let containerAspectRatio = containerSize.width / containerSize.height
        
        if imageAspectRatio > containerAspectRatio {
            // Image is wider than container - fit by width
            let width = containerSize.width
            let height = width / imageAspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Image is taller than container - fit by height
            let height = containerSize.height
            let width = height * imageAspectRatio
            return CGSize(width: width, height: height)
        }
    }
    
    /// Calculate font size based on screen size
    static func calculateFontSize(screenSize: CGSize, baseSize: CGFloat) -> CGFloat {
        guard screenSize.width > 0 && screenSize.height > 0 && baseSize > 0 else {
            return 16 // Default size
        }
        
        let screenArea = screenSize.width * screenSize.height
        let scaleFactor: CGFloat
        
        if screenArea > 1_300_000 { // iPad Pro 12.9"
            scaleFactor = 1.3
        } else if screenArea > 800_000 { // iPad
            scaleFactor = 1.2
        } else if screenArea > 400_000 { // iPhone Plus/Max
            scaleFactor = 1.1
        } else { // Regular iPhone
            scaleFactor = 1.0
        }
        
        return baseSize * scaleFactor
    }
}

// MARK: - Accessibility Helper

/// Helper for accessibility features
struct AccessibilityHelper {
    
    /// Scale size based on content size category
    static func scaledSize(baseSize: CGFloat, category: ContentSizeCategory) -> CGFloat {
        let scaleFactor: CGFloat
        
        switch category {
        case .extraSmall:
            scaleFactor = 0.8
        case .small:
            scaleFactor = 0.9
        case .medium:
            scaleFactor = 1.0
        case .large:
            scaleFactor = 1.1
        case .extraLarge:
            scaleFactor = 1.2
        case .extraExtraLarge:
            scaleFactor = 1.3
        case .extraExtraExtraLarge:
            scaleFactor = 1.4
        case .accessibilityMedium:
            scaleFactor = 1.6
        case .accessibilityLarge:
            scaleFactor = 1.8
        case .accessibilityExtraLarge:
            scaleFactor = 2.0
        case .accessibilityExtraExtraLarge:
            scaleFactor = 2.3
        case .accessibilityExtraExtraExtraLarge:
            scaleFactor = 2.6
        default:
            scaleFactor = 1.0
        }
        
        return baseSize * scaleFactor
    }
    
    /// Ensure minimum touch target size
    static func ensureMinimumTouchTarget(size: CGSize) -> CGSize {
        let minimumSize: CGFloat = 44
        return CGSize(
            width: max(size.width, minimumSize),
            height: max(size.height, minimumSize)
        )
    }
}
