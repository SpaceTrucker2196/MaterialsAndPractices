//
//  FarmDashboardView.swift
//  MaterialsAndPractices
//
//  Comprehensive farm operations dashboard implementing clean architecture principles.
//  Provides centralized access to farm management with intuitive tile-based interface.
//  Follows Clean Code principles with clear separation of concerns and single responsibility.
//
//  Features:
//  - Farm property overview with visual status indicators
//  - Worker management with real-time clock status
//  - Lease tracking with payment notifications
//  - Conditional UI based on farm availability
//  - Progressive disclosure for advanced features
//
//  Clean Code Principles Applied:
//  - Single Responsibility: Each section handles one aspect of farm management
//  - Meaningful Names: All properties and methods have descriptive, intent-revealing names
//  - Small Functions: Complex operations broken into focused, readable methods
//  - Comments: Documentation explains "why" not "what"
//
//  Created by AI Assistant following Dr. Bob Martin's Clean Code principles.
//

import SwiftUI
import CoreData

/// Primary farm operations dashboard providing comprehensive overview of agricultural activities
/// Implements clean architecture with clear separation between data access, business logic, and presentation
/// Features conditional interface behavior based on farm existence and operational state
struct FarmDashboardView: View {
    // MARK: - Core Data Environment

    /// Managed object context for Core Data operations
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Data Access Layer

