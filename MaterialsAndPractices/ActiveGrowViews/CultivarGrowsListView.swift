//
//  CultivarGrowsListView.swift
//  MaterialsAndPractices
//
//  List view displaying all grows associated with a specific cultivar.
//  Provides organized access to cultivar-specific growing history and
//  management capabilities for tracking cultivation success.
//
//  Features:
//  - Complete list of cultivar-associated grows
//  - Grow status and timeline information
//  - Navigation to individual grow details
//  - Sorting and filtering capabilities
//  - Quick grow creation for the cultivar
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// List view for all grows associated with a specific cultivar
/// Provides comprehensive grow management and historical tracking
struct CultivarGrowsListView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Properties
    
    let cultivar: Cultivar
    
    // MARK: - State Properties
    
    @State private var sortOrder: SortOrder = .newestFirst
    @State private var showingCreateGrow = false
    
    // MARK: - Computed Properties
    
    /// Sorted grows based on selected sort order
    private var sortedGrows: [Grow] {
        let grows = cultivar.growsArray
        
        switch sortOrder {
        case .newestFirst:
            return grows.sorted { ($0.plantedDate ?? Date.distantPast) > ($1.plantedDate ?? Date.distantPast) }
        case .oldestFirst:
            return grows.sorted { ($0.plantedDate ?? Date.distantPast) < ($1.plantedDate ?? Date.distantPast) }
        case .alphabetical:
            return grows.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .location:
            return grows.sorted { ($0.locationName ?? "") < ($1.locationName ?? "") }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            if sortedGrows.isEmpty {
                emptyStateView
            } else {
                growsList
            }
        }
        .navigationTitle("\(cultivar.displayName) Grows")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Create New Grow") {
                        showingCreateGrow = true
                    }
                    
                    Divider()
                    
                    Picker("Sort Order", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Label(order.displayName, systemImage: order.icon)
                                .tag(order)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingCreateGrow) {
            CreateGrowFromSeedLibrary(seed: nil, cultivar: cultivar, isPresented: $showingCreateGrow, context: viewContext)
        }
    }
    
    // MARK: - View Components
    
    /// Empty state when no grows exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Grows Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("You haven't created any grows for \(cultivar.displayName) yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Create First Grow") {
                showingCreateGrow = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    /// List of grows
    private var growsList: some View {
        List {
            // Summary section
            summarySection
            
            // Grows section
//            Section("Grows (\(sortedGrows.count))") {
//                ForEach(sortedGrows, id: \.objectID) { grow in
//                    NavigationLink(destination: GrowDetailView(grow:grow.cultivar)) {
//                        GrowRowView(grow: grow)
//                    }
//                }
//            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    /// Summary information section
    private var summarySection: some View {
        Section("Summary") {
            VStack(spacing: 12) {
                HStack {
                    // Cultivar info
                    HStack {
                        Text(cultivar.emoji ?? "🌱")
                            .font(.title)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cultivar.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let family = cultivar.family {
                                Text(family)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Organic certification status
                    if cultivar.isOrganicCertified {
                        Label("Organic", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Divider()
                
                // Statistics
                HStack {
                    statisticView(
                        title: "Total Grows",
                        value: "\(sortedGrows.count)",
                        icon: "list.number"
                    )
                    
                    Spacer()
                    
                    statisticView(
                        title: "Active",
                        value: "\(activeGrowsCount)",
                        icon: "leaf.fill"
                    )
                    
                    Spacer()
                    
                    statisticView(
                        title: "Completed",
                        value: "\(completedGrowsCount)",
                        icon: "checkmark.circle.fill"
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// Individual statistic view
    private func statisticView(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Computed Properties for Statistics
    
    private var activeGrowsCount: Int {
        sortedGrows.filter { grow in
            guard let plantedDate = grow.plantedDate,
                  let harvestDate = grow.harvestDate else { return false }
            let now = Date()
            return plantedDate <= now && harvestDate >= now
        }.count
    }
    
    private var completedGrowsCount: Int {
        sortedGrows.filter { grow in
            guard let harvestDate = grow.harvestDate else { return false }
            return harvestDate < Date()
        }.count
    }
}

// MARK: - Supporting Views

/// Row view for individual grow display
struct GrowRowView: View {
    let grow: Grow
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                // Grow title
                Text(grow.title ?? "Untitled Grow")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Location and dates
                HStack {
                    if let location = grow.locationName, !location.isEmpty {
                        Label(location, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let plantedDate = grow.plantedDate {
                        Label(plantedDate.formatted(date: .abbreviated, time: .shortened), systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Size information
                if grow.size > 0 {
                    Text("\(grow.size, specifier: "%.1f") acres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Days information
            VStack(alignment: .trailing, spacing: 2) {
                if let daysInfo = daysInformation {
                    Text(daysInfo.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(daysInfo.color)
                    
                    Text(daysInfo.label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        guard let plantedDate = grow.plantedDate,
              let harvestDate = grow.harvestDate else { return .gray }
        
        let now = Date()
        if now < plantedDate {
            return .orange // Planned
        } else if now >= plantedDate && now <= harvestDate {
            return .green // Active
        } else {
            return .blue // Completed
        }
    }
    
    private var daysInformation: (text: String, label: String, color: Color)? {
        guard let plantedDate = grow.plantedDate,
              let harvestDate = grow.harvestDate else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        
        if now < plantedDate {
            // Days until planting
            let days = calendar.dateComponents([.day], from: now, to: plantedDate).day ?? 0
            return ("\(days)", "until planting", .orange)
        } else if now >= plantedDate && now <= harvestDate {
            // Days until harvest
            let days = calendar.dateComponents([.day], from: now, to: harvestDate).day ?? 0
            return ("\(days)", "to harvest", .green)
        } else {
            // Days since harvest
            let days = calendar.dateComponents([.day], from: harvestDate, to: now).day ?? 0
            return ("\(days)", "since harvest", .blue)
        }
    }
}

// MARK: - Supporting Types

enum SortOrder: String, CaseIterable {
    case newestFirst = "newest"
    case oldestFirst = "oldest"
    case alphabetical = "alphabetical"
    case location = "location"
    
    var displayName: String {
        switch self {
        case .newestFirst: return "Newest First"
        case .oldestFirst: return "Oldest First"
        case .alphabetical: return "Alphabetical"
        case .location: return "By Location"
        }
    }
    
    var icon: String {
        switch self {
        case .newestFirst: return "arrow.down"
        case .oldestFirst: return "arrow.up"
        case .alphabetical: return "textformat.abc"
        case .location: return "location"
        }
    }
}

// MARK: - Preview Provider

struct CultivarGrowsListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample cultivar
        let cultivar = Cultivar(context: context)
        cultivar.name = "Cherokee Purple Tomato"
        cultivar.family = "Solanaceae"
        cultivar.emoji = "🍅"
        cultivar.isOrganicCertified = true
        
        // Create sample grows
        let grow1 = Grow(context: context)
        grow1.title = "Spring Tomatoes 2024"
        grow1.cultivar = cultivar
        grow1.locationName = "North Field"
        grow1.plantedDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        grow1.harvestDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        grow1.size = 2.5
        
        let grow2 = Grow(context: context)
        grow2.title = "Summer Tomatoes 2024"
        grow2.cultivar = cultivar
        grow2.locationName = "South Field"
        grow2.plantedDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        grow2.harvestDate = Calendar.current.date(byAdding: .month, value: 2, to: Date())
        grow2.size = 1.8
        
        return NavigationView {
            CultivarGrowsListView(cultivar: cultivar)
        }
        .environment(\.managedObjectContext, context)
    }
}
