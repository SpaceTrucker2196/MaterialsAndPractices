//
//  ActivePractices.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 9/1/25.
//

import SwiftUI
import CoreData

// MARK: - Main View

struct ActivePracticesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Core Data Fetch Requests
    
    @FetchRequest(
        entity: SeedLibrary.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SeedLibrary.seedName, ascending: true)]
    ) private var allSeeds: FetchedResults<SeedLibrary>
    
    @FetchRequest(
        entity: CropAmendment.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CropAmendment.productName, ascending: true)]
    ) private var allAmendments: FetchedResults<CropAmendment>
    
    @FetchRequest(
        entity: Harvest.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Harvest.harvestDate, ascending: false)]
    ) private var allHarvests: FetchedResults<Harvest>
    
    @FetchRequest(
        entity: Grow.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Grow.plantedDate, ascending: false)
        ]
    ) private var allGrows: FetchedResults<Grow>
    
    // MARK: - State
    
    @State private var searchText: String = ""
    @State private var selectedSeed: SeedLibrary?
    @State private var selectedAmendment: CropAmendment?
    @State private var selectedHarvest: Harvest?
    @State private var selectedGrow: Grow?
    @State private var showingSeedDetail = false
    @State private var showingAmendmentDetail = false
    @State private var showingHarvestDetail = false
    @State private var showingUpcomingHarvests = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            header
            searchField
            
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.large) {
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
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Active Practices")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSeedDetail) {
            if let seed = selectedSeed {
                //  SeedDetailView(seed: seed, isPresented:false)
            }
        }
        .sheet(isPresented: $showingAmendmentDetail) {
            if let amendment = selectedAmendment {
                AmendmentDetailView(amendment: amendment)
            }
        }
        .sheet(isPresented: $showingHarvestDetail) {
            if let harvest = selectedHarvest {
                HarvestDetailView(harvest: harvest)
            }
        }
        .sheet(isPresented: $showingUpcomingHarvests) {
            UpcomingHarvestsView(grows: upcomingGrows)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Seeds that have active grows
    private var activeSeedsWithGrows: [SeedLibrary] {
        let activeSeedsSet = Set(allGrows.compactMap { $0.seed }.filter { _ in true })
        return Array(activeSeedsSet).filter { seed in
            let hasActiveGrows = allGrows.contains { grow in
                grow.isActive && grow.seed == seed
            }
            
            if searchText.isEmpty {
                return hasActiveGrows
            } else {
                let matchesSearch = (seed.seedName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (seed.cultivar?.name?.localizedCaseInsensitiveContains(searchText) ?? false)
                return hasActiveGrows && matchesSearch
            }
        }.sorted { ($0.seedName ?? "") < ($1.seedName ?? "") }
    }
    
    /// Amendments that have work orders in the last 3 years
    private var activeAmendments: [CropAmendment] {
        let threeYearsAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        
        return allAmendments.filter { amendment in
            guard let workOrders = amendment.workOrders?.allObjects as? [WorkOrder] else { return false }
            
            let hasRecentWorkOrders = workOrders.contains { workOrder in
                guard let createdDate = workOrder.createdDate else { return false }
                return createdDate >= threeYearsAgo
            }
            
            if searchText.isEmpty {
                return hasRecentWorkOrders
            } else {
                let matchesSearch = amendment.productName?.localizedCaseInsensitiveContains(searchText) ?? false
                return hasRecentWorkOrders && matchesSearch
            }
        }.sorted { ($0.productName ?? "") < ($1.productName ?? "") }
    }
    
    /// Active harvests deduped by grow
    private var activeHarvestsByGrow: [Harvest] {
        let activeHarvests = allHarvests.filter { harvest in
            // Only include harvests from active grows
            let hasActiveGrow = harvest.grow?.isActive == true
            
            if searchText.isEmpty {
                return hasActiveGrow
            } else {
                let matchesSearch =
                (harvest.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (harvest.grow?.title?.localizedCaseInsensitiveContains(searchText) ?? false)
                
                return hasActiveGrow && matchesSearch
            }
        }
        return activeHarvests
    }
    
    /// Grows for upcoming harvests sorted by harvest date
    private var upcomingGrows: [Grow] {
        return allGrows.filter { grow in grow.harvestDate != nil
        }.sorted { grow1, grow2 in
            guard let date1 = grow1.harvestDate,
                  let date2 = grow2.harvestDate  else { return false }
            return date1 < date2
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
    
    // MARK: - Section Views
    
    private var activeSeedsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeader(title: "Active Seeds", actionTitle: "See all") {
                // Handle see all action
            }
            
            if activeSeedsWithGrows.isEmpty {
                emptyStateCard(
                    title: "No active seeds",
                    subtitle: "Add seed lots or start new grows.",
                    icon: "leaf"
                )
            } else {
                LazyVGrid(columns: tileColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(activeSeedsWithGrows.prefix(6), id: \.objectID) { seed in
                        ActiveSeedTile(seed: seed, activeGrows: activeGrowsForSeed(seed)) {
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
            sectionHeader(title: "Active Amendments", actionTitle: "See all") {
                // Handle see all action
            }
            
            if activeAmendments.isEmpty {
                emptyStateCard(
                    title: "No active amendments",
                    subtitle: "Track nutrients and applications here.",
                    icon: "leaf.fill"
                )
            } else {
                LazyVGrid(columns: tileColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(activeAmendments.prefix(6), id: \.objectID) { amendment in
                        ActiveAmendmentTile(amendment: amendment) {
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
            sectionHeader(title: "Active Harvests", actionTitle: "See all") {
                // Handle see all action
            }
            
            if activeHarvestsByGrow.isEmpty {
                emptyStateCard(
                    title: "No active harvests",
                    subtitle: "Harvest windows will appear as they open.",
                    icon: "basket"
                )
            } else {
                LazyVGrid(columns: tileColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(activeHarvestsByGrow.prefix(6), id: \.objectID) { harvest in
                        ActiveHarvestTile(harvest: harvest) {
                            selectedHarvest = harvest
                            //  showingHarvestDetail = true
                        }
                    }
                }
            }
        }
    }
    
    private var upcomingHarvestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeader(title: "Upcoming Harvests", actionTitle: "See all") {
                //    showingUpcomingHarvests = true
            }
            
            if upcomingGrows.isEmpty {
                emptyStateCard(
                    title: "No upcoming harvests",
                    subtitle: "Plant some grows to see harvest predictions.",
                    icon: "calendar"
                )
            } else {
                LazyVGrid(columns: tileColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(upcomingGrows.prefix(4), id: \.objectID) { grow in
                        UpcomingHarvestTile(grow: grow) {
                            //  selectedGrow = grow
                            // Navigate to harvest creation flow
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func activeGrowsForSeed(_ seed: SeedLibrary) -> [Grow] {
        return allGrows.filter { grow in
            (grow.isActive != nil) && grow.seed == seed
        }
    }
    
    private var tileColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
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
    
    private func emptyStateCard(title: String, subtitle: String, icon: String) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            VStack(spacing: AppTheme.Spacing.tiny) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(subtitle)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Tile Components

struct ActiveSeedTile: View {
    let seed: SeedLibrary
    let activeGrows: [Grow]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with emoji and organic status
                HStack {
                    Text(seed.cultivar?.emoji ?? "🌱")
                        .font(.system(size: 28))
                    
                    Spacer()
                    
                    if seed.isCertifiedOrganic {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(AppTheme.Colors.organicPractice)
                            .font(.caption)
                    }
                }
                
                // Seed name
                Text(seed.displayName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Cultivar name if available
                if let cultivarName = seed.cultivar?.name {
                    Text(cultivarName)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Active grows dots
                HStack {
                    Text("\(activeGrows.count) grow\(activeGrows.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.dataSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(0..<min(activeGrows.count, 5), id: \.self) { _ in
                            Circle()
                                .fill(AppTheme.Colors.success)
                                .frame(width: 6, height: 6)
                        }
                        
                        if activeGrows.count > 5 {
                            Text("+\(activeGrows.count - 5)")
                                .font(AppTheme.Typography.dataSmall)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(seed.isCertifiedOrganic ? AppTheme.Colors.organicPractice.opacity(0.3) : AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActiveAmendmentTile: View {
    let amendment: CropAmendment
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with icon and OMRI status
                HStack {
                    Image(systemName: amendment.omriListed ? "leaf.fill" : "leaf")
                        .foregroundColor(amendment.omriListed ? AppTheme.Colors.organicPractice : AppTheme.Colors.textTertiary)
                        .font(.title3)
                    
                    Spacer()
                    
                    // Time-based color indicator
                    Circle()
                        .fill(timingColor)
                        .frame(width: 12, height: 12)
                }
                
                // Amendment name
                Text(amendment.productName ?? "Unknown Amendment")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Application rate if available
                if let rate = amendment.unitOfMeasure {
                    Text(rate)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Last application info
                HStack {
                    Text(lastApplicationText)
                        .font(AppTheme.Typography.dataSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    if amendment.omriListed {
                        Text("OMRI")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.organicPractice)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(AppTheme.Colors.organicPractice.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(timingColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var timingColor: Color {
        guard let workOrders = amendment.workOrders?.allObjects as? [WorkOrder],
              let latestWorkOrder = workOrders.max(by: { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }),
              let createdDate = latestWorkOrder.createdDate else {
            return AppTheme.Colors.amendmentOld
        }
        
        return AppTheme.ColorCoding.colorForAmendmentTiming(createdDate)
    }
    
    private var lastApplicationText: String {
        guard let workOrders = amendment.workOrders?.allObjects as? [WorkOrder],
              let latestWorkOrder = workOrders.max(by: { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }),
              let createdDate = latestWorkOrder.createdDate else {
            return "No applications"
        }
        
        let daysSince = Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
        
        switch daysSince {
        case 0...7:
            return "\(daysSince) day\(daysSince == 1 ? "" : "s") ago"
        case 8...28:
            let weeks = daysSince / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        case 29...365:
            let months = daysSince / 30
            return "\(months) month\(months == 1 ? "" : "s") ago"
        default:
            let years = daysSince / 365
            return "\(years) year\(years == 1 ? "" : "s") ago"
        }
    }
}

struct ActiveHarvestTile: View {
    let harvest: Harvest
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with harvest icon
                HStack {
                    Image(systemName: "basket.fill")
                        .foregroundColor(AppTheme.Colors.success)
                        .font(.title3)
                    
                    Spacer()
                    
                    if harvest.isCertifiedOrganic {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(AppTheme.Colors.organicPractice)
                            .font(.caption)
                    }
                }
                
                // Harvest info
                Text(harvestDisplayName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Harvest date if available
                if let harvestDate = harvest.harvestDate {
                    Text(harvestDate, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Quantity and compliance
                HStack {
                    if harvest.netQuantityValue > 0 {
                        Text(harvest.netQuantityDisplay)
                            .font(AppTheme.Typography.dataSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    if harvest.isCompliant {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.success)
                            .font(.caption)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(harvest.isCompliant ? AppTheme.Colors.success.opacity(0.3) : AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var harvestDisplayName: String {
        if let notes = harvest.notes, !notes.isEmpty {
            return notes
        }
//        if let cropPlan = harvest.cropPlan,
//           let grows = grows?.allObjects as? [Grow],
//           let firstGrow = grows.first {
//            return firstGrow.displayName
//        }
        return "Harvest"
    }
}

struct UpcomingHarvestTile: View {
    let grow: Grow
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with cultivar emoji
                HStack {
                    Text(grow.cultivar?.emoji ?? "🌱")
                        .font(.system(size: 28))
                    
                    Spacer()
                    if let harvestDate = grow.harvestDate {
                        if Calendar.current.isDateInToday(harvestDate) || harvestDate < Date() {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.Colors.warning)
                                .font(.caption)
                        }
                    }
                }
                
                // Grow name
                Text(grow.title ?? "Taco Harvest")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Estimated harvest date
                if let estimatedDate = grow.harvestDate {
                    Text("Est. \(estimatedDate, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Days info
                HStack {
                    if let daysSince = grow.daysSincePlanting {
                        Text("\(daysSince) days planted")
                            .font(AppTheme.Typography.dataSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.caption)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail Views (Placeholders)

struct AmendmentDetailView: View {
    let amendment: CropAmendment
    
    var body: some View {
        NavigationView {
            Text("Amendment Detail - Coming Soon")
                .navigationTitle(amendment.productName ?? "Amendment")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HarvestDetailView: View {
    let harvest: Harvest
    
    var body: some View {
        NavigationView {
            Text("Harvest Detail - Coming Soon")
                .navigationTitle("Harvest Details")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct UpcomingHarvestsView: View {
    let grows: [Grow]
    
    var body: some View {
//        NavigationView {
//            List(grows, id: \.objectID) { grow in
//                Text(grow.title)
//            }
//            .navigationTitle("Upcoming Harvests")
//            .navigationBarTitleDisplayMode(.inline)
//        }
    }
}

// MARK: - Preview

struct ActivePracticesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ActivePracticesView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.light)

        NavigationView {
            ActivePracticesView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.dark)
    }
}
