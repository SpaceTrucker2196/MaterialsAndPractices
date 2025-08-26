
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
