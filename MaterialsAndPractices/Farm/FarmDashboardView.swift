//
//  FarmDashboardView.swift
//  MaterialsAndPractices
//
//  Comprehensive farm dashboard with tile views for farms, workers, and leases.
//  Highlights active workers and leases requiring payment.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Main farm dashboard with overview of all farm operations
struct FarmDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) var properties: FetchedResults<Property>
    
    @FetchRequest(
        entity: Worker.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Worker.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Worker.name, ascending: true)
        ]
    ) var workers: FetchedResults<Worker>
    
    @FetchRequest(
        entity: Lease.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Lease.startDate, ascending: false)]
    ) var leases: FetchedResults<Lease>
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.large) {
                    // Dashboard Header
                    dashboardHeader
                    
                    // Farms Tile View
                    farmsTileSection
                    
                    // Workers Tile View
                    workersTileSection
                    
                    // Leases Overview
                    leasesOverviewSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Farm Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Dashboard Sections
    
    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Good \(greetingTime)!")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Welcome to your farm operations dashboard")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Status indicators
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    if clockedInWorkers.count > 0 {
                        HStack {
                            Circle()
                                .fill(AppTheme.Colors.success)
                                .frame(width: 8, height: 8)
                            
                            Text("\(clockedInWorkers.count) active")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                    }
                    
                    if urgentLeases.count > 0 {
                        HStack {
                            Circle()
                                .fill(AppTheme.Colors.warning)
                                .frame(width: 8, height: 8)
                            
                            Text("\(urgentLeases.count) due")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.warning)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(
            LinearGradient(
                colors: [AppTheme.Colors.primary.opacity(0.1), AppTheme.Colors.secondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    private var farmsTileSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Farms")
                
                Spacer()
                
                NavigationLink(destination: FarmListView()) {
                    Text("View All")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if !properties.isEmpty {
                LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(properties, id: \.id) { property in
                        FarmTile(property: property)
                    }
                }
            } else {
                EmptyStateView(
                    title: "No Farms",
                    message: "Add your first farm property to get started",
                    systemImage: "building.2",
                    actionTitle: "Add Farm"
                ) {
                    // Navigation to create farm
                }
                .frame(height: 120)
            }
        }
    }
    
    private var workersTileSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Workers")
                
                Spacer()
                
                NavigationLink(destination: WorkerListView()) {
                    Text("View All")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if !activeWorkers.isEmpty {
                LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(activeWorkers, id: \.id) { worker in
                        WorkerTile(worker: worker, isClockedIn: clockedInWorkers.contains(worker))
                    }
                }
            } else {
                EmptyStateView(
                    title: "No Workers",
                    message: "Add workers to manage your farm team",
                    systemImage: "person.3",
                    actionTitle: "Add Worker"
                ) {
                    // Navigation to create worker
                }
                .frame(height: 120)
            }
        }
    }
    
    private var leasesOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Leases")
                
                Spacer()
                
                Text("View All")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            if !activeLeases.isEmpty {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(activeLeases.prefix(3), id: \.id) { lease in
                        LeaseOverviewRow(lease: lease, isUrgent: urgentLeases.contains(lease))
                    }
                    
                    if activeLeases.count > 3 {
                        Text("+ \(activeLeases.count - 3) more leases")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            } else {
                Text("No active leases")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Quick Actions")
            
            LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.medium) {
                QuickActionTile(
                    title: "Add Grow",
                    icon: "leaf.fill",
                    color: AppTheme.Colors.organicMaterial
                ) {
                    // Navigate to create grow
                }
                
                QuickActionTile(
                    title: "Add Field",
                    icon: "grid",
                    color: AppTheme.Colors.primary
                ) {
                    // Navigate to create field
                }
                
                QuickActionTile(
                    title: "Add Worker",
                    icon: "person.badge.plus",
                    color: AppTheme.Colors.secondary
                ) {
                    // Navigate to create worker
                }
                
                QuickActionTile(
                    title: "Safety Check",
                    icon: "checkmark.shield",
                    color: AppTheme.Colors.compliance
                ) {
                    // Navigate to safety checklist
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
        ]
    }
    
    private var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        default:
            return "Evening"
        }
    }
    
    private var activeWorkers: [Worker] {
        workers.filter { $0.isActive }
    }
    
    private var clockedInWorkers: [Worker] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return activeWorkers.filter { worker in
            guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else { return false }
            return timeEntries.contains { entry in
                guard let entryDate = entry.date,
                      entryDate >= today && entryDate < tomorrow else { return false }
                return entry.isActive
            }
        }
    }
    
    private var activeLeases: [Lease] {
        leases.filter { $0.status == "active" }
    }
    
    private var urgentLeases: [Lease] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        return activeLeases.filter { lease in
            // Check if lease has payment due this month
            // This is a simplified check - in a real app you'd want more sophisticated payment tracking
            guard let rentFrequency = lease.rentFrequency else { return false }
            
            switch rentFrequency.lowercased() {
            case "monthly":
                return true // All monthly leases are potentially due
            case "annual":
                if let startDate = lease.startDate {
                    let startMonth = calendar.component(.month, from: startDate)
                    return startMonth == currentMonth
                }
            default:
                return false
            }
            
            return false
        }
    }
}

// MARK: - Tile Components

/// Tile component for farm properties
struct FarmTile: View {
    let property: Property
    
    var body: some View {
        NavigationLink(destination: PropertyDetailView(property: property, isAdvancedMode: true)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title2)
                    
                    Spacer()
                    
                    if property.hasIrrigation {
                        Image(systemName: "drop.fill")
                            .foregroundColor(AppTheme.Colors.info)
                            .font(.caption)
                    }
                }
                
                Text(property.displayName ?? "Unnamed Property")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                
                Text("\(property.totalAcres, specifier: "%.1f") acres")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                if let county = property.county, let state = property.state {
                    Text("\(county), \(state)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
}

/// Tile component for workers with clock-in status
struct WorkerTile: View {
    let worker: Worker
    let isClockedIn: Bool
    
    var body: some View {
        NavigationLink(destination: WorkerDetailView(worker: worker)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    // Worker photo or placeholder
                    if let photoData = worker.profilePhotoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppTheme.Colors.backgroundSecondary)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.primary)
                            )
                    }
                    
                    Spacer()
                    
                    // Clock status
                    Circle()
                        .fill(isClockedIn ? AppTheme.Colors.success : AppTheme.Colors.textSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                Text(worker.name ?? "Unknown Worker")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                
                if let position = worker.position {
                    Text(position)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Text(isClockedIn ? "Clocked In" : "Clocked Out")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(isClockedIn ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .background(isClockedIn ? AppTheme.Colors.success.opacity(0.1) : AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isClockedIn ? AppTheme.Colors.success : Color.clear, lineWidth: 2)
            )
        }
    }
}

/// Row component for lease overview
struct LeaseOverviewRow: View {
    let lease: Lease
    let isUrgent: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(lease.leaseType?.capitalized ?? "Lease")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let endDate = lease.endDate {
                    Text("Expires: \(endDate, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                if let rentAmount = lease.rentAmount {
                    Text("$\(rentAmount)")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                if isUrgent {
                    Text("Payment Due")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.warning)
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.tiny)
                        .background(AppTheme.Colors.warning.opacity(0.1))
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(isUrgent ? AppTheme.Colors.warning.opacity(0.05) : AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(isUrgent ? AppTheme.Colors.warning : Color.clear, lineWidth: 1)
        )
    }
}

/// Quick action tile component
struct QuickActionTile: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
}

// MARK: - Preview Provider

struct FarmDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        FarmDashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}