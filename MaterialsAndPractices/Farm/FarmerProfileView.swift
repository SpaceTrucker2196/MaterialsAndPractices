//
//  FarmerProfileView.swift
//  MaterialsAndPractices
//
//  Profile view for farmer information including photo and basic details.
//  Supports create/edit modes with photo management integration.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Profile view for farmer information with photo support
struct FarmerProfileView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @State private var farmer: Farmer?
    @State private var isEditing = false
    @State private var showingPhotoPicker = false
    
    // Form data
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var orgName = ""
    @State private var notes = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Profile photo section
                    profilePhotoSection
                    
                    // Profile information section
                    profileInformationSection
                    
                    if !isEditing && farmer != nil {
                        // Additional information sections
                        leaseInformationSection
                    }
                }
                .padding()
            }
            .navigationBarTitle("Farmer Profile", displayMode: .large)
            .navigationBarItems(
                leading: isEditing ? Button("Cancel") {
                    cancelEditing()
                } : nil,
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveFarmerProfile()
                    } else {
                        enterEditMode()
                    }
                }
            )
        }
        .onAppear {
            loadFarmerProfile()
        }
        .sheet(isPresented: $showingPhotoPicker) {
         //   PhotoCaptureView(farmer: farmer, isPresented: $showingPhotoPicker)
        }
    }
    
    // MARK: - Sections
    
    /// Profile photo section with edit capability
    private var profilePhotoSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                Spacer()
                
                Button(action: {
                    if isEditing {
                        showingPhotoPicker = true
                    }
                }) {
                    if let farmer = farmer, farmer.profilePhotoData != nil {
                        FarmerProfileImage(farmer: farmer)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.Colors.primary, lineWidth: 3)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.backgroundSecondary)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                .disabled(!isEditing)
                
                Spacer()
            }
            
            if isEditing {
                Text("Tap to change photo")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Profile information form section
    private var profileInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Profile Information")
            
            if isEditing {
                VStack(spacing: AppTheme.Spacing.medium) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    TextField("Organization", text: $orgName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    if !name.isEmpty {
                        CommonInfoRow(label: "Name:") {
                            Text(name)
                        }
                    }
                    
                    if !email.isEmpty {
                        CommonInfoRow(label: "Email:") {
                            Text(email)
                        }
                    }
                    
                    if !phone.isEmpty {
                        CommonInfoRow(label: "Phone:") {
                            Text(phone)
                        }
                    }
                    
                    if !orgName.isEmpty {
                        CommonInfoRow(label: "Organization:") {
                            Text(orgName)
                        }
                    }
                    
                    if !notes.isEmpty {
                        CommonInfoRow(label: "Notes:") {
                            Text(notes)
                        }
                    }
                }
            }
        }
    }
    
    /// Lease information section
    private var leaseInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Active Leases")
            
            if let farmer = farmer,
               let leases = farmer.leases?.allObjects as? [Lease],
               !leases.isEmpty {
                ForEach(leases.filter { $0.status == "active" }, id: \.id) { lease in
                    LeaseRow(lease: lease)
                }
            } else {
                Text("No active leases")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Methods
    
    /// Loads existing farmer profile or creates a new one
    private func loadFarmerProfile() {
        let request: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let farmers = try viewContext.fetch(request)
            if let existingFarmer = farmers.first {
                farmer = existingFarmer
                updateFormFields()
            } else {
                // Create a new farmer if none exists
                isEditing = true
            }
        } catch {
            print("Error loading farmer profile: \(error)")
            isEditing = true
        }
    }
    
    /// Updates form fields with farmer data
    private func updateFormFields() {
        guard let farmer = farmer else { return }
        name = farmer.name ?? ""
        email = farmer.email ?? ""
        phone = farmer.phone ?? ""
        orgName = farmer.orgName ?? ""
        notes = farmer.notes ?? ""
    }
    
    /// Enters edit mode
    private func enterEditMode() {
        isEditing = true
        updateFormFields()
    }
    
    /// Cancels editing and reverts changes
    private func cancelEditing() {
        if farmer == nil {
            presentationMode.wrappedValue.dismiss()
        } else {
            updateFormFields()
            isEditing = false
        }
    }
    
    /// Saves farmer profile
    private func saveFarmerProfile() {
        if farmer == nil {
            farmer = Farmer(context: viewContext)
            farmer?.id = UUID()
        }
        
        farmer?.name = name.isEmpty ? nil : name
        farmer?.email = email.isEmpty ? nil : email
        farmer?.phone = phone.isEmpty ? nil : phone
        farmer?.orgName = orgName.isEmpty ? nil : orgName
        farmer?.notes = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            isEditing = false
        } catch {
            print("Error saving farmer profile: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Custom image view for farmer profile photos
struct FarmerProfileImage: View {
    let farmer: Farmer
    
    var body: some View {
        if let photoData = farmer.profilePhotoData,
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.primary)
                .background(AppTheme.Colors.backgroundSecondary)
        }
    }
}

/// Row view for displaying lease information
struct LeaseRow: View {
    let lease: Lease
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(lease.leaseType?.capitalized ?? "Lease")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let startDate = lease.startDate,
                   let endDate = lease.endDate {
                    Text("\(startDate, formatter: dateFormatter) - \(endDate, formatter: dateFormatter)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let rentAmount = lease.rentAmount {
                Text("$\(rentAmount)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

// MARK: - Date Formatter

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

// MARK: - Preview Provider

struct FarmerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FarmerProfileView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
