//
//  AmendmentCatalogView.swift
//  MaterialsAndPractices
//
//  Comprehensive amendment catalog view for managing crop amendments with OMRI listing
//  indicators, current inventory tracking, and supplier association capabilities.
//  Provides centralized access to all farm amendment management functions.
//
//  Features:
//  - Complete amendment listing with search and filtering
//  - OMRI listing status indicators for organic compliance
//  - Current inventory tracking with low stock alerts
//  - Supplier association and management
//  - Amendment detail views with editing capabilities
//  - Quick add functionality for new amendments
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Main amendment catalog view with comprehensive management capabilities
/// Serves as the central hub for farm amendment inventory and compliance tracking
struct CropAmendmentCatalogView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Fetch Requests
    
    @FetchRequest(
        entity: CropAmendment.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CropAmendment.productType, ascending: true),
            NSSortDescriptor(keyPath: \CropAmendment.productName, ascending: true)
        ]
    ) var amendments: FetchedResults<CropAmendment>
    
    // MARK: - State Properties
    
    @State private var searchText = ""
    @State private var selectedProductType: String? = nil
    @State private var omriOnly = false
    @State private var lowStockOnly = false
    @State private var showingFilters = false
    @State private var showingNewAmendment = false
    
    // MARK: - Computed Properties
    
    /// Filtered amendments based on search criteria
    private var filteredAmendments: [CropAmendment] {
        return amendments.filter { amendment in
            // Search text filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesSearch = (amendment.productName?.lowercased().contains(searchLower) ?? false) ||
                                  (amendment.productType?.lowercased().contains(searchLower) ?? false) ||
                                  (amendment.notes?.lowercased().contains(searchLower) ?? false)
                
                if !matchesSearch {
                    return false
                }
            }
            
            // Product type filter
            if let productType = selectedProductType, amendment.productType != productType {
                return false
            }
            
            // OMRI listing filter
            if omriOnly && !amendment.omriListed {
                return false
            }
            
            // Low stock filter
            if lowStockOnly && !amendment.isLowStock {
                return false
            }
            
            return true
        }
    }
    
    /// Unique product types for filter options
    private var availableProductTypes: [String] {
        let types = Set(amendments.compactMap { $0.productType }).sorted()
        return types
    }
    
    /// Grouped amendments by product type
    private var groupedAmendments: [(String, [CropAmendment])] {
        let grouped = Dictionary(grouping: filteredAmendments) { amendment in
            amendment.productType ?? "Unknown Type"
        }
        
        return grouped.map { (type, amendments) in
            (type, amendments.sorted { ($0.productName ?? "") < ($1.productName ?? "") })
        }.sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Section
                searchAndFilterSection
                
                // Amendment List
                if filteredAmendments.isEmpty {
                    emptyStateView
                } else {
                    amendmentListView
                }
            }
            .navigationTitle("Amendment Catalog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewAmendment = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                filterSheet
            }
            .sheet(isPresented: $showingNewAmendment) {
              //  CreateAmendmentView(isPresented: $showingNewAmendment)
            }
        }
    }
    
    // MARK: - View Components
    
    /// Search bar and quick filter chips
    private var searchAndFilterSection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextField("Search amendments...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal)
            
            // Quick Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    // OMRI Filter Chip
                    FilterChip(
                        title: "OMRI Listed",
                        isSelected: omriOnly,
                        icon: "checkmark.seal.fill"
                    ) {
                        omriOnly.toggle()
                    }
                    
                    // Low Stock Filter Chip
                    FilterChip(
                        title: "Low Stock",
                        isSelected: lowStockOnly,
                        icon: "exclamationmark.triangle.fill"
                    ) {
                        lowStockOnly.toggle()
                    }
                    
                    // Product Type Filter Chips
                    ForEach(availableProductTypes.prefix(4), id: \.self) { type in
                        FilterChip(
                            title: type,
                            isSelected: selectedProductType == type
                        ) {
                            selectedProductType = (selectedProductType == type) ? nil : type
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    /// Main amendment list organized by product type
    private var amendmentListView: some View {
        List {
            ForEach(groupedAmendments, id: \.0) { productType, typeAmendments in
                Section(header: productTypeSectionHeader(productType)) {
                    ForEach(typeAmendments, id: \.amendmentID) { amendment in
//                        NavigationLink(destination: AmendmentDetailView(amendment: amendment)) {
//                            AmendmentRowView(amendment: amendment)
//                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
    
    /// Empty state when no amendments match filters
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "flask.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Amendments Found")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Try adjusting your search criteria or add a new amendment")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if hasActiveFilters {
                Button("Clear All Filters") {
                    clearAllFilters()
                }
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.primary)
            }
            
            Button("Add New Amendment") {
                showingNewAmendment = true
            }
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding()
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Filter bottom sheet
    private var filterSheet: some View {
        NavigationView {
            AmendmentFilterOptionsView(
                selectedProductType: $selectedProductType,
                omriOnly: $omriOnly,
                lowStockOnly: $lowStockOnly,
                availableProductTypes: availableProductTypes
            )
            .navigationTitle("Filter Amendments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        clearAllFilters()
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilters = false
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }
    
    /// Product type section header with count
    private func productTypeSectionHeader(_ productType: String) -> some View {
        HStack {
            Text(productType)
                .font(AppTheme.Typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            let count = groupedAmendments.first { $0.0 == productType }?.1.count ?? 0
            Text("\(count) amendment\(count != 1 ? "s" : "")")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Helper Properties
    
    /// Check if any filters are currently active
    private var hasActiveFilters: Bool {
        return selectedProductType != nil || omriOnly || lowStockOnly || !searchText.isEmpty
    }
    
    // MARK: - Actions
    
    /// Clear all active filters
    private func clearAllFilters() {
        searchText = ""
        selectedProductType = nil
        omriOnly = false
        lowStockOnly = false
    }
}

// MARK: - Supporting Views

/// Individual amendment row view with status indicators
struct AmendmentRowView: View {
    let amendment: CropAmendment
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Amendment type icon
            Image(systemName: amendment.productTypeIcon)
                .foregroundColor(amendment.statusColor)
                .frame(width: 24, height: 24)
            
            // Amendment information
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                HStack {
                    Text(amendment.displayName)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Status indicators
                    HStack(spacing: AppTheme.Spacing.tiny) {
                        // OMRI listing indicator
                        if amendment.omriListed {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(AppTheme.Colors.organicPractice)
                                .font(.caption)
                        }
                        
                        // Low stock indicator
                        if amendment.isLowStock {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.Colors.warning)
                                .font(.caption)
                        }
                    }
                }
                
                // Product type and supplier info
                HStack {
                    if let productType = amendment.productType {
                        Text(productType)
                            .font(AppTheme.Typography.labelSmall)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, AppTheme.Spacing.tiny)
                            .background(AppTheme.Colors.backgroundTertiary)
                            .cornerRadius(AppTheme.CornerRadius.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if let supplier = amendment.supplier {
                        Text("• \(supplier.displayName)")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                }
                
                // Inventory status
                HStack {
                    Text(amendment.inventoryStatusText)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(amendment.isLowStock ? AppTheme.Colors.warning : AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if let unitOfMeasure = amendment.unitOfMeasure, !unitOfMeasure.isEmpty {
                        Text(unitOfMeasure)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
            
            // Navigation chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

/// Filter options view for amendments
struct AmendmentFilterOptionsView: View {
    @Binding var selectedProductType: String?
    @Binding var omriOnly: Bool
    @Binding var lowStockOnly: Bool
    
    let availableProductTypes: [String]
    
    var body: some View {
        List {
            Section("Status Filters") {
                Toggle("OMRI Listed Only", isOn: $omriOnly)
                Toggle("Low Stock Only", isOn: $lowStockOnly)
            }
            
            Section("Product Type") {
                Button("All Types") {
                    selectedProductType = nil
                }
                .foregroundColor(selectedProductType == nil ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                
                ForEach(availableProductTypes, id: \.self) { productType in
                    Button(productType) {
                        selectedProductType = (selectedProductType == productType) ? nil : productType
                    }
                    .foregroundColor(selectedProductType == productType ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                    .background(selectedProductType == productType ? AppTheme.Colors.primary.opacity(0.1) : Color.clear)
                }
            }
        }
    }
}

// MARK: - CropAmendment Extensions

extension CropAmendment {
    /// Display name for amendment
    var displayName: String {
        return productName ?? "Unknown Amendment"
    }
    
    /// Check if amendment is low stock
    var isLowStock: Bool {
        return currentInventoryAmount <= 10.0 // Threshold for low stock
    }
    
    /// Inventory status text
    var inventoryStatusText: String {
        let amount = currentInventoryAmount
        if amount <= 0 {
            return "Out of stock"
        } else if isLowStock {
            return "Low stock: \(String(format: "%.1f", amount))"
        } else {
            return "In stock: \(String(format: "%.1f", amount))"
        }
    }
    
    /// Product type icon
    var productTypeIcon: String {
        guard let type = productType?.lowercased() else {
            return "flask.fill"
        }
        
        switch type {
        case "fertilizer":
            return "drop.fill"
        case "pesticide", "insecticide":
            return "shield.fill"
        case "herbicide":
            return "leaf.fill"
        case "fungicide":
            return "sparkles"
        case "soil amendment", "compost":
            return "globe.americas.fill"
        default:
            return "flask.fill"
        }
    }
    
    /// Status color based on inventory and OMRI status
    var statusColor: Color {
        if currentInventoryAmount <= 0 {
            return AppTheme.Colors.error
        } else if isLowStock {
            return AppTheme.Colors.warning
        } else if omriListed {
            return AppTheme.Colors.organicPractice
        } else {
            return AppTheme.Colors.primary
        }
    }
}

/// Filter chip component for quick filtering
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let icon: String?
    let action: () -> Void
    
    init(title: String, isSelected: Bool, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.tiny) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
            }
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(
                isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundTertiary
            )
            .foregroundColor(
                isSelected ? .white : AppTheme.Colors.textSecondary
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider

struct AmendmentCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CropAmendmentCatalogView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
