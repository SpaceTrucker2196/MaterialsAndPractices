//
//  EditGrowView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/7/20.
//

import SwiftUI

struct EditGrowView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var name: String = ""
    @State var selectedCultivar: Cultivar?
    @State var location: String = ""
    @State var plantedDate: Date = Date()
    @State var expectedHarvestDate: Date = Date()
    @State var propertyOwner: String = ""
    @State var propertyOwnerPhone: String = ""
    @State var address: String = ""
    @State var city: String = ""
    @State var state: String = ""
    @State var zip: String = ""
    @State var county: String = ""
    @State var drivingDirections: String = ""
    @State var manager: String = ""
    @State var managerPhone: String = ""
    @State var notes : String = ""
    @State var size : String = ""
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
                    TextField("Grow Name", text: $name, prompt: Text("Enter grow name"))
                    
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
                                .pickerStyle(.navigationLink)
                                
                                TextField("Location", text: $location, prompt: Text("Enter location"))
                                DatePicker("Planted:", selection: $plantedDate, displayedComponents: .date)
                                DatePicker("Expected Harvest:", selection: $expectedHarvestDate, displayedComponents: .date)
        
                                TextField("Size (acres)", text: $size, prompt: Text("0.0"))
                                    .keyboardType(.decimalPad)
                            }
                            Section(header: Text("Property Information")) {
                                TextField("Property Owner", text: $propertyOwner, prompt: Text("Owner name"))
                                TextField("Owner Phone", text: $propertyOwnerPhone, prompt: Text("Phone number"))
                                    .keyboardType(.phonePad)
                                TextField("Address", text: $address, prompt: Text("Street address"))
                                TextField("City", text: $city, prompt: Text("City"))
                                TextField("State", text: $state, prompt: Text("State"))
                                TextField("Zip Code", text: $zip, prompt: Text("ZIP"))
                                    .keyboardType(.numberPad)
                                TextField("County", text: $county, prompt: Text("County"))
                                TextField("Manager", text: $manager, prompt: Text("Property manager"))
                                TextField("Manager Phone", text: $managerPhone, prompt: Text("Manager phone"))
                                    .keyboardType(.phonePad)
                            }
                            
                            Section(header: Text("Additional Notes")) {
                                TextField("Notes", text: $notes, prompt: Text("Any additional information..."), axis: .vertical)
                                    .lineLimit(3...6)
                            }
                            Section {
                                Button(action: {
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
                                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                    }

                                }) {
                                    Text("Create New Grow")
                                        .frame(maxWidth: .infinity)
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!isFormValid)
                            }
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
}

struct EditGrowView_Previews: PreviewProvider {
    static var previews: some View {
        EditGrowView(isPresented: .constant(true))
    }
}
