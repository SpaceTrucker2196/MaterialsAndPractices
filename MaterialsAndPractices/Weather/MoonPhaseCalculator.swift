//
//  MoonPhaseCalculator.swift
//  MaterialsAndPractices
//
//  Calculates lunar phases using astronomical algorithms for agricultural planning.
//  Provides moon phase information for optimal planting and harvesting timing.
//
//  Created by AI Assistant.
//

import Foundation

/// Calculator for lunar phases using astronomical algorithms
/// Provides accurate moon phase information for agricultural planning
struct MoonPhaseCalculator {
    
    // MARK: - Moon Phase Definition
    
    /// Represents the eight primary lunar phases
    enum MoonPhase: String, CaseIterable {
        case newMoon = "New Moon"
        case waxingCrescent = "Waxing Crescent"
        case firstQuarter = "First Quarter"
        case waxingGibbous = "Waxing Gibbous"
        case fullMoon = "Full Moon"
        case waningGibbous = "Waning Gibbous"
        case lastQuarter = "Last Quarter"
        case waningCrescent = "Waning Crescent"
        
        /// Display name for the moon phase
        var displayName: String {
            return self.rawValue
        }
        
        /// Emoji representation of the moon phase
        var emoji: String {
            switch self {
            case .newMoon: return "🌑"
            case .waxingCrescent: return "🌒"
            case .firstQuarter: return "🌓"
            case .waxingGibbous: return "🌔"
            case .fullMoon: return "🌕"
            case .waningGibbous: return "🌖"
            case .lastQuarter: return "🌗"
            case .waningCrescent: return "🌘"
            }
        }
        
        /// Symbol representation for UI
        var symbol: String {
            switch self {
            case .newMoon: return "moon.circle"
            case .waxingCrescent: return "moon.zzz"
            case .firstQuarter: return "moon.haze"
            case .waxingGibbous: return "moon.dust"
            case .fullMoon: return "moon.circle.fill"
            case .waningGibbous: return "moon.stars"
            case .lastQuarter: return "moon.zzz.fill"
            case .waningCrescent: return "moon.haze.fill"
            }
        }
        
        /// Agricultural significance of the moon phase
        var agriculturalSignificance: String {
            switch self {
            case .newMoon:
                return "Ideal for planting root crops and bulbs"
            case .waxingCrescent:
                return "Good for planting leafy annuals"
            case .firstQuarter:
                return "Best time for planting fruiting annuals"
            case .waxingGibbous:
                return "Continue planting root crops"
            case .fullMoon:
                return "Peak time for harvesting and transplanting"
            case .waningGibbous:
                return "Good for planting biennials and perennials"
            case .lastQuarter:
                return "Time for pruning and pest control"
            case .waningCrescent:
                return "Rest period, avoid planting"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Calculates the current moon phase
    /// - Returns: Current lunar phase
    static func currentMoonPhase() -> MoonPhase {
        return moonPhase(for: Date())
    }
    
    /// Calculates the moon phase for a specific date
    /// - Parameter date: Date to calculate moon phase for
    /// - Returns: Lunar phase for the given date
    static func moonPhase(for date: Date) -> MoonPhase {
        let illumination = lunarIllumination(for: date)
        return phaseFromIllumination(illumination)
    }
    
    /// Calculates the lunar illumination percentage
    /// - Parameter date: Date to calculate illumination for
    /// - Returns: Illumination percentage (0.0 to 1.0)
    static func lunarIllumination(for date: Date) -> Double {
        let julianDate = date.julianDate
        let daysFromNewMoon = daysSinceNewMoon(julianDate: julianDate)
        let lunarCycle = 29.530588853 // Average lunar cycle length in days
        
        // Calculate phase angle (0 to 2π)
        let phaseAngle = (daysFromNewMoon / lunarCycle) * 2 * Double.pi
        
        // Calculate illumination using phase angle
        let illumination = (1 - cos(phaseAngle)) / 2
        
        return max(0, min(1, illumination))
    }
    
    /// Gets the number of days until the next full moon
    /// - Parameter date: Reference date
    /// - Returns: Days until next full moon
    static func daysUntilFullMoon(from date: Date) -> Int {
        let currentPhase = moonPhase(for: date)
        let calendar = Calendar.current
        
        // Estimate based on current phase
        var daysToAdd = 0
        switch currentPhase {
        case .newMoon: daysToAdd = 14
        case .waxingCrescent: daysToAdd = 10
        case .firstQuarter: daysToAdd = 7
        case .waxingGibbous: daysToAdd = 3
        case .fullMoon: daysToAdd = 0
        case .waningGibbous: daysToAdd = 25
        case .lastQuarter: daysToAdd = 22
        case .waningCrescent: daysToAdd = 18
        }
        
        // Find the exact date by checking subsequent days
        for dayOffset in daysToAdd..<(daysToAdd + 7) {
            let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: date) ?? date
            if moonPhase(for: checkDate) == .fullMoon {
                return dayOffset
            }
        }
        
        return daysToAdd
    }
    
    /// Gets the number of days until the next new moon
    /// - Parameter date: Reference date
    /// - Returns: Days until next new moon
    static func daysUntilNewMoon(from date: Date) -> Int {
        let currentPhase = moonPhase(for: date)
        let calendar = Calendar.current
        
        // Estimate based on current phase
        var daysToAdd = 0
        switch currentPhase {
        case .newMoon: daysToAdd = 0
        case .waxingCrescent: daysToAdd = 25
        case .firstQuarter: daysToAdd = 22
        case .waxingGibbous: daysToAdd = 18
        case .fullMoon: daysToAdd = 14
        case .waningGibbous: daysToAdd = 10
        case .lastQuarter: daysToAdd = 7
        case .waningCrescent: daysToAdd = 3
        }
        
        // Find the exact date by checking subsequent days
        for dayOffset in daysToAdd..<(daysToAdd + 7) {
            let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: date) ?? date
            if moonPhase(for: checkDate) == .newMoon {
                return dayOffset
            }
        }
        
        return daysToAdd
    }
    
