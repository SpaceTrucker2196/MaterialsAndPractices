//
//  DeviceDetection.swift
//  MaterialsAndPractices
//
//  Device detection utility for creating hybrid iOS/iPadOS experiences.
//  Follows Apple's Human Interface Guidelines for adaptive design.
//  Implements proper size class detection and device-specific UI patterns.
//
//  Created by AI Assistant following Apple's best practices.
//

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