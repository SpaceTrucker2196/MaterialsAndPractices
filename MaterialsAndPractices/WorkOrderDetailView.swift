//
//  WorkOrderDetailView.swift
//  MaterialsAndPractices
//
//  Unified work order view supporting both display and insert modes
//  with time tracking, team management, and audit trail functionality.
//
//  Created by GitHub Copilot on 12/18/24.
//

import SwiftUI
import CoreData

/// Mode for the work order view
enum WorkOrderViewMode {
    case display    // View existing work order
    case insert     // Create new work order
}

/// State for work order operations
enum WorkOrderOperationState {
    case notStarted
    case inProgress
    case stopped
    case completed
    case locked     // Cannot be modified after completion
}

/// Unified work order view that handles both creation and display
struct WorkOrderDetailView: View {
    // MARK: - Properties
    
    let mode: WorkOrderViewMode
    let grow: Grow
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // Existing work order (for display mode)
    let workOrder: WorkOrder?
    
    // Form state for insert mode or edits
    @State private var workOrderTitle = ""
    @State private var workOrderNotes = ""
    @State private var selectedPriority = WorkOrderPriority.medium
    @State private var selectedStatus = AgricultureWorkStatus.notStarted
    @State private var selectedWorkOrderType = WorkOrderType.other
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var estimatedHours: Double = 8.0
    
    // Amendment tracking
    @State private var selectedAmendments: Set<CropAmendment> = []
    @State private var showingAmendmentSelection = false
    @State private var organicCertificationStatus: OrganicCertificationStatus = .requiredForOrganic
    
    // Farm practice state (replaces old Work practice)
    @State private var selectedFarmPractices: Set<FarmPractice> = []
    
    // Work shift state
    @State private var selectedShifts: Set<WorkShift> = []
    
    // Team assignment
    @State private var selectedTeam: WorkTeam?
    @State private var showingTeamPicker = false
    
    // Time tracking state
    @State private var currentWorkSegment: WorkSegment?
    @State private var workSegments: [WorkSegment] = []
    @State private var totalHours: Double = 0.0
    @State private var operationState: WorkOrderOperationState = .notStarted
    
    // Edit mode for display view
    @State private var isEditing = false
    
    // Available teams
    @FetchRequest(
        entity: WorkTeam.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkTeam.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == YES")
    ) private var availableTeams: FetchedResults<WorkTeam>
    
    // MARK: - Initializers
    
    /// Initialize for insert mode (new work order)
    init(mode: WorkOrderViewMode, grow: Grow, isPresented: Binding<Bool>) {
        self.mode = mode
        self.grow = grow
        self.workOrder = nil
        self._isPresented = isPresented
    }
    
