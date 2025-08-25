//
//  SoilTestSettingsView.swift
//  MaterialsAndPractices
//
//  Settings and management interface for soil testing functionality.
//  Provides access to labs, testing history, and configuration options.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Settings view for soil testing functionality
struct SoilTestSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Lab.name, ascending: true)],
        animation: .default
    )
    private var labs: FetchedResults<Lab>
    
    @State private var showingNewLab = false
    @State private var showingTestFlow = false
    
    var body: some View {
        List {
            // Quick Actions Section
            Section("Soil Testing") {
                Button(action: { showingTestFlow = true }) {
                    HStack {
                        Image(systemName: "flask.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                            Text("Add Soil Test")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("Record new soil test results")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: SoilTestHistoryView()) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(AppTheme.Colors.info)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                            Text("Test History")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("View all soil test records")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            
            // Laboratory Management Section
            Section("Laboratory Management") {
                ForEach(labs, id: \.id) { lab in
                    NavigationLink(destination: LabDetailView(lab: lab)) {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(AppTheme.Colors.secondary)
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                                Text(lab.name ?? "Unnamed Lab")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                if let phone = lab.phone, !phone.isEmpty {
                                    Text(phone)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Test count badge
                            if let testCount = lab.soilTests?.count, testCount > 0 {
                                Text("\(testCount)")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.Colors.primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteLabs)
                
                Button(action: { showingNewLab = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Add Laboratory")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            
            // Soil Health Information Section
            Section("Soil Health Information") {
                NavigationLink(destination: SoilHealthGuideView()) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(AppTheme.Colors.organicMaterial)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                            Text("Soil Health Guide")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("Learn about soil testing and interpretation")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                
                NavigationLink(destination: SoilTestEducationView(isPresented: .constant(false)) {}) {
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(AppTheme.Colors.info)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                            Text("Testing Guide")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("How to take and submit soil samples")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Soil Testing")
        .sheet(isPresented: $showingNewLab) {
            CreateLabView { _ in
                showingNewLab = false
            }
        }
        .sheet(isPresented: $showingTestFlow) {
            SoilTestFlowView()
        }
    }
    
    private func deleteLabs(offsets: IndexSet) {
        withAnimation {
            offsets.map { labs[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting labs: \(error)")
            }
        }
    }
}

// MARK: - Soil Test History View

/// Comprehensive view of all soil test history across fields
struct SoilTestHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \SoilTest.date, ascending: false)
        ],
        animation: .default
    )
    private var allSoilTests: FetchedResults<SoilTest>
    
    var body: some View {
        List {
            if allSoilTests.isEmpty {
                EmptyStateView(
                    title: "No Soil Tests",
                    message: "Add your first soil test to start tracking soil health",
                    systemImage: "flask",
                    actionTitle: "Add Test"
                ) {
                    // Action handled by parent view
                }
                .listRowSeparator(.hidden)
            } else {
                ForEach(allSoilTests, id: \.id) { soilTest in
                    NavigationLink(destination: SoilTestDetailView(soilTest: soilTest)) {
                        SoilTestHistoryRow(soilTest: soilTest)
                    }
                }
                .onDelete(perform: deleteTests)
            }
        }
        .navigationTitle("Test History")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func deleteTests(offsets: IndexSet) {
        withAnimation {
            offsets.map { allSoilTests[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting tests: \(error)")
            }
        }
    }
}

// MARK: - Soil Test History Row

/// Row component for soil test history display
struct SoilTestHistoryRow: View {
    let soilTest: SoilTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(soilTest.field?.name ?? "Unknown Field")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let date = soilTest.date {
                        Text(date, style: .date)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    Text("pH \(soilTest.ph, specifier: "%.1f")")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(colorForPH(soilTest.ph))
                        .fontWeight(.semibold)
                    
                    if let labName = soilTest.lab?.name ?? soilTest.labName {
                        Text(labName)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            
            // Quick metrics overview
            HStack {
                MetricBadge(label: "OM", value: soilTest.omPct, format: "%.1f%%")
                MetricBadge(label: "P", value: soilTest.p_ppm, format: "%.0f ppm")
                MetricBadge(label: "K", value: soilTest.k_ppm, format: "%.0f ppm")
                
                Spacer()
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5, 8.0...: return AppTheme.Colors.error
        case 5.5..<6.0, 7.5..<8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
}

// MARK: - Metric Badge

/// Small badge for displaying soil test metrics
struct MetricBadge: View {
    let label: String
    let value: Double
    let format: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(String(format: format, value))
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(4)
    }
}

// MARK: - Soil Health Guide View

/// Comprehensive guide to soil health and testing
struct SoilHealthGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                
                SectionHeader(title: "USDA Soil Guidelines")
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("The USDA recommends regular soil testing to maintain optimal crop production and soil health.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    BulletPoint(text: "Test soil every 2-3 years for established fields")
                    BulletPoint(text: "Test before each new crop rotation")
                    BulletPoint(text: "Test when yield problems occur")
                    BulletPoint(text: "Test after major soil amendments")
                }
                
                SectionHeader(title: "Optimal Soil Ranges")
                
                VStack(spacing: AppTheme.Spacing.medium) {
                    SoilRangeCard(
                        parameter: "pH Level",
                        optimal: "6.0 - 7.0",
                        description: "Most nutrients are available in this range",
                        color: AppTheme.Colors.success
                    )
                    
                    SoilRangeCard(
                        parameter: "Organic Matter",
                        optimal: "3% - 5%",
                        description: "Supports healthy soil biology and structure",
                        color: AppTheme.Colors.organicMaterial
                    )
                    
                    SoilRangeCard(
                        parameter: "Phosphorus",
                        optimal: "15 - 30 ppm",
                        description: "Essential for root development and flowering",
                        color: AppTheme.Colors.info
                    )
                    
                    SoilRangeCard(
                        parameter: "Potassium",
                        optimal: "100 - 200 ppm",
                        description: "Important for disease resistance and water regulation",
                        color: AppTheme.Colors.warning
                    )
                }
                
                SectionHeader(title: "Soil Microbes & Health")
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Healthy soil contains billions of beneficial microorganisms that are essential for:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    BulletPoint(text: "Converting organic matter into plant-available nutrients")
                    BulletPoint(text: "Forming beneficial partnerships with plant roots (mycorrhizae)")
                    BulletPoint(text: "Improving soil structure and water infiltration")
                    BulletPoint(text: "Suppressing harmful soil pathogens naturally")
                    BulletPoint(text: "Cycling nutrients and maintaining soil fertility")
                    
                    Text("Impact of Chemical Fertilizers")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.warning)
                        .padding(.top)
                    
                    Text("Excessive use of chemical fertilizers can disrupt soil microbial communities by:")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    BulletPoint(text: "Killing beneficial bacteria and fungi")
                    BulletPoint(text: "Reducing microbial diversity")
                    BulletPoint(text: "Disrupting natural nutrient cycling")
                    BulletPoint(text: "Increasing soil compaction over time")
                    
                    Text("Organic farming practices promote soil biology through compost applications, cover crops, reduced tillage, and avoiding synthetic chemicals.")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.top)
                        .padding()
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                SectionHeader(title: "Plant Nutrient Deficiency Signs")
                
                VStack(spacing: AppTheme.Spacing.medium) {
                    DeficiencyCard(
                        nutrient: "Nitrogen (N)",
                        signs: "Yellow lower leaves, stunted growth, pale green color",
                        causes: "Low organic matter, excessive rainfall, poor soil biology"
                    )
                    
                    DeficiencyCard(
                        nutrient: "Phosphorus (P)",
                        signs: "Purple or red leaf coloring, delayed maturity, poor root development",
                        causes: "Cold soils, high pH, aluminum toxicity"
                    )
                    
                    DeficiencyCard(
                        nutrient: "Potassium (K)",
                        signs: "Brown leaf edges, weak stems, increased disease susceptibility",
                        causes: "Sandy soils, excessive calcium or magnesium"
                    )
                    
                    DeficiencyCard(
                        nutrient: "Iron (Fe)",
                        signs: "Yellow leaves with green veins, especially on new growth",
                        causes: "High pH (above 7.5), poor drainage, excess phosphorus"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Soil Health Guide")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Soil Range Card

/// Card displaying optimal soil parameter ranges
struct SoilRangeCard: View {
    let parameter: String
    let optimal: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(parameter)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Optimal: \(optimal)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Deficiency Card

/// Card displaying nutrient deficiency information
struct DeficiencyCard: View {
    let nutrient: String
    let signs: String
    let causes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(nutrient)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Signs: \(signs)")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Common causes: \(causes)")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Preview Provider

struct SoilTestSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SoilTestSettingsView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}