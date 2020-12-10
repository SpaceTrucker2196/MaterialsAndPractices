//
//  MaterialsView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/8/20.
//

import SwiftUI

struct MaterialsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showCreateMaterial = false
    @State private var selectedMaterial = Material()
    @State var selectedGrow : Grow = Grow()
    
    
    var fetchRequest: FetchRequest<Material>

    @State private var showEditView = false
    
    init(selectedGrow: Grow) {
        fetchRequest = FetchRequest<Material>(entity:Material.entity(),
                                            sortDescriptors: [NSSortDescriptor(keyPath: \Material.name, ascending: true)], predicate: NSPredicate(format: "grow == %@",selectedGrow),
                                            animation: .default)
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.fixed(94), spacing: 16, alignment: .leading),GridItem(.fixed(94), spacing: 16, alignment: .leading), GridItem(.fixed(94), spacing: 16, alignment: .leading)],
                  content: {
                    ForEach(fetchRequest.wrappedValue) { material in
                        NavigationLink(
                            destination: MaterialDetailView(isPresented: $showEditView, material:material),
                            label: {
                                Material.Image(materialTitle:material.name ?? "")
                            })
                    }
                  }).frame(maxWidth: .infinity,maxHeight: .infinity )
        }
}

struct MaterialsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MaterialsView(selectedGrow: Grow(context:PersistenceController.preview.container.viewContext) ).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
