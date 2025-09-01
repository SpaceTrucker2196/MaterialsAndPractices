import SwiftUI
import Foundation

// MARK: - Harvest Season Data (unchanged)

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
        week >= 10 && week <= 40
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

// MARK: - Season tinting

enum Season: String, CaseIterable {
    case winter, spring, summer, fall
    
    var tint: Color {
        switch self {
        case .spring: return Color.green.opacity(0.12)
        case .summer: return Color.yellow.opacity(0.12)
        case .fall:   return Color.orange.opacity(0.12)
        case .winter: return Color.brown.opacity(0.12)
        }
    }
    
    static func season(forMonth m: Int) -> Season {
        switch m {
        case 3,4,5:   return .spring
        case 6,7,8:   return .summer
        case 9,10,11: return .fall
        default:      return .winter
        }
    }
    
    var title: String {
        switch self {
        case .winter: return "Winter"
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall:   return "Fall"
        }
    }
}

// MARK: - Harvest Calendar Heat Map View (with grow-period highlight)

struct ActiveGrowHeatMap: View {
    let harvestData: HarvestCalendarData
    let showLabels: Bool
    private let _legendAlwaysVisible = true
    
    // Layout tokens
    private let monthHeaderHeight: CGFloat = 22
    private let legendHeight: CGFloat = 44
    private let seasonRowHeight: CGFloat = 20
    private let columnSpacing: CGFloat = 6
    private let rowSpacing: CGFloat = 6
    private let cellCornerRadius: CGFloat = 4
    private let columnCornerRadius: CGFloat = 8
    private let contentPadding: CGFloat = 8
    private let cellMinHeight: CGFloat = 14
    private let spacingAfterGrid: CGFloat = 6
    private let spacingAfterLegend: CGFloat = 6
    
    // Transparent highlight color (adjust opacity to taste)
    private let growHighlightColor = AppTheme.Colors.accent.opacity(0.18)
    
