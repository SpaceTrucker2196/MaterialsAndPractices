//
//  HelpSystemIntegrationExample.swift
//  MaterialsAndPractices
//
//  Example demonstrating how to integrate the help system into existing views.
//  Shows best practices for iOS-optimized help presentation and localization.
//
//  Created by AI Assistant on current date.
//

import SwiftUI

/// Example view demonstrating proper help system integration
/// Shows how to conditionally display help based on user settings
struct ExampleViewWithHelp: View {
    @State private var showingHelp = false
    @State private var selectedHelpSection: HelpSection?
    
    /// Access to configuration for help system setting
    private let config = SecureConfiguration.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.large) {
                // Main content area
                mainContent
                
                // Action buttons
                actionButtons
                
                Spacer()
            }
            .padding()
            .navigationTitle(LocalizationUtility.localizedString("Farm Management", comment: "Main view title"))
            .toolbar {
                // Only show help button if help system is enabled in settings
                if config.helpSystemEnabled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        helpButton
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {
                WorkOrderHelpView()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Main content area of the view
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text.localized("Welcome to your farm management dashboard", 
                          comment: "Main dashboard welcome message")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text.localized("Here you can manage work orders, track time, and coordinate your team effectively.", 
                          comment: "Dashboard description")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Context-sensitive help hint
            if config.helpSystemEnabled {
                contextualHelpHint
            }
        }
    }
    
    /// Action buttons for main functionality
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            CommonActionButton(
                title: LocalizationUtility.localizedString("Create Work Order", comment: "Create work order button"),
                style: .primary
            ) {
                // Work order creation action
                selectedHelpSection = .workOrders
                showingHelp = true
            }
            
            CommonActionButton(
                title: LocalizationUtility.localizedString("Track Time", comment: "Track time button"),
                style: .secondary
            ) {
                // Time tracking action
                selectedHelpSection = .timeTracking
                showingHelp = true
            }
            
            CommonActionButton(
                title: LocalizationUtility.localizedString("Manage Team", comment: "Manage team button"),
                style: .outline
            ) {
                // Team management action
                selectedHelpSection = .teamManagement
                showingHelp = true
            }
        }
    }
    
    /// Help button for the toolbar
    private var helpButton: some View {
        Button(action: {
            showingHelp = true
        }) {
            Image(systemName: "questionmark.circle")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.primary)
        }
        .accessibilityLabel(LocalizationUtility.Accessibility.helpButton)
        .accessibilityHint(LocalizationUtility.localizedString(
            "Shows help and documentation for this feature", 
            comment: "Help button accessibility hint"
        ))
    }
    
    /// Contextual help hint shown when help is enabled
    private var contextualHelpHint: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(AppTheme.Colors.info)
                .font(.caption)
            
            Text.localized("Tap the help icon for detailed guidance", 
                          comment: "Contextual help hint")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.info.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Preview Providers

struct ExampleViewWithHelp_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExampleViewWithHelp()
                .previewDisplayName("Help Enabled")
            
            ExampleViewWithHelp()
                .previewDisplayName("Help Disabled")
                .onAppear {
                    // Simulate help disabled for preview
                    SecureConfiguration.shared.setValue("false", for: .helpSystemEnabled)
                }
        }
    }
}