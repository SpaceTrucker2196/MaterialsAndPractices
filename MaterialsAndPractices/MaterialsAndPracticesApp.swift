//
//  MaterialsAndPracticesApp.swift
//  MaterialsAndPractices
//
//  Main application entry point providing Core Data persistence setup and
//  primary navigation structure. Implements clean architecture principles
//  with proper separation of concerns between data and presentation layers.
//
//  Features:
//  - Automatic farmer profile validation on startup
//  - Tab-based navigation with farm management focus
//  - Core Data integration with proper context management
//  - Clean architecture following SOLID principles
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

/// Main application structure conforming to App protocol
/// Manages application lifecycle and provides Core Data context to views
/// Implements startup profile validation for seamless user onboarding
@main
struct MaterialsAndPracticesApp: App {
    // MARK: - Properties
    
    /// Shared persistence controller for Core Data management
    /// Provides centralized access to the Core Data stack
    let persistenceController = PersistenceController.shared

    // MARK: - Scene Configuration
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(CoreDataNotificationCenter.shared)
        }
    }
}

/// Primary content view providing tab-based navigation structure
/// Implements the main user interface with grows and cultivars management
/// Features automatic farmer profile validation and guided onboarding
struct ContentView: View {
    // MARK: - Core Data Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State Management
    
    /// Controls whether the profile setup flow should be displayed
    @State private var showingProfileSetup = false
    
    /// Tracks whether the initial profile check has completed
    @State private var hasCheckedProfile = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if hasCheckedProfile {
                // Main application interface
                mainInterface
            } else {
                // Loading state while checking profile
                LoadingView(message: "Initializing Farm Management System...")
            }
        }
        .onAppear {
            performStartupProfileCheck()
        }
        .sheet(isPresented: $showingProfileSetup) {
            // Guided farmer profile creation flow
            FarmerProfileSetupView(isPresented: $showingProfileSetup)
        }
    }
    
    // MARK: - Interface Components
    
    /// Main tab-based interface for farm management operations
    private var mainInterface: some View {
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
            
            // Farm management dashboard tab
            FarmDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "building.2.fill")
                }
            
            // Application utilities tab (formerly Settings)
            UtilitiesView()
                .tabItem {
                    Label("Utilities", systemImage: "gear")
                }
        }
        .accentColor(AppTheme.Colors.primary)
    }
    
    // MARK: - Profile Management Methods
    
    /// Performs startup check for existing farmer profile
    /// Triggers profile setup flow if no farmer profile exists
    private func performStartupProfileCheck() {
        let request: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let farmers = try viewContext.fetch(request)
            
            // Set completion flag
            hasCheckedProfile = true
            
            // Show profile setup if no farmer exists
            if farmers.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingProfileSetup = true
                }
            }
        } catch {
            print("❌ Error checking farmer profile during startup: \(error)")
            hasCheckedProfile = true
        }
    }
}

/// Guided farmer profile setup view for new users
/// Provides a welcoming onboarding experience with step-by-step guidance
struct FarmerProfileSetupView: View {
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.extraLarge) {
                // Welcome header
                welcomeHeader
                
                // Feature highlights
                featureHighlights
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .padding()
            .navigationTitle("Welcome to Farm Management")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - UI Components
    
    /// Welcome header with app introduction
    private var welcomeHeader: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("Let's Get Started!")
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Create your farmer profile to begin managing your agricultural operations with our comprehensive farm management system.")
                .font(AppTheme.Typography.bodyLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    /// Feature highlights showcasing app capabilities
    private var featureHighlights: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            FeatureRow(
                icon: "building.2.fill",
                title: "Farm Management",
                description: "Organize your properties, fields, and infrastructure"
            )
            
            FeatureRow(
                icon: "person.3.fill",
                title: "Worker Coordination",
                description: "Track your team and manage time efficiently"
            )
            
            FeatureRow(
                icon: "leaf.fill",
                title: "Crop Planning",
                description: "Plan grows and track cultivar performance"
            )
            
            FeatureRow(
                icon: "checkmark.circle.fill",
                title: "Compliance Tracking",
                description: "Maintain organic certification standards"
            )
        }
    }
    
    /// Action buttons for profile creation or app exploration
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            CommonActionButton(
                title: "Create My Profile",
                style: .primary
            ) {
                openProfileCreation()
            }
            
            Button("Skip for Now") {
                isPresented = false
            }
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Actions
    
    /// Opens the profile creation interface
    private func openProfileCreation() {
        isPresented = false
        
        // Navigate to profile creation
        // Note: In a real implementation, you might want to use a coordinator pattern
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // This could trigger a navigation to FarmerProfileView in edit mode
            NotificationCenter.default.post(name: .showProfileCreation, object: nil)
        }
    }
}

/// Individual feature row component for onboarding highlights
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    /// Notification for triggering profile creation flow
    static let showProfileCreation = Notification.Name("showProfileCreation")
}
