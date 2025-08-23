//
//  LocationManager.swift
//  MaterialsAndPractices
//
//  Enhanced location services manager for obtaining device location for weather data and USDA zone detection.
//  Follows privacy best practices and handles permission requests appropriately.
//
//  Created by AI Assistant.
//

import Foundation
import CoreLocation
import Combine
import os.log

/// Observable location manager for handling device location services
/// Provides location data for weather API integration and USDA zone detection
class LocationManager: NSObject, ObservableObject {
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let logger = Logger(subsystem: "MaterialsAndPractices", category: "LocationManager")
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: WeatherError?
    @Published var currentUSDAZone: Int?
    @Published var locationInfo: LocationInfo?
    @Published var isLoading = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    /// Requests location permission and starts location updates
    func requestLocation() {
        logger.info("Location requested")
        isLoading = true
        error = nil
        
        switch authorizationStatus {
        case .notDetermined:
            logger.debug("Requesting location authorization")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            logger.warning("Location access denied or restricted")
            error = WeatherError.invalidLocation("Location access denied. Please enable location services in Settings.")
            isLoading = false
        case .authorizedWhenInUse, .authorizedAlways:
            logger.debug("Location authorized, starting updates")
            startLocationUpdates()
        @unknown default:
            logger.error("Unknown authorization status")
            error = WeatherError.invalidLocation("Unable to determine location authorization status")
            isLoading = false
        }
    }
    
    /// Manually set location for testing purposes
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    func setTestLocation(latitude: Double, longitude: Double) {
        logger.info("Setting test location: \(latitude), \(longitude)")
        let testLocation = CLLocation(latitude: latitude, longitude: longitude)
        processNewLocation(testLocation)
    }
    
    /// Gets USDA zone for current location
    /// - Returns: USDA hardiness zone number (1-11)
    func getCurrentUSDAZone() -> Int? {
        guard let location = location else {
            logger.warning("No location available for USDA zone detection")
            return nil
        }
        
        return calculateUSDAZone(for: location)
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 1000 // Only update if moved 1km
        authorizationStatus = locationManager.authorizationStatus
        
        logger.debug("Location manager configured with \(self.locationManager.desiredAccuracy)m accuracy")
    }
    
