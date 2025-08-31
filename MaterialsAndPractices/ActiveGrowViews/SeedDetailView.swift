//
//  SeedDetailView.swift
//  MaterialsAndPractices
//
//  Detailed view for viewing and editing seed library entries.
//  Provides comprehensive seed information management with organic
//  compliance tracking and supplier relationship management.
//
//  Features:
//  - Complete seed information editing
//  - Organic certification status management
//  - Supplier relationship editing
//  - Quality tracking and testing history
//  - Storage location management
//  - Related grows tracking
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Detailed view for viewing and editing seed library entries
/// Provides comprehensive seed management with organic compliance tracking
struct SeedDetailView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    @ObservedObject var seed: SeedLibrary
    @Binding var isPresented: Bool
    
    // MARK: - State Properties
    
    @State private var isEditing = false
    @State private var editedSeedName: String = ""
    @State private var editedQuantity: String = ""
    @State private var editedUnit: String = ""
    @State private var editedLotNumber: String = ""
    @State private var editedOrigin: String = ""
    @State private var editedStorageLocation: String = ""
    @State private var editedNotes: String = ""
    @State private var editedPurchasedDate = Date()
    @State private var editedProductionYear: Int = 2024
    @State private var editedIsCertifiedOrganic = false
    @State private var editedIsGMO = false
    @State private var editedIsUntreated = true
    @State private var editedIntendedUse = "Production"
    @State private var editedGerminationRate: String = ""
    @State private var editedGerminationTestDate: Date?
    @State private var hasGerminationTest = false
    
    // UI state
    @State private var showingSupplierSelection = false
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingCreateGrow = false
    
    // MARK: - Computed Properties
    
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
                if isEditing {
                    editingSections
                } else {
                    viewingSections
                }
            }
            .navigationTitle(isEditing ? "Edit Seed" : seed.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing {
                            cancelEditing()
                        } else {
                            isPresented = false
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                    }
                }
            }
        }
        .alert("Delete Seed", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteSeed()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete this seed from your library. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingSupplierSelection) {
            if let cultivar = seed.cultivar {
                SupplierSelectionView(
                    cultivar: cultivar,
                    isPresented: $showingSupplierSelection,
                    onSupplierSelected: { supplier in
                        seed.supplierSource = supplier
                    }
                )
            }
        }
        .sheet(isPresented: $showingCreateGrow) {
            CreateGrowFromSeedView(seed: seed, isPresented: $showingCreateGrow)
        }
    }
    
    // MARK: - Viewing Sections
    
    @ViewBuilder
    private var viewingSections: some View {
        // Basic information section
        basicInfoViewSection
        
        // Cultivar information section
        cultivarInfoSection
        
        // Supplier information section
        supplierInfoSection
        
        // Certification section
        certificationViewSection
        
        // Quality tracking section
        qualityViewSection
        
        // Storage section
        storageViewSection
        
        // Related grows section
        relatedGrowsSection
        
        // Actions section
        actionsSection
    }
    
    // MARK: - Editing Sections
    
    @ViewBuilder
    private var editingSections: some View {
        // Basic information editing
        basicInfoEditSection
        
        // Certification editing
        certificationEditSection
        
        // Quality tracking editing
        qualityEditSection
        
        // Storage editing
        storageEditSection
    }
    
    // MARK: - View Section Components
    
    private var basicInfoViewSection: some View {
        Section("Seed Information") {
            HStack {
                Text("Name")
                Spacer()
                Text(seed.seedName ?? "Unknown")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            HStack {
                Text("Quantity")
                Spacer()
                Text(seed.quantityDisplay)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if let lotNumber = seed.lotNumber {
                HStack {
                    Text("Lot Number")
                    Spacer()
                    Text(lotNumber)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            if let origin = seed.origin {
                HStack {
                    Text("Origin")
                    Spacer()
                    Text(origin)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            if let purchasedDate = seed.purchasedDate {
                HStack {
                    Text("Purchased")
                    Spacer()
                    Text(purchasedDate, style: .date)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            HStack {
                Text("Production Year")
                Spacer()
                Text("\(seed.productionYear)")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if let intendedUse = seed.intendedUse {
                HStack {
                    Text("Intended Use")
                    Spacer()
                    Text(intendedUse)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    private var cultivarInfoSection: some View {
        Section("Cultivar") {
            if let cultivar = seed.cultivar {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(cultivar.displayName)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.semibold)
                    
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
            } else {
                Text("No cultivar associated")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var supplierInfoSection: some View {
        Section("Supplier") {
            if let supplier = seed.supplierSource {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(supplier.name ?? "Unknown Supplier")
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.semibold)
                    
                    if let contactPerson = supplier.contactPerson {
                        Text(contactPerson)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if supplier.isOrganicCertified {
                        Text("Organic Certified Supplier")
                            .font(AppTheme.Typography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.organicPractice)
                    }
                }
            } else {
                Text("No supplier associated")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var certificationViewSection: some View {
        Section("Certification Status") {
            HStack {
                Text("Compliance Status")
                Spacer()
                Text(seed.complianceStatus)
                    .foregroundColor(seed.meetsOrganicCompliance ? AppTheme.Colors.organicPractice : AppTheme.Colors.warning)
                    .font(AppTheme.Typography.labelMedium)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Certified Organic")
                Spacer()
                Image(systemName: seed.isCertifiedOrganic ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(seed.isCertifiedOrganic ? AppTheme.Colors.organicPractice : AppTheme.Colors.textTertiary)
            }
            
            HStack {
                Text("Contains GMO")
                Spacer()
                Image(systemName: seed.isGMO ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(seed.isGMO ? AppTheme.Colors.error : AppTheme.Colors.organicPractice)
            }
            
            HStack {
                Text("Untreated")
                Spacer()
                Image(systemName: seed.isUntreated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(seed.isUntreated ? AppTheme.Colors.organicPractice : AppTheme.Colors.warning)
            }
        }
    }
    
    private var qualityViewSection: some View {
        Section("Quality Information") {
            if seed.germinationRate > 0 {
                HStack {
                    Text("Germination Rate")
                    Spacer()
                    Text("\(Int(seed.germinationRate))%")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            if let testDate = seed.germinationTestDate {
                HStack {
                    Text("Test Date")
                    Spacer()
                    Text(testDate, style: .date)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                HStack {
                    Text("Test Current")
                    Spacer()
                    Image(systemName: seed.isGerminationTestCurrent ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(seed.isGerminationTestCurrent ? AppTheme.Colors.organicPractice : AppTheme.Colors.warning)
                }
            }
            
            HStack {
                Text("Seed Age")
                Spacer()
                Text(seed.isExpired ? "Expired" : "Current")
                    .foregroundColor(seed.isExpired ? AppTheme.Colors.error : AppTheme.Colors.organicPractice)
                    .fontWeight(.medium)
            }
        }
    }
    
    private var storageViewSection: some View {
        Section("Storage & Notes") {
            if let storageLocation = seed.storageLocation {
                HStack {
                    Text("Storage Location")
                    Spacer()
                    Text(storageLocation)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            if let notes = seed.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Notes")
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                    
                    Text(notes)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    private var relatedGrowsSection: some View {
        Section("Related Grows") {
            if seed.growsArray.isEmpty {
                Text("No grows using this seed")
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } else {
                ForEach(seed.growsArray, id: \.objectID) { grow in
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                            Text(grow.displayName)
                                .font(AppTheme.Typography.bodyMedium)
                            
                            if let plantedDate = grow.plantedDate {
                                Text("Planted: \(plantedDate, style: .date)")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        if grow.isActive {
                            Text("Active")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.organicPractice)
                        } else {
                            Text("Completed")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        Section {
            Button("Create Grow from This Seed") {
                showingCreateGrow = true
            }
            .foregroundColor(AppTheme.Colors.primary)
            
            Button("Delete Seed") {
                showingDeleteAlert = true
            }
            .foregroundColor(AppTheme.Colors.error)
        }
    }
    
    // MARK: - Edit Section Components
    
    private var basicInfoEditSection: some View {
        Section("Seed Information") {
            TextField("Seed Name", text: $editedSeedName)
            
            HStack {
                TextField("Quantity", text: $editedQuantity)
                    .keyboardType(.decimalPad)
                
                Picker("Unit", selection: $editedUnit) {
                    ForEach(availableUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            TextField("Lot Number", text: $editedLotNumber)
            TextField("Origin/Source", text: $editedOrigin)
            TextField("Storage Location", text: $editedStorageLocation)
            
            DatePicker("Purchase Date", selection: $editedPurchasedDate, displayedComponents: .date)
            
            Stepper("Production Year: \(editedProductionYear)", value: $editedProductionYear, in: 2020...2030)
            
            Picker("Intended Use", selection: $editedIntendedUse) {
                ForEach(availableIntendedUses, id: \.self) { use in
                    Text(use).tag(use)
                }
            }
        }
    }
    
    private var certificationEditSection: some View {
        Section("Certification & Compliance") {
            Toggle("Certified Organic", isOn: $editedIsCertifiedOrganic)
            Toggle("Contains GMO", isOn: $editedIsGMO)
            Toggle("Untreated Seeds", isOn: $editedIsUntreated)
        }
    }
    
    private var qualityEditSection: some View {
        Section("Quality Tracking") {
            Toggle("Germination Test Performed", isOn: $hasGerminationTest)
            
            if hasGerminationTest {
                HStack {
                    TextField("Germination Rate (%)", text: $editedGerminationRate)
                        .keyboardType(.decimalPad)
                    
                    Text("%")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                DatePicker("Test Date", selection: Binding(
                    get: { editedGerminationTestDate ?? Date() },
                    set: { editedGerminationTestDate = $0 }
                ), displayedComponents: .date)
            }
        }
    }
    
    private var storageEditSection: some View {
        Section("Storage & Notes") {
            TextField("Storage Location", text: $editedStorageLocation)
            
            TextField("Notes", text: $editedNotes, axis: .vertical)
                .lineLimit(3...5)
        }
    }
    
    // MARK: - Actions
    
    private func startEditing() {
        editedSeedName = seed.seedName ?? ""
        editedQuantity = "\(seed.quantity)"
        editedUnit = seed.unit ?? "packets"
        editedLotNumber = seed.lotNumber ?? ""
        editedOrigin = seed.origin ?? ""
        editedStorageLocation = seed.storageLocation ?? ""
        editedNotes = seed.notes ?? ""
        editedPurchasedDate = seed.purchasedDate ?? Date()
        editedProductionYear = Int(seed.productionYear)
        editedIsCertifiedOrganic = seed.isCertifiedOrganic
        editedIsGMO = seed.isGMO
        editedIsUntreated = seed.isUntreated
        editedIntendedUse = seed.intendedUse ?? "Production"
        editedGerminationRate = seed.germinationRate > 0 ? "\(seed.germinationRate)" : ""
        editedGerminationTestDate = seed.germinationTestDate
        hasGerminationTest = seed.germinationTestDate != nil
        
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
    }
    
    private func saveChanges() {
        do {
            seed.seedName = editedSeedName
            seed.quantity = Double(editedQuantity) ?? 0
            seed.unit = editedUnit
            seed.lotNumber = editedLotNumber.isEmpty ? nil : editedLotNumber
            seed.origin = editedOrigin.isEmpty ? nil : editedOrigin
            seed.storageLocation = editedStorageLocation.isEmpty ? nil : editedStorageLocation
            seed.notes = editedNotes.isEmpty ? nil : editedNotes
            seed.purchasedDate = editedPurchasedDate
            seed.productionYear = Int16(editedProductionYear)
            seed.isCertifiedOrganic = editedIsCertifiedOrganic
            seed.isGMO = editedIsGMO
            seed.isUntreated = editedIsUntreated
            seed.intendedUse = editedIntendedUse
            
            if hasGerminationTest {
                seed.germinationRate = Double(editedGerminationRate) ?? 0
                seed.germinationTestDate = editedGerminationTestDate
            } else {
                seed.germinationRate = 0
                seed.germinationTestDate = nil
            }
            
            seed.updateModificationDate()
            
            try viewContext.save()
            isEditing = false
            
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    private func deleteSeed() {
        do {
            viewContext.delete(seed)
            try viewContext.save()
            isPresented = false
        } catch {
            errorMessage = "Failed to delete seed: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - Preview Provider

struct SeedDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let seed = SeedLibrary(context: context)
        seed.seedName = "Test Tomato Seeds"
        seed.quantity = 10
        seed.unit = "packets"
        seed.isCertifiedOrganic = true
        
        return SeedDetailView(seed: seed, isPresented: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}