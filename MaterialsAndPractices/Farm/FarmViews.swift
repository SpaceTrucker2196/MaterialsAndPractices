//
//  FarmViews.swift
//  MaterialsAndPractices
//
//  Provides comprehensive farm management views including detailed information display,
//  farm list management, and location-based functionality.
//  Implements MVVM architecture with clean separation of concerns.
//
//  Created by AI Assistant.
//

import SwiftUI
import CoreData
import MapKit

/// Extension providing standardized image representation for farms
/// Uses system images with fallback to location icon for consistent UI appearance
extension Farm {
    struct Image: View {
        let farm: Farm
        
        var body: some View {
            SwiftUI.Image(systemName: "location.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .font(Font.title.weight(.light))
                .foregroundColor(AppTheme.Colors.primary)
        }
    }
}

/// Main farm list view providing searchable display of all farms
/// Implements master-detail relationship with navigation to detailed farm views
struct FarmListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showCreateFarm = false
    @State private var searchText = ""
    
    @FetchRequest(
        entity: Farm.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Farm.name, ascending: true)]
    ) var farms: FetchedResults<Farm>
    
    /// Filtered farms based on search text matching name or location
    var filteredFarms: [Farm] {
        if searchText.isEmpty {
            return Array(farms)
        } else {
            return farms.filter { farm in
                (farm.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (farm.city?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (farm.address?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            if #available(iOS 15.0, *) {
                modernListView
            } else {
                fallbackListView
            }
        }
    }
    
    // MARK: - Modern List View (iOS 15+)
    
    /// Enhanced list view with improved styling for iOS 15 and later
    @available(iOS 15.0, *)
    private var modernListView: some View {
        List {
            ForEach(filteredFarms, id: \.self) { farm in
                NavigationLink(destination: FarmDetailView(farm: farm)) {
                    FarmRow(farm: farm)
                }
            }
            .onDelete(perform: deleteFarms)
        }
        .searchable(text: $searchText, prompt: "Search farms...")
        .navigationTitle("Farms")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCreateFarm = true
                }) {
                    Label("Add New Farm", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateFarm) {
            EditFarmView(isPresented: $showCreateFarm)
        }
    }
    
    // MARK: - Fallback List View
    
    /// Fallback list view for iOS versions prior to 15
    private var fallbackListView: some View {
        List {
            ForEach(filteredFarms, id: \.self) { farm in
                NavigationLink(destination: FarmDetailView(farm: farm)) {
                    FarmRow(farm: farm)
                }
            }
            .onDelete(perform: deleteFarms)
        }
        .navigationTitle("Farms")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showCreateFarm = true
                }) {
                    Label("Add New Farm", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateFarm) {
            EditFarmView(isPresented: $showCreateFarm)
        }
    }
    
    // MARK: - Methods
    
    /// Deletes selected farm items from Core Data
    private func deleteFarms(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredFarms[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Farm Row Component

/// Individual row component for displaying farm information in lists
/// Provides consistent layout with icon, name, and location metadata
struct FarmRow: View {
    let farm: Farm
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Farm.Image(farm: farm)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(farm.name ?? "Unknown Farm")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack(spacing: AppTheme.Spacing.extraSmall) {
                    if let city = farm.city, !city.isEmpty,
                       let state = farm.state, !state.isEmpty {
                        MetadataTag(text: "\(city), \(state)", color: AppTheme.Colors.primary)
                    }
                    
                    if farm.totalAcres > 0 {
                        MetadataTag(text: "\(Int(farm.totalAcres)) acres", color: AppTheme.Colors.organicMaterial)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.extraSmall)
    }
}

// MARK: - Metadata Tag Component

/// Small tag component for displaying farm metadata (location, acreage, etc.)
/// Provides consistent styling and color coding for different metadata types
private struct MetadataTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(AppTheme.Typography.labelSmall)
            .padding(.horizontal, AppTheme.Spacing.extraSmall)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(color.opacity(0.2))
            .cornerRadius(AppTheme.CornerRadius.small)
            .foregroundColor(color)
    }
}

struct FarmViews_Previews: PreviewProvider {
    static var previews: some View {
        FarmListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}