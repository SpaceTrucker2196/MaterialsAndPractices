//
//  SeedCreationView.swift
//  MaterialsAndPractices
//
//  View for creating a new seed library entry from a selected cultivar.
//  Provides comprehensive seed information capture with supplier selection,
//  organic certification tracking, and compliance documentation.
//
//  Features:
//  - Pre-populated cultivar information
//  - Supplier selection and creation
//  - Organic certification tracking
//  - Seed quality and quantity tracking
//  - Storage location management
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData




/// Main view for creating a seed library entry from a selected cultivar
struct SeedCreationView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    let cultivar: Cultivar
    @Binding var isPresented: Bool
    
    // MARK: - State Properties
    
    @State private var seedName: String = ""
    @State private var quantity: String = "0"
    @State private var unit: String = "packets"
    @State private var lotNumber: String = ""
    @State private var origin: String = ""
    @State private var storageLocation: String = ""
    @State private var notes: String = ""
    @State private var purchasedDate = Date()
    @State private var productionYear: Int = Calendar.current.component(.year, from: Date())
    @State private var isCertifiedOrganic = false
    @State private var isGMO = false
    @State private var isUntreated = true
    @State private var intendedUse = "Production"
    
    // Supplier selection
    @State private var selectedSupplier: SupplierSource?
    @State private var showingSupplierSelection = false
    @State private var showingNewSupplierCreation = false
    
    // Quality tracking
    @State private var germinationRate: String = ""
    @State private var germinationTestDate: Date?
    @State private var hasGerminationTest = false
    
    // UI state
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // MARK: - Fetch Requests
    
    @FetchRequest var seedSuppliers: FetchedResults<SupplierSource>
    
    // MARK: - Initialization
    
    init(cultivar: Cultivar, isPresented: Binding<Bool>) {
        self.cultivar = cultivar
        self._isPresented = isPresented
        
        // Initialize fetch request for seed suppliers
        self._seedSuppliers = FetchRequest(
            entity: SupplierSource.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)],
            predicate: NSPredicate(format: "supplierType == %@", SupplierKind.seed.rawValue)
        )
        
        // Pre-populate seed name with cultivar name
        self._seedName = State(initialValue: cultivar.displayName)
        self._isCertifiedOrganic = State(initialValue: cultivar.isOrganicCertified)
    }
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !seedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedSupplier != nil &&
        Double(quantity) != nil
    }
    
    var availableUnits: [String] {
        ["packets", "ounces", "pounds", "grams", "kilograms", "seeds"]
    }
    
    var availableIntendedUses: [String] {
        ["Production", "Trial", "Cover Crop", "Green Manure", "Research"]
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Cultivar info section
                cultivarInfoSection
                
                // Basic seed information
                basicInfoSection
                
                // Supplier section
                supplierSection
                
                // Certification and compliance
                certificationSection
                
                // Quality tracking
                qualitySection
                
                // Storage and notes
                storageSection
                
                // Save button
                saveSection
            }
            .navigationTitle("New Seed Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSeed()
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
            Text("Seed has been added to your library successfully.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingSupplierSelection) {
            SupplierSelectionView(
                cultivar: cultivar,
                isPresented: $showingSupplierSelection,
                onSupplierSelected: { supplier in
                    selectedSupplier = supplier
                }
            )
        }
        .sheet(isPresented: $showingNewSupplierCreation) {
            CreateSupplierView(
                supplierKind: .seed,
                isPresented: $showingNewSupplierCreation,
                onSupplierCreated: { supplier in
                    selectedSupplier = supplier
                }
            )
        }
    }
    
    // MARK: - View Sections
    
    /// Cultivar information display
    private var cultivarInfoSection: some View {
        Section("Source Cultivar") {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(cultivar.displayName)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let family = cultivar.family {
                        Text(family)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if cultivar.isOrganicCertified {
                        Text("Organic Certified Cultivar")
                            .font(AppTheme.Typography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.organicPractice)
                    }
                }
                
                Spacer()
                
                Text(cultivar.emoji ?? "🌱")
                    .font(.largeTitle)
            }
        }
    }
    
    /// Basic seed information inputs
    private var basicInfoSection: some View {
        Section("Seed Information") {
            TextField("Seed Name", text: $seedName)
            
            HStack {
                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)
                
                Picker("Unit", selection: $unit) {
                    ForEach(availableUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            TextField("Lot Number", text: $lotNumber)
            
            TextField("Origin/Source", text: $origin)
            
            DatePicker("Purchase Date", selection: $purchasedDate, displayedComponents: .date)
            
            Stepper("Production Year: \(productionYear)", value: $productionYear, in: 2020...2030)
            
            Picker("Intended Use", selection: $intendedUse) {
                ForEach(availableIntendedUses, id: \.self) { use in
                    Text(use).tag(use)
                }
            }
        }
    }
    
    /// Supplier selection section
    private var supplierSection: some View {
        Section("Supplier") {
            if let supplier = selectedSupplier {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                        Text(supplier.name ?? "Unknown Supplier")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if supplier.isOrganicCertified {
                            Text("Organic Certified")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.organicPractice)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingSupplierSelection = true
                    }
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            } else {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Button("Select Supplier") {
                        showingSupplierSelection = true
                    }
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
                    
                    Button("Create New Supplier") {
                        showingNewSupplierCreation = true
                    }
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.secondary)
                }
            }
        }
    }
    
    /// Certification and compliance section
    private var certificationSection: some View {
        Section("Certification & Compliance") {
            Toggle("Certified Organic", isOn: $isCertifiedOrganic)
            Toggle("Contains GMO", isOn: $isGMO)
            Toggle("Untreated Seeds", isOn: $isUntreated)
            
            if !isCertifiedOrganic || isGMO || !isUntreated {
                Text("⚠️ This seed may not meet organic certification requirements")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.warning)
            }
        }
    }
    
    /// Quality tracking section
    private var qualitySection: some View {
        Section("Quality Tracking") {
            Toggle("Germination Test Performed", isOn: $hasGerminationTest)
            
            if hasGerminationTest {
                HStack {
                    TextField("Germination Rate (%)", text: $germinationRate)
                        .keyboardType(.decimalPad)
                    
                    Text("%")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                DatePicker("Test Date", selection: Binding(
                    get: { germinationTestDate ?? Date() },
                    set: { germinationTestDate = $0 }
                ), displayedComponents: .date)
            }
        }
    }
    
    /// Storage and notes section
    private var storageSection: some View {
        Section("Storage & Notes") {
            TextField("Storage Location", text: $storageLocation)
            
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...5)
        }
    }
    
    /// Save button section
    private var saveSection: some View {
        Section {
            Button("Save to Seed Library") {
                saveSeed()
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
    
    /// Save the seed to Core Data
    private func saveSeed() {
        guard isFormValid else { return }
        
        do {
            let seed = SeedLibrary.createFromCultivar(cultivar, in: viewContext)
            
            // Set basic information
            seed.seedName = seedName.trimmingCharacters(in: .whitespacesAndNewlines)
            seed.quantity = Double(quantity) ?? 0.0
            seed.unit = unit
            seed.lotNumber = lotNumber.isEmpty ? nil : lotNumber
            seed.origin = origin.isEmpty ? nil : origin
            seed.storageLocation = storageLocation.isEmpty ? nil : storageLocation
            seed.notes = notes.isEmpty ? nil : notes
            seed.purchasedDate = purchasedDate
            seed.productionYear = Int16(productionYear)
            seed.intendedUse = intendedUse
            
            // Set supplier
            seed.supplierSource = selectedSupplier
            
            // Set certification
            seed.isCertifiedOrganic = isCertifiedOrganic
            seed.isGMO = isGMO
            seed.isUntreated = isUntreated
            
            // Set quality data
            if hasGerminationTest {
                seed.germinationRate = Double(germinationRate) ?? 0.0
                seed.germinationTestDate = germinationTestDate
            }
            
            try viewContext.save()
            showingSuccessAlert = true
            
        } catch {
            errorMessage = "Failed to save seed: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - Preview Provider

struct SeedCreationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let cultivar = Cultivar(context: context)
        cultivar.name = "Test Tomato"
        cultivar.family = "Solanaceae"
        cultivar.isOrganicCertified = true
        
        return SeedCreationView(cultivar: cultivar, isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
