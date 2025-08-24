//
//  WeatherKitDemoView.swift
//  MaterialsAndPractices
//
//  Demo view showcasing the new WeatherKit integration with season and moon phase display.
//  This view demonstrates the enhanced grows dashboard functionality.
//
//  Created by AI Assistant.
//

import SwiftUI

/// Demo view showcasing the new WeatherKit integration features
struct WeatherKitDemoView: View {
    // MARK: - Properties
    
    @State private var showingDetails = false
    
    // Sample data for demonstration
    private let demoWeatherData = WeatherData(
        current: WeatherConditions(
            temperature: 72.5,
            humidity: 65.0,
            windSpeed: 8.2,
            windDirection: "SW",
            condition: "Partly Cloudy",
            icon: "cloud.sun",
            timestamp: Date(),
            visibility: 10.0,
            dewPoint: 58.3,
            pressure: 30.15
        ),
        hourlyForecast: [
            HourlyForecast(time: Date(), temperature: 72.5, condition: "Partly Cloudy", icon: "cloud.sun", precipitationProbability: 10, windSpeed: 8.2),
            HourlyForecast(time: Date().addingTimeInterval(3600), temperature: 74.0, condition: "Sunny", icon: "sun.max", precipitationProbability: 5, windSpeed: 9.0),
            HourlyForecast(time: Date().addingTimeInterval(7200), temperature: 75.5, condition: "Sunny", icon: "sun.max", precipitationProbability: 0, windSpeed: 10.2),
            HourlyForecast(time: Date().addingTimeInterval(10800), temperature: 76.0, condition: "Partly Cloudy", icon: "cloud.sun", precipitationProbability: 15, windSpeed: 12.0)
        ],
        daylight: DaylightInfo(
            sunrise: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            sunset: Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date(),
            daylightDuration: 12.5 * 3600,
            solarNoon: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(),
            twilightBegin: Calendar.current.date(byAdding: .hour, value: -2.5, to: Date()) ?? Date(),
            twilightEnd: Calendar.current.date(byAdding: .hour, value: 8.5, to: Date()) ?? Date()
        ),
        location: "San Francisco, CA",
        lastUpdated: Date()
    )
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Header
                    headerSection
                    
                    // Weather Kit Integration Section
                    weatherKitSection
                    
                    // Season & Moon Phase Section
                    seasonMoonSection
                    
                    // Agricultural Guidance Section
                    agriculturalGuidanceSection
                    
                    // Benefits Section
                    benefitsSection
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("WeatherKit Integration")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "cloud.sun.rain.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("Enhanced Weather Integration")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Powered by Apple WeatherKit with agricultural timing guidance")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - WeatherKit Section
    
    private var weatherKitSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("WeatherKit Integration")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("Enhanced weather data from Apple's WeatherKit provides more accurate and comprehensive weather information for better agricultural planning.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Demo weather display
            VStack(spacing: AppTheme.Spacing.small) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Conditions")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("\(String(format: "%.1f", demoWeatherData.current.temperature))°F")
                            .font(AppTheme.Typography.displayMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(demoWeatherData.current.condition)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: demoWeatherData.current.icon)
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                HStack {
                    weatherDetailItem("Humidity", value: "\(Int(demoWeatherData.current.humidity))%", icon: "humidity")
                    Spacer()
                    weatherDetailItem("Wind", value: "\(String(format: "%.1f", demoWeatherData.current.windSpeed)) mph", icon: "wind")
                    Spacer()
                    weatherDetailItem("Visibility", value: "\(String(format: "%.1f", demoWeatherData.current.visibility)) mi", icon: "eye")
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Season & Moon Section
    
    private var seasonMoonSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Season & Moon Phase")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("Agricultural timing based on astronomical calculations and lunar gardening principles.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Demo season and moon display
            SeasonMoonView()
        }
    }
    
    // MARK: - Agricultural Guidance Section
    
    private var agriculturalGuidanceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Agricultural Guidance")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                guidanceCard(
                    title: "Planting Timing",
                    description: "Based on current moon phase and season",
                    recommendation: "Good time for planting leafy greens",
                    icon: "leaf.fill",
                    color: .green
                )
                
                guidanceCard(
                    title: "Harvest Timing",
                    description: "Optimal harvest windows for maximum yield",
                    recommendation: "Wait 3 days for full moon harvest",
                    icon: "scissors",
                    color: .orange
                )
                
                guidanceCard(
                    title: "Weather Planning",
                    description: "Short-term weather considerations",
                    recommendation: "No rain expected - good for outdoor work",
                    icon: "cloud.sun",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Key Benefits")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                benefitItem(icon: "checkmark.circle.fill", title: "More Accurate Data", description: "Apple's WeatherKit provides precise weather information")
                benefitItem(icon: "clock.fill", title: "Better Timing", description: "Astronomical calculations for optimal agricultural timing")
                benefitItem(icon: "moon.stars.fill", title: "Lunar Gardening", description: "Traditional wisdom meets modern technology")
                benefitItem(icon: "leaf.fill", title: "Improved Yields", description: "Better planning leads to healthier crops")
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func weatherDetailItem(_ label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
    
    private func guidanceCard(title: String, description: String, recommendation: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(recommendation)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(color)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private func benefitItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview Provider

struct WeatherKitDemoView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherKitDemoView()
            .preferredColorScheme(.light)
            .previewDisplayName("WeatherKit Demo")
    }
}