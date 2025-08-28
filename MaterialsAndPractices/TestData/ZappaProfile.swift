//
//  ZappaProfile.swift
//  MaterialsAndPractices
//
//  Common profile utility for managing random profile image selection.
//  Provides functionality to select random profile images from the bundle resources.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import UIKit

/// Common profile utility class for managing profile images
/// Provides functionality to select random ZappaProfile images from bundle resources
class ZappaProfile {
    
    /// Get a random image path from available ZappaProfile images in the bundle
    /// - Returns: Path to a random ZappaProfile image, or nil if no images found
    static func getRandomImagePath() -> String? {
        // Get all ZappaProfile images from the TestData bundle
        guard let bundlePath = Bundle.main.path(forResource: "TestData", ofType: nil),
              let testDataBundle = Bundle(path: bundlePath) else {
            // Fallback: look in main bundle for TestData directory
            return getRandomImagePathFromMainBundle()
        }
        
        let fileManager = FileManager.default
        
        do {
            let testDataPath = testDataBundle.bundlePath
            let contents = try fileManager.contentsOfDirectory(atPath: testDataPath)
            
            // Filter for ZappaProfile images
            let zappaProfileImages = contents.filter { filename in
                filename.hasPrefix("ZappaProfile") &&
                (filename.lowercased().hasSuffix(".png") ||
                 filename.lowercased().hasSuffix(".jpg") ||
                 filename.lowercased().hasSuffix(".jpeg"))
            }
            
            guard !zappaProfileImages.isEmpty else {
                print("⚠️ No ZappaProfile images found in TestData bundle")
                return nil
            }
            
            // Select random image
            let randomImage = zappaProfileImages.randomElement()!
            let imagePath = "\(testDataPath)/\(randomImage)"
            
            print("✅ Selected random ZappaProfile image: \(randomImage)")
            return imagePath
            
        } catch {
            print("❌ Error reading TestData directory: \(error)")
            return nil
        }
    }
    
    /// Fallback method to get random image path from main bundle TestData directory
    /// - Returns: Path to a random ZappaProfile image, or nil if no images found
    private static func getRandomImagePathFromMainBundle() -> String? {
        guard let testDataPath = Bundle.main.path(forResource: "TestData", ofType: nil) else {
            // Look for images directly in main bundle if TestData directory not found
            return getRandomImagePathFromBundle()
        }
        
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: testDataPath)
            
            // Filter for ZappaProfile images
            let zappaProfileImages = contents.filter { filename in
                filename.hasPrefix("ZappaProfile") &&
                (filename.lowercased().hasSuffix(".png") ||
                 filename.lowercased().hasSuffix(".jpg") ||
                 filename.lowercased().hasSuffix(".jpeg"))
            }
            
            guard !zappaProfileImages.isEmpty else {
                print("⚠️ No ZappaProfile images found in main bundle TestData")
                return getRandomImagePathFromBundle()
            }
            
            // Select random image
            let randomImage = zappaProfileImages.randomElement()!
            let imagePath = "\(testDataPath)/\(randomImage)"
            
            print("✅ Selected random ZappaProfile image from main bundle: \(randomImage)")
            return imagePath
            
        } catch {
            print("❌ Error reading main bundle TestData directory: \(error)")
            return getRandomImagePathFromBundle()
        }
    }
    
    /// Final fallback to search for ZappaProfile images anywhere in the main bundle
    /// - Returns: Path to a random ZappaProfile image, or nil if no images found
    private static func getRandomImagePathFromBundle() -> String? {
        let fileManager = FileManager.default
        let bundlePath = Bundle.main.bundlePath  // FIX: bundlePath is non-optional
        
        do {
            // Recursive search for ZappaProfile images
            let zappaProfileImages = try findZappaProfileImages(in: bundlePath, fileManager: fileManager)
            
            guard !zappaProfileImages.isEmpty else {
                print("⚠️ No ZappaProfile images found anywhere in bundle")
                return nil
            }
            
            // Select random image
            let randomImagePath = zappaProfileImages.randomElement()!
            let filename = URL(fileURLWithPath: randomImagePath).lastPathComponent
            
            print("✅ Selected random ZappaProfile image from bundle search: \(filename)")
            return randomImagePath
            
        } catch {
            print("❌ Error searching for ZappaProfile images: \(error)")
            return nil
        }
    }
    
    /// Recursively find ZappaProfile images in a directory
    /// - Parameters:
    ///   - directory: Directory path to search
    ///   - fileManager: FileManager instance
    /// - Returns: Array of full paths to ZappaProfile images
    private static func findZappaProfileImages(in directory: String, fileManager: FileManager) throws -> [String] {
        var zappaProfileImages: [String] = []
        
        let contents = try fileManager.contentsOfDirectory(atPath: directory)
        
        for item in contents {
            let itemPath = "\(directory)/\(item)"
            var isDirectory: ObjCBool = false
            
            if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Recursively search subdirectories
                    let subImages = try findZappaProfileImages(in: itemPath, fileManager: fileManager)
                    zappaProfileImages.append(contentsOf: subImages)
                } else if item.hasPrefix("ZappaProfile") &&
                          (item.lowercased().hasSuffix(".png") ||
                           item.lowercased().hasSuffix(".jpg") ||
                           item.lowercased().hasSuffix(".jpeg")) {
                    zappaProfileImages.append(itemPath)
                }
            }
        }
        
        return zappaProfileImages
    }
    
    /// Check if an image exists at the given path
    /// - Parameter imagePath: Path to check
    /// - Returns: True if image exists and can be loaded
    static func imageExists(at imagePath: String?) -> Bool {
        guard let imagePath = imagePath else { return false }
        return FileManager.default.fileExists(atPath: imagePath)
    }
    
    /// Load UIImage from the given path
    /// - Parameter imagePath: Path to the image file
    /// - Returns: UIImage if successfully loaded, nil otherwise
    static func loadImage(from imagePath: String?) -> UIImage? {
        guard let imagePath = imagePath,
              imageExists(at: imagePath) else {
            return nil
        }
        return UIImage(contentsOfFile: imagePath)
    }
}
