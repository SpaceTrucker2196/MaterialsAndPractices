import SwiftUI
import CoreData

/// Displays property details with photo management and mode-specific content
struct PropertyDetailView: View {
    // MARK: - Properties

    let property: Property
    let isAdvancedMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingPhotoCapture = false
    @State private var showingEditView = false
    @State private var showingInspectionScheduling = false
    @StateObject private var loadingState = ViewLoadingStateManager()
    @State private var selectedFieldForDetail: Field?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                propertyInformationSection
                fieldsSection

                if isAdvancedMode {
                    infrastructureSection
                    leasesSection
                    inspectionSection
                    notesSection
                }
            }
            .padding()
        }
        .navigationTitle(property.displayName ?? "Property Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(item: $selectedFieldForDetail) { field in
            NavigationView {
                FieldDetailView(field: field)
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditPropertyView(property: property, isPresented: $showingEditView)
        }
        .sheet(isPresented: $showingInspectionScheduling) {
           // FarmInspectionSchedulingView(property: property, isPresented: $showingInspectionScheduling)
        }
        .dataLoadingState(
            isLoading: loadingState.isLoading,
            hasError: loadingState.hasError,
            errorMessage: loadingState.errorMessage,
            retryAction: loadPropertyData
        )
        .onAppear {
            loadPropertyData()
        }
    }

    private func loadPropertyData() {
        loadingState.setLoading(true)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                PropertyDataLoader.ensurePropertyDataLoaded(property, in: viewContext)
                DispatchQueue.main.async {
                    loadingState.setLoading(false)
                }
            } catch {
                DispatchQueue.main.async {
                    loadingState.setError(error)
                }
            }
        }
    }

    private var propertyInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Property Dashboard")
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                LargeInfoBlock(label: "Property") {
                    Text(property.displayName ?? "N/A")
                }
                InfoBlock(label: "Total Acres:") {
                    Text("\(property.totalAcres, specifier: "%.1f")")
                }
                if isAdvancedMode {
                    HStack {
                        InfoBlock(label: "Tillable Acres") {
                            Text("\(property.tillableAcres, specifier: "%.1f")")
                        }
                        InfoBlock(label: "Pasture Acres") {
                            Text("\(property.pastureAcres, specifier: "%.1f")")
                        }
                    }
                    HStack {
                        InfoBlock(label: "Woodland Acres") {
                            Text("\(property.woodlandAcres, specifier: "%.1f")")
                        }
                        InfoBlock(label: "Wetland Acres") {
                            Text("\(property.wetlandAcres, specifier: "%.1f")")
                        }
                    }
                    HStack {
                        InfoBlock(label: "Has Irrigation") {
                            Text(property.hasIrrigation ? "Yes" : "No")
                        }
                    }
                    if let county = property.county, let state = property.state {
                        InfoBlock(label: "Location") {
                            Text("\(county), \(state)")
                        }
                    }
                }
            }
        }
    }

    @State private var showingCreateFieldView = false

    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Fields")
                Spacer()
                Button(action: {
                    showingCreateFieldView = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            if let fields = property.fields?.allObjects as? [Field], !fields.isEmpty {
                ForEach(fields.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.id) { field in
                    Button(action: {
                        selectedFieldForDetail = field
                    }) {
                        FieldRowWithPrefetch(field: field)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                EmptyStateView(
                    title: "No Fields",
                    message: "Add fields to track cultivation areas",
                    systemImage: "grid",
                    actionTitle: "Add Field"
                ) {
                    showingCreateFieldView = true
                }
                .frame(height: 250)
            }
        }
        .sheet(isPresented: $showingCreateFieldView) {
            CreateFieldView(property: property)
        }
    }

    private var infrastructureSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Infrastructure")
                Spacer()
                NavigationLink(destination: CreateInfrastructureView(property: property)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            if let infrastructure = property.infrastructure?.allObjects as? [Infrastructure], !infrastructure.isEmpty {
                ForEach(infrastructure.sorted(by: { ($0.type ?? "") < ($1.type ?? "") }), id: \.id) { item in
                    InfrastructureRow(infrastructure: item)
                }
            } else {
                EmptyStateView(
                    title: "No Infrastructure",
                    message: "Add infrastructure to track farm assets",
                    systemImage: "building.2",
                    actionTitle: "Add Infrastructure"
                ) {}
                .frame(height: 120)
            }
        }
    }
    
    /// Row view for displaying a single infrastructure item
    struct InfrastructureRow: View {
        let infrastructure: Infrastructure
        @State private var showDetail = false

        var body: some View {
            Button(action: {
                showDetail = true
            }) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    // Icon
                    Text(iconForInfrastructure)
                        .font(.title2)

                    // Name and details
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(infrastructure.name ?? "Unnamed Infrastructure")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        HStack {
                            Text(infrastructure.type?.capitalized ?? "Unknown Type")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            Spacer()

                            Text(infrastructure.status?.capitalized ?? "Unknown Status")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(statusColor)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
                .padding(.vertical, AppTheme.Spacing.small)
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showDetail) {
                InfrastructureDetailView(infrastructure: infrastructure)
            }
        }

        private var iconForInfrastructure: String {
            switch infrastructure.type?.lowercased() {
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

        private var statusColor: Color {
            switch infrastructure.status?.lowercased() {
            case "excellent", "good":
                return AppTheme.Colors.success
            case "fair":
                return AppTheme.Colors.warning
            case "poor", "needs repair":
                return AppTheme.Colors.error
            default:
                return AppTheme.Colors.textSecondary
            }
        }
    }

    private var leasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Leases")
            if let leases = property.leases?.allObjects as? [Lease], !leases.isEmpty {
                ForEach(leases.sorted(by: { ($0.startDate ?? Date.distantPast) > ($1.startDate ?? Date.distantPast) }), id: \.id) { lease in
                    LeaseRow(lease: lease)
                }
            } else {
                Text("No active leases")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    /// Row view for displaying a lease summary using NavigationLink
    struct LeaseRow: View {
        let lease: Lease

        var body: some View {
            NavigationLink(destination: LeaseDetailView(lease: lease)) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(lease.leaseType?.capitalized ?? "Unknown Lease Type")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if let startDate = lease.startDate {
                            Text("Started: \(startDate, style: .date)")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }

                        Text(lease.status?.capitalized ?? "Unknown Status")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(statusColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
                .padding(.vertical, AppTheme.Spacing.small)
            }
        }

        private var statusColor: Color {
            switch lease.status?.lowercased() {
            case "active": return AppTheme.Colors.success
            case "expired": return AppTheme.Colors.error
            case "pending": return AppTheme.Colors.warning
            default: return AppTheme.Colors.textSecondary
            }
        }
    }
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Property Notes")
            if let notes = property.notes, !notes.isEmpty {
                InfoBlock(label: "Notes:") {
                    Text(notes)
                }
            }
        }
    }

    private var inspectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Farm Inspections")
            if let recentInspections = getRecentFarmInspections(), !recentInspections.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Recent Inspections")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    ForEach(recentInspections.prefix(3), id: \.id) { inspection in
                       FarmInspectionRow(inspection: inspection)
                    }
                    if recentInspections.count > 3 {
                        Button("View All Inspections") {}
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            VStack(spacing: AppTheme.Spacing.small) {
                CommonActionButton(
                    title: "Schedule Farm Inspection",
                    style: .outline,
                    action: scheduleFarmInspection
                )
                NavigationLink(destination: InspectionManagementView()) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.Colors.compliance)
                        Text("Manage All Inspections")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .font(.caption)
                    }
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
    }
    /// Row view for displaying a farm inspection summary
    struct FarmInspectionRow: View {
        let inspection: Inspection

        var body: some View {
            NavigationLink(destination: InspectionDetailView(inspection: inspection)) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(inspection.title ?? "Taco Inspection")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("By \(inspection.inspectorName)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                        MetadataTag(
                            text: inspection.title ?? "TacoInspection",
                            backgroundColor: AppTheme.Colors.backgroundSecondary,
                            textColor: AppTheme.Colors.textDataFieldNormal
                        )

                        Text(inspection.completedDate!, style: .date)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
                .padding(.vertical, AppTheme.Spacing.small)
            }
        }
    }
    
    
    struct FarmInspectionDisplayData: Identifiable {
        let id: UUID
        let name: String
        let category: InspectionCategory
        let completedAt: Date
        let inspector: String
        let status: InspectionStatus
    }


    private func getRecentFarmInspections() -> [Inspection]? {
        guard let fields = property.fields?.allObjects as? [Field], !fields.isEmpty else {
            return nil
        }

        var inspections: [Inspection] = []

        for field in fields {
            if let fieldInspections = field.inspections?.allObjects as? [Inspection] {
                inspections.append(contentsOf: fieldInspections)
            }
        }

        // Sort by completedDate descending
        let sorted = inspections
            .sorted(by: { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) })

        
        return sorted
    }
    

    private func scheduleFarmInspection() {
        showingInspectionScheduling = true
    }
}
extension InspectionCategory {
    static func from(rawValue: String) -> InspectionCategory {
        return InspectionCategory(rawValue: rawValue.lowercased()) ?? .grow
    }
}

