//
//  LeaseCreationWorkflowView.swift
//  MaterialsAndPractices
//
//  Comprehensive lease creation workflow with template selection,
//  data entry, and markdown generation. Follows the pattern established
//  by the inspection system for consistency.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Comprehensive lease creation workflow view
struct LeaseCreationWorkflowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var selectedTemplate: String = ""
    @State private var leaseType: String = "cash"
    @State private var growingYear: Int = Calendar.current.component(.year, from: Date())
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var rentAmount = ""
    @State private var rentFrequency = "annual"
    @State private var selectedProperty: Property?
    @State private var selectedFarmer: Farmer?
    @State private var currentStep = 1
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var availableTemplates: [String] = []
    
    // Fetch properties and farmers
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var properties: FetchedResults<Property>
    
    @FetchRequest(
        entity: Farmer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Farmer.name, ascending: true)]
    ) private var farmers: FetchedResults<Farmer>
    
    private let leaseTemplateSeeder = LeaseTemplateSeeder()
    private let leaseDirectoryManager = LeaseDirectoryManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.large) {
                        switch currentStep {
                        case 1:
                            templateSelectionStep
                        case 2:
                            basicInformationStep
                        case 3:
                            paymentTermsStep
                        case 4:
                            reviewAndCreateStep
                        default:
                            templateSelectionStep
                        }
                    }
                    .padding()
                }
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Create Lease Agreement")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                setupInitialData()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var progressIndicator: some View {
        HStack {
            ForEach(1...4, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? AppTheme.Colors.primary : AppTheme.Colors.backgroundTertiary)
                    .frame(width: 12, height: 12)
                
                if step < 4 {
                    Rectangle()
                        .fill(step < currentStep ? AppTheme.Colors.primary : AppTheme.Colors.backgroundTertiary)
                        .frame(height: 2)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    private var templateSelectionStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Step 1: Select Lease Template")
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("Choose the type of lease agreement that best fits your needs")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(availableTemplates, id: \.self) { template in
                    LeaseTemplateCard(
                        templateName: template,
                        isSelected: selectedTemplate == template
                    ) {
                        selectedTemplate = template
                        // Set lease type based on template
                        if template.contains("Cash_Rent") {
                            leaseType = "cash"
                        } else if template.contains("Crop_Share") {
                            leaseType = "crop_share"
                        } else if template.contains("Flexible") {
                            leaseType = "flexible_cash"
                        } else if template.contains("Pasture") {
                            leaseType = "pasture"
                        } else if template.contains("Custom") {
                            leaseType = "custom"
                        }
                    }
                }
            }
        }
    }
    
    private var basicInformationStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Step 2: Basic Information")
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Growing Year Selector
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Growing Year")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Picker("Growing Year", selection: $growingYear) {
                        ForEach(currentYear...(currentYear + 3), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Property Selection
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Property")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Menu {
                        ForEach(properties, id: \.objectID) { property in
                            Button(property.displayName ?? "Unknown Property") {
                                selectedProperty = property
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedProperty?.displayName ?? "Select Property")
                                .foregroundColor(selectedProperty == nil ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding()
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                }
                
                // Farmer Selection
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Farmer/Tenant")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Menu {
                        ForEach(farmers, id: \.objectID) { farmer in
                            Button(farmer.name ?? "Unknown Farmer") {
                                selectedFarmer = farmer
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedFarmer?.name ?? "Select Farmer")
                                .foregroundColor(selectedFarmer == nil ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding()
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                }
                
                // Date Selection
                HStack(spacing: AppTheme.Spacing.medium) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Start Date")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("End Date")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
            }
        }
    }
    
    private var paymentTermsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Step 3: Payment Terms")
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Rent Amount
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Rent Amount")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    TextField("Enter amount", text: $rentAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Payment Frequency
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Payment Frequency")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Picker("Payment Frequency", selection: $rentFrequency) {
                        Text("Annual").tag("annual")
                        Text("Semi-Annual").tag("semi_annual")
                        Text("Quarterly").tag("quarterly")
                        Text("Monthly").tag("monthly")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    private var reviewAndCreateStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Step 4: Review & Create")
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ReviewRow(label: "Template", value: selectedTemplate.replacingOccurrences(of: "_", with: " "))
                ReviewRow(label: "Growing Year", value: "\(growingYear)")
                ReviewRow(label: "Property", value: selectedProperty?.displayName ?? "None")
                ReviewRow(label: "Farmer", value: selectedFarmer?.name ?? "None")
                ReviewRow(label: "Lease Period", value: "\(startDate) - \(endDate)")
                ReviewRow(label: "Rent Amount", value: "$\(rentAmount)")
                ReviewRow(label: "Payment Frequency", value: rentFrequency.replacingOccurrences(of: "_", with: " ").capitalized)
            }
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 1 {
                Button("Previous") {
                    currentStep -= 1
                }
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(currentStep == 4 ? "Create Lease" : "Next") {
                if currentStep == 4 {
                    createLease()
                } else {
                    if validateCurrentStep() {
                        currentStep += 1
                    }
                }
            }
            .foregroundColor(AppTheme.Colors.primary)
            .disabled(!isCurrentStepValid)
        }
        .padding()
    }
    
    // MARK: - Helper Properties
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1:
            return !selectedTemplate.isEmpty
        case 2:
            return selectedProperty != nil && selectedFarmer != nil
        case 3:
            return !rentAmount.isEmpty && Double(rentAmount) != nil
        case 4:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialData() {
        // Seed templates if needed
        leaseTemplateSeeder.seedTemplatesIfNeeded()
        
        // Load available templates
        availableTemplates = leaseDirectoryManager.listFiles(in: .templates)
        
        // Set default end date to end of year
        let calendar = Calendar.current
        endDate = calendar.date(from: DateComponents(year: growingYear, month: 12, day: 31)) ?? endDate
    }
    
    private func validateCurrentStep() -> Bool {
        // Add specific validation for each step
        return isCurrentStepValid
    }
    
    private func createLease() {
        do {
            // Create lease in Core Data first
            let lease = Lease(context: viewContext)
            lease.id = UUID()
            lease.leaseType = leaseType
            lease.startDate = startDate
            lease.endDate = endDate
            lease.rentAmount = NSDecimalNumber(string: rentAmount)
            lease.rentFrequency = rentFrequency
            lease.status = "active"
            lease.property = selectedProperty
            lease.farmer = selectedFarmer
            
            // Create lease data for template population
            let leaseData = LeaseCreationData(
                leaseId: lease.id,
                propertyName: selectedProperty?.displayName,
                farmerName: selectedFarmer?.name,
                growingYear: growingYear,
                leaseType: leaseType,
                startDate: startDate,
                endDate: endDate,
                rentAmount: NSDecimalNumber(string: rentAmount).decimalValue,
                rentFrequency: rentFrequency
            )
            
            // Create a unique working template name
            let workingTemplateName = "Working_\(selectedTemplate)_\(UUID().uuidString.prefix(8))"
            
            // Copy template to working directory
            try leaseDirectoryManager.copyTemplateToWorking(
                templateName: selectedTemplate,
                workingName: workingTemplateName
            )
            
            // Create completed lease with improved error handling
            let createdLeaseInfo = try leaseDirectoryManager.createCompletedLease(
                workingTemplateName: workingTemplateName,
                leaseData: leaseData
            )
            
            // Store the document path in the lease entity
            lease.leaseDocumentPath = createdLeaseInfo.filePath
            
            // Create payment schedule based on rent frequency
            createPaymentSchedule(for: lease)
            
            // Save Core Data context
            try viewContext.save()
            
            print("✅ Successfully created lease agreement: \(createdLeaseInfo.fileName)")
            print("📄 Document saved to: \(createdLeaseInfo.filePath)")
            
            // Clean up working template
            cleanupWorkingTemplate(workingTemplateName)
            
            isPresented = false
            
        } catch let leaseError as LeaseError {
            errorMessage = leaseError.localizedDescription
            showingError = true
            print("❌ Lease creation error: \(leaseError)")
        } catch {
            errorMessage = "Failed to create lease: \(error.localizedDescription)"
            showingError = true
            print("❌ Unexpected error: \(error)")
        }
    }
    
    /// Creates payment schedule for the lease based on rent frequency
    private func createPaymentSchedule(for lease: Lease) {
        guard let rentAmount = lease.rentAmount,
              let startDate = lease.startDate,
              let endDate = lease.endDate,
              let frequency = lease.rentFrequency else { return }
        
        let calendar = Calendar.current
        var paymentDates: [Date] = []
        
        // Calculate payment dates based on frequency
        switch frequency.lowercased() {
        case "monthly":
            var currentDate = startDate
            while currentDate <= endDate {
                paymentDates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
            }
        case "quarterly":
            var currentDate = startDate
            while currentDate <= endDate {
                paymentDates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 3, to: currentDate) ?? endDate
            }
        case "semi-annual":
            var currentDate = startDate
            while currentDate <= endDate {
                paymentDates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 6, to: currentDate) ?? endDate
            }
        case "annual":
            paymentDates.append(startDate)
        default:
            paymentDates.append(startDate)
        }
        
        // Create payment entities
        let paymentAmount = rentAmount.dividing(by: NSDecimalNumber(value: paymentDates.count))
        
        for (index, dueDate) in paymentDates.enumerated() {
            let payment = Payment(context: viewContext)
            payment.id = UUID()
            payment.amount = paymentAmount.decimalValue as NSDecimalNumber
            payment.dueDate = dueDate
            payment.isPaid = false
            payment.paymentStatus = "pending"
            payment.sequence = Int16(index + 1)
            payment.memo = "Lease payment \(index + 1) of \(paymentDates.count)"
            payment.lease = lease
        }
        
        print("✅ Created \(paymentDates.count) payment(s) for lease")
    }
    
    /// Cleans up the working template file after use
    private func cleanupWorkingTemplate(_ workingTemplateName: String) {
        let workingURL = leaseDirectoryManager.directoryURL(for: .working)
            .appendingPathComponent("\(workingTemplateName).md")
        
        do {
            if FileManager.default.fileExists(atPath: workingURL.path) {
                try FileManager.default.removeItem(at: workingURL)
                print("🧹 Cleaned up working template: \(workingTemplateName)")
            }
        } catch {
            print("⚠️ Failed to cleanup working template: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct LeaseTemplateCard: View {
    let templateName: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(displayName)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.primary.opacity(0.1) : AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var displayName: String {
        templateName.replacingOccurrences(of: "_", with: " ")
    }
    
    private var description: String {
        switch templateName {
        case let name where name.contains("Cash_Rent"):
            return "Fixed annual payment for land use"
        case let name where name.contains("Crop_Share"):
            return "Percentage-based sharing of crop proceeds"
        case let name where name.contains("Flexible"):
            return "Cash rent with price/yield adjustments"
        case let name where name.contains("Pasture"):
            return "Grazing rights for livestock operations"
        case let name where name.contains("Custom"):
            return "Custom farming services agreement"
        default:
            return "Agricultural lease agreement"
        }
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
