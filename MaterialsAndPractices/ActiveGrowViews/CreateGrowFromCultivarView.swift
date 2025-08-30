//
//  CreateGrowFromCultivarView.swift
//  MaterialsAndPractices
//
//  Create a new grow pre-populated with cultivar information.
//  Reuses the core grow creation functionality while providing a streamlined
//  workflow specifically for creating grows from cultivar detail views.
//
//  Features:
//  - Pre-populated cultivar selection
//  - Streamlined form focused on essential grow details
//  - Integration with existing grow management system
//  - Full location and property management
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Create grow view specifically designed for cultivar-initiated grow creation
/// Provides a pre-populated form with the selected cultivar and streamlined workflow
struct CreateGrowFromCultivarView: View {
    // MARK: - Environment Properties

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Properties

    let cultivar: Cultivar
    @Binding var isPresented: Bool

    // MARK: - State Properties

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var plantedDate: Date = Date()
    @State private var expectedHarvestDate: Date = Date()
    @State private var propertyOwner: String = ""
    @State private var propertyOwnerPhone: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var county: String = ""
    @State private var drivingDirections: String = ""
    @State private var manager: String = ""
    @State private var managerPhone: String = ""
    @State private var notes: String = ""
    @State private var size: String = ""

    // Property and field selection
    @State private var selectedProperty: Property?
    @State private var selectedField: Field?
    @State private var showingPropertySelection = false
    @State private var showingFieldSelection = false

    // Fetch requests for properties and fields
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var properties: FetchedResults<Property>

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedProperty != nil && selectedField != nil
    }

    // MARK: - Initialization

    init(cultivar: Cultivar, isPresented: Binding<Bool>) {
        self.cultivar = cultivar
        self._isPresented = isPresented

        // Pre-populate name with cultivar
        self._name = State(initialValue: "New \(cultivar.displayName) Grow")

        // Pre-populate expected harvest date based on growing days
//        if let growingDaysString = cultivar.growingDays,
//           let growingDays = CreateGrowFromCultivarView.extractDaysFromString(growingDaysString) {
//            let harvestDate = Calendar.current.date(byAdding: .day, value: growingDays, to: Date()) ?? Date()
//            self._expectedHarvestDate = State(initialValue: harvestDate)
//        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                if cultivar.isOrganicCertified {
                  //  organicCertificationBanner
                }
              //  cultivarInfoSection
             //   basicDetailsSection
                LocationSelectionView(
                    selectedProperty: $selectedProperty,
                    selectedField: $selectedField,
                    showingPropertySelection: $showingPropertySelection,
                    showingFieldSelection: $showingFieldSelection
                )
            //    harvestCalendarSection
            //    additionalInformationSection
             //   saveSection
            }
            .navigationTitle("New Grow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingPropertySelection) {
//                PropertySelectionView(
//                    properties: Array(properties),
//                    selectedProperty: $selectedProperty,
//                    isPresented: $showingPropertySelection
//                ) { property in
//                    selectedProperty = property
//                    selectedField = nil
//                    updateOwnerInformation()
               // }
            }
            .sheet(isPresented: $showingFieldSelection) {
//                if let property = selectedProperty {
//                    FieldSelectionView(
//                        property: property,
//                        selectedField: $selectedField,
//                        isPresented: $showingFieldSelection
//                    )
//                }
            }
        }
    }

    // MARK: - Refactored Se
}
