//
//  PhotoCaptureView.swift
//  MaterialsAndPractices
//
//  Camera interface for capturing farm photos with overlay functionality.
//  Integrates with PhotoOverlay for adding farm name and date information.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import UIKit

/// Camera interface for capturing farm photos
struct PhotoCaptureView: UIViewControllerRepresentable {
    // MARK: - Properties
    
    let property: Property
    @Binding var isPresented: Bool
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoCaptureView
        
        init(_ parent: PhotoCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
                parent.isPresented = false
                return
            }
            
            // Add farm overlay to the captured image
            let farmName = parent.property.displayName ?? "Farm Property"
            
            if let overlaidImage = PhotoOverlay.addFarmOverlay(to: image, farmName: farmName) {
                // Save the overlaid image to photo library
                let photoManager = PhotoManager()
                photoManager.savePhotoWithOverlay(image: overlaidImage, overlayText: "") { success in
                    DispatchQueue.main.async {
                        // Handle save result if needed
                        if success {
                            print("Photo saved successfully with overlay")
                        } else {
                            print("Failed to save photo with overlay")
                        }
                    }
                }
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

/// Alternative SwiftUI camera view with more control
struct CameraCaptureView: View {
    // MARK: - Properties
    
    let property: Property
    @Binding var isPresented: Bool
    @StateObject private var photoManager = PhotoManager()
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.large) {
                
                if let image = capturedImage {
                    // Show captured image preview
                    imagePreviewSection(image: image)
                } else {
                    // Show camera interface
                    cameraInterfaceSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Capture Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                if capturedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            savePhotoWithOverlay()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage)
        }
        .alert("Photo Status", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    isPresented = false
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Components
    
    /// Camera interface section
    private var cameraInterfaceSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "camera.fill")
                .font(.system(size: 72))
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("Capture Photo for \(property.displayName ?? "Property")")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Photos will include property name and timestamp overlay")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                requestCameraPermissionAndShowPicker()
            }) {
                Label("Take Photo", systemImage: "camera")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(.white)
                    .padding()
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    /// Image preview section
    private func imagePreviewSection(image: UIImage) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Preview with overlay
            if let overlaidImage = PhotoOverlay.addFarmOverlay(to: image, farmName: property.displayName ?? "Property") {
                Image(uiImage: overlaidImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            Text("Preview with overlay applied")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.medium) {
                Button("Retake") {
                    capturedImage = nil
                }
                .foregroundColor(AppTheme.Colors.error)
                
                Spacer()
                
                Button("Use Photo") {
                    savePhotoWithOverlay()
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
            .font(AppTheme.Typography.bodyMedium)
        }
    }
    
    // MARK: - Methods
    
    /// Requests camera permission and shows image picker
    private func requestCameraPermissionAndShowPicker() {
        photoManager.requestCameraPermission { granted in
            if granted {
                showingImagePicker = true
            } else {
                alertMessage = "Camera permission is required to take photos"
                showingAlert = true
            }
        }
    }
    
    /// Saves the captured photo with overlay
    private func savePhotoWithOverlay() {
        guard let image = capturedImage else { return }
        
        let farmName = property.displayName ?? "Property"
        
        photoManager.savePhotoWithOverlay(image: image, overlayText: farmName) { success in
            if success {
                alertMessage = "Photo saved successfully with farm overlay"
            } else {
                alertMessage = "Failed to save photo. Please check permissions."
            }
            showingAlert = true
        }
    }
}

/// UIKit image picker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview Provider

struct PhotoCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoCaptureView(property: Property(), isPresented: .constant(true))
    }
}