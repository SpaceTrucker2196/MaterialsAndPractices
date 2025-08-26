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
    @State private var showingPerformWorkView = false
    @State private var showingInspectionScheduling = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // MARK: - Cultivar Information Section
                cultivarInformationSection
                
                // MARK: - Cultivar Growing Details Section
                cultivarGrowingDetailsSection
                
                // MARK: - Field and Farm Information Section
                fieldAndFarmInformationSection
                
                // MARK: - Timeline Information Section  
                timelineInformationSection
                
                // MARK: - Harvest Calendar Section
                harvestCalendarSection
                
                // MARK: - Location Information Section
                locationInformationSection
                
                // MARK: - Work Practices Section
                workPracticesSection
                
                // MARK: - Amendments Section
                amendmentsSection
                
                // MARK: - Harvest Safety Section
                harvestSafetySection
                
                // MARK: - Inspection Section
                inspectionSection
            }
            .padding()
        }
        .navigationTitle(growViewModel.name)
        .sheet(isPresented: $showingPerformWorkView) {
            PerformWorkView(grow: growViewModel.grow, isPresented: $showingPerformWorkView)
        }
        .sheet(isPresented: $showingInspectionScheduling) {
            GrowInspectionSchedulingView(grow: growViewModel.grow, isPresented: $showingInspectionScheduling)
        }
    }
    
    // MARK: - Section Components
    
    /// Section displaying comprehensive cultivar information with metadata tags
    private var cultivarInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
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
            HStack {
                growViewModel.previewImage
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    
                   
                    
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
    
    /// Section displaying detailed cultivar growing information
    private var cultivarGrowingDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Growing Information")
            
            if let cultivar = growViewModel.grow.cultivar {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.medium) {
                    // Growing days information
                    if let growingDays = cultivar.growingDays, !growingDays.isEmpty {
                        DetailCard(
                            title: "Growing Days",
                            value: growingDays,
                            subtitle: "Days to maturity",
                            backgroundColor: AppTheme.ColorCoding.colorForGrowingDays(growingDays).opacity(0.1),
                            titleColor: AppTheme.ColorCoding.colorForGrowingDays(growingDays)
                        )
                    }
                    
                    // Transplant age information
                    if let transplantAge = cultivar.transplantAge, !transplantAge.isEmpty {
                        DetailCard(
                            title: "Transplant Age",
                            value: transplantAge,
                            subtitle: "Weeks for transplant",
                            backgroundColor: AppTheme.Colors.info.opacity(0.1),
                            titleColor: AppTheme.Colors.info
                        )
                    }
                    
                    // Weather tolerance
                    if let weatherTolerance = cultivar.weatherTolerance, !weatherTolerance.isEmpty {
                        DetailCard(
                            title: "Weather Tolerance",
                            value: weatherTolerance,
                            subtitle: "Climate conditions",
                            backgroundColor: AppTheme.Colors.secondary.opacity(0.1),
                            titleColor: AppTheme.Colors.secondary
                        )
                    }
                    
                    // Soil conditions
                    if let soilConditions = cultivar.soilConditions, !soilConditions.isEmpty {
                        DetailCard(
                            title: "Soil Conditions",
                            value: soilConditions,
                            subtitle: "Preferred soil type",
                            backgroundColor: AppTheme.Colors.organicMaterial.opacity(0.1),
                            titleColor: AppTheme.Colors.organicMaterial
                        )
                    }
                }
                
                // Expandable sections for detailed information
                if hasExtendedCultivarInfo(cultivar) {
                    extendedCultivarInfoSection(cultivar)
                }
            } else {
                Text("No cultivar information available")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Extended cultivar information section with expandable details
    private func extendedCultivarInfoSection(_ cultivar: Cultivar) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Growing advice
            if let growingAdvice = cultivar.growingAdvice, !growingAdvice.isEmpty {
                ExpandableDetailCard(
                    title: "Growing Advice",
                    value: growingAdvice,
                    backgroundColor: AppTheme.Colors.primary.opacity(0.1),
                    titleColor: AppTheme.Colors.primary
                )
            }
            
            // Harvest instructions
            if let harvestInstructions = cultivar.harvestInstructions, !harvestInstructions.isEmpty {
                ExpandableDetailCard(
                    title: "Harvest Instructions",
                    value: harvestInstructions,
                    backgroundColor: AppTheme.Colors.organicPractice.opacity(0.1),
                    titleColor: AppTheme.Colors.organicPractice
                )
            }
            
            // Ripeness indicators
            if let ripenessIndicators = cultivar.ripenessIndicators, !ripenessIndicators.isEmpty {
                ExpandableDetailCard(
                    title: "Ripeness Indicators",
                    value: ripenessIndicators,
                    backgroundColor: AppTheme.Colors.success.opacity(0.1),
                    titleColor: AppTheme.Colors.success
                )
            }
            
            // Greenhouse instructions
            if let greenhouseInstructions = cultivar.greenhouseInstructions, !greenhouseInstructions.isEmpty {
                ExpandableDetailCard(
                    title: "Greenhouse Instructions",
                    value: greenhouseInstructions,
                    backgroundColor: AppTheme.Colors.info.opacity(0.1),
                    titleColor: AppTheme.Colors.info
                )
            }
        }
    }
    
    /// Section displaying field and farm information with navigation links
    private var fieldAndFarmInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Location")
            
            if let field = growViewModel.grow.field {
                // Field information
                NavigationLink(destination: FieldDetailView(field: field)) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Image(systemName: "grid")
                                .foregroundColor(AppTheme.Colors.primary)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                                Text("Field: \(field.name ?? "Unnamed Field")")
                                    .font(AppTheme.Typography.bodyLarge)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Text("\(field.acres, specifier: "%.1f") acres")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                if field.hasDrainTile {
                                    MetadataTag(
                                        text: "Drain Tile",
                                        backgroundColor: AppTheme.Colors.info.opacity(0.2),
                                        textColor: AppTheme.Colors.info
                                    )
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .font(.caption)
                        }
                        
                        // Latest soil test pH spectrum
                        if let latestSoilTest = latestSoilTest(for: field) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Current Soil pH")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                PHSpectrumView(currentPH: latestSoilTest.ph, showLabels: false)
                                    .frame(height: 30)
                                
                                if let testDate = latestSoilTest.date {
                                    Text("Tested: \(testDate, style: .date)")
                                        .font(AppTheme.Typography.labelSmall)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                        }
                        
                        // Farm/Property information
                        if let property = field.property {
                            Divider()
                            
                            NavigationLink(destination: PropertyDetailView(property: property, isAdvancedMode: true)) {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(AppTheme.Colors.secondary)
                                    
                                    
                                    
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                                        Text("Farm: \(property.displayName ?? "Unnamed Property")")
                                            .font(AppTheme.Typography.bodyLarge)
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                        
                                        if let county = property.county, let state = property.state {
                                            Text("\(county), \(state)")
                                                .font(AppTheme.Typography.bodyMedium)
                                                .foregroundColor(AppTheme.Colors.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.medium)
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                // Link to soil test information
                if let field = growViewModel.grow.field,
                   let soilTests = field.soilTests?.allObjects as? [SoilTest],
                   !soilTests.isEmpty {
                    NavigationLink(destination: SoilTestListView(field: field)) {
                        HStack {
                            Image(systemName: "flask")
                                .foregroundColor(AppTheme.Colors.organicMaterial)
                            
                            Text("View Soil Test Information")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.primary)
                            
                            Spacer()
                            
                            Text("\(soilTests.count) test\(soilTests.count == 1 ? "" : "s")")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .font(.caption)
                        }
                        .padding(AppTheme.Spacing.small)
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
            } else {
                // No field assigned
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(AppTheme.Colors.warning)
                        
                        Text("No Field Assigned")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                    
                    Text("This grow is not associated with a specific field. Consider editing to add field information.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.warning.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.medium)
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
                    value: daysToHarvestText
                )
                
                if let harvestEstimate = currentHarvestEstimate {
                    GrowInfoRow(
                        label: "Harvest Timing:",
                        value: harvestEstimate.estimatedRange
                    )
                }
            }
        }
    }
    
    /// Section displaying harvest calendar heat map
    private var harvestCalendarSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Harvest Calendar")
            
            if let cultivar = growViewModel.grow.cultivar,
               let plantedDate = growViewModel.grow.plantedDate {
                let harvestData = HarvestCalculator.calculateHarvestCalendarData(
                    cultivar: cultivar,
                    plantDate: plantedDate,
                    usdaZone: cultivar.hardyZone
                )
                
                HarvestCalendarHeatMap(
                    harvestData: harvestData,
                    showLabels: true,
                    showLegend: true
                )
            } else {
                Text("Harvest calendar requires cultivar and planted date information")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
                    .background(AppTheme.Colors.warning.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.medium)
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
                title: "Perform Work",
                style: .outline,
                action: performWork
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
    
    /// Section for inspection management and assignment
    private var inspectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Inspections")
            
            // Recent inspections for this grow
            if let recentInspections = getRecentInspections(), !recentInspections.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Recent Inspections")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(recentInspections.prefix(3), id: \.id) { inspection in
                        GrowInspectionRow(inspection: inspection)
                    }
                    
                    if recentInspections.count > 3 {
                        Button("View All Inspections") {
                            // Navigate to full inspection list for this grow
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            
            // Inspection actions
            VStack(spacing: AppTheme.Spacing.small) {
                CommonActionButton(
                    title: "Schedule Inspection",
                    style: .outline,
                    action: scheduleGrowInspection
                )
                
                NavigationLink(destination: InspectionManagementView()) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.Colors.compliance)
                        
                        Text("Manage All Inspections")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .font(.caption)
                    }
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
    }
    
    // MARK: - Action Methods
    
    /// Opens the perform work view to create new work order
    private func performWork() {
        showingPerformWorkView = true
    }
    
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
    
    /// Opens the inspection scheduling view for this grow
    private func scheduleGrowInspection() {
        showingInspectionScheduling = true
    }
    
    // MARK: - Helper Methods
    
    /// Current harvest estimate for the grow
    private var currentHarvestEstimate: HarvestEstimate? {
        guard let cultivar = growViewModel.grow.cultivar,
              let plantedDate = growViewModel.grow.plantedDate else {
            return nil
        }
        
        return HarvestCalculator.calculateHarvestEstimate(
            cultivar: cultivar,
            plantDate: plantedDate,
            usdaZone: cultivar.hardyZone
        )
    }
    
    /// Formatted days to harvest text
    private var daysToHarvestText: String {
        guard let cultivar = growViewModel.grow.cultivar,
              let plantedDate = growViewModel.grow.plantedDate else {
            return "Unknown"
        }
        
        let daysUntilHarvest = HarvestCalculator.daysUntilHarvest(
            cultivar: cultivar,
            plantDate: plantedDate
        )
        
        if daysUntilHarvest == 0 {
            return "Ready to harvest!"
        } else if daysUntilHarvest < 0 {
            return "Overdue for harvest"
        } else {
            return "\(daysUntilHarvest) days remaining"
        }
    }
    
    /// Check if cultivar has extended information to display
    private func hasExtendedCultivarInfo(_ cultivar: Cultivar) -> Bool {
        return [
            cultivar.growingAdvice,
            cultivar.harvestInstructions,
            cultivar.ripenessIndicators,
            cultivar.greenhouseInstructions
        ].contains { $0 != nil && !($0?.isEmpty ?? true) }
    }
    
    /// Gets the latest soil test for a field
    private func latestSoilTest(for field: Field) -> SoilTest? {
        guard let soilTests = field.soilTests?.allObjects as? [SoilTest] else { return nil }
        return soilTests.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }.first
    }
    
    /// Gets recent inspections for this grow
    private func getRecentInspections() -> [GrowInspectionDisplayData]? {
        // This would fetch actual inspection data from Core Data
        // For now, return sample data if grow has been inspected
        guard let plantedDate = growViewModel.grow.plantedDate,
              plantedDate < Date().addingTimeInterval(-7 * 24 * 60 * 60) else { // Planted more than a week ago
            return nil
        }
        
        return [
            GrowInspectionDisplayData(
                id: UUID(),
                name: "Pre-Harvest Inspection",
                category: .grow,
                completedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60),
                inspector: "John Smith",
                status: .completed
            )
        ]
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

/// Compact detail card for displaying cultivar information
private struct DetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    let backgroundColor: Color
    let titleColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(titleColor)
            
            Text(value)
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
            
            Text(subtitle)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Expandable detail card for longer cultivar information
private struct ExpandableDetailCard: View {
    let title: String
    let value: String
    let backgroundColor: Color
    let titleColor: Color
    @State private var isExpanded = false
    
    private var displayValue: String {
        if isExpanded || value.count <= 100 {
            return value
        }
        return String(value.prefix(100)) + "..."
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(titleColor)
                
                Spacer()
                
                if value.count > 100 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(titleColor)
                            .font(.caption)
                    }
                }
            }
            
            Text(displayValue)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

