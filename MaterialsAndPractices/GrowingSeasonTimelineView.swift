//
//  GrowingSeasonTimelineView.swift
//  MaterialsAndPractices
//
//  Timeline visualization showing local growing season with frost dates and harvest markers.
//  Displays days to harvest countdown and optimal planting/harvest timing.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import Foundation

/// Timeline component showing the growing season from last frost to first frost
/// with planting and harvest markers based on location and cultivar data
struct GrowingSeasonTimelineView: View {
    let cultivar: Cultivar
    let grow: Grow?
    @State private var currentDate = Date()
    @State private var lastFrostDate = Calendar.current.date(from: DateComponents(year: 2024, month: 4, day: 15)) ?? Date()
    @State private var firstFrostDate = Calendar.current.date(from: DateComponents(year: 2024, month: 10, day: 15)) ?? Date()
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // MARK: - Header with countdown
            headerSection
            
            // MARK: - Timeline
            timelineSection
            
            // MARK: - Frost date indicators
            frostDateSection
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Growing Season Timeline")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                if let daysToHarvest = calculateDaysToHarvest() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(daysToHarvest)")
                            .font(AppTheme.Typography.displaySmall)
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("days to harvest")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            
            Text(cultivar.name ?? "Unknown Cultivar")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Timeline bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background timeline
                    Rectangle()
                        .fill(AppTheme.Colors.backgroundTertiary)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Growing season portion
                    Rectangle()
                        .fill(AppTheme.Colors.secondary.opacity(0.6))
                        .frame(width: growingSeasonWidth(totalWidth: geometry.size.width), height: 8)
                        .cornerRadius(4)
                        .offset(x: frostStartOffset(totalWidth: geometry.size.width))
                    
                    // Current date marker
                    currentDateMarker(totalWidth: geometry.size.width)
                    
                    // Planting markers
                    plantingMarkers(totalWidth: geometry.size.width)
                    
                    // Harvest markers
                    harvestMarkers(totalWidth: geometry.size.width)
                    
                    // Planted date marker (if grow exists)
                    if let grow = grow, let plantedDate = grow.plantedDate {
                        plantedDateMarker(for: plantedDate, totalWidth: geometry.size.width)
                    }
                }
            }
            .frame(height: 40)
            
            // Month labels
            monthLabelsView
        }
    }
    
    // MARK: - Frost Date Section
    
    private var frostDateSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Frost")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(formatDate(lastFrostDate))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text("Growing Days")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text("\(growingSeasonDays)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.success)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("First Frost")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(formatDate(firstFrostDate))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }
    
    // MARK: - Timeline Components
    
    private func currentDateMarker(totalWidth: CGFloat) -> some View {
        let position = datePosition(for: currentDate, totalWidth: totalWidth)
        
        return VStack(spacing: 2) {
            Rectangle()
                .fill(AppTheme.Colors.accent)
                .frame(width: 2, height: 20)
            
            Circle()
                .fill(AppTheme.Colors.accent)
                .frame(width: 8, height: 8)
        }
        .offset(x: position - 1)
    }
    
    private func plantingMarkers(totalWidth: CGFloat) -> some View {
        ForEach(Array(optimalPlantingDates.enumerated()), id: \.offset) { index, date in
            plantingMarker(for: date, totalWidth: totalWidth)
        }
    }
    
    private func plantingMarker(for date: Date, totalWidth: CGFloat) -> some View {
        let position = datePosition(for: date, totalWidth: totalWidth)
        
        return VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.Colors.success)
                .frame(width: 2, height: 15)
            
            Text("P")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(AppTheme.Colors.success)
        }
        .offset(x: position - 1)
    }
    
    private func harvestMarkers(totalWidth: CGFloat) -> some View {
        ForEach(Array(optimalHarvestDates.enumerated()), id: \.offset) { index, date in
            harvestMarker(for: date, totalWidth: totalWidth)
        }
    }
    
    private func harvestMarker(for date: Date, totalWidth: CGFloat) -> some View {
        let position = datePosition(for: date, totalWidth: totalWidth)
        
        return VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.Colors.bestHarvest)
                .frame(width: 2, height: 15)
            
            Text("H")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(AppTheme.Colors.bestHarvest)
        }
        .offset(x: position - 1)
    }
    
    private func plantedDateMarker(for date: Date, totalWidth: CGFloat) -> some View {
        let position = datePosition(for: date, totalWidth: totalWidth)
        
        return VStack(spacing: 2) {
            Rectangle()
                .fill(AppTheme.Colors.primary)
                .frame(width: 3, height: 25)
            
            Text("Planted")
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(AppTheme.Colors.primary)
                .rotationEffect(.degrees(-45))
        }
        .offset(x: position - 1.5)
    }
    
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
    
    // MARK: - Helper Properties and Methods
    
    private var monthsInYear: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return (1...12).compactMap { month in
            let date = Calendar.current.date(from: DateComponents(year: 2024, month: month, day: 1))
            return date != nil ? formatter.string(from: date!) : nil
        }
    }
    
    private var growingSeasonDays: Int {
        Calendar.current.dateComponents([.day], from: lastFrostDate, to: firstFrostDate).day ?? 0
    }
    
    private var optimalPlantingDates: [Date] {
        // Parse planting weeks from cultivar data
        guard let plantingWeek = cultivar.plantingWeek else { return [] }
        
        // Convert week ranges to actual dates
        let weekComponents = plantingWeek.components(separatedBy: "-")
        guard let startWeek = Int(weekComponents.first ?? ""),
              let endWeek = Int(weekComponents.last ?? "") else { return [] }
        
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? Date()
        
        var dates: [Date] = []
        for week in [startWeek, (startWeek + endWeek) / 2, endWeek] {
            if let date = calendar.date(byAdding: .weekOfYear, value: week - 1, to: startOfYear) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private var optimalHarvestDates: [Date] {
        // Calculate harvest dates based on growing days
        guard let plantedDate = grow?.plantedDate,
              let growingDaysString = cultivar.growingDays,
              let growingDays = extractDayNumber(from: growingDaysString) else {
            return []
        }
        
        let calendar = Calendar.current
        let harvestDate = calendar.date(byAdding: .day, value: growingDays, to: plantedDate) ?? Date()
        
        return [harvestDate]
    }
    
    private func calculateDaysToHarvest() -> Int? {
        guard let plantedDate = grow?.plantedDate,
              let growingDaysString = cultivar.growingDays,
              let growingDays = extractDayNumber(from: growingDaysString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let harvestDate = calendar.date(byAdding: .day, value: growingDays, to: plantedDate) ?? Date()
        let daysToHarvest = calendar.dateComponents([.day], from: currentDate, to: harvestDate).day ?? 0
        
        return max(0, daysToHarvest)
    }
    
    private func extractDayNumber(from days: String) -> Int? {
        let cleaned = days.replacingOccurrences(of: "[^0-9-]", with: "", options: .regularExpression)
        let parts = cleaned.components(separatedBy: "-")
        return Int(parts.first ?? "0")
    }
    
    private func datePosition(for date: Date, totalWidth: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? Date()
        let endOfYear = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31)) ?? Date()
        
        let totalDays = calendar.dateComponents([.day], from: startOfYear, to: endOfYear).day ?? 365
        let daysSinceStart = calendar.dateComponents([.day], from: startOfYear, to: date).day ?? 0
        
        return (CGFloat(daysSinceStart) / CGFloat(totalDays)) * totalWidth
    }
    
    private func frostStartOffset(totalWidth: CGFloat) -> CGFloat {
        return datePosition(for: lastFrostDate, totalWidth: totalWidth)
    }
    
    private func growingSeasonWidth(totalWidth: CGFloat) -> CGFloat {
        let startPosition = datePosition(for: lastFrostDate, totalWidth: totalWidth)
        let endPosition = datePosition(for: firstFrostDate, totalWidth: totalWidth)
        return endPosition - startPosition
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct GrowingSeasonTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample cultivar
        let sampleCultivar = Cultivar(context: context)
        sampleCultivar.name = "Tomato"
        sampleCultivar.growingDays = "75-85"
        sampleCultivar.plantingWeek = "16-20"
        
        // Create sample grow
        let sampleGrow = Grow(context: context)
        sampleGrow.plantedDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        
        return GrowingSeasonTimelineView(cultivar: sampleCultivar, grow: sampleGrow)
            .padding()
            .background(AppTheme.Colors.backgroundPrimary)
            .previewLayout(.sizeThatFits)
    }
}