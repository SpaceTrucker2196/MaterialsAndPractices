//
//  ImageUtilities.swift
//  MaterialsAndPractices
//
//  Utility functions for image processing, resizing, and profile photo management.
//  Provides standardized image handling for worker profile photos with consistent sizing.
//
//  Created by AI Assistant following Clean Code principles.
//

import UIKit
import CoreData

/// Utility class for image processing and management
struct ImageUtilities {
    
    /// Standard size for profile photos (300x300)
    static let profilePhotoSize = CGSize(width: 300, height: 300)
    
    /// Load worker profile image with fallback chain: imagePath -> profilePhotoData -> default
    /// - Parameter worker: Worker entity to load profile image for
    /// - Returns: UIImage if available, nil if no image can be loaded
    static func loadWorkerProfileImage(for worker: Worker) -> UIImage? {
        // First try to load from imagePath
        if let imagePath = worker.imagePath,
           let image = UIImage(contentsOfFile: imagePath) {
            return image
        }
        
        // Fallback to profilePhotoData
        if let photoData = worker.profilePhotoData,
           let image = UIImage(data: photoData) {
            return image
        }
        
        return nil
    }
    
    /// Generate and save profilePhotoData from imagePath if profilePhotoData is empty
    /// - Parameters:
    ///   - worker: Worker entity to process
    ///   - context: Core Data managed object context
    /// - Returns: True if profilePhotoData was generated and saved, false otherwise
    @discardableResult
    static func generateProfilePhotoDataIfNeeded(for worker: Worker, context: NSManagedObjectContext) -> Bool {
        // Skip if profilePhotoData already exists
        if worker.profilePhotoData != nil {
            return false
        }
        
        // Try to load image from imagePath
        guard let imagePath = worker.imagePath,
              let originalImage = UIImage(contentsOfFile: imagePath) else {
            return false
        }
        
        // Resize image to standard profile photo size
        guard let resizedImage = resizeImage(originalImage, to: profilePhotoSize),
              let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            return false
        }
        
        // Save to worker entity
        worker.profilePhotoData = imageData
        
        do {
            try context.save()
            return true
        } catch {
            print("Error saving profilePhotoData: \(error)")
            return false
        }
    }
    
    /// Resize image to specified size maintaining aspect ratio and center cropping
    /// - Parameters:
    ///   - image: Original image to resize
    ///   - size: Target size for the resized image
    /// - Returns: Resized UIImage or nil if resizing fails
    static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        let originalSize = image.size
        let targetSize = size
        
        // Calculate scale to fill the target size
        let scaleX = targetSize.width / originalSize.width
        let scaleY = targetSize.height / originalSize.height
        let scale = max(scaleX, scaleY)
        
        // Calculate the scaled size
        let scaledSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        // Calculate crop rect to center the image
        let cropRect = CGRect(
            x: (scaledSize.width - targetSize.width) / 2,
            y: (scaledSize.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // Draw the scaled image
        let drawRect = CGRect(
            x: -cropRect.origin.x,
            y: -cropRect.origin.y,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        image.draw(in: drawRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Create a circular cropped version of an image
    /// - Parameter image: Image to make circular
    /// - Returns: Circular cropped UIImage
    static func makeCircularImage(_ image: UIImage) -> UIImage? {
        let size = min(image.size.width, image.size.height)
        let targetSize = CGSize(width: size, height: size)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.addEllipse(in: CGRect(origin: .zero, size: targetSize))
        context?.clip()
        
        let drawRect = CGRect(
            x: (targetSize.width - image.size.width) / 2,
            y: (targetSize.height - image.size.height) / 2,
            width: image.size.width,
            height: image.size.height
        )
        
        image.draw(in: drawRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}