//
//  TimeClockDonutChart.swift
//  MaterialsAndPractices
//
//  Donut chart for visualizing worker time clock data with overtime indicators.
//  Shows 24-hour day divided into 15-minute segments with color coding for different time zones.
//
//  Created by AI Assistant following Clean Code principles.
//

import SwiftUI
import Foundation

// MARK: - Time Clock Donut Chart

/// Donut chart displaying worker hours as percentage of 24-hour day
/// with color coding for regular time, warning zones, and overtime
struct TimeClockDonutChart: View {
    let hoursWorked: Double
    let clockInTime: Date?
    let isActive: Bool
    
    // Chart appearance constants - optimized for button height matching
    private let chartSize: CGFloat = 100
    private let strokeWidth: CGFloat = 10
    private let totalHours: Double = 24.0
    private let regularHours: Double = 8.0
    private let warningHours: Double = 9.0
    private let overtimeHours: Double = 10.0
    
    var body: some View {
        ZStack {
            // Background circle (full 24 hours)
            Circle()
                .stroke(AppTheme.Colors.backgroundSecondary, lineWidth: strokeWidth)
                .frame(width: chartSize, height: chartSize)
            
            // Time zone indicators (static background)
            timeZoneIndicators
            
            // Active hours indicator
            if hoursWorked > 0 {
                hoursWorkedIndicator
            }
            
            // Center information
            centerInformation
        }
        .frame(width: chartSize + strokeWidth, height: chartSize + strokeWidth)
    }
    
    // MARK: - Time Zone Background Indicators
    
    private var timeZoneIndicators: some View {
        ZStack {
            // Regular hours (0-8 hours) - Green
            timeZoneArc(
                startAngle: -90,
                endAngle: angleForHours(regularHours) - 90,
                color: isActive ? AppTheme.Colors.success : AppTheme.Colors.success.opacity(0.3)
            )
            
            // Warning zone (8-9 hours) - Yellow
            timeZoneArc(
                startAngle: angleForHours(regularHours) - 90,
                endAngle: angleForHours(warningHours) - 90,
                color: isActive ? AppTheme.Colors.warning : AppTheme.Colors.warning.opacity(0.3)
            )
            
            // Overtime zone (9-10 hours) - Orange
            timeZoneArc(
                startAngle: angleForHours(warningHours) - 90,
                endAngle: angleForHours(overtimeHours) - 90,
                color: isActive ? Color.orange : Color.orange.opacity(0.3)
            )
            
            // Excessive overtime (10+ hours) - Red
            timeZoneArc(
                startAngle: angleForHours(overtimeHours) - 90,
                endAngle: 270, // Full circle
                color: isActive ? AppTheme.Colors.error : AppTheme.Colors.error.opacity(0.3)
            )
        }
    }
    
    // MARK: - Active Hours Indicator
    
    private var hoursWorkedIndicator: some View {
        Circle()
            .trim(from: 0, to: CGFloat(hoursWorked / totalHours))
            .stroke(
                colorForHours(hoursWorked),
                style: StrokeStyle(lineWidth: strokeWidth * 1.2, lineCap: .round)
            )
            .frame(width: chartSize, height: chartSize)
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 0.8), value: hoursWorked)
    }
    
    // MARK: - Center Information Display
    
    private var centerInformation: some View {
        VStack(spacing: 0) {
            // Hours worked
            Text("\(hoursWorked, specifier: "%.1f")")
                .font(AppTheme.Typography.dataMedium)
                .foregroundColor(colorForHours(hoursWorked))
            
            Text("hrs")
                .font(AppTheme.Typography.dataMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeZoneArc(startAngle: Double, endAngle: Double, color: Color) -> some View {
        Circle()
            .trim(
                from: CGFloat(startAngle / 360.0),
                to: CGFloat(endAngle / 360.0)
            )
            .stroke(color, lineWidth: strokeWidth * 0.6)
            .frame(width: chartSize, height: chartSize)
    }
    
    private func angleForHours(_ hours: Double) -> Double {
        return (hours / totalHours) * 360.0
    }
    
    private func colorForHours(_ hours: Double) -> Color {
        switch hours {
        case 0..<regularHours:
            return AppTheme.Colors.success
        case regularHours..<warningHours:
            return AppTheme.Colors.warning
        case warningHours..<overtimeHours:
            return Color.orange
        default:
            return AppTheme.Colors.error
        }
    }
}

// MARK: - Time Clock Data Model

/// Data structure for time clock information
struct TimeClockData {
    let hoursWorked: Double
    let clockInTime: Date?
    let clockOutTime: Date?
    let isActive: Bool
    
    init(timeEntry: TimeClock?) {
        if let entry = timeEntry {
            self.clockInTime = entry.clockInTime
            self.clockOutTime = entry.clockOutTime
            self.isActive = entry.isActive
            
            // Calculate hours worked
            if let clockIn = entry.clockInTime {
                if let clockOut = entry.clockOutTime {
                    // Completed shift
                    self.hoursWorked = clockOut.timeIntervalSince(clockIn) / 3600.0
                } else if entry.isActive {
                    // Currently clocked in
                    self.hoursWorked = Date().timeIntervalSince(clockIn) / 3600.0
                } else {
                    self.hoursWorked = 0
                }
            } else {
                self.hoursWorked = 0
            }
        } else {
            self.hoursWorked = 0
            self.clockInTime = nil
            self.clockOutTime = nil
            self.isActive = false
        }
    }
}

// MARK: - Preview

struct TimeClockDonutChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Regular hours
            TimeClockDonutChart(hoursWorked: 6.5, clockInTime: Date(), isActive: true)
            
            // Warning zone
            TimeClockDonutChart(hoursWorked: 8.5, clockInTime: Date(), isActive: true)
            
            // Overtime
            TimeClockDonutChart(hoursWorked: 11.2, clockInTime: Date(), isActive: false)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