    init(
        harvestData: HarvestCalendarData,
        showLabels: Bool = true,
        showLegend: Bool = true // kept for API compatibility
    ) {
        self.harvestData = harvestData
        self.showLabels = showLabels
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            if showLabels {
                cultivarHeader
            }
            
            GeometryReader { geo in
                // Sequential layout: header → grid → season row → legend
                let cols = 12
                let rows = 4
                
                // Available area inside our padded card
                let innerWidth  = max(0, geo.size.width  - contentPadding * 2)
                let innerHeight = max(0, geo.size.height - contentPadding * 2)
                
                // Fixed vertical real estate
                let fixedTop: CGFloat = showLabels ? monthHeaderHeight : 0
                let fixedBottom: CGFloat = spacingAfterGrid + legendHeight + spacingAfterLegend + seasonRowHeight
                
                // Grid area height
                let gridAreaHeight = max(0, innerHeight - fixedTop - fixedBottom)
                
                // Spacing sums
                let totalHSpacing = columnSpacing * CGFloat(cols - 1)
                let totalVSpacing = rowSpacing * CGFloat(rows - 1)
                
                // Cell sizes with minimums
                let cellWidth  = max(0, (innerWidth - totalHSpacing) / CGFloat(cols))
                let cellHeight = max(cellMinHeight, (gridAreaHeight - totalVSpacing) / CGFloat(rows))
                let gridHeight = cellHeight * CGFloat(rows) + totalVSpacing
                let gridWidth  = cellWidth  * CGFloat(cols) + totalHSpacing
                
                let anchorDate = harvestData.plantedDate ?? Date()
                let monthAbbrevs = (1...12).map { monthAbbrev(for: $0, anchor: anchorDate) }
                let monthWeeks = monthToWeeks4(anchorDate: anchorDate) // [month: [Int?]]
                
                // Compute highlight range (weeks 1...52, wrap-aware)
                let highlightWeeks: Set<Int> = {
                    guard let planted = harvestData.plantedDate else { return [] }
                    let plantWeek = clampWeek(Calendar.current.component(.weekOfYear, from: planted))
                    let latestBest = harvestData.bestHarvestWeeks.max()
                    let latestGood = harvestData.goodHarvestWeeks.max()
                    let harvestWeek = clampWeek(latestBest ?? latestGood ?? plantWeek)
                    return weeksInRange(start: plantWeek, end: harvestWeek)
                }()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Month header
                    if showLabels {
                        HStack(alignment: .center, spacing: columnSpacing) {
                            ForEach(Array(monthAbbrevs.enumerated()), id: \.0) { _, label in
                                Text(label)
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: cellWidth, height: monthHeaderHeight)
                            }
                        }
                        .frame(width: gridWidth, alignment: .leading)
                    }
                    
                    // Grid with layered backgrounds:
                    // 1) Season bands
                    // 2) Grow-period highlight cells (transparent)
                    // 3) Week cells
                    ZStack(alignment: .topLeading) {
                        // (1) Season bands
                        HStack(spacing: columnSpacing) {
                            ForEach(1...12, id: \.self) { month in
                                RoundedRectangle(cornerRadius: columnCornerRadius)
                                    .fill(Season.season(forMonth: month).tint)
                                    .frame(width: cellWidth, height: gridHeight)
                            }
                        }
                        
                        // (2) Grow-period highlight overlay (per-cell so it follows the 4-row grid)
                        HStack(alignment: .top, spacing: columnSpacing) {
                            ForEach(1...12, id: \.self) { month in
                                let weeks = monthWeeks[month] ?? []
                                VStack(alignment: .center, spacing: rowSpacing) {
                                    ForEach(0..<rows, id: \.self) { row in
                                        let wk = (row < weeks.count) ? weeks[row] : nil
                                        RoundedRectangle(cornerRadius: cellCornerRadius)
                                            .fill(
                                                (wk != nil && highlightWeeks.contains(wk!))
                                                ? growHighlightColor
                                                : Color.clear
                                            )
                                            .frame(width: cellWidth, height: cellHeight)
                                            .accessibilityHidden(true)
                                    }
                                }
                            }
                        }
                        
                        // (3) Week cells (painted on top so harvest colors are readable)
                        HStack(alignment: .top, spacing: columnSpacing) {
                            ForEach(1...12, id: \.self) { month in
                                let weeks = monthWeeks[month] ?? []
                                VStack(alignment: .center, spacing: rowSpacing) {
                                    ForEach(0..<rows, id: \.self) { row in
                                        if row < weeks.count, let wk = weeks[row] {
                                            weekCell(for: wk)
                                                .frame(width: cellWidth, height: cellHeight)
                                        } else {
                                            RoundedRectangle(cornerRadius: cellCornerRadius)
                                                .fill(AppTheme.Colors.backgroundSecondary.opacity(0.5))
                                                .frame(width: cellWidth, height: cellHeight)
                                                .accessibilityHidden(true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: gridWidth, height: gridHeight, alignment: .topLeading)
                    
                    // Space to separate grid and legend (kept even if tight)
                    Spacer(minLength: spacingAfterGrid)
                    
                    // Bottom season row over 4 equal spans (3 months each)
                    seasonRow(
                        spanWidth: cellWidth * 3 + columnSpacing * 2,
                        gridWidth: gridWidth
                    )
                    .frame(height: seasonRowHeight)
                    
                    // Legend (always visible)
                    legendSection
                        .frame(width: gridWidth, height: legendHeight, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AppTheme.Colors.surface.opacity(0.6))
                        )
                    
                    Spacer(minLength: spacingAfterLegend)
                }
                .frame(width: innerWidth, height: innerHeight, alignment: .topLeading)
                .padding(contentPadding) // padding after sizing
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        // Ensure enough height for header + 4 rows + legend + season row; cap at 500.
        .frame(
            maxWidth: .infinity,
            minHeight:
                (showLabels ? monthHeaderHeight : 0)
                + (cellMinHeight * 4) + (rowSpacing * 3)
                + spacingAfterGrid
                + legendHeight
                + spacingAfterLegend
                + seasonRowHeight
                + contentPadding * 2,
            maxHeight: 400,
            alignment: .topLeading
        )
    }
    
    // MARK: - Season Row
    private func seasonRow(spanWidth: CGFloat, gridWidth: CGFloat) -> some View {
        HStack(spacing: columnSpacing * 3) {
            ForEach([Season.winter, .spring, .summer, .fall], id: \.self) { season in
                Text(season.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: spanWidth, alignment: .center)
            }
        }
        .frame(width: gridWidth, alignment: .leading)
    }
    
    // MARK: - Cultivar header
    private var cultivarHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(harvestData.cultivar.emoji ?? "🌱")
                    .font(.title2)
                Text(harvestData.cultivar.name ?? "Unknown")
                    .font(AppTheme.Typography.dataLarge)
                    .foregroundColor(AppTheme.Colors.textDataFieldNormal)
            }
            if let plantedDate = harvestData.plantedDate {
                Text("Planted: \(plantedDate, style: .date)")
                    .font(AppTheme.Typography.dataMedium)
                    .foregroundColor(AppTheme.Colors.textDataFieldNormal)
            }
        }
    }
    
    // MARK: - Week cell
    private func weekCell(for week: Int) -> some View {
        let quality = harvestData.harvestQuality(for: week)
        let isCurrentWeek = Calendar.current.component(.weekOfYear, from: Date()) == week
        
        return RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
            .fill(quality.color.opacity(quality.opacity))
            .overlay(
                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                    .stroke(isCurrentWeek ? AppTheme.Colors.primary : Color.clear, lineWidth: isCurrentWeek ? 2 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: quality.opacity)
            .accessibilityLabel(Text(accessibilityText(for: week, quality: quality, isCurrent: isCurrentWeek)))
    }
    
    // MARK: - Legend (always shown)
    private var legendSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Legend")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(HarvestQuality.allCases, id: \.self) { quality in
                    HStack(spacing: AppTheme.Spacing.tiny) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(quality.color.opacity(quality.opacity))
                            .frame(width: 16, height: 16)
                        Text(quality.description)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    if quality != HarvestQuality.allCases.last {
                        Spacer(minLength: 0)
                    }
                }
                // Optional: small chip for grow-period highlight (uncomment if you want it in the legend)
                /*
                HStack(spacing: AppTheme.Spacing.tiny) {
                    RoundedRectangle(cornerRadius: 2).fill(growHighlightColor).frame(width: 16, height: 16)
                    Text("Grow Period")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                */
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Helpers
    
    private func monthToWeeks4(anchorDate: Date) -> [Int: [Int?]] {
        let cal = Calendar.current
        let year = cal.component(.year, from: anchorDate)
        
        guard
            let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
            let end   = cal.date(from: DateComponents(year: year, month: 12, day: 31))
        else { return [:] }
        
        var cursor = start
        var perMonthWeeks: [Int: [Int]] = (1...12).reduce(into: [:]) { $0[$1] = [] }
        
        while cursor <= end {
            let m = cal.component(.month, from: cursor)
            var w = cal.component(.weekOfYear, from: cursor)
            if w == 53 { w = 52 }
            if let arr = perMonthWeeks[m], !arr.contains(w) {
                perMonthWeeks[m]?.append(w)
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        
        var output: [Int: [Int?]] = [:]
        for m in 1...12 {
            let weeks = perMonthWeeks[m] ?? []
            let trimmed = Array(weeks.prefix(4))
            if trimmed.count < 4 {
                output[m] = trimmed + Array(repeating: nil, count: 4 - trimmed.count)
            } else {
                output[m] = trimmed.map { Optional($0) }
            }
        }
        return output
    }
    
    private func monthAbbrev(for month: Int, anchor: Date) -> String {
        let cal = Calendar.current
        let year = cal.component(.year, from: anchor)
        let comps = DateComponents(year: year, month: month, day: 1)
        let date = cal.date(from: comps) ?? anchor
        let df = DateFormatter()
        df.calendar = cal
        df.dateFormat = "MMM"
        return df.string(from: date)
    }
    
    private func accessibilityText(for week: Int, quality: HarvestQuality, isCurrent: Bool) -> String {
        let label = quality.description
        let current = isCurrent ? " (current week)" : ""
        return "Week \(week): \(label)\(current)"
    }
    
    private func clampWeek(_ w: Int) -> Int { max(1, min(52, w == 53 ? 52 : w)) }
    
    /// Inclusive set of ISO weeks between start and end (wraps across year if needed).
    private func weeksInRange(start: Int, end: Int) -> Set<Int> {
        if start <= end {
            return Set(start...end)
        } else {
            // Wrap: e.g., start=50, end=5  -> 50...52 + 1...5
            return Set(Array(start...52) + Array(1...end))
        }
    }
}
