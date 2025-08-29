//
//  SupplierDetailView.swift
//  MaterialsAndPractices
//
//  Detailed supplier information view with editing capabilities and relationship management.
//  Provides comprehensive supplier data display with organic certification tracking
//  and integration with farm management workflows.
//
//  Features:
//  - Complete supplier information display
//  - Organic certification status and expiry monitoring
//  - Associated cultivars and amendments listing
//  - Edit mode for supplier information updates
//  - Contact information management
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Detailed view for individual supplier with editing capabilities
/// Provides comprehensive supplier information and relationship management
struct SupplierDetailView: View {
    // MARK: - Environment Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    @ObservedObject var supplier: SupplierSource
    
    // MARK: - State Properties
    
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedContactPerson: String = ""
    @State private var editedPhoneNumber: String = ""
    @State private var editedEmail: String = ""
    @State private var editedWebsiteURL: String = ""
    @State private var editedAddress: String = ""
    @State private var editedCity: String = ""
    @State private var editedState: String = ""
    @State private var editedZipCode: String = ""
    @State private var editedIsOrganicCertified: Bool = false
    @State private var editedCertificationNumber: String = ""
    @State private var editedCertificationExpiryDate: Date = Date()
    @State private var editedNotes: String = ""
    
    // MARK: - Initialization
    
