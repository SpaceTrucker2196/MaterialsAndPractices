//
//  MaterialDetailView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/8/20.
//

import SwiftUI

struct AmendmentDetail: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    @State var amendment : Amendment
    @State private var selectedMaterialIndex = 0
    
    var materials = ["Compost","Bat Guano","Manure","Worm Compost","Greensand","Azomite","Comfrey","Cover Crop","Wood Chips","Leaf Mold","Bone Meal","Wood Ash","Humus","Humic Acid","Blood Meal","Straw","Paper"]

    var body: some View {
        VStack {
                Form {
                    Section(header: Text("Details")) {
                        
                        TextField("New Application", text:Binding($amendment.name, ""))
                        TextField("Material:", text:Binding($amendment.material, ""))
                        
                        Picker(selection:$selectedMaterialIndex, label: Text("Apply Material:").foregroundColor(Color("OrganicMaterialColor"))) {
                                   ForEach(0 ..< materials.count) {
                                      Text(self.materials[$0])
                                   }
                        }.onChange(of:selectedMaterialIndex, perform: { value in
                            amendment.material = materials[selectedMaterialIndex]
                            if amendment.name == "" {
                                amendment.name = "\(materials[selectedMaterialIndex]) Application"
                            }
                        })
                    }
                    
                    Section(header: Text("Labor")) {
                        TextField("Notes", text:Binding($amendment.notes, ""))
                        TextField("Labor Hours", text:Binding($amendment.laborHours,""))
                    }
                    
                    Button(action: {
                        amendment.materialIndex = Int32(selectedMaterialIndex)
                        do {
                            try viewContext.save()
                        } catch {
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Update")
                            .font(.headline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.all, 4.0)
                            .frame(maxWidth: .infinity)
                        
                    }).border(Color.accentColor, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    .cornerRadius(4.0) .padding()
                }
        }
    }
}

struct MaterialDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AmendmentDetail(amendment:Amendment(context:PersistenceController.preview.container.viewContext))
    }
}
