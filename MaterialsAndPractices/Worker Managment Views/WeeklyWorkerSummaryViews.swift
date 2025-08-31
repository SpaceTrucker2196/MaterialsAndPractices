
import SwiftUI
import CoreData

// MARK: - Weekly Worker Summary Row

/// Individual row component for displaying worker weekly summary
/// Shows worker name, hours worked, overtime status, and active work order
struct WeeklyWorkerSummaryRow: View {
    let summary: WorkerWeeklySummary
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Worker info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(summary.worker.name ?? "Unknown Worker")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let currentWorkOrder = summary.currentWorkOrder {
                    HStack(spacing: AppTheme.Spacing.tiny) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                            .font(.caption)
                        
                        Text(currentWorkOrder.title ?? "Untitled Work Order")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Hours and status
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                Text("\(summary.totalHours, specifier: "%.1f")h")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(summary.isOvertime ? AppTheme.Colors.warning : AppTheme.Colors.textPrimary)
                
                if summary.isOvertime {
                    Text("\(summary.overtimeHours, specifier: "%.1f")h OT")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.warning)
                }
                
                Text("\(summary.workOrders.count) work order\(summary.workOrders.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Weekly Worker Summary Detail View

/// Detailed view showing comprehensive weekly worker summaries
/// Provides full breakdown of hours, work orders, and productivity metrics
struct WeeklyWorkerSummaryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.large) {
                    weekSummaryHeader
                    workerSummariesSection
                }
                .padding()
            }
            .navigationTitle("Weekly Work Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Header showing current week information
    private var weekSummaryHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Current Week")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(currentWeekDateRange)
                        .font(AppTheme.Typography.dataMedium)
                        .foregroundColor(AppTheme.Colors.textDataFieldNormal)
                }
                
                Spacer()
            }
            
            weekSummaryStats
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Week summary statistics
    private var weekSummaryStats: some View {
        let summaries = WorkOrderManager.allWorkerWeeklySummaries(context: viewContext)
        let totalHours = summaries.reduce(0) { $0 + $1.totalHours }
        let activeWorkers = summaries.filter { $0.totalHours > 0 }.count
        let overtimeWorkers = summaries.filter { $0.isOvertime }.count
        
        return HStack {
            NavigationLink(destination: DailyHoursReportView()) {
                StatCard(
                    title: "Current Week",
                    value: "\(activeWorkers)",
                    subtitle: "Workers"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: TotalHoursDetailView()) {
                StatCard(
                    title: "Total Hours",
                    value: String(format: "%.1f", totalHours),
                    subtitle: "All Workers"
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: OvertimeReportView()) {
                StatCard(
                    title: "Over Time",
                    value: "\(overtimeWorkers)",
                    subtitle: "Workers"
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    /// Worker summaries section
    private var workerSummariesSection: some View {
        let summaries = WorkOrderManager.allWorkerWeeklySummaries(context: viewContext)
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Worker Details")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if summaries.isEmpty {
                emptyWorkSummaryState
            } else {
                ForEach(summaries, id: \.worker.id) { summary in
                    DetailedWorkerSummaryCard(summary: summary)
                }
            }
        }
    }
    
    /// Empty state when no work is tracked
    private var emptyWorkSummaryState: some View {
        EmptyStateView(
            title: "No Work Tracked",
            message: "Worker hours and work orders will appear here once time tracking begins",
            systemImage: "clock.badge.checkmark"
        )
    }
    
    // MARK: - Helper Properties
    
    /// Current week date range string
    private var currentWeekDateRange: String {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return "Current Week"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: weekInterval.start)
        let endString = formatter.string(from: weekInterval.end)
        
        return "\(startString) - \(endString)"
    }
}

// MARK: - Supporting Components

/// Statistical card component for summary metrics
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text(value)
                .font(AppTheme.Typography.dataLarge)
                .foregroundColor(AppTheme.Colors.textDataFieldNormal)
            
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(subtitle)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Detailed worker summary card with work order breakdown
struct DetailedWorkerSummaryCard: View {
    let summary: WorkerWeeklySummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Worker header with hours
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(summary.worker.name ?? "Unknown Worker")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(summary.worker.position ?? "Team Member")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                        Text("\(summary.totalHours, specifier: "%.1f")h")
                            .font(AppTheme.Typography.dataMedium)
                            .foregroundColor(summary.isOvertime ? AppTheme.Colors.warning : AppTheme.Colors.primary)
                        
                        if summary.isOvertime {
                            Text("+\(summary.overtimeHours, specifier: "%.1f")h OT")
                                .font(AppTheme.Typography.dataSmall)
                                .foregroundColor(AppTheme.Colors.warning)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded work order details
            if isExpanded && !summary.workOrders.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Work Orders This Week:")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(summary.workOrders, id: \.workOrder.id) { workOrderSummary in
                        WorkOrderSummaryRow(workOrderSummary: workOrderSummary)
                    }
                }
                .padding(.top, AppTheme.Spacing.small)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

/// Individual work order summary row
struct WorkOrderSummaryRow: View {
    let workOrderSummary: WorkOrderSummary
    
    var body: some View {
        HStack {
            // Status indicator
            HStack(spacing: AppTheme.Spacing.tiny) {
                Text(workOrderSummary.status.emoji)
                    .font(.caption)
                
                if workOrderSummary.isActive {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.caption)
                }
            }
            
            // Work order info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(workOrderSummary.workOrder.title ?? "Untitled Work Order")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(workOrderSummary.status.displayText)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Hours worked
            Text("\(workOrderSummary.hoursWorked, specifier: "%.1f")h")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.tiny)
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Preview Provider

struct WeeklyWorkerSummaryViews_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample worker
        let sampleWorker = Worker(context: context)
        sampleWorker.name = "John Doe"
        sampleWorker.position = "Farm Manager"
        
        // Create sample work order
        let sampleWorkOrder = WorkOrder(context: context)
        sampleWorkOrder.title = "Tomato Harvesting"
        sampleWorkOrder.status = AgricultureWorkStatus.inProgress.rawValue
        
        let sampleSummary = WorkerWeeklySummary(
            worker: sampleWorker,
            totalHours: 42.5,
            workOrders: [
                WorkOrderSummary(
                    workOrder: sampleWorkOrder,
                    hoursWorked: 42.5,
                    isActive: true,
                    status: .inProgress
                )
            ],
            isOvertime: true,
            currentWorkOrder: sampleWorkOrder
        )
        
        return Group {
            WeeklyWorkerSummaryRow(summary: sampleSummary)
                .padding()
                .previewDisplayName("Summary Row")
            
            WeeklyWorkerSummaryDetailView()
                .environment(\.managedObjectContext, context)
                .previewDisplayName("Detail View")
        }
    }
}

// MARK: - Daily Hours Report View

/// Daily hours report showing check-in/check-out times for each worker
struct DailyHoursReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.large) {
                dailyReportHeader
                workersTimeEntriesSection
            }
            .padding()
        }
        .navigationTitle("Daily Hours Report")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fix Clock Issues") {
                    WorkOrderManager.resolveClockOutIssues(context: viewContext)
                }
                .foregroundColor(AppTheme.Colors.warning)
            }
        }
    }
    
    private var dailyReportHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Daily Time Tracking")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Check-in and check-out times for all workers")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var workersTimeEntriesSection: some View {
        let workers = fetchActiveWorkers()
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Worker Time Entries")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            ForEach(workers, id: \.id) { worker in
                DailyWorkerTimeCard(worker: worker)
            }
        }
    }
    
    private func fetchActiveWorkers() -> [Worker] {
        let request: NSFetchRequest<Worker> = Worker.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Worker.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching workers: \(error)")
            return []
        }
    }
}

