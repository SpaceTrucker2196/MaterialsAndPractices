//
//  CultivarCatalogView.swift
//  MaterialsAndPractices
//
//  Comprehensive cultivar catalog view providing searchable listing of all available cultivars.
//  Features advanced filtering capabilities, organic certification indicators, and detailed
//  navigation to cultivar management and grow creation workflows.
//
//  Features:
//  - Searchable cultivar listing with real-time filtering
//  - Family and seasonal grouping options
//  - Organic certification status indicators
//  - Direct navigation to cultivar detail and grow creation
//  - Responsive design optimized for iPhone and iPad
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Main cultivar catalog view with comprehensive search and filtering capabilities
/// Serves as the central hub for cultivar discovery and management
struct CultivarCatalogView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    
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
    @State private var selectedSeason: String? = nil
    @State private var organicOnly = false
    @State private var showingFilters = false
    
    // MARK: - Computed Properties
    
    /// Filtered cultivars based on search criteria
    private var filteredCultivars: [Cultivar] {
        return cultivars.filter { cultivar in
            // Search text filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesSearch = (cultivar.name?.lowercased().contains(searchLower) ?? false) ||
                                  (cultivar.commonName?.lowercased().contains(searchLower) ?? false) ||
                                  (cultivar.family?.lowercased().contains(searchLower) ?? false) ||
                                  (cultivar.cultivarName?.lowercased().contains(searchLower) ?? false)
                
                if !matchesSearch {
                    return false
                }
            }
            
            // Family filter
            if let family = selectedFamily, cultivar.family != family {
                return false
            }
            
            // Season filter
            if let season = selectedSeason, cultivar.season != season {
                return false
            }
            
            // Organic certification filter
            if organicOnly && !cultivar.isOrganicCertified {
                return false
            }
            
            return true
        }
    }
    
    /// Unique families for filter options
    private var availableFamilies: [String] {
        let families = Set(cultivars.compactMap { $0.family }).sorted()
        return families
    }
    
    /// Unique seasons for filter options
    private var availableSeasons: [String] {
        let seasons = Set(cultivars.compactMap { $0.season }).sorted()
        return seasons
    }
    
    /// Grouped cultivars by family for organized display
    private var groupedCultivars: [(String, [Cultivar])] {
        let grouped = Dictionary(grouping: filteredCultivars) { cultivar in
            cultivar.family ?? "Unknown Family"
        }
        
        return grouped.map { (family, cultivars) in
            (family, cultivars.sorted { ($0.name ?? "") < ($1.name ?? "") })
        }.sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Section
                searchAndFilterSection
                
                // Cultivar List
                if filteredCultivars.isEmpty {
                    emptyStateView
                } else {
                    cultivarListView
                }
            }
            .navigationTitle("Cultivar Catalog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                filterSheet
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
                
                TextField("Search cultivars...", text: $searchText)
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
                    // Organic Filter Chip
                    FilterChip(
                        title: "Organic",
                        isSelected: organicOnly,
                        icon: "checkmark.seal.fill"
                    ) {
                        organicOnly.toggle()
                    }
                    
                    // Family Filter Chips
                    ForEach(availableFamilies.prefix(5), id: \.self) { family in
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
    
    /// Main cultivar list organized by family
    private var cultivarListView: some View {
        List {
            ForEach(groupedCultivars, id: \.0) { family, familyCultivars in
                Section(header: familySectionHeader(family)) {
                    ForEach(familyCultivars, id: \.self) { cultivar in
                        NavigationLink(destination: CultivarDetailView(cultivar: cultivar)) {
                            CultivarRowView(cultivar: cultivar)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
    
    /// Empty state when no cultivars match filters
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Cultivars Found")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Try adjusting your search criteria or filters")
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
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Filter bottom sheet
    private var filterSheet: some View {
        NavigationView {
            FilterOptionsView(
                selectedFamily: $selectedFamily,
                selectedSeason: $selectedSeason,
                organicOnly: $organicOnly,
                availableFamilies: availableFamilies,
                availableSeasons: availableSeasons
            )
            .navigationTitle("Filter Cultivars")
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
    
    /// Family section header with count
    private func familySectionHeader(_ family: String) -> some View {
        HStack {
            Text(family)
                .font(AppTheme.Typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            let count = groupedCultivars.first { $0.0 == family }?.1.count ?? 0
            Text("\(count) cultivar\(count != 1 ? "s" : "")")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Helper Properties
    
    /// Check if any filters are currently active
    private var hasActiveFilters: Bool {
        return selectedFamily != nil || selectedSeason != nil || organicOnly || !searchText.isEmpty
    }
    
    // MARK: - Actions
    
    /// Clear all active filters
    private func clearAllFilters() {
        searchText = ""
        selectedFamily = nil
        selectedSeason = nil
        organicOnly = false
    }
}

// MARK: - Supporting Views

/// Individual cultivar row view with organic certification indicator
struct CultivarRowView: View {
    let cultivar: Cultivar
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Cultivar emoji/icon
            ZStack {
                Circle()
                    .fill(cultivarColor)
                    .frame(width: 40, height: 40)
                
                Text(cultivar.emoji ?? "🌱")
                    .font(.title2)
            }
            
            // Cultivar information
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                HStack {
                    Text(cultivar.name ?? "Unknown Cultivar")
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Organic certification indicator
                    if cultivar.isOrganicCertified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.Colors.organicPractice)
                            .font(.caption)
                    }
                }
                
                if let commonName = cultivar.commonName, !commonName.isEmpty {
                    Text(commonName)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    if let season = cultivar.season {
                        Text(season)
                            .font(AppTheme.Typography.labelSmall)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, AppTheme.Spacing.tiny)
                            .background(AppTheme.Colors.backgroundTertiary)
                            .cornerRadius(AppTheme.CornerRadius.small)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if let growingDays = cultivar.growingDays {
                        Text("\(growingDays) days")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                }
            }
            
            // Navigation chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
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

/// Detailed filter options view
struct FilterOptionsView: View {
    @Binding var selectedFamily: String?
    @Binding var selectedSeason: String?
    @Binding var organicOnly: Bool
    
    let availableFamilies: [String]
    let availableSeasons: [String]
    
    var body: some View {
        List {
            Section("Certification") {
                Toggle("Organic Certified Only", isOn: $organicOnly)
            }
            
            Section("Plant Family") {
                Button("All Families") {
                    selectedFamily = nil
                }
                .foregroundColor(selectedFamily == nil ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                
                ForEach(availableFamilies, id: \.self) { family in
                    Button(family) {
                        selectedFamily = (selectedFamily == family) ? nil : family
                    }
                    .foregroundColor(selectedFamily == family ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                    .background(selectedFamily == family ? AppTheme.Colors.primary.opacity(0.1) : Color.clear)
                }
            }
            
            Section("Growing Season") {
                Button("All Seasons") {
                    selectedSeason = nil
                }
                .foregroundColor(selectedSeason == nil ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                
                ForEach(availableSeasons, id: \.self) { season in
                    Button(season) {
                        selectedSeason = (selectedSeason == season) ? nil : season
                    }
                    .foregroundColor(selectedSeason == season ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                    .background(selectedSeason == season ? AppTheme.Colors.primary.opacity(0.1) : Color.clear)
                }
            }
        }
    }
}

// MARK: - Preview Provider

struct CultivarCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CultivarCatalogView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}