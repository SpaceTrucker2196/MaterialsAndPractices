
import SwiftUI
import Foundation

// MARK: - Harvest Season Data

/// Data structure for harvest calendar information
struct HarvestCalendarData {
    let bestHarvestWeeks: [Int]
    let goodHarvestWeeks: [Int]
    let cultivar: Cultivar
    let plantedDate: Date?
    let usdaZone: String?
    
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
    
    private func isWithinGrowingSeason(week: Int) -> Bool {
        return week >= 10 && week <= 40
    }
}

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
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(harvestData.cultivar.emoji ?? "🌱")
                    .font(.title2)
                Text("\(harvestData.cultivar.name ?? "Unknown")")
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
    
    private var calendarGrid: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if showLabels {
                monthLabelsView
            }
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
    
    private var legendSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Legend")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.small) {
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
    
    private var gridColumns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: 13)
    }
    
    private var monthsInYear: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return (1...12).compactMap {
            Calendar.current.date(from: DateComponents(year: 2024, month: $0, day: 1)).map {
                formatter.string(from: $0)
            }
        }
    }
}

// MARK: - Harvest Calculator Enhancement

extension HarvestCalculator {
    
    static func calculateHarvestCalendarData(
        cultivar: Cultivar,
        plantDate: Date,
        usdaZone: String? = nil
    ) -> HarvestCalendarData {
        let growingDays = cultivar.parseGrowingDays()
        let calendar = Calendar.current
        
        let earlyHarvestDate = calendar.date(byAdding: .day, value: growingDays.early, to: plantDate) ?? plantDate
        let lateHarvestDate = calendar.date(byAdding: .day, value: growingDays.late, to: plantDate) ?? plantDate
        
        let earlyWeek = calendar.component(.weekOfYear, from: earlyHarvestDate)
        let lateWeek = calendar.component(.weekOfYear, from: lateHarvestDate)
        
        let bestWeeks: [Int]
        if lateWeek >= earlyWeek {
            bestWeeks = Array(earlyWeek...min(lateWeek, earlyWeek + 2))
        } else {
            bestWeeks = Array(earlyWeek...52) + Array(1...min(lateWeek, 2))
        }
        
        let goodStartWeek = max(1, earlyWeek - 1)
        let goodEndWeek = min(52, lateWeek + 1)
        let goodWeeks: [Int]
        if lateWeek >= earlyWeek {
            goodWeeks = Array(goodStartWeek...goodEndWeek).filter { !bestWeeks.contains($0) }
        } else {
            goodWeeks = (Array(goodStartWeek...52) + Array(1...goodEndWeek)).filter { !bestWeeks.contains($0) }
        }
        
        return HarvestCalendarData(
            bestHarvestWeeks: bestWeeks,
            goodHarvestWeeks: goodWeeks,
            cultivar: cultivar,
            plantedDate: plantDate,
            usdaZone: usdaZone
        )
    }
}

// MARK: - Preview

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
            
            HarvestCalendarHeatMap(harvestData: harvestData, showLabels: false, showLegend: false)
                .padding()
        }
        .background(AppTheme.Colors.backgroundPrimary)
    }
}
