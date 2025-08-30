//
//  LabManagementViews.swift
//  MaterialsAndPractices
//
//  Views for selecting and creating laboratory entries for soil testing.
//  Manages lab contact information and selection interface.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

// MARK: - Lab Selection View

/// View for selecting existing lab or creating new one
struct LabSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Lab.name, ascending: true)],
        animation: .default
    )
    private var labs: FetchedResults<Lab>
    
    @Binding var selectedLab: Lab?
    let onNewLab: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(labs, id: \.id) { lab in
                        LabRow(lab: lab) {
                            selectedLab = lab
                            dismiss()
                        }
                    }
                } header: {
                    Text("Available Laboratories")
                }
                
                Section {
                    Button(action: onNewLab) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("Add New Laboratory")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Laboratory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Lab Row Component

/// Individual lab row for selection
struct LabRow: View {
    let lab: Lab
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(lab.name ?? "Unnamed Lab")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let phone = lab.phone, !phone.isEmpty {
                    Text(phone)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                if let address = lab.address, !address.isEmpty {
                    Text(address)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Lab View

/// Form for creating new laboratory entries
struct CreateLabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let onLabCreated: (Lab) -> Void
    
    @State private var labName = ""
    @State private var labPhone = ""
    @State private var labEmail = ""
    @State private var labAddress = ""
    @State private var labWebsite = ""
    @State private var labNotes = ""
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Laboratory Information") {
                    TextField("Laboratory Name", text: $labName)
                    
                    TextField("Phone Number", text: $labPhone)
                        .keyboardType(.phonePad)
                    
                    TextField("Email Address", text: $labEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Contact Details") {
                    TextField("Address", text: $labAddress, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Website", text: $labWebsite)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Notes") {
                    TextField("Additional notes about this laboratory", text: $labNotes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("New Laboratory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLab()
                    }
                    .disabled(labName.isEmpty)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func saveLab() {
        guard !labName.isEmpty else {
            validationMessage = "Laboratory name is required"
            showingValidationAlert = true
            return
        }
        
        let lab = Lab(context: viewContext)
        lab.id = UUID()
        lab.name = labName
        lab.phone = labPhone.isEmpty ? nil : labPhone
        lab.email = labEmail.isEmpty ? nil : labEmail
        lab.address = labAddress.isEmpty ? nil : labAddress
        lab.website = labWebsite.isEmpty ? nil : labWebsite
        lab.notes = labNotes.isEmpty ? nil : labNotes
        
        do {
            try viewContext.save()
            onLabCreated(lab)
        } catch {
            validationMessage = "Failed to save laboratory: \(error.localizedDescription)"
            showingValidationAlert = true
        }
    }
}

// MARK: - Lab Detail View

/// Detailed view for laboratory information
struct LabDetailView: View {
    let lab: Lab
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                
                // Basic Information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    SectionHeader(title: "Laboratory Information")
                    
                    VStack(spacing: AppTheme.Spacing.small) {
                        InfoBlock(label: "Name:") {
                            Text(lab.name ?? "Unknown")
                        }
                        
                        if let phone = lab.phone, !phone.isEmpty {
                            InfoBlock(label: "Phone:") {
                                Button(phone) {
                                    if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                        
                        if let email = lab.email, !email.isEmpty {
                            InfoBlock(label: "Email:") {
                                Button(email) {
                                    if let url = URL(string: "mailto:\(email)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                        
                        if let website = lab.website, !website.isEmpty {
                            InfoBlock(label: "Website:") {
                                Button(website) {
                                    if let url = URL(string: website) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                        
                        if let address = lab.address, !address.isEmpty {
                            InfoBlock(label: "Address:") {
                                Text(address)
                            }
                        }
                        
                        if let notes = lab.notes, !notes.isEmpty {
                            InfoBlock(label: "Notes:") {
                                Text(notes)
                            }
                        }
                    }
                }
                
                // Soil Tests Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    SectionHeader(title: "Soil Tests")
                    
                    if let soilTests = lab.soilTests?.allObjects as? [SoilTest],
                       !soilTests.isEmpty {
                        ForEach(soilTests.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }), id: \.id) { soilTest in
                            LabSoilTestRow(soilTest: soilTest)
                        }
                    } else {
                        Text("No soil tests from this laboratory")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(lab.name ?? "Laboratory")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditLabView(lab: lab, isPresented: $isEditing)
        }
    }
}

// MARK: - Lab Soil Test Row

/// Row showing soil test associated with a lab
struct LabSoilTestRow: View {
    let soilTest: SoilTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            HStack {
                Text(soilTest.field?.name ?? "Unknown Field")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                if let date = soilTest.date {
                    Text(date, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            HStack {
                Text("pH: \(soilTest.ph, specifier: "%.1f")")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text("OM: \(soilTest.omPct, specifier: "%.1f")%")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

// MARK: - Edit Lab View

/// Form for editing existing laboratory information
struct EditLabView: View {
    let lab: Lab
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var labName: String
    @State private var labPhone: String
    @State private var labEmail: String
    @State private var labAddress: String
    @State private var labWebsite: String
    @State private var labNotes: String
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    init(lab: Lab, isPresented: Binding<Bool>) {
        self.lab = lab
        self._isPresented = isPresented
        self._labName = State(initialValue: lab.name ?? "")
        self._labPhone = State(initialValue: lab.phone ?? "")
        self._labEmail = State(initialValue: lab.email ?? "")
        self._labAddress = State(initialValue: lab.address ?? "")
        self._labWebsite = State(initialValue: lab.website ?? "")
        self._labNotes = State(initialValue: lab.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Laboratory Information") {
                    TextField("Laboratory Name", text: $labName)
                    
                    TextField("Phone Number", text: $labPhone)
                        .keyboardType(.phonePad)
                    
                    TextField("Email Address", text: $labEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Contact Details") {
                    TextField("Address", text: $labAddress, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Website", text: $labWebsite)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Notes") {
                    TextField("Additional notes about this laboratory", text: $labNotes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Edit Laboratory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLab()
                    }
                    .disabled(labName.isEmpty)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func saveLab() {
        guard !labName.isEmpty else {
            validationMessage = "Laboratory name is required"
            showingValidationAlert = true
            return
        }
        
        lab.name = labName
        lab.phone = labPhone.isEmpty ? nil : labPhone
        lab.email = labEmail.isEmpty ? nil : labEmail
        lab.address = labAddress.isEmpty ? nil : labAddress
        lab.website = labWebsite.isEmpty ? nil : labWebsite
        lab.notes = labNotes.isEmpty ? nil : labNotes
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            validationMessage = "Failed to save laboratory: \(error.localizedDescription)"
            showingValidationAlert = true
        }
    }
}

// MARK: - Preview Provider

struct LabManagementViews_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let lab = Lab(context: context)
        lab.name = "AgriTest Labs"
        lab.phone = "(555) 123-4567"
        lab.email = "info@agritest.com"
        lab.address = "123 Farm Road, Agriculture City, AG 12345"
        
        return LabDetailView(lab: lab)
            .environment(\.managedObjectContext, context)
    }
}
