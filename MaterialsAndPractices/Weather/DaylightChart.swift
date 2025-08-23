//
//  DaylightChart.swift
//  MaterialsAndPractices
//
//  Daylight hours visualization component for agricultural planning.
//  Shows sunrise, sunset, and daylight duration in an intuitive graph format.
//
//  Created by AI Assistant.
//

import SwiftUI

/// Visual representation of daylight hours for agricultural planning
struct DaylightChart: View {
    // MARK: - Properties
    
    let daylightInfo: DaylightInfo
    private let chartHeight: CGFloat = 60
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Daylight Hours")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            HStack(spacing: AppTheme.Spacing.small) {
                // Sunrise time
                timeLabel(
                    title: "Sunrise",
                    time: daylightInfo.sunrise,
                    color: AppTheme.Colors.warning
                )
                
                Spacer()
                
                // Daylight duration
                VStack(spacing: AppTheme.Spacing.tiny) {
                    Text("Duration")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(formatDuration(daylightInfo.daylightDuration))
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                Spacer()
                
                // Sunset time
                timeLabel(
                    title: "Sunset",
                    time: daylightInfo.sunset,
                    color: AppTheme.Colors.error
                )
            }
            
            // Visual daylight chart
            daylightVisualization
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Components
    
    /// Time label component
    private func timeLabel(title: String, time: Date, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.tiny) {
            Text(title)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(color)
            
            Text(formatTime(time))
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    /// Visual representation of daylight hours
    private var daylightVisualization: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let sunrisePosition = sunriseRelativePosition * width
            let sunsetPosition = sunsetRelativePosition * width
            let daylightWidth = sunsetPosition - sunrisePosition
            
            ZStack(alignment: .leading) {
                // Background (night)
                Rectangle()
                    .fill(AppTheme.Colors.textTertiary.opacity(0.2))
                    .frame(height: chartHeight)
                
                // Daylight period
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.Colors.warning.opacity(0.3),
                                AppTheme.Colors.primary.opacity(0.3),
                                AppTheme.Colors.error.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: daylightWidth, height: chartHeight)
                    .offset(x: sunrisePosition)
                
                // Current time indicator
                if let currentPosition = currentTimePosition {
                    Rectangle()
                        .fill(AppTheme.Colors.accent)
                        .frame(width: 2, height: chartHeight)
                        .offset(x: currentPosition * width - 1)
                }
                
                // Sunrise marker
                Circle()
                    .fill(AppTheme.Colors.warning)
                    .frame(width: 8, height: 8)
                    .offset(x: sunrisePosition - 4, y: chartHeight / 2 - 4)
                
                // Sunset marker
                Circle()
                    .fill(AppTheme.Colors.error)
                    .frame(width: 8, height: 8)
                    .offset(x: sunsetPosition - 4, y: chartHeight / 2 - 4)
            }
        }
        .frame(height: chartHeight)
    }
    
    // MARK: - Computed Properties
    
    /// Calculate sunrise position as fraction of day (0.0 to 1.0)
    private var sunriseRelativePosition: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: daylightInfo.sunrise)
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        return (hours + minutes / 60.0) / 24.0
    }
    
    /// Calculate sunset position as fraction of day (0.0 to 1.0)
    private var sunsetRelativePosition: Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: daylightInfo.sunset)
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        return (hours + minutes / 60.0) / 24.0
    }
    
    /// Calculate current time position as fraction of day (0.0 to 1.0)
    private var currentTimePosition: Double? {
        let calendar = Calendar.current
        let now = Date()
        
        // Only show current time indicator if it's the same day
        guard calendar.isDate(now, inSameDayAs: daylightInfo.sunrise) else {
            return nil
        }
        
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        return (hours + minutes / 60.0) / 24.0
    }
    
    // MARK: - Helper Methods
    
    /// Formats time for display
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Formats duration in hours and minutes
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Preview Provider

struct DaylightChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleDaylight = DaylightInfo(
            sunrise: Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date(),
            sunset: Calendar.current.date(from: DateComponents(hour: 19, minute: 45)) ?? Date(),
            daylightDuration: 13.25 * 3600, // 13 hours 15 minutes
            solarNoon: Calendar.current.date(from: DateComponents(hour: 13, minute: 7)) ?? Date(),
            twilightBegin: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
            twilightEnd: Calendar.current.date(from: DateComponents(hour: 20, minute: 15)) ?? Date()
        )
        
        Group {
            DaylightChart(daylightInfo: sampleDaylight)
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.light)
            
            DaylightChart(daylightInfo: sampleDaylight)
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}