//
//  FieldManagementViews.swift
//  MaterialsAndPractices
//
//  Comprehensive field management views including list, detail, and edit functionality.
//  Supports the common photo system and master-detail relationships.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

// MARK: - Field Row Component

/// Row component for displaying field information in lists
struct FieldRow: View {
    let field: Field
    @State private var latestSoilTest: SoilTest?
    
    var body: some View {
        NavigationLink(destination: FieldDetailView(field: field)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(field.name ?? "Unnamed Field")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        Text("\(field.acres, specifier: "%.1f") acres")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if field.hasDrainTile {
                            MetadataTag(
                                text: "Drain Tile",
                                backgroundColor: AppTheme.Colors.info
                            )
                        }
                        
                        // Soil test status tag
                        if let soilTest = latestSoilTest {
                            // Show pH with appropriate color if recent test exists
                            if isRecentTest(soilTest) {
                                MetadataTag(
                                    text: "pH \(soilTest.ph, specifier: "%.1f")",
                                    backgroundColor: colorForPH(soilTest.ph)
                                )
                            } else {
                                // Old test - show warning
                                MetadataTag(
                                    text: "Old Test",
                                    backgroundColor: AppTheme.Colors.warning
                                )
                            }
                        } else {
                            // No test - show yellow warning
                            MetadataTag(
                                text: "No pH Test",
                                backgroundColor: AppTheme.Colors.warning
                            )
                        }
                    }
                }
                
                Spacer()
                
                if field.photoData != nil {
                    Image(systemName: "photo.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.caption)
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
        .onAppear {
            loadLatestSoilTest()
        }
    }
    
    private func loadLatestSoilTest() {
        if let soilTests = field.soilTests?.allObjects as? [SoilTest] {
            latestSoilTest = soilTests
                .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
                .first
        }
    }
    
    private func isRecentTest(_ soilTest: SoilTest) -> Bool {
        guard let testDate = soilTest.date else { return false }
        let daysSinceTest = Calendar.current.dateComponents([.day], from: testDate, to: Date()).day ?? 0
        return daysSinceTest <= 1095 // 3 years
    }
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5, 8.0...: return AppTheme.Colors.error
        case 5.5..<6.0, 7.5..<8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
}

// MARK: - Field Detail View

/// Detailed view for field information and management
struct FieldDetailView: View {
    let field: Field
    @State private var isEditing = false
    @State private var showingPhotoCapture = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Field Information Section
                fieldInformationSection
                
                // Photo Section
                photoSection
                
                // Soil Tests Section
                soilTestsSection
                
                // Wells Section
                wellsSection
                
