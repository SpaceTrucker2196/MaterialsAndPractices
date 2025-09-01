//
//  MaterialsView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/8/20.
//

import SwiftUI

struct Amendments: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showCreateMaterial = false
    @State private var selectedMaterial = Amendment()
    @State var selectedGrow : Grow = Grow()
    
    var fetchRequest: FetchRequest<Amendment>

    @State private var showEditView = false
    
    init(selectedGrow: Grow) {
        fetchRequest = FetchRequest<Amendment>(entity:Amendment.entity(),
                                            sortDescriptors: [NSSortDescriptor(keyPath: \Amendment.name, ascending: true)], predicate: NSPredicate(format: "grow == %@",selectedGrow),
                                            animation: .default)
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.fixed(94), spacing: 16, alignment: .leading),GridItem(.fixed(94), spacing: 16, alignment: .leading), GridItem(.fixed(94), spacing: 16, alignment: .leading)],
                  content: {
                    ForEach(fetchRequest.wrappedValue) { amendment in
                        NavigationLink(
                            destination: AmendmentDetail(amendment:amendment),
                            label: {
                                //Amendment.Image(amendmentTitle:amendment.name ?? "")
                            })
                    }
                  }).frame(maxWidth: .infinity,maxHeight: .infinity )
        }
}

struct MaterialsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Amendments(selectedGrow: Grow(context:PersistenceController.preview.container.viewContext) ).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
