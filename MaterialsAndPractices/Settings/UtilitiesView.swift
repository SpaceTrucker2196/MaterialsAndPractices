//
//  UtilitiesView.swift
//  MaterialsAndPractices
//
//  Application utilities view providing farm management tools and configuration options.
//  Centralizes access to farming operations, settings, and administrative functions.
//  Follows clean architecture principles with clear separation of concerns.
//
//  Features:
//  - Farm management utilities (add farm, worker, infrastructure)
//  - Application configuration and settings
//  - Profile management access
//  - Debug and maintenance tools
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Main application utilities view providing farm management tools and settings
/// Serves as the central hub for administrative and operational functions
/// Implements clean code principles with comprehensive documentation
struct UtilitiesView: View {
    // MARK: - Properties
    
    /// Core Data environment for database operations
    @Environment(\.managedObjectContext) private var viewContext
    
    /// State management for configuration options
    @State private var debugLoggingEnabled: Bool
    @State private var farmManagementAdvancedMode: Bool
    @State private var helpSystemEnabled: Bool
    @State private var showingResetAlert = false
    
    /// Navigation state for various utility flows
    @State private var showingFarmCreation = false
    @State private var showingWorkerCreation = false
    @State private var showingInfrastructureCreation = false
    
    /// Shared configuration manager for app settings
    private let config = SecureConfiguration.shared
    
    // MARK: - Initialization
    
