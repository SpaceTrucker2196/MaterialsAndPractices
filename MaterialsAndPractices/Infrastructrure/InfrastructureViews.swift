
import SwiftUI
import CoreData

// MARK: - Quick Action Button

struct InfastructureQuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }

                Text(title)
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Infrastructure Tile

struct InfrastructureTile: View {
    let infrastructure: Infrastructure

    var body: some View {
        NavigationLink(destination: InfrastructureDetailView(infrastructure: infrastructure)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(infrastructure.name ?? "Unnamed")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                if let status = infrastructure.status {
                    MetadataTag(
                        text: status.capitalized,
                        backgroundColor: statusColor(for: status)
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "good", "excellent":
            return AppTheme.Colors.success
        case "poor", "damaged":
            return AppTheme.Colors.error
        case "fair", "maintenance needed":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.secondary
        }
    }
}

// MARK: - All Infrastructure List View
struct AllInfrastructureRow: View {
    let infrastructure: Infrastructure
    @State private var showingDetail = false
    @State private var showingActionSheet = false
    
    var body: some View {
        HStack {
            // Infrastructure icon
            Text(iconForInfrastructure)
                .font(.title2)
                .frame(width: 40)
            
            // Infrastructure information
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(infrastructure.name ?? "Unnamed Infrastructure")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack {
                    Text(infrastructure.type?.capitalized ?? "Unknown Type")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: AppTheme.Spacing.tiny) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(infrastructure.status?.capitalized ?? "Unknown")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(statusColor)
                    }
                }
                
                if let property = infrastructure.property {
                    Text("📍 \(property.displayName ?? "Unknown Farm")")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Action button
            Button(action: {
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            InfrastructureDetailView(infrastructure: infrastructure)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Infrastructure Actions"),
                buttons: [
                    .default(Text("View Details")) {
                        showingDetail = true
                    },
                    .default(Text("Edit")) {
                        editInfrastructure()
                    },
                    .default(Text("Copy")) {
                        copyInfrastructure()
                    },
                    .cancel()
                ]
            )
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
    
    // MARK: - Actions
    
    private func editInfrastructure() {
        // Implementation would open edit view
        print("Edit infrastructure: \(infrastructure.name ?? "Unknown")")
    }
    
    private func copyInfrastructure() {
        // Implementation would create a copy
        print("Copy infrastructure: \(infrastructure.name ?? "Unknown")")
    }
}

struct AllInfrastructureListView: View {
    @FetchRequest(
        entity: Infrastructure.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Infrastructure.name, ascending: true)
        ]
    ) private var infrastructureItems: FetchedResults<Infrastructure>

    var body: some View {
        List {
            ForEach(infrastructureItems, id: \..self) { item in
                NavigationLink(destination: InfrastructureDetailView(infrastructure: item)) {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Unnamed")
                            .font(AppTheme.Typography.bodyMedium)
                        if let category = item.category {
                            Text(category.capitalized)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("All Infrastructure")
    }
}

/// Row component for displaying infrastructure information in lists
struct InfrastructureDetailRow: View {
    let infrastructure: Infrastructure
    
    var body: some View {
        NavigationLink(destination: InfrastructureDetailView(infrastructure: infrastructure)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(infrastructure.type?.capitalized ?? "Infrastructure")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let installDate = infrastructure.installDate {
                        Text("Installed: \(installDate, style: .date)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let status = infrastructure.status {
                    MetadataTag(
                        text: status.capitalized,
                        backgroundColor: statusColor(for: status)
                    )
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "good", "excellent":
            return AppTheme.Colors.success
        case "poor", "damaged":
            return AppTheme.Colors.error
        case "fair", "maintenance needed":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.secondary
        }
    }
}

// MARK: - Infrastructure Detail View

/// Detailed view for infrastructure information and management
struct InfrastructureDetailView: View {
    let infrastructure: Infrastructure
    @State private var isEditing = false
    @State private var showingPhotoCapture = false
    @State private var showingInspectionScheduling = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Infrastructure Information Section
                infrastructureInformationSection
                
                // Photo Section
                photoSection
                
                // Documents Section
                documentsSection
                
                // Inspection Section
                inspectionSection
            }
            .padding()
        }
        .navigationTitle(infrastructure.type?.capitalized ?? "Infrastructure")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditInfrastructureView(infrastructure: infrastructure, isPresented: $isEditing)
        }
        .sheet(isPresented: $showingPhotoCapture) {
            InfrastructurePhotoCaptureView(infrastructure: infrastructure, isPresented: $showingPhotoCapture)
        }
        .sheet(isPresented: $showingInspectionScheduling) {
            InfrastructureInspectionSchedulingView(infrastructure: infrastructure, isPresented: $showingInspectionScheduling)
        }
    }
    
    // MARK: - Sections
    
    private var infrastructureInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Infrastructure Information")
            
            VStack(spacing: AppTheme.Spacing.small) {
                CommonInfoRow(label: "Type:") {
                    Text(infrastructure.type?.capitalized ?? "Unknown")
                }
                
                CommonInfoRow(label: "Status:") {
                    Text(infrastructure.status?.capitalized ?? "Unknown")
                }
                
                if let installDate = infrastructure.installDate {
                    CommonInfoRow(label: "Install Date:") {
                        Text(installDate, style: .date)
                    }
                }
                
                if let lastServiceDate = infrastructure.lastServiceDate {
                    CommonInfoRow(label: "Last Service:") {
                        Text(lastServiceDate, style: .date)
                    }
                }
                
                if let property = infrastructure.property {
                    CommonInfoRow(label: "Property:") {
                        Text(property.displayName ?? "Unnamed Property")
                    }
                }
                
                if let notes = infrastructure.notes, !notes.isEmpty {
                    CommonInfoRow(label: "Notes:") {
                        Text(notes)
                    }
                }
            }
        }
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Photos")
                
                Spacer()
                
                Button(action: {
                    showingPhotoCapture = true
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            Text("Infrastructure photos will be available with enhanced photo system")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Documents")
            
            if let documents = infrastructure.documents?.allObjects as? [Document],
               !documents.isEmpty {
                ForEach(documents.sorted(by: { ($0.title ?? "") < ($1.title ?? "") }), id: \.id) { document in
                    DocumentRow(document: document)
                }
            } else {
                Text("No documents attached")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Section for inspection management and assignment
    private var inspectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Inspections")
            
            // Recent inspections for this infrastructure
            if let recentInspections = getRecentInfrastructureInspections(), !recentInspections.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Recent Inspections")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(recentInspections.prefix(3), id: \.id) { inspection in
                        InfrastructureInspectionRow(inspection: inspection)
                    }
                    
                    if recentInspections.count > 3 {
                        Button("View All Inspections") {
                            // Navigate to full inspection list for this infrastructure
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            
            // Inspection actions
            VStack(spacing: AppTheme.Spacing.small) {
                CommonActionButton(
                    title: "Schedule Inspection",
                    style: .outline,
                    action: scheduleInfrastructureInspection
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
    
    /// Gets recent inspections for this infrastructure
    private func getRecentInfrastructureInspections() -> [InfrastructureInspectionDisplayData]? {
        // This would fetch actual inspection data from Core Data
        // For now, return sample data if infrastructure has been in service
        guard let installDate = infrastructure.installDate,
              installDate < Date().addingTimeInterval(-30 * 24 * 60 * 60) else { // Installed more than a month ago
            return nil
        }
        
        return [
            InfrastructureInspectionDisplayData(
                id: UUID(),
                name: "Safety Inspection",
                category: .infrastructure,
                completedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                inspector: "Jane Doe",
                status: .completed
            )
        ]
    }
    
    /// Opens the inspection scheduling view for this infrastructure
    private func scheduleInfrastructureInspection() {
        showingInspectionScheduling = true
    }
}

// MARK: - Edit Infrastructure View

/// Form for editing infrastructure information
struct EditInfrastructureView: View {
    let infrastructure: Infrastructure
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var type: String
    @State private var status: String
    @State private var installDate: Date
    @State private var lastServiceDate: Date
    @State private var notes: String
    
    private let infrastructureTypes = ["Fence", "Gate", "Barn", "Storage", "Water System", "Drainage", "Road", "Other"]
    private let statusOptions = ["Excellent", "Good", "Fair", "Poor", "Damaged", "Maintenance Needed"]
    
    init(infrastructure: Infrastructure, isPresented: Binding<Bool>) {
        self.infrastructure = infrastructure
        self._isPresented = isPresented
        self._type = State(initialValue: infrastructure.type ?? "")
        self._status = State(initialValue: infrastructure.status ?? "")
        self._installDate = State(initialValue: infrastructure.installDate ?? Date())
        self._lastServiceDate = State(initialValue: infrastructure.lastServiceDate ?? Date())
        self._notes = State(initialValue: infrastructure.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Infrastructure Details") {
                    Picker("Type", selection: $type) {
                        ForEach(infrastructureTypes, id: \.self) { infraType in
                            Text(infraType).tag(infraType.lowercased())
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { statusOption in
                            Text(statusOption).tag(statusOption.lowercased())
                        }
                    }
                    
                    DatePicker("Install Date", selection: $installDate, displayedComponents: .date)
                    
                    DatePicker("Last Service Date", selection: $lastServiceDate, displayedComponents: .date)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Infrastructure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveInfrastructure()
                    }
                    .disabled(type.isEmpty)
                }
            }
        }
    }
    
    private func saveInfrastructure() {
        infrastructure.type = type.isEmpty ? nil : type
        infrastructure.status = status.isEmpty ? nil : status
        infrastructure.installDate = installDate
        infrastructure.lastServiceDate = lastServiceDate
        infrastructure.notes = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving infrastructure: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Row for displaying document information
struct DocumentRow: View {
    let document: Document
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(document.title ?? "Untitled Document")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let kind = document.kind {
                    Text(kind.capitalized)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let attachedAt = document.attachedAt {
                Text(attachedAt, style: .date)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

// MARK: - Photo Capture for Infrastructure

/// Photo capture view specifically for infrastructure
struct InfrastructurePhotoCaptureView: View {
    let infrastructure: Infrastructure
    @Binding var isPresented: Bool
    
    var body: some View {
        // Placeholder for infrastructure photo capture
        // This would integrate with the common photo system
        NavigationView {
            VStack {
                Text("Infrastructure Photo Capture")
                Text("Will integrate with common photo system")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .navigationTitle("Add Photo")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting View Components for Infrastructure Inspections

/// Display data for infrastructure inspections
struct InfrastructureInspectionDisplayData {
    let id: UUID
    let name: String
    let category: InspectionCategory
    let completedAt: Date
    let inspector: String
    let status: InspectionStatus
}

/// Row view for displaying infrastructure inspection information
struct InfrastructureInspectionRow: View {
    let inspection: InfrastructureInspectionDisplayData
    
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

/// Inspection scheduling view for infrastructure
struct InfrastructureInspectionSchedulingView: View {
    let infrastructure: Infrastructure
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTemplate: InspectionCategory = .infrastructure
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
                        
                        Text("Suggested: Safety Inspection, Maintenance Check, Compliance Review")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Picker("Template Category", selection: $selectedTemplate) {
                        ForEach([InspectionCategory.infrastructure, .equipment, .healthSafety], id: \.self) { category in
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
                
                Section("Safety & Compliance Requirements") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppTheme.Colors.warning)
                            Text("Safety Protocol Verification")
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        
                        Text("Ensure all safety protocols and equipment are properly maintained")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(AppTheme.Colors.compliance)
                            Text("Regulatory Compliance")
                                .font(AppTheme.Typography.bodyMedium)
                        }
                        
                        Text("Verify compliance with local and federal regulations")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Section("Infrastructure Information") {
                    HStack {
                        Text("Type:")
                        Spacer()
                        Text(infrastructure.type?.capitalized ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text(infrastructure.status?.capitalized ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    if let property = infrastructure.property {
                        HStack {
                            Text("Property:")
                            Spacer()
                            Text(property.displayName ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let installDate = infrastructure.installDate {
                        HStack {
                            Text("Installed:")
                            Spacer()
                            Text(installDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Additional Notes") {
                    TextField("Inspection notes or requirements", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Schedule Inspection")
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
        
        print("Scheduling inspection: \(inspectionName) for infrastructure: \(infrastructure.name ?? "Unknown")")
        print("Category: \(selectedTemplate.displayName)")
        print("Time: \(scheduledTime.rawValue)")
        print("Frequency: \(frequency.rawValue)")
        
        isPresented = false
    }
    
    /// Updates suggested inspection name based on category and infrastructure context
    private func updateSuggestedName(for category: InspectionCategory) {
        if inspectionName.isEmpty {
            let infraType = infrastructure.type?.capitalized ?? "Infrastructure"
            switch category {
            case .infrastructure:
                inspectionName = "Safety Inspection - \(infraType)"
            case .equipment:
                inspectionName = "Maintenance Check - \(infraType)"
            case .healthSafety:
                inspectionName = "Safety Review - \(infraType)"
            case .grow:
                inspectionName = "General Inspection - \(infraType)"
            case .organicManagement:
                inspectionName = "Compliance Check - \(infraType)"
            }
        }
    }
}
