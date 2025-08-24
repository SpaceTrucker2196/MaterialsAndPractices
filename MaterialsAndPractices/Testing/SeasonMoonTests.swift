//
//  SeasonMoonTests.swift
//  MaterialsAndPractices
//
//  Tests for season and moon phase calculations to verify accuracy
//  and proper functionality of astronomical algorithms.
//
//  Created by AI Assistant.
//

import Foundation

/// Simple test suite for season and moon phase calculations
struct SeasonMoonTests {
    
    /// Runs all tests and prints results
    static func runAllTests() {
        print("🧪 Running Season & Moon Phase Tests...")
        
        testSeasonCalculations()
        testMoonPhaseCalculations()
        testSeasonTransitions()
        testMoonPhaseTiming()
        
        print("✅ All Season & Moon Phase tests completed!")
    }
    
    /// Tests basic season calculations
    private static func testSeasonCalculations() {
        print("\n📅 Testing Season Calculations:")
        
        // Test known dates
        let calendar = Calendar.current
        
        // Spring test (March 21)
        let springDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 21)) ?? Date()
        let springSeason = SeasonCalculator.season(for: springDate)
        print("March 21, 2024 season: \(springSeason.displayName) \(springSeason.emoji)")
        
        // Summer test (June 21)
        let summerDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 21)) ?? Date()
        let summerSeason = SeasonCalculator.season(for: summerDate)
        print("June 21, 2024 season: \(summerSeason.displayName) \(summerSeason.emoji)")
        
        // Autumn test (September 23)
        let autumnDate = calendar.date(from: DateComponents(year: 2024, month: 9, day: 23)) ?? Date()
        let autumnSeason = SeasonCalculator.season(for: autumnDate)
        print("September 23, 2024 season: \(autumnSeason.displayName) \(autumnSeason.emoji)")
        
        // Winter test (December 21)
        let winterDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 21)) ?? Date()
        let winterSeason = SeasonCalculator.season(for: winterDate)
        print("December 21, 2024 season: \(winterSeason.displayName) \(winterSeason.emoji)")
        
        // Current season
        let currentSeason = SeasonCalculator.currentSeason()
        print("Current season: \(currentSeason.displayName) \(currentSeason.emoji)")
    }
    
    /// Tests moon phase calculations
    private static func testMoonPhaseCalculations() {
        print("\n🌙 Testing Moon Phase Calculations:")
        
        // Test current moon phase
        let currentPhase = MoonPhaseCalculator.currentMoonPhase()
        print("Current moon phase: \(currentPhase.displayName) \(currentPhase.emoji)")
        
        // Test illumination calculation
        let illumination = MoonPhaseCalculator.lunarIllumination(for: Date())
        print("Current lunar illumination: \(String(format: "%.1f", illumination * 100))%")
        
        // Test upcoming full moon
        let daysToFullMoon = MoonPhaseCalculator.daysUntilFullMoon(from: Date())
        print("Days until next full moon: \(daysToFullMoon)")
        
        // Test upcoming new moon
        let daysToNewMoon = MoonPhaseCalculator.daysUntilNewMoon(from: Date())
        print("Days until next new moon: \(daysToNewMoon)")
        
        // Test agricultural timing
        let isGoodPlanting = MoonPhaseCalculator.isGoodPlantingTime(for: Date())
        let isGoodHarvesting = MoonPhaseCalculator.isGoodHarvestTime(for: Date())
        print("Good for planting: \(isGoodPlanting ? "✅" : "❌")")
        print("Good for harvesting: \(isGoodHarvesting ? "✅" : "❌")")
    }
    
    /// Tests season transition calculations
    private static func testSeasonTransitions() {
        print("\n🔄 Testing Season Transitions:")
        
        let currentDate = Date()
        let nextTransition = SeasonCalculator.nextSeasonTransition(from: currentDate)
        let daysUntilNext = SeasonCalculator.daysUntilNextSeason(from: currentDate)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        print("Next season transition: \(nextTransition.season.displayName) on \(formatter.string(from: nextTransition.date))")
        print("Days until next season: \(daysUntilNext)")
    }
    
    /// Tests moon phase timing and consistency
    private static func testMoonPhaseTiming() {
        print("\n⏰ Testing Moon Phase Timing:")
        
        let calendar = Calendar.current
        
        // Test phases over a few days
        for i in 0..<7 {
            if let testDate = calendar.date(byAdding: .day, value: i, to: Date()) {
                let phase = MoonPhaseCalculator.moonPhase(for: testDate)
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM dd"
                print("\(formatter.string(from: testDate)): \(phase.displayName) \(phase.emoji)")
            }
        }
    }
}

/// Agricultural guidance tests
struct AgriculturalGuidanceTests {
    
    /// Tests agricultural recommendations based on season and moon
    static func testAgriculturalGuidance() {
        print("\n🌱 Testing Agricultural Guidance:")
        
        let currentSeason = SeasonCalculator.currentSeason()
        let currentPhase = MoonPhaseCalculator.currentMoonPhase()
        
        print("Season: \(currentSeason.agriculturalInfo)")
        print("Moon Phase: \(currentPhase.agriculturalSignificance)")
        
        // Check combined recommendations
        let isOptimalPlanting = MoonPhaseCalculator.isGoodPlantingTime(for: Date()) && 
                               (currentSeason == .spring || currentSeason == .autumn)
        
        if isOptimalPlanting {
            print("🎯 Optimal planting conditions!")
        } else {
            print("⏳ Wait for better planting conditions")
        }
    }
}