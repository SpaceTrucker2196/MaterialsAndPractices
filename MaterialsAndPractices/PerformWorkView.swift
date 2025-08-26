//
//  PerformWorkView.swift
//  MaterialsAndPractices
//
//  Provides interface for creating new work orders and practices
//  with comprehensive team assignment and task management.
//  Supports farm management system work coordination.
//
//  Created by GitHub Copilot on 12/18/24.
//

import SwiftUI
import CoreData

/// View for creating new work orders and assigning work practices
/// Allows comprehensive task creation with team assignments and scheduling
struct PerformWorkView: View {
    // MARK: - Properties
    
    let grow: Grow
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // Form state
    @State private var workOrderTitle = ""
    @State private var workOrderNotes = ""
    @State private var selectedPriority = WorkOrderPriority.medium
    @State private var selectedStatus = AgricultureWorkStatus.notStarted
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var estimatedHours: Double = 8.0
    
    // Work practice state
    @State private var practiceName = ""
    @State private var practiceNotes = ""
    
    // Work shift state
    @State private var selectedShifts: Set<WorkShift> = []
    
    // Team assignment
    @State private var selectedTeam: WorkTeam?
    @State private var showingTeamPicker = false
    
    // Available teams
    @FetchRequest(
        entity: WorkTeam.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkTeam.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == YES")
    ) private var availableTeams: FetchedResults<WorkTeam>
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Work Order Section
                workOrderSection
                
                // Work Practice Section
                workPracticeSection
                
                // Work Shift Section
                workShiftSection
                
                // Team Assignment Section
                teamAssignmentSection
                
                // Schedule Section
                scheduleSection
                
