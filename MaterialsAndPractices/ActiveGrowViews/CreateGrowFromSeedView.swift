//
//  CreateGrowFromSeedView.swift
//  MaterialsAndPractices
//
//  Create a new grow using seed library entries instead of cultivars directly.
//  Provides a streamlined workflow for starting grows from seed inventory
//  with proper traceability and organic compliance tracking.
//
//  Features:
//  - Pre-populated seed and cultivar information
//  - Streamlined form focused on essential grow details
//  - Integration with existing grow management system
//  - Full location and property management
//  - Seed quantity tracking and deduction
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Create grow view specifically designed for seed-initiated grow creation
/// Provides a pre-populated form with the selected seed and streamlined workflow
struct CreateGrowFromSeedView: View {
    // MARK: - Environment Properties

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Properties

    let seed: SeedLibrary
    @Binding var isPresented: Bool

    // MARK: - State Properties

    @State private var name: String = ""
    @State private var plantedDate = Date()
    @State private var expectedHarvestDate = Date()
    @State private var size: String = "0"
    @State private var notes: String = ""
    @State private var seedQuantityUsed: String = "1"

    // Location selection
    @State private var selectedProperty: Property?
    @State private var selectedField: Field?
    @State private var showingPropertySelection = false
    @State private var showingFieldSelection = false

