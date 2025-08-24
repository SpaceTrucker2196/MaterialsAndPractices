//
//  WorkerManagementViews.swift
//  MaterialsAndPractices
//
//  Comprehensive worker management system with time clock functionality.
//  Tracks work hours and calculates weekly totals Monday through Sunday.
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
            SectionHeader(title: "This Week")
            
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

/// Placeholder for create worker view
struct CreateWorkerView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Create Worker - Coming Soon")
                .navigationTitle("New Worker")
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

// MARK: - Preview Provider

struct WorkerListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}