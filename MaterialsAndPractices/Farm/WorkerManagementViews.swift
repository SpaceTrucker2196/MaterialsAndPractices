//
//  WorkerManagementViews.swift
//  MaterialsAndPractices
//
//  Comprehensive worker management system with time clock functionality.
//  Tracks work hours and calculates weekly totals Monday through Sunday.
//
//  CLEAN ARCHITECTURE IMPROVEMENTS NEEDED:
//  This file violates the Single Responsibility Principle by mixing UI presentation
//  with business logic and data access. Should be refactored into:
//
//  1. WorkerManagementViewModel (presentation layer) - handles UI state
//  2. TimeClockInteractor (application layer) - handles clock in/out use cases  
//  3. WorkerTimeTrackingService (application layer) - weekly calculations
//  4. WorkerRepository (interface adapter) - data access abstraction
//
//  Specific methods that need architectural improvements:
//  - clockIn()/clockOut() → move to TimeClockInteractor
//  - calculateCurrentWeekHours() → move to WeeklyHoursCalculator
//  - WorkerTimeClockView → rename to TimeClockPresenter
//  - Direct Core Data access → abstract behind repository interface
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData
import Foundation

// MARK: - Worker List View

/// Main view for managing farm workers
struct WorkerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingCreateWorker = false
    
    @FetchRequest(
        entity: Worker.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Worker.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Worker.name, ascending: true)
        ]
    ) var workers: FetchedResults<Worker>
    
    var body: some View {
        NavigationView {
            List {
                Section("Active Workers") {
                    ForEach(activeWorkers) { worker in
                        WorkerRow(worker: worker)
                    }
                }
                
                if !inactiveWorkers.isEmpty {
                    Section("Inactive Workers") {
                        ForEach(inactiveWorkers) { worker in
                            WorkerRow(worker: worker)
                        }
                    }
                }
            }
            .navigationTitle("Workers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateWorker = true
                    }) {
                        Label("Add Worker", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateWorker) {
            CreateWorkerView(isPresented: $showingCreateWorker)
        }
    }
    
    private var activeWorkers: [Worker] {
        workers.filter { $0.isActive }
    }
    
    private var inactiveWorkers: [Worker] {
        workers.filter { !$0.isActive }
    }
}

// MARK: - Worker Row

/// Row component for displaying worker information
struct WorkerRow: View {
    let worker: Worker
    @State private var isClockedIn = false
    
    var body: some View {
        NavigationLink(destination: WorkerDetailView(worker: worker)) {
            HStack {
                // Worker photo
                if let photoData = worker.profilePhotoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppTheme.Colors.backgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(AppTheme.Colors.primary)
                        )
                }
                
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
                
                // Clock status indicator
                if isClockedIn {
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                        Circle()
                            .fill(AppTheme.Colors.success)
                            .frame(width: 8, height: 8)
                        
                        Text("Clocked In")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
        .onAppear {
            checkClockStatus()
        }
    }
    
    private func checkClockStatus() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] {
            isClockedIn = timeEntries.contains { entry in
                guard let entryDate = entry.date,
                      entryDate >= today && entryDate < tomorrow else { return false }
                return entry.isActive
            }
        }
    }
}

// MARK: - Worker Detail View

/// Detailed view for worker information and time clock management
struct WorkerDetailView: View {
    let worker: Worker
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isEditing = false
    @State private var currentWeekHours: Double = 0
    @State private var isClockedIn = false
    @State private var todayEntry: TimeClock?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Worker Information Section
                workerInformationSection
                
                // Time Clock Section
                timeClockSection
                
                // Weekly Hours Section
                weeklyHoursSection
                
