//
//  CreateGrowFromCultivarView.swift
//  MaterialsAndPractices
//
//  Create a new grow pre-populated with cultivar information.
//  Reuses the core grow creation functionality while providing a streamlined
//  workflow specifically for creating grows from cultivar detail views.
//
//  Features:
//  - Pre-populated cultivar selection
//  - Streamlined form focused on essential grow details
//  - Integration with existing grow management system
//  - Full location and property management
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Create grow view specifically designed for cultivar-initiated grow creation
/// Provides a pre-populated form with the selected cultivar and streamlined workflow
struct CreateGrowFromCultivarView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    let cultivar: Cultivar
    @Binding var isPresented: Bool
    
    // MARK: - State Properties
    
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var plantedDate: Date = Date()
    @State private var expectedHarvestDate: Date = Date()
    @State private var propertyOwner: String = ""
    @State private var propertyOwnerPhone: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var county: String = ""
    @State private var drivingDirections: String = ""
    @State private var manager: String = ""
    @State private var managerPhone: String = ""
    @State private var notes: String = ""
    @State private var size: String = ""
    
    // Property and field selection
    @State private var selectedProperty: Property?
    @State private var selectedField: Field?
    @State private var showingPropertySelection = false
    @State private var showingFieldSelection = false
    
    // Fetch requests for properties and fields
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.name, ascending: true)]
    ) private var properties: FetchedResults<Property>
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedProperty != nil && selectedField != nil
    }
    
    // MARK: - Initialization
    
    init(cultivar: Cultivar, isPresented: Binding<Bool>) {
        self.cultivar = cultivar
        self._isPresented = isPresented
        
        // Pre-populate name with cultivar
        self._name = State(initialValue: "New \(cultivar.displayName) Grow")
        
        // Pre-populate expected harvest date based on growing days
        if let growingDaysString = cultivar.growingDays,
           let growingDays = CreateGrowFromCultivarView.extractDaysFromString(growingDaysString) {
            let harvestDate = Calendar.current.date(byAdding: .day, value: growingDays, to: Date()) ?? Date()
            self._expectedHarvestDate = State(initialValue: harvestDate)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Organic Certification Banner
                if cultivar.isOrganicCertified {
                    organicCertificationBanner
                }
                
                // Cultivar Information Section
                cultivarInfoSection
                
                // Basic Details Section
                basicDetailsSection
                
                // Property and Field Selection Section
                propertyFieldSelectionSection
                
                // Harvest Calendar Section
                harvestCalendarSection
                
                // Additional Information Section
                additionalInformationSection
                
                // Save Button Section
                saveSection
            }
            .navigationTitle("New Grow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Organic certification banner
    private var organicCertificationBanner: some View {
        Section {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(AppTheme.Colors.organicPractice)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Certified Organic")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.organicPractice)
                    Text("This cultivar meets organic certification standards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(AppTheme.Colors.organicPractice.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    /// Display selected cultivar information
    private var cultivarInfoSection: some View {
        Section("Selected Cultivar") {
            HStack {
                // Cultivar icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(cultivar.emoji ?? "🌱")
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(cultivar.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let family = cultivar.family {
                        Text(family)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if cultivar.isOrganicCertified {
                        Label("Organic Certified", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if let growingDays = cultivar.growingDays {
                    VStack(alignment: .trailing) {
                        Text("Growing Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(growingDays)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// Basic grow details
    private var basicDetailsSection: some View {
        Section("Grow Details") {
            TextField("Grow Name", text: $name)
            DatePicker("Planted Date", selection: $plantedDate, displayedComponents: .date)
            DatePicker("Expected Harvest", selection: $expectedHarvestDate, displayedComponents: .date)
            TextField("Size (acres)", text: $size)
                .keyboardType(.decimalPad)
        }
    }
    
    /// Property and field selection section
    private var propertyFieldSelectionSection: some View {
        Section("Location") {
            // Property Selection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Property")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(selectedProperty?.name ?? "Select Property") {
                        showingPropertySelection = true
                    }
                    .foregroundColor(selectedProperty == nil ? .blue : .primary)
                }
                
                if let property = selectedProperty {
                    VStack(alignment: .leading, spacing: 4) {
                        if let address = property.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let city = property.city, let state = property.state {
                            Text("\(city), \(state)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Field Selection (only show if property is selected)
            if selectedProperty != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Field")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(selectedField?.name ?? "Select Field") {
                            showingFieldSelection = true
                        }
                        .foregroundColor(selectedField == nil ? .blue : .primary)
                    }
                    
                    if let field = selectedField {
                        VStack(alignment: .leading, spacing: 4) {
                            if let size = field.size {
                                Text("Size: \(size) acres")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let soilType = field.soilType {
                                Text("Soil: \(soilType)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPropertySelection) {
            PropertySelectionView(
                properties: Array(properties),
                selectedProperty: $selectedProperty,
                isPresented: $showingPropertySelection
            ) { property in
                selectedProperty = property
                selectedField = nil // Reset field when property changes
                updateOwnerInformation()
            }
        }
        .sheet(isPresented: $showingFieldSelection) {
            if let property = selectedProperty {
                FieldSelectionView(
                    property: property,
                    selectedField: $selectedField,
                    isPresented: $showingFieldSelection
                )
            }
        }
    }
    
    /// Harvest calendar section showing estimated harvest timeline
    private var harvestCalendarSection: some View {
        Section("Harvest Calendar") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.Colors.primary)
                    Text("Growing Timeline")
                        .font(.headline)
                }
                
                if let growingDaysString = cultivar.growingDays,
                   let growingDays = CreateGrowFromCultivarView.extractDaysFromString(growingDaysString) {
                    
                    VStack(spacing: 8) {
                        TimelineRow(
                            title: "Planted",
                            date: plantedDate,
                            icon: "seedling",
                            color: .green
                        )
                        
                        TimelineRow(
                            title: "Expected Harvest",
                            date: expectedHarvestDate,
                            icon: "scissors",
                            color: .orange
                        )
                        
                        HStack {
                            Text("Growing Period:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(growingDays) days")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                } else {
                    Text("No growing timeline available for this cultivar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// Property information section (populated from selected property)
    private var propertyInformationSection: some View {
        Section("Property Information") {
            TextField("Property Owner", text: $propertyOwner)
                .disabled(selectedProperty != nil)
            TextField("Owner Phone", text: $propertyOwnerPhone)
                .keyboardType(.phonePad)
                .disabled(selectedProperty != nil)
            TextField("Address", text: $address)
                .disabled(selectedProperty != nil)
            
            HStack {
                TextField("City", text: $city)
                    .disabled(selectedProperty != nil)
                TextField("State", text: $state)
                    .frame(maxWidth: 80)
                    .disabled(selectedProperty != nil)
            }
            
            HStack {
                TextField("Zip Code", text: $zip)
                    .keyboardType(.numberPad)
                    .disabled(selectedProperty != nil)
                TextField("County", text: $county)
                    .disabled(selectedProperty != nil)
            }
            
            TextField("Manager", text: $manager)
                .disabled(selectedProperty != nil)
            TextField("Manager Phone", text: $managerPhone)
                .keyboardType(.phonePad)
                .disabled(selectedProperty != nil)
                
            if selectedProperty != nil {
                Text("Property information is automatically populated from the selected property")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    /// Additional information section
    private var additionalInformationSection: some View {
        Section("Additional Information") {
            TextField("Driving Directions", text: $drivingDirections)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ZStack(alignment: .topLeading) {
                    if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Any additional information about this grow...")
                            .foregroundColor(Color.secondary.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $notes)
                        .frame(minHeight: 90, maxHeight: 180)
                }
            }
        }
    }
    
    /// Save button section
    private var saveSection: some View {
        Section {
            Button(action: saveGrow) {
                HStack {
                    Spacer()
                    Text("Create Grow")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .disabled(!isFormValid)
            .listRowBackground(isFormValid ? Color.blue : Color.gray)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Save the new grow to Core Data
    private func saveGrow() {
        let newGrow = Grow(context: viewContext)
        newGrow.title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.cultivar = cultivar
        
        // Use selected property and field
        if let selectedProperty = selectedProperty {
            newGrow.property = selectedProperty
        }
        if let selectedField = selectedField {
            newGrow.field = selectedField
            newGrow.locationName = selectedField.name ?? ""
        }
        
        newGrow.plantedDate = plantedDate
        newGrow.harvestDate = expectedHarvestDate
        newGrow.timestamp = Date()
        newGrow.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.county = county.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.drivingDirections = drivingDirections.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.growType = "field"
        newGrow.manager = manager.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.managerPhone = managerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.propertyOwner = propertyOwner.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.propertyOwnerPhone = propertyOwnerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.state = state.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.zip = zip.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Convert size to double if possible, or use field size if available
        if !size.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let sizeValue = Double(size.trimmingCharacters(in: .whitespacesAndNewlines)) {
            newGrow.size = sizeValue
        } else if let fieldSize = selectedField?.size {
            newGrow.size = Double(fieldSize) ?? 0
        }
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            // Handle the error appropriately
            print("Error saving grow: \(error)")
        }
    }
    
    /// Update owner information when property is selected
    private func updateOwnerInformation() {
        guard let property = selectedProperty else { return }
        
        propertyOwner = property.ownerName ?? ""
        propertyOwnerPhone = property.ownerPhone ?? ""
        address = property.address ?? ""
        city = property.city ?? ""
        state = property.state ?? ""
        zip = property.zip ?? ""
        county = property.county ?? ""
        manager = property.managerName ?? ""
        managerPhone = property.managerPhone ?? ""
    }
    
    /// Extract number of days from growing days string
    private static func extractDaysFromString(_ string: String) -> Int? {
        let components = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let numbers = components.compactMap { Int($0) }
        
        if numbers.count >= 2 {
            // If range like "80-90", use the middle value
            return (numbers[0] + numbers[1]) / 2
        } else if let first = numbers.first {
            // If single number, use it
            return first
        }
        
        return nil
    }
}

// MARK: - Helper Views

/// Timeline row component for harvest calendar
struct TimelineRow: View {
    let title: String
    let date: Date
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

/// Property selection sheet view
struct PropertySelectionView: View {
    let properties: [Property]
    @Binding var selectedProperty: Property?
    @Binding var isPresented: Bool
    let onSelection: (Property) -> Void
    
    var body: some View {
        NavigationView {
            List(properties, id: \.id) { property in
                PropertyRow(property: property) {
                    onSelection(property)
                    isPresented = false
                }
            }
            .navigationTitle("Select Property")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// Individual property row component
struct PropertyRow: View {
    let property: Property
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(property.name ?? "Unnamed Property")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let address = property.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let city = property.city, let state = property.state {
                    Text("\(city), \(state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let owner = property.ownerName {
                    Text("Owner: \(owner)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Field selection sheet view
struct FieldSelectionView: View {
    let property: Property
    @Binding var selectedField: Field?
    @Binding var isPresented: Bool
    
    private var fields: [Field] {
        guard let fieldSet = property.fields else { return [] }
        return Array(fieldSet).compactMap { $0 as? Field }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    var body: some View {
        NavigationView {
            List(fields, id: \.id) { field in
                FieldRowView(field: field) {
                    selectedField = field
                    isPresented = false
                }
            }
            .navigationTitle("Select Field")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// Individual field row component
struct FieldRowView: View {
    let field: Field
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(field.name ?? "Unnamed Field")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let size = field.size {
                    Text("Size: \(size) acres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let soilType = field.soilType {
                    Text("Soil: \(soilType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let slope = field.slope {
                    Text("Slope: \(slope)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Functions

/// Extract number of days from growing days string
private func extractDaysFromString(_ string: String) -> Int? {
    let components = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
    let numbers = components.compactMap { Int($0) }
    
    if numbers.count >= 2 {
        // If range like "80-90", use the middle value
        return (numbers[0] + numbers[1]) / 2
    } else if let first = numbers.first {
        // If single number, use it
        return first
    }
    
    return nil
}

// MARK: - Preview Provider

struct CreateGrowFromCultivarView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let cultivar = Cultivar(context: context)
        cultivar.name = "Cherokee Purple Tomato"
        cultivar.family = "Solanaceae"
        cultivar.growingDays = "80-90"
        cultivar.emoji = "🍅"
        cultivar.isOrganicCertified = true
        
        return CreateGrowFromCultivarView(cultivar: cultivar, isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
