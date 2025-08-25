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

                    // Primary section: Active farm properties (required for all other features)
                    activeFarmPropertiesSection

                    // Secondary sections: Only visible when farms exist
                    if hasFarmProperties {
                        teamMembersOverviewSection
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

    /// Team members overview section showing worker status and availability
    /// Only displayed when farm properties exist to maintain logical flow
    private var teamMembersOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeaderWithNavigation(
                title: "Team Members",
                destination: AnyView(WorkerListView()),
                showNavigation: true
            )

            if !activeTeamMembers.isEmpty {
                teamMembersGrid
            } else {
                teamMembersEmptyState
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

// MARK: - Preview Provider

struct FarmDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        FarmDashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
