//
//  InspectionCreationWorkflowView.swift
//  MaterialsAndPractices
//
//  Comprehensive inspection creation workflow following the appointment scheduling
//  pattern. Provides step-by-step guidance for creating inspections with proper
//  entity association and scheduling.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Inspection creation workflow similar to appointment scheduling
/// Provides comprehensive step-by-step inspection creation process
struct InspectionCreationWorkflowView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // State management
    @State private var currentStep: CreationStep = .selectTemplate
    @State private var selectedWorkingTemplate: WorkingTemplateData?
    @State private var inspectionName = ""
    @State private var selectedTime: InspectionTime = .morning
    @State private var selectedFrequency: InspectionFrequency = .oneTime
    @State private var selectedCategory: InspectionCategory = .grow
    @State private var selectedEntity: EntitySelectionData?
    @State private var selectedInspectors: [InspectorData] = []
    @State private var selectedTeam: WorkTeamData?
    @State private var notes = ""
    
    // Data sources
    @State private var workingTemplates: [WorkingTemplateData] = []
    @State private var availableInspectors: [InspectorData] = []
    @State private var availableTeams: [WorkTeamData] = []
    @State private var availableEntities: [EntitySelectionData] = []
    
    private let directoryManager = InspectionDirectoryManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Current step content
                currentStepView
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("New Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                loadWorkflowData()
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ForEach(CreationStep.allCases, id: \.self) { step in
                Circle()
                    .fill(stepColor(for: step))
                    .frame(width: 12, height: 12)
                
                if step != CreationStep.allCases.last {
                    Rectangle()
                        .fill(stepColor(for: step))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    // MARK: - Current Step View
    
    @ViewBuilder
    private var currentStepView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                switch currentStep {
                case .selectTemplate:
                    selectTemplateStep
                case .configureInspection:
                    configureInspectionStep
                case .selectTime:
                    selectTimeStep
                case .selectCategory:
                    selectCategoryStep
                case .selectEntity:
                    selectEntityStep
                case .selectInspectors:
                    selectInspectorsStep
                case .review:
                    reviewStep
                }
            }
            .padding()
        }
    }
    
    // MARK: - Step Views
    
    private var selectTemplateStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            StepHeader(
                title: "Select Working Template",
                description: "Choose from your working inspection templates"
            )
            
            if workingTemplates.isEmpty {
                EmptyWorkingTemplatesView {
                    // Navigate to template creation
                }
            } else {
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(workingTemplates, id: \.id) { template in
                        WorkingTemplateSelectionCard(
                            template: template,
                            isSelected: selectedWorkingTemplate?.id == template.id
                        ) {
                            selectedWorkingTemplate = template
                            inspectionName = generateInspectionName(from: template)
                        }
                    }
                }
            }
        }
    }
    
    private var configureInspectionStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            StepHeader(
                title: "Configure Inspection",
                description: "Set the name and notes for this inspection"
            )
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Inspection Name")
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                TextField("Enter inspection name", text: $inspectionName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Notes (Optional)")
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var selectTimeStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            StepHeader(
                title: "Schedule Time",
                description: "Pick morning, evening, or night for the inspection"
            )
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                ForEach(InspectionTime.allCases, id: \.self) { time in
                    TimeSelectionCard(
                        time: time,
                        isSelected: selectedTime == time
                    ) {
                        selectedTime = time
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Recurrence Frequency")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Select how often this inspection should be performed")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.small) {
                    ForEach(InspectionFrequency.allCases, id: \.self) { frequency in
                        FrequencySelectionChip(
                            frequency: frequency,
                            isSelected: selectedFrequency == frequency
                        ) {
                            selectedFrequency = frequency
                        }
                    }
                }
            }
        }
    }
    
    private var selectCategoryStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            StepHeader(
                title: "Inspection Category",
                description: "Choose the type of inspection you're performing"
            )
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                ForEach(InspectionCategory.allCases, id: \.self) { category in
                    CategorySelectionCard(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        loadEntitiesForCategory(category)
                    }
                }
            }
        }
    }
    
    private var selectEntityStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            StepHeader(
                title: "Select \(selectedCategory.displayName)",
                description: "Choose the specific \(selectedCategory.displayName.lowercased()) to inspect"
            )
            
            if availableEntities.isEmpty {
                EmptyEntityStateView(category: selectedCategory) {
                    // Navigate to entity creation
                }
            } else {
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(availableEntities, id: \.id) { entity in
                        EntitySelectionCard(
                            entity: entity,
                            isSelected: selectedEntity?.id == entity.id
                        ) {
                            selectedEntity = entity
                        }
                    }
                }
            }
        }
    }
    
    private var selectInspectorsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            StepHeader(
                title: "Select Inspectors",
                description: "Choose who will perform this inspection"
            )
            
            if availableInspectors.isEmpty {
                Text("No qualified inspectors available")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Individual Inspectors")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(availableInspectors, id: \.id) { inspector in
                            InspectorSelectionRow(
                                inspector: inspector,
                                isSelected: selectedInspectors.contains { $0.id == inspector.id }
                            ) {
                                toggleInspectorSelection(inspector)
                            }
                        }
                    }
                    
                    if !availableTeams.isEmpty {
                        Divider()
                        
                        Text("Teams")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        LazyVStack(spacing: AppTheme.Spacing.small) {
                            ForEach(availableTeams, id: \.id) { team in
                                TeamSelectionRow(
                                    team: team,
                                    isSelected: selectedTeam?.id == team.id
                                ) {
                                    selectedTeam = team
                                    selectedInspectors = team.qualifiedMembers
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            StepHeader(
                title: "Review Inspection",
                description: "Review your inspection details before creating"
            )
            
            VStack(spacing: AppTheme.Spacing.medium) {
                ReviewSection(title: "Template") {
                    Text(selectedWorkingTemplate?.name ?? "Not selected")
                }
                
                ReviewSection(title: "Inspection Name") {
                    Text(inspectionName)
                }
                
                ReviewSection(title: "Schedule") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("\(selectedTime.rawValue) (\(selectedTime.timeRange))")
                        Text("Frequency: \(selectedFrequency.rawValue)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                ReviewSection(title: "Category") {
                    Text(selectedCategory.displayName)
                }
                
                if let entity = selectedEntity {
                    ReviewSection(title: entity.entityType) {
                        Text(entity.name)
                    }
                }
                
                ReviewSection(title: "Inspectors") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        ForEach(selectedInspectors, id: \.id) { inspector in
                            Text(inspector.name)
                        }
                        if let team = selectedTeam {
                            Text("Team: \(team.name)")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                
                if !notes.isEmpty {
                    ReviewSection(title: "Notes") {
                        Text(notes)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            if currentStep != .selectTemplate {
                Button("Back") {
                    previousStep()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.backgroundSecondary)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            Button(currentStep == .review ? "Create Inspection" : "Next") {
                if currentStep == .review {
                    createInspection()
                } else {
                    nextStep()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canProceed ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .disabled(!canProceed)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func stepColor(for step: CreationStep) -> Color {
        let currentIndex = CreationStep.allCases.firstIndex(of: currentStep) ?? 0
        let stepIndex = CreationStep.allCases.firstIndex(of: step) ?? 0
        
        if stepIndex < currentIndex {
            return AppTheme.Colors.success
        } else if stepIndex == currentIndex {
            return AppTheme.Colors.primary
        } else {
            return AppTheme.Colors.textTertiary
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .selectTemplate:
            return selectedWorkingTemplate != nil
        case .configureInspection:
            return !inspectionName.isEmpty
        case .selectTime:
            return true
        case .selectCategory:
            return true
        case .selectEntity:
            return true // Optional step
        case .selectInspectors:
            return !selectedInspectors.isEmpty
        case .review:
            return true
        }
    }
    
    private func nextStep() {
        guard let currentIndex = CreationStep.allCases.firstIndex(of: currentStep),
              currentIndex < CreationStep.allCases.count - 1 else {
            return
        }
        
        withAnimation {
            currentStep = CreationStep.allCases[currentIndex + 1]
        }
    }
    
    private func previousStep() {
        guard let currentIndex = CreationStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }
        
        withAnimation {
            currentStep = CreationStep.allCases[currentIndex - 1]
        }
    }
    
    private func loadWorkflowData() {
        loadWorkingTemplates()
        loadInspectors()
        loadTeams()
    }
    
    private func loadWorkingTemplates() {
        let templateFiles = directoryManager.listFiles(in: .working)
        workingTemplates = templateFiles.compactMap { fileName in
            guard let content = try? directoryManager.readTemplate(fileName: fileName, from: .working) else {
                return nil
            }
            
            return WorkingTemplateData(
                id: UUID(),
                fileName: fileName,
                name: fileName.replacingOccurrences(of: "_", with: " "),
                category: .grow,
                description: "Working template ready for inspection creation",
                itemCount: content.components(separatedBy: "- [ ]").count - 1
            )
        }
    }
    
    private func loadInspectors() {
        // This would fetch from Core Data
        availableInspectors = [
            InspectorData(id: UUID(), name: "John Smith", canInspect: true, certifications: ["Organic Inspector"]),
            InspectorData(id: UUID(), name: "Jane Doe", canInspect: true, certifications: ["Lead Inspector"])
        ]
    }
    
    private func loadTeams() {
        // This would fetch from Core Data
        availableTeams = [
            WorkTeamData(id: UUID(), name: "Inspection Team A", qualifiedMembers: availableInspectors)
        ]
    }
    
    private func loadEntitiesForCategory(_ category: InspectionCategory) {
        // This would fetch appropriate entities from Core Data based on category
        switch category {
        case .grow:
            availableEntities = [
                EntitySelectionData(id: UUID(), name: "North Field Tomatoes", entityType: "Grow", farmName: "Main Farm"),
                EntitySelectionData(id: UUID(), name: "South Field Lettuce", entityType: "Grow", farmName: "Main Farm")
            ]
        case .infrastructure:
            availableEntities = [
                EntitySelectionData(id: UUID(), name: "Processing Facility", entityType: "Infrastructure", farmName: "Main Farm"),
                EntitySelectionData(id: UUID(), name: "Storage Barn", entityType: "Infrastructure", farmName: "Main Farm")
            ]
        default:
            availableEntities = []
        }
    }
    
    private func generateInspectionName(from template: WorkingTemplateData) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        return "\(template.name) - \(dateString)"
    }
    
    private func toggleInspectorSelection(_ inspector: InspectorData) {
        if let index = selectedInspectors.firstIndex(where: { $0.id == inspector.id }) {
            selectedInspectors.remove(at: index)
        } else {
            selectedInspectors.append(inspector)
        }
        selectedTeam = nil // Clear team selection when selecting individuals
    }
    
    private func createInspection() {
        // This would create the actual inspection
        print("Creating inspection: \(inspectionName)")
        isPresented = false
    }
}

// MARK: - Supporting Types

enum CreationStep: CaseIterable {
    case selectTemplate
    case configureInspection
    case selectTime
    case selectCategory
    case selectEntity
    case selectInspectors
    case review
}

struct WorkingTemplateData {
    let id: UUID
    let fileName: String
    let name: String
    let category: InspectionCategory
    let description: String
    let itemCount: Int
}

struct InspectorData {
    let id: UUID
    let name: String
    let canInspect: Bool
    let certifications: [String]
}

struct WorkTeamData {
    let id: UUID
    let name: String
    let qualifiedMembers: [InspectorData]
}

struct EntitySelectionData {
    let id: UUID
    let name: String
    let entityType: String
    let farmName: String
}

// MARK: - Supporting Views (Continued in next message due to length)