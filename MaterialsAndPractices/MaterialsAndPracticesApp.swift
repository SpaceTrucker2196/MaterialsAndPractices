//
//  MaterialsAndPracticesApp.swift
//  MaterialsAndPractices
//
//  Main application entry point providing Core Data persistence setup and
//  primary navigation structure. Implements clean architecture principles
//  with proper separation of concerns between data and presentation layers.
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI

/// Main application structure conforming to App protocol
/// Manages application lifecycle and provides Core Data context to views
@main
struct MaterialsAndPracticesApp: App {
    // MARK: - Properties
    
    /// Shared persistence controller for Core Data management
    let persistenceController = PersistenceController.shared

    // MARK: - Scene Configuration
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

/// Primary content view providing tab-based navigation structure
/// Implements the main user interface with grows and cultivars management
struct ContentView: View {
    // MARK: - Body
    
    var body: some View {
        TabView {
            // Active grows management tab
            CurrentGrowsView()
                .tabItem {
                    Label("Grows", systemImage: "leaf.fill")
                }
            
            // Plant cultivar database tab
            CultivarListView()
                .tabItem {
                    Label("Cultivars", systemImage: "list.bullet.rectangle")
                }
            
            // Farm management tab
            FarmListView()
                .tabItem {
                    Label("Farms", systemImage: "building.2.fill")
                }
            
            // App settings tab
            AppSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(AppTheme.Colors.primary)
    }
}
