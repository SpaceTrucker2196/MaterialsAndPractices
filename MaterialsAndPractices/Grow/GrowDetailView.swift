//
//  GrowDetailView.swift
//  MaterialsAndPractices
//
//  Provides comprehensive grow management and tracking functionality including
//  cultivar information, work practices, amendments, and safety compliance.
//  Implements MVVM architecture with clean separation of concerns.
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

/// View model for grow detail presentation and data management
/// Encapsulates grow data and provides computed properties for UI consumption
struct GrowDetailViewModel  {
    // MARK: - Properties
    
    var grow: Grow
    var cultivar = "New Cultivar"
    var cultivarFamily = ""
    var hardyZone = ""
    var season = ""
    var plantingWeek = ""
    var name = "My Grow"
    var plantedDate = Date()
    var harvestDate = Date()
    var daysTillHarvest = 90
    var locationName = "My Location"
    var previewImage = Grow.Image(grow: Grow())
    
    // MARK: - Initialization
    
    /// Initializes view model with grow entity data
    /// Extracts and formats all necessary information for display
    /// - Parameter grow: The Core Data grow entity
    init(grow: Grow) {
        self.grow = grow
        cultivar = grow.cultivar?.name ?? "No Cultivar Selected"
        cultivarFamily = grow.cultivar?.family ?? ""
        hardyZone = grow.cultivar?.hardyZone ?? ""
        season = grow.cultivar?.season ?? ""
        plantingWeek = grow.cultivar?.plantingWeek ?? ""
        name = grow.title ?? ""
        plantedDate = grow.plantedDate ?? Date()
        harvestDate = grow.harvestDate ?? Date()
        locationName = grow.locationName ?? ""
        previewImage = Grow.Image(grow: grow)
    }
}

/// Date formatter for consistent date display throughout the application
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

/// Comprehensive grow detail view providing complete grow information and management
/// Displays cultivar details, dates, location, work practices, amendments, and safety compliance
struct GrowDetailView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @State var growViewModel: GrowDetailViewModel
    @State private var showingHarvestChecklist = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // MARK: - Cultivar Information Section
                cultivarInformationSection
                
                // MARK: - Timeline Information Section  
                timelineInformationSection
                
                // MARK: - Location Information Section
                locationInformationSection
                
                // MARK: - Work Practices Section
                workPracticesSection
                
                // MARK: - Amendments Section
                amendmentsSection
                
                // MARK: - Harvest Safety Section
                harvestSafetySection
            }
            .padding()
        }
        .navigationTitle(growViewModel.name)
    }
    
    // MARK: - Section Components
    
    /// Section displaying comprehensive cultivar information with metadata tags
    private var cultivarInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                growViewModel.previewImage
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text("Cultivar:")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text(growViewModel.cultivar)
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if !growViewModel.cultivarFamily.isEmpty {
                        Text("Family: \(growViewModel.cultivarFamily)")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Metadata tags for season and zone information
                    HStack(spacing: AppTheme.Spacing.extraSmall) {
                        if !growViewModel.season.isEmpty {
                            MetadataTag(
                                text: "Season: \(growViewModel.season)",
                                backgroundColor: AppTheme.Colors.seasonIndicator.opacity(0.2),
                                textColor: AppTheme.Colors.seasonIndicator
                            )
                        }
                        
                        if !growViewModel.hardyZone.isEmpty {
                            MetadataTag(
                                text: "Zone: \(growViewModel.hardyZone)",
                                backgroundColor: AppTheme.Colors.zoneIndicator.opacity(0.2),
                                textColor: AppTheme.Colors.zoneIndicator
                            )
                        }
                    }
                    
                    if !growViewModel.plantingWeek.isEmpty {
                        Text("Planting Week: \(growViewModel.plantingWeek)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    /// Section displaying timeline information including planted and harvest dates
    private var timelineInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            SectionHeader(title: "Timeline")
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                GrowDateInfoRow(
                    label: "Planted Date:",
                    date: growViewModel.plantedDate,
                    formatter: itemFormatter
                )
                
                GrowDateInfoRow(
                    label: "Expected Harvest:",
                    date: growViewModel.harvestDate,
                    formatter: itemFormatter
                )
                
                GrowInfoRow(
                    label: "Remaining:",
                    value: "90 Days" // TODO: Calculate actual remaining days
                )
            }
        }
    }
    
    /// Section displaying location information
    private var locationInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            SectionHeader(title: "Location")
            
            Text(growViewModel.locationName)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    /// Section for managing work practices with add functionality
    private var workPracticesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Work")
            
            WorkPractices(selectedGrow: growViewModel.grow)
                .frame(maxWidth: .infinity)
            
            CommonActionButton(
                title: "Perform",
                action: addWorkPractice
            )
        }
    }
    
    /// Section for managing amendments with add functionality
    private var amendmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Amendment Applications")
            
            Amendments(selectedGrow: growViewModel.grow)
                .frame(maxWidth: .infinity)
            
            CommonActionButton(
                title: "Apply",
                action: addAmendment
            )
        }
    }
    
    /// Section for harvest safety compliance with checklist access
    private var harvestSafetySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Harvest Safety")
            
            CommonActionButton(
                title: "Safety Checklist",
                action: { showingHarvestChecklist = true }
            )
            .sheet(isPresented: $showingHarvestChecklist) {
                HarvestSafetyChecklistView()
            }
        }
    }
    
    // MARK: - Action Methods
    
    /// Adds a new work practice entry to the current grow
    private func addWorkPractice() {
        let newWork = Work(context: viewContext)
        growViewModel.grow.addToWork(newWork)
    }
    
    /// Adds a new amendment application to the current grow
    private func addAmendment() {
        let newAmendment = Amendment(context: viewContext)
        growViewModel.grow.addToAmendments(newAmendment)
    }
}

// MARK: - Supporting View Components

/// Reusable section header component with consistent styling
//private struct SectionHeader: View {
//    let title: String
//    
//    var body: some View {
//        Text(title)
//            .font(AppTheme.Typography.headlineMedium)
//            .foregroundColor(AppTheme.Colors.primary)
//    }
//}

/// Reusable component for displaying label-value information pairs
private struct GrowInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(label)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}
//
///// Specialized component for displaying date information with formatting
private struct GrowDateInfoRow: View {
    let label: String
    let date: Date
    let formatter: DateFormatter
    
    var body: some View {
        GrowInfoRow(label: label, value: formatter.string(from: date))
    }
}

/// Reusable metadata tag component for displaying categorical information
private struct GrowMetadataTag: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    
    var body: some View {
        Text(text)
            .font(AppTheme.Typography.labelSmall)
            .padding(.horizontal, AppTheme.Spacing.extraSmall)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(backgroundColor)
            .cornerRadius(AppTheme.CornerRadius.small)
            .foregroundColor(textColor)
    }
}

/// Reusable action button component with consistent styling
//private struct ActionButton: View {
//    let title: String
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            Text(title)
//                .font(AppTheme.Typography.headlineSmall)
//                .frame(maxWidth: .infinity)
//                .padding()
//        }
//        .background(AppTheme.Colors.primary.opacity(0.1))
//        .cornerRadius(AppTheme.CornerRadius.medium)
//        .overlay(
//            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
//                .stroke(AppTheme.Colors.primary, lineWidth: 1)
//        )
//    }
//}

struct GrowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GrowDetailView(growViewModel: GrowDetailViewModel(grow: Grow(context:PersistenceController.preview.container.viewContext)))
        }
    }
}
