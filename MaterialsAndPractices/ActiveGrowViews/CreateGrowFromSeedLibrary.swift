//
//  CreateGrowFromSeedLibrary.swift
//  MaterialsAndPractices
//
//  Create a new grow entry using data from a SeedLibrary item.
//  Optimized for farm workflows with location integration and streamlined entry.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// SwiftUI view to create a Grow entity from a SeedLibrary reference
struct CreateGrowFromSeedLibrary: View {
    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Input Properties
    let cultivar: Cultivar
    var seed: SeedLibrary
    @Binding var isPresented: Bool

    // MARK: - Grow Metadata

    @State private var name: String = ""
    @State private var plantedDate: Date = Date()
    @State private var expectedHarvestDate: Date = Date()

    @State private var manager: String = ""
    @State private var managerPhone: String = ""
    @State private var notes: String = ""
    @State private var size: Double = 0

    // MARK: - Location and Property Info

    @State private var selectedProperty: Property?
    @State private var selectedField: Field?
    @State private var showingPropertySelection = false
    @State private var showingFieldSelection = false

    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var county: String = ""
    @State private var drivingDirections: String = ""
    @State private var propertyOwner: String = ""
    @State private var propertyOwnerPhone: String = ""

    // MARK: - Fetch Requests

    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var properties: FetchedResults<Property>

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedProperty != nil &&
        selectedField != nil
    }

    // MARK: - Init
    
    static func extractGrowingDays(from input: String?) -> Int? {
        guard let input = input else { return nil }
        let digits = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits)
    }

    
    init(seed maybeSeed: SeedLibrary?, cultivar: Cultivar, isPresented: Binding<Bool>, context: NSManagedObjectContext) {
        self.cultivar = cultivar
        self._isPresented = isPresented

        // Ensure we always have a seed
        if let providedSeed = maybeSeed {
            self.seed = providedSeed
        } else {
            self.seed = SeedLibrary.createFromCultivar(cultivar, in: context)
        }

        // Pre-fill grow name
        self._name = State(initialValue: "New \(cultivar.displayName) Grow")

        // Auto-calculate expected harvest date if days are available
        if let growingDays = Self.extractGrowingDays(from: cultivar.growingDays) {
            let harvestDate = Calendar.current.date(byAdding: .day, value: growingDays, to: Date()) ?? Date()
            self._expectedHarvestDate = State(initialValue: harvestDate)
        }
    }
    
    init(seed:SeedLibrary, isPresented: Binding<Bool>) {
        self.cultivar = seed.cultivar!
        self._isPresented = isPresented

        // Pre-populate name with cultivar
        self._name = State(initialValue: "New \(cultivar.displayName) Grow")
        self.seed = seed
        
        // Pre-populate expected harvest date based on growing days
//        if let growingDaysString = cultivar.growingDays,
//           let growingDays = CreateGrowFromCultivarView.extractDaysFromString(growingDaysString) {
//            let harvestDate = Calendar.current.date(byAdding: .day, value: growingDays, to: Date()) ?? Date()
//            self._expectedHarvestDate = State(initialValue: harvestDate)
//        }
    }
    
    // MARK: - View Body

    var body: some View {
        NavigationView {
            Form {
                if seed.isCertifiedOrganic {
                    organicCertificationBanner
                }

                basicDetailsSection
                LocationSelectionView(
                    selectedProperty: $selectedProperty,
                    selectedField: $selectedField,
                    showingPropertySelection: $showingPropertySelection,
                    showingFieldSelection: $showingFieldSelection
                )
                additionalInformationSection
                saveSection
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
                // TODO: Re-enable property picker
            }
            .sheet(isPresented: $showingFieldSelection) {
                // TODO: Re-enable field picker
            }
        }
    }

    // MARK: - View Sections

    private var organicCertificationBanner: some View {
        HStack {
            Image(systemName: "leaf")
                .foregroundColor(.green)
            Text("Certified Organic Seed")
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }

    private var basicDetailsSection: some View {
        Section(header: Text("Grow Details")) {
            TextField("Grow Name", text: $name)

            DatePicker("Planted Date", selection: $plantedDate, displayedComponents: .date)

            DatePicker("Expected Harvest", selection: $expectedHarvestDate, displayedComponents: .date)
        }
    }

    private var additionalInformationSection: some View {
        Section(header: Text("Management")) {
            TextField("Manager", text: $manager)
            TextField("Manager Phone", text: $managerPhone)

            TextField("Grow Size (e.g. acres)", value: $size, format: .number)
                .keyboardType(.decimalPad)

            TextEditor(text: $notes)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.3)))
        }
    }

    private var saveSection: some View {
        Section {
            Button("Save Grow") {
                saveGrow()
            }
            .disabled(!isFormValid)
        }
    }

    // MARK: - Save Logic

    private func saveGrow() {
        let newGrow = Grow(context: viewContext)
        newGrow.title = name
        newGrow.plantedDate = plantedDate
        //newGrow.expectedHavestDate = expectedHarvestDate
        newGrow.manager = manager
        newGrow.managerPhone = managerPhone
        newGrow.notes = notes
        newGrow.size = size
        newGrow.seed = seed
        newGrow.field?.property = selectedProperty
        newGrow.field = selectedField

        // Add address and property metadata as needed

        do {
            try viewContext.save()
            isPresented = false
        } catch {
            // TODO: Add error handling/logging
            print("Failed to save Grow: \(error.localizedDescription)")
        }
    }
}
