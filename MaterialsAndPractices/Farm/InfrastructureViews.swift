//
//  InfrastructureViews.swift
//  MaterialsAndPractices
//
//  Infrastructure management views including list, detail, and edit functionality.
//  Supports the common photo system and master-detail relationships.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

// MARK: - Infrastructure Row Component

/// Row component for displaying infrastructure information in lists
struct InfrastructureRow: View {
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