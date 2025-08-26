//
//  InspectionCatalogBrowserView.swift
//  MaterialsAndPractices
//
//  Provides inspection catalog browsing interface with organic compliance templates.
//  Allows selection and copying of catalog items to create new working inspection
//  templates for farm assignment, following the infrastructure catalog pattern.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Inspection catalog browser for selecting and creating inspections from templates
/// Provides comprehensive browsing of predefined inspection types with detailed information
struct InspectionCatalogBrowserView: View {
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // State management
    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var selectedTemplate: InspectionTemplateDisplayData?
    @State private var showingTemplateDetail = false
    @State private var showingWorkingTemplateCreation = false
    @State private var templateData: [InspectionTemplateDisplayData] = []
    
    private let directoryManager = InspectionDirectoryManager.shared
    private let templateSeeder = InspectionTemplateSeeder()
    
    // Available categories
    private let categories = ["All"] + InspectionCategory.allCases.map { $0.displayName }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
                // Category filter
                categoryFilterSection
                
                // Templates list
                templatesListSection
            }
            .navigationTitle("Inspection Catalog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Seed Templates") {
                        seedTemplates()
                    }
                    .disabled(!templateData.isEmpty)
                }
            }
            .sheet(isPresented: $showingTemplateDetail) {
                if let template = selectedTemplate {
                    InspectionTemplateDetailView(
                        template: template,
                        isPresented: $showingTemplateDetail,
                        onCreateWorkingTemplate: { templateName in
                            createWorkingTemplate(from: template, name: templateName)
                        }
                    )
                }
            }
            .sheet(isPresented: $showingWorkingTemplateCreation) {
                if let template = selectedTemplate {
                    CreateWorkingTemplateView(
                        template: template,
                        isPresented: $showingWorkingTemplateCreation
                    ) { workingTemplateName in
                        createWorkingTemplate(from: template, name: workingTemplateName)
                    }
                }
            }
            .onAppear {
                loadTemplateData()
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Search and filter section
    private var searchAndFilterSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                TextField("Search inspections...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding()
    }
    
    /// Category filter section
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(categories, id: \.self) { category in
                    CategoryFilterChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    /// Templates list section
    private var templatesListSection: some View {
        Group {
            if filteredTemplates.isEmpty {
                EmptyTemplateStateView(
                    hasTemplates: !templateData.isEmpty,
                    searchText: searchText,
                    onSeedTemplates: {
                        seedTemplates()
                    }
                )
            } else {
                List(filteredTemplates, id: \.id) { template in
                    InspectionTemplateRowView(template: template) {
                        selectedTemplate = template
                        showingTemplateDetail = true
                    } onCreateWorkingTemplate: {
                        selectedTemplate = template
                        showingWorkingTemplateCreation = true
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Filtered templates based on search and category
    private var filteredTemplates: [InspectionTemplateDisplayData] {
        var filtered = templateData
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    // MARK: - Helper Methods
    
    /// Load template data from directory
    private func loadTemplateData() {
        let templateFiles = directoryManager.listFiles(in: .templates)
        
        templateData = templateFiles.compactMap { fileName in
            guard let content = try? directoryManager.readTemplate(fileName: fileName, from: .templates) else {
                return nil
            }
            
            return parseTemplateContent(fileName: fileName, content: content)
        }
    }
    
    /// Parse template content to extract metadata
    private func parseTemplateContent(fileName: String, content: String) -> InspectionTemplateDisplayData {
        let lines = content.components(separatedBy: .newlines)
        
        // Extract title (first # line)
        let title = lines.first { $0.hasPrefix("# ") }?.replacingOccurrences(of: "# ", with: "") ?? fileName
        
        // Extract category
        let categoryLine = lines.first { $0.contains("**Category:**") }
        let category = categoryLine?.components(separatedBy: "**Category:**").last?.trimmingCharacters(in: .whitespaces) ?? "General"
        
        // Extract inspection type
        let typeLine = lines.first { $0.contains("**Inspection Type:**") }
        let inspectionType = typeLine?.components(separatedBy: "**Inspection Type:**").last?.trimmingCharacters(in: .whitespaces) ?? title
        
        // Count checklist items
        let checklistItems = lines.filter { $0.contains("- [ ]") }.count
        
        // Extract requirement level
        let requirementLine = lines.first { $0.contains("**Requirement Level:**") }
        let requirementLevel = requirementLine?.components(separatedBy: "**Requirement Level:**").last?.trimmingCharacters(in: .whitespaces) ?? "Standard"
        
        // Generate description
        let description = "Comprehensive \(inspectionType.lowercased()) with \(checklistItems) checklist items for organic certification compliance."
        
        return InspectionTemplateDisplayData(
            id: UUID(),
            fileName: fileName,
            name: title,
            category: category,
            inspectionType: inspectionType,
            description: description,
            checklistItemCount: checklistItems,
            requirementLevel: requirementLevel,
            lastModified: Date(),
            content: content
        )
    }
    
    /// Seed templates from the seeder
    private func seedTemplates() {
        templateSeeder.seedTemplatesIfNeeded()
        loadTemplateData()
    }
    
    /// Create working template from catalog template
    private func createWorkingTemplate(from template: InspectionTemplateDisplayData, name: String) {
        do {
            let _ = try directoryManager.copyTemplateToWorking(
                templateName: template.fileName,
                newName: name
            )
            
            showingTemplateDetail = false
            showingWorkingTemplateCreation = false
            isPresented = false
            
            // Show success message
            print("✅ Created working template: \(name)")
        } catch {
            print("❌ Error creating working template: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Category filter chip
struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Template row view
struct InspectionTemplateRowView: View {
    let template: InspectionTemplateDisplayData
    let onTap: () -> Void
    let onCreateWorkingTemplate: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Template icon
            VStack {
                Image(systemName: categoryIcon(for: template.category))
                    .font(.title2)
                    .foregroundColor(categoryColor(for: template.category))
                    .frame(width: 40, height: 40)
                    .background(categoryColor(for: template.category).opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
            
            // Template info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(template.name)
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Text(template.description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Label("\(template.checklistItemCount) items", systemImage: "list.bullet")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    Text(template.category)
                        .font(AppTheme.Typography.labelTiny)
                        .foregroundColor(categoryColor(for: template.category))
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, 2)
                        .background(categoryColor(for: template.category).opacity(0.1))
                        .cornerRadius(AppTheme.CornerRadius.tiny)
                }
            }
            
            // Actions
            VStack(spacing: AppTheme.Spacing.tiny) {
                Button("View") {
                    onTap()
                }
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.primary)
                
                Button("Use") {
                    onCreateWorkingTemplate()
                }
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Grow": return "leaf.fill"
        case "Infrastructure": return "building.2.fill"
        case "Health and Safety": return "cross.case.fill"
        case "Equipment": return "wrench.and.screwdriver.fill"
        case "Organic Management": return "checkmark.seal.fill"
        default: return "doc.text.fill"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Grow": return AppTheme.Colors.success
        case "Infrastructure": return AppTheme.Colors.primary
        case "Health and Safety": return AppTheme.Colors.error
        case "Equipment": return AppTheme.Colors.warning
        case "Organic Management": return AppTheme.Colors.compliance
        default: return AppTheme.Colors.textSecondary
        }
    }
}

/// Empty state view for templates
struct EmptyTemplateStateView: View {
    let hasTemplates: Bool
    let searchText: String
    let onSeedTemplates: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: hasTemplates ? "magnifyingglass" : "doc.text.below.ecg")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text(hasTemplates ? "No Templates Found" : "No Templates Available")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(hasTemplates ? 
                     "Try adjusting your search or category filter" : 
                     "Seed the inspection catalog to get started with organic compliance templates")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasTemplates {
                Button("Seed Templates") {
                    onSeedTemplates()
                }
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(.white)
                .padding()
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .padding(AppTheme.Spacing.extraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Template Detail View

/// Detailed view of an inspection template
struct InspectionTemplateDetailView: View {
    let template: InspectionTemplateDisplayData
    @Binding var isPresented: Bool
    let onCreateWorkingTemplate: (String) -> Void
    
    @State private var showingCreateWorkingTemplate = false
    @State private var workingTemplateName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Header
                    templateHeaderSection
                    
                    // Metadata
                    templateMetadataSection
                    
                    // Content preview
                    templateContentSection
                }
                .padding()
            }
            .navigationTitle("Template Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Template") {
                        showingCreateWorkingTemplate = true
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .alert("Create Working Template", isPresented: $showingCreateWorkingTemplate) {
                TextField("Template Name", text: $workingTemplateName)
                Button("Create") {
                    onCreateWorkingTemplate(workingTemplateName)
                }
                .disabled(workingTemplateName.isEmpty)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name for your working template")
            }
        }
    }
    
    private var templateHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(template.name)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(template.description)
                .font(AppTheme.Typography.bodyLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    private var templateMetadataSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Template Information")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                TemplateMetadataRow(label: "Category", value: template.category)
                TemplateMetadataRow(label: "Type", value: template.inspectionType)
                TemplateMetadataRow(label: "Checklist Items", value: "\(template.checklistItemCount)")
                TemplateMetadataRow(label: "Requirement Level", value: template.requirementLevel)
                TemplateMetadataRow(label: "Last Modified", value: DateFormatter.mediumDate.string(from: template.lastModified))
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var templateContentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Template Preview")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            ScrollView {
                Text(template.content)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 300)
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
}

/// Metadata row for template details
struct TemplateMetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
        }
    }
}

/// Create working template view
struct CreateWorkingTemplateView: View {
    let template: InspectionTemplateDisplayData
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void
    
    @State private var workingTemplateName = ""
    @State private var selectedCategory = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Create Working Template")
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Create a working copy of '\(template.name)' that you can customize for your specific needs.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Template Name")
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    TextField("Enter template name", text: $workingTemplateName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Working Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate(workingTemplateName)
                    }
                    .disabled(workingTemplateName.isEmpty)
                }
            }
        }
        .onAppear {
            workingTemplateName = "\(template.name) - Working Copy"
        }
    }
}

// MARK: - Supporting Types

/// Display data for inspection templates
struct InspectionTemplateDisplayData {
    let id: UUID
    let fileName: String
    let name: String
    let category: String
    let inspectionType: String
    let description: String
    let checklistItemCount: Int
    let requirementLevel: String
    let lastModified: Date
    let content: String
}