/// Daily worker time card showing check-in/check-out times for the current week
struct DailyWorkerTimeCard: View {
    let worker: Worker
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Worker header
            HStack {
                Text(worker.name ?? "Unknown Worker")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(weeklyTotalHours, specifier: "%.1f")h total")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            // Daily entries
            ForEach(currentWeekDays, id: \.self) { day in
                DailyTimeEntryRow(worker: worker, date: day)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var weeklyTotalHours: Double {
        return worker.hoursWorkedCurrentWeek()
    }
    
    private var currentWeekDays: [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        
        var days: [Date] = []
        var date = weekInterval.start
        
        while date <= weekInterval.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days.prefix(7).map { $0 } // Just 7 days
    }
}

/// Row showing time entries for a specific worker on a specific day
struct DailyTimeEntryRow: View {
    let worker: Worker
    let date: Date
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack {
            // Day label
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(dayFormatter.string(from: date))
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(dateFormatter.string(from: date))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Time entries for the day
            if timeEntriesForDay.isEmpty {
                Text("No time tracked")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            } else {
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    ForEach(timeEntriesForDay, id: \.id) { timeEntry in
                        TimeEntryPeriodView(timeEntry: timeEntry)
                    }
                    
                    if totalHoursForDay > 0 {
                        Text("\(totalHoursForDay, specifier: "%.1f")h total")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
    
    private var timeEntriesForDay: [TimeClock] {
        guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else {
            return []
        }
        
        let calendar = Calendar.current
        return timeEntries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return calendar.isDate(entryDate, inSameDayAs: date)
        }.sorted { entry1, entry2 in
            (entry1.clockInTime ?? Date.distantPast) < (entry2.clockInTime ?? Date.distantPast)
        }
    }
    
    private var totalHoursForDay: Double {
        return timeEntriesForDay.reduce(0.0) { $0 + $1.hoursWorked }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

/// View showing a single time entry period with check-in/check-out times
struct TimeEntryPeriodView: View {
    let timeEntry: TimeClock
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            // Check-in time
            if let clockIn = timeEntry.clockInTime {
                Text(timeFormatter.string(from: clockIn))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.success)
            }
            
            Text("-")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            // Check-out time
            if let clockOut = timeEntry.clockOutTime {
                Text(timeFormatter.string(from: clockOut))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.error)
            } else if timeEntry.isActive {
                Text("Active")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.primary)
            } else {
                Text("--:--")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            // Hours worked
            Text("(\(timeEntry.hoursWorked, specifier: "%.1f")h)")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.tiny)
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

// MARK: - Total Hours Detail View

/// Total hours detail view with work order breakdown
struct TotalHoursDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.large) {
                totalHoursHeader
                workOrderBreakdownSection
            }
            .padding()
        }
        .navigationTitle("Total Hours Detail")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var totalHoursHeader: some View {
        let summaries = WorkOrderManager.allWorkerWeeklySummaries(context: viewContext)
        let totalHours = summaries.reduce(0) { $0 + $1.totalHours }
        let totalWorkOrders = Set(summaries.flatMap { $0.workOrders.map { $0.workOrder.id } }).count
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Total Hours Breakdown")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("\(totalHours, specifier: "%.1f") hours across \(totalWorkOrders) work orders")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var workOrderBreakdownSection: some View {
        let workOrderBreakdowns = calculateWorkOrderBreakdowns()
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Work Order Breakdown")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            ForEach(workOrderBreakdowns, id: \.workOrder.id) { breakdown in
                WorkOrderHoursBreakdownCard(breakdown: breakdown)
            }
        }
    }
    
    private func calculateWorkOrderBreakdowns() -> [WorkOrderHoursBreakdown] {
        let summaries = WorkOrderManager.allWorkerWeeklySummaries(context: viewContext)
        var workOrderMap: [UUID: WorkOrderHoursBreakdown] = [:]
        
        for summary in summaries {
            for workOrderSummary in summary.workOrders {
                let workOrderId = workOrderSummary.workOrder.id!
                
                if var existing = workOrderMap[workOrderId] {
                    existing.totalHours += workOrderSummary.hoursWorked
                    existing.workerBreakdowns.append(
                        WorkerHoursBreakdown(
                            worker: summary.worker,
                            hours: workOrderSummary.hoursWorked
                        )
                    )
                    workOrderMap[workOrderId] = existing
                } else {
                    workOrderMap[workOrderId] = WorkOrderHoursBreakdown(
                        workOrder: workOrderSummary.workOrder,
                        totalHours: workOrderSummary.hoursWorked,
                        workerBreakdowns: [
                            WorkerHoursBreakdown(
                                worker: summary.worker,
                                hours: workOrderSummary.hoursWorked
                            )
                        ]
                    )
                }
            }
        }
        
        return Array(workOrderMap.values).sorted { $0.totalHours > $1.totalHours }
    }
}

