//
//  EnhancedEditGrowView.swift
//  MaterialsAndPractices
//
//  Enhanced grow creation and editing with field picker functionality.
//  Provides better UX showing farm and field relationships.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Enhanced form for creating and editing grows with field integration
struct ActiveGrowCreateEdit: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Binding var isPresented: Bool
    
    // Grow data
    @State private var name: String = ""
    @State private var selectedSeed: SeedLibrary?
    @State private var selectedField: Field?
    @State private var plantedDate: Date = Date()
    @State private var expectedHarvestDate: Date = Date()
    @State private var notes: String = ""
    @State private var size: String = ""
    
    // Field creation
    @State private var showingCreateField = false
    @State private var showingCreateProperty = false
    
    // Fetch requests
    @FetchRequest(
        entity: SeedLibrary.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SeedLibrary.seedName, ascending: true)]
    ) var seeds: FetchedResults<SeedLibrary>
    
    @FetchRequest(
        entity: Field.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Field.property?.displayName, ascending: true),
            NSSortDescriptor(keyPath: \Field.name, ascending: true)
        ]
    ) var fields: FetchedResults<Field>
    
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) var properties: FetchedResults<Property>
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedSeed != nil &&
        selectedField != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                basicInformationSection
                
                // Field Selection Section
                fieldSelectionSection
                
                // Timeline Section
                timelineSection
                
                // Additional Information Section
                additionalInformationSection
            }
            .navigationTitle("New Grow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGrow()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingCreateField) {
            CreateFieldForGrowView(isPresented: $showingCreateField, onFieldCreated: { field in
                selectedField = field
            })
        }
    }
    
    // MARK: - Sections
    
    private var basicInformationSection: some View {
        Section("Grow Details") {
            TextField("Grow Name", text: $name)
            
            Picker("Seed Library", selection: $selectedSeed) {
                Text("Select Cultivar").tag(nil as SeedLibrary?)
                ForEach(seeds, id: \.self) { seed in
                    VStack(alignment: .leading) {
                        Text(seed.seedName ?? "Unknown")
                            .font(AppTheme.Typography.bodyMedium)
                        if let family = seed.cultivar!.family, !family.isEmpty {
                            Text(family)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    .tag(seed as SeedLibrary?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var fieldSelectionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Text("Field Selection")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Button("Create New Field") {
                        showingCreateField = true
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.primary)
                }
                
                if !fields.isEmpty {
                    Picker("Field", selection: $selectedField) {
                        Text("Select Field").tag(nil as Field?)
                        ForEach(groupedFields, id: \.0) { propertyName, propertyFields in
                            Section(propertyName) {
                                ForEach(propertyFields, id: \.id) { field in
                                    FieldPickerRow(field: field)
                                        .tag(field as Field?)
                                }
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } else {
                    VStack(spacing: AppTheme.Spacing.small) {
                        Text("No fields available")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Button("Create Your First Field") {
                            showingCreateField = true
                        }
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                
                // Show selected field information
                if let selectedField = selectedField {
                    SelectedFieldInfo(field: selectedField)
                }
            }
        }
    }
    
    private var timelineSection: some View {
        Section("Timeline") {
            DatePicker("Planted Date", selection: $plantedDate, displayedComponents: .date)
            
            DatePicker("Expected Harvest", selection: $expectedHarvestDate, displayedComponents: .date)
            
            TextField("Size (acres)", text: $size)
                .keyboardType(.decimalPad)
        }
    }
    
    private var additionalInformationSection: some View {
        Section("Additional Information") {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Groups fields by property for better picker organization
    private var groupedFields: [(String, [Field])] {
        let fieldsByProperty = Dictionary(grouping: fields) { field in
            field.property?.displayName ?? "Unknown Property"
        }
        
        return fieldsByProperty.sorted { $0.key < $1.key }
    }
    
    // MARK: - Methods
    
    private func saveGrow() {
        let newGrow = Grow(context: viewContext)
        newGrow.title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.seed = selectedSeed
        newGrow.field = selectedField
        newGrow.plantedDate = plantedDate
        newGrow.harvestDate = expectedHarvestDate
        newGrow.size = Double(size.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        newGrow.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.timestamp = Date()
        
        // Set location information from field/property
        if let field = selectedField,
           let property = field.property {
            newGrow.locationName = "\(property.displayName ?? "Property") - \(field.name ?? "Field")"
            newGrow.county = property.county
            newGrow.state = property.state
        }
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving grow: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Row for displaying field information in picker
struct FieldPickerRow: View {
    let field: Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(field.name ?? "Unnamed Field")
                .font(AppTheme.Typography.bodyMedium)
            
            Text("\(field.acres, specifier: "%.1f") acres")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

/// Information display for selected field
struct SelectedFieldInfo: View {
    let field: Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.success)
                Text("Selected Field")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.success)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text("Farm: \(field.property?.displayName ?? "Unknown")")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Field: \(field.name ?? "Unknown") (\(field.acres, specifier: "%.1f") acres)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let county = field.property?.county,
                   let state = field.property?.state {
                    Text("Location: \(county), \(state)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// View for creating a new field during grow creation
struct CreateFieldForGrowView: View {
    @Binding var isPresented: Bool
    let onFieldCreated: (Field) -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedProperty: Property?
    @State private var fieldName = ""
    @State private var fieldAcres = ""
    @State private var hasDrainTile = false
    
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) var properties: FetchedResults<Property>
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Property") {
                    if !properties.isEmpty {
                        Picker("Property", selection: $selectedProperty) {
                            Text("Select Property").tag(nil as Property?)
                            ForEach(properties, id: \.id) { property in
                                Text(property.displayName ?? "Unnamed Property")
                                    .tag(property as Property?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    } else {
                        Text("No properties available. Create a property first.")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Section("Field Details") {
                    TextField("Field Name", text: $fieldName)
                    
                    TextField("Acres", text: $fieldAcres)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Has Drain Tile", isOn: $hasDrainTile)
                }
            }
            .navigationTitle("Create Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createField()
                    }
                    .disabled(selectedProperty == nil || fieldName.isEmpty || fieldAcres.isEmpty)
                }
            }
        }
    }
    
    private func createField() {
        guard let property = selectedProperty else { return }
        
        let newField = Field(context: viewContext)
        newField.id = UUID()
        newField.name = fieldName
        newField.acres = Double(fieldAcres) ?? 0.0
        newField.hasDrainTile = hasDrainTile
        newField.property = property
        
        do {
            try viewContext.save()
            onFieldCreated(newField)
            isPresented = false
        } catch {
            print("Error creating field: \(error)")
        }
    }
}

// MARK: - Preview Provider

struct EnhancedEditGrowView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveGrowCreateEdit(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
