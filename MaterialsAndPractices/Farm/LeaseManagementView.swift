//
//  LeaseManagementView.swift
//  MaterialsAndPractices
//
//  Comprehensive lease management interface providing access to lease creation,
//  monitoring, and management. Follows established UI patterns and provides
//  comprehensive lease workflow management.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Main lease management view for the utilities section
/// Provides comprehensive lease workflow management and monitoring
struct LeaseManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingLeaseCreation = false
    @State private var selectedFilter: LeaseFilter = .all
    
    // Fetch leases from Core Data
    @FetchRequest(
        entity: Lease.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Lease.startDate, ascending: false)
        ]
    ) private var allLeases: FetchedResults<Lease>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                leaseHeaderSection
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.large) {
                        quickActionsSection
                        
                        leaseFilterSection
                        
                        activeLeasesSection
                        
                        upcomingLeasesSection
                        
                        expiredLeasesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Lease Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Lease") {
                        showingLeaseCreation = true
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingLeaseCreation) {
                LeaseCreationView(isPresented: $showingLeaseCreation)
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Header section with overview statistics
    private var leaseHeaderSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                LeaseStatCard(
                    title: "Active",
                    value: "\(activeLeases.count)",
                    subtitle: "Leases",
                    color: AppTheme.Colors.success
                )
                
                LeaseStatCard(
                    title: "Expiring",
                    value: "\(expiringSoonLeases.count)",
                    subtitle: "This Month",
                    color: AppTheme.Colors.warning
                )
                
                LeaseStatCard(
                    title: "Total",
                    value: "\(allLeases.count)",
                    subtitle: "All Time",
                    color: AppTheme.Colors.primary
                )
            }
            
            Divider()
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    /// Quick actions section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Quick Actions")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                
                LeaseActionCard(
                    title: "New Lease",
                    description: "Create a new property lease agreement",
                    icon: "doc.badge.plus",
                    color: AppTheme.Colors.primary
                ) {
                    showingLeaseCreation = true
                }
                
                LeaseActionCard(
                    title: "Renewals",
                    description: "Manage lease renewals and extensions",
                    icon: "arrow.clockwise.circle.fill",
                    color: AppTheme.Colors.secondary
                ) {
                    // Navigate to renewals view
                }
                
                LeaseActionCard(
                    title: "Payments",
                    description: "Track lease payments and history",
                    icon: "dollarsign.circle.fill",
                    color: AppTheme.Colors.compliance
                ) {
                    // Navigate to payments view
                }
                
                LeaseActionCard(
                    title: "Reports",
                    description: "Generate lease and revenue reports",
                    icon: "chart.bar.doc.horizontal.fill",
                    color: AppTheme.Colors.warning
                ) {
                    // Navigate to reports view
                }
            }
        }
    }
    
    /// Lease filter section
    private var leaseFilterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Filter Leases")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(LeaseFilter.allCases, id: \.self) { filter in
                        LeaseFilterCard(
                            filter: filter,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Active leases section
    private var activeLeasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Active Leases")
                Spacer()
                if activeLeases.count > 3 {
                    NavigationLink("View All", destination: AllLeasesListView(leases: activeLeases))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if activeLeases.isEmpty {
                LeaseEmptyStateView(
                    icon: "doc.text",
                    title: "No Active Leases",
                    description: "Create a lease to get started",
                    actionTitle: "Create Lease"
                ) {
                    showingLeaseCreation = true
                }
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(activeLeases.prefix(3)), id: \.objectID) { lease in
                        LeaseRowView(lease: lease)
                    }
                }
            }
        }
    }
    
    /// Upcoming leases section
    private var upcomingLeasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Expiring Soon")
            
            if expiringSoonLeases.isEmpty {
                Text("No leases expiring in the next 30 days")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(expiringSoonLeases.prefix(3)), id: \.objectID) { lease in
                        LeaseRowView(lease: lease, showExpirationWarning: true)
                    }
                }
            }
        }
    }
    
    /// Expired leases section
    private var expiredLeasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Recently Expired")
                Spacer()
                if expiredLeases.count > 2 {
                    NavigationLink("View All", destination: AllLeasesListView(leases: expiredLeases))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if expiredLeases.isEmpty {
                Text("No recently expired leases")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(expiredLeases.prefix(2)), id: \.objectID) { lease in
                        LeaseRowView(lease: lease, isExpired: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var activeLeases: [Lease] {
        allLeases.filter { lease in
            lease.status?.lowercased() == "active"
        }
    }
    
    private var expiringSoonLeases: [Lease] {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return allLeases.filter { lease in
            guard let endDate = lease.endDate else { return false }
            return endDate > Date() && endDate <= thirtyDaysFromNow
        }
    }
    
    private var expiredLeases: [Lease] {
        allLeases.filter { lease in
            guard let endDate = lease.endDate else { return false }
            return endDate < Date()
        }
    }
}

// MARK: - Supporting Types

enum LeaseFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case expiring = "Expiring"
    case expired = "Expired"
    case cash = "Cash Rent"
    case share = "Share Rent"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.text"
        case .active: return "checkmark.circle.fill"
        case .expiring: return "clock.badge.exclamationmark"
        case .expired: return "xmark.circle.fill"
        case .cash: return "dollarsign.circle"
        case .share: return "percent"
        }
    }
}