    /// Initializes the utilities view with current configuration values
    /// Loads existing settings and prepares the interface state
    init() {
        let config = SecureConfiguration.shared
        _debugLoggingEnabled = State(initialValue: config.debugLoggingEnabled)
        _farmManagementAdvancedMode = State(initialValue: config.farmManagementAdvancedMode)
        _helpSystemEnabled = State(initialValue: config.helpSystemEnabled)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Farm Management Utilities Section
                farmManagementUtilitiesSection
                
                // Soil Testing Section
                soilTestingSection
                
                // Profile Management Section
                profileManagementSection
                
                // App Configuration Section
                appConfigurationSection
                
                // Application Information Section
                appInformationSection
                
                // Debug and Development Section
                debugSection
                
                // Maintenance and Reset Section
                maintenanceSection
            }
            .navigationTitle("Utilities")
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
        }
        .sheet(isPresented: $showingFarmCreation) {
            EditPropertyView(isPresented: $showingFarmCreation)
        }
        .sheet(isPresented: $showingWorkerCreation) {
            CreateWorkerView(isPresented: $showingWorkerCreation)
        }
        .sheet(isPresented: $showingInfrastructureCreation) {
            InfrastructureManagementView()
        }
    }
    
    // MARK: - Section Components
    
    /// Farm management utilities providing quick access to creation flows
    /// Enables users to efficiently add new farm entities and resources
    private var farmManagementUtilitiesSection: some View {
        Section("Farm Management") {
            // Add New Farm Utility
            UtilityActionRow(
                title: "Add New Farm",
                description: "Create a new farm property with guided setup",
                icon: "building.2.fill",
                iconColor: AppTheme.Colors.primary
            ) {
                showingFarmCreation = true
            }
            
            // Add New Worker Utility
            UtilityActionRow(
                title: "Add New Worker",
                description: "Onboard a new team member with complete profile",
                icon: "person.badge.plus",
                iconColor: AppTheme.Colors.secondary
            ) {
                showingWorkerCreation = true
            }
            
            // Manage Infrastructure Utility
            NavigationLink(destination: InfrastructureManagementView()) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundColor(AppTheme.Colors.compliance)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Manage Infrastructure")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("View and manage all farm infrastructure, equipment, and facilities")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            
            // Manage Inspections Utility
            NavigationLink(destination: InspectionManagementView()) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.compliance)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Manage Inspections")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Create, schedule, and track organic compliance inspections")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            
            // Manage Leases Utility
            NavigationLink(destination: LeaseManagementView()) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(AppTheme.Colors.secondary)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Manage Leases")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Track property leases, contracts, and rental agreements")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            
            // General Ledger Utility
            NavigationLink(destination: LedgerView()) {
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(AppTheme.Colors.compliance)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("General Ledger")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("GAAP-compliant accounting ledger for agricultural business")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
        }
    }
    
    /// Soil testing utilities section for managing soil health monitoring
    /// Provides access to comprehensive soil testing functionality
    private var soilTestingSection: some View {
        Section("Soil Health Monitoring") {
            NavigationLink(destination: SoilTestSettingsView()) {
                HStack {
                    Image(systemName: "flask.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text("Soil Testing")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Manage soil tests, labs, and health monitoring")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
        }
    }
    
    /// Profile management section with farmer profile access
    /// Provides centralized access to user profile information
    private var profileManagementSection: some View {
        Section("Profile") {
            NavigationLink(destination: FarmerProfileView()) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Farmer Profile")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("View and edit your profile information")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.tiny)
            }
        }
    }
    
    /// Application configuration settings for farm management features
    /// Controls advanced functionality and operational modes
    private var appConfigurationSection: some View {
        Section(NSLocalizedString("Configuration", comment: "Configuration section title")) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Toggle(NSLocalizedString("Advanced Mode", comment: "Advanced mode setting"), isOn: $farmManagementAdvancedMode)
                    .onChange(of: farmManagementAdvancedMode) { value in
                        saveFarmManagementSetting(value)
                    }
                
                Text(NSLocalizedString("Advanced mode provides access to detailed farm management features including fields, leases, payments, and compliance tracking.", comment: "Advanced mode description"))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Toggle(NSLocalizedString("Help System", comment: "Help system setting"), isOn: $helpSystemEnabled)
                    .onChange(of: helpSystemEnabled) { value in
                        saveHelpSystemSetting(value)
                    }
                
                Text(NSLocalizedString("Enable or disable the in-app help system and documentation features.", comment: "Help system description"))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    /// Application version and build information display
    /// Provides transparency about the current software version
    private var appInformationSection: some View {
        Section("App Information") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(buildNumber)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Debug and development settings for troubleshooting
    /// Enables logging and displays configuration values for support
    private var debugSection: some View {
        Section("Debug") {
            Toggle("Debug Logging", isOn: $debugLoggingEnabled)
                .onChange(of: debugLoggingEnabled) { value in
                    saveDebugSetting(value)
                }
            
            HStack {
                Text("Network Timeout")
                Spacer()
                Text("\(Int(config.networkTimeoutSeconds))s")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            HStack {
                Text("Max Retry Attempts")
                Spacer()
                Text("\(config.maxRetryAttempts)")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Maintenance and reset options for data management
    /// Provides controls for system maintenance and troubleshooting
    private var maintenanceSection: some View {
        Section("Maintenance") {
            Button("Reset All Settings") {
                showingResetAlert = true
            }
            .foregroundColor(AppTheme.Colors.error)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Application version string from bundle information
    /// - Returns: Version string or "Unknown" if unavailable
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number string from bundle information
    /// - Returns: Build number or "Unknown" if unavailable
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    // MARK: - Configuration Management Methods
    
    /// Saves farm management advanced mode setting to persistent storage
    /// - Parameter value: New setting value to persist
    private func saveFarmManagementSetting(_ value: Bool) {
        config.setValue(value ? "true" : "false", for: .farmManagementAdvancedMode)
    }
    
    /// Saves debug logging setting to persistent storage
    /// - Parameter value: New debug logging state to persist
    private func saveDebugSetting(_ value: Bool) {
        config.setValue(value ? "true" : "false", for: .debugLoggingEnabled)
    }
    
    /// Saves help system setting to persistent storage
    /// - Parameter value: New help system state to persist
    private func saveHelpSystemSetting(_ value: Bool) {
        config.setValue(value ? "true" : "false", for: .helpSystemEnabled)
    }
    
    /// Resets all application settings to their default values
    /// Clears stored configuration and re-establishes defaults
    private func resetToDefaults() {
        // Reset state variables to defaults
        debugLoggingEnabled = true
        farmManagementAdvancedMode = false
        helpSystemEnabled = true
        
        // Clear all stored configuration values
        for key in SecureConfiguration.ConfigKey.allCases {
            config.removeValue(for: key)
        }
        
        // Re-establish default configuration
        ConfigurationSetup.setupDefaults()
    }
}

// MARK: - Supporting Views

/// Reusable utility action row component for consistent interface presentation
/// Provides standardized layout for utility functions with descriptive information
struct UtilityActionRow: View {
    // MARK: - Properties
    
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Icon container with consistent sizing
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 30, height: 30)
                
                // Content container with title and description
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(title)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(description)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.vertical, AppTheme.Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Placeholder view for farm creation flow
/// This will be replaced with a comprehensive farm creation interface
//struct CreateFarmView: View {
//    @Binding var isPresented: Bool
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Create New Farm")
//                    .font(AppTheme.Typography.displayMedium)
//                
//                Text("Farm creation interface will be implemented here")
//                    .font(AppTheme.Typography.bodyMedium)
//                    .foregroundColor(AppTheme.Colors.textSecondary)
//                
//                Spacer()
//                
//                CommonActionButton(title: "Close") {
//                    isPresented = false
//                }
//            }
//            .padding()
//            .navigationTitle("New Farm")
//            .navigationBarItems(trailing: Button("Cancel") {
//                isPresented = false
//            })
//        }
//    }
//}

/// Placeholder view for worker creation flow
/// This will be replaced with a comprehensive worker onboarding interface
//struct CreateWorkerView: View {
//    @Binding var isPresented: Bool
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Add New Worker")
//                    .font(AppTheme.Typography.displayMedium)
//                
//                Text("Worker creation interface will be implemented here")
//                    .font(AppTheme.Typography.bodyMedium)
//                    .foregroundColor(AppTheme.Colors.textSecondary)
//                
//                Spacer()
//                
//                CommonActionButton(title: "Close") {
//                    isPresented = false
//                }
//            }
//            .padding()
//            .navigationTitle("New Worker")
//            .navigationBarItems(trailing: Button("Cancel") {
//                isPresented = false
//            })
//        }
//    }
//}

/// Placeholder view for infrastructure creation flow
/// This will be replaced with a comprehensive infrastructure management interface
//struct CreateInfrastructureView: View {
//    @Binding var isPresented: Bool
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Add Infrastructure")
//                    .font(AppTheme.Typography.displayMedium)
//                
//                Text("Infrastructure creation interface will be implemented here")
//                    .font(AppTheme.Typography.bodyMedium)
//                    .foregroundColor(AppTheme.Colors.textSecondary)
//                
//                Spacer()
//                
//                CommonActionButton(title: "Close") {
//                    isPresented = false
//                }
//            }
//            .padding()
//            .navigationTitle("New Infrastructure")
//            .navigationBarItems(trailing: Button("Cancel") {
//                isPresented = false
//            })
//        }
//    }
//}

// MARK: - Preview Provider

struct UtilitiesView_Previews: PreviewProvider {
    static var previews: some View {
        UtilitiesView()
    }
}
