//
//  WeatherDemonstration.swift
//  MaterialsAndPractices
//
//  Demonstration of weather functionality integration for agricultural grows.
//  Shows how the NOAA weather data flows through the app components.
//
//  Created by AI Assistant.
//

import Foundation
import CoreLocation

/// Demonstration of weather functionality
class WeatherDemonstration {
    
    /// Demonstrates the complete weather data flow
    static func demonstrateWeatherFlow() {
        print("🌾 Materials & Practices - Weather Integration Demo")
        print("=" * 50)
        
        // 1. Location Setup
        print("\n📍 Step 1: Location Services")
        let sampleLocation = CLLocation(latitude: 44.0582, longitude: -91.3957) // La Crosse, WI
        print("Sample Farm Location: \(sampleLocation.coordinate.latitude), \(sampleLocation.coordinate.longitude)")
        
        // 2. Weather Data Models
        print("\n🌤️ Step 2: Weather Data Structure")
        demonstrateWeatherModels()
        
        // 3. NOAA API Integration
        print("\n🔗 Step 3: NOAA API Integration")
        demonstrateNOAAIntegration()
        
        // 4. UI Components
        print("\n📱 Step 4: UI Components")
        demonstrateUIComponents()
        
        // 5. Agricultural Benefits
        print("\n🌱 Step 5: Agricultural Benefits")
        demonstrateAgriculturalBenefits()
        
        print("\n✅ Weather integration complete!")
    }
    
    private static func demonstrateWeatherModels() {
        // Current conditions
        let currentConditions = WeatherConditions(
            temperature: 72.5,
            humidity: 68.0,
            windSpeed: 8.5,
            windDirection: "SW",
            condition: "Partly Cloudy",
            icon: "https://api.weather.gov/icons/land/day/sct",
            timestamp: Date(),
            visibility: 10.0,
            dewPoint: 58.3,
            pressure: 30.15
        )
        
        print("Current Conditions:")
        print("  Temperature: \(currentConditions.temperature)°F")
        print("  Wind: \(currentConditions.windSpeed) mph \(currentConditions.windDirection)")
        print("  Condition: \(currentConditions.condition)")
        
        // Hourly forecast
        let hourlyForecast = [
            HourlyForecast(time: Date(), temperature: 72.5, condition: "Partly Cloudy", icon: "", precipitationProbability: 10, windSpeed: 8.5),
            HourlyForecast(time: Date().addingTimeInterval(3600), temperature: 74.0, condition: "Sunny", icon: "", precipitationProbability: 5, windSpeed: 9.0),
            HourlyForecast(time: Date().addingTimeInterval(7200), temperature: 75.5, condition: "Sunny", icon: "", precipitationProbability: 0, windSpeed: 10.0),
            HourlyForecast(time: Date().addingTimeInterval(10800), temperature: 76.0, condition: "Partly Cloudy", icon: "", precipitationProbability: 15, windSpeed: 12.0)
        ]
        
        print("\n4-Hour Forecast:")
        for (index, forecast) in hourlyForecast.enumerated() {
            print("  Hour \(index + 1): \(forecast.temperature)°F, \(forecast.condition), \(forecast.precipitationProbability)% chance rain")
        }
        
        // Daylight information
        let daylight = DaylightInfo(
            sunrise: Calendar.current.date(from: DateComponents(hour: 6, minute: 45)) ?? Date(),
            sunset: Calendar.current.date(from: DateComponents(hour: 19, minute: 30)) ?? Date(),
            daylightDuration: 12.75 * 3600, // 12 hours 45 minutes
            solarNoon: Calendar.current.date(from: DateComponents(hour: 13, minute: 7)) ?? Date(),
            twilightBegin: Calendar.current.date(from: DateComponents(hour: 6, minute: 15)) ?? Date(),
            twilightEnd: Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        )
        
        print("\nDaylight Information:")
        print("  Sunrise: \(formatTime(daylight.sunrise))")
        print("  Sunset: \(formatTime(daylight.sunset))")
        print("  Daylight Duration: \(formatDuration(daylight.daylightDuration))")
    }
    
    private static func demonstrateNOAAIntegration() {
        print("NOAA Weather API Integration:")
        print("  ✓ Grid Point Lookup: /points/{lat},{lon}")
        print("  ✓ Current Conditions: /gridpoints/{office}/{grid}/forecast")
        print("  ✓ Hourly Forecast: /gridpoints/{office}/{grid}/forecast/hourly")
        print("  ✓ Error Handling: Network, parsing, and API errors")
        print("  ✓ User Agent: 'MaterialsAndPractices/1.0' (required by NOAA)")
    }
    
    private static func demonstrateUIComponents() {
        print("SwiftUI Components:")
        print("  📊 WeatherView: Main weather display component")
        print("    - Current conditions with temperature and wind")
        print("    - Weather icons from NOAA")
        print("    - Loading and error states")
        print("  📈 DaylightChart: Visual daylight hours representation")
        print("    - Sunrise/sunset times")
        print("    - Daylight duration bar chart")
        print("    - Current time indicator")
        print("  📱 Integration: Added to top of CurrentGrowsView")
        print("    - Section header: 'Current Conditions'")
        print("    - Clean list integration")
        print("    - Responsive design for all screen sizes")
    }
    
    private static func demonstrateAgriculturalBenefits() {
        print("Agricultural Planning Benefits:")
        print("  🌡️ Temperature Monitoring:")
        print("    - Frost warnings for sensitive crops")
        print("    - Optimal planting temperature conditions")
        print("    - Heat stress monitoring")
        print("  💨 Wind Information:")
        print("    - Spray application timing")
        print("    - Wind damage risk assessment")
        print("    - Pollination conditions")
        print("  ☀️ Daylight Hours:")
        print("    - Photoperiod sensitive crop planning")
        print("    - Work schedule optimization")
        print("    - Solar energy estimation")
        print("  🌧️ Precipitation Forecast:")
        print("    - Irrigation scheduling")
        print("    - Field work timing")
        print("    - Disease pressure assessment")
    }
    
    // Helper methods
    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// Extension for string repetition
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}