    /// Farm properties fetch request with alphabetical sorting for consistent presentation
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) var farmProperties: FetchedResults<Property>

    /// Active workers fetch request prioritizing active status for operational visibility
    @FetchRequest(
        entity: Worker.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Worker.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Worker.name, ascending: true)
        ]
    ) var teamMembers: FetchedResults<Worker>

    /// Lease agreements fetch request ordered by start date for chronological review
    @FetchRequest(
        entity: Lease.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Lease.startDate, ascending: false)]
    ) var leaseAgreements: FetchedResults<Lease>

    /// Infrastructure fetch request for dashboard overview
    @FetchRequest(
        entity: Infrastructure.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Infrastructure.category, ascending: true),
            NSSortDescriptor(keyPath: \Infrastructure.name, ascending: true)
        ]
    ) var infrastructureItems: FetchedResults<Infrastructure>

    // MARK: - Navigation State Management

    /// Currently selected farm property for detailed view presentation
    @State private var selectedFarmProperty: Property?

    /// Controls presentation of property detail sheet
    @State private var isPresentingPropertyDetail = false

    /// Controls presentation of farm creation flow
    @State private var isPresentingFarmCreation = false

    // MARK: - Main Interface

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.large) {
                    // Header with operational status overview
                    operationalStatusHeader

                    // Work Orders section: Only visible when farms exist
                    if hasFarmProperties {
                        workOrdersManagementSection
                    }

                    // Primary section: Active farm properties (required for all other features)
                    activeFarmPropertiesSection

                    // Secondary sections: Only visible when farms exist
                    if hasFarmProperties {
                        infrastructureOverviewSection
                        teamMembersOverviewSection
                        weeklyWorkerSummarySection
                        leaseAgreementsOverviewSection
                    }
                }
                .padding()
            }
            .navigationTitle("Farm Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isPresentingPropertyDetail) {
                if let selectedProperty = selectedFarmProperty {
                    PropertyDetailView(property: selectedProperty, isAdvancedMode: true)
                }
            }
            .sheet(isPresented: $isPresentingFarmCreation) {
                EditPropertyView(isPresented: $isPresentingFarmCreation)
            }
        }
    }

    // MARK: - Dashboard Header Section

    /// Operational status header displaying time-based greeting and key metrics
    /// Provides immediate visibility into current farm operational state
    private var operationalStatusHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                // Greeting and welcome message
                welcomeMessageContent

                Spacer()

                // Real-time operational indicators
                operationalStatusIndicators
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.Colors.primary.opacity(0.1),
                    AppTheme.Colors.secondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    /// Welcome message content with context-sensitive greeting
    /// Adapts messaging based on time of day for personalized experience
    private var welcomeMessageContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Good \(currentGreetingTime)!")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("Welcome to your farm operations dashboard")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    /// Operational status indicators showing active workers and urgent items
    /// Provides at-a-glance operational awareness for farm managers
    private var operationalStatusIndicators: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
            // Active workers indicator
            if currentlyActiveworkers.count > 0 {
                operationalIndicator(
                    count: currentlyActiveworkers.count,
                    label: "active",
                    color: AppTheme.Colors.success
                )
            }

            // Urgent lease payments indicator
            if urgentLeasePayments.count > 0 {
                operationalIndicator(
                    count: urgentLeasePayments.count,
                    label: "due",
                    color: AppTheme.Colors.warning
                )
            }
        }
    }

    /// Individual operational indicator component for consistent presentation
    /// - Parameters:
    ///   - count: Number to display in indicator
    ///   - label: Descriptive label for the metric
    ///   - color: Color theme for the indicator
    /// - Returns: Formatted indicator view
    private func operationalIndicator(count: Int, label: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(count) \(label)")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(color)
        }
    }

    // MARK: - Work Orders Management Section

    /// Work orders management section for daily task coordination
    /// Displays compact list of today's work orders with priority indicators
    private var workOrdersManagementSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Work orders list component
            WorkOrderListView(maxDisplayedOrders: 4, showViewAllButton: true)
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.Colors.primary.opacity(0.05),
                    AppTheme.Colors.secondary.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    // MARK: - Primary Section: Farm Properties

    /// Active farm properties section - the foundational requirement for all operations
    /// Displays farm tiles when available, or guided creation flow when none exist
    /// This section determines the availability of all other dashboard features
    private var activeFarmPropertiesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeaderWithNavigation(
                title: "Active Farms",
                destination: hasFarmProperties ? AnyView(FarmListView()) : nil,
                showNavigation: hasFarmProperties
            )

            if hasFarmProperties {
                // Display existing farm properties in organized grid
                activeFarmPropertiesGrid
            } else {
                // Display creation prompt when no farms exist
                noFarmsExistPrompt
            }
        }
    }

    /// Grid layout for active farm properties with responsive design
    /// Presents farm information in an easily scannable tile format
    private var activeFarmPropertiesGrid: some View {
        LazyVGrid(columns: responsiveGridColumns, spacing: AppTheme.Spacing.medium) {
            ForEach(farmProperties, id: \.id) { farmProperty in
                FarmPropertyTile(
                    property: farmProperty,
                    onTap: { selectFarmPropertyForDetails(farmProperty) }
                )
            }
        }
    }

    /// No farms exist prompt with guided creation flow
    /// Encourages users to create their first farm to unlock dashboard functionality
    private var noFarmsExistPrompt: some View {
        EmptyStateView(
            title: "No Farms Registered",
            message: "Add your first farm property to begin managing your agricultural operations",
            systemImage: "building.2",
            actionTitle: "Create First Farm"
        ) {
            initiateFirstFarmCreation()
        }
        .frame(height: 120)
    }

    // MARK: - Secondary Sections: Available When Farms Exist

    /// Infrastructure overview section showing farm equipment and facilities
    /// Displays infrastructure tiles with status indicators and navigation to management
    private var infrastructureOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeaderWithNavigation(
                title: "Infrastructure",
                destination: AnyView(InfrastructureManagementView()),
                showNavigation: true
            )

            if !infrastructureItems.isEmpty {
                infrastructureGrid
            } else {
                infrastructureEmptyState
            }
        }
    }

    /// Grid layout for infrastructure tiles
    private var infrastructureGrid: some View {
        LazyVGrid(columns: responsiveGridColumns, spacing: AppTheme.Spacing.medium) {
            ForEach(Array(infrastructureItems.prefix(6)), id: \.id) { infrastructure in
                DashboardInfrastructureTile(infrastructure: infrastructure)
            }
        }
    }

    /// Empty state for infrastructure when none are registered
    private var infrastructureEmptyState: some View {
        EmptyStateView(
            title: "No Infrastructure Registered",
            message: "Add equipment, buildings, and facilities to track your farm infrastructure",
            systemImage: "wrench.and.screwdriver",
            actionTitle: nil,
            action: nil
        )
        .frame(height: 120)
    }

    /// Team members overview section showing team tiles and individual worker status
    /// Only displayed when farm properties exist to maintain logical flow
    private var teamMembersOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeaderWithNavigation(
                title: "Teams & Workers",
                destination: AnyView(WorkerListView()),
                showNavigation: true
            )

            // Active teams section
            if !activeTeams.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Active Teams")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    teamsGrid
                }
            }

            // Individual workers section
            if !activeTeamMembers.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Individual Workers")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    teamMembersGrid
                }
            } else if activeTeams.isEmpty {
                teamMembersEmptyState
            }
        }
    }

    /// Grid layout for team tiles with status indicators
    private var teamsGrid: some View {
        LazyVGrid(columns: responsiveGridColumns, spacing: AppTheme.Spacing.medium) {
            ForEach(activeTeams, id: \.id) { team in
                WorkTeamTile(
                    team: team,
                    clockedInCount: team.clockedInCount(),
                    totalMembers: team.activeMembers().count
                )
            }
        }
    }

    /// Grid layout for team member tiles with status indicators
    private var teamMembersGrid: some View {
        LazyVGrid(columns: responsiveGridColumns, spacing: AppTheme.Spacing.medium) {
            ForEach(activeTeamMembers, id: \.id) { teamMember in
                TeamMemberTile(
                    worker: teamMember,
                    isClockedIn: currentlyActiveworkers.contains(teamMember),
                    isAssignedToPractice: isWorkerAssignedToPractice(teamMember)
                )
            }
        }
    }

    /// Empty state for team members when none are registered
    private var teamMembersEmptyState: some View {
        EmptyStateView(
            title: "No Team Members",
            message: "Add workers to manage your farm team and track operations",
            systemImage: "person.3",
            actionTitle: nil,
            action: nil
        )
        .frame(height: 120)
    }

    /// Weekly worker summary section showing hours worked and active work orders
    /// Provides oversight of current week labor allocation and progress
    private var weeklyWorkerSummarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeaderWithNavigation(
                title: "This Week's Work Summary",
                destination: AnyView(WeeklyWorkerSummaryDetailView()),
                showNavigation: true
            )
            
            let weeklySummaries = WorkOrderManager.allWorkerWeeklySummaries(context: viewContext)
            
            if !weeklySummaries.isEmpty {
                weeklyWorkerSummaryContent(summaries: weeklySummaries)
            } else {
                weeklyWorkerSummaryEmptyState
            }
        }
    }
    
    /// Content display for weekly worker summaries
    private func weeklyWorkerSummaryContent(summaries: [WorkerWeeklySummary]) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(summaries.prefix(4), id: \.worker.id) { summary in
                WeeklyWorkerSummaryRow(summary: summary)
            }
            
            if summaries.count > 4 {
                Text("+ \(summaries.count - 4) more workers")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.top, AppTheme.Spacing.small)
            }
        }
    }
    
    /// Empty state for weekly worker summary when no work is tracked
    private var weeklyWorkerSummaryEmptyState: some View {
        EmptyStateView(
            title: "No Work Tracked This Week",
            message: "Worker hours and work orders will appear here once time tracking begins",
            systemImage: "clock.badge.checkmark",
            actionTitle: nil,
            action: nil
        )
        .frame(height: 120)
    }

    /// Lease agreements overview section showing active leases and payment status
    /// Provides financial oversight for farm property agreements
    private var leaseAgreementsOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeaderWithNavigation(
                title: "Lease Agreements",
                destination: nil,
                showNavigation: false
            )

            if !activeLeaseAgreements.isEmpty {
                leaseAgreementsContent
            } else {
                leaseAgreementsEmptyState
            }
        }
    }

    /// Content display for active lease agreements with payment indicators
    private var leaseAgreementsContent: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(activeLeaseAgreements.prefix(3), id: \.id) { leaseAgreement in
                LeaseAgreementRow(
                    lease: leaseAgreement,
                    requiresUrgentAttention: urgentLeasePayments.contains(leaseAgreement)
                )
            }

            if activeLeaseAgreements.count > 3 {
                additionalLeasesIndicator
            }
        }
    }

    /// Indicator showing additional leases beyond the displayed preview
    private var additionalLeasesIndicator: some View {
        Text("+ \(activeLeaseAgreements.count - 3) more lease agreements")
            .font(AppTheme.Typography.bodySmall)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }

    /// Empty state for lease agreements when none are active
    private var leaseAgreementsEmptyState: some View {
        Text("No active lease agreements")
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }

    // MARK: - Helper Components

    /// Section header with optional navigation link for consistent interface presentation
    /// Type-erased destination avoids generic inference failures when passing `nil`.
    private func sectionHeaderWithNavigation(
        title: String,
        destination: AnyView?,
        showNavigation: Bool
    ) -> some View {
        HStack {
            SectionHeader(title: title)

            Spacer()

            if showNavigation, let destination = destination {
                NavigationLink(destination: destination) {
                    Text("View All")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Business Logic Methods

    /// Selects a farm property for detailed viewing
    /// Encapsulates navigation state management for property details
    /// - Parameter property: Farm property to view in detail
    private func selectFarmPropertyForDetails(_ property: Property) {
        selectedFarmProperty = property
        isPresentingPropertyDetail = true
    }

    /// Initiates the first farm creation flow for new users
    /// Provides guided onboarding experience when no farms exist
    private func initiateFirstFarmCreation() {
        isPresentingFarmCreation = true
    }
    
    /// Determines if a worker is currently assigned to an active practice
    /// - Parameter worker: Worker to check for practice assignment
    /// - Returns: True if worker is assigned to an incomplete practice
    private func isWorkerAssignedToPractice(_ worker: Worker) -> Bool {
        // For now, return false as we don't have worker assignment logic yet
        // In a full implementation, this would check if the worker is assigned
        // to any practice that is not yet completed
        return false
    }

    // MARK: - Computed Properties for Business Logic

    /// Determines if any farm properties exist in the system
    /// Critical for conditional UI presentation and feature availability
    private var hasFarmProperties: Bool {
        !farmProperties.isEmpty
    }

    /// Responsive grid columns adapting to content and screen size
    /// Provides consistent layout across different device orientations
    private var responsiveGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
        ]
    }

    /// Context-sensitive greeting based on current time of day
    /// Enhances user experience with personalized interaction
    private var currentGreetingTime: String {
        let currentHour = Calendar.current.component(.hour, from: Date())
        switch currentHour {
        case 0..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        default:
            return "Evening"
        }
    }

    /// Active team members filtered from all workers
    /// Focuses interface on currently relevant workforce
    private var activeTeamMembers: [Worker] {
        teamMembers.filter { $0.isActive }
    }

    /// Active teams for display
    /// Shows teams that have active members
    private var activeTeams: [WorkTeam] {
        let request: NSFetchRequest<WorkTeam> = WorkTeam.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkTeam.name, ascending: true)]
        
        do {
            let teams = try viewContext.fetch(request)
            return teams.filter { !$0.activeMembers().isEmpty }
        } catch {
            print("Error fetching active teams: \(error)")
            return []
        }
    }

    /// Workers currently clocked in for today's operations
    /// Provides real-time operational visibility for farm managers
    private var currentlyActiveworkers: [Worker] {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

        return activeTeamMembers.filter { worker in
            guard let timeEntries = worker.timeClockEntries?.allObjects as? [TimeClock] else {
                return false
            }

            return timeEntries.contains { timeEntry in
                guard let entryDate = timeEntry.date,
                      entryDate >= todayStart && entryDate < tomorrowStart else {
                    return false
                }
                return timeEntry.isActive
            }
        }
    }

    /// Active lease agreements requiring management attention
    /// Filters leases to show only currently relevant agreements
    private var activeLeaseAgreements: [Lease] {
        leaseAgreements.filter { $0.status == "active" }
    }

    /// Lease agreements requiring urgent payment attention
    /// Identifies financial obligations needing immediate action
    private var urgentLeasePayments: [Lease] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())

        return activeLeaseAgreements.filter { lease in
            // Determine if lease has payment due this month
            // Note: This is simplified logic - production systems would use more sophisticated payment tracking
            guard let paymentFrequency = lease.rentFrequency else { return false }

            switch paymentFrequency.lowercased() {
            case "monthly":
                // All monthly leases are potentially due each month
                return true
            case "annual":
                // Annual leases are due in their anniversary month
                if let startDate = lease.startDate {
                    let anniversaryMonth = calendar.component(.month, from: startDate)
                    return anniversaryMonth == currentMonth
                }
                return false
            default:
                return false
            }
        }
    }
}