struct GrowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GrowDetailView(growViewModel: GrowDetailViewModel(grow: Grow(context:PersistenceController.preview.container.viewContext)))
        }
    }
}

// MARK: - Supporting View Components for Inspections

/// Display data for grow inspections
struct GrowInspectionDisplayData {
    let id: UUID
    let name: String
    let category: InspectionCategory
    let completedAt: Date
    let inspector: String
    let status: InspectionStatus
}

enum InspectionStatus {
    case scheduled
    case inProgress
    case completed
    case overdue
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        }
    }
    
    var color: Color {
        switch self {
        case .scheduled: return AppTheme.Colors.primary
        case .inProgress: return AppTheme.Colors.warning
        case .completed: return AppTheme.Colors.success
        case .overdue: return AppTheme.Colors.error
        }
    }
}

/// Row view for displaying grow inspection information
struct GrowInspectionRow: View {
    let inspection: GrowInspectionDisplayData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(inspection.name)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("By \(inspection.inspector)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                MetadataTag(
                    text: inspection.status.displayName,
                    backgroundColor: inspection.status.color.opacity(0.2),
                    textColor: inspection.status.color
                )
                
                Text(inspection.completedAt, style: .date)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Inspection scheduling view for grows
struct GrowInspectionSchedulingView: View {
    let grow: Grow
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTemplate: InspectionCategory = .grow
    @State private var inspectionName: String = ""
    @State private var scheduledTime: InspectionTime = .morning
    @State private var frequency: InspectionFrequency = .oneTime
    @State private var selectedInspectors: [UUID] = []
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Inspection Details") {
                    TextField("Inspection Name", text: $inspectionName)
                    
