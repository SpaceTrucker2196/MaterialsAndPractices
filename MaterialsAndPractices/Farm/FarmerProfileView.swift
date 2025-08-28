//
//  FarmerProfileView.swift
//  MaterialsAndPractices
//
//  Comprehensive farmer profile management view implementing clean architecture principles.
//  Provides create/edit modes with photo management and lease information integration.
//  Follows Clean Code principles with clear separation of concerns and single responsibility.
//
//  Created by AI Assistant following Dr. Bob Martin's Clean Code principles.
//

import SwiftUI
import CoreData
import Combine

/// Comprehensive farmer profile management view with create/edit capabilities
/// Handles both new farmer onboarding and existing profile maintenance
/// Integrates with notification system for guided profile creation flows
struct FarmerProfileView: View {
    // MARK: - Core Data Environment

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Profile Data State

    @State private var currentFarmer: Farmer?
    @State private var isCurrentlyEditing = false
    @State private var isPresentingPhotoPicker = false

    // MARK: - Form Data State

    @State private var farmerName = ""
    @State private var emailAddress = ""
    @State private var phoneNumber = ""
    @State private var organizationName = ""
    @State private var additionalNotes = ""

    // MARK: - Main Interface

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Profile photo management section
                    profilePhotoManagementSection

                    // Personal information form section
                    personalInformationFormSection

