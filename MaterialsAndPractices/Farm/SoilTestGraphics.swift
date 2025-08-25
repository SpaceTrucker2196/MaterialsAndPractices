//
//  SoilTestGraphics.swift
//  MaterialsAndPractices
//
//  Core Graphics components for visualizing soil test data.
//  Provides pH spectrum and nutrient level indicators.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreGraphics

// MARK: - pH Spectrum View

/// Visual pH spectrum with current pH level indicator
struct PHSpectrumView: View {
    let currentPH: Double
    let showLabels: Bool
    
    init(currentPH: Double, showLabels: Bool = true) {
        self.currentPH = currentPH
        self.showLabels = showLabels
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Spectrum with indicator
            ZStack(alignment: .leading) {
                // Background spectrum
                PHSpectrumBackground()
                    .frame(height: 30)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                
                // Current pH indicator
                PHIndicator(ph: currentPH)
            }
            .frame(height: 40)
            
            if showLabels {
                // pH scale labels
                HStack {
                    ForEach([4.0, 5.0, 6.0, 7.0, 8.0, 9.0], id: \.self) { ph in
                        Text("\(ph, specifier: "%.0f")")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // pH interpretation labels
                HStack {
                    Text("Acidic")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("Neutral")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("Alkaline")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - pH Spectrum Background

/// Core Graphics background for pH spectrum
struct PHSpectrumBackground: View {
    var body: some View {
        Canvas { context, size in
            // Define pH range and colors
            let phRange = 4.0...9.0
            let colors: [(ph: Double, color: Color)] = [
                (4.0, Color.red),           // Very acidic
                (5.0, Color.orange),        // Acidic
                (6.0, Color.yellow),        // Slightly acidic
                (7.0, Color.green),         // Neutral
                (8.0, Color.blue),          // Slightly alkaline
                (9.0, Color.purple)         // Very alkaline
            ]
            
            // Create gradient
            let gradient = Gradient(stops: colors.map { colorStop in
                let position = CGFloat((colorStop.ph - phRange.lowerBound) / (phRange.upperBound - phRange.lowerBound))
                return Gradient.Stop(color: colorStop.color, location: position)
            })
            
            // Draw gradient rectangle
            let rect = CGRect(origin: .zero, size: size)
            context.fill(
                Path(rect),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: size.height / 2),
                    endPoint: CGPoint(x: size.width, y: size.height / 2)
                )
            )
            
            // Add optimal range indicator (6.0-7.5)
            let optimalStart = CGFloat((6.0 - phRange.lowerBound) / (phRange.upperBound - phRange.lowerBound)) * size.width
            let optimalEnd = CGFloat((7.5 - phRange.lowerBound) / (phRange.upperBound - phRange.lowerBound)) * size.width
            
            let optimalRect = CGRect(
                x: optimalStart,
                y: 0,
                width: optimalEnd - optimalStart,
                height: size.height
            )
            
            // Add subtle border for optimal range
            context.stroke(
                Path(optimalRect),
                with: .color(.white),
                lineWidth: 2
            )
        }
    }
}

// MARK: - pH Indicator

/// Indicator showing current pH position on spectrum
struct PHIndicator: View {
    let ph: Double
    
    var body: some View {
        GeometryReader { geometry in
            let phRange = 4.0...9.0
            let clampedPH = max(phRange.lowerBound, min(phRange.upperBound, ph))
            let position = CGFloat((clampedPH - phRange.lowerBound) / (phRange.upperBound - phRange.lowerBound))
            let xPosition = position * geometry.size.width
            
            VStack(spacing: 2) {
                // Arrow pointing down
                Triangle()
                    .fill(AppTheme.Colors.textPrimary)
                    .frame(width: 12, height: 8)
                
                // pH value label
                Text("\(ph, specifier: "%.1f")")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.backgroundPrimary)
                    .cornerRadius(4)
                    .shadow(radius: 2)
            }
            .offset(x: xPosition - 6) // Center the indicator
        }
    }
}

// MARK: - Triangle Shape

/// Triangle shape for pH indicator arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Nutrient Level Indicator

/// Visual indicator for nutrient levels (P, K, CEC)
struct NutrientLevelIndicator: View {
    let value: Double
    let ranges: [(range: Range<Double>, label: String, color: Color)]
    let unit: String
    let name: String
    
    init(value: Double, nutrientType: NutrientType) {
        self.value = value
        self.unit = nutrientType.unit
        self.name = nutrientType.name
        self.ranges = nutrientType.ranges
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Header with name and value
            HStack {
                Text(name)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(value, specifier: "%.1f")\(unit)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(currentColor)
                    .fontWeight(.semibold)
            }
            
            // Level indicator bar
            HStack(spacing: 2) {
                ForEach(Array(ranges.enumerated()), id: \.offset) { index, range in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isInRange(value, range.range) ? range.color : range.color.opacity(0.3))
                        .frame(height: 8)
                }
            }
            
            // Range labels
            HStack {
                ForEach(ranges, id: \.label) { range in
                    Text(range.label)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(isInRange(value, range.range) ? range.color : AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Interpretation
            Text(interpretationText)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var currentColor: Color {
        for range in ranges {
            if isInRange(value, range.range) {
                return range.color
            }
        }
        return AppTheme.Colors.textSecondary
    }
    
    private var interpretationText: String {
        for range in ranges {
            if isInRange(value, range.range) {
                switch range.label {
                case "Low":
                    return "May need \(name.lowercased()) supplementation"
                case "Medium":
                    return "Adequate \(name.lowercased()) levels"
                case "High":
                    return "Sufficient \(name.lowercased()) for most crops"
                default:
                    return range.label
                }
            }
        }
        return "Out of typical range"
    }
    
    private func isInRange(_ value: Double, _ range: Range<Double>) -> Bool {
        range.contains(value)
    }
}

// MARK: - Nutrient Type Definitions

/// Nutrient types with their ranges and characteristics
enum NutrientType {
    case phosphorus
    case potassium
    case cec
    case organicMatter
    
    var name: String {
        switch self {
        case .phosphorus: return "Phosphorus"
        case .potassium: return "Potassium"
        case .cec: return "CEC"
        case .organicMatter: return "Organic Matter"
        }
    }
    
    var unit: String {
        switch self {
        case .phosphorus, .potassium: return " ppm"
        case .cec: return " meq/100g"
        case .organicMatter: return "%"
        }
    }
    
    var ranges: [(range: Range<Double>, label: String, color: Color)] {
        switch self {
        case .phosphorus:
            return [
                (0..<15, "Low", AppTheme.Colors.error),
                (15..<30, "Medium", AppTheme.Colors.warning),
                (30..<200, "High", AppTheme.Colors.success)
            ]
        case .potassium:
            return [
                (0..<100, "Low", AppTheme.Colors.error),
                (100..<200, "Medium", AppTheme.Colors.warning),
                (200..<500, "High", AppTheme.Colors.success)
            ]
        case .cec:
            return [
                (0..<10, "Low", AppTheme.Colors.error),
                (10..<20, "Medium", AppTheme.Colors.warning),
                (20..<40, "High", AppTheme.Colors.success)
            ]
        case .organicMatter:
            return [
                (0..<2, "Low", AppTheme.Colors.error),
                (2..<3, "Medium", AppTheme.Colors.warning),
                (3..<10, "High", AppTheme.Colors.success)
            ]
        }
    }
}

// MARK: - Soil Health Summary

/// Overall soil health visualization
struct SoilHealthSummary: View {
    let soilTest: SoilTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            SectionHeader(title: "Soil Health Overview")
            
            // pH Spectrum
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("pH Level")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                PHSpectrumView(currentPH: soilTest.ph)
            }
            
            // Nutrient indicators in grid
            VStack(spacing: AppTheme.Spacing.medium) {
                NutrientLevelIndicator(value: soilTest.omPct, nutrientType: .organicMatter)
                NutrientLevelIndicator(value: soilTest.p_ppm, nutrientType: .phosphorus)
                NutrientLevelIndicator(value: soilTest.k_ppm, nutrientType: .potassium)
                NutrientLevelIndicator(value: soilTest.cec, nutrientType: .cec)
            }
        }
    }
}

// MARK: - Preview Provider

struct SoilTestGraphics_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PHSpectrumView(currentPH: 6.5)
                .frame(height: 80)
            
            NutrientLevelIndicator(value: 25, nutrientType: .phosphorus)
            
            NutrientLevelIndicator(value: 3.5, nutrientType: .organicMatter)
        }
        .padding()
    }
}