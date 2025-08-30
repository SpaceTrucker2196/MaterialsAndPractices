import SwiftUI

// MARK: - Help Section Definition

/// Help sections enum defining available help topics with content
enum HelpSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case workOrders = "Work Orders"
    case timeTracking = "Time Tracking"
    case teamManagement = "Team Management"
    case reporting = "Weekly Reports"
    case troubleshooting = "Troubleshooting"
    
    var id: String { rawValue }
    
    /// System icon for each help section
    var icon: String {
        switch self {
        case .overview:
            return "book.fill"
        case .workOrders:
            return "doc.text.fill"
        case .timeTracking:
            return "clock.fill"
        case .teamManagement:
            return "person.3.fill"
        case .reporting:
            return "chart.bar.fill"
        case .troubleshooting:
            return "wrench.fill"
        }
    }
    
    /// Content view for each help section
    @ViewBuilder
    var content: some View {
        switch self {
        case .overview:
            OverviewHelpContent()
        case .workOrders:
            WorkOrderHelpContent()
        case .timeTracking:
            TimeTrackingHelpContent()
        case .teamManagement:
            TeamManagementHelpContent()
        case .reporting:
            ReportingHelpContent()
        case .troubleshooting:
            TroubleshootingHelpContent()
        }
    }
}

// MARK: - Main Help View

/// iOS-optimized help view using NavigationStack for iPhone compatibility
struct WorkOrderHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(HelpSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label(LocalizationUtility.localizedString(section.rawValue, comment: "Help section title"), 
                              systemImage: section.icon)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                }
            }
            .navigationTitle(LocalizationUtility.HelpSystem.helpTitle)
            .navigationDestination(for: HelpSection.self) { section in
                HelpDetailView(section: section)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationUtility.CommonUI.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Help Detail View

/// Detail view for individual help sections with proper iOS navigation
struct HelpDetailView: View {
    let section: HelpSection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                section.content
            }
            .padding()
        }
        .background(AppTheme.Colors.backgroundPrimary)
        .navigationTitle(NSLocalizedString(section.rawValue, comment: "Help section title"))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Help Content Views

/// Overview help content explaining the farm management system
struct OverviewHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(NSLocalizedString("Welcome to Farm Management", comment: "Overview help title"))
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(NSLocalizedString("This app helps you manage your farm operations including work orders, time tracking, and team coordination.", comment: "Overview help description"))
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("Key Features:", comment: "Key features label"))
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HelpBulletPoint(text: NSLocalizedString("Create and manage work orders", comment: "Feature description"))
                HelpBulletPoint(text: NSLocalizedString("Track worker time and productivity", comment: "Feature description"))
                HelpBulletPoint(text: NSLocalizedString("Monitor harvest schedules", comment: "Feature description"))
                HelpBulletPoint(text: NSLocalizedString("Generate weekly reports", comment: "Feature description"))
            }
        }
    }
}

/// Work order help content with creation and management guidance
struct WorkOrderHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(NSLocalizedString("Managing Work Orders", comment: "Work order help title"))
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("Creating Work Orders:", comment: "Creating work orders section"))
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HelpNumberedStep(number: 1, text: NSLocalizedString("Tap 'Perform Work' on any grow tile", comment: "Step instruction"))
                HelpNumberedStep(number: 2, text: NSLocalizedString("Fill in work details and assign team", comment: "Step instruction"))
                HelpNumberedStep(number: 3, text: NSLocalizedString("Set priority and due date", comment: "Step instruction"))
                HelpNumberedStep(number: 4, text: NSLocalizedString("Save to create the work order", comment: "Step instruction"))
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("Status Management:", comment: "Status management section"))
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HelpBulletPoint(text: NSLocalizedString("🌧️ Weather Delay - For weather-related postponements", comment: "Status description"))
                HelpBulletPoint(text: NSLocalizedString("💧 Too Wet - When soil conditions aren't suitable", comment: "Status description"))
                HelpBulletPoint(text: NSLocalizedString("🔧 Equipment Issue - For mechanical problems", comment: "Status description"))
            }
        }
    }
}

/// Time tracking help content with clock-in/out procedures
struct TimeTrackingHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(NSLocalizedString("Time Tracking", comment: "Time tracking help title"))
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(NSLocalizedString("Track work hours for accurate payroll and productivity analysis.", comment: "Time tracking description"))
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("Clock Operations:", comment: "Clock operations section"))
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HelpBulletPoint(text: NSLocalizedString("Clock In - Start your work shift", comment: "Clock operation"))
                HelpBulletPoint(text: NSLocalizedString("Clock Out - End your work shift", comment: "Clock operation"))
                HelpBulletPoint(text: NSLocalizedString("Break - Take a temporary break", comment: "Clock operation"))
                HelpBulletPoint(text: NSLocalizedString("Lunch - Take a lunch break", comment: "Clock operation"))
            }
        }
    }
}

/// Team management help content for worker coordination
struct TeamManagementHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(NSLocalizedString("Team Management", comment: "Team management help title"))
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(NSLocalizedString("Organize workers into teams and assign work orders efficiently.", comment: "Team management description"))
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("Team Organization:", comment: "Team organization section"))
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HelpBulletPoint(text: NSLocalizedString("Create work teams for different operations", comment: "Team feature"))
                HelpBulletPoint(text: NSLocalizedString("Assign workers with relevant skills", comment: "Team feature"))
                HelpBulletPoint(text: NSLocalizedString("Monitor team productivity", comment: "Team feature"))
                HelpBulletPoint(text: NSLocalizedString("Balance workload across teams", comment: "Team feature"))
            }
        }
    }
}

/// Reporting help content for weekly summaries and analytics
struct ReportingHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(NSLocalizedString("Weekly Reports", comment: "Weekly reports help title"))
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(NSLocalizedString("Generate comprehensive reports on worker productivity and work order completion.", comment: "Weekly reports description"))
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("Report Features:", comment: "Report features section"))
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HelpBulletPoint(text: NSLocalizedString("Total hours worked per worker", comment: "Report feature"))
                HelpBulletPoint(text: NSLocalizedString("Overtime detection (>40 hours)", comment: "Report feature"))
                HelpBulletPoint(text: NSLocalizedString("Work order completion rates", comment: "Report feature"))
                HelpBulletPoint(text: NSLocalizedString("Team productivity metrics", comment: "Report feature"))
            }
        }
    }
}

/// Troubleshooting help content for common issues
struct TroubleshootingHelpContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(NSLocalizedString("Troubleshooting", comment: "Troubleshooting help title"))
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("Common Issues:", comment: "Common issues section"))
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(NSLocalizedString("Can't create work order:", comment: "Issue title"))
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(NSLocalizedString("• Ensure you have workers assigned\n• Check that grow has active status\n• Verify team permissions", comment: "Issue solution"))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(NSLocalizedString("Time tracking issues:", comment: "Issue title"))
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(NSLocalizedString("• Make sure you're clocked in\n• Check work order assignment\n• Verify correct date/time", comment: "Issue solution"))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Helper Components

/// Bullet point component for help content
struct HelpBulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Text("•")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(text)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
}

/// Numbered step component for help content
struct HelpNumberedStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Text("\(number).")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(minWidth: 20, alignment: .leading)
            
            Text(text)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview Provider

struct WorkOrderHelpView_Previews: PreviewProvider {
    static var previews: some View {
        WorkOrderHelpView()
    }
}
