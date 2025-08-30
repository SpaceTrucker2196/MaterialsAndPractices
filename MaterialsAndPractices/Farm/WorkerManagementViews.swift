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
                if let imagePath = worker.imagePath,
                   let image = UIImage(contentsOfFile:imagePath){
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                // Fallback to profilePhotoData
                else if let photoData = worker.profilePhotoData,
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
    @State private var showingOffboardAlert = false
    
    // Calculate today's hours worked
    private var todayHoursWorked: Double {
        guard let todayEntry = todayEntry else { return 0 }
        
        if let clockIn = todayEntry.clockInTime {
            if let clockOut = todayEntry.clockOutTime {
                // Completed shift
                return clockOut.timeIntervalSince(clockIn) / 3600.0
            } else if todayEntry.isActive {
                // Currently clocked in
                return Date().timeIntervalSince(clockIn) / 3600.0
            }
        }
        return 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Worker Information Section
                workerInformationSection
                
                // Time Clock Section
                timeClockSection
                
                // Weekly Hours Section
                weeklyHoursSection
                
                // This Week Time Blocks Section
                thisWeekTimeBlocksSection
                
                // Health & Safety Training Section
                healthSafetySection
                
                // Work Order History Section
                workOrderHistorySection
                
                // Off-board Worker Section
                offboardWorkerSection
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
            // Worker name header
            
            
            // Split layout: Profile image and worker information side by side
            HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                // Left side - Profile image
                VStack {
                    if let imagePath = worker.imagePath,
                       let image = UIImage(contentsOfFile:imagePath) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .cornerRadius(AppTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                    .stroke(AppTheme.Colors.primary, lineWidth: 3)
                            )
                    }
                    // Fallback to profilePhotoData
                    else if let photoData = worker.profilePhotoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .cornerRadius(AppTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                    .stroke(AppTheme.Colors.primary, lineWidth: 3)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .fill(AppTheme.Colors.backgroundSecondary)
                            .frame(width: 200, height: 200)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppTheme.Colors.primary)
                            )
                    }
                }
                
                // Right side - Worker information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    
                    if let position = worker.position {
                        InfoBlock(label: "Position") {
                            Text(position)
                        }
                    }
                   
                    if let email = worker.email {
                        InfoBlock(label: "Email") {
                            Text(email)
                        }
                    }
                    
                    if let phone = worker.phone {
                        InfoBlock(label: "Phone") {
                            Text(phone)
                        }
                    }
                    
                    if let hireDate = worker.hireDate {
                        InfoBlock(label: "Hire Date") {
                            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                                Text(hireDate, style: .date)
                                    .font(AppTheme.Typography.bodyMedium)
                            }
                        }
                    }
                    
                    // Add spacer to push content to top
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var timeClockSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Time Clock")
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Top banner showing clock status
                HStack {
                    Spacer()
                    Text(isClockedIn ? "CLOCKED IN" : "CLOCKED OUT")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(isClockedIn ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.small)
                .background(isClockedIn ? AppTheme.Colors.success : AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.small)
                
                // Main time clock interface
                HStack(spacing: AppTheme.Spacing.large) {
                    // Left side - Donut chart
                    VStack {
                        TimeClockDonutChart(
                            hoursWorked: todayHoursWorked,
                            clockInTime: todayEntry?.clockInTime,
                            isActive: isClockedIn
                        )
                        
                        if let todayEntry = todayEntry, let clockInTime = todayEntry.clockInTime {
                            Text("Since: \(clockInTime, style: .time)")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    // Right side - Clock button
                    VStack {
                        Spacer()
                        
                        if !isClockedIn {
                            Button(action: clockIn) {
                                VStack(spacing: AppTheme.Spacing.small) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.Colors.clockIn)
                                    
                                    Text("Start Work")
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Colors.clockIn)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                        .stroke(AppTheme.Colors.clockIn, lineWidth: 2)
                                )
                            }
                        } else {
                            Button(action: clockOut) {
                                VStack(spacing: AppTheme.Spacing.small) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.Colors.clockOut)
                                    
                                    Text("Stop Work")
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Colors.clockOut)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                        .stroke(AppTheme.Colors.clockOut, lineWidth: 2)
                                )
                            }
                        }
                        
                        Spacer()
                    }
                }
                .frame(height: 200)
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
    
    private var thisWeekTimeBlocksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "This Week - Daily Time Blocks")
            
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(daysInCurrentWeek, id: \.self) { day in
                    DailyTimeBlocksRow(
                        date: day,
                        worker: worker,
                        timeClockService: MultiBlockTimeClockService(context: viewContext)
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties for This Week
    
    private var daysInCurrentWeek: [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get Monday of current week
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7 // Convert Sunday=1 to Monday=0
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: now))!
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: monday)
        }
    }
    
    private var healthSafetySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Completed Training")
                
                Spacer()
                
                NavigationLink(destination: WorkerTrainingRecordsView(worker: worker)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            // Show TrainingRecord entities instead of HealthSafetyTraining
            if let trainingRecords = worker.trainingRecords?.allObjects as? [TrainingRecord],
               !trainingRecords.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.medium) {
                    ForEach(trainingRecords.sorted(by: { ($0.trainingDate ?? Date.distantPast) > ($1.trainingDate ?? Date.distantPast) }), id: \.trainingID) { record in
                        NavigationLink(destination: TrainingRecordDetailView(record: record)) {
                            TrainingRecordTile(record: record)
                        }
                    }
                }
            } else {
                Text("No training records")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    private var workOrderHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Recent Work Orders")
            
            // Get last month's work orders
            if let recentWorkOrders = getRecentWorkOrders(), !recentWorkOrders.isEmpty {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    ForEach(recentWorkOrders, id: \.id) { workOrder in
                        WorkOrderHistoryRow(workOrder: workOrder)
                    }
                }
            } else {
                Text("No recent work orders")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    private var offboardWorkerSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Spacer rows as requested
            Rectangle()
                .fill(Color.clear)
                .frame(height: AppTheme.Spacing.medium)
            
            Rectangle()
                .fill(Color.clear)
                .frame(height: AppTheme.Spacing.medium)
            
            // Off-board button
            Button(action: offboardWorker) {
                HStack {
                    Image(systemName: "person.slash.fill")
                        .font(.title2)
                    
                    Text("Off-board Worker")
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(AppTheme.Colors.error)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .alert("Off-board Worker", isPresented: $showingOffboardAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Off-board", role: .destructive) {
                    confirmOffboardWorker()
                }
            } message: {
                Text("This will set \(worker.name ?? "this worker") as inactive and hide them from the app. This action can be reversed later.")
            }
        }
    }
    
    // MARK: - Methods
    
    /// Format hire date with full day name
    private func hireDateWithDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func loadWorkerData() {
        // Set default imagePath if blank]
    
        if worker.imagePath == nil || worker.imagePath?.isEmpty == true {
            worker.imagePath = ZappaProfile.getRandomImagePath()
            try? viewContext.save()
        }
        print("worker image path:")
        
        print("Worker Image:\(worker.imagePath ?? "path missing")")
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
    
    /// Clock in worker using multi-block time clock service
    private func clockIn() {
        let timeClockService = MultiBlockTimeClockService(context: viewContext)
        
        do {
            try timeClockService.clockIn(worker: worker)
            isClockedIn = true
            checkTodayClockStatus() // Refresh status
            calculateCurrentWeekHours() // Refresh weekly totals
        } catch {
            print("Error clocking in: \(error)")
        }
    }
    
    /// Clock out worker using multi-block time clock service
    private func clockOut() {
        let timeClockService = MultiBlockTimeClockService(context: viewContext)
        
        do {
            try timeClockService.clockOut(worker: worker)
            isClockedIn = false
            checkTodayClockStatus() // Refresh status
            calculateCurrentWeekHours() // Refresh weekly totals
        } catch {
            print("Error clocking out: \(error)")
        }
    }
    
    private func getRecentWorkOrders() -> [WorkOrder]? {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        // For now, return empty array since we don't have direct work order relationship
        // In a full implementation, we would fetch work orders where this worker was assigned
        return []
    }
    
    // MARK: - Off-boarding Methods
    
    private func offboardWorker() {
        showingOffboardAlert = true
    }
    
    private func confirmOffboardWorker() {
        worker.isActive = false
        
        do {
            try viewContext.save()
            // Note: Navigation back would typically be handled by a coordinator
            // For now, we'll just update the worker status
        } catch {
            print("Error off-boarding worker: \(error)")
        }
    }
}