// MARK: - Supporting Views

/// Statistics card for lease overview
struct LeaseStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.tiny) {
            Text(title)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(value)
                .font(AppTheme.Typography.displaySmall)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Action card for quick actions
struct LeaseActionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }
                
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .frame(height: 120)
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Filter card for lease categories
struct LeaseFilterCard: View {
    let filter: LeaseFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: filter.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.primary)
                
                Text(filter.displayName)
                    .font(AppTheme.Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Row view for leases
struct LeaseRowView: View {
    let lease: Lease
    var showExpirationWarning: Bool = false
    var isExpired: Bool = false
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(lease.leaseType?.capitalized ?? "Lease")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let property = lease.property {
                        Text(property.displayName ?? "Unknown Property")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if let startDate = lease.startDate, let endDate = lease.endDate {
                        Text("\(startDate, style: .date) - \(endDate, style: .date)")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    if showExpirationWarning {
                        MetadataTag(
                            text: "Expiring Soon",
                            backgroundColor: AppTheme.Colors.warning.opacity(0.2),
                            textColor: AppTheme.Colors.warning
                        )
                    } else if isExpired {
                        MetadataTag(
                            text: "Expired",
                            backgroundColor: AppTheme.Colors.error.opacity(0.2),
                            textColor: AppTheme.Colors.error
                        )
                    } else {
                        MetadataTag(
                            text: lease.status?.capitalized ?? "Unknown",
                            backgroundColor: AppTheme.Colors.success.opacity(0.2),
                            textColor: AppTheme.Colors.success
                        )
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .sheet(isPresented: $showingDetail) {
            LeaseDetailView(lease: lease)
        }
    }
}

/// Empty state view for leases
struct LeaseEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text(title)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(description)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(actionTitle, action: action)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Placeholder Views

/// Placeholder for lease creation
struct LeaseCreationView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Lease Creation")
                    .font(AppTheme.Typography.displayMedium)
                
                Text("Comprehensive lease creation interface will be implemented here")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Lease")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// Placeholder for lease detail view
struct LeaseDetailView: View {
    let lease: Lease
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Lease Details")
                    .font(AppTheme.Typography.displayMedium)
                
                Text("Detailed lease view for: \(lease.leaseType?.capitalized ?? "Unknown")")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Lease Details")
        }
    }
}

/// Placeholder for all leases list
struct AllLeasesListView: View {
    let leases: [Lease]
    
    var body: some View {
        List {
            ForEach(leases, id: \.objectID) { lease in
                LeaseRowView(lease: lease)
            }
        }
        .navigationTitle("All Leases")
    }
}