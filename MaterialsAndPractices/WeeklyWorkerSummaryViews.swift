//
//  WeeklyWorkerSummaryViews.swift
//  MaterialsAndPractices
//
//  Provides weekly worker summary components for dashboard display
//  and detailed view for comprehensive work order and time tracking.
//  Supports farm management system worker oversight.
//
//  Created by GitHub Copilot on 12/18/24.
//

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
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
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
            StatCard(
                title: "Total Hours",
                value:String(format: "%.1f", totalHours),
                subtitle: "All Workers"
            )
            
            StatCard(
                title: "Active Workers",
                value: "\(activeWorkers)",
                subtitle: "This Week"
            )
            
            StatCard(
                title: "Overtime",
                value: "\(overtimeWorkers)",
                subtitle: "Workers"
            )
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
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(subtitle)
                .font(AppTheme.Typography.bodySmall)
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
                            .font(AppTheme.Typography.headlineLarge)
                            .foregroundColor(summary.isOvertime ? AppTheme.Colors.warning : AppTheme.Colors.primary)
                        
                        if summary.isOvertime {
                            Text("+\(summary.overtimeHours, specifier: "%.1f")h OT")
                                .font(AppTheme.Typography.labelSmall)
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
