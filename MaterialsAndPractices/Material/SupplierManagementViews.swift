//
//  SupplierManagementViews.swift
//  MaterialsAndPractices
//
//  Supporting views for supplier management including selection, creation, and detail views.
//  Provides comprehensive supplier management capabilities integrated with cultivar and 
//  amendment management workflows.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

// MARK: - Supplier Selection View

/// View for selecting existing suppliers for association with cultivars
struct SupplierSelectionView: View {
    // MARK: - Properties
    
    let cultivar: Cultivar
    @Binding var isPresented: Bool
    let onSupplierSelected: (SupplierSource) -> Void
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Fetch Request
    
    @FetchRequest var suppliers: FetchedResults<SupplierSource>
    
    // MARK: - State
    
    @State private var searchText = ""
    
    // MARK: - Initialization
    
    init(cultivar: Cultivar, isPresented: Binding<Bool>, onSupplierSelected: @escaping (SupplierSource) -> Void) {
        self.cultivar = cultivar
        self._isPresented = isPresented
        self.onSupplierSelected = onSupplierSelected
        
        // Initialize fetch request for seed suppliers
        self._suppliers = FetchRequest(
            entity: SupplierSource.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)],
            predicate: NSPredicate(format: "supplierType == %@", SupplierSource.SupplierType.seed.rawValue)
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search suppliers...")
                
