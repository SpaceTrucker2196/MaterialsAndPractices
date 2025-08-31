//
//  CreateSeedFromCultivarView.swift
//  MaterialsAndPractices
//
//  View for creating seed library entries from cultivar selection.
//  Provides cultivar catalog browsing and seed creation workflow
//  with supplier selection and organic compliance tracking.
//
//  Features:
//  - Cultivar catalog navigation
//  - Seed library creation from selected cultivar
//  - Supplier selection and creation
//  - Organic certification tracking
//  - Comprehensive seed information capture
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Main view for creating seed library entries from cultivar selection
/// First shows cultivar catalog, then creates seed from selected cultivar
struct CreateSeedFromCultivarView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Properties
    
    @State private var selectedCultivar: Cultivar?
    @State private var showingSeedCreation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            CultivarSelectionView(selectedCultivar: $selectedCultivar)
                .navigationTitle("Select Cultivar")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .onChange(of: selectedCultivar) { cultivar in
                    if cultivar != nil {
                        showingSeedCreation = true
                    }
                }
                .sheet(isPresented: $showingSeedCreation) {
                    if let cultivar = selectedCultivar {
                        SeedCreationView(cultivar: cultivar, isPresented: $showingSeedCreation)
                    }
                }
        }
    }
}

/// Cultivar selection view using the existing catalog
struct CultivarSelectionView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Binding Properties
    
    @Binding var selectedCultivar: Cultivar?
    
    // MARK: - Fetch Requests
    
    @FetchRequest(
        entity: Cultivar.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Cultivar.family, ascending: true),
            NSSortDescriptor(keyPath: \Cultivar.name, ascending: true)
        ]
    ) var cultivars: FetchedResults<Cultivar>
    
    // MARK: - State Properties
    
    @State private var searchText = ""
    @State private var selectedFamily: String? = nil
    @State private var organicOnly = false
    
    // MARK: - Computed Properties
    
    /// Filtered cultivars based on search criteria
    private var filteredCultivars: [Cultivar] {
        return cultivars.filter { cultivar in
            // Search text filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesSearch = (cultivar.name.lowercased().contains(searchLower)) ||
                                  (cultivar.commonName?.lowercased().contains(searchLower) ?? false) ||
                                  (cultivar.family?.lowercased().contains(searchLower) ?? false)
                if !matchesSearch { return false }
            }
            
            // Family filter
            if let selectedFamily = selectedFamily {
                if cultivar.family != selectedFamily { return false }
            }
            
            // Organic filter
            if organicOnly && !cultivar.isOrganicCertified {
                return false
            }
            
            return true
        }
    }
    
    /// Available families for filtering
    private var availableFamilies: [String] {
        let families = Set(cultivars.compactMap { $0.family })
        return Array(families).sorted()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter section
            searchAndFilterSection
            
            // Cultivar list
            List(filteredCultivars, id: \.objectID) { cultivar in
                CultivarSelectionRow(cultivar: cultivar) {
                    selectedCultivar = cultivar
                }
            }
            .listStyle(PlainListStyle())
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
                
                TextField("Search cultivars...", text: $searchText)
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
                    
                    // Family filters
                    ForEach(availableFamilies, id: \.self) { family in
                        FilterChip(
                            title: family,
                            isSelected: selectedFamily == family
                        ) {
                            selectedFamily = (selectedFamily == family) ? nil : family
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundSecondary)
    }
}

/// Individual cultivar row for selection
struct CultivarSelectionRow: View {
    let cultivar: Cultivar
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Cultivar icon or color indicator
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(cultivarColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(cultivar.emoji ?? "🌱")
                            .font(.title2)
                    )
                
                // Cultivar information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(cultivar.displayName)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let family = cultivar.family {
                        Text(family)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        if cultivar.isOrganicCertified {
                            Text("Organic")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppTheme.Spacing.small)
                                .padding(.vertical, AppTheme.Spacing.tiny)
                                .background(AppTheme.Colors.organicPractice)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        
                        if let season = cultivar.season {
                            Text(season)
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.caption)
            }
            .padding(.vertical, AppTheme.Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Cultivar color based on family or default
    private var cultivarColor: Color {
        if let colorString = cultivar.iosColor {
            // Parse iOS color string if available
            return Color(colorString) ?? AppTheme.Colors.primary
        } else {
            // Default color based on family
            return AppTheme.Colors.primary.opacity(0.1)
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
                    .font(AppTheme.Typography.labelSmall)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary
            )
            .foregroundColor(
                isSelected ? .white : AppTheme.Colors.textPrimary
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.primary, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider

struct CreateSeedFromCultivarView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSeedFromCultivarView()
    }
}