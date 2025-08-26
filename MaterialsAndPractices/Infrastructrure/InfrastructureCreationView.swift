//
//  InfrastructureCreationView.swift
//  MaterialsAndPractices
//
//  Provides infrastructure creation interface for adding new infrastructure items
//  to farms. Supports both catalog-based creation and custom infrastructure entry.
//  Includes farm assignment and comprehensive infrastructure details.
//
//  Created by GitHub Copilot on 12/19/24.
//

import SwiftUI
import CoreData

/// Infrastructure creation view for adding new infrastructure items to farms
/// Supports creation from catalog items or custom infrastructure entry
struct InfrastructureCreationView: View {
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    let fromCatalogItem: InfrastructureCatalog?
    @Environment(\.managedObjectContext) private var viewContext
    
    // Form state
    @State private var infrastructureName = ""
    @State private var infrastructureType = ""
    @State private var infrastructureCategory = ""
    @State private var infrastructureStatus = "Good"
    @State private var installDate = Date()
    @State private var lastServiceDate: Date?
    @State private var notes = ""
    @State private var maintenanceProcedures = ""
    @State private var safetyTraining = ""
    @State private var rodentInspectionProcedure = ""
    @State private var selectedFarm: Property?
    @State private var showingFarmPicker = false
    
    // Predefined options
    private let statusOptions = ["Excellent", "Good", "Fair", "Poor", "Needs Repair"]
    private let categoryOptions = ["Machinery", "Transportation", "Buildings", "Irrigation", "Storage", "Equipment"]
    
    // Farm selection
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var availableFarms: FetchedResults<Property>
    
    // MARK: - Initialization
    
