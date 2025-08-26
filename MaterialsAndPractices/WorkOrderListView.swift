//
//  WorkOrderListView.swift
//  MaterialsAndPractices
//
//  Provides compact work order list display for dashboard with priority color coding,
//  elapsed time tracking, and worker assignment indicators.
//  Supports farm management workflow for daily task assignment.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Compact work order list component for dashboard display
/// Shows open work orders with priority indicators and worker assignments
struct WorkOrderListView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    let maxUpcomingDisplayed: Int
    let showViewAllButton: Bool
    
    // Fetch today's and overdue work orders (all incomplete with due date today or earlier)
    @FetchRequest private var todayAndOverdueWorkOrders: FetchedResults<WorkOrder>
    
    // Fetch upcoming work orders (next work orders after today)
    @FetchRequest private var upcomingWorkOrders: FetchedResults<WorkOrder>
    
    // MARK: - Initialization
    
    init(maxUpcomingDisplayed: Int = 4, showViewAllButton: Bool = true) {
        self.maxUpcomingDisplayed = maxUpcomingDisplayed
        self.showViewAllButton = showViewAllButton
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Fetch incomplete work orders due today or earlier (including overdue)
        let todayAndOverduePredicate = NSPredicate(format: "dueDate <= %@ AND isCompleted == NO", 
                                                 today.addingTimeInterval(24*60*60-1) as NSDate)
        
        self._todayAndOverdueWorkOrders = FetchRequest(
            entity: WorkOrder.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \WorkOrder.dueDate, ascending: true),
                NSSortDescriptor(keyPath: \WorkOrder.priority, ascending: false),
                NSSortDescriptor(keyPath: \WorkOrder.createdDate, ascending: true)
            ],
            predicate: todayAndOverduePredicate
        )
        
        // Fetch upcoming work orders (after today)
        let upcomingPredicate = NSPredicate(format: "dueDate >= %@ AND isCompleted == NO", 
                                          tomorrow as NSDate)
        
        self._upcomingWorkOrders = FetchRequest(
            entity: WorkOrder.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \WorkOrder.dueDate, ascending: true),
                NSSortDescriptor(keyPath: \WorkOrder.priority, ascending: false),
                NSSortDescriptor(keyPath: \WorkOrder.createdDate, ascending: true)
            ],
            predicate: upcomingPredicate
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            // Today's Work Orders Section (including overdue)
            todaysWorkOrdersSection
            
            // Upcoming Work Orders Section (next work orders)
            if !upcomingWorkOrders.isEmpty {
                upcomingWorkOrdersSection
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Today's work orders section showing all incomplete work orders due today or earlier
    private var todaysWorkOrdersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Section header
            HStack {
                Text("Today's Work Orders")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                // Show count of overdue items if any
                if hasOverdueWorkOrders {
                    HStack(spacing: AppTheme.Spacing.tiny) {
                        Circle()
                            .fill(AppTheme.Colors.warning)
                            .frame(width: 8, height: 8)
                        
                        Text("\(overdueCount) overdue")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
            }
            
            // Work orders list
            if todayAndOverdueWorkOrders.isEmpty {
                todaysWorkOrdersEmptyState
            } else {
                todaysWorkOrdersList
            }
        }
    }
    
    /// Upcoming work orders section showing next 4 work orders
    private var upcomingWorkOrdersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Section header with navigation
            HStack {
                Text("Next Work Orders")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                if showViewAllButton {
                    NavigationLink(destination: AllWorkOrdersView()) {
                        Text("View All (\(totalOpenWorkOrdersCount))")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            
            // Upcoming work orders list (limited to maxUpcomingDisplayed)
            upcomingWorkOrdersList
        }
    }
    
    // MARK: - UI Components
    
    /// Empty state when no work orders exist for today
    private var todaysWorkOrdersEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.success)
            
            Text("No work orders for today")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("All caught up!")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.success.opacity(0.05))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// List of today's and overdue work orders
    private var todaysWorkOrdersList: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(Array(todayAndOverdueWorkOrders), id: \.id) { workOrder in
                WorkOrderRow(workOrder: workOrder, isOverdue: workOrder.isOverdue())
            }
        }
    }
    
    /// List of upcoming work orders (limited to maxUpcomingDisplayed)
    private var upcomingWorkOrdersList: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(Array(upcomingWorkOrders.prefix(maxUpcomingDisplayed)), id: \.id) { workOrder in
                WorkOrderRow(workOrder: workOrder, isOverdue: false)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total count of all open work orders (today + upcoming)
    private var totalOpenWorkOrdersCount: Int {
        return todayAndOverdueWorkOrders.count + upcomingWorkOrders.count
    }
    
    /// Whether there are any overdue work orders
    private var hasOverdueWorkOrders: Bool {
        return todayAndOverdueWorkOrders.contains { $0.isOverdue() }
    }
    
    /// Count of overdue work orders
    private var overdueCount: Int {
        return todayAndOverdueWorkOrders.filter { $0.isOverdue() }.count
    }
    
    /// Helper to determine if a work order is overdue
    private func isWorkOrderOverdue(_ workOrder: WorkOrder) -> Bool {
        return workOrder.isOverdue()
    }
}

// MARK: - Work Order Row Component

/// Individual work order row with priority color coding and status indicators
struct WorkOrderRow: View {
    // MARK: - Properties
    
