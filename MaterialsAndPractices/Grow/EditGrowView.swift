//
//  EditGrowView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/7/20.
//

import SwiftUI
import CoreData

struct EditGrowView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var selectedCultivar: Cultivar?
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
    
    @Binding var isPresented: Bool
    
    @FetchRequest(
        entity: Cultivar.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Cultivar.name, ascending: true)]
    ) var cultivars: FetchedResults<Cultivar>
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCultivar != nil &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Grow Name", text: $name)
                    
                    Picker("Cultivar", selection: $selectedCultivar) {
                        Text("Select Cultivar").tag(nil as Cultivar?)
                        ForEach(cultivars, id: \.self) { cultivar in
                            VStack(alignment: .leading) {
                                Text(cultivar.name ?? "Unknown")
                                    .font(.headline)
                                if let family = cultivar.family, !family.isEmpty {
                                    Text(family)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(cultivar as Cultivar?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Location", text: $location)
                    DatePicker("Planted:", selection: $plantedDate, displayedComponents: .date)
                    DatePicker("Expected Harvest:", selection: $expectedHarvestDate, displayedComponents: .date)
                    
                    TextField("Size (acres)", text: $size)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Property Information")) {
                    TextField("Property Owner", text: $propertyOwner)
                    TextField("Owner Phone", text: $propertyOwnerPhone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Zip Code", text: $zip)
                        .keyboardType(.numberPad)
                    TextField("County", text: $county)
                    TextField("Manager", text: $manager)
                    TextField("Manager Phone", text: $managerPhone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Driving / Notes")) {
                    TextField("Driving Directions", text: $drivingDirections)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ZStack(alignment: .topLeading) {
                            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Any additional information...")
                                    .foregroundColor(Color.secondary.opacity(0.6))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            TextEditor(text: $notes)
                                .frame(minHeight: 90, maxHeight: 180)
                        }
                    }
                }
                
                Section {
                    Button(action: saveGrow) {
                        Text("Create New Grow")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationBarTitle("New Grow", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveGrow() {
        isPresented = false
        
        let newGrow = Grow(context: self.viewContext)
        newGrow.title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.cultivar = selectedCultivar
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
        newGrow.propertyType = "own"
        newGrow.size = Double(size.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        newGrow.state = state.trimmingCharacters(in: .whitespacesAndNewlines)
        newGrow.zip = zip.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct EditGrowView_Previews: PreviewProvider {
    static var previews: some View {
        EditGrowView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
