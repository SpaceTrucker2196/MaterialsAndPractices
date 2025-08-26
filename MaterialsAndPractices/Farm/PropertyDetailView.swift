//
//  PropertyDetailView.swift
//  MaterialsAndPractices
//
//  Displays detailed property information with photo management
//  and advanced/basic mode support.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Displays property details with photo management and mode-specific content
struct PropertyDetailView: View {
    // MARK: - Properties
    
    let property: Property
    let isAdvancedMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingPhotoCapture = false
    @State private var showingEditView = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // MARK: - Property Information Section
                propertyInformationSection
                
                // MARK: - Photo Management Section
                photoManagementSection
                
                // MARK: - Advanced Sections (only in advanced mode)
                if isAdvancedMode {
                    fieldsSection
                    infrastructureSection
                    leasesSection
                }
            }
            .padding()
        }
        .navigationTitle(property.displayName ?? "Property Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditPropertyView(property: property, isPresented: $showingEditView)
        }
    }
    
    // MARK: - Section Components
    
    /// Section displaying comprehensive property information
    private var propertyInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Property Information")
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                CommonInfoRow(label: "Display Name:") {
                    Text(property.displayName ?? "N/A")
                }

                CommonInfoRow(label: "Total Acres:") {
                    Text("\(property.totalAcres, specifier: "%.1f")")
                }

                if isAdvancedMode {
                    CommonInfoRow(label: "Tillable Acres:") {
                        Text("\(property.tillableAcres, specifier: "%.1f")")
                    }
                    CommonInfoRow(label: "Pasture Acres:") {
                        Text("\(property.pastureAcres, specifier: "%.1f")")
                    }
                    CommonInfoRow(label: "Woodland Acres:") {
                        Text("\(property.woodlandAcres, specifier: "%.1f")")
                    }
                    CommonInfoRow(label: "Wetland Acres:") {
                        Text("\(property.wetlandAcres, specifier: "%.1f")")
                    }
                    CommonInfoRow(label: "Has Irrigation:") {
                        Text(property.hasIrrigation ? "Yes" : "No")
                    }
                }

                if let county = property.county, let state = property.state {
                    CommonInfoRow(label: "Location:") {
                        Text("\(county), \(state)")
                    }
                }

                if let notes = property.notes, !notes.isEmpty {
                    CommonInfoRow(label: "Notes:") {
                        Text(notes)
                    }
                }
            }
        }
    }
    
    /// Section for photo management with tile interface
    private var photoManagementSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Photos")
                
                Spacer()
                
                Button(action: {
                    showingPhotoCapture = true
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            PhotoGalleryView(property: property)
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureView(property: property, isPresented: $showingPhotoCapture)
        }
    }
    
    /// Section displaying fields (advanced mode only)
    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Fields")
                
                Spacer()
                
                NavigationLink(destination: CreateFieldView(property: property)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let fields = property.fields?.allObjects as? [Field], !fields.isEmpty {
                ForEach(fields.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.id) { field in
                    FieldRow(field: field)
                }
            } else {
                EmptyStateView(
                    title: "No Fields",
                    message: "Add fields to track cultivation areas",
                    systemImage: "grid",
                    actionTitle: "Add Field"
                ) {
                    // This will be handled by the NavigationLink above
                }
                .frame(height: 120)
            }
        }
    }
    
    /// Section displaying infrastructure (advanced mode only)
    private var infrastructureSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Infrastructure")
                
                Spacer()
                
                NavigationLink(destination: CreateInfrastructureView(property: property)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let infrastructure = property.infrastructure?.allObjects as? [Infrastructure], !infrastructure.isEmpty {
                ForEach(infrastructure.sorted(by: { ($0.type ?? "") < ($1.type ?? "") }), id: \.id) { item in
                    InfrastructureRow(infrastructure: item)
                }
            } else {
                EmptyStateView(
                    title: "No Infrastructure",
                    message: "Add infrastructure to track farm assets",
                    systemImage: "building.2",
                    actionTitle: "Add Infrastructure"
                ) {
                    // This will be handled by the NavigationLink above
                }
                .frame(height: 120)
            }
        }
    }
    
    /// Section displaying leases (advanced mode only)
    private var leasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Leases")
            
            if let leases = property.leases?.allObjects as? [Lease], !leases.isEmpty {
                ForEach(leases.sorted(by: { ($0.startDate ?? Date.distantPast) > ($1.startDate ?? Date.distantPast) }), id: \.id) { lease in
                    LeaseRow(lease: lease)
                }
            } else {
                Text("No active leases")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

/// Helper view for field information rows
//struct FieldRow: View {
//    let field: Field
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
//                Text(field.name ?? "Unknown Field")
//                    .font(AppTheme.Typography.bodyMedium)
//                    .foregroundColor(AppTheme.Colors.textPrimary)
//                
//                Text("\(field.acres, specifier: "%.1f") acres")
//                    .font(AppTheme.Typography.bodySmall)
//                    .foregroundColor(AppTheme.Colors.textSecondary)
//            }
//            
//            Spacer()
//            
//            if field.hasDrainTile {
//                Image(systemName: "drop.triangle.fill")
//                    .foregroundColor(AppTheme.Colors.info)
//                    .font(AppTheme.Typography.labelMedium)
//            }
//        }
//        .padding(.vertical, AppTheme.Spacing.extraSmall)
//    }
//}
//
/// Helper view for infrastructure information rows
struct InfrastructureRow: View {
    let infrastructure: Infrastructure
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack {
                // Infrastructure icon
                Text(iconForInfrastructure)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(infrastructure.name ?? "Unnamed Infrastructure")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        Text(infrastructure.type?.capitalized ?? "Unknown Type")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text(infrastructure.status?.capitalized ?? "Unknown Status")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.caption)
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            InfrastructureDetailView(infrastructure: infrastructure)
        }
    }
    
    /// Icon selection based on infrastructure type
    private var iconForInfrastructure: String {
        guard let type = infrastructure.type?.lowercased() else { return "🏗️" }
        
        switch type {
        case "tractor": return "🚜"
        case "truck": return "🚛"
        case "barn": return "🏠"
        case "greenhouse": return "🪴"
        case "pump": return "💧"
        case "tools": return "🔧"
        case "silo": return "🏗️"
        case "fence": return "🚧"
        case "irrigation": return "💦"
        case "storage": return "📦"
        default: return "🏗️"
        }
    }
    
    private var statusColor: Color {
        switch infrastructure.status?.lowercased() {
        case "excellent", "good":
            return AppTheme.Colors.success
        case "fair":
            return AppTheme.Colors.warning
        case "poor", "needs repair":
            return AppTheme.Colors.error
        default:
            return AppTheme.Colors.textSecondary
        }
    }
}

/// Helper view for lease information rows
struct LeaseRow: View {
    let lease: Lease
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(lease.leaseType?.capitalized ?? "Unknown Type")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let startDate = lease.startDate {
                    Text("Started: \(startDate, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Text(lease.status?.capitalized ?? "Unknown Status")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(leaseStatusColor(for: lease.status))
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.extraSmall)
    }
    
    private func leaseStatusColor(for status: String?) -> Color {
        switch status?.lowercased() {
        case "active":
            return AppTheme.Colors.success
        case "expired":
            return AppTheme.Colors.error
        case "pending":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - Preview Provider

struct PropertyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PropertyDetailView(property: Property(), isAdvancedMode: true)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