/// Work order hours breakdown card
struct WorkOrderHoursBreakdownCard: View {
    let breakdown: WorkOrderHoursBreakdown
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(breakdown.workOrder.title ?? "Untitled Work Order")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("\(breakdown.workerBreakdowns.count) worker\(breakdown.workerBreakdowns.count == 1 ? "" : "s") assigned")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                        Text("\(breakdown.totalHours, specifier: "%.1f")h")
                            .font(AppTheme.Typography.headlineLarge)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .font(.caption)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Worker Hours:")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(breakdown.workerBreakdowns, id: \.worker.id) { workerBreakdown in
                        HStack {
                            Text(workerBreakdown.worker.name ?? "Unknown Worker")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(workerBreakdown.hours, specifier: "%.1f")h")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.tiny)
                        .background(AppTheme.Colors.backgroundPrimary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Overtime Report View

/// Overtime report showing workers with overtime hours
struct OvertimeReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.large) {
                overtimeHeader
                overtimeWorkersSection
            }
            .padding()
        }
        .navigationTitle("Overtime Report")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var overtimeHeader: some View {
        let overtimeWorkers = WorkOrderManager.allWorkerWeeklySummaries(context: viewContext).filter { $0.isOvertime }
        let totalOvertimeHours = overtimeWorkers.reduce(0) { $0 + $1.overtimeHours }
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.Colors.warning)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text("Overtime Report")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("\(totalOvertimeHours, specifier: "%.1f") overtime hours across \(overtimeWorkers.count) worker\(overtimeWorkers.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.warning.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var overtimeWorkersSection: some View {
        let overtimeWorkers = WorkOrderManager.allWorkerWeeklySummaries(context: viewContext).filter { $0.isOvertime }
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Workers with Overtime")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if overtimeWorkers.isEmpty {
                EmptyStateView(
                    title: "No Overtime This Week",
                    message: "All workers are within standard hours",
                    systemImage: "checkmark.circle.fill"
                )
            } else {
                ForEach(overtimeWorkers, id: \.worker.id) { summary in
                    OvertimeWorkerCard(summary: summary)
                }
            }
        }
    }
}

/// Card showing overtime details for a worker
struct OvertimeWorkerCard: View {
    let summary: WorkerWeeklySummary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(summary.worker.name ?? "Unknown Worker")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(summary.worker.position ?? "Team Member")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                Text("\(summary.totalHours, specifier: "%.1f")h total")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("+\(summary.overtimeHours, specifier: "%.1f")h overtime")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.warning)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.warning.opacity(0.05))
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Data Structures

struct WorkOrderHoursBreakdown {
    let workOrder: WorkOrder
    var totalHours: Double
    var workerBreakdowns: [WorkerHoursBreakdown]
}

struct WorkerHoursBreakdown {
    let worker: Worker
    let hours: Double
}
