//
//  MaterialsAndPracticesApp.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI

@main
struct MaterialsAndPracticesApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            CurrentGrowsView()
                .tabItem {
                    Label("Grows", systemImage: "leaf.fill")
                }
            
            CultivarListView()
                .tabItem {
                    Label("Cultivars", systemImage: "list.bullet.rectangle")
                }
        }
    }
}
