//
//  WeatherKitService.swift
//  MaterialsAndPractices
//
//  Enhanced service for fetching weather data from Apple's WeatherKit API
//  Provides current conditions and hourly forecast for agricultural planning
//  with comprehensive error handling and debugging capabilities.
//
//  Created by AI Assistant.
//

import Foundation
import Combine
import CoreLocation
import WeatherKit
import os.log

/// WeatherKit-based weather service with improved accuracy and reliability
@available(iOS 16.0, *)
class WeatherKitService: ObservableObject {
    // MARK: - Properties
    
    private let weatherService = WeatherService.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "MaterialsAndPractices", category: "WeatherKitService")
    
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var error: WeatherError?
    
    // MARK: - Configuration Management
    
    /// Gets configuration values from secure configuration manager
    private var timeout: TimeInterval {
        return SecureConfiguration.shared.networkTimeoutSeconds
    }
    
    private var maxRetries: Int {
        return SecureConfiguration.shared.maxRetryAttempts
    }
    
    // MARK: - Public Methods
    
    /// Initializes the WeatherKit service
    init() {
        logger.info("WeatherKit service initialized")
    }
    
    /// Fetches weather data for a given location using WeatherKit
    /// - Parameter location: CLLocation to fetch weather for
    func fetchWeather(for location: CLLocation) {
        guard !isLoading else {
            logger.warning("Weather fetch already in progress, ignoring duplicate request")
            return
        }
        
        logger.info("Starting weather fetch for location: \\(location.coordinate.latitude), \\(location.coordinate.longitude)")
        
        isLoading = true
        error = nil
        
        Task {
            await fetchWeatherData(for: location)
        }
    }
    
    /// Clears current weather data and error state
    func clearWeatherData() {
        weatherData = nil
        error = nil
        isLoading = false
        logger.debug("Weather data cleared")
    }
    
    // MARK: - Private Methods
    
    /// Fetches weather data asynchronously using WeatherKit
    /// - Parameter location: Location to fetch weather for
    @MainActor
    private func fetchWeatherData(for location: CLLocation) async {
        do {
            logger.debug("Requesting weather data from WeatherKit")
            
            // Request current weather and hourly forecast
            let weather = try await weatherService.weather(
                for: location,
                including: .current, .hourly, .daily
            )
            
            logger.info("Successfully received weather data from WeatherKit")
            
            // Convert WeatherKit data to our app's format
            let convertedData = convertWeatherKitData(
                current: weather.0,
                hourly: weather.1,
                daily: weather.2,
                location: location
            )
            
            self.weatherData = convertedData
            self.isLoading = false
            
            logger.debug("Weather data conversion completed successfully")
            
        } catch {
            logger.error("WeatherKit request failed: \\(error.localizedDescription)")
            await handleWeatherKitError(error)
        }
    }
    
    /// Converts WeatherKit data to our app's WeatherData format
    /// - Parameters:
    ///   - current: Current weather from WeatherKit
    ///   - hourly: Hourly forecast from WeatherKit
    ///   - daily: Daily forecast from WeatherKit
    ///   - location: Location for the weather data
    /// - Returns: Converted WeatherData object
    private func convertWeatherKitData(
        current: CurrentWeather,
        hourly: Forecast<HourWeather>,
        daily: Forecast<DayWeather>,
        location: CLLocation
    ) -> WeatherData {
        
        logger.debug("Converting WeatherKit data to app format")
        
        // Convert current conditions
        let currentConditions = WeatherConditions(
            temperature: current.temperature.value,
            humidity: current.humidity,
            windSpeed: current.wind.speed.value,
            windDirection: windDirectionString(from: current.wind.direction),
            condition: current.condition.description,
            icon: symbolNameForCondition(current.condition),
            timestamp: current.date,
            visibility: current.visibility.value,
            dewPoint: current.dewPoint.value,
            pressure: current.pressure.value
        )
        
        // Convert hourly forecast (next 4 hours)
        let hourlyForecast = hourly.forecast.prefix(4).map { hourWeather in
            HourlyForecast(
                time: hourWeather.date,
                temperature: hourWeather.temperature.value,
                condition: hourWeather.condition.description,
                icon: symbolNameForCondition(hourWeather.condition),
                precipitationProbability: hourWeather.precipitationChance,
                windSpeed: hourWeather.wind.speed.value
            )
        }
        
        // Calculate daylight information from daily forecast
        let today = daily.forecast.first
        let daylightInfo = calculateDaylightInfo(from: today, location: location)
        
        // Get location name (simplified for now)
        let locationName = "\\(String(format: "%.2f", location.coordinate.latitude)), \\(String(format: "%.2f", location.coordinate.longitude))"
        
        return WeatherData(
            current: currentConditions,
            hourlyForecast: Array(hourlyForecast),
            daylight: daylightInfo,
            location: locationName,
            lastUpdated: Date()
        )
    }
    
    /// Converts wind direction to string representation
    /// - Parameter direction: Wind direction in Measurement<UnitAngle>
    /// - Returns: String representation of wind direction
    private func windDirectionString(from direction: Measurement<UnitAngle>?) -> String {
        guard let direction = direction else { return "N/A" }
        
        let degrees = direction.converted(to: .degrees).value
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    /// Converts WeatherKit condition to symbol name
    /// - Parameter condition: WeatherCondition from WeatherKit
    /// - Returns: SF Symbol name for the condition
    private func symbolNameForCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max"
        case .cloudy:
            return "cloud"
        case .mostlyCloudy:
            return "cloud.sun"
        case .partlyCloudy:
            return "cloud.sun"
        case .mostlyClear:
            return "sun.min"
        case .rain:
            return "cloud.rain"
        case .snow:
            return "cloud.snow"
        case .sleet:
            return "cloud.sleet"
        case .hail:
            return "cloud.hail"
        case .thunderstorms:
            return "cloud.bolt"
        case .heavyRain:
            return "cloud.heavyrain"
        case .heavySnow:
            return "cloud.snow"
        case .foggy:
            return "cloud.fog"
        case .haze:
            return "sun.haze"
        case .smoky:
            return "smoke"
        case .drizzle:
            return "cloud.drizzle"
        case .windy:
            return "wind"
        case .breezy:
            return "wind"
        default:
            return "questionmark"
        }
    }
    
    /// Calculates daylight information from daily weather data
    /// - Parameters:
    ///   - dayWeather: DayWeather from WeatherKit
    ///   - location: Location for calculations
    /// - Returns: DaylightInfo object
    private func calculateDaylightInfo(from dayWeather: DayWeather?, location: CLLocation) -> DaylightInfo {
        guard let dayWeather = dayWeather else {
            // Fallback daylight calculation
            return calculateFallbackDaylight(for: location)
        }
        
        let sunrise = dayWeather.sun.sunrise ?? calculateSunrise(for: location)
        let sunset = dayWeather.sun.sunset ?? calculateSunset(for: location)
        
        let daylightDuration = sunset.timeIntervalSince(sunrise)
        let solarNoon = Date(timeInterval: daylightDuration / 2, since: sunrise)
        
        // Calculate twilight times (approximate)
        let twilightBegin = Date(timeInterval: -30 * 60, since: sunrise) // 30 minutes before sunrise
        let twilightEnd = Date(timeInterval: 30 * 60, since: sunset) // 30 minutes after sunset
        
        return DaylightInfo(
            sunrise: sunrise,
            sunset: sunset,
            daylightDuration: daylightDuration,
            solarNoon: solarNoon,
            twilightBegin: twilightBegin,
            twilightEnd: twilightEnd
        )
    }
    
    /// Calculates fallback daylight information when WeatherKit data is unavailable
    /// - Parameter location: Location for calculations
    /// - Returns: Fallback DaylightInfo
    private func calculateFallbackDaylight(for location: CLLocation) -> DaylightInfo {
        // Simplified sunrise/sunset calculation
        let sunrise = calculateSunrise(for: location)
        let sunset = calculateSunset(for: location)
        
        let daylightDuration = sunset.timeIntervalSince(sunrise)
        let solarNoon = Date(timeInterval: daylightDuration / 2, since: sunrise)
        
        let twilightBegin = Date(timeInterval: -30 * 60, since: sunrise)
        let twilightEnd = Date(timeInterval: 30 * 60, since: sunset)
        
        return DaylightInfo(
            sunrise: sunrise,
            sunset: sunset,
            daylightDuration: daylightDuration,
            solarNoon: solarNoon,
            twilightBegin: twilightBegin,
            twilightEnd: twilightEnd
        )
    }
    
    /// Simplified sunrise calculation
    /// - Parameter location: Location for calculation
    /// - Returns: Approximate sunrise time
    private func calculateSunrise(for location: CLLocation) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Very simplified calculation - in production, use proper astronomical algorithms
        let baseHour = 6 + (location.coordinate.longitude / 15.0) // Rough timezone adjustment
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        
        return calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: Int(baseHour),
            minute: Int((baseHour.truncatingRemainder(dividingBy: 1)) * 60)
        )) ?? today
    }
    
    /// Simplified sunset calculation
    /// - Parameter location: Location for calculation
    /// - Returns: Approximate sunset time
    private func calculateSunset(for location: CLLocation) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Very simplified calculation - in production, use proper astronomical algorithms
        let baseHour = 18 + (location.coordinate.longitude / 15.0) // Rough timezone adjustment
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        
        return calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: Int(baseHour),
            minute: Int((baseHour.truncatingRemainder(dividingBy: 1)) * 60)
        )) ?? today
    }
    
    /// Handles WeatherKit-specific errors
    /// - Parameter error: Error from WeatherKit
    @MainActor
    private func handleWeatherKitError(_ error: Error) async {
        logger.error("WeatherKit error: \\(error.localizedDescription)")
        
        if let weatherError = error as? WeatherError {
            self.error = weatherError
        } else {
            // Convert other errors to our weather error format
            if error.localizedDescription.contains("authorization") {
                self.error = .permissionDenied
            } else if error.localizedDescription.contains("network") {
                self.error = .networkError("WeatherKit network error: \\(error.localizedDescription)")
            } else {
                self.error = .apiError("WeatherKit error: \\(error.localizedDescription)")
            }
        }
        
        self.isLoading = false
    }
}

// MARK: - iOS Version Compatibility

/// Fallback weather service for iOS versions below 16.0
class LegacyWeatherService: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var error: WeatherError?
    
    private let logger = Logger(subsystem: "MaterialsAndPractices", category: "LegacyWeatherService")
    
    func fetchWeather(for location: CLLocation) {
        logger.warning("WeatherKit not available on this iOS version, using legacy NOAA service")
        // Here you would call the original NOAA service
        // For now, we'll just show an error
        error = .apiError("WeatherKit requires iOS 16.0 or later")
    }
    
    func clearWeatherData() {
        weatherData = nil
        error = nil
        isLoading = false
    }
}