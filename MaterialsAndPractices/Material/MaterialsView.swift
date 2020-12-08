//
//  MaterialsView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/8/20.
//

import SwiftUI

struct MaterialsView: View {
    
    @State private var showCreateMaterial = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity:Material.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Material.name, ascending: true)],
        animation: .default)
    
    private var grows: FetchedResults<Grow>
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct MaterialsView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialsView()
    }
}