                    // Additional information sections (shown when not editing and farmer exists)
                    if !isCurrentlyEditing && currentFarmer != nil {
                        activeLeasesInformationSection
                    }
                }
                .padding()
            }
            .navigationBarTitle("Farmer Profile", displayMode: .large)
            .navigationBarItems(
                leading: editingCancelButton,
                trailing: editingSaveButton
            )
        }
        .onAppear {
            performProfileLoadingCheck()
        }
        // Replace init-time observer with a safe view-life-cycle listener.
        .onReceive(NotificationCenter.default.publisher(for: .showProfileCreation)) { _ in
            isCurrentlyEditing = true
        }
        .sheet(isPresented: $isPresentingPhotoPicker) {
            // Photo capture interface (placeholder for future implementation)
            //PhotoCaptureView(farmer: currentFarmer, isPresented: $isPresentingPhotoPicker)
        }
    }

    // MARK: - Navigation Bar Components

    private var editingCancelButton: some View {
        Group {
            if isCurrentlyEditing {
                Button("Cancel") {
                    cancelEditingWithReversion()
                }
            }
        }
    }

    private var editingSaveButton: some View {
        Button(isCurrentlyEditing ? "Save" : "Edit") {
            if isCurrentlyEditing {
                saveCurrentFarmerProfile()
            } else {
                enterProfileEditingMode()
            }
        }
    }

    // MARK: - Interface Sections

    private var profilePhotoManagementSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Farmer Profile")
            
            profilePhotoDisplayWithEditCapability
                .frame(maxWidth: .infinity)

            if isCurrentlyEditing {
                profilePhotoEditInstructions
            }
        }
    }

    private var profilePhotoDisplayWithEditCapability: some View {
        Button(action: {
            if isCurrentlyEditing { isPresentingPhotoPicker = true }
        }) {
            profilePhotoVisualDisplay
        }
        .disabled(!isCurrentlyEditing)
    }

    private var profilePhotoVisualDisplay: some View {
        Group {
            if let farmer = currentFarmer, let imagePath = farmer.imagePath,
               let image = ZappaProfile.loadImage(from: imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 1024, maxHeight: 400)
                    .clipped()
                    .cornerRadius(AppTheme.CornerRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(AppTheme.Colors.primary, lineWidth: 3)
                    )
            } else if let farmer = currentFarmer, farmer.profilePhotoData != nil {
                FarmerProfileImage(farmer: farmer)
                    .frame(maxWidth: 1024, maxHeight: 400)
                    .clipped()
                    .cornerRadius(AppTheme.CornerRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(AppTheme.Colors.primary, lineWidth: 3)
                    )
            } else {
                profilePhotoPlaceholder
            }
        }
    }

    private var profilePhotoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.Colors.backgroundSecondary)
                .frame(maxWidth: 1024, maxHeight: 400)

            Image(systemName: "person.fill")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.Colors.primary)
        }
    }

    private var profilePhotoEditInstructions: some View {
        Text("Tap to change photo")
            .font(AppTheme.Typography.bodySmall)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }

    private var personalInformationFormSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Profile Information")

            if isCurrentlyEditing {
                editablePersonalInformationForm
            } else {
                readOnlyPersonalInformationDisplay
            }
        }
    }

    private var editablePersonalInformationForm: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            TextField("Full Name", text: $farmerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Email", text: $emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            TextField("Phone", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)

            TextField("Organization", text: $organizationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Notes", text: $additionalNotes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }

    private var readOnlyPersonalInformationDisplay: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if !farmerName.isEmpty {
                informationDisplayRow(label: "Name:", content: farmerName)
            }
            if !emailAddress.isEmpty {
                informationDisplayRow(label: "Email:", content: emailAddress)
            }
            if !phoneNumber.isEmpty {
                informationDisplayRow(label: "Phone:", content: phoneNumber)
            }
            if !organizationName.isEmpty {
                informationDisplayRow(label: "Organization:", content: organizationName)
            }
            if !additionalNotes.isEmpty {
                informationDisplayRow(label: "Notes:", content: additionalNotes)
            }
        }
    }

    private func informationDisplayRow(label: String, content: String) -> some View {
        CommonInfoRow(label: label) { Text(content) }
    }

    private var activeLeasesInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Active Leases")

            if let farmer = currentFarmer,
               let leases = farmer.leases?.allObjects as? [Lease],
               !leases.isEmpty {
                ForEach(leases.filter { $0.status == "active" }, id: \.id) { lease in
                    LeaseInformationRow(lease: lease)
                }
            } else {
                Text("No active leases")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Profile Management Methods

    private func performProfileLoadingCheck() {
        let fetchRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        fetchRequest.fetchLimit = 1

        do {
            let existingFarmers = try viewContext.fetch(fetchRequest)
            if let existingFarmer = existingFarmers.first {
                currentFarmer = existingFarmer
                
                // Set default imagePath if blank
                if existingFarmer.imagePath == nil || existingFarmer.imagePath?.isEmpty == true {
                    existingFarmer.imagePath = ZappaProfile.getRandomImagePath()
                    try? viewContext.save()
                }
                
                populateFormFieldsFromFarmer()
            } else {
                isCurrentlyEditing = true
            }
        } catch {
            print("❌ Error loading farmer profile: \(error)")
            isCurrentlyEditing = true
        }
    }

    private func populateFormFieldsFromFarmer() {
        guard let farmer = currentFarmer else { return }
        farmerName = farmer.name ?? ""
        emailAddress = farmer.email ?? ""
        phoneNumber = farmer.phone ?? ""
        organizationName = farmer.orgName ?? ""
        additionalNotes = farmer.notes ?? ""
    }

    private func enterProfileEditingMode() {
        isCurrentlyEditing = true
        populateFormFieldsFromFarmer()
    }

    private func cancelEditingWithReversion() {
        if currentFarmer == nil {
            presentationMode.wrappedValue.dismiss()
        } else {
            populateFormFieldsFromFarmer()
            isCurrentlyEditing = false
        }
    }

    private func saveCurrentFarmerProfile() {
        if currentFarmer == nil {
            currentFarmer = Farmer(context: viewContext)
            currentFarmer?.id = UUID()
            
            // Set default imagePath for new farmer
            currentFarmer?.imagePath = ZappaProfile.getRandomImagePath()
        }

        updateFarmerWithFormData()

        do {
            try viewContext.save()
            isCurrentlyEditing = false
            print("✅ Farmer profile saved successfully")
        } catch {
            print("❌ Error saving farmer profile: \(error)")
        }
    }

    private func updateFarmerWithFormData() {
        guard let farmer = currentFarmer else { return }

        farmer.name = farmerName.isEmpty ? nil : farmerName
        farmer.email = emailAddress.isEmpty ? nil : emailAddress
        farmer.phone = phoneNumber.isEmpty ? nil : phoneNumber
        farmer.orgName = organizationName.isEmpty ? nil : organizationName
        farmer.notes = additionalNotes.isEmpty ? nil : additionalNotes
    }
}

// MARK: - Supporting Views

struct FarmerProfileImage: View {
    let farmer: Farmer

    var body: some View {
        // First try to load from imagePath
        if let imagePath = farmer.imagePath,
           let image = ZappaProfile.loadImage(from: imagePath) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        // Fallback to profilePhotoData
        else if let photoData = farmer.profilePhotoData,
           let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } 
        // Default placeholder
        else {
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.primary)
                .background(AppTheme.Colors.backgroundSecondary)
        }
    }
}

struct LeaseInformationRow: View {
    let lease: Lease

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(lease.leaseType?.capitalized ?? "Lease")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if let startDate = lease.startDate, let endDate = lease.endDate {
                    Text("\(startDate, formatter: standardDateFormatter) - \(endDate, formatter: standardDateFormatter)")
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

// MARK: - Date Formatting Utilities

private let standardDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

// MARK: - Preview

struct FarmerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FarmerProfileView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
