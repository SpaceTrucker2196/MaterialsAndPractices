//
//  CurrentGrowsView.swift
//  MaterialsAndPractices
//
//  Provides the main interface for managing active growing operations with
//  comprehensive display of grow information and navigation to detailed views.
//  Implements MVVM architecture with proper separation of concerns.
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

/// Main view for displaying and managing current active grows
/// Provides list interface with add, delete, and navigation capabilities
struct CurrentGrowsView: View {
    // MARK: - Properties
    
    @State private var showCreateGrow = false
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Grow.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Grow.title, ascending: true)],
        animation: .default
    )
    private var grows: FetchedResults<Grow>

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Weather information section at the top
                Section {
                    WeatherView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Current Conditions")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.primary)
                        .textCase(nil)
                }
                
                // Active grows section
                Section("Active Grows") {
                    ForEach(grows) { grow in
                        GrowRow(grow: grow)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateGrow = true
                    }) {
                        Label("Add New Grow", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Growing Dashboard")
        }
        .sheet(isPresented: $showCreateGrow) {
            EditGrowView(isPresented: $showCreateGrow)
        }
    }
    
    // MARK: - Methods
    
    /// Deletes selected grow items from Core Data
    /// Handles Core Data save operation with error handling
    /// - Parameter offsets: IndexSet of items to delete
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { grows[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

/// Date formatter for consistent date display in grow rows
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

/// Individual row component for displaying grow information in list format
/// Provides comprehensive grow details with navigation to detail view
struct GrowRow: View {
    // MARK: - Properties
    
    let grow: Grow
    
    // MARK: - Body
    
    var body: some View {
        NavigationLink(
            destination: GrowDetailView(growViewModel: GrowDetailViewModel(grow: grow))
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                    Grow.Image(grow: grow)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                        // Grow title with fallback
                        Text(grow.title ?? "My Grow")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(nil)
                        
                        // Cultivar information section
                        cultivarInfoSection
                        
                        // Planted date information section
                        plantedDateSection
                        
                        // Location information section
                        locationSection
                    }
                    .padding(.leading, AppTheme.Spacing.tiny)
                    
                    Spacer()
                }
                .padding([.top, .leading, .bottom], AppTheme.Spacing.extraSmall)
            }
            .padding(.all, AppTheme.Spacing.extraSmall)
        }
    }
    
    // MARK: - Section Components
    
    /// Section displaying cultivar name with appropriate styling
    private var cultivarInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text("Cultivar")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(grow.cultivar?.name ?? "No Cultivar Selected")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    /// Section displaying planted date with proper formatting
    private var plantedDateSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text("Planted Date")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(plantedDateText)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    /// Section displaying location information
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text("Location")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(grow.locationName ?? "")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Formatted planted date text with fallback for nil dates
    private var plantedDateText: String {
        guard let plantedDate = grow.plantedDate else {
            return "Not Set"
        }
        return itemFormatter.string(from: plantedDate)
    }
}

// MARK: - Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CurrentGrowsView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
