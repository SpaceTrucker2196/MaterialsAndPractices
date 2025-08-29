//
//  CultivarDetailView.swift
//  MaterialsAndPractices
//
//  Comprehensive cultivar detail view providing complete information about a specific cultivar
//  including seed source management, organic certification status, and grow creation capabilities.
//  Integrates with supplier management for complete seed sourcing traceability.
//
//  Features:
//  - Complete cultivar information display with organic certification status
//  - Seed source management with supplier association
//  - Quick grow creation from cultivar
//  - Supplier management integration
//  - Growing instructions and cultivation guidance
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Detailed view for individual cultivar with supplier management and grow creation
/// Provides comprehensive cultivar information and integrated farm management actions
struct CultivarDetailView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    let cultivar: Cultivar
    
    // MARK: - State Properties
    
    @State private var showingGrowCreation = false
    @State private var showingSupplierSelection = false
    @State private var showingNewSupplierCreation = false
    @State private var selectedSupplier: SupplierSource?
    
    // MARK: - Fetch Requests
    
    @FetchRequest var seedSuppliers: FetchedResults<SupplierSource>
    
    // MARK: - Initialization
    
    init(cultivar: Cultivar) {
        self.cultivar = cultivar
        
        // Initialize fetch request for seed suppliers
        self._seedSuppliers = FetchRequest(
            entity: SupplierSource.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)],
            predicate: NSPredicate(format: "supplierType == %@", SupplierSource.SupplierType.seed.rawValue)
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Header Section
                cultivarHeaderSection
                
                // Seed Source Section
                seedSourceSection
                
                // Quick Actions Section
                quickActionsSection
                
                // Growing Information Section
                growingInformationSection
                
                // Cultivation Details Section
                cultivationDetailsSection
            }
            .padding()
        }
        .navigationTitle(cultivar.displayName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingGrowCreation) {
            CreateGrowFromCultivarView(cultivar: cultivar, isPresented: $showingGrowCreation)
        }
        .sheet(isPresented: $showingSupplierSelection) {
            SupplierSelectionView(
                cultivar: cultivar,
                isPresented: $showingSupplierSelection,
                onSupplierSelected: { supplier in
                    associateSupplierWithCultivar(supplier)
                }
            )
        }
        .sheet(isPresented: $showingNewSupplierCreation) {
            CreateSupplierView(
                supplierType: .seed,
                isPresented: $showingNewSupplierCreation,
                onSupplierCreated: { supplier in
                    associateSupplierWithCultivar(supplier)
                }
            )
        }
    }
    
    // MARK: - View Components
    
    /// Cultivar header with basic information and certification status
    private var cultivarHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                // Cultivar icon/emoji
                ZStack {
                    Circle()
                        .fill(cultivarColor)
                        .frame(width: 80, height: 80)
                    
                    Text(cultivar.emoji ?? "🌱")
                        .font(.system(size: 32))
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    // Cultivar name
                    Text(cultivar.displayName)
                        .font(AppTheme.Typography.displaySmall)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    // Common name
                    if let commonName = cultivar.commonName, !commonName.isEmpty {
                        Text(commonName)
                            .font(AppTheme.Typography.bodyLarge)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Organic certification status
                    HStack {
                        if cultivar.isOrganicCertified {
                            Label("Organic Certified", systemImage: "checkmark.seal.fill")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Colors.organicPractice)
                        } else {
                            Label("Not Certified", systemImage: "exclamationmark.triangle")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Colors.warning)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Family and season information
            HStack(spacing: AppTheme.Spacing.medium) {
                if let family = cultivar.family {
                    InfoChip(label: "Family", value: family, icon: "leaf.fill")
                }
                
                if let season = cultivar.season {
                    InfoChip(label: "Season", value: season, icon: "calendar")
                }
                
                if let growingDays = cultivar.growingDays {
                    InfoChip(label: "Days to Harvest", value: growingDays, icon: "clock")
                }
            }
            
            // Description
            if let description = cultivar.cultivarDescription, !description.isEmpty {
                Text(description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    /// Seed source management section
    private var seedSourceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Seed Sources")
                    .font(AppTheme.Typography.headlineMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Menu {
                    Button("Select from Existing", action: { showingSupplierSelection = true })
                    Button("Create New Supplier", action: { showingNewSupplierCreation = true })
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title3)
                }
            }
            
            if cultivar.seedSourcesArray.isEmpty {
                // No seed sources state
                VStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: "leaf.arrow.circlepath")
                        .font(.title)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Text("No seed sources available")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("Add a seed source to track supplier information and organic certification status for compliance documentation.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                // Seed sources list
                ForEach(cultivar.seedSourcesArray, id: \.id) { supplier in
                    NavigationLink(destination: SupplierDetailView(supplier: supplier)) {
                        SupplierRowView(supplier: supplier)
                    }
                }
            }
        }
    }
    
    /// Quick action buttons for common operations
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Quick Actions")
                .font(AppTheme.Typography.headlineMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            HStack(spacing: AppTheme.Spacing.medium) {
                // Create Grow button
                ActionButton(
                    title: "Create Grow",
                    subtitle: "Start new grow with this cultivar",
                    icon: "plus.circle.fill",
                    color: AppTheme.Colors.primary
                ) {
                    showingGrowCreation = true
                }
                
                // View Existing Grows button
                if !cultivar.growsArray.isEmpty {
                    NavigationLink(destination: CultivarGrowsListView(cultivar: cultivar)) {
                        ActionButton(
                            title: "View Grows",
                            subtitle: "\(cultivar.growsArray.count) existing",
                            icon: "list.bullet",
                            color: AppTheme.Colors.secondary
                        ) {
                            // Navigation handled by NavigationLink
                        }
                    }
                }
            }
        }
    }
    
    /// Growing information section
    private var growingInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Growing Information")
                .font(AppTheme.Typography.headlineMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                if let plantingDates = cultivar.bestPlantingDates {
                    InfoCard(title: "Best Planting", content: plantingDates, icon: "calendar.badge.plus")
                }
                
                if let harvestInfo = cultivar.bestHarvest {
                    InfoCard(title: "Harvest Time", content: harvestInfo, icon: "basket")
                }
                
                if let zones = cultivar.optimalZones {
                    InfoCard(title: "Optimal Zones", content: zones, icon: "map")
                }
                
                if let hardyZone = cultivar.hardyZone {
                    InfoCard(title: "Hardy Zone", content: hardyZone, icon: "snowflake")
                }
            }
        }
    }
    
    /// Detailed cultivation information
    private var cultivationDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Cultivation Details")
                .font(AppTheme.Typography.headlineMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.medium) {
                if let soilInfo = cultivar.soilInfo {
                    DetailSection(title: "Soil Requirements", content: soilInfo, icon: "globe.americas")
                }
                
                if let growingAdvice = cultivar.growingAdvice {
                    DetailSection(title: "Growing Advice", content: growingAdvice, icon: "lightbulb")
                }
                
                if let harvestInstructions = cultivar.harvestInstructions {
                    DetailSection(title: "Harvest Instructions", content: harvestInstructions, icon: "basket.fill")
                }
                
                if let pests = cultivar.pests {
                    DetailSection(title: "Common Pests", content: pests, icon: "ladybug")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Cultivar color for theming
    private var cultivarColor: Color {
        if let colorString = cultivar.iosColor {
            return Color(colorString) ?? AppTheme.Colors.primary
        }
        return AppTheme.Colors.primary.opacity(0.2)
    }
    
    // MARK: - Helper Methods
    
    /// Associate a supplier with the cultivar
    private func associateSupplierWithCultivar(_ supplier: SupplierSource) {
        cultivar.addToSeedSources(supplier)
        
        do {
            try viewContext.save()
        } catch {
            print("Error associating supplier with cultivar: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Information chip for displaying key cultivar attributes
struct InfoChip: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.tiny) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(value)
                .font(AppTheme.Typography.labelMedium)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Action button for quick operations
struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Information card for growing details
struct InfoCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.caption)
                
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Text(content)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(3)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Detailed section for cultivation information
struct DetailSection: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Text(content)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Supplier row view for seed sources
struct SupplierRowView: View {
    let supplier: SupplierSource
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Supplier type icon
            Image(systemName: supplier.supplierTypeEnum?.icon ?? "building.2")
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24, height: 24)
            
            // Supplier information
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(supplier.displayName)
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let contact = supplier.primaryContact {
                    Text(contact)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                // Certification status
                HStack {
                    if supplier.isOrganicCertified {
                        Label("Organic Certified", systemImage: "checkmark.seal.fill")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.organicPractice)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.Colors.textTertiary)
                .font(.caption)
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Extensions

extension Cultivar {
    /// Display name for cultivar
    var displayName: String {
        return name ?? "Unknown Cultivar"
    }
    
    /// Array of associated seed sources
    var seedSourcesArray: [SupplierSource] {
        let set = seedSources as? Set<SupplierSource> ?? []
        return Array(set).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    /// Array of associated grows
    var growsArray: [Grow] {
        let set = grows as? Set<Grow> ?? []
        return Array(set).sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
}

// MARK: - Preview Provider

struct CultivarDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CultivarDetailView(cultivar: PreviewData.sampleCultivar)
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

// MARK: - Preview Data

extension PreviewData {
    static var sampleCultivar: Cultivar {
        let context = PersistenceController.preview.container.viewContext
        let cultivar = Cultivar(context: context)
        cultivar.name = "Cherokee Purple Tomato"
        cultivar.commonName = "Heirloom Tomato"
        cultivar.family = "Solanaceae"
        cultivar.season = "Summer"
        cultivar.growingDays = "80-90"
        cultivar.emoji = "🍅"
        cultivar.isOrganicCertified = true
        cultivar.cultivarDescription = "A beautiful heirloom tomato with deep purple shoulders and rich, complex flavor."
        return cultivar
    }
}