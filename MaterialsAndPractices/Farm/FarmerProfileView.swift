//
//  FarmerProfileView.swift
//  MaterialsAndPractices
//
//  Comprehensive farmer profile management view implementing clean architecture principles.
//  Provides create/edit modes with photo management and lease information integration.
//  Follows Clean Code principles with clear separation of concerns and single responsibility.
//
//  Features:
//  - Profile creation and editing with guided UX
//  - Photo management integration (placeholder for future implementation)
//  - Active lease relationship display
//  - Form validation and error handling
//  - Responsive to profile creation notifications
//
//  Clean Code Principles Applied:
//  - Single Responsibility: Each method handles one specific aspect of profile management
//  - Meaningful Names: All properties and methods have descriptive, intent-revealing names
//  - Small Functions: Complex operations broken into focused, readable methods
//  - Comments: Documentation explains "why" not "what"
//
//  Created by AI Assistant following Dr. Bob Martin's Clean Code principles.
//

import SwiftUI
import CoreData

/// Comprehensive farmer profile management view with create/edit capabilities
/// Handles both new farmer onboarding and existing profile maintenance
/// Integrates with notification system for guided profile creation flows
struct FarmerProfileView: View {
    // MARK: - Core Data Environment
    
    /// Managed object context for Core Data operations
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Presentation mode for dismissal control in modal contexts
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Profile Data State
    
    /// Current farmer entity being viewed or edited
    @State private var currentFarmer: Farmer?
    
    /// Controls whether the interface is in editing mode
    @State private var isCurrentlyEditing = false
    
    /// Controls presentation of photo selection interface
    @State private var isPresentingPhotoPicker = false
    
    // MARK: - Form Data State
    
    /// Farmer's full name for identification and communication
    @State private var farmerName = ""
    
    /// Email address for digital communication and notifications
    @State private var emailAddress = ""
    
    /// Phone number for direct communication and emergency contact
    @State private var phoneNumber = ""
    
    /// Organization name for business identification and partnerships
    @State private var organizationName = ""
    
    /// Additional notes for personalization and operational context
    @State private var additionalNotes = ""
    
    // MARK: - Initialization and Lifecycle
    
    init() {
        // Listen for profile creation notifications from onboarding flow
        NotificationCenter.default.addObserver(
            forName: .showProfileCreation,
            object: nil,
            queue: .main
        ) { _ in
            // Automatically enter edit mode when triggered by onboarding
            DispatchQueue.main.async {
                isCurrentlyEditing = true
            }
        }
    }
    
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
        .sheet(isPresented: $isPresentingPhotoPicker) {
            // Photo capture interface (placeholder for future implementation)
            // PhotoCaptureView(farmer: currentFarmer, isPresented: $isPresentingPhotoPicker)
        }
    }
    
    // MARK: - Navigation Bar Components
    
    /// Cancel button shown during editing mode for reverting changes
    private var editingCancelButton: some View {
        Group {
            if isCurrentlyEditing {
                Button("Cancel") {
                    cancelEditingWithReversion()
                }
            }
        }
    }
    
    /// Save/Edit button with context-sensitive functionality
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
    
    /// Profile photo management section with edit capability and visual feedback
    /// Provides clear indication of photo status and editing availability
    private var profilePhotoManagementSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                Spacer()
                
                // Photo display with tap-to-edit functionality
                profilePhotoDisplayWithEditCapability
                
                Spacer()
            }
            
            // Edit instruction text (shown only during editing)
            if isCurrentlyEditing {
                profilePhotoEditInstructions
            }
        }
    }
    
    /// Profile photo display with conditional editing capability
    private var profilePhotoDisplayWithEditCapability: some View {
        Button(action: {
            if isCurrentlyEditing {
                isPresentingPhotoPicker = true
            }
        }) {
            profilePhotoVisualDisplay
        }
        .disabled(!isCurrentlyEditing)
    }
    
    /// Visual display of profile photo or placeholder
    private var profilePhotoVisualDisplay: some View {
        Group {
            if let farmer = currentFarmer, farmer.profilePhotoData != nil {
                FarmerProfileImage(farmer: farmer)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppTheme.Colors.primary, lineWidth: 3)
                    )
            } else {
                profilePhotoPlaceholder
            }
        }
    }
    
    /// Placeholder display when no profile photo is available
    private var profilePhotoPlaceholder: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.backgroundSecondary)
                .frame(width: 120, height: 120)
            
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.primary)
        }
    }
    
    /// Instructions for photo editing during edit mode
    private var profilePhotoEditInstructions: some View {
        Text("Tap to change photo")
            .font(AppTheme.Typography.bodySmall)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
    
    /// Personal information form section with context-sensitive presentation
    /// Shows either editable form fields or read-only information display
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
    
    /// Editable form for personal information during edit mode
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
    
    /// Read-only display of personal information when not editing
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
    
    /// Helper method for consistent information display rows
    /// - Parameters:
    ///   - label: Field label to display
    ///   - content: Content text to display
    /// - Returns: Formatted information row view
    private func informationDisplayRow(label: String, content: String) -> some View {
        CommonInfoRow(label: label) {
            Text(content)
        }
    }
    
    /// Active leases information section for relationship display
    /// Shows lease agreements associated with the current farmer
    private var activeLeasesInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Active Leases")
            
            if let farmer = currentFarmer,
               let leases = farmer.leases?.allObjects as? [Lease],
               !leases.isEmpty {
                activeLeasesContent(leases: leases)
            } else {
                activeLeasesEmptyState
            }
        }
    }
    
    /// Content display for active leases
    /// - Parameter leases: Array of lease objects to display
    /// - Returns: Formatted leases content view
    private func activeLeasesContent(leases: [Lease]) -> some View {
        ForEach(leases.filter { $0.status == "active" }, id: \.id) { lease in
            LeaseInformationRow(lease: lease)
        }
    }
    
    /// Empty state display when no active leases exist
    private var activeLeasesEmptyState: some View {
        Text("No active leases")
            .font(AppTheme.Typography.bodyMedium)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
    
    // MARK: - Profile Management Methods
    
    /// Performs initial profile loading check when view appears
    /// Determines whether to show existing profile or enter creation mode
    private func performProfileLoadingCheck() {
        let fetchRequest: NSFetchRequest<Farmer> = Farmer.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let existingFarmers = try viewContext.fetch(fetchRequest)
            if let existingFarmer = existingFarmers.first {
                currentFarmer = existingFarmer
                populateFormFieldsFromFarmer()
            } else {
                // No farmer exists - enter creation mode automatically
                isCurrentlyEditing = true
            }
        } catch {
            print("❌ Error loading farmer profile: \(error)")
            // On error, default to creation mode for recovery
            isCurrentlyEditing = true
        }
    }
    
    /// Populates form fields with data from the current farmer entity
    /// Ensures UI reflects the current state of farmer data
    private func populateFormFieldsFromFarmer() {
        guard let farmer = currentFarmer else { return }
        farmerName = farmer.name ?? ""
        emailAddress = farmer.email ?? ""
        phoneNumber = farmer.phone ?? ""
        organizationName = farmer.orgName ?? ""
        additionalNotes = farmer.notes ?? ""
    }
    
    /// Enters profile editing mode and refreshes form fields
    /// Ensures form shows current farmer data when editing begins
    private func enterProfileEditingMode() {
        isCurrentlyEditing = true
        populateFormFieldsFromFarmer()
    }
    
    /// Cancels editing mode and handles state restoration
    /// Reverts form fields and dismisses if no farmer exists (creation mode)
    private func cancelEditingWithReversion() {
        if currentFarmer == nil {
            // If no farmer exists, dismiss the view (was in creation mode)
            presentationMode.wrappedValue.dismiss()
        } else {
            // Revert form fields to saved values
            populateFormFieldsFromFarmer()
            isCurrentlyEditing = false
        }
    }
    
    /// Saves the current farmer profile with form validation and error handling
    /// Creates new farmer if none exists, updates existing farmer otherwise
    private func saveCurrentFarmerProfile() {
        // Create new farmer if one doesn't exist
        if currentFarmer == nil {
            currentFarmer = Farmer(context: viewContext)
            currentFarmer?.id = UUID()
        }
        
        // Update farmer properties with form data
        updateFarmerWithFormData()
        
        do {
            try viewContext.save()
            isCurrentlyEditing = false
            print("✅ Farmer profile saved successfully")
        } catch {
            print("❌ Error saving farmer profile: \(error)")
            // TODO: Show user-friendly error message in production
        }
    }
    
    /// Updates the current farmer entity with data from form fields
    /// Handles empty field validation and nil assignment appropriately
    private func updateFarmerWithFormData() {
        guard let farmer = currentFarmer else { return }
        
        // Assign form values to farmer properties, using nil for empty strings
        farmer.name = farmerName.isEmpty ? nil : farmerName
        farmer.email = emailAddress.isEmpty ? nil : emailAddress
        farmer.phone = phoneNumber.isEmpty ? nil : phoneNumber
        farmer.orgName = organizationName.isEmpty ? nil : organizationName
        farmer.notes = additionalNotes.isEmpty ? nil : additionalNotes
    }
}

