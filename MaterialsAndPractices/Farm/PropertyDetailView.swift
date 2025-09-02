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
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // MARK: - Property Information Section
                propertyInformationSection
                fieldsSection
                // MARK: - Photo Management Section
                //photoManagementSection
                
                // MARK: - Advanced Sections (only in advanced mode)
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
        .sheet(isPresented: $showingEditView) {
            EditPropertyView(property: property, isPresented: $showingEditView)
        }
        .sheet(isPresented: $showingInspectionScheduling) {
            FarmInspectionSchedulingView(property: property, isPresented: $showingInspectionScheduling)
        }
    }
    
    // MARK: - Section Components
    
    /// Section displaying comprehensive property information
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
                    HStack(){
                        InfoBlock(label: "Tillable Acres") {
                            Text("\(property.tillableAcres, specifier: "%.1f")")
                        }
                        InfoBlock(label: "Pasture Acres") {
                            Text("\(property.pastureAcres, specifier: "%.1f")")
                        }
                    }
                    HStack(){
                        InfoBlock(label: "Woodland Acres") {
                            Text("\(property.woodlandAcres, specifier: "%.1f")")
                        }
                        InfoBlock(label: "Wetland Acres") {
                            Text("\(property.wetlandAcres, specifier: "%.1f")")
                        }
                    }
                    HStack(){
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
    
    /// Section for photo management with tile interface
//    private var photoManagementSection: some View {
//        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
//            HStack {
//                SectionHeader(title: "Photos")
//                
//                Spacer()
//                
//                Button(action: {
//                    showingPhotoCapture = true
//                }) {
//                    Image(systemName: "camera.fill")
//                        .foregroundColor(AppTheme.Colors.primary)
//                }
//            }
//            
//            PhotoGalleryView(property: property)
//        }
//        .sheet(isPresented: $showingPhotoCapture) {
//            PhotoCaptureView(property: property, isPresented: $showingPhotoCapture)
//        }
//    }
//    
    /// Section displaying fields (advanced mode only)
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
                    FieldRow(field: field)
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
    /// Section displaying infrastructure (advanced mode only)
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
                ) {
                    // This will be handled by the NavigationLink above
                }
                .frame(height: 120)
            }
        }
    }
    
    /// Section displaying leases (advanced mode only)
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
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing:AppTheme.Spacing.medium){
            SectionHeader(title: "Property Notes")
            if let notes = property.notes, !notes.isEmpty {
                InfoBlock(label: "Notes:") {
                    Text(notes)
                }
            }
        }
    }
    
    /// Section for inspection management and assignment
    private var inspectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Farm Inspections")
            
            // Recent inspections for this farm
            if let recentInspections = getRecentFarmInspections(), !recentInspections.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Recent Inspections")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(recentInspections.prefix(3), id: \.id) { inspection in
                        FarmInspectionRow(inspection: inspection)
                    }
                    
                    if recentInspections.count > 3 {
                        Button("View All Inspections") {
                            // Navigate to full inspection list for this farm
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            
            // Inspection actions
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
    
    /// Gets recent inspections for this farm
    private func getRecentFarmInspections() -> [FarmInspectionDisplayData]? {
        // This would fetch actual inspection data from Core Data
        // For now, return sample data if farm has some activity
        guard let fields = property.fields?.allObjects as? [Field], !fields.isEmpty else {
            return nil
        }
        
        return [
            FarmInspectionDisplayData(
                id: UUID(),
                name: "Organic Certification Inspection",
                category: .organicManagement,
                completedAt: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                inspector: "Certification Board",
                status: .completed
            ),
            FarmInspectionDisplayData(
                id: UUID(),
                name: "General Farm Inspection",
                category: .healthSafety,
                completedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                inspector: "Safety Inspector",
                status: .completed
            )
        ]
    }
    
    /// Opens the inspection scheduling view for this farm
    private func scheduleFarmInspection() {
        showingInspectionScheduling = true
    }
}

/// Helper view for field information rows
//struct FieldRow: View {
//    let field: Field
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
//                Text(field.name ?? "Unknown Field")
//                    .font(AppTheme.Typography.bodyMedium)
//                    .foregroundColor(AppTheme.Colors.textPrimary)
//
//                Text("\(field.acres, specifier: "%.1f") acres")
//                    .font(AppTheme.Typography.bodySmall)
//                    .foregroundColor(AppTheme.Colors.textSecondary)
//            }
//
//            Spacer()
//
//            if field.hasDrainTile {
//                Image(systemName: "drop.triangle.fill")
//                    .foregroundColor(AppTheme.Colors.info)
//                    .font(AppTheme.Typography.labelMedium)
//            }
//        }
//        .padding(.vertical, AppTheme.Spacing.extraSmall)
//    }
//}
//
/// Helper view for infrastructure information rows
struct InfrastructureRow: View {
    let infrastructure: Infrastructure
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack {
                // Infrastructure icon
                Text(iconForInfrastructure)
                    .font(.title3)
                
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
        .sheet(isPresented: $showingDetail) {
            InfrastructureDetailView(infrastructure: infrastructure)
        }
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

/// Helper view for lease information rows
struct LeaseRow: View {
    let lease: Lease
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(lease.leaseType?.capitalized ?? "Unknown Type")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let startDate = lease.startDate {
                    Text("Started: \(startDate, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Text(lease.status?.capitalized ?? "Unknown Status")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(leaseStatusColor(for: lease.status))
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.extraSmall)
    }
    
    private func leaseStatusColor(for status: String?) -> Color {
        switch status?.lowercased() {
        case "active":
            return AppTheme.Colors.success
        case "expired":
            return AppTheme.Colors.error
        case "pending":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - Preview Provider

struct PropertyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PropertyDetailView(property: Property(), isAdvancedMode: true)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}

// MARK: - Supporting View Components for Farm Inspections

/// Display data for farm inspections
struct FarmInspectionDisplayData {
    let id: UUID
    let name: String
    let category: InspectionCategory
    let completedAt: Date
    let inspector: String
    let status: InspectionStatus
}

/// Row view for displaying farm inspection information
struct FarmInspectionRow: View {
    let inspection: FarmInspectionDisplayData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(inspection.name)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("By \(inspection.inspector)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                MetadataTag(
                    text: inspection.status.displayName,
                    backgroundColor: inspection.status.color.opacity(0.2),
                    textColor: inspection.status.color
                )
                
                Text(inspection.completedAt, style: .date)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Inspection scheduling view for farms
struct FarmInspectionSchedulingView: View {
    let property: Property
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTemplate: InspectionCategory = .organicManagement
    @State private var inspectionName: String = ""
    @State private var scheduledTime: InspectionTime = .morning
    @State private var frequency: InspectionFrequency = .oneTime
    @State private var selectedInspectors: [UUID] = []
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Inspection Details") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        TextField("Inspection Name", text: $inspectionName)
                        
                        Text("Suggested: Organic Certification, Farm Safety Audit, General Compliance")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Picker("Template Category", selection: $selectedTemplate) {
                        ForEach(InspectionCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }.tag(category)
                        }
                    }
                    .onChange(of: selectedTemplate) { newCategory in
                        updateSuggestedName(for: newCategory)
                    }
                    
                    Picker("Scheduled Time", selection: $scheduledTime) {
                        ForEach(InspectionTime.allCases, id: \.self) { time in
                            VStack(alignment: .leading) {
                                Text(time.rawValue)
                                Text(time.timeRange)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }.tag(time)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(InspectionFrequency.allCases, id: \.self) { freq in
                            HStack {
                                Image(systemName: freq.icon)
                                Text(freq.rawValue)
                            }.tag(freq)
                        }
                    }
                }
                
                Section("Organic Certification & Compliance") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(AppTheme.Colors.compliance)
                            Text("Organic System Plan Review")
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        
                        Text("Comprehensive review of farm's organic system plan and practices")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Image(systemName: "leaf.arrow.circlepath")
                                .foregroundColor(AppTheme.Colors.organicPractice)
                            Text("Transition Period Monitoring")
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        
                        Text("Track transition from conventional to organic farming practices")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("Record Keeping Audit")
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        
                        Text("Verify comprehensive record keeping for organic certification")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Section("Farm Information") {
                    HStack {
                        Text("Farm Name:")
                        Spacer()
                        Text(property.displayName ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Acres:")
                        Spacer()
                        Text("\(property.totalAcres, specifier: "%.1f")")
                            .foregroundColor(.secondary)
                    }
                    
                    if let county = property.county, let state = property.state {
                        HStack {
                            Text("Location:")
                            Spacer()
                            Text("\(county), \(state)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let fields = property.fields?.allObjects as? [Field] {
                        HStack {
                            Text("Fields:")
                            Spacer()
                            Text("\(fields.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Additional Notes") {
                    TextField("Inspection notes or requirements", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Schedule Farm Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        scheduleInspection()
                    }
                    .disabled(inspectionName.isEmpty)
                }
            }
        }
    }
    
    private func scheduleInspection() {
        // Here we would create the inspection using the inspection system
        // For now, we'll just dismiss the view
        // TODO: Integrate with InspectionCreationWorkflowView or create inspection directly
        
        print("Scheduling inspection: \(inspectionName) for farm: \(property.displayName ?? "Unknown")")
        print("Category: \(selectedTemplate.displayName)")
        print("Time: \(scheduledTime.rawValue)")
        print("Frequency: \(frequency.rawValue)")
        
        isPresented = false
    }
    
    /// Updates suggested inspection name based on category and farm context
    private func updateSuggestedName(for category: InspectionCategory) {
        if inspectionName.isEmpty {
            let farmName = property.displayName ?? "Farm"
            switch category {
            case .organicManagement:
                inspectionName = "Organic Certification - \(farmName)"
            case .healthSafety:
                inspectionName = "Farm Safety Audit - \(farmName)"
            case .infrastructure:
                inspectionName = "Farm Infrastructure Review - \(farmName)"
            case .equipment:
                inspectionName = "Equipment Inspection - \(farmName)"
            case .grow:
                inspectionName = "General Farm Inspection - \(farmName)"
            }
        }
    }
}