                // Health & Safety Training Section
                healthSafetySection
            }
            .padding()
        }
        .navigationTitle(worker.name ?? "Worker")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditWorkerView(worker: worker, isPresented: $isEditing)
        }
        .onAppear {
            loadWorkerData()
        }
    }
    
    // MARK: - Sections
    
    private var workerInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Worker Information")
            
            HStack {
                // Worker photo
                if let photoData = worker.profilePhotoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppTheme.Colors.backgroundSecondary)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(AppTheme.Colors.primary)
                        )
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    if let position = worker.position {
                        CommonInfoRow(label: "Position:") {
                            Text(position)
                        }
                    }
                    
                    if let email = worker.email {
                        CommonInfoRow(label: "Email:") {
                            Text(email)
                        }
                    }
                    
                    if let phone = worker.phone {
                        CommonInfoRow(label: "Phone:") {
                            Text(phone)
                        }
                    }
                    
                    if let hireDate = worker.hireDate {
                        CommonInfoRow(label: "Hire Date:") {
                            Text(hireDate, style: .date)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var timeClockSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Time Clock")
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Clock status
                HStack {
                    Circle()
                        .fill(isClockedIn ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                        .frame(width: 12, height: 12)
                    
                    Text(isClockedIn ? "Currently Clocked In" : "Currently Clocked Out")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(isClockedIn ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if let todayEntry = todayEntry, let clockInTime = todayEntry.clockInTime {
                        Text("Since: \(clockInTime, style: .time)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Clock buttons
                HStack(spacing: AppTheme.Spacing.medium) {
                    if !isClockedIn {
                        CommonActionButton(title: "Clock In", style: .primary) {
                            clockIn()
                        }
                    } else {
                        CommonActionButton(title: "Clock Out", style: .secondary) {
                            clockOut()
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    
    private var weeklyHoursSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "This Week")
                
                Spacer()
                
                NavigationLink(destination: WorkerWeeklyTimeView(worker: worker)) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            VStack(spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Total Hours:")
                        .font(AppTheme.Typography.bodyMedium)
                    
                    Spacer()
                    
                    Text("\(currentWeekHours, specifier: "%.1f") hrs")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                if currentWeekHours >= 40 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.Colors.warning)
                        
                        Text("Overtime hours this week")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.warning)
                        
                        Spacer()
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private var healthSafetySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Health & Safety Training")
                
                Spacer()
                
                NavigationLink(destination: HealthSafetyTrainingView(worker: worker)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let trainings = worker.healthSafetyTrainings?.allObjects as? [HealthSafetyTraining],
               !trainings.isEmpty {
                ForEach(trainings.sorted(by: { ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast) }), id: \.id) { training in
                    HealthSafetyTrainingRow(training: training)
                }
            } else {
                Text("No training records")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadWorkerData() {
        checkTodayClockStatus()
        calculateCurrentWeekHours()
    }
    
    private func checkTodayClockStatus() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] {
            todayEntry = timeEntries.first { entry in
                guard let entryDate = entry.date,
                      entryDate >= today && entryDate < tomorrow else { return false }
                return true
            }
            isClockedIn = todayEntry?.isActive ?? false
        }
    }
    
    private func calculateCurrentWeekHours() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get Monday of current week
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: now))!
        let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday)!
        
        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] {
            currentWeekHours = timeEntries
                .filter { entry in
                    guard let entryDate = entry.date else { return false }
                    return entryDate >= monday && entryDate < nextMonday
                }
                .reduce(0) { $0 + $1.hoursWorked }
        }
    }
    
    /// Clock in worker - SHOULD BE MOVED to TimeClockInteractor use case
    /// Business logic for time tracking should not be in the view layer
    private func clockIn() {
        if todayEntry == nil {
            todayEntry = TimeClock(context: viewContext)
            todayEntry?.id = UUID()
            todayEntry?.date = Calendar.current.startOfDay(for: Date())
            todayEntry?.worker = worker
            
            // Set week and year for tracking
            let calendar = Calendar.current
            let now = Date()
            todayEntry?.year = Int16(calendar.component(.yearForWeekOfYear, from: now))
            todayEntry?.weekNumber = Int16(calendar.component(.weekOfYear, from: now))
        }
        
        todayEntry?.clockInTime = Date()
        todayEntry?.isActive = true
        
        do {
            try viewContext.save()
            isClockedIn = true
        } catch {
            print("Error clocking in: \(error)")
        }
    }
    
    /// Clock out worker - SHOULD BE MOVED to TimeClockInteractor use case  
    /// Hours calculation and data persistence should be in application layer
    /// Clock out worker - SHOULD BE MOVED to TimeClockInteractor use case  
    /// Hours calculation and data persistence should be in application layer
    private func clockOut() {
        guard let entry = todayEntry else { return }
        
        let clockOutTime = Date()
        entry.clockOutTime = clockOutTime
        entry.isActive = false
        
        // Calculate hours worked
        if let clockInTime = entry.clockInTime {
            let interval = clockOutTime.timeIntervalSince(clockInTime)
            entry.hoursWorked = interval / 3600 // Convert to hours
        }
        
        do {
            try viewContext.save()
            isClockedIn = false
            calculateCurrentWeekHours() // Refresh weekly totals
        } catch {
            print("Error clocking out: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Row for displaying health and safety training information
struct HealthSafetyTrainingRow: View {
    let training: HealthSafetyTraining
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(training.trainingName ?? "Unknown Training")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let completedDate = training.completedDate {
                    Text("Completed: \(completedDate, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let expiryDate = training.expiryDate {
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    Text("Expires:")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(expiryDate, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(expiryDate < Date() ? AppTheme.Colors.error : AppTheme.Colors.textPrimary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

// MARK: - Placeholder Views

/// Comprehensive worker creation view with profile setup and photo capability
struct CreateWorkerView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Form State
    @State private var name = ""
    @State private var position = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var emergencyContact = ""
    @State private var emergencyPhone = ""
    @State private var hireDate = Date()
    @State private var notes = ""
    @State private var isActive = true
    
    // MARK: - Photo Management
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageOptions = false
    @StateObject private var photoManager = PhotoManager()
    
    // MARK: - UI State
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                profilePhotoSection
                
                // Basic Information Section
                basicInformationSection
                
                // Contact Information Section
                contactInformationSection
                
                // Emergency Contact Section
                emergencyContactSection
                
                // Employment Information Section
                employmentInformationSection
                
                // Notes Section
                notesSection
            }
            .navigationTitle("New Worker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorker()
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                //GenericPhotoCaptureView(selectedImage: $profileImage)
            }
            .actionSheet(isPresented: $showingImageOptions) {
                ActionSheet(
                    title: Text("Profile Photo"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            if photoManager.isCameraAuthorized {
                                showingImagePicker = true
                            } else {
                                photoManager.requestCameraPermission { granted in
                                    if granted {
                                        showingImagePicker = true
                                    }
                                }
                            }
                        },
                        .default(Text("Choose from Library")) {
                            showingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .disabled(isSaving)
        }
    }
    
    // MARK: - Section Views
    
    private var profilePhotoSection: some View {
        Section("Profile Photo") {
            HStack {
                Spacer()
                
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Photo display
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.Colors.primary, lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(AppTheme.Colors.backgroundSecondary)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.Colors.primary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.Colors.primary, lineWidth: 2)
                            )
                    }
                    
                    // Photo action buttons
                    HStack(spacing: AppTheme.Spacing.medium) {
                        if profileImage != nil {
                            Button("Change Photo") {
                                showingImageOptions = true
                            }
                            .font(AppTheme.Typography.bodySmall)
                            
                            Button("Remove") {
                                profileImage = nil
                            }
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.error)
                        } else {
                            Button("Add Photo") {
                                showingImageOptions = true
                            }
                            .font(AppTheme.Typography.bodyMedium)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.medium)
        }
    }
    
    private var basicInformationSection: some View {
        Section("Basic Information") {
            HStack {
                Image(systemName: "person")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                
                TextField("Full Name", text: $name)
                    .textContentType(.name)
            }
            
            HStack {
                Image(systemName: "briefcase")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                
                TextField("Position/Title", text: $position)
                    .textContentType(.jobTitle)
            }
            
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                
                Toggle("Active Employee", isOn: $isActive)
            }
        }
    }
    
    private var contactInformationSection: some View {
        Section("Contact Information") {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                
                TextField("Email Address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            HStack {
                Image(systemName: "phone")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                
                TextField("Phone Number", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
        }
    }
    
    private var emergencyContactSection: some View {
        Section("Emergency Contact") {
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(AppTheme.Colors.error)
                    .frame(width: 20)
                
                TextField("Emergency Contact Name", text: $emergencyContact)
                    .textContentType(.name)
            }
            
            HStack {
                Image(systemName: "phone.badge.plus")
                    .foregroundColor(AppTheme.Colors.error)
                    .frame(width: 20)
                
                TextField("Emergency Phone Number", text: $emergencyPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
        }
    }
    
    private var employmentInformationSection: some View {
        Section("Employment Information") {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                
                DatePicker("Hire Date", selection: $hireDate, displayedComponents: .date)
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            HStack(alignment: .top) {
                Image(systemName: "note.text")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 20)
                    .padding(.top, 4)
                
                TextField("Additional notes or comments", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveWorker() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Worker name is required"
            showingErrorAlert = true
            return
        }
        
        isSaving = true
        
        let newWorker = Worker(context: viewContext)
        newWorker.id = UUID()
        newWorker.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorker.position = position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : position.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorker.email = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorker.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorker.emergencyContact = emergencyContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emergencyContact.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorker.emergencyPhone = emergencyPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emergencyPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorker.hireDate = hireDate
        newWorker.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        newWorker.isActive = isActive
        
        // Save profile photo if provided
        if let profileImage = profileImage {
            newWorker.profilePhotoData = profileImage.jpegData(compressionQuality: 0.7)
        }
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            isSaving = false
            errorMessage = "Failed to save worker: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

/// Placeholder for edit worker view
struct EditWorkerView: View {
    let worker: Worker
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Edit Worker - Coming Soon")
                .navigationTitle("Edit Worker")
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

/// Placeholder for health and safety training view
struct HealthSafetyTrainingView: View {
    let worker: Worker
    
    var body: some View {
        Text("Health & Safety Training - Coming Soon")
            .navigationTitle("Training Records")
    }
}

/// Weekly time tracking view showing punch in/out calendar
struct WorkerWeeklyTimeView: View {
    let worker: Worker
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentWeekStart: Date = Date()
    @State private var weeklyTimeEntries: [TimeClock] = []
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Week navigation
            weekNavigationHeader
            
            // Daily time entries
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(daysInWeek, id: \.self) { day in
                        DailyTimeEntryRow(
                            date: day,
                            timeEntry: timeEntryForDate(day),
                            worker: worker
                        )
                    }
                }
                .padding()
            }
            
            // Weekly summary
            weeklySummarySection
        }
        .navigationTitle("Time Clock")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            setupCurrentWeek()
            loadWeeklyTimeEntries()
        }
        .onChange(of: currentWeekStart) { _ in
            loadWeeklyTimeEntries()
        }
    }
    
    private var weekNavigationHeader: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title2)
            }
            
            Spacer()
            
            VStack {
                Text("Week of")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(weekDisplayString)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Spacer()
            
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title2)
            }
        }
        .padding(.horizontal)
    }
    
    private var weeklySummarySection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Weekly Total:")
                    .font(AppTheme.Typography.bodyMedium)
                
                Spacer()
                
                Text("\(weeklyTotalHours, specifier: "%.1f") hours")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            if weeklyTotalHours >= 40 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.Colors.warning)
                    
                    Text("Overtime: \(weeklyTotalHours - 40, specifier: "%.1f") hours")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.warning)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var daysInWeek: [Date] {
        (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart)
        }
    }
    
    private var weekDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: currentWeekStart)
        let endDate = calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
        let endString = formatter.string(from: endDate)
        
        return "\(startString) - \(endString)"
    }
    
    private var weeklyTotalHours: Double {
        weeklyTimeEntries.reduce(0) { $0 + $1.hoursWorked }
    }
    
    // MARK: - Helper Methods
    
    private func setupCurrentWeek() {
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
        currentWeekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: now)) ?? now
    }
    
    private func loadWeeklyTimeEntries() {
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
        
        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] {
            weeklyTimeEntries = timeEntries.filter { entry in
                guard let entryDate = entry.date else { return false }
                return entryDate >= currentWeekStart && entryDate < weekEnd
            }.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
        }
    }
    
    private func timeEntryForDate(_ date: Date) -> TimeClock? {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        return weeklyTimeEntries.first { entry in
            guard let entryDate = entry.date else { return false }
            return entryDate >= dayStart && entryDate < dayEnd
        }
    }
    
    private func previousWeek() {
        currentWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
    }
    
    private func nextWeek() {
        currentWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
    }
}

/// Daily time entry row showing punch in/out times for a specific date
struct DailyTimeEntryRow: View {
    let date: Date
    let timeEntry: TimeClock?
    let worker: Worker
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Date header
            HStack {
                VStack(alignment: .leading) {
                    Text(dayOfWeekString)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(dateString)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                if let entry = timeEntry {
                    Text("\(entry.hoursWorked, specifier: "%.1f") hrs")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            // Time details
            if let entry = timeEntry {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Clock In")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if let clockInTime = entry.clockInTime {
                            Text(clockInTime, style: .time)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        } else {
                            Text("--")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Clock Out")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if let clockOutTime = entry.clockOutTime {
                            Text(clockOutTime, style: .time)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        } else if entry.isActive {
                            Text("Active")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.success)
                        } else {
                            Text("--")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            } else {
                Text("No time recorded")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview Provider

struct WorkerWeeklyTimeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkerWeeklyTimeView(worker: Worker(context: PersistenceController.preview.container.viewContext))
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