                // Action Section
                actionSection
            }
            .navigationTitle("Perform Work")
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
    
    /// Work order information section
    private var workOrderSection: some View {
        Section("Work Order") {
            TextField("Work Order Title", text: $workOrderTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Text("Priority:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Picker("Priority", selection: $selectedPriority) {
                    ForEach(WorkOrderPriority.allCases, id: \.self) { priority in
                        Text("\(priority.emoji) \(priority.displayText)")
                            .tag(priority)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                Text("Status:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Picker("Status", selection: $selectedStatus) {
                    ForEach(AgricultureWorkStatus.allCases, id: \.self) { status in
                        Text(status.displayWithEmoji)
                            .tag(status)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Notes:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextEditor(text: $workOrderNotes)
                    .frame(minHeight: 80)
                    .padding(AppTheme.Spacing.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    /// Work practice information section
    private var workPracticeSection: some View {
        Section("Work Practice") {
            TextField("Practice Name (e.g., Weeding, Harvesting)", text: $practiceName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Practice Notes:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextEditor(text: $practiceNotes)
                    .frame(minHeight: 60)
                    .padding(AppTheme.Spacing.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    /// Work shift selection section
    private var workShiftSection: some View {
        Section("Work Shifts") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Select which 4-hour shifts this work order will occupy for the day:")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                ForEach(WorkShift.allCases, id: \.self) { shift in
                    WorkShiftToggleRow(
                        shift: shift,
                        isSelected: selectedShifts.contains(shift),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedShifts.insert(shift)
                            } else {
                                selectedShifts.remove(shift)
                            }
                        }
                    )
                }
                
                if selectedShifts.isEmpty {
                    Text("At least one shift must be selected")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.error)
                }
            }
        }
    }
    
    /// Team assignment section
    private var teamAssignmentSection: some View {
        Section("Team Assignment") {
            Button(action: { showingTeamPicker = true }) {
                HStack {
                    Text("Assigned Team:")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if let selectedTeam = selectedTeam {
                        VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                            Text(selectedTeam.name ?? "Unnamed Team")
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("\(selectedTeam.activeMembers().count) members")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } else {
                        Text("Select Team")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            .sheet(isPresented: $showingTeamPicker) {
                TeamPickerView(selectedTeam: $selectedTeam, isPresented: $showingTeamPicker, workOrderDate: dueDate)
            }
            
            if let selectedTeam = selectedTeam {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Team Members:")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(selectedTeam.activeMembers(), id: \.self) { worker in
                        HStack {
                            Image(systemName: worker.isClockedIn() ? "clock.fill" : "clock")
                                .foregroundColor(worker.isClockedIn() ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                                .font(.caption)
                            
                            Text(worker.name ?? "Unknown Worker")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            if worker.isClockedIn() {
                                Text("(Clocked In)")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, AppTheme.Spacing.small)
            }
        }
    }
    
    /// Schedule and estimation section
    private var scheduleSection: some View {
        Section("Schedule & Estimation") {
            DatePicker(
                "Due Date:",
                selection: $dueDate,
                in: Date()...,
                displayedComponents: [.date]
            )
            
            HStack {
                Text("Estimated Hours:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Stepper(
                    value: $estimatedHours,
                    in: 0.5...40.0,
                    step: 0.5
                ) {
                    Text("\(estimatedHours, specifier: "%.1f") hours")
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }
        }
    }
    
    /// Action buttons section
    private var actionSection: some View {
        Section {
            CommonActionButton(
                title: "Create Work Order",
                style: .primary
            ) {
                createWorkOrder()
            }
            .disabled(!isFormValid)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Validation for form completion
    private var isFormValid: Bool {
        return !workOrderTitle.isEmpty && 
               !practiceName.isEmpty && 
               !selectedShifts.isEmpty &&
               selectedTeam != nil
    }
    
    // MARK: - Actions
    
    /// Creates the work order with associated work practice
    private func createWorkOrder() {
        guard isFormValid else { return }
        
        // Create work order
        let workOrder = WorkOrder(context: viewContext)
        workOrder.id = UUID()
        workOrder.title = workOrderTitle
        workOrder.notes = workOrderNotes
        workOrder.priority = selectedPriority.rawValue
        workOrder.status = selectedStatus.rawValue
        workOrder.createdDate = Date()
        workOrder.dueDate = dueDate
        workOrder.totalEstimatedHours = estimatedHours
        workOrder.isCompleted = false
        workOrder.assignedTeam = selectedTeam
        workOrder.workShifts = Array(selectedShifts)
        workOrder.grow = grow
        
        // Create work practice
        let workPractice = Work(context: viewContext)
        workPractice.name = practiceName
        workPractice.practice = practiceNotes
        workPractice.jobCompleted = false
        workPractice.grow = grow
        workPractice.workOrder = workOrder
        
        // Save context
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error creating work order: \(error)")
            // In a real app, show an error alert
        }
    }
}

// MARK: - Team Picker View

/// Picker view for selecting work teams with team creation capability
struct TeamPickerView: View {
    @Binding var selectedTeam: WorkTeam?
    @Binding var isPresented: Bool
    let workOrderDate: Date
    @Environment(\.managedObjectContext) private var viewContext
    
    // Team creation state
    @State private var showingTeamCreation = false
    @State private var createdTeam: WorkTeam?
    
    @FetchRequest(
        entity: WorkTeam.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkTeam.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == YES")
    ) private var availableTeams: FetchedResults<WorkTeam>
    
    var body: some View {
        NavigationView {
            List {
                // Create new team section
                Section {
                    Button(action: {
                        showingTeamCreation = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.Colors.primary)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                                Text("Create New Team")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.primary)
                                
                                Text("Select workers and create a team for this work order")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .font(.caption)
                        }
                    }
                }
                
                // Available teams section
                if !availableTeams.isEmpty {
                    Section("Available Teams") {
                        ForEach(availableTeams, id: \.self) { team in
                            Button(action: {
                                selectedTeam = team
                                isPresented = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                                        Text(team.name ?? "Unnamed Team")
                                            .font(AppTheme.Typography.bodyMedium)
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                        
                                        Text("\(team.activeMembers().count) members (\(team.clockedInCount()) clocked in)")
                                            .font(AppTheme.Typography.bodySmall)
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedTeam?.id == team.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppTheme.Colors.primary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        Text("No existing teams. Create your first team above.")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(AppTheme.Typography.bodyMedium)
                    }
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingTeamCreation) {
                TeamCreationView(
                    isPresented: $showingTeamCreation,
                    createdTeam: $createdTeam,
                    workOrderDate: workOrderDate
                )
            }
            .onChange(of: createdTeam) { newTeam in
                if let newTeam = newTeam {
                    selectedTeam = newTeam
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Work Shift Toggle Row

/// Individual work shift toggle row for shift selection
struct WorkShiftToggleRow: View {
    let shift: WorkShift
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                // Shift emoji and name
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(shift.emoji)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(shift.displayText)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(shift.timeRange)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                    .font(.title3)
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct PerformWorkView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleGrow = Grow(context: context)
        sampleGrow.title = "Sample Grow"
        
        return PerformWorkView(
            grow: sampleGrow,
            isPresented: .constant(true)
        )
        .environment(\.managedObjectContext, context)
    }
}