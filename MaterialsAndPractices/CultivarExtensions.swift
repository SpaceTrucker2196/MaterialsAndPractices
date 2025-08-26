//
//  CultivarExtensions.swift
//  MaterialsAndPractices
//
//  Provides enhanced functionality for Cultivar entities including
//  growing days parsing and harvest estimation calculations.
//  Supports farm management system with comprehensive growing data.
//
//  Created by GitHub Copilot on 12/18/24.
//

import Foundation
import CoreData

// MARK: - Growing Days Parsing

extension Cultivar {
    /// Parses the growing days string to extract early and late values
    /// Supports empty strings, single values, or early-late ranges separated by dash
    /// Falls back to (0, 0) if parsing fails
    /// - Returns: Tuple containing (early, late) growing days
    func parseGrowingDays() -> (early: Int, late: Int) {
        guard let growingDaysString = self.growingDays, 
              !growingDaysString.isEmpty else {
            return (early: 0, late: 0)
        }
        
        // Clean the string to only contain numbers and dashes
        let cleaned = growingDaysString.replacingOccurrences(of: "[^0-9-]", with: "", options: .regularExpression)
        
        // Split by dash to handle ranges
        let parts = cleaned.components(separatedBy: "-").filter { !$0.isEmpty }
        
        switch parts.count {
        case 0:
            // Empty after cleaning
            return (early: 0, late: 0)
        case 1:
            // Single value - use for both early and late
            let value = Int(parts[0]) ?? 0
            return (early: value, late: value)
        case 2:
            // Range - early and late values
            let early = Int(parts[0]) ?? 0
            let late = Int(parts[1]) ?? 0
            return (early: early, late: late)
        default:
            // Multiple dashes - take first and last
            let early = Int(parts.first ?? "0") ?? 0
            let late = Int(parts.last ?? "0") ?? 0
            return (early: early, late: late)
        }
    }
    
    /// Computed property for early growing days
    var earlyGrowingDays: Int {
        return parseGrowingDays().early
    }
    
    /// Computed property for late growing days
    var lateGrowingDays: Int {
        return parseGrowingDays().late
    }
}

// MARK: - Harvest Estimation

/// Enumeration for harvest timing estimation
enum HarvestTiming: String, CaseIterable {
    case earlyJanuary = "early January"
    case midJanuary = "mid January"
    case lateJanuary = "late January"
    case earlyFebruary = "early February"
    case midFebruary = "mid February"
    case lateFebruary = "late February"
    case earlyMarch = "early March"
    case midMarch = "mid March"
    case lateMarch = "late March"
    case earlyApril = "early April"
    case midApril = "mid April"
    case lateApril = "late April"
    case earlyMay = "early May"
    case midMay = "mid May"
    case lateMay = "late May"
    case earlyJune = "early June"
    case midJune = "mid June"
    case lateJune = "late June"
    case earlyJuly = "early July"
    case midJuly = "mid July"
    case lateJuly = "late July"
    case earlyAugust = "early August"
    case midAugust = "mid August"
    case lateAugust = "late August"
    case earlySeptember = "early September"
    case midSeptember = "mid September"
    case lateSeptember = "late September"
    case earlyOctober = "early October"
    case midOctober = "mid October"
    case lateOctober = "late October"
    case earlyNovember = "early November"
    case midNovember = "mid November"
    case lateNovember = "late November"
    case earlyDecember = "early December"
    case midDecember = "mid December"
    case lateDecember = "late December"
    case unknown = "unknown timing"
    
    /// Creates harvest timing from a date
    /// - Parameter date: The harvest date
    /// - Returns: Corresponding harvest timing
    static func from(date: Date) -> HarvestTiming {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let timing: String
        if day <= 10 {
            timing = "early"
        } else if day <= 20 {
            timing = "mid"
        } else {
            timing = "late"
        }
        
        let monthName: String
        switch month {
        case 1: monthName = "January"
        case 2: monthName = "February"
        case 3: monthName = "March"
        case 4: monthName = "April"
        case 5: monthName = "May"
        case 6: monthName = "June"
        case 7: monthName = "July"
        case 8: monthName = "August"
        case 9: monthName = "September"
        case 10: monthName = "October"
        case 11: monthName = "November"
        case 12: monthName = "December"
        default: return .unknown
        }
        
        let rawValue = "\(timing) \(monthName)"
        return HarvestTiming(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Harvest Calculator

/// Reusable harvest calculator class for generating harvest estimates and calendar data
class HarvestCalculator {
    
    /// Calculates harvest estimates for a given cultivar and plant date
    /// - Parameters:
    ///   - cultivar: The cultivar being grown
    ///   - plantDate: The date the cultivar was planted
    ///   - usdaZone: The USDA hardiness zone (optional)
    /// - Returns: Harvest estimation data
    static func calculateHarvestEstimate(
        cultivar: Cultivar, 
        plantDate: Date, 
        usdaZone: String? = nil
    ) -> HarvestEstimate {
        let growingDays = cultivar.parseGrowingDays()
        let calendar = Calendar.current
        
        // Calculate early and late harvest dates
        let earlyHarvestDate = calendar.date(byAdding: .day, value: growingDays.early, to: plantDate) ?? plantDate
        let lateHarvestDate = calendar.date(byAdding: .day, value: growingDays.late, to: plantDate) ?? plantDate
        
        // Generate harvest timing strings
        let earlyTiming = HarvestTiming.from(date: earlyHarvestDate)
        let lateTiming = HarvestTiming.from(date: lateHarvestDate)
        
        return HarvestEstimate(
            earlyHarvestDate: earlyHarvestDate,
            lateHarvestDate: lateHarvestDate,
            earlyTiming: earlyTiming,
            lateTiming: lateTiming,
            estimatedRange: generateHarvestRangeString(early: earlyTiming, late: lateTiming)
        )
    }
    
    /// Generates a harvest range string from early and late timings
    private static func generateHarvestRangeString(early: HarvestTiming, late: HarvestTiming) -> String {
        if early == late {
            return early.rawValue
        } else {
            return "\(early.rawValue) to \(late.rawValue)"
        }
    }
    
    /// Calculates days until harvest from current date
    /// - Parameters:
    ///   - cultivar: The cultivar being grown
    ///   - plantDate: The date the cultivar was planted
    ///   - currentDate: The current date (defaults to now)
    /// - Returns: Number of days until harvest (using early estimate)
    static func daysUntilHarvest(
        cultivar: Cultivar, 
        plantDate: Date, 
        currentDate: Date = Date()
    ) -> Int {
        let growingDays = cultivar.parseGrowingDays()
        let calendar = Calendar.current
        
        let harvestDate = calendar.date(byAdding: .day, value: growingDays.early, to: plantDate) ?? plantDate
        let daysToHarvest = calendar.dateComponents([.day], from: currentDate, to: harvestDate).day ?? 0
        
        return max(0, daysToHarvest)
    }
}

// MARK: - Supporting Structures

/// Structure containing harvest estimation data
struct HarvestEstimate {
    let earlyHarvestDate: Date
    let lateHarvestDate: Date
    let earlyTiming: HarvestTiming
    let lateTiming: HarvestTiming
    let estimatedRange: String
}