    init(supplier: SupplierSource) {
        self.supplier = supplier
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                supplierHeaderSection
                
                // Contact Information Section
                contactInformationSection
                
                // Address Section
                addressSection
                
                // Certification Section
                certificationSection
                
                // Associated Items Section
                associatedItemsSection
                
                // Notes Section
                if !supplier.notes?.isEmpty ?? true || isEditing {
                    notesSection
                }
            }
            .padding()
        }
        .navigationTitle(supplier.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        enterEditMode()
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Supplier header with basic information
    private var supplierHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Supplier type icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: supplier.kind.icon)
                        .foregroundColor(.blue)
                        .font(.title)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField("Company Name", text: $editedName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(supplier.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text(supplier.kind.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Certification status
                    HStack {
                        if isEditing {
                            Toggle(isOn: $editedIsOrganicCertified) {
                                Text("Organic Certified")
                            }
                        } else {
                            if supplier.isOrganicCertified {
                                Label("Organic Certified", systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("Not Certified", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Contact information section
    private var contactInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                if isEditing {
                    contactEditRow(title: "Contact Person", text: $editedContactPerson)
                    contactEditRow(title: "Phone", text: $editedPhoneNumber)
                    contactEditRow(title: "Email", text: $editedEmail)
                    contactEditRow(title: "Website", text: $editedWebsiteURL)
                } else {
                    if let contact = supplier.contactPerson, !contact.isEmpty {
                        contactDisplayRow(title: "Contact Person", value: contact, icon: "person")
                    }
                    
                    if let phone = supplier.formattedPhoneNumber {
                        contactDisplayRow(title: "Phone", value: phone, icon: "phone", action: {
                            if let url = URL(string: "tel:\(supplier.phoneNumber ?? "")") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    
                    if let email = supplier.email, !email.isEmpty {
                        contactDisplayRow(title: "Email", value: email, icon: "envelope", action: {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                    
                    if let website = supplier.websiteURLValue {
                        contactDisplayRow(title: "Website", value: website.absoluteString, icon: "globe", action: {
                            UIApplication.shared.open(website)
                        })
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Address section
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Address")
                .font(.headline)
                .foregroundColor(.primary)
            
            if isEditing {
                VStack(spacing: 8) {
                    TextField("Street Address", text: $editedAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        TextField("City", text: $editedCity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("State", text: $editedState)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 80)
                    }
                    
                    TextField("Zip Code", text: $editedZipCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } else {
                if !supplier.fullAddress.isEmpty {
                    Text(supplier.formattedAddressMultiLine)
                        .font(.body)
                        .foregroundColor(.primary)
                } else {
                    Text("No address provided")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Certification section
    private var certificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Organic Certification")
                .font(.headline)
                .foregroundColor(.primary)
            
            if supplier.isOrganicCertified || isEditing {
                if isEditing {
                    VStack(spacing: 8) {
                        TextField("Certification Number", text: $editedCertificationNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        DatePicker("Expiry Date", selection: $editedCertificationExpiryDate, displayedComponents: .date)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        if let certNumber = supplier.certificationNumber {
                            HStack {
                                Text("Certification Number:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(certNumber)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let expiryDate = supplier.certificationExpiryDate {
                            HStack {
                                Text("Expires:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(expiryDate, style: .date)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(supplier.isCertificationExpired ? .red : .primary)
                            }
                            
                            if let days = supplier.daysUntilExpiry {
                                if days < 0 {
                                    Label("Certification expired", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else if days <= 90 {
                                    Label("Expires in \(days) days", systemImage: "clock.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("This supplier is not organic certified")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Associated items section
    private var associatedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Associated Items")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Associated cultivars
                if let cultivars = supplier.cultivars as? Set<Cultivar>, !cultivars.isEmpty {
                    Text("Cultivars (\(cultivars.count))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(cultivars).sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.objectID) { cultivar in
                        HStack {
                            Text(cultivar.emoji ?? "🌱")
                            Text(cultivar.displayName)
                                .font(.body)
                            Spacer()
                        }
                        .padding(.leading, 16)
                    }
                }
                
                // Associated amendments
                if let amendments = supplier.cropAmendments as? Set<CropAmendment>, !amendments.isEmpty {
                    Text("Amendments (\(amendments.count))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(amendments).sorted(by: { ($0.productName ?? "") < ($1.productName ?? "") }), id: \.objectID) { amendment in
                        HStack {
                            Image(systemName: "leaf.circle")
                                .foregroundColor(.green)
                            Text(amendment.productName ?? "Unknown Amendment")
                                .font(.body)
                            Spacer()
                        }
                        .padding(.leading, 16)
                    }
                }
                
                if (supplier.cultivars?.count ?? 0) == 0 && (supplier.cropAmendments?.count ?? 0) == 0 {
                    Text("No associated items")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Notes section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            if isEditing {
                TextEditor(text: $editedNotes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            } else {
                Text(supplier.notes ?? "No notes")
                    .font(.body)
                    .foregroundColor(supplier.notes?.isEmpty ?? true ? .secondary : .primary)
                    .italic(supplier.notes?.isEmpty ?? true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func contactDisplayRow(title: String, value: String, icon: String, action: (() -> Void)? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let action = action {
                Button(value) {
                    action()
                }
                .foregroundColor(.blue)
            } else {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    private func contactEditRow(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(title, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    // MARK: - Helper Methods
    
    /// Enter edit mode and populate edit fields
    private func enterEditMode() {
        editedName = supplier.name ?? ""
        editedContactPerson = supplier.contactPerson ?? ""
        editedPhoneNumber = supplier.phoneNumber ?? ""
        editedEmail = supplier.email ?? ""
        editedWebsiteURL = supplier.websiteURL ?? ""
        editedAddress = supplier.address ?? ""
        editedCity = supplier.city ?? ""
        editedState = supplier.state ?? ""
        editedZipCode = supplier.zipCode ?? ""
        editedIsOrganicCertified = supplier.isOrganicCertified
        editedCertificationNumber = supplier.certificationNumber ?? ""
        editedCertificationExpiryDate = supplier.certificationExpiryDate ?? Date()
        editedNotes = supplier.notes ?? ""
        
        isEditing = true
    }
    
    /// Save changes to Core Data
    private func saveChanges() {
        supplier.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.contactPerson = editedContactPerson.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.phoneNumber = editedPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.email = editedEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.websiteURL = editedWebsiteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.address = editedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.city = editedCity.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.state = editedState.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.zipCode = editedZipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.isOrganicCertified = editedIsOrganicCertified
        supplier.certificationNumber = editedCertificationNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        supplier.certificationExpiryDate = editedCertificationExpiryDate
        supplier.notes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try viewContext.save()
            isEditing = false
        } catch {
            print("Error saving supplier changes: \(error)")
        }
    }
}

// MARK: - Preview Provider

struct SupplierDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let supplier = SupplierSource(context: context)
        supplier.name = "Organic Seeds Co"
        supplier.supplierType = SupplierKind.seed.rawValue
        supplier.contactPerson = "John Smith"
        supplier.phoneNumber = "5551234567"
        supplier.email = "john@organicseeds.com"
        supplier.websiteURL = "https://organicseeds.com"
        supplier.address = "123 Garden Way"
        supplier.city = "Portland"
        supplier.state = "OR"
        supplier.zipCode = "97201"
        supplier.isOrganicCertified = true
        supplier.certificationNumber = "CERT-12345"
        supplier.certificationExpiryDate = Date().addingTimeInterval(180 * 24 * 60 * 60) // 180 days
        supplier.notes = "Reliable supplier with excellent quality organic seeds."
        
        return NavigationView {
            SupplierDetailView(supplier: supplier)
        }
        .environment(\.managedObjectContext, context)
    }
}