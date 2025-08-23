//
//  WeatherView.swift
//  MaterialsAndPractices
//
//  Weather information display component for the grows page.
//  Shows current conditions, 4-hour forecast, and daylight information.
//
//  Created by AI Assistant.
//

import SwiftUI

/// Main weather display component for the grows page
struct WeatherView: View {
    // MARK: - Properties
    
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationManager = LocationManager()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if weatherService.isLoading {
                loadingView
            } else if let error = weatherService.error ?? locationManager.error {
                errorView(error)
            } else if let weatherData = weatherService.weatherData {
                weatherContentView(weatherData)
            } else {
                emptyStateView
            }
        }
        .onAppear {
            requestWeatherData()
        }
        .onReceive(locationManager.$location) { location in
            if let location = location {
                weatherService.fetchWeather(for: location)
            }
        }
    }
    
    // MARK: - Content Views
    
    /// Loading state view
    private var loadingView: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading weather data...")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Error state view
    private func errorView(_ error: WeatherError) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppTheme.Colors.warning)
                .font(AppTheme.Typography.headlineMedium)
            
            Text("Weather Unavailable")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(error.localizedDescription)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                requestWeatherData()
            }
            .font(AppTheme.Typography.labelMedium)
            .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Empty state view
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "cloud.sun")
                .foregroundColor(AppTheme.Colors.primary)
                .font(AppTheme.Typography.headlineLarge)
            
            Text("Tap to Load Weather")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Get current conditions and forecast")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .onTapGesture {
            requestWeatherData()
        }
    }
    
    /// Main weather content view
    private func weatherContentView(_ weatherData: WeatherData) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Current conditions section
            currentConditionsView(weatherData.current)
            
            // 4-hour forecast section
            if !weatherData.hourlyForecast.isEmpty {
                hourlyForecastView(weatherData.hourlyForecast)
            }
            
            // Daylight information
            DaylightChart(daylightInfo: weatherData.daylight)
        }
    }
    
    /// Current weather conditions view
    private func currentConditionsView(_ conditions: WeatherConditions) -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Weather icon and condition
            VStack(spacing: AppTheme.Spacing.tiny) {
                AsyncImage(url: URL(string: conditions.icon)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "cloud.sun")
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .frame(width: 48, height: 48)
                
                Text(conditions.condition)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Temperature and details
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                Text("\(Int(conditions.temperature))°F")
                    .font(AppTheme.Typography.displayMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack(spacing: AppTheme.Spacing.small) {
                    weatherDetail(
                        icon: "wind",
                        value: "\(Int(conditions.windSpeed)) mph",
                        direction: conditions.windDirection
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Hourly forecast view
    private func hourlyForecastView(_ forecast: [HourlyForecast]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Next 4 Hours")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(Array(forecast.enumerated()), id: \.offset) { index, hour in
                        hourlyForecastCard(hour, isFirst: index == 0)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.small)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Individual hourly forecast card
    private func hourlyForecastCard(_ forecast: HourlyForecast, isFirst: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text(isFirst ? "Now" : formatHour(forecast.time))
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            AsyncImage(url: URL(string: forecast.icon)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "cloud")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(width: 32, height: 32)
            
            Text("\(Int(forecast.temperature))°")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if forecast.precipitationProbability > 0 {
                Text("\(Int(forecast.precipitationProbability))%")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.info)
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundTertiary)
        .cornerRadius(AppTheme.CornerRadius.small)
        .frame(width: 70)
    }
    
    /// Weather detail component
    private func weatherDetail(icon: String, value: String, direction: String = "") -> some View {
        HStack(spacing: AppTheme.Spacing.tiny) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .font(AppTheme.Typography.labelSmall)
            
            Text(value)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            if !direction.isEmpty {
                Text(direction)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats hour for display in forecast
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
    
    /// Requests weather data by getting location first
    private func requestWeatherData() {
        weatherService.error = nil
        locationManager.error = nil
        locationManager.requestLocation()
    }
}

// MARK: - Preview Provider

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeatherView()
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.light)
            
            WeatherView()
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}