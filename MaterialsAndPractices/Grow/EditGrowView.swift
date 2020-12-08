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
    @State var cultivar: String = ""
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
    
    var body: some View {
        VStack {
            NavigationView {
                        Form {
                            Section(header: Text("Details")) {
                                TextField("My New Grow", text: $name)
                                TextField("Cultivar", text:$cultivar)
                                TextField("Location", text:$location)
                                DatePicker("Planted:", selection: $plantedDate)
                                DatePicker("Harvest:", selection: $expectedHarvestDate)
        
                                TextField("Size", text:$size)
                            }
                            Section(header: Text("Property")) {
                                TextField("Owner", text: $propertyOwner)
                                TextField("Phone", text:$propertyOwnerPhone)
                                TextField("Address", text:$address)
                                TextField("City", text:$city)
                                TextField("State", text:$state)
                                TextField("Zip", text:$zip)
                                TextField("County", text:$county)
                                TextField("Manager", text: $manager)
                                TextField("Phone", text:$managerPhone)
                            }
                            
                            Section(header: Text("Notes")) {
                                TextField("Notes", text: $notes)
                            }
                            
                            Button(action: {
                                isPresented = false
        
                                let newGrow = Grow(context: self.viewContext)
                                newGrow.title = name
                                newGrow.cultivar = cultivar
                                newGrow.locationName = location
                                newGrow.plantedDate = plantedDate
                                newGrow.harvestDate = expectedHarvestDate
                                newGrow.timestamp = Date()
                                newGrow.city = city
                                newGrow.county = county
                                newGrow.drivingDirections = drivingDirections
                                newGrow.growType = "field"
                                newGrow.locationName = location
                                newGrow.manager = manager
                                newGrow.managerPhone = managerPhone
                                newGrow.notes = notes
                                newGrow.propertyOwner = propertyOwner
                                newGrow.propertyOwnerPhone = propertyOwnerPhone
                                newGrow.propertyType = "own"
                                newGrow.size = Double(size) ?? 0
                                newGrow.state = state
                                newGrow.zip = zip
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    let nsError = error as NSError
                                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }

                            }, label: {
                                Text("Create New Grow")
                                    .multilineTextAlignment(.center)
                            })
                        } .navigationTitle("New Grow")
            }
        }
       
    }
}

struct EditGrowView_Previews: PreviewProvider {
    static var previews: some View {
        EditGrowView(isPresented: .constant(true))
    }
}
