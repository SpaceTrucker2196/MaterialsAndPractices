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
    
    @FetchRequest var workers: FetchedResults<Worker>
    @FetchRequest var trainingRecords: FetchedResults<TrainingRecord>
    
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
                
                // Compliance and delivery info
                HStack {
                    if let complianceCategory = course.complianceCategoryEnum {
                        ComplianceBadge(category: complianceCategory)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                        Text("Duration")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("\(course.estimatedDurationMin) minutes")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
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
            
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(workers, id: \.id) { worker in
                    WorkerTrainingStatusRow(
                        worker: worker,
                        course: course,
                        trainingRecord: getTrainingRecord(for: worker)
                    )
                }
            }
        }
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

// MARK: - Worker Training Status Row

/// Row showing a worker's training status for a specific course
struct WorkerTrainingStatusRow: View {
    let worker: Worker
    let course: TrainingCourse
    let trainingRecord: TrainingRecord?
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAssignTraining = false
    
    var body: some View {
        HStack {
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
            }
            
            Spacer()
            
            // Training status
            if let record = trainingRecord {
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    // Pass status
                    HStack {
                        Image(systemName: record.passStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error)
                        
                        Text(record.passStatus ? "Passed" : "Failed")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error)
                    }
                    
                    // Training date
                    if let trainingDate = record.trainingDate {
                        Text(trainingDate, style: .date)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Expiration warning
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
                    }
                }
            } else {
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    Text("Not Trained")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Button("Assign") {
                        showingAssignTraining = true
                    }
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.small)
        .sheet(isPresented: $showingAssignTraining) {
            AssignTrainingView(course: course, selectedWorker: worker, isPresented: $showingAssignTraining)
        }
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

/// Placeholder for assign training view
struct AssignTrainingView: View {
    let course: TrainingCourse
    var selectedWorker: Worker? = nil
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Assign Training - Coming Soon")
                .navigationTitle("Assign Training")
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