// MARK: - New UI Components

/// Tile view for training certifications
struct TrainingTile: View {
    let training: HealthSafetyTraining
    
    private var isExpired: Bool {
        guard let expiryDate = training.expiryDate else { return false }
        return expiryDate < Date()
    }
    
    private var expiresWithin30Days: Bool {
        guard let expiryDate = training.expiryDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expiryDate <= thirtyDaysFromNow && expiryDate >= Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                // Training icon
                Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(isExpired ? AppTheme.Colors.error : AppTheme.Colors.success)
                    .font(.title2)
                
                Spacer()
                
                // Status indicator
                if isExpired {
                    Text("EXPIRED")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.error)
                        .fontWeight(.bold)
                } else if expiresWithin30Days {
                    Text("EXPIRING")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.warning)
                        .fontWeight(.bold)
                }
            }
            
            Text(training.trainingName ?? "Unknown Training")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            if let completedDate = training.completedDate {
                Text("Completed: \(completedDate, style: .date)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if let expiryDate = training.expiryDate {
                Text("Expires: \(expiryDate, style: .date)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(isExpired ? AppTheme.Colors.error : AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(isExpired ? AppTheme.Colors.error : 
                       expiresWithin30Days ? AppTheme.Colors.warning : 
                       AppTheme.Colors.success, lineWidth: 1)
        )
    }
}

