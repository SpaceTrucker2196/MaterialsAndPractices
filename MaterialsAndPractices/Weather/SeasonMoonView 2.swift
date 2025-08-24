//
//  SeasonMoonView.swift
//  MaterialsAndPractices
//
//  Combined display component for current season and moon phase information.
//  Provides agricultural timing guidance for planting and harvesting.
//
//  Created by AI Assistant.
//

import SwiftUI

/// Combined view displaying current season and moon phase information
/// Provides agricultural context and timing guidance for farming activities
struct SeasonMoonView: View {
    // MARK: - Properties
    
    @State private var currentSeason: SeasonCalculator.Season = .spring
    @State private var currentMoonPhase: MoonPhaseCalculator.MoonPhase = .newMoon
    @State private var daysUntilNextSeason: Int = 0
    @State private var daysUntilFullMoon: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                Text("Season & Moon Phase")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                // Refresh button
                Button(action: updateInformation) {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            // Season and Moon Phase Cards
            HStack(spacing: AppTheme.Spacing.medium) {
                // Season Card
                seasonCard
                    .frame(maxWidth: .infinity)
                
                // Moon Phase Card
                moonPhaseCard
                    .frame(maxWidth: .infinity)
            }
            
            // Agricultural Guidance Section
            if shouldShowGuidance {
                agriculturalGuidanceView
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .onAppear {
            updateInformation()
        }
    }
    
    // MARK: - Season Card
    
    private var seasonCard: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Season emoji and name
            HStack(spacing: AppTheme.Spacing.small) {
                Text(currentSeason.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentSeason.displayName)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(currentSeason.temperatureDescription)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Divider()
                .background(AppTheme.Colors.textTertiary)
            
            // Next season information
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Season")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text("\(daysUntilNextSeason) days")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(seasonBackgroundColor)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    // MARK: - Moon Phase Card
    
    private var moonPhaseCard: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Moon phase emoji and name
            HStack(spacing: AppTheme.Spacing.small) {
                Text(currentMoonPhase.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentMoonPhase.displayName)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    Text("\(currentMoonPhase.visibilityPercentage)% visible")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Divider()
                .background(AppTheme.Colors.textTertiary)
            
            // Next full moon information
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Full Moon")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text("\(daysUntilFullMoon) days")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(moonPhaseBackgroundColor)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    // MARK: - Agricultural Guidance
    
    private var agriculturalGuidanceView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Agricultural Guidance")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                // Season guidance
                HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(seasonColor)
                        .frame(width: 16)
                    
                    Text(currentSeason.agriculturalInfo)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                // Moon phase guidance
                HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                    Image(systemName: currentMoonPhase.symbol)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(width: 16)
                    
                    Text(currentMoonPhase.agriculturalSignificance)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                // Optimal timing indicator
                if MoonPhaseCalculator.isGoodPlantingTime(for: Date()) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .frame(width: 16)
                        
                        Text("Good time for planting")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(.green)
                    }
                } else if MoonPhaseCalculator.isGoodHarvestTime(for: Date()) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                            .frame(width: 16)
                        
                        Text("Good time for harvesting")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    // MARK: - Computed Properties
    
    private var seasonBackgroundColor: Color {
        switch currentSeason {
        case .spring:
            return Color(red: 0.9, green: 0.95, blue: 0.9)
        case .summer:
            return Color(red: 1.0, green: 0.95, blue: 0.85)
        case .autumn:
            return Color(red: 1.0, green: 0.92, blue: 0.85)
        case .winter:
            return Color(red: 0.9, green: 0.94, blue: 1.0)
        }
    }
    
    private var moonPhaseBackgroundColor: Color {
        if currentMoonPhase.isWaxing {
            return Color(red: 0.95, green: 0.95, blue: 1.0)
        } else if currentMoonPhase.isWaning {
            return Color(red: 0.95, green: 0.93, blue: 0.95)
        } else {
            return Color(red: 0.92, green: 0.92, blue: 0.92)
        }
    }
    
    private var seasonColor: Color {
        switch currentSeason {
        case .spring:
            return .green
        case .summer:
            return .orange
        case .autumn:
            return .red
        case .winter:
            return .blue
        }
    }
    
    private var shouldShowGuidance: Bool {
        // Show guidance if it's a particularly good time for agricultural activities
        return MoonPhaseCalculator.isGoodPlantingTime(for: Date()) ||
               MoonPhaseCalculator.isGoodHarvestTime(for: Date()) ||
               daysUntilFullMoon <= 3
    }
    
    // MARK: - Methods
    
    private func updateInformation() {
        let currentDate = Date()
        
        // Update season information
        currentSeason = SeasonCalculator.currentSeason()
        daysUntilNextSeason = SeasonCalculator.daysUntilNextSeason(from: currentDate)
        
        // Update moon phase information
        currentMoonPhase = MoonPhaseCalculator.currentMoonPhase()
        daysUntilFullMoon = MoonPhaseCalculator.daysUntilFullMoon(from: currentDate)
    }
}

// MARK: - Preview Provider

struct SeasonMoonView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SeasonMoonView()
                .padding()
                .background(AppTheme.Colors.backgroundPrimary)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Season & Moon View")
            
            SeasonMoonView()
                .preferredColorScheme(.dark)
                .padding()
                .background(AppTheme.Colors.backgroundPrimary)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Season & Moon View (Dark)")
        }
    }
}