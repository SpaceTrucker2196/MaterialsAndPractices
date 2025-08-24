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
    
    // Form data
    @State private var displayName = ""
    @State private var county = ""
    @State private var state = ""
    @State private var totalAcres = ""
    @State private var tillableAcres = ""
    @State private var pastureAcres = ""
    @State private var woodlandAcres = ""
    @State private var wetlandAcres = ""
    @State private var hasIrrigation = false
    @State private var notes = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    HStack {
                        Text("Property Name")
                        TextField("Display Name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("County")
                        TextField("County", text: $county)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("State")
                        TextField("State", text: $state)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Acreage") {
                    HStack {
                        Text("Total Acres")
                        TextField("0.0", text: $totalAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tillable Acres")
                        TextField("0.0", text: $tillableAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Pasture Acres")
                        TextField("0.0", text: $pastureAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Woodland Acres")
                        TextField("0.0", text: $woodlandAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Wetland Acres")
                        TextField("0.0", text: $wetlandAcres)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Features") {
                    Toggle("Has Irrigation", isOn: $hasIrrigation)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProperty()
                    }
                    .disabled(displayName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Saves the new property to Core Data
    private func saveProperty() {
        let newProperty = Property(context: viewContext)
        newProperty.id = UUID()
        newProperty.displayName = displayName.isEmpty ? nil : displayName
        newProperty.county = county.isEmpty ? nil : county
        newProperty.state = state.isEmpty ? nil : state
        newProperty.totalAcres = Double(totalAcres) ?? 0.0
        newProperty.tillableAcres = Double(tillableAcres) ?? 0.0
        newProperty.pastureAcres = Double(pastureAcres) ?? 0.0
        newProperty.woodlandAcres = Double(woodlandAcres) ?? 0.0
        newProperty.wetlandAcres = Double(wetlandAcres) ?? 0.0
        newProperty.hasIrrigation = hasIrrigation
        newProperty.notes = notes.isEmpty ? nil : notes
        
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