//
//  MaterialDetailView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/8/20.
//

import SwiftUI

struct MaterialDetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var isPresented: Bool
    @State var material : Material = Material()
    
    var body: some View {
        VStack {
            NavigationView {
                Form {
                    Section(header: Text("Details")) {
                        TextField("Name", text:Binding($material.name, "New Application"))
                    }
                    Section(header: Text("Labor")) {
                        TextField("Notes", text:Binding($material.notes, ""))
                        TextField("Labor Hours", text:Binding($material.laborHours,"0"))
                    }
                    Button(action: {
                        material.name = material.name
                        do {
                            try viewContext.save()
                        } catch {
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        isPresented = false

                    }, label: {
                        Text("Update")
                            .font(.headline)
                            .foregroundColor(Color("OrganicMaterialColor"))
                            .multilineTextAlignment(.center)
                            .padding(.all, 8.0)
                            .border(/*@START_MENU_TOKEN@*/Color("OrganicMaterialColor")/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                            .cornerRadius(2.0)
                            
                    })
                    .padding(.all, 4.0)
                    
                }
            }
            .navigationTitle("Material Application" )
        }
    }
}

struct MaterialDetailView_Previews: PreviewProvider {
   
    static var previews: some View {

        MaterialDetailView(isPresented:.constant(true), material:Material(context:PersistenceController.preview.container.viewContext))
    }
}
