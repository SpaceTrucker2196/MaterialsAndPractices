//
//  ProfileImageTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for worker profile image functionality including loading, resizing, and data generation.
//  Validates the ImageUtilities class and worker photo management features.
//
//  Created by AI Assistant following Clean Code testing principles.
//

import XCTest
import CoreData
import UIKit
@testable import MaterialsAndPractices

/// Test suite for worker profile image functionality
/// Validates image loading, resizing, and profilePhotoData generation
class ProfileImageTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var mockPersistenceController: PersistenceController!
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Create in-memory Core Data stack for testing
        mockPersistenceController = PersistenceController(inMemory: true)
        mockContext = mockPersistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        mockPersistenceController = nil
        mockContext = nil
    }
    
    // MARK: - Image Loading Tests
    
    /// Tests loading worker profile image from imagePath
    func testLoadWorkerProfileImageFromImagePath() throws {
        // Given: A worker with valid imagePath
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        
        // Create a test image path pointing to a test image
        if let testImagePath = createTestImageFile() {
            worker.imagePath = testImagePath
            
            // When: Loading profile image
            let loadedImage = ImageUtilities.loadWorkerProfileImage(for: worker)
            
            // Then: Should load the image successfully
            XCTAssertNotNil(loadedImage, "Should load image from imagePath")
            XCTAssertGreaterThan(loadedImage?.size.width ?? 0, 0, "Loaded image should have valid dimensions")
            
            // Cleanup
            try? FileManager.default.removeItem(atPath: testImagePath)
        } else {
            XCTFail("Could not create test image file")
        }
    }
    
    /// Tests loading worker profile image from profilePhotoData
    func testLoadWorkerProfileImageFromPhotoData() throws {
        // Given: A worker with profilePhotoData but no imagePath
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.imagePath = nil
        
        // Create test image data
        let testImage = createTestUIImage()
        worker.profilePhotoData = testImage.jpegData(compressionQuality: 0.8)
        
        // When: Loading profile image
        let loadedImage = ImageUtilities.loadWorkerProfileImage(for: worker)
        
        // Then: Should load the image from profilePhotoData
        XCTAssertNotNil(loadedImage, "Should load image from profilePhotoData")
        XCTAssertGreaterThan(loadedImage?.size.width ?? 0, 0, "Loaded image should have valid dimensions")
    }
    
    /// Tests fallback behavior when no image is available
    func testLoadWorkerProfileImageNoneAvailable() throws {
        // Given: A worker with no imagePath or profilePhotoData
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.imagePath = nil
        worker.profilePhotoData = nil
        
        // When: Loading profile image
        let loadedImage = ImageUtilities.loadWorkerProfileImage(for: worker)
        
        // Then: Should return nil
        XCTAssertNil(loadedImage, "Should return nil when no image is available")
    }
    
    // MARK: - Profile Photo Data Generation Tests
    
    /// Tests generating profilePhotoData from imagePath
    func testGenerateProfilePhotoDataFromImagePath() throws {
        // Given: A worker with imagePath but no profilePhotoData
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.profilePhotoData = nil
        
        if let testImagePath = createTestImageFile() {
            worker.imagePath = testImagePath
            
            // When: Generating profilePhotoData
            let result = ImageUtilities.generateProfilePhotoDataIfNeeded(for: worker, context: mockContext)
            
            // Then: Should generate and save profilePhotoData
            XCTAssertTrue(result, "Should successfully generate profilePhotoData")
            XCTAssertNotNil(worker.profilePhotoData, "Worker should now have profilePhotoData")
            
            // Verify the generated image has correct dimensions
            if let photoData = worker.profilePhotoData,
               let savedImage = UIImage(data: photoData) {
                XCTAssertEqual(savedImage.size.width, 300, accuracy: 1.0, "Generated image should be 300px wide")
                XCTAssertEqual(savedImage.size.height, 300, accuracy: 1.0, "Generated image should be 300px tall")
            } else {
                XCTFail("Generated profilePhotoData should contain valid image")
            }
            
            // Cleanup
            try? FileManager.default.removeItem(atPath: testImagePath)
        } else {
            XCTFail("Could not create test image file")
        }
    }
    
    /// Tests that profilePhotoData generation is skipped when data already exists
    func testGenerateProfilePhotoDataSkippedWhenExists() throws {
        // Given: A worker with existing profilePhotoData
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        
        let testImage = createTestUIImage()
        let originalData = testImage.jpegData(compressionQuality: 0.8)
        worker.profilePhotoData = originalData
        
        // When: Attempting to generate profilePhotoData
        let result = ImageUtilities.generateProfilePhotoDataIfNeeded(for: worker, context: mockContext)
        
        // Then: Should skip generation and return false
        XCTAssertFalse(result, "Should skip generation when profilePhotoData already exists")
        XCTAssertEqual(worker.profilePhotoData, originalData, "Original profilePhotoData should be unchanged")
    }
    
    // MARK: - Image Resizing Tests
    
    /// Tests image resizing to standard profile photo size
    func testResizeImageToProfileSize() throws {
        // Given: A test image
        let originalImage = createTestUIImage(size: CGSize(width: 800, height: 600))
        
        // When: Resizing to profile photo size
        let resizedImage = ImageUtilities.resizeImage(originalImage, to: ImageUtilities.profilePhotoSize)
        
        // Then: Should resize to 300x300
        XCTAssertNotNil(resizedImage, "Should successfully resize image")
        XCTAssertEqual(resizedImage?.size.width, 300, accuracy: 1.0, "Resized image should be 300px wide")
        XCTAssertEqual(resizedImage?.size.height, 300, accuracy: 1.0, "Resized image should be 300px tall")
    }
    
    /// Tests circular image cropping
    func testMakeCircularImage() throws {
        // Given: A test image
        let originalImage = createTestUIImage()
        
        // When: Making image circular
        let circularImage = ImageUtilities.makeCircularImage(originalImage)
        
        // Then: Should return a valid circular image
        XCTAssertNotNil(circularImage, "Should successfully create circular image")
        
        // Note: Testing actual circular shape would require pixel-level analysis
        // which is beyond the scope of unit tests. We verify the operation succeeds.
    }
    
    // MARK: - Integration Tests
    
    /// Tests complete worker profile photo workflow
    func testCompleteProfilePhotoWorkflow() throws {
        // Given: A worker with imagePath
        let worker = Worker(context: mockContext)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.profilePhotoData = nil
        
        if let testImagePath = createTestImageFile() {
            worker.imagePath = testImagePath
            
            try mockContext.save()
            
            // When: Going through complete workflow
            // 1. Generate profilePhotoData from imagePath
            let generated = ImageUtilities.generateProfilePhotoDataIfNeeded(for: worker, context: mockContext)
            XCTAssertTrue(generated, "Should generate profilePhotoData")
            
            // 2. Load image using utility function
            let loadedImage = ImageUtilities.loadWorkerProfileImage(for: worker)
            XCTAssertNotNil(loadedImage, "Should load image successfully")
            
            // 3. Verify image properties
            if let image = loadedImage {
                XCTAssertGreaterThan(image.size.width, 0, "Loaded image should have valid width")
                XCTAssertGreaterThan(image.size.height, 0, "Loaded image should have valid height")
            }
            
            // Cleanup
            try? FileManager.default.removeItem(atPath: testImagePath)
        } else {
            XCTFail("Could not create test image file")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test UIImage for testing purposes
    private func createTestUIImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    /// Creates a temporary test image file
    private func createTestImageFile() -> String? {
        let testImage = createTestUIImage()
        guard let imageData = testImage.jpegData(compressionQuality: 0.8) else { return nil }
        
        let tempDir = NSTemporaryDirectory()
        let fileName = "test_profile_\(UUID().uuidString).jpg"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: URL(fileURLWithPath: filePath))
            return filePath
        } catch {
            return nil
        }
    }
}