    let workOrder: WorkOrder
    let isOverdue: Bool
    @State private var showingWorkOrderDetail = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            showingWorkOrderDetail = true
        }) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Priority indicator stripe
                priorityIndicatorStripe
                
                // Work order content
                workOrderContent
                
                // Status and worker indicators
                statusAndWorkerIndicators
            }
            .padding(AppTheme.Spacing.medium)
            .background(backgroundColorForPriority)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(borderOverlayForPriority)
            .overlay(overdueOverlayIfNeeded)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWorkOrderDetail) {
            WorkOrderAssignmentView(workOrder: workOrder, isPresented: $showingWorkOrderDetail)
        }
    }
    
    // MARK: - UI Components
    
    /// Priority indicator stripe on the left
    private var priorityIndicatorStripe: some View {
        Rectangle()
            .fill(priorityColor)
            .frame(width: 4)
            .cornerRadius(2)
    }
    
    /// Main work order content
    private var workOrderContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            // Work order title
            Text(workOrder.title ?? "Untitled Work Order")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Grow location and practice
            if let grow = workOrder.grow {
                HStack {
                    if let cultivar = grow.cultivar {
                        Text(cultivar.emoji ?? "🌱")
                            .font(.caption)
                    }
                    
                    Text(grow.title ?? "Unknown Grow")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
            
            // Due date and elapsed time
            HStack {
                // Due date with overdue indication
                if let dueDate = workOrder.dueDate {
                    if isOverdue {
                        HStack(spacing: AppTheme.Spacing.tiny) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.warning)
                            
                            Text("Overdue: \(dueDate, style: .date)")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.warning)
                        }
                    } else {
                        Text("Due: \(dueDate, style: .time)")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Elapsed time counter
                elapsedTimeIndicator
            }
        }
    }
    
    /// Status and worker count indicators
    private var statusAndWorkerIndicators: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
            // Status indicator
            statusIndicator
            
            // Worker count indicator
            workerCountIndicator
            
            Spacer()
        }
    }
    
    /// Status indicator with appropriate color
    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(workOrder.agricultureStatus.displayText)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(statusColor)
        }
    }
    
    /// Worker count indicator with person icons
    private var workerCountIndicator: some View {
        HStack(spacing: AppTheme.Spacing.tiny) {
            Image(systemName: "person.fill")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("\(assignedWorkerCount)")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.tiny)
        .background(AppTheme.Colors.primary.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    /// Elapsed time indicator
    private var elapsedTimeIndicator: some View {
        Group {
            if let activeTimeEntry = currentActiveTimeEntry {
                HStack(spacing: AppTheme.Spacing.tiny) {
                    Circle()
                        .fill(AppTheme.Colors.success)
                        .frame(width: 6, height: 6)
                    
                    Text(activeTimeEntry.elapsedTimeFormatted)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                        .monospacedDigit()
                }
            } else {
                Text("Not started")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
    
    /// Overdue overlay for work orders that are past due
    private var overdueOverlayIfNeeded: some View {
        Group {
            if isOverdue {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.warning, lineWidth: 2)
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Priority color based on work order priority
    private var priorityColor: Color {
        switch workOrder.workPriority {
        case .low:
            return Color.green
        case .medium:
            return Color.orange
        case .high:
            return Color.red
        case .urgent:
            return Color.purple
        }
    }
    
    /// Status color based on agriculture status
    private var statusColor: Color {
        switch workOrder.agricultureStatus {
        case .notStarted:
            return Color.gray
        case .inProgress:
            return AppTheme.Colors.primary
        case .completed:
            return AppTheme.Colors.success
        case .onHold, .weatherDelay, .tooWet, .equipmentIssue, .waitingForMaterials, .waitingForInspection:
            return AppTheme.Colors.warning
        case .cancelled:
            return AppTheme.Colors.error
        }
    }
    
    /// Background color based on priority
    private var backgroundColorForPriority: Color {
        switch workOrder.workPriority {
        case .urgent:
            return Color.purple.opacity(0.05)
        case .high:
            return Color.red.opacity(0.05)
        default:
            return AppTheme.Colors.backgroundSecondary
        }
    }
    
    /// Border overlay for high priority items
    private var borderOverlayForPriority: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .stroke(
                workOrder.workPriority == .urgent ? Color.purple.opacity(0.3) : Color.clear,
                lineWidth: 1
            )
    }
    
    /// Count of assigned workers
    private var assignedWorkerCount: Int {
        return workOrder.assignedWorkers().count
    }
    
    /// Current active time entry for this work order
    private var currentActiveTimeEntry: TimeClock? {
        guard let timeEntries = workOrder.timeClockEntries?.allObjects as? [TimeClock] else {
            return nil
        }
        
        return timeEntries.first { $0.isActive }
    }
}

// MARK: - All Work Orders View

/// Full list view of all work orders for navigation
struct AllWorkOrdersView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: WorkOrder.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WorkOrder.priority, ascending: false),
            NSSortDescriptor(keyPath: \WorkOrder.dueDate, ascending: true)
        ],
        predicate: NSPredicate(format: "isCompleted == NO")
    ) private var allWorkOrders: FetchedResults<WorkOrder>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allWorkOrders, id: \.id) { workOrder in
                    WorkOrderRow(
                        workOrder: workOrder,
                        isOverdue: workOrder.isOverdue()
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .padding(.vertical, AppTheme.Spacing.tiny)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("All Work Orders")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    /// Helper to determine if a work order is overdue
    private func isWorkOrderOverdue(_ workOrder: WorkOrder) -> Bool {
        return workOrder.isOverdue()
    }
}

// MARK: - Preview

struct WorkOrderListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkOrderListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding()
    }
}