// MARK: - Supporting Views Following Clean Code Principles

/// Custom image view for farmer profile photos with fallback support
/// Provides consistent photo display across the application
struct FarmerProfileImage: View {
    // MARK: - Properties
    
    let farmer: Farmer
    
    // MARK: - Body
    
    var body: some View {
        if let photoData = farmer.profilePhotoData,
           let uiImage = UIImage(data: photoData) {
            // Display actual profile photo
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Display fallback placeholder
            profilePhotoFallback
        }
    }
    
    /// Fallback placeholder when no profile photo is available
    private var profilePhotoFallback: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 50))
            .foregroundColor(AppTheme.Colors.primary)
            .background(AppTheme.Colors.backgroundSecondary)
    }
}

/// Row view for displaying lease information with proper formatting
/// Maintains consistent presentation of lease details across the interface
struct LeaseInformationRow: View {
    // MARK: - Properties
    
    let lease: Lease
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Lease identification and duration information
            leaseIdentificationContent
            
            Spacer()
            
            // Financial information display
            leaseFinancialInformation
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
    
    /// Lease identification content with type and date range
    private var leaseIdentificationContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(lease.leaseType?.capitalized ?? "Lease")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if let startDate = lease.startDate,
               let endDate = lease.endDate {
                leaseDateRangeDisplay(startDate: startDate, endDate: endDate)
            }
        }
    }
    
    /// Date range display for lease duration
    /// - Parameters:
    ///   - startDate: Lease start date
    ///   - endDate: Lease end date
    /// - Returns: Formatted date range view
    private func leaseDateRangeDisplay(startDate: Date, endDate: Date) -> some View {
        Text("\(startDate, formatter: standardDateFormatter) - \(endDate, formatter: standardDateFormatter)")
            .font(AppTheme.Typography.bodySmall)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
    
    /// Financial information display for lease rent amount
    private var leaseFinancialInformation: some View {
        Group {
            if let rentAmount = lease.rentAmount {
                Text("$\(rentAmount)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }
}

// MARK: - Date Formatting Utilities

/// Standard date formatter for consistent date presentation across the application
/// Provides medium-style date formatting following platform conventions
private let standardDateFormatter: DateFormatter = {
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
