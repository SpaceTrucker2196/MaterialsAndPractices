//
//  InfrastructureCatalogBrowserView.swift
//  MaterialsAndPractices
//
//  Provides infrastructure catalog browsing interface with common farm equipment,
//  buildings, and systems. Allows selection and copying of catalog items to
//  create new infrastructure instances for farm assignment.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Infrastructure catalog browser for selecting and creating infrastructure from templates
/// Provides comprehensive browsing of predefined infrastructure types with detailed information
struct InfrastructureCatalogBrowserView: View {
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // State management
    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var selectedCatalogItem: InfrastructureCatalog?
    @State private var showingInfrastructureCreation = false
    
    // Fetch catalog items
    @FetchRequest(
        entity: InfrastructureCatalog.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \InfrastructureCatalog.category, ascending: true),
            NSSortDescriptor(keyPath: \InfrastructureCatalog.name, ascending: true)
        ]
    ) private var catalogItems: FetchedResults<InfrastructureCatalog>
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
                // Catalog items list
                catalogItemsList
            }
            .navigationTitle("Infrastructure Catalog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Seed Catalog") {
                        seedCatalogIfNeeded()
                    }
                    .disabled(!catalogItems.isEmpty)
                }
            }
            .sheet(isPresented: $showingInfrastructureCreation) {
                if let catalogItem = selectedCatalogItem {
                    InfrastructureCreationView(
                        isPresented: $showingInfrastructureCreation,
                        fromCatalogItem: catalogItem
                    )
                }
            }
        }
        .onAppear {
            seedCatalogIfNeeded()
        }
    }
    
    // MARK: - UI Sections
    
    /// Search and filter section
    private var searchAndFilterSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                TextField("Search infrastructure...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(["All"] + availableCategories, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            onTap: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
    }
    
    /// Catalog items list
    private var catalogItemsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.medium) {
                if filteredCatalogItems.isEmpty {
                    catalogEmptyState
                } else {
                    ForEach(filteredCatalogItems, id: \.id) { catalogItem in
                        CatalogItemRow(catalogItem: catalogItem) {
                            selectedCatalogItem = catalogItem
                            showingInfrastructureCreation = true
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    /// Empty state for catalog
    private var catalogEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text("No Catalog Items Found")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if catalogItems.isEmpty {
                    Text("Tap 'Seed Catalog' to load common farm infrastructure")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Try adjusting your search or category filter")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.extraLarge)
    }
    
    // MARK: - Computed Properties
    
    /// Available categories from catalog items
    private var availableCategories: [String] {
        let categories = Set(catalogItems.compactMap { $0.category })
        return Array(categories).sorted()
    }
    
    /// Filtered catalog items based on search and category
    private var filteredCatalogItems: [InfrastructureCatalog] {
        var items = Array(catalogItems)
        
        // Filter by category
        if selectedCategory != "All" {
            items = items.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { item in
                (item.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.type?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.category?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return items
    }
    
    // MARK: - Actions
    
    /// Seed catalog if it's empty
    private func seedCatalogIfNeeded() {
        if catalogItems.isEmpty {
            InfrastructureCatalogSeeder.seedInfrastructureCatalog(context: viewContext)
        }
    }
}

// MARK: - Category Filter Button

/// Category filter button component
struct CategoryFilterButton: View {
    let category: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Catalog Item Row

/// Individual catalog item row display
struct CatalogItemRow: View {
    let catalogItem: InfrastructureCatalog
    let onSelect: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(catalogItem.name ?? "Unknown Infrastructure")
                        .font(AppTheme.Typography.bodyLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        if let category = catalogItem.category {
                            Text(category)
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppTheme.Spacing.small)
                                .padding(.vertical, AppTheme.Spacing.tiny)
                                .background(AppTheme.Colors.primary)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        
                        if let type = catalogItem.type {
                            Text(type.capitalized)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: AppTheme.Spacing.small) {
                    Button("View Details") {
                        showingDetail = true
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.primary)
                    
                    Button("Create Item") {
                        onSelect()
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
            
            // Summary information
            if let maintenanceProcedures = catalogItem.maintenanceProcedures,
               !maintenanceProcedures.isEmpty {
                Text("Includes comprehensive maintenance procedures and safety training")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .sheet(isPresented: $showingDetail) {
            CatalogItemDetailView(catalogItem: catalogItem, isPresented: $showingDetail)
        }
    }
}

// MARK: - Catalog Item Detail View

/// Detailed view for catalog item information
struct CatalogItemDetailView: View {
    let catalogItem: InfrastructureCatalog
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Header information
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(catalogItem.name ?? "Unknown Infrastructure")
                            .font(AppTheme.Typography.headlineLarge)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        HStack {
                            if let category = catalogItem.category {
                                Text(category)
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppTheme.Spacing.medium)
                                    .padding(.vertical, AppTheme.Spacing.small)
                                    .background(AppTheme.Colors.primary)
                                    .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            
                            if let type = catalogItem.type {
                                Text(type.capitalized)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                    
                    // Maintenance procedures
                    if let maintenanceProcedures = catalogItem.maintenanceProcedures,
                       !maintenanceProcedures.isEmpty {
                        DetailSection(title: "Maintenance Procedures", content: maintenanceProcedures)
                    }
                    
                    // Safety training
                    if let safetyTraining = catalogItem.safetyTraining,
                       !safetyTraining.isEmpty {
                        DetailSection(title: "Safety Training", content: safetyTraining)
                    }
                    
                    // Rodent inspection procedures
                    if let rodentInspection = catalogItem.rodentInspectionProcedure,
                       !rodentInspection.isEmpty {
                        DetailSection(title: "Rodent Inspection Procedures", content: rodentInspection)
                    }
                }
                .padding()
            }
            .navigationTitle("Catalog Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Detail Section Component

/// Section component for displaying detailed text content
struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(title)
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(content)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineSpacing(2)
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Preview

struct InfrastructureCatalogBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        InfrastructureCatalogBrowserView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}