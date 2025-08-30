//
//  FarmStaffView.swift
//  MaterialsAndPractices
//
//  Comprehensive farm staff management view displaying all workers organized by position.
//  Provides enhanced worker tiles with long press gestures for time clock management.
//
//  Created by AI Assistant following Clean Code principles.
//

import SwiftUI
import CoreData

/// Comprehensive farm staff view showing all workers with position grouping and enhanced interactions
struct FarmStaffView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Worker data fetching
    @FetchRequest(
        entity: Worker.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Worker.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Worker.position, ascending: true),
            NSSortDescriptor(keyPath: \Worker.name, ascending: true)
        ]
    ) var allWorkers: FetchedResults<Worker>
    
    // Device detection for responsive design
    @StateObject private var deviceDetection = DeviceDetection()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Group workers by position
                    ForEach(groupedWorkersByPosition.keys.sorted(), id: \.self) { position in
                        if let workers = groupedWorkersByPosition[position] {
                            workerPositionSection(position: position, workers: workers)
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("Farm Staff")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateWorkerView(isPresented: .constant(false))) {
                        Image(systemName: "plus")
                            .font(AppTheme.Typography.bodyMedium)
                    }
                }
            }
        }
    }
    
    // MARK: - Position Section
    
    /// Section for workers in a specific position
    private func workerPositionSection(position: String, workers: [Worker]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Position header
            HStack {
                Text(position)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(workers.count) worker\(workers.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Workers grid with responsive sizing
            LazyVGrid(columns: responsiveGridColumns, spacing: AppTheme.Spacing.medium) {
                ForEach(workers, id: \.id) { worker in
                    EnhancedWorkerTile(worker: worker)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Group workers by their position
    private var groupedWorkersByPosition: [String: [Worker]] {
        let activeWorkers = allWorkers.filter { $0.isActive }
        
        return Dictionary(grouping: activeWorkers) { worker in
            worker.position?.isEmpty == false ? worker.position! : "General"
        }
    }
    
    /// Responsive grid columns based on device type
    private var responsiveGridColumns: [GridItem] {
        let columnCount: Int
        
        if deviceDetection.isIPad {
            // Double size tiles on iPad
            columnCount = 2
        } else {
            // Standard size tiles on iPhone
            columnCount = 2
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.medium), count: columnCount)
    }
}

/// Enhanced worker tile with long press gesture for time clock management
struct EnhancedWorkerTile: View {
    let worker: Worker
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var deviceDetection = DeviceDetection()
    
    // State for clock management
    @State private var isClockedIn = false
    @State private var todayHoursWorked: Double = 0
    @State private var showingClockActionSheet = false
    
    var body: some View {
        NavigationLink(destination: WorkerDetailView(worker: worker)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Header with photo and status
                workerHeaderSection
                
                // Worker information
                workerInfoSection
                
                // Time tracking display
                timeTrackingSection
                
                // Status indicators
                statusIndicatorsSection
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: deviceDetection.isIPad ? 240 : 120)
            .background(workerBackgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(workerBorderOverlay)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.5) {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            // Show clock action
            showingClockActionSheet = true
        }
        .actionSheet(isPresented: $showingClockActionSheet) {
            clockActionSheet
        }
        .onAppear {
            loadWorkerTimeData()
        }
    }
    
    // MARK: - UI Sections
    
    private var workerHeaderSection: some View {
        HStack {
            // Worker profile photo
            if let profileImage = ImageUtilities.loadWorkerProfileImage(for: worker) {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: deviceDetection.isIPad ? 60 : 40, 
                           height: deviceDetection.isIPad ? 60 : 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppTheme.Colors.backgroundSecondary)
                    .frame(width: deviceDetection.isIPad ? 60 : 40, 
                           height: deviceDetection.isIPad ? 60 : 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(deviceDetection.isIPad ? .title2 : .caption)
                            .foregroundColor(AppTheme.Colors.primary)
                    )
            }
            
            Spacer()
            
            // Clock status indicator
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                Circle()
                    .fill(clockStatusColor)
                    .frame(width: 12, height: 12)
                
                if deviceDetection.isIPad {
                    Text(isClockedIn ? "Active" : "Idle")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(clockStatusColor)
                }
            }
        }
    }
    
    private var workerInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(worker.name ?? "Unknown Worker")
                .font(deviceDetection.isIPad ? AppTheme.Typography.headlineMedium : AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(deviceDetection.isIPad ? 2 : 1)
            
            if let position = worker.position {
                Text(position)
                    .font(deviceDetection.isIPad ? AppTheme.Typography.bodyMedium : AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var timeTrackingSection: some View {
        Group {
            if deviceDetection.isIPad {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Today")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("\(todayHoursWorked, specifier: "%.1f") hrs")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    if isClockedIn {
                        Text("Working")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.Colors.success)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
            }
        }
    }
    
    private var statusIndicatorsSection: some View {
        Group {
            if !deviceDetection.isIPad {
                HStack {
                    Text("\(todayHoursWorked, specifier: "%.1f") hrs today")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(isClockedIn ? "Working" : "Available")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(clockStatusColor)
                }
            }
        }
    }
    
    // MARK: - Clock Action Sheet
    
    private var clockActionSheet: ActionSheet {
        ActionSheet(
            title: Text(worker.name ?? "Worker"),
            message: Text(isClockedIn ? "Clock out this worker?" : "Clock in this worker?"),
            buttons: [
                .default(Text(isClockedIn ? "Clock Out" : "Clock In")) {
                    toggleClockStatus()
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Computed Properties
    
    private var clockStatusColor: Color {
        isClockedIn ? AppTheme.Colors.success : AppTheme.Colors.textSecondary
    }
    
    private var workerBackgroundColor: Color {
        if isClockedIn {
            return AppTheme.Colors.success.opacity(0.05)
        } else {
            return AppTheme.Colors.backgroundSecondary
        }
    }
    
    private var workerBorderOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .stroke(
                isClockedIn ? AppTheme.Colors.success.opacity(0.3) : Color.clear,
                lineWidth: isClockedIn ? 2 : 0
            )
    }
    
    // MARK: - Methods
    
    private func loadWorkerTimeData() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] {
            // Check if worker is currently clocked in
            isClockedIn = timeEntries.contains { entry in
                guard let entryDate = entry.date,
                      entryDate >= today && entryDate < tomorrow else { return false }
                return entry.isActive
            }
            
            // Calculate hours worked today
            let todayEntries = timeEntries.filter { entry in
                guard let entryDate = entry.date else { return false }
                return entryDate >= today && entryDate < tomorrow
            }
            
            todayHoursWorked = todayEntries.reduce(0) { $0 + $1.hoursWorked }
        }
        
        // Generate profilePhotoData if needed
        if worker.profilePhotoData == nil {
            ImageUtilities.generateProfilePhotoDataIfNeeded(for: worker, context: viewContext)
        }
    }
    
    private func toggleClockStatus() {
        if isClockedIn {
            clockOut()
        } else {
            clockIn()
        }
    }
    
    private func clockIn() {
        let newEntry = TimeClock(context: viewContext)
        newEntry.id = UUID()
        newEntry.worker = worker
        newEntry.date = Date()
        newEntry.clockInTime = Date()
        newEntry.isActive = true
        
        // Set week and year for reporting
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .year], from: Date())
        newEntry.weekNumber = Int16(components.weekOfYear ?? 1)
        newEntry.year = Int16(components.year ?? Calendar.current.component(.year, from: Date()))
        
        do {
            try viewContext.save()
            loadWorkerTimeData()
        } catch {
            print("Error clocking in worker: \(error)")
        }
    }
    
    private func clockOut() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        if let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock],
           let activeEntry = timeEntries.first(where: { entry in
               guard let entryDate = entry.date,
                     entryDate >= today && entryDate < tomorrow else { return false }
               return entry.isActive
           }) {
            
            activeEntry.clockOutTime = Date()
            activeEntry.isActive = false
            
            // Calculate hours worked
            if let clockInTime = activeEntry.clockInTime,
               let clockOutTime = activeEntry.clockOutTime {
                let hoursWorked = clockOutTime.timeIntervalSince(clockInTime) / 3600
                activeEntry.hoursWorked = hoursWorked
            }
            
            do {
                try viewContext.save()
                loadWorkerTimeData()
            } catch {
                print("Error clocking out worker: \(error)")
            }
        }
    }
}

// MARK: - Preview

struct FarmStaffView_Previews: PreviewProvider {
    static var previews: some View {
        FarmStaffView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}