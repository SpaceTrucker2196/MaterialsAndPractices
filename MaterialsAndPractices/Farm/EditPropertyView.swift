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
            .navigationTitle("Create New Farm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveProperty()
                    }
                    .disabled(farmDisplayName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Saves the new property to Core Data
    private func saveProperty() {
        let newProperty = Property(context: viewContext)
        newProperty.id = UUID()
        newProperty.displayName = farmDisplayName.isEmpty ? nil : farmDisplayName
        newProperty.county = farmCounty.isEmpty ? nil : farmCounty
        newProperty.state = farmState.isEmpty ? nil : farmState
        newProperty.totalAcres = Double(farmTotalAcres) ?? 0.0
        newProperty.tillableAcres = Double(farmTillableAcres) ?? 0.0
        newProperty.pastureAcres = Double(farmPastureAcres) ?? 0.0
        newProperty.woodlandAcres = Double(farmWoodlandAcres) ?? 0.0
        newProperty.wetlandAcres = Double(farmWetlandAcres) ?? 0.0
        newProperty.hasIrrigation = farmHasIrrigation
        newProperty.notes = farmNotes.isEmpty ? nil : farmNotes
        
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