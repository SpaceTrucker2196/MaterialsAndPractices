//
//  FarmPhotoView.swift
//  MaterialsAndPractices
//
//  Provides photo capture, management, and display functionality for farms
//  with location data and seasonal organization.
//
//  Created by AI Assistant.
//

import SwiftUI
import CoreData
import UIKit
import CoreLocation

/// Comprehensive photo management view for farm photos
struct FarmPhotoView: View {
    let farm: Farm
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedSeason: String = "Spring"
    @State private var groupBySeason = true
    @StateObject private var locationManager = LocationManager()
    
    @FetchRequest var photos: FetchedResults<FarmPhoto>
    
    init(farm: Farm) {
        self.farm = farm
        self._photos = FetchRequest<FarmPhoto>(
            entity: FarmPhoto.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \FarmPhoto.captureDate, ascending: false)
            ],
            predicate: NSPredicate(format: "farm == %@", farm)
        )
    }
    
    private let seasons = ["Spring", "Summer", "Fall", "Winter"]
    
    /// Photos grouped by season
    private var photosBySeasonAndWeek: [(season: String, photos: [(week: Int, photos: [FarmPhoto])])] {
        let grouped = Dictionary(grouping: Array(photos)) { photo in
            photo.season ?? "Unknown"
        }
        
        return grouped.map { season, seasonPhotos in
            let weekGrouped = Dictionary(grouping: seasonPhotos) { photo in
                Int(photo.week)
            }
            let sortedWeeks = weekGrouped.map { week, weekPhotos in
                (week: week, photos: weekPhotos.sorted { ($0.captureDate ?? Date.distantPast) > ($1.captureDate ?? Date.distantPast) })
            }.sorted { $0.week < $1.week }
            
            return (season: season, photos: sortedWeeks)
        }.sorted { first, second in
            guard let firstIndex = seasons.firstIndex(of: first.season),
                  let secondIndex = seasons.firstIndex(of: second.season) else {
                return first.season < second.season
            }
            return firstIndex < secondIndex
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if photos.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }
            }
            .navigationTitle("Farm Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingCamera = true
                        }) {
                            Label("Take Photo", systemImage: "camera")
                        }
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            groupBySeason.toggle()
                        }) {
                            Label(groupBySeason ? "Group by Date" : "Group by Season", 
                                  systemImage: groupBySeason ? "calendar" : "leaf")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                addPhoto(image: image)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                addPhoto(image: image)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Photos Yet")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Capture photos of your farm to track progress and changes over time.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)
            
            Button(action: {
                showingCamera = true
            }) {
                Label("Take First Photo", systemImage: "camera")
                    .font(AppTheme.Typography.bodyLarge)
                    .foregroundColor(.white)
                    .padding()
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Photo Grid View
    
    private var photoGridView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                if groupBySeason {
                    ForEach(photosBySeasonAndWeek, id: \.season) { seasonGroup in
                        seasonSection(seasonGroup)
                    }
                } else {
                    allPhotosSection
                }
            }
            .padding()
        }
    }
    
    private func seasonSection(_ seasonGroup: (season: String, photos: [(week: Int, photos: [FarmPhoto])])) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(seasonGroup.season)
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(seasonGroup.photos.flatMap { $0.photos }.count) photos")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            ForEach(seasonGroup.photos, id: \.week) { weekGroup in
                weekSection(weekGroup, season: seasonGroup.season)
            }
        }
    }
    
    private func weekSection(_ weekGroup: (week: Int, photos: [FarmPhoto]), season: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Week \(weekGroup.week)")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            photoGrid(for: weekGroup.photos)
        }
    }
    
    private var allPhotosSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("All Photos")
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(photos.count) photos")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            photoGrid(for: Array(photos))
        }
    }
    
    private func photoGrid(for photos: [FarmPhoto]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.small) {
            ForEach(photos, id: \.self) { photo in
                PhotoTile(photo: photo)
                    .onTapGesture {
                        // TODO: Show full-screen photo view
                    }
            }
        }
    }
    
    // MARK: - Methods
    
    private func addPhoto(image: UIImage) {
        let newPhoto = FarmPhoto(context: viewContext)
        newPhoto.farm = farm
        newPhoto.captureDate = Date()
        newPhoto.season = getCurrentSeason()
        newPhoto.week = Int16(getCurrentWeekOfYear())
        
        // Compress and store image data
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            newPhoto.photoData = imageData
        }
        
        // Create thumbnail
        if let thumbnailData = createThumbnail(from: image) {
            newPhoto.thumbnailData = thumbnailData
        }
        
        // Try to get location data
        locationManager.requestLocation { result in
            switch result {
            case .success(let location):
                newPhoto.latitude = location.coordinate.latitude
                newPhoto.longitude = location.coordinate.longitude
            case .failure:
                // Location not available, continue without it
                break
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save photo: \(error)")
            viewContext.delete(newPhoto)
        }
    }
    
    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "Spring"
        case 6...8: return "Summer"
        case 9...11: return "Fall"
        default: return "Winter"
        }
    }
    
    private func getCurrentWeekOfYear() -> Int {
        return Calendar.current.component(.weekOfYear, from: Date())
    }
    
    private func createThumbnail(from image: UIImage) -> Data? {
        let targetSize = CGSize(width: 150, height: 150)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - Photo Tile Component

/// Individual photo tile for grid display
struct PhotoTile: View {
    let photo: FarmPhoto
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraSmall) {
            // Photo thumbnail
            if let thumbnailData = photo.thumbnailData,
               let thumbnail = UIImage(data: thumbnailData) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(AppTheme.CornerRadius.small)
            } else {
                Rectangle()
                    .fill(AppTheme.Colors.backgroundTertiary)
                    .frame(width: 100, height: 100)
                    .cornerRadius(AppTheme.CornerRadius.small)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(.title2)
                    )
            }
            
            // Photo metadata
            VStack(spacing: 2) {
                if let captureDate = photo.captureDate {
                    Text(captureDate.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Text("Week \(photo.week)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Image Picker

/// UIImagePickerController wrapper for SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
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
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct FarmPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let farm = Farm(context: context)
        farm.name = "Sample Farm"
        
        return FarmPhotoView(farm: farm)
            .environment(\.managedObjectContext, context)
    }
}