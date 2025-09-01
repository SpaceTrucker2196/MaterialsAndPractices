//
//  ActivePractices.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 9/1/25.
//

import SwiftUI

// MARK: - Enhanced data models for tile-based Active Practices

struct ActiveSeed: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var cultivar: String?
    var quantity: String?
    var emoji: String = "🌱"
    var isOrganic: Bool = false
    var activeGrowCount: Int = 0
    var totalGrowCount: Int = 0
}

struct ActiveAmendment: Identifiable, Hashable {
    let id = UUID()
    var productName: String
    var rateDisplay: String?
    var isOMRI: Bool = false
    var daysSinceApplication: Int = 0
    var lastApplicationDate: Date?
    var workOrderCount: Int = 0
}

struct ActiveHarvest: Identifiable, Hashable {
    let id = UUID()
    var cropName: String
    var growId: String
    var windowDisplay: String?   // e.g., "Weeks 31–34"
    var status: String?          // e.g., "Best", "Good"
    var emoji: String = "🧺"
    var estimatedYield: String?
    var harvestCount: Int = 0
}

struct UpcomingHarvest: Identifiable, Hashable {
    let id = UUID()
    var cropName: String
    var growId: String
    var estimatedHarvestDate: Date
    var fieldName: String?
    var daysUntilHarvest: Int
    var readyToHarvest: Bool = false
}

// MARK: - Main View

struct ActivePracticesView: View {
    // Injection points so you can plug in Core Data later
    var seeds: [ActiveSeed] = []
    var amendments: [ActiveAmendment] = []
    var harvests: [ActiveHarvest] = []
    var upcomingHarvests: [UpcomingHarvest] = []

    // UI state
    @State private var searchText: String = ""
    @State private var selectedSeed: ActiveSeed?
    @State private var selectedAmendment: ActiveAmendment?
    @State private var selectedHarvest: ActiveHarvest?
    @State private var selectedUpcomingHarvest: UpcomingHarvest?
    @State private var showingSeedDetail = false
    @State private var showingAmendmentDetail = false
    @State private var showingHarvestDetail = false
    @State private var showingCreateHarvest = false

