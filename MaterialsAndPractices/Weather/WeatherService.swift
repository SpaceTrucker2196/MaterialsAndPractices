//
//  WeatherService.swift
//  MaterialsAndPractices
//
//  Service for fetching weather data from NOAA Weather API
//  Provides current conditions and hourly forecast for agricultural planning.
//
//  Created by AI Assistant.
//

import Foundation
import Combine
import CoreLocation

/// Service for fetching weather data from NOAA Weather API
class WeatherService: ObservableObject {
    // MARK: - Properties
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    @Published var error: WeatherError?
    
    // NOAA API base URLs
    private let baseURL = "https://api.weather.gov"
    
    // MARK: - Public Methods
    
    /// Fetches weather data for the given location
    /// - Parameter location: CLLocation to get weather for
    func fetchWeather(for location: CLLocation) {
        isLoading = true
        error = nil
        
        // First, get the grid point information
        fetchGridPoint(latitude: location.coordinate.latitude,
                       longitude: location.coordinate.longitude)
    }
    
    // MARK: - Private Methods
    
    /// Fetches grid point information from NOAA API
    private func fetchGridPoint(latitude: Double, longitude: Double) {
        let urlString = "\(baseURL)/points/\(latitude),\(longitude)"
        
        guard let url = URL(string: urlString) else {
            error = WeatherError.apiError("Invalid grid point URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("MaterialsAndPractices/1.0", forHTTPHeaderField: "User-Agent")
        
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NOAAGridResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = WeatherError.networkError(error.localizedDescription)
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] response in
                    self?.fetchForecastData(from: response.properties)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Fetches forecast data using grid point URLs
    private func fetchForecastData(from gridProperties: NOAAGridProperties) {
        // Create publishers for both current conditions and hourly forecast
        let currentPublisher = fetchCurrentConditions(from: gridProperties.forecast)
        let hourlyPublisher = fetchHourlyForecast(from: gridProperties.forecastHourly)
        
        Publishers.CombineLatest(currentPublisher, hourlyPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = WeatherError.networkError(error.localizedDescription)
                    }
                    self?.isLoading = false
                },
                receiveValue: { [weak self] (current, hourly) in
                    self?.createWeatherData(current: current, hourly: hourly)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Fetches current weather conditions
    private func fetchCurrentConditions(from urlString: String) -> AnyPublisher<NOAAForecastPeriod, Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: WeatherError.apiError("Invalid forecast URL"))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.addValue("MaterialsAndPractices/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NOAAForecastResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard let current = response.properties.periods.first else {
                    throw WeatherError.parsingError("No current conditions available")
                }
                return current
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetches hourly weather forecast
    private func fetchHourlyForecast(from urlString: String) -> AnyPublisher<[NOAAForecastPeriod], Error> {
        guard let url = URL(string: urlString) else {
            return Fail(error: WeatherError.apiError("Invalid hourly forecast URL"))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.addValue("MaterialsAndPractices/1.0", forHTTPHeaderField: "User-Agent")
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NOAAForecastResponse.self, decoder: JSONDecoder())
            .map { response in
                // Return next 4 hours
                Array(response.properties.periods.prefix(4))
            }
            .eraseToAnyPublisher()
    }
    
    /// Creates WeatherData from API responses
    private func createWeatherData(current: NOAAForecastPeriod, hourly: [NOAAForecastPeriod]) {
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
            guard let startTime = parseDateTime(period.startTime) else { return nil }
            
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
    }
    
    /// Parses wind speed from NOAA format (e.g., "10 mph")
    private func parseWindSpeed(_ windSpeed: String) -> Double {
        let components = windSpeed.components(separatedBy: " ")
        if let speedString = components.first,
           let speed = Double(speedString) {
            return speed
        }
        return 0
    }
    
    /// Parses ISO 8601 date time string
    private func parseDateTime(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    /// Calculates daylight information for the given date (simplified)
    private func calculateDaylight(for date: Date) -> DaylightInfo {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        var sunriseComponents = components
        sunriseComponents.hour = 6
        sunriseComponents.minute = 30
        
        var sunsetComponents = components
        sunsetComponents.hour = 19
        sunsetComponents.minute = 30
        
        let sunrise = calendar.date(from: sunriseComponents) ?? date
        let sunset = calendar.date(from: sunsetComponents) ?? date
        
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
