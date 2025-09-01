//
//  CreateSupplierView.swift
//  MaterialsAndPractices
//
//  Comprehensive supplier creation view with organic certification tracking.
//  Provides full contact information management and certification compliance
//  features for complete supplier source traceability.
//
//  Features:
//  - Complete contact information entry
//  - Organic certification status and expiry tracking
//  - Supplier type categorization
//  - Form validation and error handling
//  - Integration with supplier management system
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// View for creating new suppliers with comprehensive contact and certification information
/// Supports organic certification compliance and complete supplier source tracking
struct CreateSupplierView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    let supplierKind: SupplierKind
    @Binding var isPresented: Bool
    let onSupplierCreated: (SupplierSource) -> Void
    
    // MARK: - State Properties
    
    // Basic Information
    @State private var name: String = ""
    @State private var contactPerson: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var websiteURL: String = ""
    @State private var faxNumber: String = ""
    
    // Address Information
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    
    // Certification Information
    @State private var isOrganicCertified: Bool = false
    @State private var certificationNumber: String = ""
    @State private var certificationExpiryDate: Date = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
    
    // Additional Information
    @State private var notes: String = ""
    
    // Validation
    @State private var showingValidationErrors = false
    @State private var validationErrors: [String] = []
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!isOrganicCertified || (!certificationNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                basicInformationSection
                
                // Contact Information Section
                contactInformationSection
                
                // Address Information Section
                addressInformationSection
                
                // Certification Section
                certificationSection
                
                // Additional Information Section
                additionalInformationSection
                
                // Save Button Section
                saveSection
            }
            .navigationTitle("New \(supplierKind.displayName) Supplier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Validation Errors", isPresented: $showingValidationErrors) {
                Button("OK") { }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
        }
    }
    
    // MARK: - View Components
    
    /// Basic supplier information
    private var basicInformationSection: some View {
        Section("Basic Information") {
            TextField("Company Name *", text: $name)
            
            HStack {
                Image(systemName: supplierKind.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Supplier Type")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(supplierKind.displayName)
                    .foregroundColor(.secondary)
            }
            
            TextField("Contact Person", text: $contactPerson)
        }
    }
    
    /// Contact information section
    private var contactInformationSection: some View {
        Section("Contact Information") {
            TextField("Phone Number", text: $phoneNumber)
                .keyboardType(.phonePad)
            
            TextField("Email Address", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Website URL", text: $websiteURL)
                .keyboardType(.URL)
                .autocapitalization(.none)
            
            TextField("Fax Number", text: $faxNumber)
                .keyboardType(.phonePad)
        }
    }
    
    /// Address information section
    private var addressInformationSection: some View {
        Section("Address") {
            TextField("Street Address", text: $address)
            
            HStack {
                TextField("City", text: $city)
                TextField("State", text: $state)
                    .frame(maxWidth: 80)
            }
            
            TextField("Zip Code", text: $zipCode)
                .keyboardType(.numberPad)
        }
    }
    
    /// Organic certification section
    private var certificationSection: some View {
        Section("Organic Certification") {
            HStack {
                Toggle(isOn: $isOrganicCertified) {
                    HStack {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(isOrganicCertified ? .green : .gray)
                        Text("Organic Certified")
                    }
                }
            }
            
            if isOrganicCertified {
                TextField("Certification Number *", text: $certificationNumber)
                    .background(certificationNumber.isEmpty ? Color.red.opacity(0.1) : Color.clear)
                
                DatePicker("Certification Expiry", selection: $certificationExpiryDate, displayedComponents: .date)
                
                // Expiry warning
                if certificationExpiryDate < Date() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Certification has expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else if let daysToExpiry = Calendar.current.dateComponents([.day], from: Date(), to: certificationExpiryDate).day,
                          daysToExpiry <= 90 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Expires in \(daysToExpiry) days")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    /// Additional information section
    private var additionalInformationSection: some View {
        Section("Additional Information") {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ZStack(alignment: .topLeading) {
                    if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Any additional information about this supplier...")
                            .foregroundColor(Color.secondary.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $notes)
                        .frame(minHeight: 90, maxHeight: 180)
                }
            }
        }
    }
    
    /// Save button section
    private var saveSection: some View {
        Section {
            Button(action: saveSupplier) {
                HStack {
                    Spacer()
                    Text("Create Supplier")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .disabled(!isFormValid)
            .listRowBackground(isFormValid ? Color.blue : Color.gray)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Validate form data
    private func validateForm() -> [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Company name is required")
        }
        
        if !email.isEmpty && !email.contains("@") {
            errors.append("Please enter a valid email address")
        }
        
        if isOrganicCertified {
            if certificationNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Certification number is required for organic certified suppliers")
            }
            
            if certificationExpiryDate < Date() {
                errors.append("Certification expiry date cannot be in the past")
            }
        }
        
        return errors
    }
    
    /// Save the new supplier to Core Data
    private func saveSupplier() {
        // Validate form
        let errors = validateForm()
        if !errors.isEmpty {
            validationErrors = errors
            showingValidationErrors = true
            return
        }
        
        // Create new supplier
        let newSupplier = SupplierSource(context: viewContext)
      
        newSupplier.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.supplierType = supplierKind.rawValue
        newSupplier.contactName = contactPerson.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.websiteURL = websiteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.faxNumber = faxNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.state = state.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.zipCode = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        newSupplier.isOrganicCertified = isOrganicCertified
        newSupplier.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isOrganicCertified {
            newSupplier.certificationNumber = certificationNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            newSupplier.certificationExpiryDate = certificationExpiryDate
        }
        
        do {
            try viewContext.save()
            onSupplierCreated(newSupplier)
            isPresented = false
        } catch {
            // Handle the error appropriately
            print("Error saving supplier: \(error)")
        }
    }
}

// MARK: - Preview Provider

struct CreateSupplierView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSupplierView(
            supplierKind: .seed,
            isPresented: .constant(true),
            onSupplierCreated: { _ in }
        )
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