    /// Checks if the current date is good for planting based on moon phase
    /// - Parameter date: Date to check
    /// - Returns: True if it's a good planting time according to lunar gardening
    static func isGoodPlantingTime(for date: Date) -> Bool {
        let phase = moonPhase(for: date)
        switch phase {
        case .newMoon, .waxingCrescent, .firstQuarter:
            return true
        default:
            return false
        }
    }
    
    /// Checks if the current date is good for harvesting based on moon phase
    /// - Parameter date: Date to check
    /// - Returns: True if it's a good harvesting time according to lunar gardening
    static func isGoodHarvestTime(for date: Date) -> Bool {
        let phase = moonPhase(for: date)
        return phase == .fullMoon || phase == .waningGibbous
    }
    
    // MARK: - Private Methods
    
    /// Calculates days since the known new moon reference point
    /// Uses a known new moon date as reference for calculations
    /// - Parameter julianDate: Julian date to calculate from
    /// - Returns: Days since new moon in current lunar cycle
    private static func daysSinceNewMoon(julianDate: Double) -> Double {
        // Reference new moon: January 6, 2000, 18:14 UTC (JD 2451550.26)
        let referenceNewMoon: Double = 2451550.26
        let lunarCycle: Double = 29.530588853
        
        let daysSinceReference = julianDate - referenceNewMoon
        let cyclesSinceReference = daysSinceReference / lunarCycle
        let daysInCurrentCycle = (cyclesSinceReference - floor(cyclesSinceReference)) * lunarCycle
        
        return daysInCurrentCycle
    }
    
    /// Determines moon phase from illumination percentage
    /// - Parameter illumination: Illumination percentage (0.0 to 1.0)
    /// - Returns: Corresponding moon phase
    private static func phaseFromIllumination(_ illumination: Double) -> MoonPhase {
        // Additional logic needed to distinguish between waxing and waning
        // For simplification, we'll use illumination ranges
        
        if illumination < 0.02 {
            return .newMoon
        } else if illumination < 0.25 {
            return .waxingCrescent
        } else if illumination < 0.48 {
            return .firstQuarter
        } else if illumination < 0.75 {
            return .waxingGibbous
        } else if illumination < 0.98 {
            return .fullMoon
        } else {
            return .fullMoon
        }
    }
    
    /// More accurate phase calculation considering lunar cycle position
    /// - Parameter date: Date to calculate phase for
    /// - Returns: Accurate moon phase
    private static func accurateMoonPhase(for date: Date) -> MoonPhase {
        let julianDate = date.julianDate
        let daysFromNewMoon = daysSinceNewMoon(julianDate: julianDate)
        let lunarCycle = 29.530588853
        
        let phasePosition = daysFromNewMoon / lunarCycle
        
        if phasePosition < 0.0625 || phasePosition >= 0.9375 {
            return .newMoon
        } else if phasePosition < 0.1875 {
            return .waxingCrescent
        } else if phasePosition < 0.3125 {
            return .firstQuarter
        } else if phasePosition < 0.4375 {
            return .waxingGibbous
        } else if phasePosition < 0.5625 {
            return .fullMoon
        } else if phasePosition < 0.6875 {
            return .waningGibbous
        } else if phasePosition < 0.8125 {
            return .lastQuarter
        } else {
            return .waningCrescent
        }
    }
}

// MARK: - Date Extensions

extension Date {
    /// Calculates the Julian date for astronomical calculations
    var julianDate: Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        
        let jdn = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        let hourFraction = Double(hour) / 24.0
        let minuteFraction = Double(minute) / 1440.0
        let secondFraction = Double(second) / 86400.0
        
        return Double(jdn) + hourFraction + minuteFraction + secondFraction - 0.5
    }
}

// MARK: - Moon Phase Extensions

extension MoonPhaseCalculator.MoonPhase {
    /// Returns whether this phase is considered "increasing" (waxing)
    var isWaxing: Bool {
        switch self {
        case .waxingCrescent, .firstQuarter, .waxingGibbous:
            return true
        default:
            return false
        }
    }
    
    /// Returns whether this phase is considered "decreasing" (waning)
    var isWaning: Bool {
        switch self {
        case .waningGibbous, .lastQuarter, .waningCrescent:
            return true
        default:
            return false
        }
    }
    
    /// Returns the visibility percentage of the moon (approximate)
    var visibilityPercentage: Int {
        switch self {
        case .newMoon: return 0
        case .waxingCrescent: return 25
        case .firstQuarter: return 50
        case .waxingGibbous: return 75
        case .fullMoon: return 100
        case .waningGibbous: return 75
        case .lastQuarter: return 50
        case .waningCrescent: return 25
        }
    }
}