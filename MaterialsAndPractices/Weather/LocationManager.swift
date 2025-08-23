//
//  LocationManager.swift
//  MaterialsAndPractices
//
//  Location services manager for obtaining device location for weather data.
//  Follows privacy best practices and handles permission requests appropriately.
//
//  Created by AI Assistant.
//

import Foundation
import CoreLocation
import Combine

/// Observable location manager for handling device location services
/// Provides location data for weather API integration
class LocationManager: NSObject, ObservableObject {
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: WeatherError?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    /// Requests location permission and starts location updates
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            error = WeatherError.permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            error = WeatherError.locationNotAvailable
        }
    }
    
    /// Starts location updates if authorized
    private func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            error = WeatherError.permissionDenied
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    /// Stops location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Only update if the new location is significantly different or more recent
        if let currentLocation = location {
            let distance = newLocation.distance(from: currentLocation)
            let timeInterval = newLocation.timestamp.timeIntervalSince(currentLocation.timestamp)
            
            // Update if moved more than 1km or it's been more than 10 minutes
            if distance > 1000 || timeInterval > 600 {
                location = newLocation
            }
        } else {
            location = newLocation
        }
        
        // Stop updates after getting a location to conserve battery
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                self.error = WeatherError.permissionDenied
            case .locationUnknown:
                self.error = WeatherError.locationNotAvailable
            case .network:
                self.error = WeatherError.networkError("Location network error")
            default:
                self.error = WeatherError.locationNotAvailable
            }
        } else {
            self.error = WeatherError.locationNotAvailable
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            error = WeatherError.permissionDenied
        case .notDetermined:
            break
        @unknown default:
            error = WeatherError.locationNotAvailable
        }
    }
}

// MARK: - LocationInfo Extension

extension LocationInfo {
    /// Creates LocationInfo from CLLocation
    init(from clLocation: CLLocation) {
        self.latitude = clLocation.coordinate.latitude
        self.longitude = clLocation.coordinate.longitude
        self.city = nil // Will be filled by reverse geocoding if needed
        self.state = nil
        self.country = "US" // Assuming US for NOAA API
    }
}