                // Grows Section
                growsSection
            }
            .padding()
        }
        .navigationTitle(field.name ?? "Field")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditFieldView(field: field, isPresented: $isEditing)
        }
        .sheet(isPresented: $showingPhotoCapture) {
            FieldPhotoCaptureView(field: field, isPresented: $showingPhotoCapture)
        }
    }
    
    // MARK: - Sections
    
    private var fieldInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Field Information")
            
            VStack(spacing: AppTheme.Spacing.small) {
                CommonInfoRow(label: "Acres:") {
                    Text("\(field.acres, specifier: "%.1f")")
                }
                
                CommonInfoRow(label: "Drain Tile:") {
                    Text(field.hasDrainTile ? "Yes" : "No")
                }
                
                if let property = field.property {
                    CommonInfoRow(label: "Property:") {
                        Text(property.displayName ?? "Unnamed Property")
                    }
                }
                
                if let notes = field.notes, !notes.isEmpty {
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
            
            if let photoData = field.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                EmptyStateView(
                    title: "No Photos",
                    message: "Add photos to document field conditions",
                    systemImage: "camera",
                    actionTitle: "Take Photo"
                ) {
                    showingPhotoCapture = true
                }
                .frame(height: 150)
            }
        }
    }
    
    private var soilTestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Soil Tests")
                
                Spacer()
                
                NavigationLink(destination: CreateSoilTestView(field: field)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let soilTests = field.soilTests?.allObjects as? [SoilTest],
               !soilTests.isEmpty {
                
                // Show latest soil test pH spectrum
                if let latestTest = soilTests.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }).first {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Current pH Level")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        PHSpectrumView(currentPH: latestTest.ph, showLabels: false)
                            .frame(height: 40)
                    }
                    .padding(.bottom, AppTheme.Spacing.small)
                }
                
                ForEach(soilTests.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }), id: \.id) { soilTest in
                    SoilTestRow(soilTest: soilTest)
                }
            } else {
                Text("No soil tests recorded")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var wellsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Wells")
                
                Spacer()
                
                NavigationLink(destination: CreateWellView(field: field)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let wells = field.wells?.allObjects as? [Well],
               !wells.isEmpty {
                ForEach(wells.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.id) { well in
                    WellRow(well: well)
                }
            } else {
                Text("No wells recorded")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var growsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Associated Grows")
            
            if let grows = field.grows?.allObjects as? [Grow],
               !grows.isEmpty {
                ForEach(grows.sorted(by: { ($0.title ?? "") < ($1.title ?? "") }), id: \.timestamp) { grow in
                    GrowSummaryRow(grow: grow)
                }
            } else {
                Text("No grows in this field")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Edit Field View

/// Form for editing field information
struct EditFieldView: View {
    let field: Field
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var fieldName: String
    @State private var fieldAcres: String
    @State private var fieldHasDrainTile: Bool
    @State private var fieldNotes: String
    
    init(field: Field, isPresented: Binding<Bool>) {
        self.field = field
        self._isPresented = isPresented
        self._fieldName = State(initialValue: field.name ?? "")
        self._fieldAcres = State(initialValue: String(field.acres))
        self._fieldHasDrainTile = State(initialValue: field.hasDrainTile)
        self._fieldNotes = State(initialValue: field.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Field Details") {
                    TextField("Field Name", text: $fieldName)
                    
                    TextField("Acres", text: $fieldAcres)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Has Drain Tile", isOn: $fieldHasDrainTile)
                    
                    TextField("Notes", text: $fieldNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveField()
                    }
                    .disabled(fieldName.isEmpty)
                }
            }
        }
    }
    
    private func saveField() {
        field.name = fieldName.isEmpty ? nil : fieldName
        field.acres = Double(fieldAcres) ?? 0.0
        field.hasDrainTile = fieldHasDrainTile
        field.notes = fieldNotes.isEmpty ? nil : fieldNotes
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving field: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Row for displaying soil test information
struct SoilTestRow: View {
    let soilTest: SoilTest
    
    var body: some View {
        NavigationLink(destination: SoilTestDetailView(soilTest: soilTest)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    if let date = soilTest.date {
                        Text(date, style: .date)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    
                    if let labName = soilTest.lab?.name ?? soilTest.labName {
                        Text(labName)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    Text("pH: \(soilTest.ph, specifier: "%.1f")")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(colorForPH(soilTest.ph))
                        .fontWeight(.semibold)
                    
                    Text("OM: \(soilTest.omPct, specifier: "%.1f")%")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5, 8.0...: return AppTheme.Colors.error
        case 5.5..<6.0, 7.5..<8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
}

/// Row for displaying well information
struct WellRow: View {
    let well: Well
    
    var body: some View {
        NavigationLink(destination: WellDetailView(well: well)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(well.name ?? "Unnamed Well")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let wellType = well.wellType {
                        Text(wellType.capitalized)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let status = well.status {
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
        case "active":
            return AppTheme.Colors.success
        case "inactive", "abandoned":
            return AppTheme.Colors.error
        case "maintenance":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.secondary
        }
    }
}

/// Simplified grow row for field detail view
struct GrowSummaryRow: View {
    let grow: Grow
    
    var body: some View {
        NavigationLink(destination: GrowDetailView(growViewModel: GrowDetailViewModel(grow: grow))) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(grow.title ?? "Unnamed Grow")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let cultivar = grow.cultivar {
                        Text(cultivar.name ?? "Unknown Cultivar")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let plantedDate = grow.plantedDate {
                    Text(plantedDate, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
}

// MARK: - Photo Capture for Fields

/// Photo capture view specifically for fields
struct FieldPhotoCaptureView: View {
    let field: Field
    @Binding var isPresented: Bool
    
    var body: some View {
        GenericPhotoCaptureView(isPresented: $isPresented) { image in
            // Compress image and save to field
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                field.photoData = imageData
                
                // Save context
                do {
                    try field.managedObjectContext?.save()
                } catch {
                    print("Error saving field photo: \(error)")
                }
            }
        }
    }
}

// MARK: - Soil Test Flow Views

/// Main soil test creation flow with education and field selection
struct SoilTestFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingEducation = false
    @State private var selectedField: Field?
    @State private var hasSeenEducation = false
    
    var body: some View {
        Group {
            if shouldShowEducation {
                SoilTestEducationView(isPresented: .constant(true)) {
                    hasSeenEducation = true
                }
            } else if selectedField == nil {
                FieldSelectionTileView { field in
                    selectedField = field
                }
            } else if let field = selectedField {
                CreateSoilTestView(field: field)
            }
        }
    }
    
    private var shouldShowEducation: Bool {
        // Check if user has ever created a soil test
        return !hasSeenEducation && !hasExistingSoilTests
    }
    
    private var hasExistingSoilTests: Bool {
        // This would typically check UserDefaults or Core Data for existing tests
        // For now, we'll assume first time users need education
        return false
    }
}

/// Placeholder for soil test creation view - now redirects to full flow
struct CreateSoilTestView: View {
    let field: Field
    
    var body: some View {
        CreateSoilTestView(field: field)
    }
}

/// Placeholder for well creation view
struct CreateWellView: View {
    let field: Field
    
    var body: some View {
        Text("Create Well - Coming Soon")
            .navigationTitle("New Well")
    }
}

/// Placeholder for well detail view
struct WellDetailView: View {
    let well: Well
    
    var body: some View {
        Text("Well Detail - Coming Soon")
            .navigationTitle(well.name ?? "Well")
    }
}