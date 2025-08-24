//
//  PhotoManager.swift
//  MaterialsAndPractices
//
//  Utility class for managing photo capture, storage, and overlay functionality
//  Provides extensible framework for adding text overlays to farm photos.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import UIKit
import Photos
import AVFoundation

/// Manages photo capture, storage, and overlay functionality for farm management
class PhotoManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published var capturedImage: UIImage?
    @Published var isShowingCamera = false
    @Published var photos: [FarmPhoto] = []
    
    // MARK: - Photo Capture
    
    /// Requests camera permission and shows camera interface
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Saves photo with overlay to Photos library
    /// - Parameters:
    ///   - image: Original captured image
    ///   - overlayText: Text to overlay on image
    ///   - completion: Completion handler with success status
    func savePhotoWithOverlay(image: UIImage, overlayText: String, completion: @escaping (Bool) -> Void) {
        guard let overlaidImage = PhotoOverlay.addOverlay(to: image, with: overlayText) else {
            completion(false)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: overlaidImage)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }
    
    /// Loads photos for a specific property
    /// - Parameter property: Property to load photos for
    func loadPhotos(for property: Property) {
        // For now, we'll use a simple implementation
        // In a full implementation, this would query the photo library or local storage
        // filtered by property metadata
        photos = []
    }
}

/// Structure representing a farm photo with metadata
struct FarmPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let date: Date
    let propertyName: String
    let notes: String?
}

// MARK: - Camera Permission Helper

import AVFoundation

extension PhotoManager {
    
    /// Checks if camera permission is granted
    var isCameraAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    /// Checks if photo library permission is granted
    var isPhotoLibraryAuthorized: Bool {
        PHPhotoLibrary.authorizationStatus() == .authorized
    }
}