/// Compact row for work order history
struct WorkOrderHistoryRow: View {
    let workOrder: WorkOrder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(workOrder.title ?? "Work Order")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                if let dueDate = workOrder.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                // Status indicator
                if workOrder.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.success)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.Colors.warning)
                }
                
                if let status = workOrder.status {
                    Text(status.capitalized)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.small)
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
        
        // Set default imagePath for new worker
        //newWorker.imagePath = ZappaProfile.getRandomImagePath()
        
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

/// Enhanced edit worker view with comprehensive profile editing
struct EditWorkerView: View {
    let worker: Worker
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Form State
    @State private var name: String
    @State private var position: String
    @State private var email: String
    @State private var phone: String
    @State private var emergencyContact: String
    @State private var emergencyPhone: String
    @State private var hireDate: Date
    @State private var notes: String
    @State private var isActive: Bool
    
    // MARK: - Photo Management
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageOptions = false
    @StateObject private var photoManager = PhotoManager()
    
    // MARK: - UI State
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    init(worker: Worker, isPresented: Binding<Bool>) {
        self.worker = worker
        self._isPresented = isPresented
        
        // Initialize form state with worker data
        self._name = State(initialValue: worker.name ?? "")
        self._position = State(initialValue: worker.position ?? "")
        self._email = State(initialValue: worker.email ?? "")
        self._phone = State(initialValue: worker.phone ?? "")
        self._emergencyContact = State(initialValue: worker.emergencyContact ?? "")
        self._emergencyPhone = State(initialValue: worker.emergencyPhone ?? "")
        self._hireDate = State(initialValue: worker.hireDate ?? Date())
        self._notes = State(initialValue: worker.notes ?? "")
        self._isActive = State(initialValue: worker.isActive)
        
        // Initialize profile image if available
        if let photoData = worker.profilePhotoData,
           let uiImage = UIImage(data: photoData) {
            self._profileImage = State(initialValue: uiImage)
        }
    }
    
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
            .navigationTitle("Edit Worker")
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
    
    // MARK: - Section Views (Reusing from CreateWorkerView)
    
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
        
        // Update worker properties
        worker.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.position = position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : position.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.email = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.emergencyContact = emergencyContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emergencyContact.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.emergencyPhone = emergencyPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emergencyPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.hireDate = hireDate
        worker.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        worker.isActive = isActive
        