    init(isPresented: Binding<Bool>, fromCatalogItem: InfrastructureCatalog? = nil) {
        self._isPresented = isPresented
        self.fromCatalogItem = fromCatalogItem
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Basic information section
                basicInformationSection
                
                // Farm assignment section
                farmAssignmentSection
                
                // Status and dates section
                statusAndDatesSection
                
                // Detailed information section
                detailedInformationSection
                
                // Action buttons section
                actionButtonsSection
            }
            .navigationTitle(fromCatalogItem != nil ? "Create from Catalog" : "Add Infrastructure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                loadCatalogData()
            }
            .sheet(isPresented: $showingFarmPicker) {
                FarmPickerView(selectedFarm: $selectedFarm, isPresented: $showingFarmPicker)
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Basic infrastructure information section
    private var basicInformationSection: some View {
        Section("Infrastructure Details") {
            TextField("Infrastructure Name", text: $infrastructureName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if fromCatalogItem == nil {
                TextField("Type (e.g., tractor, barn)", text: $infrastructureType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Category", selection: $infrastructureCategory) {
                    ForEach(categoryOptions, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            } else {
                HStack {
                    Text("Type:")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text(infrastructureType)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                HStack {
                    Text("Category:")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text(infrastructureCategory)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }
        }
    }
    
    /// Farm assignment section
    private var farmAssignmentSection: some View {
        Section("Farm Assignment") {
            Button(action: { showingFarmPicker = true }) {
                HStack {
                    Text("Assigned Farm:")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    if let selectedFarm = selectedFarm {
                        Text(selectedFarm.displayName ?? "Unnamed Farm")
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    } else {
                        Text("Select Farm")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            
            if selectedFarm == nil {
                Text("Infrastructure must be assigned to a farm")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
    }
    
    /// Status and dates section
    private var statusAndDatesSection: some View {
        Section("Status & Maintenance") {
            Picker("Current Status", selection: $infrastructureStatus) {
                ForEach(statusOptions, id: \.self) { status in
                    Text(status).tag(status)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            DatePicker(
                "Install Date:",
                selection: $installDate,
                in: ...Date(),
                displayedComponents: [.date]
            )
            
            HStack {
                Text("Last Service Date:")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                if let lastServiceDate = lastServiceDate {
                    Text(lastServiceDate, style: .date)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Button("Clear") {
                        self.lastServiceDate = nil
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.primary)
                } else {
                    Button("Set Date") {
                        lastServiceDate = Date()
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let lastServiceDate = lastServiceDate {
                DatePicker(
                    "Last Service Date",
                    selection: Binding(
                        get: { lastServiceDate },
                        set: { self.lastServiceDate = $0 }
                    ),
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .labelsHidden()
            }
        }
    }
    
    /// Detailed information section
    private var detailedInformationSection: some View {
        Section("Additional Information") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Notes:")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .padding(AppTheme.Spacing.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            if fromCatalogItem != nil {
                DisclosureGroup("Maintenance Procedures") {
                    Text(maintenanceProcedures)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.vertical, AppTheme.Spacing.small)
                }
                
                DisclosureGroup("Safety Training") {
                    Text(safetyTraining)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.vertical, AppTheme.Spacing.small)
                }
                
                if !rodentInspectionProcedure.isEmpty {
                    DisclosureGroup("Rodent Inspection Procedures") {
                        Text(rodentInspectionProcedure)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.vertical, AppTheme.Spacing.small)
                    }
                }
            }
        }
    }
    
    /// Action buttons section
    private var actionButtonsSection: some View {
        Section {
            CommonActionButton(
                title: "Create Infrastructure",
                style: .primary
            ) {
                createInfrastructure()
            }
            .disabled(!isFormValid)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Form validation
    private var isFormValid: Bool {
        !infrastructureName.isEmpty && 
        !infrastructureType.isEmpty && 
        !infrastructureCategory.isEmpty && 
        selectedFarm != nil
    }
    
    // MARK: - Actions
    
    /// Load data from catalog item if provided
    private func loadCatalogData() {
        guard let catalogItem = fromCatalogItem else { return }
        
        infrastructureName = catalogItem.name ?? ""
        infrastructureType = catalogItem.type ?? ""
        infrastructureCategory = catalogItem.category ?? ""
        maintenanceProcedures = catalogItem.maintenanceProcedures ?? ""
        safetyTraining = catalogItem.safetyTraining ?? ""
        rodentInspectionProcedure = catalogItem.rodentInspectionProcedure ?? ""
    }
    
    /// Create new infrastructure item
    private func createInfrastructure() {
        guard isFormValid else { return }
        
        let infrastructure = Infrastructure(context: viewContext)
        infrastructure.id = UUID()
        infrastructure.name = infrastructureName
        infrastructure.type = infrastructureType
        infrastructure.category = infrastructureCategory
        infrastructure.status = infrastructureStatus
        infrastructure.installDate = installDate
        infrastructure.lastServiceDate = lastServiceDate
        infrastructure.notes = notes
        infrastructure.maintenanceProcedures = maintenanceProcedures
        infrastructure.safetyTraining = safetyTraining
        infrastructure.rodentInspectionProcedure = rodentInspectionProcedure
        infrastructure.property = selectedFarm
        
        do {
            try viewContext.save()
            
            // Post notification for infrastructure creation
            CoreDataNotificationCenter.postInfrastructureNotification(
                type: .created, 
                infrastructure: infrastructure
            )
            
            isPresented = false
        } catch {
            print("Error creating infrastructure: \(error)")
            // In a real app, show error alert
        }
    }
}

// MARK: - Farm Picker View

/// Farm selection picker for infrastructure assignment
struct FarmPickerView: View {
    @Binding var selectedFarm: Property?
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var availableFarms: FetchedResults<Property>
    
    var body: some View {
        NavigationView {
            List {
                Section("Available Farms") {
                    ForEach(availableFarms, id: \.id) { farm in
                        Button(action: {
                            selectedFarm = farm
                            isPresented = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                                    Text(farm.displayName ?? "Unnamed Farm")
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    if let county = farm.county, let state = farm.state {
                                        Text("\(county), \(state)")
                                            .font(AppTheme.Typography.bodySmall)
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                    
                                    Text("\(farm.totalAcres, specifier: "%.1f") acres")
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if selectedFarm?.id == farm.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.Colors.primary)
                                }
                            }
                        }
                    }
                }
                
                if availableFarms.isEmpty {
                    Section {
                        Text("No farms available. Create a farm first to assign infrastructure.")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(AppTheme.Typography.bodyMedium)
                    }
                }
            }
            .navigationTitle("Select Farm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Infrastructure Detail View

/// Detailed view for existing infrastructure items
struct InfrastructureCreationDetailView: View {
    let infrastructure: Infrastructure
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Header information
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(infrastructure.name ?? "Unnamed Infrastructure")
                            .font(AppTheme.Typography.headlineLarge)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        HStack {
                            if let category = infrastructure.category {
                                Text(category)
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppTheme.Spacing.medium)
                                    .padding(.vertical, AppTheme.Spacing.small)
                                    .background(AppTheme.Colors.primary)
                                    .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            
                            if let type = infrastructure.type {
                                Text(type.capitalized)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                    
                    // Status and maintenance information
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        HStack {
                            Text("Status:")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text(infrastructure.status ?? "Unknown")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        
                        if let installDate = infrastructure.installDate {
                            HStack {
                                Text("Installed:")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Spacer()
                                
                                Text(installDate, style: .date)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                        }
                        
                        if let lastServiceDate = infrastructure.lastServiceDate {
                            HStack {
                                Text("Last Service:")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Spacer()
                                
                                Text(lastServiceDate, style: .date)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    // Additional information sections
                    if let maintenanceProcedures = infrastructure.maintenanceProcedures,
                       !maintenanceProcedures.isEmpty {
                        DetailSection(title: "Maintenance Procedures", content: maintenanceProcedures)
                    }
                    
                    if let safetyTraining = infrastructure.safetyTraining,
                       !safetyTraining.isEmpty {
                        DetailSection(title: "Safety Training", content: safetyTraining)
                    }
                    
                    if let rodentInspection = infrastructure.rodentInspectionProcedure,
                       !rodentInspection.isEmpty {
                        DetailSection(title: "Rodent Inspection Procedures", content: rodentInspection)
                    }
                    
                    if let notes = infrastructure.notes,
                       !notes.isEmpty {
                        DetailSection(title: "Notes", content: notes)
                    }
                }
                .padding()
            }
            .navigationTitle("Infrastructure Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            editInfrastructure()
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            copyInfrastructure()
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Edit infrastructure - opens edit view
    private func editInfrastructure() {
        // Implementation would open edit view
        // For now, print action
        print("Edit infrastructure: \(infrastructure.name ?? "Unknown")")
    }
    
    /// Copy infrastructure - creates a new infrastructure based on this one
    private func copyInfrastructure() {
        // Implementation would create a copy
        print("Copy infrastructure: \(infrastructure.name ?? "Unknown")")
    }
}

// MARK: - Preview

struct InfrastructureCreationView_Previews: PreviewProvider {
    static var previews: some View {
        InfrastructureCreationView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
