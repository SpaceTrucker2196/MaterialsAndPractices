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

    // Actions (stubs) you can hook to navigation or creation flows
    var onTapSeed: (ActiveSeed) -> Void = { _ in }
    var onTapAmendment: (ActiveAmendment) -> Void = { _ in }
    var onTapHarvest: (ActiveHarvest) -> Void = { _ in }
    var onTapUpcomingHarvest: (UpcomingHarvest) -> Void = { _ in }
    var onSeeAllSeeds: () -> Void = {}
    var onSeeAllAmendments: () -> Void = {}
    var onSeeAllHarvests: () -> Void = {}
    var onSeeAllUpcomingHarvests: () -> Void = {}
    var onCreateHarvest: (UpcomingHarvest) -> Void = { _ in }

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
                            .onTapGesture { onTapSeed(seed) }
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
                            .onTapGesture { onTapAmendment(amendment) }
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
                            .onTapGesture { onTapHarvest(harvest) }
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
                            .onTapGesture { onCreateHarvest(upcomingHarvest) }
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
