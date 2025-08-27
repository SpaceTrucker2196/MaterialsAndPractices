//
//  WorkOrderAssignmentView.swift
//  MaterialsAndPractices
//
//  Provides detailed work order assignment interface with team management,
//  infrastructure requirements, and property owner notification.
//  Supports comprehensive work coordination for farm operations.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Detailed work order assignment view for team coordination and task management
/// Provides comprehensive interface for work order details and assignments
struct WorkOrderAssignmentView: View {
    // MARK: - Properties
    
    let workOrder: WorkOrder
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // Edit mode state
    @State private var isEditMode = false
    @State private var workOrderNotes = ""
    @State private var notifyPropertyOwner = false
    @State private var selectedInfrastructure: Set<String> = []
    @State private var additionalInstructions = ""
    @State private var selectedWorkers: Set<Worker> = []
    @State private var showingWorkerSelection = false
    @State private var showingInfrastructureSelection = false
    @State private var showingInspectionAssignment = false
    @State private var showingExpenseCreation = false
    
    // Infrastructure options
    private let commonInfrastructure = [
        "Tractor", "Wagon", "Truck", "Barn", "Pump", "Irrigation System",
        "Hand Tools", "Ladder", "Harvest Bins", "Greenhouse", "Storage Shed"
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Work order header
                    workOrderHeaderSection
                    
                    // Team assignment information
                    teamAssignmentSection
                    
                    // Individual worker assignment (edit mode only)
                    if isEditMode {
                        workerSelectionSection
                    }
                    
                    // Work shifts information
                    workShiftsSection
                    
                    // Infrastructure requirements
                    infrastructureSection
                    
                    // Inspection assignment (edit mode only)
                    if isEditMode {
                        inspectionAssignmentSection
                    }
                    
                    // Property owner notification
                    propertyOwnerSection
                    
                    // Additional instructions
                    instructionsSection
                    
                    // Action buttons
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("Work Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Save" : "Edit") {
                        if isEditMode {
                            saveChanges()
                        } else {
                            enterEditMode()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadWorkOrderData()
        }
    }
    
    // MARK: - UI Sections
    
    /// Work order header with title, priority, and status
    private var workOrderHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Work order title and priority
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(workOrder.title ?? "Untitled Work Order")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        Text(workOrder.workPriority.emoji)
                        Text(workOrder.workPriority.displayText)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(priorityColor)
                    }
                }
                
                Spacer()
                
                statusBadge
            }
            
            // Grow information
            if let grow = workOrder.grow {
                growInformationCard(grow: grow)
            }
            
            Divider()
        }
    }
    
    /// Team assignment information section
    private var teamAssignmentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Team Assignment")
            
            if let team = workOrder.assignedTeam {
                teamInformationCard(team: team)
            } else {
                Text("No team assigned")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Worker selection section (edit mode only)
    private var workerSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Individual Workers")
                
                Spacer()
                
                Button("Add Workers") {
                    showingWorkerSelection = true
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
            
            if !selectedWorkers.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.small) {
                    ForEach(Array(selectedWorkers), id: \.id) { worker in
                        HStack {
                            Text(worker.name ?? "Unknown")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                selectedWorkers.remove(worker)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.tiny)
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
            } else {
                Text("No individual workers selected")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .sheet(isPresented: $showingWorkerSelection) {
            WorkerSelectionView(
                selectedWorkers: $selectedWorkers,
                workOrder: workOrder,
                isPresented: $showingWorkerSelection
            )
        }
    }
    
    /// Work shifts information section
    private var workShiftsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Work Shifts")
            
            if !workOrder.workShifts.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    ForEach(workOrder.workShifts, id: \.self) { shift in
                        HStack {
                            Text(shift.emoji)
                            Text("\(shift.displayText) (\(shift.timeRange))")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                        }
                        .padding(.vertical, AppTheme.Spacing.small)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
            } else {
                Text("No shifts assigned")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Infrastructure requirements section
    private var infrastructureSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Infrastructure Needed")
            
            if isEditMode {
                infrastructureSelectionGrid
            } else {
                infrastructureDisplayList
            }
        }
    }
    
    /// Property owner notification section
    private var propertyOwnerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Property Owner Notification")
            
            if isEditMode {
                Toggle("Notify property owner before starting work", isOn: $notifyPropertyOwner)
                    .font(AppTheme.Typography.bodyMedium)
            } else {
                HStack {
                    Image(systemName: notifyPropertyOwner ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(notifyPropertyOwner ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                    
                    Text(notifyPropertyOwner ? "Property owner will be notified" : "No notification required")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }
            
            // Property owner contact info if available
            if let grow = workOrder.grow, let ownerPhone = grow.propertyOwnerPhone {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text(ownerPhone)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Button("Call") {
                        if let url = URL(string: "tel:\(ownerPhone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .padding()
                .background(AppTheme.Colors.primary.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    /// Additional instructions section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Instructions & Notes")
            
            if isEditMode {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Additional Instructions:")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextEditor(text: $additionalInstructions)
                        .frame(minHeight: 100)
                        .padding(AppTheme.Spacing.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            } else {
                if !additionalInstructions.isEmpty {
                    Text(additionalInstructions)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .padding()
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                } else {
                    Text("No additional instructions")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    /// Action buttons section
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if !isEditMode {
                HStack(spacing: AppTheme.Spacing.medium) {
                    // Start Work button (only if not started)
                    if workOrder.agricultureStatus == .notStarted {
                        CommonActionButton(
                            title: "Start Work",
                            style: .primary
                        ) {
                            startWorkOrder()
                        }
                        .disabled(workOrder.assignedTeam == nil && selectedWorkers.isEmpty)
                    }
                    
                    // End Work button (only if in progress)
                    if workOrder.agricultureStatus == .inProgress {
                        CommonActionButton(
                            title: "End Work",
                            style: .secondary
                        ) {
                            endWorkOrder()
                        }
                    }
                    
                    // Complete button (available if in progress)
                    if workOrder.agricultureStatus == .inProgress {
                        CommonActionButton(
                            title: "Mark Complete",
                            style: .secondary
                        ) {
                            completeWorkOrder()
                        }
                    }
                }
                
                // Add Expense button
                HStack {
                    CommonActionButton(
                        title: "Add Expense",
                        style: .tertiary
                    ) {
                        showingExpenseCreation = true
                    }
                    
                    Spacer()
                }
                
                // Inspection assignment section
                if isEditMode {
                    inspectionAssignmentSection
                }
            }
        }
        .sheet(isPresented: $showingExpenseCreation) {
            WorkOrderExpenseView(workOrder: workOrder, isPresented: $showingExpenseCreation)
        }
    }
    
    /// Inspection assignment section
    private var inspectionAssignmentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Inspection Assignment")
            
            Button("Assign Inspection") {
                showingInspectionAssignment = true
            }
            .foregroundColor(AppTheme.Colors.primary)
            .disabled(true) // Disabled as per requirements
            
            Text("Note: No workers are currently able to perform inspections")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .italic()
        }
        .sheet(isPresented: $showingInspectionAssignment) {
            InspectionAssignmentView(
                workOrder: workOrder,
                isPresented: $showingInspectionAssignment
            )
        }
    }
    
    // MARK: - Helper Components
    
    /// Status badge for work order
    private var statusBadge: some View {
        Text(workOrder.agricultureStatus.displayWithEmoji)
            .font(AppTheme.Typography.bodySmall)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(statusColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Grow information card
    private func growInformationCard(grow: Grow) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                if let cultivar = grow.cultivar {
                    Text(cultivar.emoji ?? "🌱")
                        .font(.title3)
                }
                
                Text(grow.title ?? "Unknown Grow")
                    .font(AppTheme.Typography.bodyLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            if let location = grow.locationName {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(.caption)
                    
                    Text(location)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Team information card
    private func teamInformationCard(team: WorkTeam) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(team.name ?? "Unnamed Team")
                    .font(AppTheme.Typography.bodyLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(team.activeMembers().count) members")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Team members
            ForEach(team.activeMembers(), id: \.id) { worker in
                HStack {
                    Circle()
                        .fill(worker.isClockedIn() ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                        .frame(width: 8, height: 8)
                    
                    Text(worker.name ?? "Unknown Worker")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    if worker.isClockedIn() {
                        Text("Clocked In")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Infrastructure selection grid for edit mode
    private var infrastructureSelectionGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.small) {
            ForEach(commonInfrastructure, id: \.self) { item in
                infrastructureToggleButton(item: item)
            }
        }
    }
    
    /// Infrastructure toggle button
    private func infrastructureToggleButton(item: String) -> some View {
        Button(action: {
            if selectedInfrastructure.contains(item) {
                selectedInfrastructure.remove(item)
            } else {
                selectedInfrastructure.insert(item)
            }
        }) {
            Text(item)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(selectedInfrastructure.contains(item) ? .white : AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, AppTheme.Spacing.tiny)
                .background(selectedInfrastructure.contains(item) ? AppTheme.Colors.primary : Color.gray.opacity(0.2))
                .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
    
    /// Infrastructure display list for view mode
    private var infrastructureDisplayList: some View {
        Group {
            if selectedInfrastructure.isEmpty {
                Text("No infrastructure requirements specified")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    ForEach(Array(selectedInfrastructure).sorted(), id: \.self) { item in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.primary)
                                .font(.caption)
                            
                            Text(item)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Priority color based on work order priority
    private var priorityColor: Color {
        switch workOrder.workPriority {
        case .low: return Color.green
        case .medium: return Color.orange
        case .high: return Color.red
        case .urgent: return Color.purple
        }
    }
    
    /// Status color based on agriculture status
    private var statusColor: Color {
        switch workOrder.agricultureStatus {
        case .notStarted: return Color.gray
        case .inProgress: return AppTheme.Colors.primary
        case .completed: return AppTheme.Colors.success
        case .onHold, .weatherDelay, .tooWet, .equipmentIssue, .waitingForMaterials, .waitingForInspection:
            return AppTheme.Colors.warning
        case .cancelled: return AppTheme.Colors.error
        }
    }
    
    // MARK: - Actions
    
    /// Load work order data into edit state
    private func loadWorkOrderData() {
        workOrderNotes = workOrder.notes ?? ""
        additionalInstructions = workOrderNotes
        // Load infrastructure requirements if they were saved previously
        // For now, using notes field to store this data
    }
    
    /// Enter edit mode
    private func enterEditMode() {
        isEditMode = true
    }
    
    /// Save changes and exit edit mode
    private func saveChanges() {
        workOrder.notes = additionalInstructions
        
        do {
            try viewContext.save()
            
            // Post notification for work order update
            CoreDataNotificationCenter.postWorkOrderNotification(
                type: .updated,
                workOrder: workOrder
            )
            
            isEditMode = false
        } catch {
            print("Error saving work order changes: \(error)")
        }
    }
    
    /// Start the work order
    private func startWorkOrder() {
        workOrder.agricultureStatus = .inProgress
        
        do {
            try viewContext.save()
            
            // Post notification for work order update
            CoreDataNotificationCenter.postWorkOrderNotification(
                type: .updated,
                workOrder: workOrder
            )
            
            // Dismiss the view as requested
            isPresented = false
        } catch {
            print("Error starting work order: \(error)")
        }
    }
    
    /// End the work order (pause/stop work)
    private func endWorkOrder() {
        workOrder.agricultureStatus = .onHold
        
        do {
            try viewContext.save()
            
            // Post notification for work order update
            CoreDataNotificationCenter.postWorkOrderNotification(
                type: .updated,
                workOrder: workOrder
            )
            
            // Dismiss the view as requested
            isPresented = false
        } catch {
            print("Error ending work order: \(error)")
        }
    }
    
    /// Complete the work order
    private func completeWorkOrder() {
        workOrder.agricultureStatus = .completed
        workOrder.isCompleted = true
        workOrder.completedDate = Date()
        
        do {
            try viewContext.save()
            
            // Post notification for work order update
            CoreDataNotificationCenter.postWorkOrderNotification(
                type: .updated,
                workOrder: workOrder
            )
            
            // Dismiss the view as requested
            isPresented = false
        } catch {
            print("Error completing work order: \(error)")
        }
    }
}

// MARK: - Worker Selection View

/// View for selecting workers to assign to work order
struct WorkerSelectionView: View {
    @Binding var selectedWorkers: Set<Worker>
    let workOrder: WorkOrder
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableWorkers, id: \.id) { worker in
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                            Text(worker.name ?? "Unknown Worker")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text(worker.position ?? "Team Member")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedWorkers.contains(worker) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.primary)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedWorkers.contains(worker) {
                            selectedWorkers.remove(worker)
                        } else {
                            selectedWorkers.insert(worker)
                        }
                    }
                }
            }
            .navigationTitle("Select Workers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var availableWorkers: [Worker] {
        let request: NSFetchRequest<Worker> = Worker.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Worker.name, ascending: true)]
        
        do {
            let allWorkers = try viewContext.fetch(request)
            // Filter out workers who are already in teams to avoid conflicts
            return allWorkers.filter { worker in
                guard let teams = worker.teams?.allObjects as? [WorkTeam] else { return true }
                return teams.filter { $0.isActive }.isEmpty
            }
        } catch {
            print("Error fetching workers: \(error)")
            return []
        }
    }
}

// MARK: - Inspection Assignment View

/// View for assigning inspections to work orders
struct InspectionAssignmentView: View {
    let workOrder: WorkOrder
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                Text("Inspection Assignment")
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("This feature will use WorkingInspectionTemplates to create inspection workflows.")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text("Note: This functionality is currently disabled as no workers are able to perform inspections.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.warning)
                    .italic()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Assign Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct WorkOrderAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleWorkOrder = WorkOrder(context: context)
        sampleWorkOrder.title = "Sample Work Order"
        sampleWorkOrder.workPriority = .high
        sampleWorkOrder.agricultureStatus = .notStarted
        
        return WorkOrderAssignmentView(
            workOrder: sampleWorkOrder,
            isPresented: .constant(true)
        )
        .environment(\.managedObjectContext, context)
    }
}