    // Actions (stubs) you can hook to navigation or creation flows
    var onSeeAllSeeds: () -> Void = {}
    var onSeeAllAmendments: () -> Void = {}
    var onSeeAllHarvests: () -> Void = {}
    var onSeeAllUpcomingHarvests: () -> Void = {}

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.large) {
                // Header
                header
                
                // Search field
                searchField
                
                // Active Seeds Section
                activeSeedsSection
                
                // Active Amendments Section  
                activeAmendmentsSection
                
                // Active Harvests Section
                activeHarvestsSection
                
                // Upcoming Harvests Section
                upcomingHarvestsSection
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.top, AppTheme.Spacing.medium)
        }
        .background(AppTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Active Practices")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSeedDetail) {
            if let seed = selectedSeed {
                NavigationView {
                    SeedDetailView(seed: seed)
                }
            }
        }
        .sheet(isPresented: $showingAmendmentDetail) {
            if let amendment = selectedAmendment {
                NavigationView {
                    AmendmentDetailView(amendment: amendment)
                }
            }
        }
        .sheet(isPresented: $showingHarvestDetail) {
            if let harvest = selectedHarvest {
                NavigationView {
                    HarvestDetailView(harvest: harvest)
                }
            }
        }
        .sheet(isPresented: $showingCreateHarvest) {
            if let upcomingHarvest = selectedUpcomingHarvest {
                CreateHarvestWorkflowView(upcomingHarvest: upcomingHarvest, isPresented: $showingCreateHarvest)
            }
        }
    }

    // MARK: - Filtering

    private var filteredSeeds: [ActiveSeed] {
        guard !searchText.isEmpty else { return seeds }
        return seeds.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.cultivar?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var filteredAmendments: [ActiveAmendment] {
        guard !searchText.isEmpty else { return amendments }
        return amendments.filter {
            $0.productName.localizedCaseInsensitiveContains(searchText)
            || ($0.rateDisplay?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var filteredHarvests: [ActiveHarvest] {
        guard !searchText.isEmpty else { return harvests }
        return harvests.filter {
            $0.cropName.localizedCaseInsensitiveContains(searchText)
            || ($0.windowDisplay?.localizedCaseInsensitiveContains(searchText) ?? false)
            || ($0.status?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var filteredUpcomingHarvests: [UpcomingHarvest] {
        guard !searchText.isEmpty else { return upcomingHarvests }
        return upcomingHarvests.filter {
            $0.cropName.localizedCaseInsensitiveContains(searchText)
            || ($0.fieldName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    // MARK: - Grid Configuration
    
    private var tileGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
        ]
    }

    // MARK: - Section Views

    private var activeSeedsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeader(title: "Active Seeds", actionTitle: "See all", action: onSeeAllSeeds)
            
            if filteredSeeds.isEmpty {
                emptyTile(title: "No active seeds", subtitle: "Add seed lots or import from suppliers.", icon: "🌱")
            } else {
                LazyVGrid(columns: tileGridColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(filteredSeeds.prefix(6)) { seed in
                        SeedTile(seed: seed)
                            .onTapGesture { 
                                selectedSeed = seed
                                showingSeedDetail = true
                            }
                    }
                }
            }
        }
    }
    
    private var activeAmendmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeader(title: "Active Amendments", actionTitle: "See all", action: onSeeAllAmendments)
            
            if filteredAmendments.isEmpty {
                emptyTile(title: "No active amendments", subtitle: "Track nutrients and applications here.", icon: "🧪")
            } else {
                LazyVGrid(columns: tileGridColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(filteredAmendments.prefix(6)) { amendment in
                        AmendmentTile(amendment: amendment)
                            .onTapGesture { 
                                selectedAmendment = amendment
                                showingAmendmentDetail = true
                            }
                    }
                }
            }
        }
    }
    
    private var activeHarvestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeader(title: "Active Harvests", actionTitle: "See all", action: onSeeAllHarvests)
            
            if filteredHarvests.isEmpty {
                emptyTile(title: "No active harvests", subtitle: "Harvest windows will appear as they open.", icon: "🧺")
            } else {
                LazyVGrid(columns: tileGridColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(filteredHarvests.prefix(6)) { harvest in
                        HarvestTile(harvest: harvest)
                            .onTapGesture { 
                                selectedHarvest = harvest
                                showingHarvestDetail = true
                            }
                    }
                }
            }
        }
    }
    
    private var upcomingHarvestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeader(title: "Upcoming Harvests", actionTitle: "See all", action: onSeeAllUpcomingHarvests)
            
            if filteredUpcomingHarvests.isEmpty {
                emptyTile(title: "No upcoming harvests", subtitle: "Harvest schedules will appear based on planting dates.", icon: "📅")
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(filteredUpcomingHarvests.prefix(5)) { upcomingHarvest in
                        UpcomingHarvestRow(harvest: upcomingHarvest)
                            .onTapGesture { 
                                selectedUpcomingHarvest = upcomingHarvest
                                showingCreateHarvest = true
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components

    private var header: some View {
        HStack {
            Text("Overview")
                .font(AppTheme.Typography.dataLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
        }
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textTertiary)
            TextField("Search seeds, amendments, harvests", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func sectionHeader(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
            Button(actionTitle, action: action)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.accent)
                .buttonStyle(.plain)
        }
        .padding(.top, AppTheme.Spacing.small)
    }

    private func emptyTile(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .center, spacing: AppTheme.Spacing.small) {
            Text(icon)
                .font(.largeTitle)
            
            Text(title)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Tile Views

private struct SeedTile: View {
    var seed: ActiveSeed

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Header with emoji and organic status
            HStack {
                Text(seed.emoji)
                    .font(.title2)
                
                Spacer()
                
                if seed.isOrganic {
                    Text("ORGANIC")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(AppTheme.Colors.success.opacity(0.12))
                        .cornerRadius(4)
                }
            }
            
            // Seed name and cultivar
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(seed.name)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let cultivar = seed.cultivar, !cultivar.isEmpty {
                    Text(cultivar)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Grow count with dots
            HStack {
                if let quantity = seed.quantity {
                    Text(quantity)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                Spacer()
                
                // Dots representing active grows
                HStack(spacing: 2) {
                    ForEach(0..<min(seed.activeGrowCount, 5), id: \.self) { _ in
                        Circle()
                            .fill(AppTheme.Colors.primary)
                            .frame(width: 4, height: 4)
                    }
                    
                    if seed.activeGrowCount > 5 {
                        Text("+\(seed.activeGrowCount - 5)")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .frame(height: 120)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

private struct AmendmentTile: View {
    var amendment: ActiveAmendment

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Header with icon and age indicator
            HStack {
                Image(systemName: amendment.isOMRI ? "leaf.fill" : "leaf")
                    .foregroundColor(amendment.isOMRI ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                    .font(.title2)
                
                Spacer()
                
                // Age color indicator
                Circle()
                    .fill(AppTheme.ColorCoding.colorForAmendmentAge(amendment.daysSinceApplication))
                    .frame(width: 12, height: 12)
            }
            
            // Amendment name and rate
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(amendment.productName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let rate = amendment.rateDisplay {
                    Text(rate)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Status row with OMRI and work order count
            HStack {
                if amendment.isOMRI {
                    Text("OMRI")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(AppTheme.Colors.success.opacity(0.12))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text("\(amendment.workOrderCount) orders")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .frame(height: 120)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.ColorCoding.colorForAmendmentAge(amendment.daysSinceApplication), lineWidth: 2)
        )
    }
}

private struct HarvestTile: View {
    var harvest: ActiveHarvest

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Header with emoji and status
            HStack {
                Text(harvest.emoji)
                    .font(.title2)
                
                Spacer()
                
                if let status = harvest.status {
                    Text(status.uppercased())
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(statusColor(for: status))
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(statusColor(for: status).opacity(0.12))
                        .cornerRadius(4)
                }
            }
            
            // Crop name and window
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(harvest.cropName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let window = harvest.windowDisplay {
                    Text(window)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Harvest info
            HStack {
                if let yield = harvest.estimatedYield {
                    Text(yield)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                Spacer()
                
                Text("\(harvest.harvestCount) harvests")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .frame(height: 120)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "best":
            return AppTheme.Colors.success
        case "good":
            return AppTheme.Colors.info
        case "fair":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.textSecondary
        }
    }
}

private struct UpcomingHarvestRow: View {
    var harvest: UpcomingHarvest

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Status indicator
            Circle()
                .fill(harvest.readyToHarvest ? AppTheme.Colors.success : AppTheme.Colors.warning)
                .frame(width: 12, height: 12)
            
            // Harvest info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(harvest.cropName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack {
                    if let fieldName = harvest.fieldName {
                        Text(fieldName)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(harvest.estimatedHarvestDate, style: .date)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Days until harvest
            VStack(alignment: .trailing) {
                Text("\(harvest.daysUntilHarvest)")
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(harvest.readyToHarvest ? AppTheme.Colors.success : AppTheme.Colors.warning)
                
                Text(harvest.daysUntilHarvest == 1 ? "day" : "days")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            // Action indicator
            Image(systemName: "plus.circle.fill")
                .foregroundColor(AppTheme.Colors.primary)
                .font(.title3)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(harvest.readyToHarvest ? AppTheme.Colors.success : AppTheme.Colors.warning, lineWidth: 1)
        )
    }
}

// MARK: - Preview with enhanced sample data

struct ActivePracticesView_Previews: PreviewProvider {
    static var previews: some View {
        let demoSeeds: [ActiveSeed] = [
            .init(name: "Tomato – Cherry Sweet 100", cultivar: "Solanum lycopersicum", quantity: "120 g", emoji: "🍅", isOrganic: true, activeGrowCount: 3, totalGrowCount: 5),
            .init(name: "Carrot – Nantes", cultivar: "Daucus carota", quantity: "2.0 kg", emoji: "🥕", isOrganic: false, activeGrowCount: 2, totalGrowCount: 2),
            .init(name: "Basil – Genovese", cultivar: "Ocimum basilicum", quantity: "400 g", emoji: "🌿", isOrganic: true, activeGrowCount: 1, totalGrowCount: 3),
            .init(name: "Lettuce – Buttercrunch", cultivar: "Lactuca sativa", quantity: "50 g", emoji: "🥬", isOrganic: true, activeGrowCount: 4, totalGrowCount: 6),
        ]

        let demoAmendments: [ActiveAmendment] = [
            .init(productName: "Down To Earth – Kelp Meal", rateDisplay: "50 lb/acre", isOMRI: true, daysSinceApplication: 5, lastApplicationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), workOrderCount: 3),
            .init(productName: "Gypsum (Calcium Sulfate)", rateDisplay: "300 lb/acre", isOMRI: false, daysSinceApplication: 45, lastApplicationDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()), workOrderCount: 2),
            .init(productName: "Compost (Windrowed)", rateDisplay: "5 ton/acre", isOMRI: true, daysSinceApplication: 120, lastApplicationDate: Calendar.current.date(byAdding: .day, value: -120, to: Date()), workOrderCount: 8),
            .init(productName: "Fish Emulsion", rateDisplay: "2 gal/acre", isOMRI: true, daysSinceApplication: 800, lastApplicationDate: Calendar.current.date(byAdding: .day, value: -800, to: Date()), workOrderCount: 12),
        ]

        let demoHarvests: [ActiveHarvest] = [
            .init(cropName: "Tomato – Sungold", growId: "grow-001", windowDisplay: "Weeks 30–33", status: "Best", emoji: "🧺", estimatedYield: "45 lbs", harvestCount: 3),
            .init(cropName: "Cucumber – Marketmore", growId: "grow-002", windowDisplay: "Weeks 27–31", status: "Good", emoji: "🥒", estimatedYield: "30 lbs", harvestCount: 2),
            .init(cropName: "Lettuce – Butterhead", growId: "grow-003", windowDisplay: "Weeks 20–22", status: "Fair", emoji: "🥬", estimatedYield: "12 lbs", harvestCount: 1),
        ]
        
        let demoUpcomingHarvests: [UpcomingHarvest] = [
            .init(cropName: "Corn – Sweet Corn", growId: "grow-004", estimatedHarvestDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(), fieldName: "Field A", daysUntilHarvest: 3, readyToHarvest: true),
            .init(cropName: "Squash – Summer", growId: "grow-005", estimatedHarvestDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(), fieldName: "Field B", daysUntilHarvest: 7, readyToHarvest: false),
            .init(cropName: "Beans – Green", growId: "grow-006", estimatedHarvestDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(), fieldName: "Field C", daysUntilHarvest: 14, readyToHarvest: false),
        ]

        NavigationView {
            ActivePracticesView(
                seeds: demoSeeds,
                amendments: demoAmendments,
                harvests: demoHarvests,
                upcomingHarvests: demoUpcomingHarvests
            )
        }
        .preferredColorScheme(.light)

        NavigationView {
            ActivePracticesView(
                seeds: demoSeeds,
                amendments: demoAmendments,
                harvests: demoHarvests,
                upcomingHarvests: demoUpcomingHarvests
            )
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Detail Views

/// Seed detail view showing seed information and active grows
struct SeedDetailView: View {
    let seed: ActiveSeed
    @State private var showingGrowCreation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Seed Header
                seedHeaderSection
                
                // Seed Information
                seedInfoSection
                
                // Active Grows Section
                activeGrowsSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(seed.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Grow") {
                    showingGrowCreation = true
                }
            }
        }
        .sheet(isPresented: $showingGrowCreation) {
            CreateGrowView(seed: seed, isPresented: $showingGrowCreation)
        }
    }
    
    private var seedHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(seed.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(seed.name)
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let cultivar = seed.cultivar {
                        Text(cultivar)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                if seed.isOrganic {
                    Text("ORGANIC")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.vertical, AppTheme.Spacing.small)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .background(AppTheme.Colors.success.opacity(0.12))
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var seedInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Seed Information")
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Available Quantity:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(seed.quantity ?? "Unknown")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Active Grows:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(seed.activeGrowCount)")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Total Grows:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(seed.totalGrowCount)")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var activeGrowsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Active Grows")
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all grows
                }
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.accent)
            }
            
            // Mock grow data for demonstration
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(0..<seed.activeGrowCount, id: \.self) { index in
                    GrowRowView(
                        growName: "Grow \(index + 1)",
                        fieldName: "Field \(Character(UnicodeScalar(65 + index % 3)!))",
                        plantedDate: Calendar.current.date(byAdding: .day, value: -(30 + index * 10), to: Date()) ?? Date(),
                        status: ["Active", "Growing", "Flowering"][index % 3]
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Amendment detail view showing amendment information and work orders
struct AmendmentDetailView: View {
    let amendment: ActiveAmendment
    @State private var showingWorkOrderCreation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Amendment Header
                amendmentHeaderSection
                
                // Amendment Information
                amendmentInfoSection
                
                // Work Orders Section
                workOrdersSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(amendment.productName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Work Order") {
                    showingWorkOrderCreation = true
                }
            }
        }
        .sheet(isPresented: $showingWorkOrderCreation) {
            CreateWorkOrderView(amendment: amendment, isPresented: $showingWorkOrderCreation)
        }
    }
    
    private var amendmentHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: amendment.isOMRI ? "leaf.fill" : "leaf")
                    .foregroundColor(amendment.isOMRI ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(amendment.productName)
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let rate = amendment.rateDisplay {
                        Text(rate)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.small) {
                    if amendment.isOMRI {
                        Text("OMRI")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.success)
                            .padding(.vertical, AppTheme.Spacing.small)
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .background(AppTheme.Colors.success.opacity(0.12))
                            .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    
                    Circle()
                        .fill(AppTheme.ColorCoding.colorForAmendmentAge(amendment.daysSinceApplication))
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.ColorCoding.colorForAmendmentAge(amendment.daysSinceApplication), lineWidth: 2)
        )
    }
    
    private var amendmentInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Amendment Information")
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Last Application:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if let lastDate = amendment.lastApplicationDate {
                        Text(lastDate, style: .date)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Text("Days Since Application:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(amendment.daysSinceApplication) days")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.ColorCoding.colorForAmendmentAge(amendment.daysSinceApplication))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Work Orders:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(amendment.workOrderCount)")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var workOrdersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Work Orders")
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all work orders
                }
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.accent)
            }
            
            // Mock work order data for demonstration
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(0..<min(amendment.workOrderCount, 5), id: \.self) { index in
                    WorkOrderRowView(
                        title: "Apply \(amendment.productName)",
                        fieldName: "Field \(Character(UnicodeScalar(65 + index % 3)!))",
                        applicationDate: Calendar.current.date(byAdding: .day, value: -(index * 30 + 15), to: Date()) ?? Date(),
                        ageColor: AppTheme.ColorCoding.colorForAmendmentAge(index * 30 + 15)
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Harvest detail view showing grow information and harvests
struct HarvestDetailView: View {
    let harvest: ActiveHarvest
    @State private var showingHarvestCreation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Harvest Header
                harvestHeaderSection
                
                // Grow Information
                growInfoSection
                
                // Harvests Section
                harvestsSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(harvest.cropName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Record Harvest") {
                    showingHarvestCreation = true
                }
            }
        }
        .sheet(isPresented: $showingHarvestCreation) {
            CreateHarvestView(harvest: harvest, isPresented: $showingHarvestCreation)
        }
    }
    
    private var harvestHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(harvest.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(harvest.cropName)
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let window = harvest.windowDisplay {
                        Text(window)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let status = harvest.status {
                    Text(status.uppercased())
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(statusColor(for: status))
                        .padding(.vertical, AppTheme.Spacing.small)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .background(statusColor(for: status).opacity(0.12))
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var growInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Grow Information")
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Grow ID:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(harvest.growId)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Estimated Yield:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(harvest.estimatedYield ?? "Not specified")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Harvest Count:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(harvest.harvestCount)")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var harvestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Harvest History")
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all harvests
                }
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.accent)
            }
            
            // Mock harvest data for demonstration
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(0..<harvest.harvestCount, id: \.self) { index in
                    HarvestEntryRowView(
                        harvestDate: Calendar.current.date(byAdding: .day, value: -(index * 7), to: Date()) ?? Date(),
                        quantity: "\(15 + index * 5) lbs",
                        quality: ["Premium", "Standard", "Processing"][index % 3],
                        worker: "Worker \(index + 1)"
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "best":
            return AppTheme.Colors.success
        case "good":
            return AppTheme.Colors.info
        case "fair":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - Row Components for Detail Views

private struct GrowRowView: View {
    let growName: String
    let fieldName: String
    let plantedDate: Date
    let status: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(growName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("\(fieldName) • \(plantedDate, style: .date)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(status)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.success)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(AppTheme.Colors.success.opacity(0.12))
                .cornerRadius(4)
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

private struct WorkOrderRowView: View {
    let title: String
    let fieldName: String
    let applicationDate: Date
    let ageColor: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(ageColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("\(fieldName) • \(applicationDate, style: .date)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("Completed")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.success)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(AppTheme.Colors.success.opacity(0.12))
                .cornerRadius(4)
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

private struct HarvestEntryRowView: View {
    let harvestDate: Date
    let quantity: String
    let quality: String
    let worker: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                HStack {
                    Text(harvestDate, style: .date)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(quantity)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Quality: \(quality)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("By: \(worker)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

// MARK: - Placeholder Creation Views

private struct CreateGrowView: View {
    let seed: ActiveSeed
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Create New Grow for \(seed.name)")
                .navigationTitle("New Grow")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

private struct CreateWorkOrderView: View {
    let amendment: ActiveAmendment
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Create Work Order for \(amendment.productName)")
                .navigationTitle("New Work Order")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

private struct CreateHarvestView: View {
    let harvest: ActiveHarvest
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Record Harvest for \(harvest.cropName)")
                .navigationTitle("Record Harvest")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

/// Enhanced harvest creation workflow for upcoming harvests
private struct CreateHarvestWorkflowView: View {
    let upcomingHarvest: UpcomingHarvest
    @Binding var isPresented: Bool
    @State private var harvestQuantity: String = ""
    @State private var qualityGrade: String = "Premium"
    @State private var notes: String = ""
    @State private var createWorkOrder: Bool = false
    @State private var assignedTeam: String = ""
    @State private var workOrderNotes: String = ""
    
    private let qualityOptions = ["Premium", "Standard", "Processing", "Seconds"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Harvest Header
                    harvestHeaderSection
                    
                    // Harvest Details Form
                    harvestDetailsForm
                    
                    // Work Order Section
                    workOrderSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Record Harvest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save harvest and work order
                        isPresented = false
                    }
                    .disabled(harvestQuantity.isEmpty)
                }
            }
        }
    }
    
    private var harvestHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(upcomingHarvest.cropName)
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        if let fieldName = upcomingHarvest.fieldName {
                            Text(fieldName)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Text("•")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        
                        Text(upcomingHarvest.estimatedHarvestDate, style: .date)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Circle()
                        .fill(upcomingHarvest.readyToHarvest ? AppTheme.Colors.success : AppTheme.Colors.warning)
                        .frame(width: 12, height: 12)
                    
                    Text(upcomingHarvest.readyToHarvest ? "Ready" : "\(upcomingHarvest.daysUntilHarvest) days")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(upcomingHarvest.readyToHarvest ? AppTheme.Colors.success : AppTheme.Colors.warning)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var harvestDetailsForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Harvest Details")
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Quantity field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Quantity Harvested")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    TextField("Enter quantity (e.g., 45 lbs, 20 kg)", text: $harvestQuantity)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Quality grade picker
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Quality Grade")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Picker("Quality Grade", selection: $qualityGrade) {
                        ForEach(qualityOptions, id: \.self) { quality in
                            Text(quality).tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Notes field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Notes")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    TextField("Harvest notes, weather conditions, etc.", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var workOrderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Toggle("Create Work Order", isOn: $createWorkOrder)
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            if createWorkOrder {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Team assignment field
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Assign Team/Worker")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        TextField("Team or worker name", text: $assignedTeam)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Work order notes field
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Work Order Notes")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        TextField("Special instructions for the harvest work", text: $workOrderNotes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3, reservesSpace: true)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .animation(.easeInOut(duration: 0.3), value: createWorkOrder)
    }
}
