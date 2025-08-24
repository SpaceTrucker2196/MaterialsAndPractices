//
//  SeasonCalculator.swift
//  MaterialsAndPractices
//
//  Provides astronomical season calculation based on solstices and equinoxes.
//  Calculates seasons for Northern Hemisphere agricultural planning.
//
//  Created by AI Assistant.
//

import Foundation

/// Calculator for determining astronomical seasons based on current date
/// Uses solstice and equinox dates for accurate seasonal transitions
struct SeasonCalculator {
    
    // MARK: - Season Definition
    
    /// Represents the four astronomical seasons
    enum Season: String, CaseIterable {
        case spring = "Spring"
        case summer = "Summer"
        case autumn = "Autumn"
        case winter = "Winter"
        
        /// Display name for the season
        var displayName: String {
            return self.rawValue
        }
        
        /// Emoji representation of the season
        var emoji: String {
            switch self {
            case .spring: return "🌱"
            case .summer: return "☀️"
            case .autumn: return "🍂"
            case .winter: return "❄️"
            }
        }
        
        /// Color theme for the season
        var color: String {
            switch self {
            case .spring: return "#66BB6A" // Light green
            case .summer: return "#FFA726" // Orange
            case .autumn: return "#FF7043" // Red-orange
            case .winter: return "#42A5F5" // Light blue
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Calculates the current season based on the current date
    /// - Returns: Current astronomical season
    static func currentSeason() -> Season {
        return season(for: Date())
    }
    
    /// Calculates the season for a specific date
    /// - Parameter date: Date to calculate season for
    /// - Returns: Astronomical season for the given date
    static func season(for date: Date) -> Season {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Get approximate solstice and equinox days for the year
        let seasonalTransitions = getSeasonalTransitions(for: year)
        
        if dayOfYear >= seasonalTransitions.springEquinox && dayOfYear < seasonalTransitions.summerSolstice {
            return .spring
        } else if dayOfYear >= seasonalTransitions.summerSolstice && dayOfYear < seasonalTransitions.autumnEquinox {
            return .summer
        } else if dayOfYear >= seasonalTransitions.autumnEquinox && dayOfYear < seasonalTransitions.winterSolstice {
            return .autumn
        } else {
            return .winter
        }
    }
    
    /// Gets the next seasonal transition date
    /// - Parameter date: Reference date
    /// - Returns: Date of next seasonal transition and the season it transitions to
    static func nextSeasonTransition(from date: Date) -> (date: Date, season: Season) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        let transitions = getSeasonalTransitions(for: year)
        
        // Check transitions in chronological order
        if dayOfYear < transitions.springEquinox {
            let transitionDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                .addingTimeInterval(TimeInterval((transitions.springEquinox - 1) * 24 * 60 * 60))
            return (transitionDate, .spring)
        } else if dayOfYear < transitions.summerSolstice {
            let transitionDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                .addingTimeInterval(TimeInterval((transitions.summerSolstice - 1) * 24 * 60 * 60))
            return (transitionDate, .summer)
        } else if dayOfYear < transitions.autumnEquinox {
            let transitionDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                .addingTimeInterval(TimeInterval((transitions.autumnEquinox - 1) * 24 * 60 * 60))
            return (transitionDate, .autumn)
        } else if dayOfYear < transitions.winterSolstice {
            let transitionDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                .addingTimeInterval(TimeInterval((transitions.winterSolstice - 1) * 24 * 60 * 60))
            return (transitionDate, .winter)
        } else {
            // Next transition is spring of following year
            let nextYear = year + 1
            let nextTransitions = getSeasonalTransitions(for: nextYear)
            let transitionDate = calendar.date(from: DateComponents(year: nextYear, month: 1, day: 1))!
                .addingTimeInterval(TimeInterval((nextTransitions.springEquinox - 1) * 24 * 60 * 60))
            return (transitionDate, .spring)
        }
    }
    
    /// Gets the number of days until the next season
    /// - Parameter date: Reference date
    /// - Returns: Number of days until next seasonal transition
    static func daysUntilNextSeason(from date: Date) -> Int {
        let nextTransition = nextSeasonTransition(from: date)
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: date, to: nextTransition.date).day ?? 0
        return max(0, days)
    }
    
    // MARK: - Private Methods
    
    /// Calculates approximate seasonal transition days for a given year
    /// Uses simplified astronomical calculations for transitions
    /// - Parameter year: Year to calculate transitions for
    /// - Returns: Day numbers for seasonal transitions
    private static func getSeasonalTransitions(for year: Int) -> (springEquinox: Int, summerSolstice: Int, autumnEquinox: Int, winterSolstice: Int) {
        // Approximate dates for Northern Hemisphere
        // These are simplified calculations; actual dates can vary by ±2 days
        
        // Spring Equinox: Around March 20-21 (day 79-80)
        let springEquinox = isLeapYear(year) ? 80 : 79
        
        // Summer Solstice: Around June 20-21 (day 171-172)
        let summerSolstice = isLeapYear(year) ? 172 : 171
        
        // Autumn Equinox: Around September 22-23 (day 265-266)
        let autumnEquinox = isLeapYear(year) ? 266 : 265
        
        // Winter Solstice: Around December 21-22 (day 355-356)
        let winterSolstice = isLeapYear(year) ? 356 : 355
        
        return (
            springEquinox: springEquinox,
            summerSolstice: summerSolstice,
            autumnEquinox: autumnEquinox,
            winterSolstice: winterSolstice
        )
    }
    
    /// Determines if a year is a leap year
    /// - Parameter year: Year to check
    /// - Returns: True if the year is a leap year
    private static func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
}

// MARK: - Season Extensions

extension SeasonCalculator.Season {
    /// Returns agricultural characteristics of the season
    var agriculturalInfo: String {
        switch self {
        case .spring:
            return "Planting season for cool weather crops"
        case .summer:
            return "Growing season for warm weather crops"
        case .autumn:
            return "Harvest season and fall planting"
        case .winter:
            return "Planning and preparation season"
        }
    }
    
    /// Average temperature range description for the season
    var temperatureDescription: String {
        switch self {
        case .spring:
            return "Mild, warming temperatures"
        case .summer:
            return "Warm to hot temperatures"
        case .autumn:
            return "Cooling temperatures"
        case .winter:
            return "Cold temperatures"
        }
    }
}