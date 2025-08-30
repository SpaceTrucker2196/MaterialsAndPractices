//
//  TeamCreationView.swift
//  MaterialsAndPractices
//
//  Provides comprehensive team creation interface for work order assignments.
//  Features worker selection with availability checking and team management.
//  Supports farm management workflow with intuitive tile-based interface.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// View for creating new work teams with worker selection and availability checking
/// Integrates with work order system to ensure proper team assignments
struct TeamCreationView: View {
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Binding var createdTeam: WorkTeam?
    let workOrderDate: Date
    @Environment(\.managedObjectContext) private var viewContext
    
    // Form state
    @State private var teamName = ""
    @State private var selectedWorkers: Set<Worker> = []
    @State private var showingNameError = false
    
    // Available workers
    @FetchRequest(
        entity: Worker.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Worker.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Worker.name, ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == YES")
    ) private var availableWorkers: FetchedResults<Worker>
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Team name input section
                teamNameSection
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary.opacity(0.3))
                
                // Worker selection section
                workerSelectionSection
                
                // Team composition warnings
                if selectedWorkers.count == 1 {
                    teamCompositionWarning
                        .padding()
                        .background(AppTheme.Colors.warning.opacity(0.1))
                }
                
                // Action buttons
                actionButtonsSection
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary.opacity(0.5))
            }
            .navigationTitle("Create Team")
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
    
    // MARK: - UI Sections
    
    /// Team name input section
    private var teamNameSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Team Name")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            TextField("Enter team name", text: $teamName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    showingNameError = teamName.isEmpty
                }
            
            if showingNameError {
                Text("Team name is required")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
    }
    
    /// Worker selection section with tiles
    private var workerSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Section header
            HStack {
                Text("Select Team Members")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Text("\(selectedWorkers.count) selected")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            .padding(.horizontal)
            
            // Worker tiles grid
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.medium) {
                    ForEach(availableWorkers, id: \.id) { worker in
                        WorkerSelectionTile(
                            worker: worker,
                            workOrderDate: workOrderDate,
                            isSelected: selectedWorkers.contains(worker),
                            onSelectionChanged: { isSelected in
                                toggleWorkerSelection(worker, isSelected: isSelected)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Team composition warning for single-person teams
    private var teamCompositionWarning: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.Colors.warning)
                
                Text("Single Person Team")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.warning)
            }
            
            Text("Good Management Practice: Consider assigning workers in pairs for better productivity, safety, and knowledge sharing. Two-person teams provide mutual support and reduce isolation during farm work.")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    /// Action buttons section
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            CommonActionButton(
                title: "Create Team",
                style: .primary
            ) {
                createTeam()
            }
            .disabled(!isFormValid)
            
            CommonActionButton(
                title: "Cancel",
                style: .secondary
            ) {
                isPresented = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Grid columns for worker tiles
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
        ]
    }
    
    /// Form validation
    private var isFormValid: Bool {
        !teamName.isEmpty && !selectedWorkers.isEmpty
    }
    
    // MARK: - Actions
    
    /// Toggle worker selection
    private func toggleWorkerSelection(_ worker: Worker, isSelected: Bool) {
        if isSelected {
            selectedWorkers.insert(worker)
        } else {
            selectedWorkers.remove(worker)
        }
    }
    
    /// Create the team with selected workers
    private func createTeam() {
        guard isFormValid else {
            showingNameError = teamName.isEmpty
            return
        }
        
        // Create new work team
        let newTeam = WorkTeam(context: viewContext)
        newTeam.id = UUID()
        newTeam.name = teamName
        newTeam.isActive = true
        newTeam.createdDate = Date()
        
        // Add selected workers to team
        for worker in selectedWorkers {
            newTeam.addToMembers(worker)
        }
        
        // Save context
        do {
            try viewContext.save()
            createdTeam = newTeam
            isPresented = false
        } catch {
            print("Error creating team: \(error)")
            // In a real app, show error alert
        }
    }
}

// MARK: - Worker Selection Tile

/// Individual worker tile for team selection with availability indicators
struct WorkerSelectionTile: View {
    // MARK: - Properties
    
    let worker: Worker
    let workOrderDate: Date
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            onSelectionChanged(!isSelected)
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with selection indicator and availability
                workerTileHeader
                
                // Worker information
                workerTileContent
                
                // Availability status
                workerAvailabilityStatus
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .background(tileBackgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(selectionBorderOverlay)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Header with selection indicator and photo
    private var workerTileHeader: some View {
        HStack {
            // Worker profile photo or placeholder
            workerProfileDisplay
            
            Spacer()
            
            // Selection indicator
            selectionIndicator
        }
    }
    
    /// Worker profile photo or default placeholder
    private var workerProfileDisplay: some View {
        Group {
            if let imagePath = worker.imagePath,
               let image = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            }
            // Fallback to profilePhotoData
            else if let photoData = worker.profilePhotoData,
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
        }
    }
    
    /// Selection indicator (checkmark or circle)
    private var selectionIndicator: some View {
        Group {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.title3)
            }
        }
    }
    
    /// Worker name and position information
    private var workerTileContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
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
        }
    }
    
    /// Worker availability status for the work order date
    private var workerAvailabilityStatus: some View {
        HStack {
            availabilityIndicator
            
            Text(availabilityText)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(availabilityColor)
        }
    }
    
    /// Availability indicator icon
    private var availabilityIndicator: some View {
        Image(systemName: isWorkerAvailable ? "checkmark.circle.fill" : "clock.fill")
            .foregroundColor(availabilityColor)
            .font(.caption)
    }
    
    // MARK: - Computed Properties
    
    /// Check if worker is available on the work order date
    private var isWorkerAvailable: Bool {
        // For now, assume workers are available if they're active
        // In a full implementation, this would check for conflicts with other work orders
        // or time off requests for the specific date
        return worker.isActive
    }
    
    /// Availability text description
    private var availabilityText: String {
        if isWorkerAvailable {
            return "Available"
        } else {
            return "Busy"
        }
    }
    
    /// Color for availability status
    private var availabilityColor: Color {
        isWorkerAvailable ? AppTheme.Colors.success : AppTheme.Colors.warning
    }
    
    /// Background color based on selection state
    private var tileBackgroundColor: Color {
        if isSelected {
            return AppTheme.Colors.primary.opacity(0.1)
        } else {
            return AppTheme.Colors.backgroundSecondary
        }
    }
    
    /// Border overlay for selection indication
    private var selectionBorderOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .stroke(
                isSelected ? AppTheme.Colors.primary : Color.clear,
                lineWidth: 2
            )
    }
}

// MARK: - Preview

struct TeamCreationView_Previews: PreviewProvider {
    static var previews: some View {
        TeamCreationView(
            isPresented: .constant(true),
            createdTeam: .constant(nil),
            workOrderDate: Date()
        )
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