    /// Starts location updates if authorized
    private func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            handleLocationError(.invalidLocation("Location not authorized"))
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            handleLocationError(.invalidLocation("Location services not enabled"))
            return
        }
        
        logger.debug("Starting location updates")
        locationManager.startUpdatingLocation()
    }
    
    /// Stops location updates
    func stopLocationUpdates() {
        logger.debug("Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
    
    /// Processes a new location update
    /// - Parameter newLocation: New CLLocation
    private func processNewLocation(_ newLocation: CLLocation) {
        logger.debug("Processing new location: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        
        // Validate location accuracy
        guard newLocation.horizontalAccuracy < 1000 else {
            logger.warning("Location accuracy too low: \(newLocation.horizontalAccuracy)m")
            return
        }
        
        // Check if location is significantly different
        if let currentLocation = location {
            let distance = newLocation.distance(from: currentLocation)
            let timeInterval = newLocation.timestamp.timeIntervalSince(currentLocation.timestamp)
            
            // Only update if moved more than 1km or it's been more than 10 minutes
            guard distance > 1000 || timeInterval > 600 else {
                logger.debug("Location change too small, ignoring update")
                return
            }
        }
        
        location = newLocation
        currentUSDAZone = calculateUSDAZone(for: newLocation)
        
        // Perform reverse geocoding to get location info
        performReverseGeocoding(for: newLocation)
        
        // Stop updates to conserve battery
        stopLocationUpdates()
        isLoading = false
        
        logger.info("Location updated successfully - Zone: \(self.currentUSDAZone ?? 0)")
    }
    
    /// Performs reverse geocoding to get human-readable location information
    /// - Parameter location: CLLocation to reverse geocode
    private func performReverseGeocoding(for location: CLLocation) {
        logger.debug("Starting reverse geocoding")
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.error("Reverse geocoding failed: \(error.localizedDescription)")
                    // Create basic location info without city/state
                    self?.locationInfo = LocationInfo(from: location)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self?.logger.warning("No placemark found in reverse geocoding")
                    self?.locationInfo = LocationInfo(from: location)
                    return
                }
                
                let locationInfo = LocationInfo(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    city: placemark.locality,
                    state: placemark.administrativeArea,
                    country: placemark.country ?? "US"
                )
                
                self?.locationInfo = locationInfo
                self?.logger.info("Reverse geocoding completed: \(placemark.locality ?? "Unknown"), \(placemark.administrativeArea ?? "Unknown")")
            }
        }
    }
    
    /// Calculates USDA hardiness zone based on location
    /// This is a simplified calculation - in production would use proper USDA zone data
    /// - Parameter location: CLLocation to calculate zone for
    /// - Returns: USDA zone number (1-11)
    private func calculateUSDAZone(for location: CLLocation) -> Int {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        // Simplified USDA zone calculation based on latitude
        // In production, would use actual USDA zone map data
        switch latitude {
        case 60...:
            return 1
        case 55..<60:
            return 2
        case 50..<55:
            return 3
        case 45..<50:
            return 4
        case 40..<45:
            return 5
        case 35..<40:
            return 6
        case 30..<35:
            return 7
        case 25..<30:
            return 8
        case 20..<25:
            return 9
        case 15..<20:
            return 10
        default:
            return 11
        }
    }
    
    /// Handles location-related errors with proper logging
    /// - Parameter locationError: WeatherError to handle
    private func handleLocationError(_ locationError: WeatherError) {
        logger.error("Location error: \(locationError.localizedDescription)")
        error = locationError
        isLoading = false
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            logger.warning("No location in didUpdateLocations")
            return
        }
        
        processNewLocation(newLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location manager failed: \(error.localizedDescription)")
        
        let weatherError: WeatherError
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                weatherError = .invalidLocation("Location access denied. Please enable location services in Settings.")
            case .locationUnknown:
                weatherError = .invalidLocation("Unable to determine current location. Please try again.")
            case .network:
                weatherError = .networkError("Network error while getting location. Check your internet connection.")
            case .headingFailure:
                weatherError = .invalidLocation("Location heading not available")
            case .rangingUnavailable:
                weatherError = .invalidLocation("Location ranging not available")
            case .rangingFailure:
                weatherError = .invalidLocation("Location ranging failed")
            default:
                weatherError = .invalidLocation("Location services unavailable: \(clError.localizedDescription)")
            }
        } else {
            weatherError = .invalidLocation("Unknown location error: \(error.localizedDescription)")
        }
        
        handleLocationError(weatherError)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        logger.info("Location authorization changed to: \(status.rawValue)")
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.debug("Location authorized, starting updates")
            if isLoading {
                startLocationUpdates()
            }
        case .denied, .restricted:
            logger.warning("Location authorization denied or restricted")
            handleLocationError(.invalidLocation("Location access denied. Please enable location services in Settings."))
        case .notDetermined:
            logger.debug("Location authorization not determined")
            break
        @unknown default:
            logger.error("Unknown location authorization status")
            handleLocationError(.invalidLocation("Unknown location authorization status"))
        }
    }
}

// MARK: - LocationInfo Extension

extension LocationInfo {
    /// Creates LocationInfo from CLLocation with basic coordinates
    /// - Parameter clLocation: CLLocation to convert
    init(from clLocation: CLLocation) {
        self.latitude = clLocation.coordinate.latitude
        self.longitude = clLocation.coordinate.longitude
        self.city = nil
        self.state = nil
        self.country = "US" // Assuming US for NOAA API compatibility
    }
}
