//
//  WorkOrdersListView.swift
//  MaterialsAndPractices
//
//  Displays work orders for a grow with navigation to display/edit mode
//  Supports the user's requirement for work order management.
//
//  Created by GitHub Copilot on 12/18/24.
//

import SwiftUI
import CoreData

/// View for displaying work orders associated with a grow
struct WorkOrdersListView: View {
    // MARK: - Properties
    
    let grow: Grow
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedWorkOrder: WorkOrder?
    @State private var showingWorkOrderDetail = false
    
    // Fetch work orders for this grow
    var fetchRequest: FetchRequest<WorkOrder>
    
    // MARK: - Initialization
    
    init(grow: Grow) {
        self.grow = grow
        self.fetchRequest = FetchRequest<WorkOrder>(
            entity: WorkOrder.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \WorkOrder.createdDate, ascending: false)
            ],
            predicate: NSPredicate(format: "grow == %@", grow),
            animation: .default
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if fetchRequest.wrappedValue.isEmpty {
                emptyStateView
            } else {
                workOrdersList
            }
        }
        .sheet(isPresented: $showingWorkOrderDetail) {
            if let workOrder = selectedWorkOrder {
                WorkOrderDetailView(
                    workOrder: workOrder,
                    isPresented: $showingWorkOrderDetail
                )
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "clipboard")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No Work Orders")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Create your first work order to start tracking farm activities")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.Spacing.extraLarge)
        .frame(maxWidth: .infinity)
    }
    
    private var workOrdersList: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
                GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
            ],
            spacing: AppTheme.Spacing.medium
        ) {
            ForEach(fetchRequest.wrappedValue, id: \.id) { workOrder in
                WorkOrderCard(workOrder: workOrder) {
                    selectedWorkOrder = workOrder
                    showingWorkOrderDetail = true
                }
            }
        }
    }
}

// MARK: - Work Order Card

/// Individual work order card for list display
struct WorkOrderCard: View {
    let workOrder: WorkOrder
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with title and status
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(workOrder.title ?? "Untitled Work Order")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if let priority = workOrder.priority,
                           let workOrderPriority = WorkOrderPriority(rawValue: priority) {
                            Text(workOrderPriority.displayWithEmoji)
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    StatusBadge(workOrder: workOrder)
                }
                
                // Work type and team info
                HStack {
                    if let assignedTeam = workOrder.assignedTeam {
                        Label {
                            Text("\(assignedTeam.activeMembers().count) members")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        } icon: {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.info)
                        }
                    }
                    
                    Spacer()
                    
                    if let dueDate = workOrder.dueDate {
                        Text(formattedDueDate(dueDate))
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(dueDateColor(dueDate))
                    }
                }
                
                // Progress indicator if work is in progress
                if isWorkInProgress {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                            .font(.caption)
                        
                        Text("Work in progress")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Spacer()
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var isWorkInProgress: Bool {
        // TODO: Determine if work is in progress based on time tracking
        return false
    }
    
    private var borderColor: Color {
        if workOrder.isCompleted {
            return AppTheme.Colors.success.opacity(0.3)
        } else if isOverdue {
            return AppTheme.Colors.error.opacity(0.3)
        } else {
            return AppTheme.Colors.border
        }
    }
    
    private var isOverdue: Bool {
        guard let dueDate = workOrder.dueDate else { return false }
        return dueDate < Date() && !workOrder.isCompleted
    }
    
    // MARK: - Helper Methods
    
    private func formattedDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isToday(date) {
            return "Today"
        } else if Calendar.current.isTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        if isOverdue {
            return AppTheme.Colors.error
        } else if Calendar.current.isToday(date) {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - Status Badge

/// Status badge for work orders
struct StatusBadge: View {
    let workOrder: WorkOrder
    
    var body: some View {
        Text(statusText)
            .font(AppTheme.Typography.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(statusColor)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    private var statusText: String {
        if workOrder.isCompleted {
            return "Completed"
        } else if let status = workOrder.status,
                  let agricultureStatus = AgricultureWorkStatus(rawValue: status) {
            return agricultureStatus.displayText
        } else {
            return "Not Started"
        }
    }
    
    private var statusColor: Color {
        if workOrder.isCompleted {
            return AppTheme.Colors.success
        } else if let status = workOrder.status,
                  let agricultureStatus = AgricultureWorkStatus(rawValue: status) {
            switch agricultureStatus {
            case .notStarted:
                return AppTheme.Colors.textSecondary
            case .inProgress:
                return AppTheme.Colors.primary
            case .completed:
                return AppTheme.Colors.success
            case .onHold:
                return AppTheme.Colors.warning
            }
        } else {
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - Preview

struct WorkOrdersListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleGrow = Grow(context: context)
        sampleGrow.title = "Sample Grow"
        
        // Create sample work orders
        let workOrder1 = WorkOrder(context: context)
        workOrder1.title = "Weeding Task"
        workOrder1.grow = sampleGrow
        workOrder1.createdDate = Date()
        workOrder1.dueDate = Date()
        workOrder1.isCompleted = false
        
        let workOrder2 = WorkOrder(context: context)
        workOrder2.title = "Harvest Preparation"
        workOrder2.grow = sampleGrow
        workOrder2.createdDate = Date()
        workOrder2.dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        workOrder2.isCompleted = true
        
        return WorkOrdersListView(grow: sampleGrow)
            .environment(\.managedObjectContext, context)
            .padding()
    }
}