// MARK: - Tile Components Following Clean Code Principles

/// Farm property tile component with clear, single responsibility
/// Displays essential farm information in a scannable, actionable format
struct FarmPropertyTile: View {
    // MARK: - Properties

    let property: Property
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with farm icon and irrigation indicator
                farmPropertyHeader

                // Farm identification and basic metrics
                farmPropertyContent

                // Location information when available
                farmLocationDisplay
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// Header section with primary icon and feature indicators
    private var farmPropertyHeader: some View {
        HStack {
            Image(systemName: "building.2.fill")
                .foregroundColor(AppTheme.Colors.primary)
                .font(.title2)

            Spacer()

            if property.hasIrrigation {
                Image(systemName: "drop.fill")
                    .foregroundColor(AppTheme.Colors.info)
                    .font(.caption)
            }
        }
    }

    /// Main content with farm name and acreage information
    private var farmPropertyContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(property.displayName ?? "Unnamed Property")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)

            Text("\(property.totalAcres, specifier: "%.1f") acres")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }

    /// Location display when county and state information is available
    private var farmLocationDisplay: some View {
        Group {
            if let county = property.county, let state = property.state {
                Text("\(county), \(state)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
    }
}

/// Team member tile component displaying worker status and availability
/// Provides visual indicators for clock status and essential worker information
struct TeamMemberTile: View {
    // MARK: - Properties

    let worker: Worker
    let isClockedIn: Bool
    let isAssignedToPractice: Bool
    
    init(worker: Worker, isClockedIn: Bool, isAssignedToPractice: Bool = false) {
        self.worker = worker
        self.isClockedIn = isClockedIn
        self.isAssignedToPractice = isAssignedToPractice
    }

    // MARK: - Body

    var body: some View {
        NavigationLink(destination: WorkerDetailView(worker: worker)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with worker photo and status tags
                workerStatusHeader

                // Worker identification and role information
                workerIdentificationContent

                // Current status display
                workerCurrentStatus
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .background(workerBackgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(workerBorderOverlay)
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// Header section with worker photo/placeholder and status indicators
    private var workerStatusHeader: some View {
        HStack {
            // Worker profile photo or default placeholder
            workerProfileDisplay

            Spacer()

            // Status tags and indicators
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                // Working status tag
                if isAssignedToPractice {
                    statusTag(text: "Working", color: AppTheme.Colors.error)
                }
                
                // Idle status tag for unassigned workers
                if !isAssignedToPractice && !isClockedIn {
                    statusTag(text: "Idle", color: Color.yellow)
                }
                
                // Clock status indicator
                Circle()
                    .fill(clockStatusColor)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    /// Status tag component for worker state display
    private func statusTag(text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }

    /// Worker profile photo or default placeholder with consistent sizing
    private var workerProfileDisplay: some View {
        Group {
            if let photoData = worker.profilePhotoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppTheme.Colors.backgroundSecondary)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.primary)
                    )
            }
        }
    }

    /// Worker identification content with name and position
    private var workerIdentificationContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(worker.name ?? "Unknown Worker")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)

            if let position = worker.position {
                Text(position)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    /// Current clock status display with appropriate styling
    private var workerCurrentStatus: some View {
        Text(isClockedIn ? "Clocked In" : "Clocked Out")
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(clockStatusColor)
    }

    // MARK: - Computed Properties for Styling

    /// Background color based on worker status
    private var workerBackgroundColor: Color {
        if !isAssignedToPractice && !isClockedIn {
            // Grey for idle workers
            return Color.gray.opacity(0.2)
        } else if isClockedIn {
            // Green for clocked in workers
            return AppTheme.Colors.success.opacity(0.1)
        } else {
            // Blue for clocked out workers
            return AppTheme.Colors.info.opacity(0.1)
        }
    }

    /// Border color for status indication
    private var clockStatusColor: Color {
        if !isAssignedToPractice && !isClockedIn {
            return Color.gray
        } else if isClockedIn {
            return AppTheme.Colors.success
        } else {
            return AppTheme.Colors.info
        }
    }

    /// Border overlay for status indication
    private var workerBorderOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .stroke(clockStatusColor, lineWidth: 2)
    }
}

/// Lease agreement row component for financial overview display
/// Shows essential lease information with payment urgency indicators
struct LeaseAgreementRow: View {
    // MARK: - Properties

    let lease: Lease
    let requiresUrgentAttention: Bool

    // MARK: - Body

    var body: some View {
        HStack {
            // Lease identification and term information
            leaseIdentificationContent

            Spacer()

            // Financial information and urgency indicators
            leaseFinancialContent
        }
        .padding(AppTheme.Spacing.medium)
        .background(urgencyBackgroundColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(urgencyBorderOverlay)
    }

    /// Lease identification content with type and expiration
    private var leaseIdentificationContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(lease.leaseType?.capitalized ?? "Lease")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)

            if let endDate = lease.endDate {
                Text("Expires: \(endDate, style: .date)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    /// Financial content with rent amount and payment urgency
    private var leaseFinancialContent: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
            if let rentAmount = lease.rentAmount {
                Text("$\(rentAmount)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            if requiresUrgentAttention {
                urgentPaymentIndicator
            }
        }
    }

    /// Urgent payment indicator with appropriate styling
    private var urgentPaymentIndicator: some View {
        Text("Payment Due")
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(AppTheme.Colors.warning)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(AppTheme.Colors.warning.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.small)
    }

    // MARK: - Computed Properties for Styling

    /// Background color based on urgency for visual priority
    private var urgencyBackgroundColor: Color {
        requiresUrgentAttention ? AppTheme.Colors.warning.opacity(0.05) : AppTheme.Colors.backgroundSecondary
    }

    /// Border overlay for urgent lease payments
    private var urgencyBorderOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .stroke(requiresUrgentAttention ? AppTheme.Colors.warning : Color.clear, lineWidth: 1)
    }
}

/// Work team tile component for displaying team information and status
/// Provides quick access to team clock-in/out functionality and member overview
struct WorkTeamTile: View {
    // MARK: - Properties
    
    let team: WorkTeam
    let clockedInCount: Int
    let totalMembers: Int
    @State private var showingTeamDetail = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            showingTeamDetail = true
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with team icon and status
                teamTileHeader
                
                // Team identification and member count
                teamTileContent
                
                // Status and action row
                teamTileStatus
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 120)
            .background(teamBackgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(teamBorderOverlay)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTeamDetail) {
            TeamDetailView(team: team, isPresented: $showingTeamDetail)
        }
    }
    
    /// Header section with team icon and status indicators
    private var teamTileHeader: some View {
        HStack {
            Image(systemName: "person.3.fill")
                .foregroundColor(AppTheme.Colors.primary)
                .font(.title2)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                // Active status indicator
                Circle()
                    .fill(clockedInCount > 0 ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                    .frame(width: 8, height: 8)
                
                // Clock status text
                if clockedInCount > 0 {
                    Text("Active")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                }
            }
        }
    }
    
    /// Team identification content with name and member count
    private var teamTileContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(team.name ?? "Unnamed Team")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
            
            Text("\(totalMembers) members")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    /// Status row with clocked in count
    private var teamTileStatus: some View {
        HStack {
            HStack(spacing: AppTheme.Spacing.tiny) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(clockedInCount > 0 ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                
                Text("\(clockedInCount) clocked in")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(clockedInCount > 0 ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties for Styling
    
    /// Background color based on team activity
    private var teamBackgroundColor: Color {
        if clockedInCount > 0 {
            return AppTheme.Colors.success.opacity(0.1)
        } else {
            return AppTheme.Colors.backgroundSecondary
        }
    }
    
    /// Border overlay for active indication
    private var teamBorderOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .stroke(
                clockedInCount > 0 ? AppTheme.Colors.success : Color.clear,
                lineWidth: 2
            )
    }
}

/// Team detail view for managing team clock-in/out and viewing member details
struct TeamDetailView: View {
    let team: WorkTeam
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Team header
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HStack {
                        Text(team.name ?? "Unnamed Team")
                            .font(AppTheme.Typography.headlineLarge)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(team.activeMembers().count) members")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Team actions
                HStack(spacing: AppTheme.Spacing.medium) {
                    CommonActionButton(
                        title: "Clock In All",
                        style: .primary
                    ) {
                        clockInAllMembers()
                    }
                    .disabled(team.clockedInCount() == team.activeMembers().count)
                    
                    CommonActionButton(
                        title: "Clock Out All",
                        style: .secondary
                    ) {
                        clockOutAllMembers()
                    }
                    .disabled(team.clockedInCount() == 0)
                }
                
                // Team members list
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Team Members")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(team.activeMembers(), id: \.id) { worker in
                        HStack {
                            Circle()
                                .fill(worker.isClockedIn() ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                                .frame(width: 12, height: 12)
                            
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
                            
                            if worker.isClockedIn() {
                                Text("Clocked In")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Colors.success)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.small)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Team Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    /// Clock in all team members
    private func clockInAllMembers() {
        // Implementation would clock in all team members
        // For now, just a placeholder
        print("Clock in all members of team: \(team.name ?? "Unknown")")
    }
    
    /// Clock out all team members
    private func clockOutAllMembers() {
        // Implementation would clock out all team members
        // For now, just a placeholder
        print("Clock out all members of team: \(team.name ?? "Unknown")")
    }
}

// MARK: - Dashboard Infrastructure Tile Component

/// Compact infrastructure tile for dashboard display
struct DashboardInfrastructureTile: View {
    let infrastructure: Infrastructure
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Icon and status indicator
                HStack {
                    Text(iconForInfrastructure)
                        .font(.title2)
                    
                    Spacer()
                    
                    statusIndicator
                }
                
                // Infrastructure information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(infrastructure.name ?? "Unnamed")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    if let type = infrastructure.type {
                        Text(type.capitalized)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .frame(height: 100)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            InfrastructureDetailView(infrastructure: infrastructure, isPresented: $showingDetail)
        }
    }
    
    /// Status indicator based on infrastructure condition
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
    }
    
    /// Icon selection based on infrastructure type
    private var iconForInfrastructure: String {
        guard let type = infrastructure.type?.lowercased() else { return "🏗️" }
        
        switch type {
        case "tractor": return "🚜"
        case "truck": return "🚛"
        case "barn": return "🏠"
        case "greenhouse": return "🪴"
        case "pump": return "💧"
        case "tools": return "🔧"
        case "silo": return "🏗️"
        case "fence": return "🚧"
        case "irrigation": return "💦"
        case "storage": return "📦"
        default: return "🏗️"
        }
    }
    
    /// Status color based on infrastructure condition
    private var statusColor: Color {
        guard let status = infrastructure.status?.lowercased() else { return Color.gray }
        
        switch status {
        case "excellent", "good": return AppTheme.Colors.success
        case "fair": return AppTheme.Colors.warning
        case "poor", "needs repair": return AppTheme.Colors.error
        default: return Color.gray
        }
    }
}

// MARK: - Preview Provider

struct FarmDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        FarmDashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
