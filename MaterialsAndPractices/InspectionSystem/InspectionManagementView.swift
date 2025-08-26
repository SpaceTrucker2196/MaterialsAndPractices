//
//  InspectionManagementView.swift
//  MaterialsAndPractices
//
//  Main inspection management interface providing access to inspection templates,
//  working inspections, and completed inspections. Follows the established UI
//  patterns and provides comprehensive inspection workflow management.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Main inspection management view for the utilities section
/// Provides comprehensive inspection workflow management and template access
struct InspectionManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingTemplateBrowser = false
    @State private var showingInspectionCreation = false
    @State private var selectedCategory: InspectionCategory = .grow
    
    // Fetch completed inspections for dashboard
    @FetchRequest(
        entity: CompletedInspection.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CompletedInspection.completedAt, ascending: false)
        ],
        predicate: NSPredicate(format: "completedAt >= %@", Calendar.current.startOfDay(for: Date()) as CVarArg)
    ) private var recentInspections: FetchedResults<CompletedInspection>
    
    // Initialize inspection directory and seeder
    private let directoryManager = InspectionDirectoryManager.shared
    private let templateSeeder = InspectionTemplateSeeder()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                inspectionHeaderSection
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.large) {
                        quickActionsSection
                        
                        inspectionCatalogSection
                        
                        workingInspectionsSection
                        
                        recentCompletedInspectionsSection
                        
                        upcomingInspectionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Inspection Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Inspection") {
                        showingInspectionCreation = true
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingTemplateBrowser) {
                InspectionCatalogBrowserView(isPresented: $showingTemplateBrowser)
            }
            .sheet(isPresented: $showingInspectionCreation) {
                InspectionCreationWorkflowView(isPresented: $showingInspectionCreation)
            }
            .onAppear {
                setupInspectionSystem()
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Header section with overview statistics
    private var inspectionHeaderSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                InspectionStatCard(
                    title: "Today",
                    value: "\(recentInspections.count)",
                    subtitle: "Completed",
                    color: AppTheme.Colors.success
                )
                
                InspectionStatCard(
                    title: "Working",
                    value: "\(getWorkingInspectionsCount())",
                    subtitle: "In Progress",
                    color: AppTheme.Colors.warning
                )
                
                InspectionStatCard(
                    title: "Due Soon",
                    value: "\(getUpcomingInspectionsCount())",
                    subtitle: "This Week",
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
                
                InspectionActionCard(
                    title: "Browse Templates",
                    description: "View inspection catalog and create working templates",
                    icon: "doc.text.magnifyingglass",
                    color: AppTheme.Colors.primary
                ) {
                    showingTemplateBrowser = true
                }
                
                InspectionActionCard(
                    title: "New Inspection",
                    description: "Create inspection from working template",
                    icon: "plus.circle.fill",
                    color: AppTheme.Colors.secondary
                ) {
                    showingInspectionCreation = true
                }
                
                InspectionActionCard(
                    title: "Audit Trail",
                    description: "View inspection history and compliance",
                    icon: "list.clipboard.fill",
                    color: AppTheme.Colors.compliance
                ) {
                    // Navigate to audit trail view
                }
                
                InspectionActionCard(
                    title: "Reports",
                    description: "Generate compliance and performance reports",
                    icon: "chart.bar.doc.horizontal.fill",
                    color: AppTheme.Colors.warning
                ) {
                    // Navigate to reports view
                }
            }
        }
    }
    
    /// Inspection catalog section
    private var inspectionCatalogSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Inspection Catalog")
                Spacer()
                Button("View All") {
                    showingTemplateBrowser = true
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(InspectionCategory.allCases, id: \.self) { category in
                        InspectionCategoryCard(
                            category: category,
                            templateCount: getTemplateCount(for: category),
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Working inspections section
    private var workingInspectionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Working Inspections")
                Spacer()
                if getWorkingInspectionsCount() > 3 {
                    NavigationLink("View All", destination: WorkingInspectionsListView())
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if getWorkingInspectionsCount() == 0 {
                EmptyStateView(
                    icon: "clipboard",
                    title: "No Working Inspections",
                    description: "Create an inspection to get started",
                    actionTitle: "Create Inspection"
                ) {
                    showingInspectionCreation = true
                }
            } else {
                // Show preview of working inspections
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(0..<min(getWorkingInspectionsCount(), 3), id: \.self) { index in
                        WorkingInspectionRowView(
                            inspection: getWorkingInspectionAtIndex(index)
                        )
                    }
                }
            }
        }
    }
    
    /// Recent completed inspections section
    private var recentCompletedInspectionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Recent Inspections")
                Spacer()
                if recentInspections.count > 3 {
                    NavigationLink("View All", destination: CompletedInspectionsListView())
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if recentInspections.isEmpty {
                Text("No inspections completed today")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(recentInspections.prefix(3)), id: \.objectID) { inspection in
                        CompletedInspectionRowView(inspection: inspection)
                    }
                }
            }
        }
    }
    
    /// Upcoming inspections section
    private var upcomingInspectionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Upcoming Inspections")
            
            if getUpcomingInspectionsCount() == 0 {
                Text("No inspections scheduled for this week")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            } else {
                // This would show upcoming inspections based on schedules
                Text("Upcoming inspections feature coming soon")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Sets up the inspection system on view appearance
    private func setupInspectionSystem() {
        templateSeeder.seedTemplatesIfNeeded()
    }
    
    /// Gets the count of working inspections
    private func getWorkingInspectionsCount() -> Int {
        return directoryManager.listFiles(in: .working).count
    }
    
    /// Gets the count of upcoming inspections
    private func getUpcomingInspectionsCount() -> Int {
        // This would calculate based on inspection schedules
        return 0
    }
    
    /// Gets template count for a category
    private func getTemplateCount(for category: InspectionCategory) -> Int {
        let allTemplates = directoryManager.listFiles(in: .templates)
        // This would filter by category when we implement category mapping
        return allTemplates.count / InspectionCategory.allCases.count
    }
    
    /// Gets working inspection at index (placeholder)
    private func getWorkingInspectionAtIndex(_ index: Int) -> WorkingInspectionDisplayData {
        return WorkingInspectionDisplayData(
            id: UUID(),
            name: "Sample Working Inspection \(index + 1)",
            category: .grow,
            progress: 0.6,
            dueDate: Date().addingTimeInterval(86400 * Double(index + 1))
        )
    }
}

