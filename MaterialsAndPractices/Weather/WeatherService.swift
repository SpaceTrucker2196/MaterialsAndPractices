//
//  WeatherService.swift
//  MaterialsAndPractices
//
//  Enhanced service for fetching weather data with WeatherKit and NOAA fallback
//  Provides current conditions and hourly forecast for agricultural planning
//  with comprehensive error handling and debugging capabilities.
//
//  Created by AI Assistant.
//

import Foundation
import Combine
import CoreLocation
import os.log

/// Enhanced weather service with WeatherKit and NOAA fallback
/// Automatically uses the best available weather service based on iOS version
class WeatherService: ObservableObject {
    // MARK: - Properties
    
    private var weatherKitService: Any? // Will be WeatherKitService when available
    private var noaaService: NOAAWeatherService?
    private let logger = Logger(subsystem: "MaterialsAndPractices", category: "WeatherService")
    
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var error: WeatherError?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupWeatherService()
    }
    
    /// Sets up the appropriate weather service based on iOS version
    private func setupWeatherService() {
        if #available(iOS 16.0, *) {
            // Use WeatherKit for iOS 16+
            logger.info("Initializing WeatherKit service")
            weatherKitService = WeatherKitService()
            
            // Subscribe to WeatherKit service updates
            if let service = weatherKitService as? WeatherKitService {
                service.$weatherData
                    .receive(on: DispatchQueue.main)
                    .assign(to: &$weatherData)
                
                service.$isLoading
                    .receive(on: DispatchQueue.main)
                    .assign(to: &$isLoading)
                
                service.$error
                    .receive(on: DispatchQueue.main)
                    .assign(to: &$error)
            }
        } else {
            // Fallback to NOAA for older iOS versions
            logger.info("Initializing NOAA weather service")
            noaaService = NOAAWeatherService()
            
            // Subscribe to NOAA service updates
            noaaService?.$weatherData
                .receive(on: DispatchQueue.main)
                .assign(to: &$weatherData)
            
            noaaService?.$isLoading
                .receive(on: DispatchQueue.main)
                .assign(to: &$isLoading)
            
            noaaService?.$error
                .receive(on: DispatchQueue.main)
                .assign(to: &$error)
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetches weather data for the given location using the best available service
    /// - Parameter location: CLLocation to get weather for
    func fetchWeather(for location: CLLocation) {
        logger.info("Starting weather fetch for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        if #available(iOS 16.0, *), let service = weatherKitService as? WeatherKitService {
            // Use WeatherKit
            service.fetchWeather(for: location)
        } else if let service = noaaService {
            // Use NOAA fallback
            service.fetchWeather(for: location)
        } else {
            handleError(.apiError("No weather service available"))
        }
    }
    
    /// Clears current weather data and error state
    func clearWeatherData() {
        if #available(iOS 16.0, *), let service = weatherKitService as? WeatherKitService {
            service.clearWeatherData()
        } else {
            noaaService?.clearWeatherData()
        }
    }
    
    // MARK: - Error Handling
    
    /// Enhanced error handling with detailed logging
    /// - Parameter weatherError: The weather error to handle
    private func handleError(_ weatherError: WeatherError) {
        logger.error("Weather service error: \(weatherError.localizedDescription)")
        
        // Log additional context based on error type
        switch weatherError {
        case .networkError(let message):
            logger.error("Network error details: \(message)")
        case .apiError(let message):
            logger.error("API error details: \(message)")
        case .invalidLocation(let message):
            logger.warning("Location error: \(message)")
        case .decodingError(let message):
            logger.error("Data parsing error: \(message)")
        case .permissionDenied:
            logger.error("Permission Error")
        case .locationNotAvailable:
            logger.error("Location error")
        case .parsingError(_):
            logger.error("Parsing error:")
        }
        
        error = weatherError
        isLoading = false
    }
}

// MARK: - NOAA Weather Service (Legacy Support)

/// Legacy NOAA weather service for iOS versions below 16.0 or as fallback
class NOAAWeatherService: ObservableObject {
    // MARK: - Properties
    
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var error: WeatherError?
    
    private let logger = Logger(subsystem: "MaterialsAndPractices", category: "NOAAWeatherService")
    
    // MARK: - Public Methods
    
    /// Fetches weather data using NOAA API (simplified implementation)
    /// - Parameter location: CLLocation to get weather for
    func fetchWeather(for location: CLLocation) {
        logger.info("NOAA service fetch requested for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        isLoading = true
        error = nil
        
        // For now, show that NOAA service is not fully implemented in this update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.error = .apiError("NOAA service temporarily unavailable. Please use iOS 16+ for WeatherKit support.")
            self.isLoading = false
        }
    }
    
    /// Clears current weather data and error state
    func clearWeatherData() {
        weatherData = nil
        error = nil
        isLoading = false
        logger.debug("NOAA weather data cleared")
    }
}