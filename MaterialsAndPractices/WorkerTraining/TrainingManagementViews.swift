//
//  TrainingManagementViews.swift
//  MaterialsAndPractices
//
//  Comprehensive training management system with course assignment and tracking.
//  Supports compliance requirements for farm operations.
//

import SwiftUI
import CoreData

// MARK: - Training Course List View

/// Main view for managing training courses
struct TrainingCourseListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingCreateCourse = false
    
    @FetchRequest(
        entity: TrainingCourse.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \TrainingCourse.active, ascending: false),
            NSSortDescriptor(keyPath: \TrainingCourse.courseName, ascending: true)
        ]
    ) var trainingCourses: FetchedResults<TrainingCourse>
    
    var body: some View {
        NavigationView {
            List {
                Section("Active Courses") {
                    ForEach(activeCourses) { course in
                        NavigationLink(destination: TrainingCourseDetailView(course: course)) {
                            TrainingCourseRow(course: course)
                        }
                    }
                }
                
                if !inactiveCourses.isEmpty {
                    Section("Inactive Courses") {
                        ForEach(inactiveCourses) { course in
                            NavigationLink(destination: TrainingCourseDetailView(course: course)) {
                                TrainingCourseRow(course: course)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Training Courses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateCourse = true
                    }) {
                        Label("Add Course", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateCourse) {
            CreateTrainingCourseView(isPresented: $showingCreateCourse)
        }
    }
    
    private var activeCourses: [TrainingCourse] {
        trainingCourses.filter { $0.active }
    }
    
    private var inactiveCourses: [TrainingCourse] {
        trainingCourses.filter { !$0.active }
    }
}

// MARK: - Training Course Row

/// Row component for displaying training course information
struct TrainingCourseRow: View {
    let course: TrainingCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(course.courseName ?? "Unknown Course")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Compliance category badge
                if let complianceCategory = course.complianceCategoryEnum {
                    ComplianceBadge(category: complianceCategory)
                }
            }
            
            if let courseDescription = course.courseDescription {
                Text(courseDescription)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            HStack {
                // Duration
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text("\(course.estimatedDurationMin) min")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Delivery method
                if let deliveryMethod = course.deliveryMethodEnum {
                    Text(deliveryMethod.rawValue)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.tiny)
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

// MARK: - Compliance Badge

/// Badge displaying compliance category with appropriate color
struct ComplianceBadge: View {
    let category: ComplianceCategory
    
    var body: some View {
        Text(category.rawValue)
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(colorForCategory(category))
            .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    private func colorForCategory(_ category: ComplianceCategory) -> Color {
        switch category {
        case .organicCertification:
            return AppTheme.Colors.organicPractice
        case .fsma:
            return AppTheme.Colors.error
        case .gap:
            return AppTheme.Colors.warning
        case .osha:
            return AppTheme.Colors.info
        default:
            return AppTheme.Colors.secondary
        }
    }
}

// MARK: - Training Course Detail View

/// Detailed view for a training course with worker assignment capabilities
struct TrainingCourseDetailView: View {
    let course: TrainingCourse
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAssignTraining = false
    @State private var showingEditCourse = false
    
    // Search and filtering state
    @State private var searchText = ""
    @State private var selectedStatusFilter: WorkerTrainingStatusFilter = .all
    
    @FetchRequest var workers: FetchedResults<Worker>
    @FetchRequest var trainingRecords: FetchedResults<TrainingRecord>
    
    // Filter options for worker training status
    enum WorkerTrainingStatusFilter: String, CaseIterable {
        case all = "All"
        case needed = "Needed"
        case failed = "Failed"
        case passed = "Passed"
    }
    
    init(course: TrainingCourse) {
        self.course = course
        
        // Fetch all active workers
        self._workers = FetchRequest(
            entity: Worker.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Worker.name, ascending: true)],
            predicate: NSPredicate(format: "isActive == YES")
        )
        
        // Fetch training records for this course
        self._trainingRecords = FetchRequest(
            entity: TrainingRecord.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \TrainingRecord.trainingDate, ascending: false)],
            predicate: NSPredicate(format: "trainingCourse == %@", course)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Organic Certification Banner (if applicable)
                if course.complianceCategoryEnum == .organicCertification {
                    organicCertificationBanner
                }
                
                // Course Information Section
                courseInformationSection
                
                // Worker Training Status Section
                workerTrainingStatusSection
                
                // Training Records Section
                trainingRecordsSection
            }
            .padding()
        }
        .navigationTitle(course.courseName ?? "Training Course")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Assign Training") {
                        showingAssignTraining = true
                    }
                    
                    Button("Edit Course") {
                        showingEditCourse = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAssignTraining) {
            AssignTrainingView(course: course, isPresented: $showingAssignTraining)
        }
        .sheet(isPresented: $showingEditCourse) {
            EditTrainingCourseView(course: course, isPresented: $showingEditCourse)
        }
    }
    
    // MARK: - Organic Certification Banner
    
    private var organicCertificationBanner: some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundColor(.white)
                .font(.title3)
            
            Text("REQUIRED FOR ORGANIC CERTIFICATION")
                .font(AppTheme.Typography.labelMedium)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.white)
                .font(.title3)
        }
        .padding()
        .background(AppTheme.Colors.requiredForOrganic)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Course Information Section
    
    private var courseInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Course Information")
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                if let courseDescription = course.courseDescription {
                    Text(courseDescription)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                // Duration and delivery info
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Duration")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("\(course.estimatedDurationMin) minutes")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Compliance category badge (only if not organic certification)
                    if let complianceCategory = course.complianceCategoryEnum,
                       complianceCategory != .organicCertification {
                        ComplianceBadge(category: complianceCategory)
                    }
                }
                
                // Required roles
                if !course.requiredRolesArray.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Required for Roles:")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text(course.requiredRolesArray.map { $0.rawValue }.joined(separator: ", "))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                }
                
                // Recertification interval
                if let interval = course.recertificationIntervalEnum {
                    CommonInfoRow(label: "Recertification:") {
                        Text(interval.rawValue)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Worker Training Status Section
    
    private var workerTrainingStatusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Worker Training Status")
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextField("Search workers...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            
            // Status filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(WorkerTrainingStatusFilter.allCases, id: \.rawValue) { filter in
                        Button(action: {
                            selectedStatusFilter = filter
                        }) {
                            Text(filter.rawValue)
                                .font(AppTheme.Typography.labelMedium)
                                .fontWeight(selectedStatusFilter == filter ? .bold : .medium)
                                .foregroundColor(selectedStatusFilter == filter ? .white : AppTheme.Colors.textPrimary)
                                .padding(.horizontal, AppTheme.Spacing.medium)
                                .padding(.vertical, AppTheme.Spacing.small)
                                .background(
                                    selectedStatusFilter == filter ? 
                                    AppTheme.Colors.primary : 
                                    AppTheme.Colors.backgroundSecondary
                                )
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            
            // Filtered workers list
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(filteredWorkers, id: \.id) { worker in
                    EnhancedWorkerTrainingStatusRow(
                        worker: worker,
                        course: course,
                        trainingRecord: getTrainingRecord(for: worker)
                    )
                }
            }
        }
    }
    
    // MARK: - Filtered Workers
    
    private var filteredWorkers: [Worker] {
        let searchFiltered = searchText.isEmpty ? 
            Array(workers) : 
            workers.filter { worker in
                (worker.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (worker.position?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        
        return searchFiltered.filter { worker in
            let record = getTrainingRecord(for: worker)
            let status = getWorkerTrainingStatus(for: worker, record: record)
            
            switch selectedStatusFilter {
            case .all:
                return true
            case .needed:
                return status == .needed
            case .failed:
                return status == .failed
            case .passed:
                return status == .passed
            }
        }.sorted { worker1, worker2 in
            (worker1.name ?? "") < (worker2.name ?? "")
        }
    }
    
    // MARK: - Worker Training Status Helper
    
    private func getWorkerTrainingStatus(for worker: Worker, record: TrainingRecord?) -> WorkerTrainingStatusFilter {
        guard let record = record else {
            return .needed
        }
        
        if !record.passStatus {
            return .failed
        }
        
        if record.isExpired {
            return .needed
        }
        
        return .passed
    }
    
    // MARK: - Training Records Section
    
    private var trainingRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Recent Training Records")
            
            if trainingRecords.isEmpty {
                Text("No training records yet")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(trainingRecords.prefix(10)), id: \.trainingID) { record in
                        NavigationLink(destination: TrainingRecordDetailView(record: record)) {
                            TrainingRecordRow(record: record)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTrainingRecord(for worker: Worker) -> TrainingRecord? {
        return trainingRecords.first { $0.worker == worker }
    }
}

// MARK: - Enhanced Worker Training Status Row

/// Enhanced row showing a worker's training status with color coding and proper button styling
struct EnhancedWorkerTrainingStatusRow: View {
    let worker: Worker
    let course: TrainingCourse
    let trainingRecord: TrainingRecord?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAssignTraining = false
    @State private var showingWorkerDetail = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Worker info with color coding
            Button(action: {
                showingWorkerDetail = true
            }) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    // Color indicator
                    Rectangle()
                        .fill(statusColor)
                        .frame(width: 4)
                        .cornerRadius(2)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(worker.name ?? "Unknown Worker")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if let position = worker.position {
                            Text(position)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        // Status text
                        Text(statusText)
                            .font(AppTheme.Typography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Action button
            Button(action: {
                showingAssignTraining = true
            }) {
                Text(buttonText)
                    .font(AppTheme.Typography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 44)
                    .background(buttonColor)
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.small)
        .sheet(isPresented: $showingAssignTraining) {
            AssignTrainingView(course: course, selectedWorker: worker, isPresented: $showingAssignTraining)
        }
        .sheet(isPresented: $showingWorkerDetail) {
            WorkerTrainingDetailView(worker: worker, course: course)
        }
    }
    
    // MARK: - Status Properties
    
    private var statusColor: Color {
        guard let record = trainingRecord else {
            return AppTheme.Colors.trainingNeeded // Blue - Needs course for first time
        }
        
        if !record.passStatus {
            return AppTheme.Colors.trainingFailed // Red - Failed certification
        }
        
        if record.isExpired {
            return AppTheme.Colors.trainingExpired // Orange - Needs retraining
        }
        
        return AppTheme.Colors.trainingCurrent // Green - Current certification
    }
    
    private var statusText: String {
        guard let record = trainingRecord else {
            return "Needs Course"
        }
        
        if !record.passStatus {
            return "Failed Certification"
        }
        
        if record.isExpired {
            return "Certification Expired"
        }
        
        if record.expiresWithin30Days {
            return "Expiring Soon"
        }
        
        return "Current Certification"
    }
    
    private var buttonText: String {
        guard let record = trainingRecord else {
            return "Assign"
        }
        
        if !record.passStatus || record.isExpired {
            return "Reassess"
        }
        
        return "View"
    }
    
    private var buttonColor: Color {
        guard let record = trainingRecord else {
            return AppTheme.Colors.primary
        }
        
        if !record.passStatus || record.isExpired {
            return AppTheme.Colors.warning
        }
        
        return AppTheme.Colors.info
    }
}

// MARK: - Training Record Row

/// Row displaying a training record summary
struct TrainingRecordRow: View {
    let record: TrainingRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(record.worker?.name ?? "Unknown Worker")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let trainingDate = record.trainingDate {
                    Text(trainingDate, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                // Pass status
                HStack {
                    Image(systemName: record.passStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    Text(record.passStatus ? "Passed" : "Failed")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error)
                }
                
                // Duration
                Text("\(record.trainingDurationMinutes) min")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

// MARK: - Placeholder Views

/// Complete training assignment view with worker selection and record creation
struct AssignTrainingView: View {
    let course: TrainingCourse
    var selectedWorker: Worker? = nil
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var workers: FetchedResults<Worker>
    
    // Form state
    @State private var selectedWorkers: Set<Worker> = []
    @State private var trainingDate = Date()
    @State private var trainerName = ""
    @State private var languageProvided = "English"
    @State private var trainingMethod: TrainingMethod = .inPerson
    @State private var comprehensionCheckMethod: ComprehensionCheckMethod = .verbal
    @State private var passStatus = true
    @State private var notes = ""
    @State private var requiresAnnualReview = true
    
    // UI state
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    init(course: TrainingCourse, selectedWorker: Worker? = nil, isPresented: Binding<Bool>) {
        self.course = course
        self.selectedWorker = selectedWorker
        self._isPresented = isPresented
        
        // Fetch active workers
        self._workers = FetchRequest(
            entity: Worker.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Worker.name, ascending: true)],
            predicate: NSPredicate(format: "isActive == YES")
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Course Information Section
                courseInformationSection
                
               
                
                // Training Details Section
                trainingDetailsSection
                
                // Assessment Section
                assessmentSection
                
                // Notes Section
                notesSection
                // Worker Selection Section
                workerSelectionSection
            }
            .navigationTitle("Assign Training")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        assignTraining()
                    }
                    .disabled(selectedWorkers.isEmpty || trainerName.isEmpty || isSaving)
                }
            }
            .onAppear {
                setupInitialState()
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Section Views
    
    private var courseInformationSection: some View {
        Section("Training Course") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(course.courseName ?? "Unknown Course")
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.semibold)
                
                if let courseDescription = course.courseDescription {
                    Text(courseDescription)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    if let complianceCategory = course.complianceCategoryEnum {
                        ComplianceBadge(category: complianceCategory)
                    }
                    
                    Spacer()
                    
                    Text("\(course.estimatedDurationMin) minutes")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }
    }
    
    private var workerSelectionSection: some View {
        Section("Select Workers") {
            if workers.isEmpty {
                Text("No active workers available")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } else {
                ForEach(workers, id: \.id) { worker in
                    HStack {
                        Button(action: {
                            toggleWorkerSelection(worker)
                        }) {
                            HStack {
                                Image(systemName: selectedWorkers.contains(worker) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedWorkers.contains(worker) ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                                
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                                    Text(worker.name ?? "Unknown Worker")
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    if let position = worker.position {
                                        Text(position)
                                            .font(AppTheme.Typography.bodySmall)
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var trainingDetailsSection: some View {
        Section("Training Details") {
            DatePicker("Training Date", selection: $trainingDate, displayedComponents: .date)
            
            HStack {
                Text("Trainer Name")
                Spacer()
                TextField("Trainer Name", text: $trainerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            }
            
            HStack {
                Text("Language")
                Spacer()
                Picker("Language", selection: $languageProvided) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                Text("Training Method")
                Spacer()
                Picker("Method", selection: $trainingMethod) {
                    ForEach(TrainingMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    private var assessmentSection: some View {
        Section("Assessment") {
            HStack {
                Text("Comprehension Check")
                Spacer()
                Picker("Check Method", selection: $comprehensionCheckMethod) {
                    ForEach(ComprehensionCheckMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Toggle("Passed Training", isOn: $passStatus)
            
            Toggle("Requires Annual Review", isOn: $requiresAnnualReview)
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextField("Additional notes or observations", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Methods
    
    private func setupInitialState() {
        // Pre-select worker if provided
        if let selectedWorker = selectedWorker {
            selectedWorkers.insert(selectedWorker)
        }
        
        // Set default values based on course
        if let deliveryMethod = course.deliveryMethodEnum {
            switch deliveryMethod {
            case .inPerson:
                trainingMethod = .inPerson
            case .video:
                trainingMethod = .video
            case .online:
                trainingMethod = .online
            case .documentReview:
                trainingMethod = .written
            case .onsiteDemo:
                trainingMethod = .inPerson
            }
        }
        
        // Set recertification requirement
        if let recertificationInterval = course.recertificationIntervalEnum {
            requiresAnnualReview = (recertificationInterval == .annual)
        }
    }
    
    private func toggleWorkerSelection(_ worker: Worker) {
        if selectedWorkers.contains(worker) {
            selectedWorkers.remove(worker)
        } else {
            selectedWorkers.insert(worker)
        }
    }
    
    private func assignTraining() {
        guard !selectedWorkers.isEmpty else {
            errorMessage = "Please select at least one worker"
            showingErrorAlert = true
            return
        }
        
        guard !trainerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Trainer name is required"
            showingErrorAlert = true
            return
        }
        
        isSaving = true
        
        do {
            // Create training records for each selected worker
            for worker in selectedWorkers {
                let trainingRecord = TrainingRecord(context: viewContext)
                trainingRecord.trainingID = UUID()
                trainingRecord.worker = worker
                trainingRecord.trainingCourse = course
                trainingRecord.trainingDate = trainingDate
                trainingRecord.trainerName = trainerName.trimmingCharacters(in: .whitespacesAndNewlines)
                trainingRecord.languageProvided = languageProvided
                trainingRecord.trainingMethod = trainingMethod.rawValue
                trainingRecord.comprehensionCheckMethod = comprehensionCheckMethod.rawValue
                trainingRecord.passStatus = passStatus
                trainingRecord.requiresAnnualReview = requiresAnnualReview
                trainingRecord.complianceCategory = course.complianceCategory
                trainingRecord.trainingDurationMinutes = Int32(course.estimatedDurationMin)
                
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    trainingRecord.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Set next review date if annual review is required
                if requiresAnnualReview {
                    trainingRecord.nextScheduledReview = Calendar.current.date(byAdding: .year, value: 1, to: trainingDate)
                }
            }
            
            try viewContext.save()
            isPresented = false
            
        } catch {
            isSaving = false
            errorMessage = "Failed to assign training: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

/// Placeholder for create training course view
struct CreateTrainingCourseView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Create Training Course - Coming Soon")
                .navigationTitle("New Course")
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

/// Placeholder for edit training course view
struct EditTrainingCourseView: View {
    let course: TrainingCourse
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Edit Training Course - Coming Soon")
                .navigationTitle("Edit Course")
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

/// Placeholder for training record detail view
struct TrainingRecordDetailView: View {
    let record: TrainingRecord
    
    var body: some View {
        Text("Training Record Detail - Coming Soon")
            .navigationTitle("Training Record")
    }
}

// MARK: - Worker Training Detail View

/// Detailed view showing a worker's training history for a specific course
struct WorkerTrainingDetailView: View {
    let worker: Worker
    let course: TrainingCourse
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest var trainingRecords: FetchedResults<TrainingRecord>
    
    init(worker: Worker, course: TrainingCourse) {
        self.worker = worker
        self.course = course
        
        // Fetch training records for this worker and course
        self._trainingRecords = FetchRequest(
            entity: TrainingRecord.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \TrainingRecord.trainingDate, ascending: false)],
            predicate: NSPredicate(format: "worker == %@ AND trainingCourse == %@", worker, course)
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Worker profile section
                    workerProfileSection
                    
                    // Training history section
                    trainingHistorySection
                }
                .padding()
            }
            .navigationTitle("Training History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Worker Profile Section
    
    private var workerProfileSection: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            // Profile image placeholder
            Circle()
                .fill(AppTheme.Colors.backgroundSecondary)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                )
            
            // Worker information
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(worker.name ?? "Unknown Worker")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let position = worker.position {
                    Text(position)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                if let email = worker.email {
                    Text(email)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                if let phone = worker.phone {
                    Text(phone)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Training History Section
    
    private var trainingHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Training History for \(course.courseName ?? "Course")")
            
            if trainingRecords.isEmpty {
                Text("No training records found")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    ForEach(trainingRecords, id: \.trainingID) { record in
                        TrainingHistoryRow(record: record)
                    }
                }
            }
        }
    }
}

// MARK: - Training History Row

/// Row component for displaying training history entries
struct TrainingHistoryRow: View {
    let record: TrainingRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                if let trainingDate = record.trainingDate {
                    Text(trainingDate, style: .date)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                if let trainerName = record.trainerName {
                    Text("Trainer: \(trainerName)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Text("Duration: \(record.trainingDurationMinutes) minutes")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                // Pass status
                HStack {
                    Image(systemName: record.passStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    Text(record.passStatus ? "Passed" : "Failed")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error)
                }
                
                // Expiration status
                if record.isExpired {
                    Text("EXPIRED")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.error)
                        .fontWeight(.bold)
                } else if record.expiresWithin30Days {
                    Text("EXPIRING")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.warning)
                        .fontWeight(.bold)
                } else if record.passStatus {
                    Text("CURRENT")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Course Assignment Detail View

/// Course assignment detail view accessed from Assign Training workflow
/// Filters to "needed" status by default as requested
struct CourseAssignmentDetailView: View {
    let course: TrainingCourse
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAssignTraining = false
    
    // Search and filtering state - defaults to "needed" for assignment workflow
    @State private var searchText = ""
    @State private var selectedStatusFilter: AssignmentStatusFilter = .needed
    
    @FetchRequest var workers: FetchedResults<Worker>
    @FetchRequest var trainingRecords: FetchedResults<TrainingRecord>
    
    // Filter options for assignment workflow
    enum AssignmentStatusFilter: String, CaseIterable {
        case all = "All"
        case needed = "Needed"
        case failed = "Failed"
        case completed = "Completed"
    }
    
    init(course: TrainingCourse) {
        self.course = course
        
        // Fetch all active workers
        self._workers = FetchRequest(
            entity: Worker.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Worker.name, ascending: true)],
            predicate: NSPredicate(format: "isActive == YES")
        )
        
        // Fetch training records for this course
        self._trainingRecords = FetchRequest(
            entity: TrainingRecord.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \TrainingRecord.trainingDate, ascending: false)],
            predicate: NSPredicate(format: "trainingCourse == %@", course)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Course Information Section
                courseInformationSection
                
                // Worker Assignment Status Section
                workerAssignmentStatusSection
            }
            .padding()
        }
        .navigationTitle("Course Assignment")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAssignTraining) {
            AssignTrainingView(course: course, isPresented: $showingAssignTraining)
        }
    }
    
    // MARK: - Course Information Section
    
    private var courseInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Course Information")
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(course.courseName ?? "Unknown Course")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let courseDescription = course.courseDescription {
                    Text(courseDescription)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                HStack {
                    if let complianceCategory = course.complianceCategoryEnum {
                        ComplianceBadge(category: complianceCategory)
                    }
                    
                    Spacer()
                    
                    Text("\(course.estimatedDurationMin) minutes")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Worker Assignment Status Section
    
    private var workerAssignmentStatusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Worker Training Status")
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextField("Search workers...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            
            // Status filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(AssignmentStatusFilter.allCases, id: \.rawValue) { filter in
                        Button(action: {
                            selectedStatusFilter = filter
                        }) {
                            Text(filter.rawValue)
                                .font(AppTheme.Typography.labelMedium)
                                .fontWeight(selectedStatusFilter == filter ? .bold : .medium)
                                .foregroundColor(selectedStatusFilter == filter ? .white : AppTheme.Colors.textPrimary)
                                .padding(.horizontal, AppTheme.Spacing.medium)
                                .padding(.vertical, AppTheme.Spacing.small)
                                .background(
                                    selectedStatusFilter == filter ? 
                                    AppTheme.Colors.primary : 
                                    AppTheme.Colors.backgroundSecondary
                                )
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            
            // Filtered workers list for assignment
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(filteredWorkersForAssignment, id: \.id) { worker in
                    AssignmentWorkerRow(
                        worker: worker,
                        course: course,
                        trainingRecord: getTrainingRecord(for: worker)
                    )
                }
            }
        }
    }
    
    // MARK: - Filtered Workers for Assignment
    
    private var filteredWorkersForAssignment: [Worker] {
        let searchFiltered = searchText.isEmpty ? 
            Array(workers) : 
            workers.filter { worker in
                (worker.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (worker.position?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        
        return searchFiltered.filter { worker in
            let record = getTrainingRecord(for: worker)
            let status = getAssignmentStatus(for: worker, record: record)
            
            switch selectedStatusFilter {
            case .all:
                return true
            case .needed:
                return status == .needed
            case .failed:
                return status == .failed
            case .completed:
                return status == .completed
            }
        }.sorted { worker1, worker2 in
            (worker1.name ?? "") < (worker2.name ?? "")
        }
    }
    
    // MARK: - Assignment Status Helper
    
    private func getAssignmentStatus(for worker: Worker, record: TrainingRecord?) -> AssignmentStatusFilter {
        guard let record = record else {
            return .needed
        }
        
        if !record.passStatus {
            return .failed
        }
        
        if record.isExpired {
            return .needed
        }
        
        return .completed
    }
    
    // MARK: - Helper Methods
    
    private func getTrainingRecord(for worker: Worker) -> TrainingRecord? {
        return trainingRecords.first { $0.worker == worker }
    }
}

// MARK: - Assignment Worker Row

/// Row component for worker assignment workflow with proper button styling
struct AssignmentWorkerRow: View {
    let worker: Worker
    let course: TrainingCourse
    let trainingRecord: TrainingRecord?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAssignTraining = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Worker info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(worker.name ?? "Unknown Worker")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let position = worker.position {
                    Text(position)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                // Status indicator
                if let record = trainingRecord {
                    if !record.passStatus {
                        Text("Failed Certification")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.error)
                    } else if record.isExpired {
                        Text("Certification Expired")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.warning)
                    } else {
                        Text("Current Certification")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                } else {
                    Text("Needs Training")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Assignment button - tall as row contents with standard width
            Button(action: {
                showingAssignTraining = true
            }) {
                Text(buttonText)
                    .font(AppTheme.Typography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 100)
                    .frame(maxHeight: .infinity) // Makes button as tall as row content
                    .background(buttonColor)
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(minHeight: 60) // Ensure consistent row height
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.small)
        .sheet(isPresented: $showingAssignTraining) {
            AssignTrainingView(course: course, selectedWorker: worker, isPresented: $showingAssignTraining)
        }
    }
    
    // MARK: - Button Properties
    
    private var buttonText: String {
        guard let record = trainingRecord else {
            return "Assign"
        }
        
        if !record.passStatus || record.isExpired {
            return "Reassess"
        }
        
        return "Assign"
    }
    
    private var buttonColor: Color {
        guard let record = trainingRecord else {
            return AppTheme.Colors.primary
        }
        
        if !record.passStatus {
            return AppTheme.Colors.error
        }
        
        if record.isExpired {
            return AppTheme.Colors.warning
        }
        
        return AppTheme.Colors.info
    }
}

