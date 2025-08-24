//
//  EditFarmView.swift
//  MaterialsAndPractices
//
//  Provides farm creation and editing functionality with address lookup,
//  geolocation services, and lease information management.
//
//  Created by AI Assistant.
//

import SwiftUI
import CoreData
import CoreLocation
import MapKit

/// Farm creation and editing view with comprehensive form inputs and location services
struct EditFarmView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    // Form state variables
    @State private var name: String = ""
    @State private var farmDescription: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var county: String = ""
    @State private var totalAcres: String = ""
    
    // Lease information
    @State private var leaseAcres: String = ""
    @State private var leaseTerm: String = ""
    @State private var leaseAmount: String = ""
    @State private var leasePaymentDate: Date = Date()
    @State private var propertyOwnerName: String = ""
    @State private var propertyOwnerPhone: String = ""
    @State private var propertyOwnerEmail: String = ""
    @State private var propertyOwnerAddress: String = ""
    @State private var paymentMethod: String = ""
    @State private var paymentAccountInfo: String = ""
    @State private var notes: String = ""
    
    // Location state
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var isLoadingLocation = false
    @State private var addressSuggestions: [MKLocalSearchCompletion] = []
    @State private var showingAddressSuggestions = false
    
    // Location services
    @StateObject private var locationManager = LocationManager()
    @StateObject private var addressSearchCompleter = AddressSearchCompleter()
    
    @Binding var isPresented: Bool
    
    // Optional farm for editing
    let farm: Farm?
    
    // Computed property for form validation
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(farm: Farm? = nil, isPresented: Binding<Bool>) {
        self.farm = farm
        self._isPresented = isPresented
        
        // Initialize form with existing farm data if editing
        if let existingFarm = farm {
            self._name = State(initialValue: existingFarm.name ?? "")
            self._farmDescription = State(initialValue: existingFarm.farmDescription ?? "")
            self._address = State(initialValue: existingFarm.address ?? "")
            self._city = State(initialValue: existingFarm.city ?? "")
            self._state = State(initialValue: existingFarm.state ?? "")
            self._zip = State(initialValue: existingFarm.zip ?? "")
            self._county = State(initialValue: existingFarm.county ?? "")
            self._totalAcres = State(initialValue: existingFarm.totalAcres > 0 ? "\(existingFarm.totalAcres)" : "")
            self._leaseAcres = State(initialValue: existingFarm.leaseAcres > 0 ? "\(existingFarm.leaseAcres)" : "")
            self._leaseTerm = State(initialValue: existingFarm.leaseTerm ?? "")
            self._leaseAmount = State(initialValue: existingFarm.leaseAmount > 0 ? "\(existingFarm.leaseAmount)" : "")
            self._leasePaymentDate = State(initialValue: existingFarm.leasePaymentDate ?? Date())
            self._propertyOwnerName = State(initialValue: existingFarm.propertyOwnerName ?? "")
            self._propertyOwnerPhone = State(initialValue: existingFarm.propertyOwnerPhone ?? "")
            self._propertyOwnerEmail = State(initialValue: existingFarm.propertyOwnerEmail ?? "")
            self._propertyOwnerAddress = State(initialValue: existingFarm.propertyOwnerAddress ?? "")
            self._paymentMethod = State(initialValue: existingFarm.paymentMethod ?? "")
            self._paymentAccountInfo = State(initialValue: existingFarm.paymentAccountInfo ?? "")
            self._notes = State(initialValue: existingFarm.notes ?? "")
            self._latitude = State(initialValue: existingFarm.latitude)
            self._longitude = State(initialValue: existingFarm.longitude)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Basic Information Section
                Section(header: Text("Farm Information")) {
                    TextField("Farm Name", text: $name)
                    TextField("Description", text: $farmDescription, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Total Acres", text: $totalAcres)
                        .keyboardType(.decimalPad)
                }
                
                // MARK: - Address Section
                Section(header: Text("Address")) {
                    addressFields
                    currentLocationButton
                }
                
                // MARK: - Lease Information Section
                Section(header: Text("Lease Information")) {
                    leaseFields
                }
                
                // MARK: - Property Owner Section
                Section(header: Text("Property Owner Information")) {
                    propertyOwnerFields
                }
                
                // MARK: - Payment Information Section
                Section(header: Text("Payment Information")) {
                    paymentFields
                }
                
                // MARK: - Notes Section
                Section(header: Text("Notes")) {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(farm == nil ? "New Farm" : "Edit Farm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFarm()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
          
        }
    }
    
    // MARK: - Address Fields
    
    @ViewBuilder
    private var addressFields: some View {
        VStack {
            TextField("Address", text: $address)
                .onChange(of: address) { newValue in
                    if !newValue.isEmpty {
                        addressSearchCompleter.search(for: newValue)
                    }
                }
            
            if !addressSearchCompleter.suggestions.isEmpty && showingAddressSuggestions {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(addressSearchCompleter.suggestions.prefix(5), id: \.title) { suggestion in
                        Button(action: {
                            selectAddressSuggestion(suggestion)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Text(suggestion.subtitle)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if suggestion.title != addressSearchCompleter.suggestions.prefix(5).last?.title {
                            Divider()
                        }
                    }
                }
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .onTapGesture {
            showingAddressSuggestions = true
        }
        
        TextField("City", text: $city)
        TextField("State", text: $state)
        TextField("ZIP Code", text: $zip)
            .keyboardType(.numberPad)
        TextField("County", text: $county)
    }
    
    // MARK: - Current Location Button
    
    private var currentLocationButton: some View {
        Button(action: {
            useCurrentLocation()
        }) {
            HStack {
                Image(systemName: isLoadingLocation ? "location.circle" : "location.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text("Use Current Location")
                    .foregroundColor(AppTheme.Colors.primary)
                if isLoadingLocation {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
        .disabled(isLoadingLocation)
    }
    
    // MARK: - Lease Fields
    
    @ViewBuilder
    private var leaseFields: some View {
        TextField("Lease Acres", text: $leaseAcres)
            .keyboardType(.decimalPad)
        TextField("Lease Term (e.g., 1 year, 5 years)", text: $leaseTerm)
        TextField("Lease Amount", text: $leaseAmount)
            .keyboardType(.decimalPad)
        DatePicker("Payment Date", selection: $leasePaymentDate, displayedComponents: .date)
    }
    
    // MARK: - Property Owner Fields
    
    @ViewBuilder
    private var propertyOwnerFields: some View {
        TextField("Owner Name", text: $propertyOwnerName)
        TextField("Owner Phone", text: $propertyOwnerPhone)
            .keyboardType(.phonePad)
        TextField("Owner Email", text: $propertyOwnerEmail)
            .keyboardType(.emailAddress)
        TextField("Owner Address", text: $propertyOwnerAddress)
    }
    
    // MARK: - Payment Fields
    
    @ViewBuilder
    private var paymentFields: some View {
        TextField("Payment Method", text: $paymentMethod)
        TextField("Account Information", text: $paymentAccountInfo)
    }
    
    // MARK: - Methods

    private func selectAddressSuggestion(_ suggestion: MKLocalSearchCompletion) {
        showingAddressSuggestions = false
        
        // Update address field with selected suggestion
        address = suggestion.title
        
        // Perform geocoding to get coordinates and detailed address info
        let searchRequest = MKLocalSearch.Request(completion: suggestion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response,
                  let mapItem = response.mapItems.first else {
                return
            }
            
            DispatchQueue.main.async {
                // Update coordinates
                self.latitude = mapItem.placemark.coordinate.latitude
                self.longitude = mapItem.placemark.coordinate.longitude
                
                // Update address components
                if let locality = mapItem.placemark.locality {
                    self.city = locality
                }
                if let administrativeArea = mapItem.placemark.administrativeArea {
                    self.state = administrativeArea
                }
                if let postalCode = mapItem.placemark.postalCode {
                    self.zip = postalCode
                }
                if let subAdministrativeArea = mapItem.placemark.subAdministrativeArea {
                    self.county = subAdministrativeArea
                }
            }
        }
    }
    
    private func useCurrentLocation() {
        isLoadingLocation = true
        
        locationManager.requestLocation { result in
            DispatchQueue.main.async {
                self.isLoadingLocation = false
                
                switch result {
                case .success(let location):
                    self.latitude = location.coordinate.latitude
                    self.longitude = location.coordinate.longitude
                    
                    // Reverse geocode to get address information
                    self.reverseGeocode(location: location)
                    
                case .failure(let error):
                    print("Failed to get location: \(error)")
                }
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                if let thoroughfare = placemark.thoroughfare,
                   let subThoroughfare = placemark.subThoroughfare {
                    self.address = "\(subThoroughfare) \(thoroughfare)"
                }
                
                if let locality = placemark.locality {
                    self.city = locality
                }
                
                if let administrativeArea = placemark.administrativeArea {
                    self.state = administrativeArea
                }
                
                if let postalCode = placemark.postalCode {
                    self.zip = postalCode
                }
                
                if let subAdministrativeArea = placemark.subAdministrativeArea {
                    self.county = subAdministrativeArea
                }
            }
        }
    }
    
    private func saveFarm() {
        let farmToSave: Farm
        
        if let existingFarm = farm {
            farmToSave = existingFarm
        } else {
            farmToSave = Farm(context: viewContext)
            farmToSave.createdDate = Date()
        }
        
        // Update farm properties
        farmToSave.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.farmDescription = farmDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.state = state.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.zip = zip.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.county = county.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.latitude = latitude
        farmToSave.longitude = longitude
        farmToSave.totalAcres = Double(totalAcres.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        farmToSave.leaseAcres = Double(leaseAcres.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        farmToSave.leaseTerm = leaseTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.leaseAmount = Double(leaseAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        farmToSave.leasePaymentDate = leasePaymentDate
        farmToSave.propertyOwnerName = propertyOwnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.propertyOwnerPhone = propertyOwnerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.propertyOwnerEmail = propertyOwnerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.propertyOwnerAddress = propertyOwnerAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.paymentMethod = paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.paymentAccountInfo = paymentAccountInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        farmToSave.updatedDate = Date()
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Failed to save farm: \(error)")
        }
    }
}

// MARK: - Address Search Completer

/// Helper class for handling address search completion
class AddressSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    func search(for query: String) {
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Address search failed: \(error)")
    }
}

// MARK: - Location Manager Extension

extension LocationManager {
    func requestLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        // Use the existing location if available, otherwise request a new one
        if let currentLocation = location {
            completion(.success(currentLocation))
        } else {
            // Request location and call completion when available
            requestLocation()
            
            // Monitor for location updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if let newLocation = self.location {
                    completion(.success(newLocation))
                } else {
                    completion(.failure(NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get location"])))
                }
            }
        }
    }
}

struct EditFarmView_Previews: PreviewProvider {
    static var previews: some View {
        EditFarmView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
