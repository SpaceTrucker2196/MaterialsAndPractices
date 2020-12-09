//
//  MaterialsView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/8/20.
//

import SwiftUI

struct MaterialsView: View {
    
    @State private var showCreateMaterial = false
    @State private var selectedMaterial = Material()
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity:Material.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Material.name, ascending: true)],
        animation: .default)
    
    private var materials: FetchedResults<Material>
    
  
    @State private var showEditView = false
    
    var body: some View {

        LazyVGrid(columns: [.init(.fixed(80)),.init(.fixed(80)),.init(.fixed(80))],
                  content: {
                    ForEach(materials) { material in
                        
                        NavigationLink(
                            destination: MaterialDetailView(isPresented: $showEditView, material:material),
                            label: {
                                Material.Image(materialTitle:material.name ?? "")
                            })
                        
                        
                    }
                  })
        }
}


struct MaterialsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MaterialsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
