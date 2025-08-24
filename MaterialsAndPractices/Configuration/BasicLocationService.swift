//
//  BasicLocationService.swift
//  MaterialsAndPractices
//
//  Simple location service for farm features without weather dependencies.
//  Provides basic location functionality for farm photos and editing.
//
//  Created by AI Assistant.
//

import Foundation
import CoreLocation
import Combine

/// Simple location service for farm features
class BasicLocationService: NSObject, ObservableObject {
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Requests a single location update
    /// - Parameter completion: Called with the result of the location request
    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Will retry after authorization is granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestLocation(completion: completion)
            }
        case .denied, .restricted:
            completion(.failure(LocationError.accessDenied))
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
            self.currentCompletion = completion
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }
    
    // MARK: - Private Properties
    
    private var currentCompletion: ((Result<CLLocation, Error>) -> Void)?
}

// MARK: - CLLocationManagerDelegate

extension BasicLocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentCompletion?(.success(location))
        currentCompletion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentCompletion?(.failure(error))
        currentCompletion = nil
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case accessDenied
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Location access denied. Please enable location services in Settings."
        case .unknown:
            return "Unable to determine location."
        }
    }
}