//
//  HarvestCalendarHeatMap.swift
//  MaterialsAndPractices
//
//  Provides reusable harvest calendar heat map component showing
//  optimal harvest timing throughout the growing year with visual indicators.
//  Supports comprehensive farm management system scheduling.
//
//  Created by GitHub Copilot on 12/18/24.
//

import SwiftUI
import Foundation

// MARK: - Harvest Season Data

/// Data structure for harvest calendar information
struct HarvestCalendarData {
    let bestHarvestWeeks: [Int]      // Week numbers for best harvest timing
    let goodHarvestWeeks: [Int]      // Week numbers for good harvest timing
    let cultivar: Cultivar
    let plantedDate: Date?
    let usdaZone: String?
    
    /// Generate harvest quality for a given week
    func harvestQuality(for week: Int) -> HarvestQuality {
        if bestHarvestWeeks.contains(week) {
            return .best
        } else if goodHarvestWeeks.contains(week) {
            return .good
        } else if isWithinGrowingSeason(week: week) {
            return .fair
        } else {
            return .offSeason
        }
    }
    
    /// Check if week is within general growing season
    private func isWithinGrowingSeason(week: Int) -> Bool {
        // General growing season is roughly weeks 10-40 (March through early October)
        return week >= 10 && week <= 40
    }
}

/// Enumeration for harvest quality ratings
enum HarvestQuality: CaseIterable {
    case best, good, fair, offSeason
    
    var color: Color {
        switch self {
        case .best: return AppTheme.Colors.bestHarvest
        case .good: return AppTheme.Colors.goodHarvest
        case .fair: return AppTheme.Colors.defaultHarvest
        case .offSeason: return AppTheme.Colors.offSeason
        }
    }
    
    var opacity: Double {
        switch self {
        case .best: return 1.0
        case .good: return 0.8
        case .fair: return 0.4
        case .offSeason: return 0.6
        }
    }
    
    var description: String {
        switch self {
        case .best: return "Best Harvest"
        case .good: return "Good Harvest"  
        case .fair: return "Fair Harvest"
        case .offSeason: return "Off Season"
        }
    }
}

// MARK: - Harvest Calendar Heat Map View

/// Grid-based calendar heat map showing harvest timing throughout the year
/// Displays weeks from January to December with color-coded harvest quality
struct HarvestCalendarHeatMap: View {
    let harvestData: HarvestCalendarData
    let showLabels: Bool
    let showLegend: Bool
    
    init(
        harvestData: HarvestCalendarData,
        showLabels: Bool = true,
        showLegend: Bool = true
    ) {
        self.harvestData = harvestData
        self.showLabels = showLabels
        self.showLegend = showLegend
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if showLabels {
                headerSection
            }
            
            calendarGrid
            
            if showLegend {
                legendSection
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Header section with cultivar information
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(harvestData.cultivar.emoji ?? "🌱")
                    .font(.title2)
                
                Text("Harvest Calendar: \(harvestData.cultivar.name ?? "Unknown")")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            if let plantedDate = harvestData.plantedDate {
                Text("Planted: \(plantedDate, style: .date)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Main calendar grid showing weeks
    private var calendarGrid: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Month labels
            if showLabels {
                monthLabelsView
            }
            
            // Week grid (12 months x ~4.3 weeks each = 52 weeks)
            LazyVGrid(columns: gridColumns, spacing: 2) {
                ForEach(1...52, id: \.self) { week in
                    weekCell(for: week)
                }
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Individual week cell in the calendar
    private func weekCell(for week: Int) -> some View {
        let quality = harvestData.harvestQuality(for: week)
        let isCurrentWeek = Calendar.current.component(.weekOfYear, from: Date()) == week
        
        return Rectangle()
            .fill(quality.color.opacity(quality.opacity))
            .frame(width: 20, height: 20)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(
                        isCurrentWeek ? AppTheme.Colors.primary : Color.clear,
                        lineWidth: isCurrentWeek ? 2 : 0
                    )
            )
            .animation(.easeInOut(duration: 0.3), value: quality)
    }
    
    /// Month labels at the top of the grid
    private var monthLabelsView: some View {
        HStack {
            ForEach(monthsInYear, id: \.self) { month in
                Text(month)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    /// Legend showing harvest quality meanings
    private var legendSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Legend")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.small) {
                ForEach(HarvestQuality.allCases, id: \.self) { quality in
                    HStack(spacing: AppTheme.Spacing.small) {
                        Rectangle()
                            .fill(quality.color.opacity(quality.opacity))
                            .frame(width: 16, height: 16)
                            .cornerRadius(2)
                        
                        Text(quality.description)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Grid columns for the calendar layout
    private var gridColumns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: 13) // ~4 weeks per month
    }
    
    /// Month abbreviations for labels
    private var monthsInYear: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return (1...12).compactMap { month in
            let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1))
            return date != nil ? formatter.string(from: date!) : nil
        }
    }
}

// MARK: - Harvest Calculator Enhancement

extension HarvestCalculator {
    
    /// Calculate harvest calendar data for a cultivar
    /// - Parameters:
    ///   - cultivar: The cultivar to calculate harvest timing for
    ///   - plantDate: The date the cultivar was planted
    ///   - usdaZone: The USDA hardiness zone (optional)
    /// - Returns: Harvest calendar data for heat map display
    static func calculateHarvestCalendarData(
        cultivar: Cultivar,
        plantDate: Date,
        usdaZone: String? = nil
    ) -> HarvestCalendarData {
        let growingDays = cultivar.parseGrowingDays()
        let calendar = Calendar.current
        
        // Calculate harvest week ranges
        let earlyHarvestDate = calendar.date(byAdding: .day, value: growingDays.early, to: plantDate) ?? plantDate
        let lateHarvestDate = calendar.date(byAdding: .day, value: growingDays.late, to: plantDate) ?? plantDate
        
        let earlyWeek = calendar.component(.weekOfYear, from: earlyHarvestDate)
        let lateWeek = calendar.component(.weekOfYear, from: lateHarvestDate)
        
        // Generate best harvest weeks (core harvest period)
        let bestWeeks = Array(earlyWeek...min(lateWeek, earlyWeek + 2))
        
        // Generate good harvest weeks (extended period)
        let goodStartWeek = max(1, earlyWeek - 1)
        let goodEndWeek = min(52, lateWeek + 1)
        let goodWeeks = Array(goodStartWeek...goodEndWeek).filter { !bestWeeks.contains($0) }
        
        return HarvestCalendarData(
            bestHarvestWeeks: bestWeeks,
            goodHarvestWeeks: goodWeeks,
            cultivar: cultivar,
            plantedDate: plantDate,
            usdaZone: usdaZone
        )
    }
}

// MARK: - Preview Provider

struct HarvestCalendarHeatMap_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let sampleCultivar = Cultivar(context: context)
        sampleCultivar.name = "Tomato"
        sampleCultivar.emoji = "🍅"
        sampleCultivar.growingDays = "75-85"
        
        let plantDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let harvestData = HarvestCalculator.calculateHarvestCalendarData(
            cultivar: sampleCultivar,
            plantDate: plantDate
        )
        
        return VStack {
            HarvestCalendarHeatMap(harvestData: harvestData)
                .padding()
            
            HarvestCalendarHeatMap(
                harvestData: harvestData,
                showLabels: false,
                showLegend: false
            )
            .padding()
        }
        .background(AppTheme.Colors.backgroundPrimary)
    }
}