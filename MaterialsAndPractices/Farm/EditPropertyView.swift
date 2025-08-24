//
//  EditPropertyView.swift
//  MaterialsAndPractices
//
//  Form for creating and editing property information.
//  Follows app conventions for editing views.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Form for creating and editing property information
struct EditPropertyView: View {
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Optional property to edit - if nil, creates new property
    let propertyToEdit: Property?
    
    // Form data
    @State private var farmDisplayName = ""
    @State private var farmCounty = ""
    @State private var farmState = ""
    @State private var farmTotalAcres = ""
    @State private var farmTillableAcres = ""
    @State private var farmPastureAcres = ""
    @State private var farmWoodlandAcres = ""
    @State private var farmWetlandAcres = ""
    @State private var farmHasIrrigation = false
    @State private var farmNotes = ""
    
    /// Computed property to determine if this is editing mode
    private var isEditingMode: Bool {
        propertyToEdit != nil
    }
    
    /// Initialize for creating a new property
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.propertyToEdit = nil
    }
    
    /// Initialize for editing an existing property
    init(property: Property, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self.propertyToEdit = property
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    HStack {
                        Text("Property Name")
                        TextField("Display Name", text: $farmDisplayName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("County")
                        TextField("County", text: $farmCounty)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("State")
                        TextField("State", text: $farmState)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Acreage") {
                    HStack {
                        Text("Total Acres")
                        TextField("0.0", text: $farmTotalAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tillable Acres")
                        TextField("0.0", text: $farmTillableAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Pasture Acres")
                        TextField("0.0", text: $farmPastureAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Woodland Acres")
                        TextField("0.0", text: $farmWoodlandAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Wetland Acres")
                        TextField("0.0", text: $farmWetlandAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Features") {
                    Toggle("Has Irrigation", isOn: $farmHasIrrigation)
                }
                
                Section("Notes") {
                    TextEditor(text: $farmNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditingMode ? "Edit Farm" : "Create New Farm")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Populate fields when editing existing property
                if let property = propertyToEdit {
                    farmDisplayName = property.displayName ?? ""
                    farmCounty = property.county ?? ""
                    farmState = property.state ?? ""
                    farmTotalAcres = String(property.totalAcres)
                    farmTillableAcres = String(property.tillableAcres)
                    farmPastureAcres = String(property.pastureAcres)
                    farmWoodlandAcres = String(property.woodlandAcres)
                    farmWetlandAcres = String(property.wetlandAcres)
                    farmHasIrrigation = property.hasIrrigation
                    farmNotes = property.notes ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditingMode ? "Save" : "Create") {
                        saveProperty()
                    }
                    .disabled(farmDisplayName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Saves the property to Core Data (creates new or updates existing)
    private func saveProperty() {
        let targetProperty: Property
        
        if let existingProperty = propertyToEdit {
            // Update existing property
            targetProperty = existingProperty
        } else {
            // Create new property
            targetProperty = Property(context: viewContext)
            targetProperty.id = UUID()
        }
        
        // Update property fields
        targetProperty.displayName = farmDisplayName.isEmpty ? nil : farmDisplayName
        targetProperty.county = farmCounty.isEmpty ? nil : farmCounty
        targetProperty.state = farmState.isEmpty ? nil : farmState
        targetProperty.totalAcres = Double(farmTotalAcres) ?? 0.0
        targetProperty.tillableAcres = Double(farmTillableAcres) ?? 0.0
        targetProperty.pastureAcres = Double(farmPastureAcres) ?? 0.0
        targetProperty.woodlandAcres = Double(farmWoodlandAcres) ?? 0.0
        targetProperty.wetlandAcres = Double(farmWetlandAcres) ?? 0.0
        targetProperty.hasIrrigation = farmHasIrrigation
        targetProperty.notes = farmNotes.isEmpty ? nil : farmNotes
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

// MARK: - Preview Provider

struct EditPropertyView_Previews: PreviewProvider {
    static var previews: some View {
        EditPropertyView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}