                    Picker("Template Category", selection: $selectedTemplate) {
                        ForEach(InspectionCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }.tag(category)
                        }
                    }
                    
                    Picker("Scheduled Time", selection: $scheduledTime) {
                        ForEach(InspectionTime.allCases, id: \.self) { time in
                            VStack(alignment: .leading) {
                                Text(time.rawValue)
                                Text(time.timeRange)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }.tag(time)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(InspectionFrequency.allCases, id: \.self) { freq in
                            HStack {
                                Image(systemName: freq.icon)
                                Text(freq.rawValue)
                            }.tag(freq)
                        }
                    }
                }
                
                Section("Grow Information") {
                    HStack {
                        Text("Cultivar:")
                        Spacer()
                        Text(grow.cultivar?.name ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    if let field = grow.field {
                        HStack {
                            Text("Field:")
                            Spacer()
                            Text(field.name ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        if let property = field.property {
                            HStack {
                                Text("Farm:")
                                Spacer()
                                Text(property.displayName ?? "Unknown")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Additional Notes") {
                    TextField("Inspection notes or requirements", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Schedule Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        scheduleInspection()
                    }
                    .disabled(inspectionName.isEmpty)
                }
            }
        }
    }
    
    private func scheduleInspection() {
        // Here we would create the inspection using the inspection system
        // For now, we'll just dismiss the view
        // TODO: Integrate with InspectionCreationWorkflowView or create inspection directly
        
        print("Scheduling inspection: \(inspectionName) for grow: \(grow.title ?? "Unknown")")
        print("Category: \(selectedTemplate.displayName)")
        print("Time: \(scheduledTime.rawValue)")
        print("Frequency: \(frequency.rawValue)")
        
        isPresented = false
    }
}