    // UI state
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    // Fetch requests for properties and fields
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var properties: FetchedResults<Property>

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedProperty != nil && selectedField != nil &&
        Double(size) != nil && Double(size)! > 0 &&
        Double(seedQuantityUsed) != nil && Double(seedQuantityUsed)! > 0
    }

    // MARK: - Initialization

    init(seed: SeedLibrary, isPresented: Binding<Bool>) {
        self.seed = seed
        self._isPresented = isPresented

        // Pre-populate name with seed and cultivar info
        let seedName = seed.seedName ?? "Unknown Seed"
        self._name = State(initialValue: "New \(seedName) Grow")

        // Calculate expected harvest date based on cultivar growing days
        if let cultivar = seed.cultivar,
           let growingDaysString = cultivar.growingDays {
            let growingDays = cultivar.parseGrowingDays()
            if growingDays.early > 0 {
                let harvestDate = Calendar.current.date(byAdding: .day, value: growingDays.early, to: Date()) ?? Date()
                self._expectedHarvestDate = State(initialValue: harvestDate)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Seed information section
                seedInfoSection
                
                // Basic grow details
                basicDetailsSection
                
                // Location selection
                LocationSelectionView(
                    selectedProperty: $selectedProperty,
                    selectedField: $selectedField,
                    showingPropertySelection: $showingPropertySelection,
                    showingFieldSelection: $showingFieldSelection
                )
                
                // Harvest planning
                harvestPlanningSection
                
                // Seed usage tracking
                seedUsageSection
                
                // Additional information
                additionalInfoSection
                
                // Save section
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGrow()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("Grow has been created successfully.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - View Sections

    /// Seed information display
    private var seedInfoSection: some View {
        Section("Seed Information") {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(seed.cultivar?.displayName ?? "Taco Beans")
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let cultivar = seed.cultivar {
                        if let family = cultivar.family {
                            Text(family)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        if cultivar.isOrganicCertified {
                            Text("Organic Certified")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.organicPractice)
                        }
                    }
                    
                    HStack {
                        Text("Available: \(seed.quantity)")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if let supplier = seed.supplierSource {
                            Text("• \(supplier.brand ?? "Unknown Supplier")")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                if let cultivar = seed.cultivar {
                    Text(cultivar.emoji ?? "🌱")
                        .font(.largeTitle)
                }
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }
    }

    /// Basic grow details inputs
    private var basicDetailsSection: some View {
        Section("Grow Details") {
            TextField("Grow Name", text: $name)
            
            DatePicker("Planting Date", selection: $plantedDate, displayedComponents: .date)
            
            HStack {
                TextField("Size", text: $size)
                    .keyboardType(.decimalPad)
                
                Text("acres")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    /// Harvest planning section
    private var harvestPlanningSection: some View {
        Section("Harvest Planning") {
            DatePicker("Expected Harvest", selection: $expectedHarvestDate, displayedComponents: .date)
            
            if let cultivar = seed.cultivar, let growingDays = cultivar.growingDays {
                HStack {
                    Text("Growing Days")
                    Spacer()
                    Text(growingDays)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // Days to harvest calculation
            let daysToHarvest = Calendar.current.dateComponents([.day], from: plantedDate, to: expectedHarvestDate).day ?? 0
            HStack {
                Text("Days to Harvest")
                Spacer()
                Text("\(daysToHarvest) days")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    /// Seed usage tracking
    private var seedUsageSection: some View {
        Section("Seed Usage") {
            HStack {
                TextField("Quantity Used", text: $seedQuantityUsed)
                    .keyboardType(.decimalPad)
                
                Text(seed.unit ?? "packets")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if let usedQuantity = Double(seedQuantityUsed),
               seed.quantity > 0 {
                let remainingQuantity = seed.quantity - usedQuantity
                
                HStack {
                    Text("Remaining After Use")
                    Spacer()
                    Text(String(format: "%.1f %@", remainingQuantity, seed.unit ?? ""))
                        .foregroundColor(remainingQuantity >= 0 ? AppTheme.Colors.textSecondary : AppTheme.Colors.error)
                }
                
                if remainingQuantity < 0 {
                    Text("⚠️ Not enough seeds available")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.error)
                }
            }
        }
    }

    /// Additional information
    private var additionalInfoSection: some View {
        Section("Additional Information") {
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...5)
        }
    }

    /// Save button section
    private var saveSection: some View {
        Section {
            Button("Create Grow") {
                saveGrow()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding()
            .background(isFormValid ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .disabled(!isFormValid)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Actions

    /// Save the grow to Core Data
    private func saveGrow() {
        guard isFormValid else { return }
        
        do {
            let grow = Grow(context: viewContext)
            
            // Set basic information
            grow.title = name.trimmingCharacters(in: .whitespacesAndNewlines)
            grow.plantedDate = plantedDate
            grow.expectedHavestDate = DateFormatter().string(from: expectedHarvestDate)
            grow.size = Double(size) ?? 0.0
            grow.notes = notes.isEmpty ? nil : notes
            grow.timestamp = Date()
            
            // Set location
            grow.field = selectedField
            if let property = selectedProperty {
                grow.locationName = property.displayName
                grow.address = property.address
                grow.city = property.city
                grow.state = property.state
                grow.zip = property.zip
            }
            
            // Associate with seed and cultivar
           // grow.addToSeed(seed)
            grow.cultivar = seed.cultivar
            
            // Update seed quantity
            if let usedQuantity = Double(seedQuantityUsed) {
                if seed.quantity >= usedQuantity {
                    seed.quantity -= usedQuantity
                    seed.lastModifiedDate = Date()
                } else {
                    errorMessage = "Not enough seeds available. Available: \(seed.quantity), Requested: \(usedQuantity)"
                    showingErrorAlert = true
                    return
                }
            }
            
            try viewContext.save()
            showingSuccessAlert = true
            
        } catch {
            errorMessage = "Failed to create grow: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - Preview Provider

struct CreateGrowFromSeedView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let cultivar = Cultivar(context: context)
        cultivar.name = "Test Tomato"
        cultivar.family = "Solanaceae"
        cultivar.growingDays = "75-85"
        cultivar.isOrganicCertified = true
        
        let seed = SeedLibrary.createFromCultivar(cultivar, in: context)
        seed.seedName = "Organic Tomato Seeds"
        seed.quantity = 10
        seed.unit = "packets"
        
        return CreateGrowFromSeedView(seed: seed, isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
