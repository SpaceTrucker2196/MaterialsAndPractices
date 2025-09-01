//
//  SupplierSelectionView.swift
//  MaterialsAndPractices
//
//  Supplier selection view for associating existing suppliers with cultivars.
//  Provides filtering and search capabilities to find appropriate seed suppliers
//  for organic certification compliance and traceability requirements.
//
//  Features:
//  - Filtered supplier list by supplier type
//  - Search functionality across supplier names and contact information
//  - Organic certification status indicators
//  - Quick supplier association with callback support
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// View for selecting existing suppliers to associate with cultivars
/// Focuses on seed suppliers with organic certification tracking
struct SupplierSelectionView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    let cultivar: Cultivar
    @Binding var isPresented: Bool
    let onSupplierSelected: (SupplierSource) -> Void
    
    // MARK: - State Properties
    
    @State private var searchText = ""
    @State private var selectedSupplierType: SupplierKind = .seed
    @State private var organicCertifiedOnly = false
    
    // MARK: - Fetch Requests
    
    @FetchRequest var suppliers: FetchedResults<SupplierSource>
    
    // MARK: - Initialization
    
    init(cultivar: Cultivar, isPresented: Binding<Bool>, onSupplierSelected: @escaping (SupplierSource) -> Void) {
        self.cultivar = cultivar
        self._isPresented = isPresented
        self.onSupplierSelected = onSupplierSelected
        
        // Initialize fetch request for suppliers
        self._suppliers = FetchRequest(
            entity: SupplierSource.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \SupplierSource.isOrganicCertified, ascending: false),
                NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)
            ]
        )
    }
    
    // MARK: - Computed Properties
    
    /// Filtered suppliers based on search criteria
    private var filteredSuppliers: [SupplierSource] {
        return suppliers.filter { supplier in
            // Filter by supplier type
            if supplier.kind != selectedSupplierType {
                return false
            }
            
            // Filter by organic certification if requested
            if organicCertifiedOnly && !supplier.isOrganicCertified {
                return false
            }
            
            // Search text filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesSearch = (supplier.name?.lowercased().contains(searchLower) ?? false) ||
                                  (supplier.contactName?.lowercased().contains(searchLower) ?? false) ||
                                  (supplier.city?.lowercased().contains(searchLower) ?? false) ||
                                  (supplier.state?.lowercased().contains(searchLower) ?? false)
                
                if !matchesSearch {
                    return false
                }
            }
            
            return true
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and filters
                searchAndFiltersSection
                
                // Suppliers list
                suppliersList
            }
            .navigationTitle("Select Supplier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Search bar and filter options
    private var searchAndFiltersSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search suppliers...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                }
            }
            
            // Filters
            HStack {
                // Supplier type picker
                Picker("Type", selection: $selectedSupplierType) {
                    ForEach(SupplierKind.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                // Organic certification filter
                Toggle(isOn: $organicCertifiedOnly) {
                    Label("Organic Only", systemImage: "checkmark.seal")
                        .font(.caption)
                }
                .toggleStyle(SwitchToggleStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    /// List of filtered suppliers
    private var suppliersList: some View {
        Group {
            if filteredSuppliers.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredSuppliers, id: \.objectID) { supplier in
                        SupplierSelectionRowView(
                            supplier: supplier,
                            cultivar: cultivar
                        ) {
                            selectSupplier(supplier)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    /// Empty state when no suppliers match criteria
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Suppliers Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("No suppliers match your current filter criteria.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                searchText = ""
                organicCertifiedOnly = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    /// Handle supplier selection
    private func selectSupplier(_ supplier: SupplierSource) {
        onSupplierSelected(supplier)
        isPresented = false
    }
}

// MARK: - Supporting Views

/// Row view for supplier selection
struct SupplierSelectionRowView: View {
    let supplier: SupplierSource
    let cultivar: Cultivar
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Supplier type icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: supplier.kind.icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                // Supplier information
                VStack(alignment: .leading, spacing: 4) {
                    Text(supplier.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let contact = supplier.contactName, !contact.isEmpty {
                        Text(contact)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !supplier.fullAddress.isEmpty {
                        Text(supplier.fullAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Certification status
                    HStack(spacing: 8) {
                        if supplier.isOrganicCertified {
                            Label("Organic Certified", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if supplier.isCertificationExpired {
                            Label("Expired", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Already associated indicator
                if cultivar.seedSourcesArray.contains(where: { $0.objectID == supplier.objectID }) {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text("Associated")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider

struct SupplierSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample cultivar
        let cultivar = Cultivar(context: context)
        cultivar.name = "Cherokee Purple Tomato"
        
        // Create sample suppliers
        let supplier1 = SupplierSource(context: context)
        supplier1.name = "Organic Seeds Co"
        supplier1.supplierType = SupplierKind.seed.rawValue
        supplier1.isOrganicCertified = true
        supplier1.contactName = "John Smith"
        supplier1.city = "Portland"
        supplier1.state = "OR"
        
        let supplier2 = SupplierSource(context: context)
        supplier2.name = "Heritage Seed Company"
        supplier2.supplierType = SupplierKind.seed.rawValue
        supplier2.isOrganicCertified = false
        supplier2.contactName = "Jane Doe"
        supplier2.city = "Seattle"
        supplier2.state = "WA"
        
        return SupplierSelectionView(
            cultivar: cultivar,
            isPresented: .constant(true),
            onSupplierSelected: { _ in }
        )
        .environment(\.managedObjectContext, context)
    }
}