    /// Initialize for display mode (existing work order)
    init(workOrder: WorkOrder, isPresented: Binding<Bool>) {
        self.mode = .display
        self.grow = workOrder.grow!
        self.workOrder = workOrder
        self._isPresented = isPresented
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                if mode == .display && !isEditing {
                    displayModeContent
                } else {
                    editModeContent
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                if mode == .display {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if operationState == .completed {
                            Text("Completed")
                                .foregroundColor(AppTheme.Colors.success)
                        } else if operationState != .locked {
                            Button(isEditing ? "Done" : "Edit") {
                                if isEditing {
                                    saveWorkOrder()
                                }
                                isEditing.toggle()
                            }
                        }
                    }
                }
            }
            .onAppear {
                setupInitialState()
            }
            .onChange(of: selectedAmendments) { _ in
                updateOrganicCertificationStatus()
            }
            .sheet(isPresented: $showingAmendmentSelection) {
                AmendmentSelectionView(
                    selectedAmendments: $selectedAmendments,
                    isPresented: $showingAmendmentSelection
                )
            }
            .sheet(isPresented: $showingTeamPicker) {
                TeamPickerView(
                    selectedTeam: $selectedTeam,
                    isPresented: $showingTeamPicker,
                    workOrderDate: dueDate
                )
            }
        }
    }
    
    // MARK: - Display Mode Content
    
    private var displayModeContent: some View {
        Group {
            // Work Order Status Section
            workOrderStatusSection
            
            // Time Tracking Section
            timeTrackingSection
            
            // Work Order Information Section
            workOrderInfoDisplaySection
            
            // Team Information Section
            teamInfoDisplaySection
            
            // Amendment Information Section
            if !selectedAmendments.isEmpty {
                amendmentApplicationSection
            }
            
            // Work Segments History
            workSegmentsSection
            
            // Action Section (for work control)
            if operationState != .locked {
                workControlSection
            }
        }
    }
    
    // MARK: - Edit Mode Content
    
    private var editModeContent: some View {
        Group {
            // Organic Certification Banner
            organicCertificationBanner
            
            // Work Order Section
            workOrderSection
            
            // Farm Practice Section (replaces old work practice)
            farmPracticeSection
            
            // Amendment Application Section
            amendmentApplicationSection
            
            // Work Shift Section
            workShiftSection
            
            // Team Assignment Section
            teamAssignmentSection
            
            // Schedule Section
            scheduleSection
            
            // Action Section
            if mode == .insert {
                insertActionSection
            }
        }
    }
    
    // MARK: - UI Sections for Display Mode
    
    private var workOrderStatusSection: some View {
        Section("Status") {
            HStack {
                StatusIndicator(state: operationState)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(operationState.displayText)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let workOrder = workOrder {
                        Text("Created \(formattedDate(workOrder.createdDate ?? Date()))")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if operationState == .locked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
    }
    
    private var timeTrackingSection: some View {
        Section("Time Tracking") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Total hours display
                HStack {
                    Text("Total Hours:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f hours", totalHours))
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                // Current segment info
                if let currentSegment = currentWorkSegment {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Current Segment:")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        HStack {
                            Text("Started: \(formattedTime(currentSegment.startTime))")
                                .font(AppTheme.Typography.bodySmall)
                            
                            Spacer()
                            
                            Text("Team: \(currentSegment.teamSize) members")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.info)
                        }
                    }
                    .padding(AppTheme.Spacing.small)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
    }
    
    private var workOrderInfoDisplaySection: some View {
        Section("Work Order Details") {
            VStack(spacing: AppTheme.Spacing.medium) {
                InfoDisplayRow(label: "Title", value: workOrderTitle)
//                InfoDisplayRow(label: "Type", value: selectedWorkOrderType.displayWithEmoji)
               
       //         InfoDisplayRow(label: "Status", value: selectedStatus.displayWithEmoji)

                if !workOrderNotes.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Notes:")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Text(workOrderNotes)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
    
    private var teamInfoDisplaySection: some View {
        Section("Team Assignment") {
            if let team = selectedTeam {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    InfoDisplayRow(label: "Team", value: team.name ?? "Unnamed Team")
                    InfoDisplayRow(label: "Members", value: "\(team.activeMembers().count)")
                    
                    if !team.activeMembers().isEmpty {
                        Text("Team Members:")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        ForEach(team.activeMembers(), id: \.self) { worker in
                            HStack {
                                Image(systemName: worker.isClockedIn() ? "clock.fill" : "clock")
                                    .foregroundColor(worker.isClockedIn() ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                                    .font(.caption)
                                
                                Text(worker.name ?? "Unknown Worker")
                                    .font(AppTheme.Typography.bodySmall)
                                
                                if worker.isClockedIn() {
                                    Text("(Active)")
                                        .font(AppTheme.Typography.labelSmall)
                                        .foregroundColor(AppTheme.Colors.success)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            } else {
                Text("No team assigned")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    
    // 1. Main method that simply calls the helper method
    
    // 2. Helper method that creates the section structure
    private func createWorkSegmentsSection() -> some View {
        Section("Work History") {
            workSegmentsContent
        }
    }

    // 3. Helper method for the content based on state
    @ViewBuilder
    private var workSegmentsContent: some View {
        if workSegments.isEmpty && currentWorkSegment == nil {
            emptyWorkSegmentsView
        } else {
            completedWorkSegmentsView
            
            if let current = currentWorkSegment {
                currentWorkSegmentView(current)
            }
        }
    }

    // 4. Helper method for empty state
    private var emptyWorkSegmentsView: some View {
        Text("No work segments recorded")
            .foregroundColor(AppTheme.Colors.textSecondary)
    }

    // 5. Helper method for completed segments
    private var completedWorkSegmentsView: some View {
        ForEach(workSegments.indices, id: \.self) { index in
            WorkSegmentRow(segment: workSegments[index], index: index + 1)
        }
    }

    // 6. Helper method for current segment
    private func currentWorkSegmentView(_ segment: WorkSegment) -> some View {
        WorkSegmentRow(segment: segment, index: workSegments.count + 1, isCurrent: true)
    }
    

    private var workSegmentsSection: some View {
        createWorkSegmentsSection()
    }

    private var workControlSection: some View {
        Section("Work Control") {
            VStack(spacing: AppTheme.Spacing.medium) {
                if operationState == .notStarted {
                    CommonActionButton(
                        title: "Start Work",
                        style: .primary,
                        action: startWork
                    )
                    .disabled(selectedTeam == nil)
                } else if operationState == .inProgress {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        CommonActionButton(
                            title: "Stop Work",
                            style: .secondary,
                            action: stopWork
                        )
                        
                        CommonActionButton(
                            title: "Complete Work Order",
                            style: .primary,
                            action: completeWorkOrder
                        )
                    }
                } else if operationState == .stopped {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        CommonActionButton(
                            title: "Resume Work",
                            style: .secondary,
                            action: startWork
                        )
                        
                        CommonActionButton(
                            title: "Complete Work Order",
                            style: .primary,
                            action: completeWorkOrder
                        )
                    }
                }
                
                if operationState != .notStarted {
                    Text("Once completed, this work order cannot be modified")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Reusable UI Sections (Edit Mode)
    
    private var organicCertificationBanner: some View {
        Section {
            HStack {
                Image(systemName: organicCertificationStatus == .requiredForOrganic ? "leaf.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(Color(organicCertificationStatus.colorName))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Organic Certification Status")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(organicCertificationStatus.displayText)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(Color(organicCertificationStatus.colorName))
                }
                
                Spacer()
                
                if organicCertificationStatus != .requiredForOrganic {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppTheme.Colors.info)
                        .font(.caption)
                }
            }
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color(organicCertificationStatus.colorName).opacity(0.1))
            )
        }
    }
    
    private var workOrderSection: some View {
        Section("Work Order") {
            TextField("Work Order Title", text: $workOrderTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Text("Type:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Picker("Work Order Type", selection: $selectedWorkOrderType) {
                    ForEach(WorkOrderType.allCases, id: \.self) { type in
                        Text(type.displayWithEmoji)
                            .tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
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
    
    private var amendmentApplicationSection: some View {
        Section("Amendment Application") {
            Button(action: {
                showingAmendmentSelection = true
            }) {
                HStack {
                    Image(systemName: "leaf.circle")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Amendment Application")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text(selectedAmendments.isEmpty ? "No amendments selected" : "\(selectedAmendments.count) amendment(s) selected")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            
            // Display selected amendments
            if !selectedAmendments.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Selected Amendments:")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(Array(selectedAmendments), id: \.amendmentID) { amendment in
                        HStack {
                            Image(systemName: amendment.omriListed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(Color(amendment.omriListed ? "requiredForOrganic" : "failedForOrganic"))
                                .font(.caption)
                            
                            Text(amendment.productName ?? "Taco Sauce")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            if !amendment.omriListed {
                                Text("(Not OMRI)")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(Color("failedForOrganic"))
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, AppTheme.Spacing.small)
            }
        }
    }
    
    private var farmPracticeSection: some View {
        Section("Farm Practices") {
            FarmPracticeSelectionView(selectedPractices: $selectedFarmPractices)
                .frame(minHeight: 200)
        }
    }
    
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
    
    private var insertActionSection: some View {
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
    
    private var navigationTitle: String {
        switch mode {
        case .insert:
            return "New Work Order"
        case .display:
            return workOrderTitle.isEmpty ? "Work Order" : workOrderTitle
        }
    }
    
    private var isFormValid: Bool {
        return !workOrderTitle.isEmpty && 
               !selectedFarmPractices.isEmpty && 
               !selectedShifts.isEmpty &&
               selectedTeam != nil
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        if let workOrder = workOrder {
            // Load existing work order data
            workOrderTitle = workOrder.title ?? ""
            workOrderNotes = workOrder.notes ?? ""
            
            if let priorityRaw = workOrder.priority {
                selectedPriority = WorkOrderPriority(rawValue: priorityRaw) ?? .medium
            }
            
            if let statusRaw = workOrder.status {
                selectedStatus = AgricultureWorkStatus(rawValue: statusRaw) ?? .notStarted
            }
            
            selectedTeam = workOrder.assignedTeam
            dueDate = workOrder.dueDate ?? Date()
            estimatedHours = workOrder.totalEstimatedHours
            
            // Load existing farm practices
            if let practices = workOrder.farmPractices?.allObjects as? [FarmPractice] {
                selectedFarmPractices = Set(practices)
            }
            
            // Determine operation state
            if workOrder.isCompleted {
                operationState = .locked
            } else {
                operationState = .notStarted // TODO: Load actual state from time segments
            }
            
            // Load work segments and calculate total hours
            loadWorkSegments()
        } else {
            // Set up for new work order
            generateWorkOrderTitle()
            updateOrganicCertificationStatus()
            operationState = .notStarted
        }
    }
    
    private func generateWorkOrderTitle() {
        let fieldName = grow.locationName ?? "Field"
        let growName = grow.title ?? "Grow"
        
        // Extract first 6 letters of field name
        let fieldPrefix = String(fieldName.prefix(6))
        
        // Extract first word of grow name
        let growFirstWord = growName.components(separatedBy: " ").first ?? growName
        
        // Get current date components
        let now = Date()
        let calendar = Calendar.current
        
        // Full day name
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: now)
        
        // Week number
        let weekNumber = calendar.component(.weekOfYear, from: now)
        
        // Hour of the day
        let hour = calendar.component(.hour, from: now)
        
        // Format: "First6-FirstWord-DayName-Week##-Hour##"
        workOrderTitle = "\(fieldPrefix)-\(growFirstWord)-\(dayName)-Week\(weekNumber)-Hour\(hour)"
    }
    
    private func updateOrganicCertificationStatus() {
        let hasNonOrganicAmendments = selectedAmendments.contains { !$0.omriListed }
        
        if hasNonOrganicAmendments {
            organicCertificationStatus = .failedForOrganic
        } else if selectedAmendments.isEmpty {
            organicCertificationStatus = .requiredForOrganic
        } else {
            organicCertificationStatus = .requiredForOrganic
        }
    }
    
    private func loadWorkSegments() {
        guard let workOrder = workOrder else { return }
        
        // Load time clock entries associated with this work order
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(format: "workOrder == %@", workOrder)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TimeClock.date, ascending: true),
            NSSortDescriptor(keyPath: \TimeClock.blockNumber, ascending: true)
        ]
        
        do {
            let timeEntries = try viewContext.fetch(request)
            
            // Group time entries by date and block to create work segments
            workSegments = createWorkSegmentsFromTimeEntries(timeEntries)
            
            // Calculate total hours
            calculateTotalHours()
            
            // Determine current operation state based on work segments
            updateOperationStateFromWorkSegments()
            
        } catch {
            print("Error loading work segments: \(error)")
        }
    }
    
    private func createWorkSegmentsFromTimeEntries(_ timeEntries: [TimeClock]) -> [WorkSegment] {
        var segments: [WorkSegment] = []
        var currentSegmentEntries: [TimeClock] = []
        var lastDate: Date?
        var lastBlockNumber: Int16 = -1
        
        for entry in timeEntries {
            let entryDate = Calendar.current.startOfDay(for: entry.date ?? Date())
            
            // Check if we need to start a new segment
            let shouldStartNewSegment = lastDate != entryDate || 
                                      entry.blockNumber != lastBlockNumber ||
                                      currentSegmentEntries.isEmpty
            
            if shouldStartNewSegment && !currentSegmentEntries.isEmpty {
                // Create segment from current entries
                if let segment = createWorkSegmentFromEntries(currentSegmentEntries) {
                    segments.append(segment)
                }
                currentSegmentEntries = []
            }
            
            currentSegmentEntries.append(entry)
            lastDate = entryDate
            lastBlockNumber = entry.blockNumber
        }
        
        // Handle remaining entries
        if !currentSegmentEntries.isEmpty {
            if let segment = createWorkSegmentFromEntries(currentSegmentEntries) {
                segments.append(segment)
            }
        }
        
        return segments
    }
    
    private func createWorkSegmentFromEntries(_ entries: [TimeClock]) -> WorkSegment? {
        guard !entries.isEmpty else { return nil }
        
        // Get the earliest start time and latest end time
        let startTimes = entries.compactMap { $0.clockInTime }
        let endTimes = entries.compactMap { $0.clockOutTime }
        
        guard let earliestStart = startTimes.min() else { return nil }
        
        let teamMembers = entries.compactMap { $0.worker?.name }
        let teamSize = entries.count
        
        var segment = WorkSegment(
            startTime: earliestStart,
            teamSize: teamSize,
            teamMembers: teamMembers
        )
        
        // Set end time if all entries are completed
        if endTimes.count == entries.count, let latestEnd = endTimes.max() {
            segment.endTime = latestEnd
            segment.calculateHours()
        }
        
        return segment
    }
    
    private func updateOperationStateFromWorkSegments() {
        guard let workOrder = workOrder else { return }
        
        if workOrder.isCompleted {
            operationState = .locked
        } else if workSegments.isEmpty {
            operationState = .notStarted
        } else if currentWorkSegment != nil {
            operationState = .inProgress
        } else {
            operationState = .stopped
        }
    }
    
    private func createWorkOrder() {
        guard isFormValid else { return }
        
        // Prepare notes with amendment information
        var combinedNotes = workOrderNotes
        
        if !selectedAmendments.isEmpty {
            if !combinedNotes.isEmpty {
                combinedNotes += "\n\n"
            }
            
            combinedNotes += "Applied Amendments:\n"
            for amendment in selectedAmendments {
                //combinedNotes += "• \(amendment.fullDescription)\n"
            }
        }
        
        // Create work order
        let newWorkOrder = WorkOrder(context: viewContext)
        newWorkOrder.id = UUID()
        newWorkOrder.title = workOrderTitle
        newWorkOrder.notes = combinedNotes
        newWorkOrder.priority = selectedPriority.rawValue
        newWorkOrder.status = selectedStatus.rawValue
        newWorkOrder.createdDate = Date()
        newWorkOrder.dueDate = dueDate
        newWorkOrder.totalEstimatedHours = estimatedHours
        newWorkOrder.isCompleted = false
        newWorkOrder.assignedTeam = selectedTeam
        newWorkOrder.grow = grow
        
        // Link selected farm practices to work order
        for practice in selectedFarmPractices {
            newWorkOrder.addToFarmPractices(practice)
        }
        
        // Create audit trail entry
        createAuditTrailEntry(for: newWorkOrder, action: "created")
        
        // Save context
        do {
            try viewContext.save()
            
            // Post notification for work order creation
            CoreDataNotificationCenter.postWorkOrderNotification(
                type: .created,
                workOrder: newWorkOrder
            )
            
            isPresented = false
        } catch {
            print("Error creating work order: \(error)")
            // In a real app, show an error alert
        }
    }
    
    private func saveWorkOrder() {
        guard let workOrder = workOrder else { return }
        
        // Update work order with changes
        workOrder.title = workOrderTitle
        workOrder.notes = workOrderNotes
        workOrder.priority = selectedPriority.rawValue
        workOrder.status = selectedStatus.rawValue
        workOrder.dueDate = dueDate
        workOrder.totalEstimatedHours = estimatedHours
        workOrder.assignedTeam = selectedTeam
        
        // Create audit trail entry
        createAuditTrailEntry(for: workOrder, action: "modified")
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving work order: \(error)")
        }
    }
    
    private func startWork() {
        guard let team = selectedTeam else { return }
        
        let segment = WorkSegment(
            startTime: Date(),
            teamSize: team.activeMembers().count,
            teamMembers: team.activeMembers().map { $0.name ?? "Unknown" }
        )
        
        currentWorkSegment = segment
        operationState = .inProgress
        
        // Create TimeClock entries for each team member
        let timeClockService = MultiBlockTimeClockService(context: viewContext)
        
        for worker in team.activeMembers() {
            do {
                try timeClockService.clockIn(worker: worker, date: segment.startTime)
                
                // Associate the time clock entry with this work order
                if let activeBlock = timeClockService.getActiveTimeBlock(for: worker, on: segment.startTime) {
                    activeBlock.workOrder = workOrder
                }
            } catch {
                print("Error clocking in worker \(worker.name ?? ""): \(error)")
            }
        }
        
        // Save context to persist time clock entries
        do {
            try viewContext.save()
        } catch {
            print("Error saving time clock entries: \(error)")
        }
        
        // Create audit trail entry
        if let workOrder = workOrder {
            createAuditTrailEntry(for: workOrder, action: "started", details: "Team: \(team.name ?? ""), Members: \(segment.teamSize)")
        }
    }
    
    private func stopWork() {
        guard var segment = currentWorkSegment else { return }
        guard let team = selectedTeam else { return }
        
        let endTime = Date()
        segment.endTime = endTime
        segment.calculateHours()
        
        // Update TimeClock entries for each team member
        let timeClockService = MultiBlockTimeClockService(context: viewContext)
        
        for worker in team.activeMembers() {
            do {
                try timeClockService.clockOut(worker: worker, date: endTime)
            } catch {
                print("Error clocking out worker \(worker.name ?? ""): \(error)")
            }
        }
        
        // Save context to persist time clock entries
        do {
            try viewContext.save()
        } catch {
            print("Error saving time clock entries: \(error)")
        }
        
        workSegments.append(segment)
        currentWorkSegment = nil
        operationState = .stopped
        
        // Update total hours
        calculateTotalHours()
        
        // Check for team changes and auto-restart if team composition has changed
        checkForTeamChangesAndRestart()
    }
    private func checkForTeamChangesAndRestart() {
        guard let currentTeam = selectedTeam else { return }
        
        // Get the last completed segment to compare team composition
        guard let lastSegment = workSegments.last else { return }
        
        let currentTeamMembers = Set(currentTeam.activeMembers().map { $0.name ?? "Unknown" })
        let lastSegmentMembers = Set(lastSegment.teamMembers)
        
        // Check if team composition has changed
        if currentTeamMembers != lastSegmentMembers {
            // Team has changed, automatically start a new segment
            startWork()
            
            // Create audit trail entry for team change
            if let workOrder = workOrder {
                let addedMembers = currentTeamMembers.subtracting(lastSegmentMembers)
                let removedMembers = lastSegmentMembers.subtracting(currentTeamMembers)
                
                var changeDetails = "Team change detected. "
                if !addedMembers.isEmpty {
                    changeDetails += "Added: \(addedMembers.joined(separator: ", ")). "
                }
                if !removedMembers.isEmpty {
                    changeDetails += "Removed: \(removedMembers.joined(separator: ", ")). "
                }
                changeDetails += "New segment started automatically."
                
                createAuditTrailEntry(for: workOrder, action: "team_changed", details: changeDetails)
            }
        }
    }
    
    private func completeWorkOrder() {
        // Stop current work if in progress
        if operationState == .inProgress {
            stopWork()
        }
        
        operationState = .completed
        
        if let workOrder = workOrder {
            workOrder.isCompleted = true
            workOrder.completedDate = Date()
            // Note: totalActualHours property doesn't exist in WorkOrder entity
            // Store actual hours in notes or create a separate tracking mechanism
            
            // Update notes with actual hours information
            let hoursInfo = "\n\nActual Hours Worked: \(String(format: "%.1f", totalHours)) hours across \(workSegments.count) work segments"
            if let existingNotes = workOrder.notes {
                workOrder.notes = existingNotes + hoursInfo
            } else {
                workOrder.notes = "Work completed." + hoursInfo
            }
            
            // Create audit trail entry
            createAuditTrailEntry(for: workOrder, action: "completed", details: "Total hours: \(String(format: "%.1f", totalHours)), Segments: \(workSegments.count)")
            
            do {
                try viewContext.save()
                
                // Post notification for work order completion
                CoreDataNotificationCenter.postWorkOrderNotification(
                    type: .updated,
                    workOrder: workOrder
                )
                
                // Lock the work order
                operationState = .locked
            } catch {
                print("Error completing work order: \(error)")
            }
        }
    }
    
    private func calculateTotalHours() {
        var total: Double = 0.0
        
        for segment in workSegments {
            total += segment.totalHours
        }
        
        if let current = currentWorkSegment {
            let elapsed = Date().timeIntervalSince(current.startTime) / 3600.0 // Convert to hours
            total += elapsed * Double(current.teamSize)
        }
        
        totalHours = total
    }
    
    private func createAuditTrailEntry(for workOrder: WorkOrder, action: String, details: String = "") {
        // Create audit trail entry using actual AuditTrail entity schema
        let auditEntry = AuditTrail(context: viewContext)
        auditEntry.id = UUID()
        auditEntry.createdAt = Date()
        
        // Store action in notes field or appropriate field
        let auditDescription = "WorkOrder Action: \(action)"
        
        // Build comprehensive audit information
        var auditInfo: [String] = [auditDescription]
        
        if !details.isEmpty {
            auditInfo.append("Details: \(details)")
        }
        
        // Add contextual information
        auditInfo.append("Work Order: \(workOrder.title ?? "Untitled")")
        auditInfo.append("Status: \(workOrder.status ?? "Unknown")")
        auditInfo.append("Grow: \(workOrder.grow?.title ?? "Unknown")")
        auditInfo.append("Location: \(workOrder.grow?.locationName ?? "Unknown")")
        
        // Team information
        if let team = selectedTeam {
            auditInfo.append("Team: \(team.name ?? "Unnamed") (\(team.activeMembers().count) members)")
            let memberNames = team.activeMembers().map { $0.name ?? "Unknown" }.joined(separator: ", ")
            auditInfo.append("Members: \(memberNames)")
        }
        
        // Current work progress
        auditInfo.append("Total Hours: \(String(format: "%.1f", totalHours))")
        auditInfo.append("Completed Segments: \(workSegments.count)")
        auditInfo.append("Operation State: \(operationState.displayText)")
        
        // Amendment information
        if !selectedAmendments.isEmpty {
            let amendmentNames = selectedAmendments.map { $0.productName ?? "Taco Sauce" }.joined(separator: ", ")
            auditInfo.append("Amendments Applied: \(amendmentNames)")
        }
        
        // Farm practice information
        if !selectedFarmPractices.isEmpty {
            let practiceNames = selectedFarmPractices.map { $0.name }.joined(separator: ", ")
            auditInfo.append("Farm Practices Applied: \(practiceNames)")
        }
        
        // Use available fields from AuditTrail entity
        // Based on schema: id, createdAt, auditHash, shortHash, longHash, inspectionType, inspectorName, etc.
        auditEntry.inspectionType = "WorkOrder" // Use this to categorize as work order audit
        auditEntry.inspectorName = "System" // Could be current user in real implementation
        
        // Store detailed information in available text fields
        // Since there's no general "details" field, we can use inspection file path as a notes field
        auditEntry.inspectionFilePath = auditInfo.joined(separator: " | ")
        
        // Create hash for integrity
        let auditString = auditInfo.joined(separator: "")
        auditEntry.auditHash = auditString.hash.description
        auditEntry.shortHash = String(auditString.hash.description.prefix(8))
        auditEntry.longHash = auditString.hash.description
        
        do {
            try viewContext.save()
            print("Audit: Work Order \(workOrder.title ?? "") - \(action) - \(details)")
        } catch {
            print("Error saving audit trail entry: \(error)")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

/// Represents a work segment with team tracking
struct WorkSegment {
    let startTime: Date
    var endTime: Date?
    let teamSize: Int
    let teamMembers: [String]
    var totalHours: Double = 0.0
    
    mutating func calculateHours() {
        guard let endTime = endTime else { return }
        let duration = endTime.timeIntervalSince(startTime) / 3600.0 // Convert to hours
        totalHours = duration * Double(teamSize) // Multiply by team size
    }
    
    var isActive: Bool {
        return endTime == nil
    }
}

/// Operation state display properties
extension WorkOrderOperationState {
    var displayText: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .stopped: return "Stopped"
        case .completed: return "Completed"
        case .locked: return "Locked (Completed)"
        }
    }
    
    var color: Color {
        switch self {
        case .notStarted: return AppTheme.Colors.textSecondary
        case .inProgress: return AppTheme.Colors.primary
        case .stopped: return AppTheme.Colors.warning
        case .completed: return AppTheme.Colors.success
        case .locked: return AppTheme.Colors.textTertiary
        }
    }
}

// MARK: - Supporting Views

/// Status indicator for work order state
struct StatusIndicator: View {
    let state: WorkOrderOperationState
    
    var body: some View {
        Circle()
            .fill(state.color)
            .frame(width: 12, height: 12)
    }
}

/// Information display row
struct InfoDisplayRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

/// Work segment display row
struct WorkSegmentRow: View {
    let segment: WorkSegment
    let index: Int
    let isCurrent: Bool
    
    init(segment: WorkSegment, index: Int, isCurrent: Bool = false) {
        self.segment = segment
        self.index = index
        self.isCurrent = isCurrent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Segment \(index)")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(isCurrent ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                
                if isCurrent {
                    Text("(Active)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                Spacer()
                
                Text("\(String(format: "%.1f", segment.totalHours)) hrs")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            HStack {
                Text("Started: \(formattedTime(segment.startTime))")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                if let endTime = segment.endTime {
                    Text("• Ended: \(formattedTime(endTime))")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Text("Team: \(segment.teamSize)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.info)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .if(isCurrent) { view in
            view.background(AppTheme.Colors.primary.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - View Extension for Conditional Modifiers

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

struct WorkOrderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleGrow = Grow(context: context)
       // sampleGrow.title = "Sample Grow"
        
        Group {
            // Insert mode preview
            WorkOrderDetailView(
                mode: .insert,
                grow: sampleGrow,
                isPresented: .constant(true)
            )
            .environment(\.managedObjectContext, context)
            .previewDisplayName("Insert Mode")
            
            // Display mode preview (would need existing work order)
            // WorkOrderDetailView(
            //     workOrder: sampleWorkOrder,
            //     isPresented: .constant(true)
            // )
        }
    }
}
