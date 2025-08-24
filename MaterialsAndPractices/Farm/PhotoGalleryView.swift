//
//  PhotoGalleryView.swift
//  MaterialsAndPractices
//
//  Tile-based photo gallery interface sorted by date
//  Displays farm photos in a grid layout with date organization.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import PhotosUI

/// Tile-based photo gallery view for farm photos
struct PhotoGalleryView: View {
    // MARK: - Properties
    
    let property: Property
    @StateObject private var photoManager = PhotoManager()
    @State private var selectedPhoto: FarmPhoto?
    @State private var showingPhotoDetail = false
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.small),
        GridItem(.flexible(), spacing: AppTheme.Spacing.small),
        GridItem(.flexible(), spacing: AppTheme.Spacing.small)
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if photoManager.photos.isEmpty {
                emptyStateView
            } else {
                photoGridView
            }
        }
        .onAppear {
            photoManager.loadPhotos(for: property)
        }
        .sheet(isPresented: $showingPhotoDetail) {
            if let photo = selectedPhoto {
                PhotoDetailView(photo: photo)
            }
        }
    }
    
    // MARK: - Components
    
    /// Empty state view when no photos are available
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No photos yet")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("Add photos using the camera button")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Grid view displaying photo tiles
    private var photoGridView: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
            ForEach(sortedPhotos) { photo in
                PhotoTile(photo: photo) {
                    selectedPhoto = photo
                    showingPhotoDetail = true
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Photos sorted by date (newest first)
    private var sortedPhotos: [FarmPhoto] {
        photoManager.photos.sorted { $0.date > $1.date }
    }
}

/// Individual photo tile component
struct PhotoTile: View {
    // MARK: - Properties
    
    let photo: FarmPhoto
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Photo image
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .clipped()
                
                // Date overlay
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(photo.date, style: .date)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(photo.date, style: .time)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.small)
                .background(AppTheme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: AppTheme.Colors.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

/// Detailed photo view modal
struct PhotoDetailView: View {
    // MARK: - Properties
    
    let photo: FarmPhoto
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Full-size photo
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Photo metadata
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    InfoRow(
                        label: "Property:",
                        value: photo.propertyName
                    )
                    
                    InfoRow(
                        label: "Date:",
                        value: DateFormatter.longStyle.string(from: photo.date)
                    )
                    
                    if let notes = photo.notes, !notes.isEmpty {
                        InfoRow(
                            label: "Notes:",
                            value: notes
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .padding()
            .navigationTitle("Photo Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let longStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview Provider

struct PhotoGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGalleryView(property: Property())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding()
    }
}