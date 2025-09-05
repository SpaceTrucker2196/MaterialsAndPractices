
import SwiftUI
import CoreData

/// Main view for displaying and managing current active grows
/// Provides comprehensive tile-based overview categorized by farm
struct ActiveGrows: View {
    // MARK: - Properties

    @State private var showCreateGrow = false
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Grow.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Grow.field?.property?.displayName, ascending: true),
            NSSortDescriptor(keyPath: \Grow.title, ascending: true)
        ],
        predicate: nil,
        animation: .default
    )
    private var activeGrows: FetchedResults<Grow>

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    if activeGrows.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(growsByFarm.keys.sorted(), id: \.self) { farmName in
                            farmSection(farmName: farmName, grows: growsByFarm[farmName] ?? [])
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Active Grows")
            .toolbar {
                AddGrowToolbar(showCreateGrow: $showCreateGrow)
            }
        }
        .sheet(isPresented: $showCreateGrow) {
            ActiveGrowCreateEdit(isPresented: $showCreateGrow)
        }
    }

    // MARK: - Computed Properties
    
    /// Groups active grows by farm property
    private var growsByFarm: [String: [Grow]] {
        let groupedGrows = Dictionary(grouping: activeGrows) { grow in
            grow.field?.property?.displayName ?? "Unassigned Farm"
        }
        return groupedGrows
    }

    // MARK: - UI Components
    
    /// Empty state view when no active grows exist
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Active Grows")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Start your first grow to see it here")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            CommonActionButton(
                title: "Create New Grow",
                style: .primary
            ) {
                showCreateGrow = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
    
    /// Farm section with grows grouped by property
    private func farmSection(farmName: String, grows: [Grow]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Farm header
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title2)
                
                Text(farmName)
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(grows.count) grow\(grows.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Grows tile grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                ForEach(grows, id: \.self) { grow in
                    NavigationLink(destination: ActiveGrowDetailView(growViewModel: ActiveGrowViewModel(grow: grow))) {
                        GrowTileView(grow: grow)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Methods

    /// Deletes selected grow items from Core Data
    /// Handles Core Data save operation with error handling
    /// - Parameter offsets: IndexSet of items to delete
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { activeGrows[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Grow Tile View

/// Individual tile component for displaying grow information in grid layout
/// Shows crop emoji, worker assignments, harvest estimates, and field information
struct GrowTileView: View {
    let grow: Grow
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Top row: Emoji and worker count
            HStack {
                // Crop emoji
                Text(grow.seed?.cultivar?.emoji ?? "🌱")
                    .font(.system(size: 32))
                
                Spacer()
                
                // Worker count indicator
                workerCountIndicator
            }
            
            // Grow title
            Text(grow.title ?? "Untitled Grow")
                .font(AppTheme.Typography.dataMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Field information
            if let field = grow.field {
                HStack {
                    Image(systemName: "grid")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(.caption)
                    
                    Text(field.name ?? "Unknown Field")
                        .font(AppTheme.Typography.dataMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Days to harvest
            daysToHarvestView
            
            // Harvest estimate
            harvestEstimateView
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    
    /// Worker count indicator showing assigned and clocked-in workers
    private var workerCountIndicator: some View {
        HStack(spacing: AppTheme.Spacing.tiny) {
            Image(systemName: "person.2.fill")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.info)
            
            Text("\(clockedInWorkerCount)/\(assignedWorkerCount)")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.info)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.tiny)
        .background(AppTheme.Colors.info.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    /// Days to harvest display
    private var daysToHarvestView: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(AppTheme.Colors.primary)
                .font(.caption)
            
            Text(daysToHarvestText)
                .font(AppTheme.Typography.dataSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    /// Harvest estimate display
    private var harvestEstimateView: some View {
        HStack {
            Image(systemName: "scissors")
                .foregroundColor(AppTheme.Colors.textDataFieldNormal)
                .font(.caption)
            
            Text(harvestEstimateText)
                .font(AppTheme.Typography.dataSmall)
                .foregroundColor(AppTheme.Colors.textDataFieldNormal)
                .lineLimit(2)
        }
    }
    
    // MARK: - Helper Properties
    
    /// Number of workers assigned to this grow (via work orders)
    private var assignedWorkerCount: Int {
        guard let workOrders = grow.workOrders?.allObjects as? [WorkOrder] else {
            return 0
        }
        
        var workers = Set<Worker>()
        for workOrder in workOrders {
            workers.formUnion(workOrder.assignedWorkers())
        }
        
        return workers.count
    }
    
    /// Number of workers currently clocked in to this grow
    private var clockedInWorkerCount: Int {
        guard let workOrders = grow.workOrders?.allObjects as? [WorkOrder] else {
            return 0
        }
        
        var clockedInWorkers = Set<Worker>()
        for workOrder in workOrders {
            if let team = workOrder.assignedTeam {
                clockedInWorkers.formUnion(team.clockedInMembers())
            }
        }
        
        return clockedInWorkers.count
    }
    
    /// Formatted days to harvest text
    private var daysToHarvestText: String {
        guard let seed = grow.seed,
              let plantedDate = grow.plantedDate else {
            return "Unknown"
        }
        guard let cultivar = seed.cultivar else{
            return "unknown"
        }
        let daysUntilHarvest = HarvestCalculator.daysUntilHarvest(
            cultivar: cultivar,
            plantDate: plantedDate
        )
        
        if daysUntilHarvest == 0 {
            return "Ready!"
        } else if daysUntilHarvest < 0 {
            return "Overdue"
        } else {
            return "\(daysUntilHarvest) days"
        }
    }
    
    /// Formatted harvest estimate text
    private var harvestEstimateText: String {
        guard let seed = grow.seed,
              let plantedDate = grow.plantedDate else {
            return "Unknown"
        }
        
        let harvestEstimate = HarvestCalculator.calculateHarvestEstimate(
            seed: seed,
            plantDate: plantedDate
        )
        
        return harvestEstimate.estimatedRange
    }
}

/// Dedicated toolbar content to avoid ambiguity with any custom .toolbar extensions
private struct AddGrowToolbar: ToolbarContent {
    @Binding var showCreateGrow: Bool

    var body: some ToolbarContent {
        // Use SwiftUI.ToolbarItem explicitly to avoid symbol collisions
        SwiftUI.ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showCreateGrow = true
            } label: {
                Label("Add New Grow", systemImage: "plus")
            }
        }
    }
}

// MARK: - Preview Provider

struct CurrentGrowsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActiveGrows()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
