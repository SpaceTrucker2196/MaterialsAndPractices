//
//  WeatherModels.swift
//  MaterialsAndPractices
//
//  Data models for NOAA weather API integration providing weather information
//  for agricultural grow tracking and management.
//
//  Created by AI Assistant.
//

import Foundation

// MARK: - NOAA Weather API Models

/// Current weather conditions from NOAA Weather API
struct WeatherConditions {
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
    let condition: String
    let icon: String
    let timestamp: Date
    let visibility: Double
    let dewPoint: Double
    let pressure: Double
}

/// Hourly weather forecast data
struct HourlyForecast {
    let time: Date
    let temperature: Double
    let condition: String
    let icon: String
    let precipitationProbability: Double
    let windSpeed: Double
}

/// Daylight information for agricultural planning
struct DaylightInfo {
    let sunrise: Date
    let sunset: Date
    let daylightDuration: TimeInterval
    let solarNoon: Date
    let twilightBegin: Date
    let twilightEnd: Date
}

/// Complete weather data package
struct WeatherData {
    let current: WeatherConditions
    let hourlyForecast: [HourlyForecast]
    let daylight: DaylightInfo
    let location: String
    let lastUpdated: Date
}

// MARK: - NOAA API Response Models

/// NOAA Grid Point Response
struct NOAAGridResponse: Codable {
    let properties: NOAAGridProperties
}

struct NOAAGridProperties: Codable {
    let forecast: String
    let forecastHourly: String
}

/// NOAA Forecast Response
struct NOAAForecastResponse: Codable {
    let properties: NOAAForecastProperties
}

struct NOAAForecastProperties: Codable {
    let periods: [NOAAForecastPeriod]
}

struct NOAAForecastPeriod: Codable {
    let name: String
    let temperature: Int
    let temperatureUnit: String
    let windSpeed: String
    let windDirection: String
    let shortForecast: String
    let icon: String
    let startTime: String
    let endTime: String
    let probabilityOfPrecipitation: NOAAPrecipitation?
}

struct NOAAPrecipitation: Codable {
    let value: Int?
}

// MARK: - Location Models

/// Geographic location information
struct LocationInfo {
    let latitude: Double
    let longitude: Double
    let city: String?
    let state: String?
    let country: String
}

// MARK: - Weather Error Types

enum WeatherError: Error, LocalizedError {
    case locationNotAvailable
    case networkError(String)
    case apiError(String)
    case parsingError(String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "Location information is not available"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "Weather API error: \(message)"
        case .parsingError(let message):
            return "Data parsing error: \(message)"
        case .permissionDenied:
            return "Location permission denied"
        }
    }
}