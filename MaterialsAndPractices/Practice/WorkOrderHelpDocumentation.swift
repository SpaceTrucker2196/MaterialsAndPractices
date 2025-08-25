//
//  WorkOrderHelpDocumentation.swift
//  MaterialsAndPractices
//
//  Provides in-app help documentation for the work order system
//  with comprehensive guides for farm workers and managers.
//  Supports onboarding and ongoing reference needs.
//
//  Created by GitHub Copilot on 12/18/24.
//

import SwiftUI

// MARK: - Work Order Help View

/// Comprehensive help documentation for the work order system
/// Provides guided tutorials and reference information for users
struct WorkOrderHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSection: HelpSection = .overview
    
    var body: some View {
        NavigationView {
            HSplitView {
                // Sidebar with help sections
                helpSectionsList
                
                // Main content area
                helpContentView
            }
            .navigationTitle("Work Order System Help")
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
    
    /// Sidebar with help section navigation
    private var helpSectionsList: some View {
        List(HelpSection.allCases, id: \.self, selection: $selectedSection) { section in
            HelpSectionRow(section: section)
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
    }
    
    /// Main content view for selected help section
    private var helpContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                selectedSection.content
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
}

// MARK: - Help Sections

/// Enumeration of available help sections
enum HelpSection: String, CaseIterable {
    case overview = "Overview"
    case creatingWorkOrders = "Creating Work Orders"
    case teamManagement = "Team Management"
    case timeTracking = "Time Tracking"
    case statusManagement = "Status Management"
    case weeklyReporting = "Weekly Reporting"
    case troubleshooting = "Troubleshooting"
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .creatingWorkOrders: return "plus.circle"
        case .teamManagement: return "person.3"
        case .timeTracking: return "clock"
        case .statusManagement: return "checkmark.circle"
        case .weeklyReporting: return "chart.bar"
        case .troubleshooting: return "wrench"
        }
    }
    
    var content: some View {
        Group {
            switch self {
            case .overview:
                OverviewHelpContent()
            case .creatingWorkOrders:
                CreatingWorkOrdersHelpContent()
            case .teamManagement:
                TeamManagementHelpContent()
            case .timeTracking:
                TimeTrackingHelpContent()
            case .statusManagement:
                StatusManagementHelpContent()
            case .weeklyReporting:
                WeeklyReportingHelpContent()
            case .troubleshooting:
                TroubleshootingHelpContent()
            }
        }
    }
}

// MARK: - Help Section Row

/// Individual row for help section navigation
struct HelpSectionRow: View {
    let section: HelpSection
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: section.icon)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 20)
            
            Text(section.rawValue)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

// MARK: - Help Content Views

/// Overview help content
struct OverviewHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HelpSectionHeader(
                title: "Work Order System Overview",
                icon: "info.circle.fill"
            )
            
            HelpTextBlock("""
            The Work Order System helps you organize and track farm work efficiently. It allows you to:
            
            • Create detailed work orders for specific tasks
            • Assign teams of workers to complete work
            • Track time spent on each work order
            • Monitor progress with status updates
            • Generate weekly reports for productivity analysis
            """)
            
            HelpFeatureGrid()
            
            HelpTextBlock("""
            Work orders connect to your existing grows, allowing you to track all work performed on specific crops and fields throughout the growing season.
            """)
        }
    }
}

/// Creating work orders help content
struct CreatingWorkOrdersHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HelpSectionHeader(
                title: "Creating Work Orders",
                icon: "plus.circle.fill"
            )
            
            HelpStepsList(steps: [
                HelpStep(
                    number: 1,
                    title: "Navigate to a Grow",
                    description: "Select a grow from the main Grows tab to create work for that specific crop."
                ),
                HelpStep(
                    number: 2,
                    title: "Tap 'Perform Work'",
                    description: "In the grow details, tap the outlined 'Perform Work' button to open the work order creation form."
                ),
                HelpStep(
                    number: 3,
                    title: "Fill Work Details",
                    description: "Enter a descriptive title, select priority level, and add any notes about the work to be performed."
                ),
                HelpStep(
                    number: 4,
                    title: "Assign a Team",
                    description: "Select which work team should complete this task. Teams group workers together for efficient coordination."
                ),
                HelpStep(
                    number: 5,
                    title: "Set Schedule",
                    description: "Choose a due date and estimate how many hours the work will take to complete."
                )
            ])
            
            HelpTipBox(
                title: "Pro Tip",
                message: "Be specific in your work order titles and notes. This helps workers understand exactly what needs to be done and improves completion quality."
            )
        }
    }
}

/// Team management help content
struct TeamManagementHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HelpSectionHeader(
                title: "Team Management",
                icon: "person.3.fill"
            )
            
            HelpTextBlock("""
            Work teams allow you to group workers together for efficient task assignment. Teams can be organized by:
            
            • Skill specialization (harvesting, planting, maintenance)
            • Field location (north field team, greenhouse team)
            • Experience level (experienced crew, training crew)
            """)
            
            HelpSubsection(title: "Creating Teams") {
                HelpTextBlock("""
                Teams are managed through the farm dashboard and can include multiple workers. Each team shows:
                
                • Number of active members
                • How many are currently clocked in
                • Current work order assignments
                """)
            }
            
            HelpSubsection(title: "Team Assignment") {
                HelpTextBlock("""
                When creating work orders, you assign entire teams rather than individual workers. This provides flexibility for team leaders to coordinate specific worker assignments on-site.
                """)
            }
        }
    }
}

