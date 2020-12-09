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
            CurrentGrowsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    
}
