//
//  Practices.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/10/20.
//

import SwiftUI

struct WorkPractices: View {
    
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedPractice = Work()
    @State var selectedGrow : Grow = Grow()
    
    var fetchRequest: FetchRequest<Work>
    
    init(selectedGrow: Grow) {
        fetchRequest = FetchRequest<Work>(entity:Work.entity(),
                                            sortDescriptors: [NSSortDescriptor(keyPath: \Work.name, ascending: true)], predicate: NSPredicate(format: "grow == %@",selectedGrow),
                                            animation: .default)
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.fixed(94), spacing: 16, alignment: .leading),GridItem(.fixed(94), spacing: 16, alignment: .leading), GridItem(.fixed(94), spacing: 16, alignment: .leading)],
                  content: {
                    ForEach(fetchRequest.wrappedValue) { practice in
                        NavigationLink(
                            destination: WorkPracticeDetailView(work: practice),
                            label: {
                                Work.Image(practiceTitle:practice.name ?? "")
                            })
                    }
                  }).frame(maxWidth: .infinity,maxHeight: .infinity )
        }
    }


struct Practices_Previews: PreviewProvider {
    static var previews: some View {
        WorkPractices(selectedGrow: Grow(context:PersistenceController.preview.container.viewContext) ).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
