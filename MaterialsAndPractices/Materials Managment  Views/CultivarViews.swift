//
//  CultivarViews.swift
//  MaterialsAndPractices
//
//  Provides comprehensive cultivar management views including detailed information display,
//  active and completed grow tracking, and seamless navigation throughout the application.
//  Implements MVVM architecture with clean separation of concerns.
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

/// Extension providing standardized image representation for cultivars
/// Uses system images with fallback to leaf icon for consistent UI appearance
extension Cultivar {
    struct Image: View {
        let cultivar: Cultivar

        var body: some View {
            let symbol = SwiftUI.Image(cultivar: cultivar) ?? .init(systemName: "leaf.fill")

            symbol
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .font(Font.title.weight(.light))
                .foregroundColor(AppTheme.Colors.primary)
        }
    }
}

/// Extension providing dynamic system image generation based on cultivar name
/// Implements first-letter mapping to square system icons with proper fallback handling
extension SwiftUI.Image {
    init?(cultivar: Cultivar) {
        guard let name = cultivar.emoji,
              let firstChar = name.first,
              case let symbolName = "\(firstChar.lowercased())",
              UIImage(systemName: symbolName) != nil
        else {
            return nil
        }
        self.init(systemName: symbolName)
    }
}

/// Comprehensive cultivar detail view displaying all cultivar information,
/// associated active grows, and historical completed grows with navigation support
struct CultivarGrowView: View {
    let cultivar: Cultivar
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Computed property to filter active grows (those without harvest dates)
    private var activeGrows: [Grow] {
        guard let grows = cultivar.grows else { return [] }
        return grows.compactMap { $0 as? Grow }
            .filter { $0.harvestDate == nil }
            .sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
    
    /// Computed property to filter completed grows (those with harvest dates)
    private var completedGrows: [Grow] {
        guard let grows = cultivar.grows else { return [] }
        return grows.compactMap { $0 as? Grow }
            .filter { $0.harvestDate != nil }
            .sorted { ($0.harvestDate ?? Date.distantPast) > ($1.harvestDate ?? Date.distantPast) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // MARK: - Cultivar Header Section
                cultivarHeaderSection
                
                // MARK: - Cultivar Details Grid
                cultivarDetailsGrid
                
                // MARK: - Active Grows Section
                if !activeGrows.isEmpty {
                    activeGrowsSection
                }
                
                // MARK: - Completed Grows Section
                if !completedGrows.isEmpty {
                    completedGrowsSection
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(cultivar.name ?? "Cultivar")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    /// Header section displaying cultivar name, image, and family information
    private var cultivarHeaderSection: some View {
        HStack {
            Text(cultivar.emoji ?? "0")
                .font(AppTheme.Typography.displayLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
            VStack(alignment: .leading) {
                Text(cultivar.name ?? "Unknown Cultivar")
                    .font(AppTheme.Typography.displaySmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if let family = cultivar.family, !family.isEmpty {
                    Text("Family: \(family)")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            Spacer()
        }
    }
    
    // MARK: - Details Grid
    
    /// Grid layout displaying cultivar attributes in organized cards with color coding
    private var cultivarDetailsGrid: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Primary information grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {

                if let season = cultivar.season, !season.isEmpty {
                    DetailCard(
                        title: "Season",
                        value: season,
                        backgroundColor: AppTheme.Colors.textSecondary,
                        titleColor: AppTheme.Colors.textSecondary
                    )
                }

                if let hardyZone = cultivar.hardyZone, !hardyZone.isEmpty {
                    DetailCard(
                        title: "Hardy Zone",
                        value: hardyZone,
                        backgroundColor: AppTheme.ColorCoding.colorForUSDAZone(hardyZone).opacity(0.1),
                        titleColor: AppTheme.Colors.textSecondary
                    )
                }

                if let weatherTolerance = cultivar.weatherTolerance, !weatherTolerance.isEmpty {
                    DetailCard(
                        title: "Weather Tolerance",
                        value: weatherTolerance,
                        backgroundColor: AppTheme.ColorCoding.colorForWeatherTolerance(weatherTolerance).opacity(0.1),
                        titleColor: AppTheme.Colors.textSecondary
                    )
                }

                if let growingDays = cultivar.growingDays, !growingDays.isEmpty {
                    DetailCard(
                        title: "Growing Days",
                        value: growingDays,
                        backgroundColor: AppTheme.ColorCoding.colorForGrowingDays(growingDays).opacity(0.1),
                        titleColor:AppTheme.Colors.textSecondary
                    )
                }

                if let plantingWeek = cultivar.plantingWeek, !plantingWeek.isEmpty {
                    DetailCard(
                        title: "Planting Week",
                        value: plantingWeek,
                        backgroundColor: AppTheme.Colors.organicPractice.opacity(0.1),
                        titleColor: AppTheme.Colors.textSecondary
                    )
                }

                if let optimalZones = cultivar.optimalZones, !optimalZones.isEmpty {
                    DetailCard(
                        title: "Optimal Zones",
                        value: optimalZones,
                        backgroundColor: AppTheme.Colors.zoneIndicator.opacity(0.1),
                        titleColor:AppTheme.Colors.textSecondary
                    )
                }
            }
            
            // Heat Map Section
            HarvestHeatMapView(cultivar: cultivar)
            
            // Timeline Section (if there's an active grow)
            if let activeGrow = activeGrows.first {
                GrowingSeasonTimelineView(cultivar: cultivar, grow: activeGrow)
            }
            
            // Additional information grid
            if hasAdditionalInfo {
                additionalInfoGrid
            }
        }
    }
    
    /// Additional information grid for extended cultivar data
    private var additionalInfoGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Additional Information")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: AppTheme.Spacing.small) {
                
                if let description = cultivar.cultivarDescription, !description.isEmpty {
                    ExpandableDetailCard(
                        title: "Description",
                        value: description,
                        backgroundColor: AppTheme.Colors.backgroundTertiary,
                        titleColor: AppTheme.Colors.textSecondary
                    )
                }
                
                if let growingAdvice = cultivar.growingAdvice, !growingAdvice.isEmpty {
                    ExpandableDetailCard(
                        title: "Growing Advice",
                        value: growingAdvice,
                        backgroundColor: AppTheme.Colors.success.opacity(0.1),
                        titleColor:  AppTheme.Colors.textSecondary
                    )
                }
                
                if let soilInfo = cultivar.soilInfo, !soilInfo.isEmpty {
                    ExpandableDetailCard(
                        title: "Soil Requirements",
                        value: soilInfo,
                        backgroundColor: AppTheme.Colors.organicMaterial.opacity(0.1),
                        titleColor:  AppTheme.Colors.textSecondary
                    )
                }
                
                if let pests = cultivar.pests, !pests.isEmpty {
                    ExpandableDetailCard(
                        title: "Common Pests",
                        value: pests,
                        backgroundColor: AppTheme.Colors.warning.opacity(0.1),
                        titleColor:  AppTheme.Colors.textSecondary
                    )
                }
                
                if let amendments = cultivar.amendments, !amendments.isEmpty {
                    ExpandableDetailCard(
                        title: "Recommended Amendments",
                        value: amendments,
                        backgroundColor: AppTheme.Colors.organicPractice.opacity(0.1),
                        titleColor:  AppTheme.Colors.textSecondary
                    )
                }
            }
        }
    }
    
    /// Check if cultivar has additional information to display
    private var hasAdditionalInfo: Bool {
        return [
            cultivar.cultivarDescription,
            cultivar.growingAdvice,
            cultivar.soilInfo,
            cultivar.pests,
            cultivar.amendments
        ].contains { $0 != nil && !($0?.isEmpty ?? true) }
    }
    
    // MARK: - Active Grows Section
    
    /// Section displaying active grows in a grid layout with small tiles
    private var activeGrowsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Active Grows")
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(activeGrows.count)")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.small) {
                ForEach(activeGrows, id: \.self) { grow in
                    NavigationLink(destination: GrowDetailView(growViewModel: GrowDetailViewModel(grow: grow))) {
                        GrowTile(grow: grow, isActive: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Completed Grows Section
    
    /// Section displaying completed grows in a grid layout with historical information
    private var completedGrowsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Completed Grows")
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(completedGrows.count)")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.small) {
                ForEach(completedGrows, id: \.self) { grow in
                    NavigationLink(destination: GrowDetailView(growViewModel: GrowDetailViewModel(grow: grow))) {
                        GrowTile(grow: grow, isActive: false)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Reusable card component for displaying cultivar detail information
/// Provides consistent styling and theming across detail sections
private struct DetailCard: View {
    let title: String
    let value: String
    let backgroundColor: Color
    let titleColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(titleColor)
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .background(backgroundColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Expandable card component for displaying longer cultivar information
/// Allows toggling between collapsed and expanded states for better UX
private struct ExpandableDetailCard: View {
    let title: String
    let value: String
    let backgroundColor: Color
    let titleColor: Color
    
    @State private var isExpanded = false
    
    private var displayValue: String {
        if isExpanded {
            return value
        } else {
            // Truncate to first sentence or 100 characters
            let truncated = String(value.prefix(100))
            return value.count > 100 ? truncated + "..." : value
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if value.count > 100 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(titleColor)
                            .font(.caption)
                    }
                }
            }
            
            Text(displayValue)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(titleColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Compact tile component for displaying grow information in grid layouts
/// Adapts styling based on active/completed status for clear visual distinction
private struct GrowTile: View {
    let grow: Grow
    let isActive: Bool
    
    private var tileColor: Color {
        isActive ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary
    }
    
    private var backgroundColor: Color {
        isActive ? AppTheme.Colors.primary.opacity(0.1) : Color(.systemGray6)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
            HStack {
                Image(systemName: isActive ? "leaf.fill" : "checkmark.circle.fill")
                    .foregroundColor(tileColor)
                    .font(.caption)
                Spacer()
            }
            
            Text(grow.title ?? "Untitled")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if let location = grow.locationName, !location.isEmpty {
                Text(location)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            if let harvestDate = grow.harvestDate, !isActive {
                Text("Harvested: \(harvestDate, formatter: dateFormatter)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            } else if let plantedDate = grow.plantedDate, isActive {
                Text("Planted: \(plantedDate, formatter: dateFormatter)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.small)
        .frame(height: 100)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Date formatter for consistent date display across grow tiles
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

/// Main cultivar list view providing searchable, grouped display of all available cultivars
/// Implements USDA plant database with family-based organization and enhanced visual design
struct CultivarListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Cultivar.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Cultivar.family, ascending: true),
                         NSSortDescriptor(keyPath: \Cultivar.name, ascending: true)]
    ) var cultivars: FetchedResults<Cultivar>

    @State private var searchText = ""

    /// Filtered cultivars based on search text matching name or family
    var filteredCultivars: [Cultivar] {
        if searchText.isEmpty {
            return Array(cultivars)
        } else {
            return cultivars.filter { cultivar in
                (cultivar.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (cultivar.family?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    /// Cultivars grouped by family for organized display
    var groupedCultivars: [(key: String, value: [Cultivar])] {
        let grouped = Dictionary(grouping: filteredCultivars) { $0.family ?? "Unknown" }
        return grouped.sorted(by: { $0.key < $1.key })
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
            ForEach(groupedCultivars, id: \.key) { family, cultivarsInFamily in
                Section(header: familyHeader(family: family, count: cultivarsInFamily.count)) {
                    ForEach(cultivarsInFamily.sorted { ($0.name ?? "") < ($1.name ?? "") }, id: \.self) { cultivar in
                        NavigationLink(destination: CultivarDetailView(cultivar: cultivar)) {
                            CultivarRow(cultivar: cultivar)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search cultivars...")
        .navigationTitle("Cultivars")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CultivarCatalogView()) {
                    Image(systemName: "book.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }
    
    // MARK: - Fallback List View
    
    /// Fallback list view for iOS versions prior to 15
    private var fallbackListView: some View {
        List {
            ForEach(groupedCultivars, id: \.key) { family, cultivarsInFamily in
                Section(header: Text(family)) {
                    ForEach(cultivarsInFamily.sorted { ($0.name ?? "") < ($1.name ?? "") }, id: \.self) { cultivar in
                        NavigationLink(destination: CultivarDetailView(cultivar: cultivar)) {
                            CultivarRow(cultivar: cultivar)
                        }
                    }
                }
            }
        }
        .navigationTitle("Cultivars")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CultivarCatalogView()) {
                    Image(systemName: "book.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }
    
    // MARK: - Supporting Methods
    
    /// Creates enhanced family header with count and styling
    private func familyHeader(family: String, count: Int) -> some View {
        HStack {
            Text(family)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
            Text("\(count)")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Cultivar Row Component

/// Individual row component for displaying cultivar information in lists
/// Provides consistent layout with icon, name, and metadata tags
private struct CultivarRow: View {
    let cultivar: Cultivar
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Text(cultivar.emoji ?? "Unknown")
                .font(AppTheme.Typography.displayLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(cultivar.name ?? "Unknown")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack(spacing: AppTheme.Spacing.extraSmall) {
                    if let season = cultivar.season, !season.isEmpty {
                        CultivarMetadataTag(text: season, color:AppTheme.Colors.seasonIndicator)
                    }
                    
                    if let hardyZone = cultivar.hardyZone, !hardyZone.isEmpty {
                        CultivarMetadataTag(text: "Zone \(hardyZone)", color: AppTheme.Colors.zoneIndicator)
                    }
                }
            }
            Spacer()
        }
    }
}

// MARK: - Metadata Tag Component

/// Small tag component for displaying cultivar metadata (season, zone, etc.)
/// Provides consistent styling and color coding for different metadata types
private struct CultivarMetadataTag: View {
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

struct CultivarViews_Previews: PreviewProvider {
    static var previews: some View {
        CultivarListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
