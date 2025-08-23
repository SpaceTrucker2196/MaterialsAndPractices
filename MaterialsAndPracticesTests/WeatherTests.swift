//
//  WeatherTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for weather functionality including NOAA API integration and data models.
//
//  Created by AI Assistant.
//

import XCTest
import CoreLocation
import Combine
@testable import MaterialsAndPractices

class WeatherTests: XCTestCase {
    
    var weatherService: WeatherService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        weatherService = WeatherService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        weatherService = nil
        cancellables = nil
    }
    
    func testWeatherModelsInitialization() throws {
        // Test WeatherConditions initialization
        let conditions = WeatherConditions(
            temperature: 72.0,
            humidity: 65.0,
            windSpeed: 10.0,
            windDirection: "SW",
            condition: "Partly Cloudy",
            icon: "https://example.com/icon.png",
            timestamp: Date(),
            visibility: 10.0,
            dewPoint: 55.0,
            pressure: 30.12
        )
        
        XCTAssertEqual(conditions.temperature, 72.0)
        XCTAssertEqual(conditions.windDirection, "SW")
        XCTAssertEqual(conditions.condition, "Partly Cloudy")
    }
    
    func testHourlyForecastInitialization() throws {
        let forecast = HourlyForecast(
            time: Date(),
            temperature: 75.0,
            condition: "Sunny",
            icon: "https://example.com/sunny.png",
            precipitationProbability: 20.0,
            windSpeed: 8.0
        )
        
        XCTAssertEqual(forecast.temperature, 75.0)
        XCTAssertEqual(forecast.condition, "Sunny")
        XCTAssertEqual(forecast.precipitationProbability, 20.0)
    }
    
    func testDaylightInfoCalculation() throws {
        let sunrise = Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date()
        let sunset = Calendar.current.date(from: DateComponents(hour: 19, minute: 30)) ?? Date()
        let duration = sunset.timeIntervalSince(sunrise)
        
        let daylight = DaylightInfo(
            sunrise: sunrise,
            sunset: sunset,
            daylightDuration: duration,
            solarNoon: Date(timeInterval: duration / 2, since: sunrise),
            twilightBegin: Date(timeInterval: -1800, since: sunrise),
            twilightEnd: Date(timeInterval: 1800, since: sunset)
        )
        
        XCTAssertEqual(daylight.daylightDuration, 13 * 3600) // 13 hours
        XCTAssertTrue(daylight.sunrise < daylight.sunset)
    }
    
    func testLocationInfoFromCLLocation() throws {
        let clLocation = CLLocation(latitude: 44.0, longitude: -91.5)
        let locationInfo = LocationInfo(from: clLocation)
        
        XCTAssertEqual(locationInfo.latitude, 44.0)
        XCTAssertEqual(locationInfo.longitude, -91.5)
        XCTAssertEqual(locationInfo.country, "US")
    }
    
    func testWeatherServiceInitialization() throws {
        XCTAssertNotNil(weatherService)
        XCTAssertFalse(weatherService.isLoading)
        XCTAssertNil(weatherService.error)
        XCTAssertNil(weatherService.weatherData)
    }
    
    func testWeatherErrorTypes() throws {
        let locationError = WeatherError.locationNotAvailable
        let networkError = WeatherError.networkError("Connection failed")
        let apiError = WeatherError.apiError("Invalid API response")
        let parsingError = WeatherError.parsingError("JSON decode failed")
        let permissionError = WeatherError.permissionDenied
        
        XCTAssertNotNil(locationError.errorDescription)
        XCTAssertNotNil(networkError.errorDescription)
        XCTAssertNotNil(apiError.errorDescription)
        XCTAssertNotNil(parsingError.errorDescription)
        XCTAssertNotNil(permissionError.errorDescription)
        
        XCTAssertTrue(networkError.errorDescription?.contains("Connection failed") == true)
    }
}