// MARK: - Supporting Views

/// Statistics card for inspection overview
struct InspectionStatCard: View {
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
                .font(AppTheme.Typography.labelTiny)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Action card for quick actions
struct InspectionActionCard: View {
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

/// Category card for inspection categories
struct InspectionCategoryCard: View {
    let category: InspectionCategory
    let templateCount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.primary)
                
                Text(category.displayName)
                    .font(AppTheme.Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                
                Text("\(templateCount) templates")
                    .font(AppTheme.Typography.labelTiny)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.Colors.textSecondary)
            }
            .padding()
            .frame(width: 120, height: 100)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Row view for working inspections
struct WorkingInspectionRowView: View {
    let inspection: WorkingInspectionDisplayData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(inspection.name)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(inspection.category.displayName)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                ProgressView(value: inspection.progress)
                    .frame(width: 60)
                
                Text("Due \(DateFormatter.shortDate.string(from: inspection.dueDate))")
                    .font(AppTheme.Typography.labelTiny)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Row view for completed inspections
struct CompletedInspectionRowView: View {
    let inspection: CompletedInspection
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.Colors.success)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(inspection.inspectionName ?? "Unknown Inspection")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(inspection.inspectorNames ?? "Unknown Inspector")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                Text(DateFormatter.shortTime.string(from: inspection.completedAt ?? Date()))
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(inspection.inspectionCategory ?? "General")
                    .font(AppTheme.Typography.labelTiny)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Empty state view
struct EmptyStateView: View {
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

// MARK: - Supporting Types

/// Display data for working inspections
struct WorkingInspectionDisplayData {
    let id: UUID
    let name: String
    let category: InspectionCategory
    let progress: Double
    let dueDate: Date
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Placeholder Views

/// Placeholder for inspection catalog browser
struct InspectionCatalogBrowserView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Inspection Catalog Browser\n(Implementation in progress)")
                .multilineTextAlignment(.center)
                .navigationTitle("Inspection Catalog")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

/// Placeholder for inspection creation workflow
struct InspectionCreationWorkflowView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Inspection Creation Workflow\n(Implementation in progress)")
                .multilineTextAlignment(.center)
                .navigationTitle("New Inspection")
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

/// Placeholder for working inspections list
struct WorkingInspectionsListView: View {
    var body: some View {
        Text("Working Inspections List\n(Implementation in progress)")
            .multilineTextAlignment(.center)
            .navigationTitle("Working Inspections")
    }
}

/// Placeholder for completed inspections list
struct CompletedInspectionsListView: View {
    var body: some View {
        Text("Completed Inspections List\n(Implementation in progress)")
            .multilineTextAlignment(.center)
            .navigationTitle("Completed Inspections")
    }
}