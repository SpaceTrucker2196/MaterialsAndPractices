//
//  CertificationOverviewView.swift
//  MaterialsAndPractices
//
//  Certification overview showing farms in tiled view organized by county and state
//  with organic certification status and upcoming inspection indicators
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Main certification overview view showing farms organized by location
struct CertificationOverviewView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch all farms with location information
    @FetchRequest(
        entity: Farm.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Farm.state, ascending: true),
            NSSortDescriptor(keyPath: \Farm.county, ascending: true),
            NSSortDescriptor(keyPath: \Farm.name, ascending: true)
        ]
    ) private var farms: FetchedResults<Farm>
    
    @State private var selectedFarm: Farm?
    @State private var showingCertificationDetail = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Header
                    headerSection
                    
                    // Farms by location
                    if farms.isEmpty {
                        emptyStateView
                    } else {
                        farmsByLocationSection
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("Certification Management")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCertificationDetail) {
            if let farm = selectedFarm {
                OrganicCertificationView(farm: farm)
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.Colors.organicPractice)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Organic Certification")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Track certification status and compliance by farm location")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Summary statistics
            HStack(spacing: AppTheme.Spacing.large) {
                CertificationStatCard(
                    title: "Total Farms",
                    value: "\(farms.count)",
                    icon: "building.2.fill",
                    color: AppTheme.Colors.primary
                )
                
                CertificationStatCard(
                    title: "Certified Organic",
                    value: "\(organicCertifiedCount)",
                    icon: "leaf.fill",
                    color: AppTheme.Colors.organicPractice
                )
                
                CertificationStatCard(
                    title: "Pending Inspections",
                    value: "\(pendingInspectionsCount)",
                    icon: "calendar.badge.exclamationmark",
                    color: AppTheme.Colors.warning
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Farms Available")
                .font(AppTheme.Typography.headingMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Add farms in Utilities > Add New Farm to track certification status")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.extraLarge)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    private var farmsByLocationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            ForEach(locationGroups, id: \.key) { locationGroup in
                locationGroupSection(for: locationGroup)
            }
        }
    }
    
    private func locationGroupSection(for locationGroup: (key: String, value: [Farm])) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Location header
            HStack {
                Text(locationGroup.key)
                    .font(AppTheme.Typography.headingMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(locationGroup.value.count) farm\(locationGroup.value.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.small)
            
            // Farm tiles
            LazyVGrid(columns: farmGridColumns, spacing: AppTheme.Spacing.medium) {
                ForEach(locationGroup.value, id: \.objectID) { farm in
                    FarmCertificationTile(farm: farm) {
                        selectedFarm = farm
                        showingCertificationDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var locationGroups: [(key: String, value: [Farm])] {
        let grouped = Dictionary(grouping: farms) { farm in
            let county = farm.county ?? "Unknown County"
            let state = farm.state ?? "Unknown State"
            return "\(county), \(state)"
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    private var farmGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
        ]
    }
    
    private var organicCertifiedCount: Int {
        farms.filter { $0.isOrganicCertified }.count
    }
    
    private var pendingInspectionsCount: Int {
        farms.filter { $0.hasUpcomingInspection }.count
    }
}

// MARK: - Supporting Views

/// Certification statistic card
struct CertificationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fontWeight(.bold)
            
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Individual farm certification tile
struct FarmCertificationTile: View {
    let farm: Farm
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Farm header
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(farm.name ?? "Unnamed Farm")
                        .font(AppTheme.Typography.headingSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    if let address = farm.address {
                        Text(address)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                // Certification indicators
                HStack(spacing: AppTheme.Spacing.medium) {
                    // Organic certification indicator
                    CertificationIndicator(
                        icon: "leaf.fill",
                        label: "Organic",
                        isActive: farm.isOrganicCertified,
                        activeColor: AppTheme.Colors.organicPractice,
                        inactiveColor: AppTheme.Colors.textTertiary
                    )
                    
                    Spacer()
                    
                    // Upcoming inspection indicator
                    CertificationIndicator(
                        icon: "calendar.badge.exclamationmark",
                        label: "Inspection",
                        isActive: farm.hasUpcomingInspection,
                        activeColor: AppTheme.Colors.warning,
                        inactiveColor: AppTheme.Colors.textTertiary
                    )
                }
                
                // Action area
                HStack {
                    Text("View Compliance")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Certification status indicator
struct CertificationIndicator: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let inactiveColor: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.tiny) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isActive ? activeColor : inactiveColor)
            
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(isActive ? activeColor : inactiveColor)
        }
    }
}

// MARK: - Farm Extensions for Certification

extension Farm {
    /// Indicates if farm has organic certification
    var isOrganicCertified: Bool {
        // TODO: Implement based on actual certification data model
        // For now, return true for some farms as demo
        return (name?.hash ?? 0) % 3 == 0
    }
    
    /// Indicates if farm has upcoming inspection
    var hasUpcomingInspection: Bool {
        // TODO: Implement based on actual inspection scheduling
        // For now, return true for some farms as demo
        return (name?.hash ?? 0) % 4 == 0
    }
    
    /// Next inspection date
    var nextInspectionDate: Date? {
        // TODO: Implement based on actual inspection scheduling
        guard hasUpcomingInspection else { return nil }
        return Calendar.current.date(byAdding: .day, value: 30, to: Date())
    }
    
    /// Certification expiration date
    var certificationExpirationDate: Date? {
        // TODO: Implement based on actual certification data
        guard isOrganicCertified else { return nil }
        return Calendar.current.date(byAdding: .year, value: 1, to: Date())
    }
}

// MARK: - Preview

struct CertificationOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        CertificationOverviewView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}