/// Time tracking help content
struct TimeTrackingHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HelpSectionHeader(
                title: "Time Tracking",
                icon: "clock.fill"
            )
            
            HelpTextBlock("""
            The system automatically tracks time worked on each work order when team members clock in and out. Time tracking includes:
            """)
            
            HelpFeatureList(features: [
                "Automatic weekly hour calculations",
                "Overtime detection (over 40 hours/week)",
                "Work order specific time allocation",
                "Real-time clock in/out status"
            ])
            
            HelpSubsection(title: "How It Works") {
                HelpStepsList(steps: [
                    HelpStep(
                        number: 1,
                        title: "Worker Clocks In",
                        description: "Team members clock in through their worker profile when starting work."
                    ),
                    HelpStep(
                        number: 2,
                        title: "Time Associates with Work Orders",
                        description: "All time is automatically tracked against active work orders for that team."
                    ),
                    HelpStep(
                        number: 3,
                        title: "Clock Out Calculates Hours",
                        description: "When workers clock out, the system calculates total hours and updates work order progress."
                    )
                ])
            }
        }
    }
}

/// Status management help content
struct StatusManagementHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HelpSectionHeader(
                title: "Work Order Status Management",
                icon: "checkmark.circle.fill"
            )
            
            HelpTextBlock("""
            Work orders use agriculture-specific status codes to reflect real farming conditions:
            """)
            
            HelpStatusGrid()
            
            HelpSubsection(title: "Using Status Updates") {
                HelpTextBlock("""
                Update work order status as conditions change:
                
                • Weather delays are common and help track seasonal impacts
                • Equipment issues should be logged for maintenance planning
                • Too wet conditions help optimize future scheduling
                """)
            }
        }
    }
}

/// Weekly reporting help content
struct WeeklyReportingHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HelpSectionHeader(
                title: "Weekly Reporting",
                icon: "chart.bar.fill"
            )
            
            HelpTextBlock("""
            The dashboard provides comprehensive weekly summaries showing:
            """)
            
            HelpFeatureList(features: [
                "Total hours worked by each team member",
                "Overtime calculations and alerts",
                "Work orders completed during the week",
                "Current active work assignments",
                "Productivity metrics and trends"
            ])
            
            HelpSubsection(title: "Accessing Reports") {
                HelpTextBlock("""
                Weekly summaries are available on the main dashboard under "This Week's Work Summary." Tap to view detailed breakdowns for each worker including their specific work order contributions.
                """)
            }
        }
    }
}

/// Troubleshooting help content
struct TroubleshootingHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HelpSectionHeader(
                title: "Troubleshooting",
                icon: "wrench.fill"
            )
            
            HelpSubsection(title: "Common Issues") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HelpTroubleshootingItem(
                        problem: "Can't create work order",
                        solution: "Ensure you have at least one work team created and the grow has a cultivar assigned."
                    )
                    
                    HelpTroubleshootingItem(
                        problem: "Time not tracking correctly",
                        solution: "Verify workers are properly clocked in and assigned to active teams with work orders."
                    )
                    
                    HelpTroubleshootingItem(
                        problem: "Weekly summary shows no data",
                        solution: "Check that workers have time clock entries for the current week and work orders are properly created."
                    )
                }
            }
            
            HelpSubsection(title: "Best Practices") {
                HelpTextBlock("""
                • Create teams before starting work orders
                • Keep work order titles descriptive and specific
                • Update status regularly to reflect actual conditions
                • Review weekly summaries to optimize labor allocation
                • Train workers on proper clock in/out procedures
                """)
            }
        }
    }
}

// MARK: - Helper Components

/// Section header for help content
struct HelpSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.primary)
                .font(.title2)
            
            Text(title)
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

/// Text block for help content
struct HelpTextBlock: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(AppTheme.Colors.textPrimary)
            .lineSpacing(4)
    }
}

/// Subsection within help content
struct HelpSubsection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(title)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            content
        }
    }
}

/// Tip box for helpful information
struct HelpTipBox: View {
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppTheme.Colors.warning)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.warning)
                
                Text(message)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.warning.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Feature grid for overview
struct HelpFeatureGrid: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.medium) {
            HelpFeatureCard(icon: "plus.circle", title: "Create Orders", description: "Organize tasks for teams")
            HelpFeatureCard(icon: "person.3", title: "Assign Teams", description: "Coordinate worker groups")
            HelpFeatureCard(icon: "clock", title: "Track Time", description: "Monitor hours automatically")
            HelpFeatureCard(icon: "chart.bar", title: "View Reports", description: "Analyze productivity")
        }
    }
}

/// Individual feature card
struct HelpFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.primary)
                .font(.title2)
            
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(description)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Steps list for procedures
struct HelpStepsList: View {
    let steps: [HelpStep]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            ForEach(steps, id: \.number) { step in
                HelpStepRow(step: step)
            }
        }
    }
}

/// Individual step in a procedure
struct HelpStep {
    let number: Int
    let title: String
    let description: String
}

/// Step row display
struct HelpStepRow: View {
    let step: HelpStep
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(step.number)")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(AppTheme.Colors.primary)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(step.title)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(step.description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

/// Feature list for highlighting capabilities
struct HelpFeatureList: View {
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.caption)
                    
                    Text(feature)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }
        }
    }
}

/// Status grid showing all agriculture statuses
struct HelpStatusGrid: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.small) {
            ForEach(AgricultureWorkStatus.allCases, id: \.self) { status in
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(status.emoji)
                        .font(.title3)
                    
                    Text(status.displayText)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.small)
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
    }
}

/// Troubleshooting item
struct HelpTroubleshootingItem: View {
    let problem: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.Colors.warning)
                    .font(.caption)
                
                Text("Problem: \(problem)")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.success)
                    .font(.caption)
                
                Text("Solution: \(solution)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Preview

struct WorkOrderHelpView_Previews: PreviewProvider {
    static var previews: some View {
        WorkOrderHelpView()
    }
}