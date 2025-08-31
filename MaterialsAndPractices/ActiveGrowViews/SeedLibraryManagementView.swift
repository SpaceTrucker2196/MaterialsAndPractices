//
//  SeedLibraryManagementView.swift
//  MaterialsAndPractices
//
//  View for managing the complete seed library with filtering, search,
//  and detailed seed management capabilities. Provides comprehensive
//  seed inventory tracking and organic compliance monitoring.
//
//  Features:
//  - Complete seed library browsing with search and filtering
//  - Organic certification status tracking
//  - Seed quality and expiration monitoring
//  - Detailed seed editing and management
//  - Supplier association tracking
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Main view for seed library management and inventory tracking
/// Provides comprehensive seed inventory management with organic compliance
struct SeedLibraryManagementView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Fetch Requests
    
    @FetchRequest(
        entity: SeedLibrary.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SeedLibrary.seedName, ascending: true)]
    ) var seeds: FetchedResults<SeedLibrary>
    
    // MARK: - State Properties
    
    @State private var searchText = ""
    @State private var selectedSupplier: SupplierSource?
    @State private var organicOnly = false
    @State private var showExpiredOnly = false
    @State private var selectedSeed: SeedLibrary?
    @State private var showingSeedDetail = false
    @State private var showingCreateSeed = false
    
    // MARK: - Computed Properties
    
    /// Filtered seeds based on search criteria
    private var filteredSeeds: [SeedLibrary] {
        return seeds.filter { seed in
            // Search text filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesSearch = (seed.seedName?.lowercased().contains(searchLower) ?? false) ||
                                  (seed.cultivar?.name.lowercased().contains(searchLower) ?? false) ||
                                  (seed.cultivar?.family?.lowercased().contains(searchLower) ?? false) ||
                                  (seed.supplierSource?.name?.lowercased().contains(searchLower) ?? false)
                if !matchesSearch { return false }
            }
            
            // Supplier filter
            if let selectedSupplier = selectedSupplier {
                if seed.supplierSource != selectedSupplier { return false }
            }
            
            // Organic filter
            if organicOnly && !seed.isCertifiedOrganic {
                return false
            }
            
            // Expired filter
            if showExpiredOnly && !seed.isExpired {
                return false
            }
            
            return true
        }
    }
    
    /// Available suppliers for filtering
    private var availableSuppliers: [SupplierSource] {
        let suppliers = Set(seeds.compactMap { $0.supplierSource })
        return Array(suppliers).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
                // Seed list
                if filteredSeeds.isEmpty {
                    emptyStateView
                } else {
                    seedListView
                }
            }
            .navigationTitle("Seed Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Seed") {
                        showingCreateSeed = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSeed) {
            CreateSeedFromCultivarView()
        }
        .sheet(isPresented: $showingSeedDetail) {
            if let seed = selectedSeed {
                SeedDetailView(seed: seed, isPresented: $showingSeedDetail)
            }
        }
    }
    
    // MARK: - View Components
    
    /// Search and filter controls
    private var searchAndFilterSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextField("Search seeds...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    // Organic filter
                    FilterChip(
                        title: "Organic Only",
                        isSelected: organicOnly,
                        icon: "leaf.fill"
                    ) {
                        organicOnly.toggle()
                    }
                    
                    // Expired filter
                    FilterChip(
                        title: "Expired Seeds",
                        isSelected: showExpiredOnly,
                        icon: "exclamationmark.triangle.fill"
                    ) {
                        showExpiredOnly.toggle()
                    }
                    
                    // Supplier filters
                    ForEach(availableSuppliers, id: \.objectID) { supplier in
                        FilterChip(
                            title: supplier.name ?? "Unknown",
                            isSelected: selectedSupplier == supplier
                        ) {
                            selectedSupplier = (selectedSupplier == supplier) ? nil : supplier
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    /// Seed list view
    private var seedListView: some View {
        List(filteredSeeds, id: \.objectID) { seed in
            SeedLibraryRow(seed: seed) {
                selectedSeed = seed
                showingSeedDetail = true
            }
        }
        .listStyle(PlainListStyle())
    }
    
    /// Empty state view when no seeds are found
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No Seeds Found")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Add seeds to your library to track inventory and maintain organic compliance.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)
            
            Button("Add Your First Seed") {
                showingCreateSeed = true
            }
            .font(AppTheme.Typography.bodyMedium)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding()
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            
            Spacer()
        }
    }
}

/// Individual seed row for the library list
struct SeedLibraryRow: View {
    let seed: SeedLibrary
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Seed status indicator
                VStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                }
                
                // Seed information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    HStack {
                        Text(seed.displayName)
                            .font(AppTheme.Typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text(seed.quantityDisplay)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if let cultivarFamily = seed.cultivar?.family {
                        Text(cultivarFamily)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        // Compliance badges
                        if seed.isCertifiedOrganic {
                            Text("Organic")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppTheme.Spacing.small)
                                .padding(.vertical, AppTheme.Spacing.tiny)
                                .background(AppTheme.Colors.organicPractice)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        
                        if seed.isExpired {
                            Text("Expired")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppTheme.Spacing.small)
                                .padding(.vertical, AppTheme.Spacing.tiny)
                                .background(AppTheme.Colors.error)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        
                        Spacer()
                        
                        if let supplier = seed.supplierSource {
                            Text(supplier.name ?? "Unknown Supplier")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.caption)
            }
            .padding(.vertical, AppTheme.Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Status color based on seed condition
    private var statusColor: Color {
        if seed.isExpired {
            return AppTheme.Colors.error
        } else if seed.isCertifiedOrganic {
            return AppTheme.Colors.organicPractice
        } else {
            return AppTheme.Colors.textTertiary
        }
    }
}

// MARK: - Preview Provider

struct SeedLibraryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SeedLibraryManagementView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}