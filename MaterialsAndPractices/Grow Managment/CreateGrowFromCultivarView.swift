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
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                // Cultivar Information Section
                cultivarInfoSection
                
                // Basic Details Section
                basicDetailsSection
                
                // Property Information Section
                propertyInformationSection
                
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
            TextField("Location", text: $location)
            DatePicker("Planted Date", selection: $plantedDate, displayedComponents: .date)
            DatePicker("Expected Harvest", selection: $expectedHarvestDate, displayedComponents: .date)
            TextField("Size (acres)", text: $size)
                .keyboardType(.decimalPad)
        }
    }
    
    /// Property information section
    private var propertyInformationSection: some View {
        Section("Property Information") {
            TextField("Property Owner", text: $propertyOwner)
            TextField("Owner Phone", text: $propertyOwnerPhone)
                .keyboardType(.phonePad)
            TextField("Address", text: $address)
            
            HStack {
                TextField("City", text: $city)
                TextField("State", text: $state)
                    .frame(maxWidth: 80)
            }
            
            HStack {
                TextField("Zip Code", text: $zip)
                    .keyboardType(.numberPad)
                TextField("County", text: $county)
            }
            
            TextField("Manager", text: $manager)
            TextField("Manager Phone", text: $managerPhone)
                .keyboardType(.phonePad)
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
        newGrow.locationName = location.trimmingCharacters(in: .whitespacesAndNewlines)
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
        
        // Convert size to double if possible
        if let sizeValue = Double(size.trimmingCharacters(in: .whitespacesAndNewlines)) {
            newGrow.size = sizeValue
        }
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            // Handle the error appropriately
            print("Error saving grow: \(error)")
        }
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
