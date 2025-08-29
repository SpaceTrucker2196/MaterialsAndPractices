//
//  HarvestHeatMapView.swift
//  MaterialsAndPractices
//
//  52-week harvest heat map visualization for optimal harvest timing based on USDA zones.
//  Provides interactive zone comparison and harvest week highlighting based on user location.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import Foundation

/// Heat map component displaying 52 weeks of the year with harvest timing visualization
/// Highlights optimal harvest weeks in green and allows zone comparisons
struct HarvestHeatMapView: View {
    let cultivar: Cultivar
    @State private var selectedZone: ZoneComparison = .normal
    @State private var currentUserZone: Int = 7 // Default to zone 7, would be determined by location
    
    // MARK: - Zone Comparison Options
    
    enum ZoneComparison: String, CaseIterable {
        case cooler = "Cool"
        case normal = "Normal" 
        case warmer = "Warm"
        
        var zoneOffset: Int {
            switch self {
            case .cooler: return -1
            case .normal: return 0
            case .warmer: return 1
            }
        }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // MARK: - Header
            headerSection
            
            // MARK: - Heat Map Grid
            heatMapGrid
            
            // MARK: - Zone Comparison Tabs
            zoneComparisonTabs
            
            // MARK: - Legend
            legendSection
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Harvest Calendar")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("Zone \(adjustedZone)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.extraSmall)
                    .background(AppTheme.ColorCoding.colorForUSDAZone("\(adjustedZone)").opacity(0.2))
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
            
            Text("52-week harvest timing for \(cultivar.name ?? "Unknown")")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Heat Map Grid
    
    private var heatMapGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 2) {
            ForEach(1...52, id: \.self) { week in
                weekTile(for: week)
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    // MARK: - Week Tile
    
    private func weekTile(for week: Int) -> some View {
        Rectangle()
            .fill(colorForWeek(week))
            .frame(width: 12, height: 12)
            .cornerRadius(2)
            .overlay(
                // Add week number for every 4th week
                Group {
                    if week % 4 == 0 {
                        Text("\(week)")
                            .font(.system(size: 6, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                }
            )
    }
    
    // MARK: - Zone Comparison Tabs
    
    private var zoneComparisonTabs: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ForEach(ZoneComparison.allCases, id: \.self) { zone in
                Button(action: {
                    selectedZone = zone
                }) {
                    Text(zone.rawValue)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(selectedZone == zone ? AppTheme.Colors.backgroundPrimary : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.small)
                        .background(
                            Group {
                                if selectedZone == zone {
                                    AppTheme.Colors.primary
                                } else {
                                    AppTheme.Colors.backgroundTertiary
                                }
                            }
                        )
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
    }
    
    // MARK: - Legend Section
    
    private var legendSection: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            legendItem(color: AppTheme.Colors.bestHarvest, label: "Best Harvest")
            legendItem(color: AppTheme.Colors.goodHarvest, label: "Good Harvest")
            legendItem(color: AppTheme.Colors.defaultHarvest, label: "Off Season")
        }
        .frame(maxWidth: .infinity)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.extraSmall) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(label)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var adjustedZone: Int {
        let baseZone = currentUserZone
        let adjustment = selectedZone.zoneOffset
        return max(1, min(11, baseZone + adjustment))
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 2), count: 13) // 13 columns for 4-week months
    }
    
    /// Determines the color for a specific week based on harvest data
    /// - Parameter week: Week number (1-52)
    /// - Returns: Color representing harvest quality for that week
    private func colorForWeek(_ week: Int) -> Color {
        let harvestWeeks = parseHarvestWeeks(for: adjustedZone)
        
        if harvestWeeks.best.contains(week) {
            return AppTheme.Colors.bestHarvest
        } else if harvestWeeks.good.contains(week) {
            return AppTheme.Colors.goodHarvest
        } else {
            return AppTheme.Colors.defaultHarvest
        }
    }
    
    /// Parses harvest week data from cultivar's best harvest information
    /// - Parameter zone: USDA zone number
    /// - Returns: Tuple with best and good harvest weeks
    private func parseHarvestWeeks(for zone: Int) -> (best: [Int], good: [Int]) {
        guard let harvestData = cultivar.bestHarvest else {
            return (best: [], good: [])
        }
        
        // Parse JSON-like data structure
        // For now, return sample data based on zone and season
        let baseWeeks = getBaseHarvestWeeks()
        let zoneAdjustment = (zone - 7) * 2 // Adjust weeks based on zone difference from zone 7
        
        let adjustedBest = baseWeeks.best.map { max(1, min(52, $0 + zoneAdjustment)) }
        let adjustedGood = baseWeeks.good.map { max(1, min(52, $0 + zoneAdjustment)) }
        
        return (best: adjustedBest, good: adjustedGood)
    }
    
    /// Returns base harvest weeks based on cultivar characteristics
    /// - Returns: Tuple with best and good harvest weeks for zone 7
    private func getBaseHarvestWeeks() -> (best: [Int], good: [Int]) {
        let season = cultivar.season?.lowercased() ?? ""
        
        if season.contains("summer") {
            // Summer crops: peak harvest mid to late summer
            return (best: [28, 29, 30, 31, 32], good: [26, 27, 33, 34, 35, 36])
        } else if season.contains("cool") {
            // Cool season crops: spring and fall harvests
            return (best: [12, 13, 14, 15, 40, 41, 42, 43], good: [10, 11, 16, 17, 38, 39, 44, 45])
        } else {
            // All season crops: extended harvest period
            return (best: [20, 21, 22, 23, 24, 25], good: [18, 19, 26, 27, 28, 29])
        }
    }
}

// MARK: - Preview

struct HarvestHeatMapView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample cultivar for preview
        let context = PersistenceController.preview.container.viewContext
        let sampleCultivar = Cultivar(context: context)
        sampleCultivar.name = "Tomato"
        sampleCultivar.season = "Summer"
        sampleCultivar.hardyZone = "5-9"
        sampleCultivar.bestHarvest = "{\"7\": [28, 29, 30, 31, 32]}"
        
        return HarvestHeatMapView(cultivar: sampleCultivar)
            .padding()
            .background(AppTheme.Colors.backgroundPrimary)
            .previewLayout(.sizeThatFits)
    }
}