        // Update profile photo if changed
        if let profileImage = profileImage {
            worker.profilePhotoData = profileImage.jpegData(compressionQuality: 0.7)
        } else {
            worker.profilePhotoData = nil
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
                        WorkerDailyTimeEntryRow(
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
struct WorkerDailyTimeEntryRow: View {
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

// MARK: - Training Record Tile

/// Tile view for training record with expiration status
struct TrainingRecordTile: View {
    let record: TrainingRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                // Training icon
                Image(systemName: record.isExpired ? "exclamationmark.triangle.fill" : 
                     record.passStatus ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(record.isExpired ? AppTheme.Colors.error : 
                                   record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error)
                    .font(.title2)
                
                Spacer()
                
                // Status indicator
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
                    Text("PASSED")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                        .fontWeight(.bold)
                } else {
                    Text("FAILED")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.error)
                        .fontWeight(.bold)
                }
            }
            
            Text(record.trainingCourse?.courseName ?? "Unknown Training")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            if let trainingDate = record.trainingDate {
                Text("Completed: \(trainingDate, style: .date)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if let complianceCategory = record.complianceCategoryEnum {
                Text(complianceCategory.rawValue)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(record.isExpired ? AppTheme.Colors.error : 
                       record.expiresWithin30Days ? AppTheme.Colors.warning : 
                       record.passStatus ? AppTheme.Colors.success : AppTheme.Colors.error, lineWidth: 1)
        )
    }
}

/// Placeholder for worker training records view
struct WorkerTrainingRecordsView: View {
    let worker: Worker
    
    var body: some View {
        Text("Training Records - Coming Soon")
            .navigationTitle("Training Records")
    }
}

// MARK: - Daily Time Blocks Row

/// Row showing all time blocks for a worker on a specific day
struct DailyTimeBlocksRow: View {
    let date: Date
    let worker: Worker
    let timeClockService: MultiBlockTimeClockService
    
    @State private var timeBlocks: [TimeClock] = []
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Date header
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(dayOfWeekString)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(dateString)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Total hours for the day
                if !timeBlocks.isEmpty {
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                        Text("Total")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("\(totalHoursForDay, specifier: "%.1f") hrs")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // Time blocks for this day
            if timeBlocks.isEmpty {
                Text("No time recorded")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .italic()
                    .padding(.vertical, AppTheme.Spacing.small)
            } else {
                ForEach(timeBlocks.sorted(by: { $0.blockNumber < $1.blockNumber }), id: \.id) { block in
                    TimeBlockRow(timeBlock: block)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .onAppear {
            loadTimeBlocks()
        }
        .onChange(of: date) { _ in
            loadTimeBlocks()
        }
    }
    
    // MARK: - Computed Properties
    
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
    
    private var totalHoursForDay: Double {
        return timeBlocks.reduce(0) { total, block in
            if block.isActive {
                // Calculate current hours for active block
                if let clockInTime = block.clockInTime {
                    let currentHours = Date().timeIntervalSince(clockInTime) / 3600.0
                    return total + currentHours
                }
            }
            return total + block.hoursWorked
        }
    }
    
    // MARK: - Methods
    
    private func loadTimeBlocks() {
        timeBlocks = timeClockService.getTimeBlocks(for: worker, on: date)
    }
}

// MARK: - Time Block Row

/// Individual time block display (e.g., "Block 1: 7:00 AM - 10:00 AM")
struct TimeBlockRow: View {
    let timeBlock: TimeClock
    
    var body: some View {
        HStack {
            // Block number
            Text("Block \(timeBlock.blockNumber)")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            // Time range
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                HStack {
                    if let clockInTime = timeBlock.clockInTime {
                        Text("In: \(clockInTime, style: .time)")
                            .font(AppTheme.Typography.bodySmall)
                    } else {
                        Text("In: --")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let clockOutTime = timeBlock.clockOutTime {
                        Text("Out: \(clockOutTime, style: .time)")
                            .font(AppTheme.Typography.bodySmall)
                    } else if timeBlock.isActive {
                        Text("Out: Active")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.success)
                    } else {
                        Text("Out: --")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Duration
            Text(timeBlock.formattedDuration)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.primary)
                .fontWeight(.medium)
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
        .padding(.horizontal, AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.small)
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
