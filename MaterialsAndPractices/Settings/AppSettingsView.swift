//
//  AppSettingsView.swift
//  MaterialsAndPractices
//
//  Application settings view including farm management configuration.
//  Provides interface for controlling advanced mode and other app preferences.
//
//  Created by AI Assistant on current date.
//

import SwiftUI

/// Main application settings view
struct AppSettingsView: View {
    // MARK: - Properties
    
    @State private var debugLoggingEnabled: Bool
    @State private var farmManagementAdvancedMode: Bool
    @State private var showingResetAlert = false
    
    private let config = SecureConfiguration.shared
    
    // MARK: - Initialization
    
    init() {
        let config = SecureConfiguration.shared
        _debugLoggingEnabled = State(initialValue: config.debugLoggingEnabled)
        _farmManagementAdvancedMode = State(initialValue: config.farmManagementAdvancedMode)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                profileSection
                
                // App Information Section
                appInformationSection
                
                // Farm Management Section
                farmManagementSection
                
                // Debug Section
                debugSection
                
                // Reset Section
                resetSection
            }
            .navigationTitle("Settings")
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Sections
    
    /// Profile section with farmer profile access
    private var profileSection: some View {
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
    
    /// App information and version details
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
    
    /// Farm management specific settings
    private var farmManagementSection: some View {
        Section("Farm Management") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Toggle("Advanced Mode", isOn: $farmManagementAdvancedMode)
                    .onChange(of: farmManagementAdvancedMode) { value in
                        saveFarmManagementSetting(value)
                    }
                
                Text("Advanced mode provides access to detailed farm management features including fields, leases, payments, and compliance tracking.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    /// Debug and development settings
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
    
    /// Reset and maintenance options
    private var resetSection: some View {
        Section("Maintenance") {
            Button("Reset All Settings") {
                showingResetAlert = true
            }
            .foregroundColor(AppTheme.Colors.error)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Application version string
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Build number string
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    // MARK: - Methods
    
    /// Saves farm management advanced mode setting
    /// - Parameter value: New setting value
    private func saveFarmManagementSetting(_ value: Bool) {
        config.setValue(value ? "true" : "false", for: .farmManagementAdvancedMode)
    }
    
    /// Saves debug logging setting
    /// - Parameter value: New setting value
    private func saveDebugSetting(_ value: Bool) {
        config.setValue(value ? "true" : "false", for: .debugLoggingEnabled)
    }
    
    /// Resets all settings to default values
    private func resetToDefaults() {
        // Reset to default values
        debugLoggingEnabled = true
        farmManagementAdvancedMode = false
        
        // Clear stored settings
        for key in SecureConfiguration.ConfigKey.allCases {
            config.removeValue(for: key)
        }
        
        // Re-setup defaults
        ConfigurationSetup.setupDefaults()
    }
}

// MARK: - Settings Row Helper

/// Helper view for consistent settings row display
struct SettingsRow: View {
    let title: String
    let value: String
    let action: (() -> Void)?
    
    init(title: String, value: String, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

// MARK: - Preview Provider

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView()
    }
}