//
//  FarmDetailView.swift
//  MaterialsAndPractices
//
//  Provides comprehensive farm detail view with map integration, lease information,
//  and photo management functionality.
//
//  Created by AI Assistant.
//

import SwiftUI
import CoreData
import MapKit

/// Comprehensive farm detail view displaying all farm information and management options
struct FarmDetailView: View {
    let farm: Farm
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditFarm = false
    @State private var region: MKCoordinateRegion
    
    init(farm: Farm) {
        self.farm = farm
        // Initialize map region based on farm coordinates
        let coordinate = CLLocationCoordinate2D(
            latitude: farm.latitude,
            longitude: farm.longitude
        )
        
        // If coordinates are not set (0,0), use a default location
        let isValidCoordinate = farm.latitude != 0 || farm.longitude != 0
        let mapCoordinate = isValidCoordinate ? coordinate : CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795) // Center of US
        
        self._region = State(initialValue: MKCoordinateRegion(
            center: mapCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // MARK: - Map Section
                if farm.latitude != 0 || farm.longitude != 0 {
                    mapSection
                }
                
                // MARK: - Farm Information Section
                farmInformationSection
                
                // MARK: - Address Information Section
                addressInformationSection
                
                // MARK: - Lease Information Section
                if hasLeaseInfo {
                    leaseInformationSection
                }
                
                // MARK: - Photos Section
                photosSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(farm.name ?? "Farm Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditFarm = true
                }
            }
        }
        .sheet(isPresented: $showingEditFarm) {
            EditFarmView(farm: farm, isPresented: $showingEditFarm)
        }
    }
    
    // MARK: - Map Section
    
    /// Map view showing the farm location
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Location")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    openInMaps()
                }) {
                    Label("Open in Maps", systemImage: "map")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            Map(coordinateRegion: .constant(region), annotationItems: [FarmAnnotation(farm: farm)]) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    VStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                            .font(.title2)
                        Text(annotation.title)
                            .font(AppTheme.Typography.bodySmall)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(AppTheme.CornerRadius.small)
                            .shadow(radius: 2)
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .onTapGesture {
                openInMaps()
            }
        }
    }
    
    // MARK: - Methods
    
    /// Opens the farm location in Apple Maps
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: farm.latitude, longitude: farm.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = farm.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    // MARK: - Farm Information Section
    
    /// Section displaying basic farm information
    private var farmInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Farm Information")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                
                if let description = farm.farmDescription, !description.isEmpty {
                    DetailCard(
                        title: "Description",
                        value: description,
                        backgroundColor: AppTheme.Colors.backgroundTertiary,
                        titleColor: AppTheme.Colors.textSecondary
                    )
                }
                
                if farm.totalAcres > 0 {
                    DetailCard(
                        title: "Total Acres",
                        value: farm.totalAcres.formatted(.number.precision(.fractionLength(1))),
                        backgroundColor: AppTheme.Colors.organicMaterial.opacity(0.1),
                        titleColor: AppTheme.Colors.organicMaterial
                    )
                }
            }
        }
    }
    
    // MARK: - Address Information Section
    
    /// Section displaying farm address information
    private var addressInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Address")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                if let address = farm.address, !address.isEmpty {
                    Text(address)
                        .font(AppTheme.Typography.bodyMedium)
                }
                
                HStack {
                    if let city = farm.city, !city.isEmpty {
                        Text(city)
                    }
                    if let state = farm.state, !state.isEmpty {
                        Text(state)
                    }
                    if let zip = farm.zip, !zip.isEmpty {
                        Text(zip)
                    }
                }
                .font(AppTheme.Typography.bodyMedium)
                
                if let county = farm.county, !county.isEmpty {
                    Text("County: \(county)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Lease Information Section
    
    /// Section displaying lease information if available
    private var leaseInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Lease Information")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                
                if farm.leaseAcres > 0 {
                    DetailCard(
                        title: "Lease Acres",
                        value: "-" + farm.leaseAcres.formatted(.number.precision(.fractionLength(2))),
                        backgroundColor: AppTheme.Colors.primary.opacity(0.1),
                        titleColor: AppTheme.Colors.primary
                    )
                }
                
                if let leaseTerm = farm.leaseTerm, !leaseTerm.isEmpty {
                    DetailCard(
                        title: "Lease Term",
                        value: leaseTerm,
                        backgroundColor: AppTheme.Colors.organicPractice.opacity(0.1),
                        titleColor: AppTheme.Colors.organicPractice
                    )
                }
                
                if farm.leaseAmount > 0 {
                    DetailCard(
                        title: "Lease Amount",
                        value: "$" + farm.leaseAmount.formatted(.number.precision(.fractionLength(2))),
                        backgroundColor: AppTheme.Colors.success.opacity(0.1),
                        titleColor: AppTheme.Colors.success
                    )
                }
                
                if let paymentDate = farm.leasePaymentDate {
                    DetailCard(
                        title: "Payment Date",
                        value: paymentDate.formatted(date: .abbreviated, time: .omitted),
                        backgroundColor: AppTheme.Colors.warning.opacity(0.1),
                        titleColor: AppTheme.Colors.warning
                    )
                }
            }
            
            // Property Owner Information
            if hasPropertyOwnerInfo {
                propertyOwnerSection
            }
        }
    }
    
    // MARK: - Property Owner Section
    
    /// Section displaying property owner information
    private var propertyOwnerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Property Owner")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                if let ownerName = farm.propertyOwnerName, !ownerName.isEmpty {
                    Text(ownerName)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                }
                
                if let ownerPhone = farm.propertyOwnerPhone, !ownerPhone.isEmpty {
                    Text("Phone: \(ownerPhone)")
                        .font(AppTheme.Typography.bodyMedium)
                }
                
                if let ownerEmail = farm.propertyOwnerEmail, !ownerEmail.isEmpty {
                    Text("Email: \(ownerEmail)")
                        .font(AppTheme.Typography.bodyMedium)
                }
                
                if let ownerAddress = farm.propertyOwnerAddress, !ownerAddress.isEmpty {
                    Text("Address: \(ownerAddress)")
                        .font(AppTheme.Typography.bodyMedium)
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundTertiary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Photos Section
    
    /// Section displaying farm photos with thumbnail grid
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Photos")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: FarmPhotoView(farm: farm)) {
                    Text("View All")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let photos = farm.photos?.allObjects as? [FarmPhoto], !photos.isEmpty {
                let sortedPhotos = photos.sorted { ($0.captureDate ?? Date.distantPast) > ($1.captureDate ?? Date.distantPast) }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.small) {
                    ForEach(sortedPhotos.prefix(3), id: \.self) { photo in
                        NavigationLink(destination: FarmPhotoView(farm: farm)) {
                            PhotoThumbnailCard(photo: photo)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if photos.count > 3 {
                    HStack {
                        Spacer()
                        NavigationLink(destination: FarmPhotoView(farm: farm)) {
                            Text("View \(photos.count - 3) more photos")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        Spacer()
                    }
                    .padding(.top, AppTheme.Spacing.small)
                }
            } else {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Text("No photos available")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    NavigationLink(destination: FarmPhotoView(farm: farm)) {
                        Label("Add Photos", systemImage: "camera")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                .padding()
                .background(AppTheme.Colors.backgroundTertiary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Check if farm has lease information to display
    private var hasLeaseInfo: Bool {
        return farm.leaseAcres > 0 ||
               !(farm.leaseTerm?.isEmpty ?? true) ||
               farm.leaseAmount > 0 ||
               farm.leasePaymentDate != nil ||
               hasPropertyOwnerInfo
    }
    
    /// Check if farm has property owner information
    private var hasPropertyOwnerInfo: Bool {
        return !(farm.propertyOwnerName?.isEmpty ?? true) ||
               !(farm.propertyOwnerPhone?.isEmpty ?? true) ||
               !(farm.propertyOwnerEmail?.isEmpty ?? true) ||
               !(farm.propertyOwnerAddress?.isEmpty ?? true)
    }
}

// MARK: - Supporting Views

/// Farm annotation for map display
struct FarmAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    
    init(farm: Farm) {
        self.coordinate = CLLocationCoordinate2D(latitude: farm.latitude, longitude: farm.longitude)
        self.title = farm.name ?? "Farm"
    }
}

/// Reusable card component for displaying farm detail information
private struct DetailCard: View {
    let title: String
    let value: String
    let backgroundColor: Color
    let titleColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(titleColor)
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Photo thumbnail component for displaying farm photos
private struct PhotoThumbnailCard: View {
    let photo: FarmPhoto
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraSmall) {
            // Photo thumbnail
            if let thumbnailData = photo.thumbnailData,
               let thumbnail = UIImage(data: thumbnailData) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(AppTheme.CornerRadius.small)
            } else {
                Rectangle()
                    .fill(AppTheme.Colors.backgroundTertiary)
                    .frame(width: 80, height: 80)
                    .cornerRadius(AppTheme.CornerRadius.small)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(.title3)
                    )
            }
            
            // Photo metadata
            if let captureDate = photo.captureDate {
                Text(captureDate.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

struct FarmDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let farm = Farm(context: context)
        farm.name = "Sample Farm"
        farm.address = "123 Farm Road"
        farm.city = "Farmville"
        farm.state = "IA"
        farm.totalAcres = 100.0
        
        return FarmDetailView(farm: farm)
            .environment(\.managedObjectContext, context)
    }
}