                // Supplier list
                List(filteredSuppliers, id: \.id) { supplier in
                    Button(action: {
                        onSupplierSelected(supplier)
                        isPresented = false
                    }) {
                        SupplierRowView(supplier: supplier)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Supplier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredSuppliers: [SupplierSource] {
        if searchText.isEmpty {
            return Array(suppliers)
        } else {
            return suppliers.filter { supplier in
                (supplier.name?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (supplier.contactPerson?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
}

// MARK: - Create Supplier View

/// View for creating new suppliers
struct CreateSupplierView: View {
    // MARK: - Properties
    
    let supplierType: SupplierSource.SupplierType
    @Binding var isPresented: Bool
    let onSupplierCreated: (SupplierSource) -> Void
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State
    
    @State private var name = ""
    @State private var contactPerson = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var websiteURL = ""
    @State private var isOrganicCertified = false
    @State private var certificationNumber = ""
    @State private var certificationExpiryDate = Date()
    @State private var notes = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Company Name", text: $name)
                    TextField("Contact Person", text: $contactPerson)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Address") {
                    TextField("Street Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                Section("Additional Information") {
                    TextField("Website URL", text: $websiteURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Toggle("Organic Certified", isOn: $isOrganicCertified)
                    
                    if isOrganicCertified {
                        TextField("Certification Number", text: $certificationNumber)
                        DatePicker("Certification Expires", selection: $certificationExpiryDate, displayedComponents: .date)
                    }
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New \(supplierType.displayName) Supplier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSupplier()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveSupplier() {
        let supplier = SupplierSource.create(in: viewContext, name: name, type: supplierType)
        
        supplier.contactPerson = contactPerson.isEmpty ? nil : contactPerson
        supplier.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        supplier.email = email.isEmpty ? nil : email
        supplier.address = address.isEmpty ? nil : address
        supplier.city = city.isEmpty ? nil : city
        supplier.state = state.isEmpty ? nil : state
        supplier.zipCode = zipCode.isEmpty ? nil : zipCode
        supplier.websiteURL = websiteURL.isEmpty ? nil : websiteURL
        supplier.isOrganicCertified = isOrganicCertified
        supplier.certificationNumber = certificationNumber.isEmpty ? nil : certificationNumber
        supplier.certificationExpiryDate = isOrganicCertified ? certificationExpiryDate : nil
        supplier.notes = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            onSupplierCreated(supplier)
            isPresented = false
        } catch {
            print("Error saving supplier: \(error)")
        }
    }
}

// MARK: - Supplier Detail View

/// Detailed view for individual suppliers
struct SupplierDetailView: View {
    // MARK: - Properties
    
    @ObservedObject var supplier: SupplierSource
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State
    
    @State private var showingEditMode = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Header with basic info
                supplierHeaderSection
                
                // Contact information
                contactInformationSection
                
                // Certification status
                certificationSection
                
                // Associated products
                associatedProductsSection
            }
            .padding()
        }
        .navigationTitle(supplier.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditMode = true
                }
            }
        }
        .sheet(isPresented: $showingEditMode) {
            EditSupplierView(supplier: supplier, isPresented: $showingEditMode)
        }
    }
    
    // MARK: - View Components
    
    private var supplierHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: supplier.supplierTypeEnum?.icon ?? "building.2")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text(supplier.displayName)
                        .font(AppTheme.Typography.displaySmall)
                        .fontWeight(.bold)
                    
                    if let type = supplier.supplierTypeEnum {
                        Text(type.displayName)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var contactInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Contact Information")
                .font(AppTheme.Typography.headlineMedium)
                .fontWeight(.semibold)
            
            VStack(spacing: AppTheme.Spacing.small) {
                if let contact = supplier.contactPerson {
                    InfoRow(label: "Contact Person", value: contact, icon: "person.fill")
                }
                
                if let phone = supplier.phoneNumber {
                    InfoRow(label: "Phone", value: phone, icon: "phone.fill")
                }
                
                if let email = supplier.email {
                    InfoRow(label: "Email", value: email, icon: "envelope.fill")
                }
                
                if !supplier.fullAddress.isEmpty {
                    InfoRow(label: "Address", value: supplier.fullAddress, icon: "location.fill")
                }
                
                if let website = supplier.websiteURL {
                    InfoRow(label: "Website", value: website, icon: "globe")
                }
            }
        }
    }
    
    private var certificationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Certification Status")
                .font(AppTheme.Typography.headlineMedium)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: supplier.isOrganicCertified ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundColor(supplier.isOrganicCertified ? AppTheme.Colors.organicPractice : AppTheme.Colors.textSecondary)
                    
                    Text(supplier.certificationStatusText)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                if let certNumber = supplier.certificationNumber {
                    InfoRow(label: "Certification Number", value: certNumber, icon: "number")
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private var associatedProductsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Associated Products")
                .font(AppTheme.Typography.headlineMedium)
                .fontWeight(.semibold)
            
            if supplier.productCount == 0 {
                Text("No associated products")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("\(supplier.cultivarsArray.count) cultivar(s)")
                        .font(AppTheme.Typography.bodyMedium)
                    
                    Text("\(supplier.cropAmendmentsArray.count) amendment(s)")
                        .font(AppTheme.Typography.bodyMedium)
                }
                .padding()
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
}

// MARK: - Supporting Views

/// Search bar component
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

/// Information row component
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(label)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(value)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Edit Supplier View (Placeholder)

/// Edit supplier view (placeholder implementation)
struct EditSupplierView: View {
    @ObservedObject var supplier: SupplierSource
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Edit Supplier - Coming Soon")
                .navigationTitle("Edit Supplier")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

// MARK: - Additional Placeholder Views

/// Create grow from cultivar view (placeholder)
struct CreateGrowFromCultivarView: View {
    let cultivar: Cultivar
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Create Grow from \(cultivar.displayName) - Coming Soon")
                .navigationTitle("New Grow")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

/// Cultivar grows list view (placeholder)
struct CultivarGrowsListView: View {
    let cultivar: Cultivar
    
    var body: some View {
        List {
            ForEach(cultivar.growsArray, id: \.self) { grow in
                Text(grow.title ?? "Untitled Grow")
            }
        }
        .navigationTitle("Grows for \(cultivar.displayName)")
    }
}

/// Create amendment view (placeholder)
struct CreateAmendmentView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Text("Create New Amendment - Coming Soon")
                .navigationTitle("New Amendment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

/// Amendment detail view (placeholder)
struct AmendmentDetailView: View {
    let amendment: CropAmendment
    
    var body: some View {
        Text("Amendment Detail for \(amendment.displayName) - Coming Soon")
            .navigationTitle(amendment.displayName)
    }
}