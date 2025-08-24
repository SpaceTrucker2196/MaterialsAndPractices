//
//  PhotoOverlay.swift
//  MaterialsAndPractices
//
//  Extensible class for adding text overlays to farm photos.
//  Designed to be easily modified for additional overlay information.
//
//  Created by AI Assistant on current date.
//

import UIKit
import CoreGraphics

/// Extensible class for adding text overlays to farm photos
/// Design allows easy modification to add additional overlay elements
class PhotoOverlay {
    
    // MARK: - Overlay Configuration
    
    /// Configuration for overlay appearance
    struct OverlayConfig {
        let backgroundColor: UIColor
        let textColor: UIColor
        let font: UIFont
        let cornerRadius: CGFloat
        let padding: CGFloat
        let margin: CGFloat
        let position: OverlayPosition
        
        static let `default` = OverlayConfig(
            backgroundColor: UIColor.black.withAlphaComponent(0.7),
            textColor: .white,
            font: UIFont.boldSystemFont(ofSize: 16),
            cornerRadius: 8,
            padding: 12,
            margin: 20,
            position: .bottomRight
        )
    }
    
    /// Position options for overlay placement
    enum OverlayPosition {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
    
    // MARK: - Public Methods
    
    /// Adds text overlay to an image with farm name and date
    /// - Parameters:
    ///   - image: Original image
    ///   - farmName: Name of the farm
    ///   - date: Date to display (defaults to current date)
    ///   - config: Overlay configuration (defaults to standard config)
    /// - Returns: Image with overlay applied, or nil if failed
    static func addFarmOverlay(
        to image: UIImage,
        farmName: String,
        date: Date = Date(),
        config: OverlayConfig = .default
    ) -> UIImage? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let overlayText = "\(farmName)\n\(formatter.string(from: date))"
        return addOverlay(to: image, with: overlayText, config: config)
    }
    
    /// Generic method for adding text overlay to an image
    /// - Parameters:
    ///   - image: Original image
    ///   - text: Text to overlay
    ///   - config: Overlay configuration
    /// - Returns: Image with overlay applied, or nil if failed
    static func addOverlay(
        to image: UIImage,
        with text: String,
        config: OverlayConfig = .default
    ) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw the original image
        image.draw(at: .zero)
        
        // Calculate text size
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: config.font,
            .foregroundColor: config.textColor
        ]
        
        let textSize = text.boundingRect(
            with: CGSize(width: image.size.width - (config.margin * 2), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: textAttributes,
            context: nil
        ).size
        
        // Calculate overlay frame
        let overlaySize = CGSize(
            width: textSize.width + (config.padding * 2),
            height: textSize.height + (config.padding * 2)
        )
        
        let overlayOrigin = calculateOverlayOrigin(
            imageSize: image.size,
            overlaySize: overlaySize,
            position: config.position,
            margin: config.margin
        )
        
        let overlayFrame = CGRect(origin: overlayOrigin, size: overlaySize)
        
        // Draw overlay background
        let overlayPath = UIBezierPath(roundedRect: overlayFrame, cornerRadius: config.cornerRadius)
        config.backgroundColor.setFill()
        overlayPath.fill()
        
        // Draw text
        let textRect = CGRect(
            x: overlayFrame.origin.x + config.padding,
            y: overlayFrame.origin.y + config.padding,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: textAttributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Extension Points
    
    /// Extension point for custom overlay elements
    /// Override this method to add additional overlay elements like weather, GPS coordinates, etc.
    /// - Parameters:
    ///   - image: Original image
    ///   - overlayData: Custom data structure for additional overlay information
    /// - Returns: Image with custom overlay applied
    static func addCustomOverlay<T>(
        to image: UIImage,
        with overlayData: T,
        config: OverlayConfig = .default
    ) -> UIImage? {
        // Base implementation - can be extended for specific overlay types
        return image
    }
    
    // MARK: - Private Helpers
    
    /// Calculates the origin point for overlay based on position
    private static func calculateOverlayOrigin(
        imageSize: CGSize,
        overlaySize: CGSize,
        position: OverlayPosition,
        margin: CGFloat
    ) -> CGPoint {
        
        switch position {
        case .topLeft:
            return CGPoint(x: margin, y: margin)
            
        case .topRight:
            return CGPoint(
                x: imageSize.width - overlaySize.width - margin,
                y: margin
            )
            
        case .bottomLeft:
            return CGPoint(
                x: margin,
                y: imageSize.height - overlaySize.height - margin
            )
            
        case .bottomRight:
            return CGPoint(
                x: imageSize.width - overlaySize.width - margin,
                y: imageSize.height - overlaySize.height - margin
            )
            
        case .center:
            return CGPoint(
                x: (imageSize.width - overlaySize.width) / 2,
                y: (imageSize.height - overlaySize.height) / 2
            )
        }
    }
}

// MARK: - Future Extension Examples

/*
 Extension examples for additional overlay information:
 
 // GPS Coordinates overlay
 extension PhotoOverlay {
     static func addGPSOverlay(to image: UIImage, latitude: Double, longitude: Double) -> UIImage? {
         let gpsText = "GPS: \(latitude), \(longitude)"
         return addOverlay(to: image, with: gpsText)
     }
 }
 
 // Weather information overlay
 extension PhotoOverlay {
     static func addWeatherOverlay(to image: UIImage, temperature: Double, condition: String) -> UIImage? {
         let weatherText = "\(temperature)°F, \(condition)"
         return addOverlay(to: image, with: weatherText)
     }
 }
 
 // Field information overlay
 extension PhotoOverlay {
     static func addFieldInfoOverlay(to image: UIImage, fieldName: String, acres: Double) -> UIImage? {
         let fieldText = "\(fieldName) - \(acres) acres"
         return addOverlay(to: image, with: fieldText)
     }
 }
 */