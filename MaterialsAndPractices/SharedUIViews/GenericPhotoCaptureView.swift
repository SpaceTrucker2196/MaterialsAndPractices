//
//  GenericPhotoCaptureView.swift
//  MaterialsAndPractices
//
//  Generic camera interface for capturing photos for different entity types.
//  Supports Farmer, Property, Field, and other entities with photo storage.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import UIKit
import CoreData

/// Generic photo capture view that can work with different entity types
struct GenericPhotoCaptureView: UIViewControllerRepresentable {
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    let onImageCaptured: (UIImage) -> Void
    
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
        let parent: GenericPhotoCaptureView
        
        init(_ parent: GenericPhotoCaptureView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
                parent.isPresented = false
                return
            }
            
            // Call the completion handler with the captured image
            parent.onImageCaptured(image)
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

/// Convenience initializer for Farmer photo capture
extension GenericPhotoCaptureView {
    init(farmer: Farmer?, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.onImageCaptured = { image in
            // Compress image and save to farmer
            if let farmer = farmer,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                farmer.profilePhotoData = imageData
                
                // Save context
                do {
                    try farmer.managedObjectContext?.save()
                } catch {
                    print("Error saving farmer photo: \(error)")
                }
            }
        }
    }
}

/// Photo capture view specifically for farmer profiles
//struct PhotoCaptureView: View {
//    let farmer: Farmer?
//    @Binding var isPresented: Bool
//    @State private var showingImagePicker = false
//    @State private var showingPhotoLibrary = false
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: AppTheme.Spacing.large) {
//                Text("Add Profile Photo")
//                    .font(AppTheme.Typography.headlineLarge)
//                    .foregroundColor(AppTheme.Colors.textPrimary)
//                
//                VStack(spacing: AppTheme.Spacing.medium) {
//                    Button(action: {
//                        showingImagePicker = true
//                    }) {
//                        Label("Take Photo", systemImage: "camera.fill")
//                            .font(AppTheme.Typography.bodyLarge)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(AppTheme.Colors.primary)
//                            .cornerRadius(AppTheme.CornerRadius.medium)
//                    }
//                    
//                    Button(action: {
//                        showingPhotoLibrary = true
//                    }) {
//                        Label("Choose from Library", systemImage: "photo.fill")
//                            .font(AppTheme.Typography.bodyLarge)
//                            .foregroundColor(AppTheme.Colors.primary)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(AppTheme.Colors.backgroundSecondary)
//                            .cornerRadius(AppTheme.CornerRadius.medium)
//                    }
//                }
//                
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("Profile Photo")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        isPresented = false
//                    }
//                }
//            }
//        }
//        .sheet(isPresented: $showingImagePicker) {
//            GenericPhotoCaptureView(farmer: farmer, isPresented: $showingImagePicker)
//        }
//        .sheet(isPresented: $showingPhotoLibrary) {
//            PhotoLibraryPicker(farmer: farmer, isPresented: $showingPhotoLibrary)
//        }
//    }
//}

/// Photo library picker for selecting existing photos
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let farmer: Farmer?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
                parent.isPresented = false
                return
            }
            
            // Compress image and save to farmer
            if let farmer = parent.farmer,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                farmer.profilePhotoData = imageData
                
                // Save context
                do {
                    try farmer.managedObjectContext?.save()
                } catch {
                    print("Error saving farmer photo: \(error)")
                }
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
