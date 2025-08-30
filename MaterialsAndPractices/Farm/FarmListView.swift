import SwiftUI
import CoreData

/// Main view for displaying and managing farm properties
/// Provides list interface with add, delete, and navigation capabilities
struct FarmListView: View {
    // MARK: - Properties
    
    @State private var showCreateProperty = false
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)],
        animation: .default
    )
    private var properties: FetchedResults<Property>
    
    /// Advanced mode setting from configuration
    private var isAdvancedMode: Bool {
        SecureConfiguration.shared.farmManagementAdvancedMode
    }

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Farm properties section
                Section("Farm Properties") {
                    ForEach(properties) { property in
                        FarmPropertyRow(property: property, isAdvancedMode: isAdvancedMode)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateProperty = true
                    }) {
                        Label("Add Property", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Farm Management")
        }
        .sheet(isPresented: $showCreateProperty) {
            EditPropertyView(isPresented: $showCreateProperty)
        }
    }
    
    // MARK: - Methods
    
    /// Deletes selected property items from Core Data
    /// Handles Core Data save operation with error handling
    /// - Parameter offsets: IndexSet of items to delete
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { properties[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

/// Individual row component for displaying property information in list format
/// Provides comprehensive property details with navigation to detail view
struct FarmPropertyRow: View {
    // MARK: - Properties
    
    let property: Property
    let isAdvancedMode: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationLink(
            destination: PropertyDetailView(property: property, isAdvancedMode: isAdvancedMode)
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                        // Property display name with fallback
                        Text(property.displayName ?? "Unknown Property")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(nil)
                        
                        // Basic property information
                        if isAdvancedMode {
                            // Advanced mode shows more details
                            advancedInfoSection
                        } else {
                            // Basic mode shows minimal information
                            basicInfoSection
                        }
                        
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
    
    /// Basic information section for basic mode
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text("Total Acres")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("\(property.totalAcres, specifier: "%.1f") acres")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    /// Advanced information section for advanced mode
    private var advancedInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Total")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    Text("\(property.totalAcres, specifier: "%.1f")")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Tillable")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    Text("\(property.tillableAcres, specifier: "%.1f")")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                if property.hasIrrigation {
                    Image(systemName: "drop.fill")
                        .foregroundColor(AppTheme.Colors.info)
                        .font(AppTheme.Typography.labelMedium)
                }
                
                Spacer()
            }
        }
    }
    
    /// Section displaying location information
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            if let county = property.county, let state = property.state {
                Text("Location")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("\(county), \(state)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Preview Provider

struct FarmListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FarmListView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
