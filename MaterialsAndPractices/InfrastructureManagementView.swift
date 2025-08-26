//
//  InfrastructureManagementView.swift
//  MaterialsAndPractices
//
//  Provides comprehensive infrastructure management interface for farm equipment,
//  buildings, and systems. Supports infrastructure catalog integration,
//  maintenance tracking, and farm assignment.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Main infrastructure management view for utilities section
/// Provides access to infrastructure catalog and farm infrastructure management
struct InfrastructureManagementView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingInfrastructureCreation = false
    @State private var showingCatalogBrowser = false
    
    // Fetch existing infrastructure
    @FetchRequest(
        entity: Infrastructure.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Infrastructure.category, ascending: true),
            NSSortDescriptor(keyPath: \Infrastructure.name, ascending: true)
        ]
    ) private var existingInfrastructure: FetchedResults<Infrastructure>
    
    // Fetch farms for assignment
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var farmProperties: FetchedResults<Property>
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                infrastructureHeaderSection
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.large) {
                        // Quick actions section
                        quickActionsSection
                        
                        // Infrastructure by category
                        if !existingInfrastructure.isEmpty {
                            infrastructureByCategorySection
                        } else {
                            infrastructureEmptyState
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Manage Infrastructure")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingInfrastructureCreation) {
                InfrastructureCreationView(isPresented: $showingInfrastructureCreation)
            }
            .sheet(isPresented: $showingCatalogBrowser) {
                InfrastructureCatalogBrowserView(isPresented: $showingCatalogBrowser)
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Header section with summary information
    private var infrastructureHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Infrastructure Overview")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("\(existingInfrastructure.count) items across \(infrastructureCategories.count) categories")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    if maintenanceDueCount > 0 {
                        Text("\(maintenanceDueCount)")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.warning)
                        
                        Text("maintenance due")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    AppTheme.Colors.primary.opacity(0.1),
                    AppTheme.Colors.secondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    /// Quick actions section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Quick Actions")
            
            HStack(spacing: AppTheme.Spacing.medium) {
                QuickActionButton(
                    title: "Browse Catalog",
                    subtitle: "Common farm equipment",
                    icon: "books.vertical.fill",
                    color: AppTheme.Colors.primary
                ) {
                    showingCatalogBrowser = true
                }
                
                QuickActionButton(
                    title: "Add Custom",
                    subtitle: "Create new infrastructure",
                    icon: "plus.circle.fill",
                    color: AppTheme.Colors.secondary
                ) {
                    showingInfrastructureCreation = true
                }
            }
        }
    }
    
    /// Infrastructure organized by category
    private var infrastructureByCategorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            ForEach(infrastructureCategories, id: \.self) { category in
                infrastructureCategorySection(category: category)
            }
        }
    }
    
    /// Individual category section
    private func infrastructureCategorySection(category: String) -> some View {
        let categoryItems = existingInfrastructure.filter { $0.category == category }
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(category)
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Text("\(categoryItems.count) items")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.medium) {
                ForEach(categoryItems, id: \.id) { infrastructure in
                    InfrastructureTile(infrastructure: infrastructure)
                }
            }
        }
    }
    
    /// Empty state when no infrastructure exists
    private var infrastructureEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text("No Infrastructure Registered")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Start by browsing the catalog or adding custom infrastructure items")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: AppTheme.Spacing.medium) {
                CommonActionButton(
                    title: "Browse Catalog",
                    style: .primary
                ) {
                    showingCatalogBrowser = true
                }
                
                CommonActionButton(
                    title: "Add Custom",
                    style: .secondary
                ) {
                    showingInfrastructureCreation = true
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.extraLarge)
    }
    
    // MARK: - Computed Properties
    
    /// Grid columns for infrastructure tiles
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
        ]
    }
    
    /// Unique categories from existing infrastructure
    private var infrastructureCategories: [String] {
        let categories = Set(existingInfrastructure.compactMap { $0.category })
        return Array(categories).sorted()
    }
    
    /// Count of infrastructure items with maintenance due
    private var maintenanceDueCount: Int {
        // Simplified calculation - in real implementation, would check maintenance schedules
        return existingInfrastructure.filter { infrastructure in
            guard let lastService = infrastructure.lastServiceDate else { return true }
            let daysSinceService = Calendar.current.dateComponents([.day], from: lastService, to: Date()).day ?? 0
            return daysSinceService > 90 // 3 months
        }.count
    }
}

// MARK: - Infrastructure Tile Component

/// Individual infrastructure item tile display
struct InfrastructureTile: View {
    let infrastructure: Infrastructure
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with icon and status
                HStack {
                    Image(systemName: iconForInfrastructure)
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title2)
                    
                    Spacer()
                    
                    statusIndicator
                }
                
                // Infrastructure information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(infrastructure.name ?? "Unnamed Infrastructure")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    if let type = infrastructure.type {
                        Text(type.capitalized)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Maintenance status
                maintenanceStatusRow
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            InfrastructureDetailView(infrastructure: infrastructure, isPresented: $showingDetail)
        }
    }
    
    /// Status indicator based on infrastructure condition
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
    }
    
    /// Maintenance status row
    private var maintenanceStatusRow: some View {
        HStack {
            Image(systemName: "wrench.fill")
                .font(.caption)
                .foregroundColor(maintenanceColor)
            
            Text(maintenanceStatusText)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(maintenanceColor)
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Icon selection based on infrastructure type
    private var iconForInfrastructure: String {
        guard let type = infrastructure.type?.lowercased() else { return "building.2" }
        
        switch type {
        case "tractor": return "car.fill"
        case "truck": return "truck.box.fill"
        case "barn": return "building.2.fill"
        case "greenhouse": return "leaf.fill"
        case "pump": return "drop.fill"
        case "tools": return "hammer.fill"
        default: return "building.2"
        }
    }
    
    /// Status color based on infrastructure condition
    private var statusColor: Color {
        guard let status = infrastructure.status?.lowercased() else { return Color.gray }
        
        switch status {
        case "excellent", "good": return AppTheme.Colors.success
        case "fair": return AppTheme.Colors.warning
        case "poor", "needs repair": return AppTheme.Colors.error
        default: return Color.gray
        }
    }
    
    /// Maintenance status text
    private var maintenanceStatusText: String {
        guard let lastService = infrastructure.lastServiceDate else { return "No service record" }
        
        let daysSinceService = Calendar.current.dateComponents([.day], from: lastService, to: Date()).day ?? 0
        
        if daysSinceService > 90 {
            return "Maintenance due"
        } else if daysSinceService > 60 {
            return "Service soon"
        } else {
            return "Up to date"
        }
    }
    
    /// Maintenance status color
    private var maintenanceColor: Color {
        guard let lastService = infrastructure.lastServiceDate else { return AppTheme.Colors.warning }
        
        let daysSinceService = Calendar.current.dateComponents([.day], from: lastService, to: Date()).day ?? 0
        
        if daysSinceService > 90 {
            return AppTheme.Colors.error
        } else if daysSinceService > 60 {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.success
        }
    }
}

// MARK: - Quick Action Button Component

/// Quick action button for infrastructure management
struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(title)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 100)
            .background(color.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct InfrastructureManagementView_Previews: PreviewProvider {
    static var previews: some View {
        InfrastructureManagementView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}