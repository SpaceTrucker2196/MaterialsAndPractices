//
//  WeatherService.swift
//  MaterialsAndPractices
//
//  Enhanced service for fetching weather data from NOAA Weather API
//  Provides current conditions and hourly forecast for agricultural planning
//  with comprehensive error handling and debugging capabilities.
//
//  Created by AI Assistant.
//

import Foundation
import Combine
import CoreLocation
import os.log

/// Enhanced weather service with improved error handling and logging
class WeatherService: ObservableObject {
    // MARK: - Properties
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "MaterialsAndPractices", category: "WeatherService")
    
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var error: WeatherError?
    
    // NOAA API base URLs - using centralized configuration
    private var baseURL: String {
        return SecureConfiguration.shared.noaaAPIEndpoint
    }
    
    private let userAgent = "MaterialsAndPractices/1.0 (farming.app@example.com)"
    
    // MARK: - Configuration Management
    
    /// Gets configuration values from secure configuration manager
    private var timeout: TimeInterval {
        return SecureConfiguration.shared.networkTimeoutSeconds
    }
    
    private var maxRetries: Int {
        return SecureConfiguration.shared.maxRetryAttempts
    }
    
    private var retryDelay: TimeInterval = 2.0
    
    // MARK: - Public Methods
    
    /// Fetches weather data for the given location with enhanced error handling
    /// - Parameter location: CLLocation to get weather for
    func fetchWeather(for location: CLLocation) {
        logger.info("Starting weather fetch for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        isLoading = true
        error = nil
        
        // Validate location
        guard isValidLocation(location) else {
            handleError(.invalidLocation("Invalid coordinates provided"))
            return
        }
        
        // First, get the grid point information
        fetchGridPoint(latitude: location.coordinate.latitude,
                       longitude: location.coordinate.longitude)
    }
    
    // MARK: - Private Methods
    
    /// Validates if the provided location is reasonable for NOAA weather data
    /// - Parameter location: CLLocation to validate
    /// - Returns: Boolean indicating if location is valid
    private func isValidLocation(_ location: CLLocation) -> Bool {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // NOAA covers primarily US and territories
        let isUSLocation = lat >= 15.0 && lat <= 72.0 && lon >= -180.0 && lon <= -60.0
        
        if !isUSLocation {
            logger.warning("Location outside NOAA coverage area: \(lat), \(lon)")
        }
        
        return isUSLocation
    }
    
    /// Fetches grid point information from NOAA API with retry logic
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    ///   - retryCount: Current retry attempt (default 0)
    private func fetchGridPoint(latitude: Double, longitude: Double, retryCount: Int = 0) {
        let urlString = "\(baseURL)/points/\(latitude),\(longitude)"
        
        guard let url = URL(string: urlString) else {
            handleError(.apiError("Invalid grid point URL: \(urlString)"))
            return
        }
        
        logger.debug("Fetching grid point from: \(urlString)")
        
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NOAAGridResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.error("Grid point fetch failed: \(error.localizedDescription)")
                        
                        // Implement retry logic
                        if retryCount < (self?.maxRetries ?? 3) {
                            self?.logger.info("Retrying grid point fetch, attempt \(retryCount + 1)")
                            DispatchQueue.main.asyncAfter(deadline: .now() + (self?.retryDelay ?? 2.0)) {
                                self?.fetchGridPoint(latitude: latitude, longitude: longitude, retryCount: retryCount + 1)
                            }
                        } else {
                            self?.handleError(.networkError("Failed to fetch grid point after \(self?.maxRetries ?? 3) attempts: \(error.localizedDescription)"))
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    self?.logger.info("Successfully fetched grid point data")
                    self?.fetchForecastData(from: response.properties)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Fetches forecast data using grid point URLs with enhanced error handling
    /// - Parameter gridProperties: NOAA grid properties containing forecast URLs
    private func fetchForecastData(from gridProperties: NOAAGridProperties) {
        logger.debug("Fetching forecast data from grid properties")
        
        // Validate that we have the required URLs
        guard !gridProperties.forecast.isEmpty,
              !gridProperties.forecastHourly.isEmpty else {
            handleError(.apiError("Invalid grid properties - missing forecast URLs"))
            return
        }
        
        // Create publishers for both current conditions and hourly forecast
        let currentPublisher = fetchCurrentConditions(from: gridProperties.forecast)
        let hourlyPublisher = fetchHourlyForecast(from: gridProperties.forecastHourly)
        
        Publishers.CombineLatest(currentPublisher, hourlyPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.error("Forecast data fetch failed: \(error.localizedDescription)")
                        self?.handleError(.networkError("Failed to fetch forecast data: \(error.localizedDescription)"))
                    }
                    self?.isLoading = false
                },
                receiveValue: { [weak self] (current, hourly) in
                    self?.logger.info("Successfully fetched all weather data")
                    self?.createWeatherData(current: current, hourly: hourly)
                }
            )
            .store(in: &cancellables)
    }
    
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
            logger.error("Arsing error:")
        }
        
        error = weatherError
        isLoading = false
    }
    
    /// Fetches current weather conditions with enhanced error handling
    /// - Parameter urlString: NOAA forecast URL
    /// - Returns: Publisher emitting current conditions
    private func fetchCurrentConditions(from urlString: String) -> AnyPublisher<NOAAForecastPeriod, Error> {
        guard let url = URL(string: urlString) else {
            logger.error("Invalid forecast URL: \(urlString)")
            return Fail(error: WeatherError.apiError("Invalid forecast URL"))
                .eraseToAnyPublisher()
        }
        
        logger.debug("Fetching current conditions from: \(urlString)")
        
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NOAAForecastResponse.self, decoder: JSONDecoder())
            .tryMap { [weak self] response in
                guard let current = response.properties.periods.first else {
                    self?.logger.error("No current conditions available in response")
                    throw WeatherError.decodingError("No current conditions available")
                }
                self?.logger.debug("Successfully parsed current conditions")
                return current
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetches hourly weather forecast with enhanced error handling
    /// - Parameter urlString: NOAA hourly forecast URL
    /// - Returns: Publisher emitting hourly forecast array
    private func fetchHourlyForecast(from urlString: String) -> AnyPublisher<[NOAAForecastPeriod], Error> {
        guard let url = URL(string: urlString) else {
            logger.error("Invalid hourly forecast URL: \(urlString)")
            return Fail(error: WeatherError.apiError("Invalid hourly forecast URL"))
                .eraseToAnyPublisher()
        }
        
        logger.debug("Fetching hourly forecast from: \(urlString)")
        
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NOAAForecastResponse.self, decoder: JSONDecoder())
            .tryMap { [weak self] response in
                let hourlyData = Array(response.properties.periods.prefix(4))
                self?.logger.debug("Successfully parsed \(hourlyData.count) hourly forecasts")
                return hourlyData
            }
            .eraseToAnyPublisher()
    }
    
    /// Creates WeatherData from API responses with error handling
    /// - Parameters:
    ///   - current: Current weather conditions
    ///   - hourly: Hourly forecast array
    private func createWeatherData(current: NOAAForecastPeriod, hourly: [NOAAForecastPeriod]) {
        logger.debug("Creating weather data from API responses")
        
        let currentConditions = WeatherConditions(
            temperature: Double(current.temperature),
            humidity: 0, // NOAA basic forecast lacks humidity
            windSpeed: parseWindSpeed(current.windSpeed),
            windDirection: current.windDirection,
            condition: current.shortForecast,
            icon: current.icon,
            timestamp: Date(),
            visibility: 0,
            dewPoint: 0,
            pressure: 0
        )
        
        let hourlyForecast = hourly.compactMap { period -> HourlyForecast? in
            guard let startTime = parseDateTime(period.startTime) else {
                logger.warning("Failed to parse date time: \(period.startTime)")
                return nil
            }
            
            return HourlyForecast(
                time: startTime,
                temperature: Double(period.temperature),
                condition: period.shortForecast,
                icon: period.icon,
                precipitationProbability: Double(period.probabilityOfPrecipitation?.value ?? 0),
                windSpeed: parseWindSpeed(period.windSpeed)
            )
        }
        
        let daylight = calculateDaylight(for: Date())
        
        weatherData = WeatherData(
            current: currentConditions,
            hourlyForecast: hourlyForecast,
            daylight: daylight,
            location: "Current Location",
            lastUpdated: Date()
        )
        
        logger.info("Successfully created weather data with \(hourlyForecast.count) hourly forecasts")
    }
    
    /// Parses wind speed from NOAA format (e.g., "10 mph") with error handling
    /// - Parameter windSpeed: Wind speed string from NOAA
    /// - Returns: Wind speed in mph, or 0 if parsing fails
    private func parseWindSpeed(_ windSpeed: String) -> Double {
        let components = windSpeed.components(separatedBy: " ")
        if let speedString = components.first,
           let speed = Double(speedString) {
            return speed
        }
        
        logger.warning("Failed to parse wind speed: \(windSpeed)")
        return 0
    }
    
    /// Parses ISO 8601 date time string with error handling
    /// - Parameter dateString: ISO 8601 formatted date string
    /// - Returns: Parsed Date or nil if parsing fails
    private func parseDateTime(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: dateString)
        
        if date == nil {
            logger.warning("Failed to parse date time: \(dateString)")
        }
        
        return date
    }
    
    /// Calculates daylight information for the given date
    /// This is a simplified calculation - in production would use proper solar calculation
    /// - Parameter date: Date to calculate daylight for
    /// - Returns: DaylightInfo with sunrise, sunset, and related times
    private func calculateDaylight(for date: Date) -> DaylightInfo {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Simplified calculation - in production would use proper solar position algorithms
        var sunriseComponents = components
        sunriseComponents.hour = 6
        sunriseComponents.minute = 30
        
        var sunsetComponents = components
        sunsetComponents.hour = 19
        sunsetComponents.minute = 30
        
        let sunrise = calendar.date(from: sunriseComponents) ?? date
        let sunset = calendar.date(from: sunsetComponents) ?? date
        
        logger.debug("Calculated daylight times - Sunrise: \(sunrise), Sunset: \(sunset)")
        
        return DaylightInfo(
            sunrise: sunrise,
            sunset: sunset,
            daylightDuration: sunset.timeIntervalSince(sunrise),
            solarNoon: Date(timeInterval: sunset.timeIntervalSince(sunrise) / 2, since: sunrise),
            twilightBegin: Date(timeInterval: -1800, since: sunrise),
            twilightEnd: Date(timeInterval: 1800, since: sunset)
        )
    }
}
