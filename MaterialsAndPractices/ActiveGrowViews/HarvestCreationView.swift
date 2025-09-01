
import SwiftUI
import CoreData

/// Comprehensive harvest creation view with work order generation
/// Provides data entry for harvest details and automatic work order creation
struct HarvestCreationView: View {
    
    // MARK: - Environment and Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    let grow: Grow
    
    // MARK: - Form State
    
    @State private var harvestDate = Date()
    @State private var harvestEndDate = Date()
    @State private var quantity: Double = 0.0
    @State private var netQuantity: Double = 0.0
    @State private var quantityUnit: Harvest.HarvestUnit = .pounds
    @State private var containerCount: Int32 = 1
    @State private var destination: Harvest.HarvestDestination = .cooler
    @State private var notes = ""
    @State private var buyer = ""
    @State private var lotCode = ""
    @State private var isCertifiedOrganic = true
    
    // Compliance flags
    @State private var sanitationVerified: Harvest.ComplianceFlag = .unknown
    @State private var comminglingRisk: Harvest.ComplianceFlag = .unknown
    @State private var contaminationRisk: Harvest.ComplianceFlag = .unknown
    @State private var complianceHold = false
    @State private var bufferZoneObserved = false
    
    // Work order details
    @State private var createWorkOrder = true
    @State private var workOrderTitle = ""
    @State private var workOrderNotes = ""
    @State private var estimatedHours: Double = 4.0
    @State private var selectedTeam: WorkTeam?
    @State private var priorty  = "" 
    
    // UI State
    @State private var isCreatingHarvest = false
    @State private var showingTeamSelection = false
    
    // MARK: - Fetch Requests
    
    @FetchRequest(
        entity: WorkTeam.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkTeam.name, ascending: true)]
    ) private var workTeams: FetchedResults<WorkTeam>
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.large) {
                    // Header section
                    headerSection
                    
                    // Harvest details
                    harvestDetailsSection
                    
                    // Quantity information
                    quantitySection
                    
                    // Compliance section
                    complianceSection
                    
                    // Work order section
                    if createWorkOrder {
                        workOrderSection
                    }
                }
                .padding()
            }
            .navigationTitle("Create Harvest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createHarvestRecord()
                    }
                    .disabled(isCreatingHarvest)
                }
            }
        }
        .onAppear {
            setupDefaultValues()
        }
        .sheet(isPresented: $showingTeamSelection) {
            TeamSelectionView(selectedTeam: $selectedTeam)
        }
    }
    
    // MARK: - Section Views
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(grow.cultivar?.emoji ?? "🌱")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading) {
                    Text(grow.title ?? "Taco Field")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let cultivarName = grow.seed!.cultivar!.name {
                        Text(cultivarName)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private var harvestDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Harvest Details")
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Harvest dates
                HStack {
                    VStack(alignment: .leading) {
                        Text("Start Date")
                            .font(AppTheme.Typography.labelMedium)
                        DatePicker("Harvest Date", selection: $harvestDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("End Date")
                            .font(AppTheme.Typography.labelMedium)
                        DatePicker("End Date", selection: $harvestEndDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }
                }
                
                // Destination and buyer
                HStack {
                    VStack(alignment: .leading) {
                        Text("Destination")
                            .font(AppTheme.Typography.labelMedium)
                        Picker("Destination", selection: $destination) {
                            ForEach(Harvest.HarvestDestination.allCases, id: \.self) { dest in
                                Text(String(describing: dest).capitalized).tag(dest)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Buyer (Optional)")
                            .font(AppTheme.Typography.labelMedium)
                        TextField("Enter buyer name", text: $buyer)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Notes and lot code
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(AppTheme.Typography.labelMedium)
                    TextField("Harvest notes and observations", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Lot Code (Optional)")
                            .font(AppTheme.Typography.labelMedium)
                        TextField("Auto-generated if empty", text: $lotCode)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Toggle("Certified Organic", isOn: $isCertifiedOrganic)
                        .font(AppTheme.Typography.labelMedium)
                }
            }
        }
    }
    
    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Quantity Information")
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Quantity and unit
                HStack {
                    VStack(alignment: .leading) {
                        Text("Gross Quantity")
                            .font(AppTheme.Typography.labelMedium)
                        TextField("0.0", value: $quantity, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Net Quantity")
                            .font(AppTheme.Typography.labelMedium)
                        TextField("0.0", value: $netQuantity, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Unit")
                            .font(AppTheme.Typography.labelMedium)
                        Picker("Unit", selection: $quantityUnit) {
                            ForEach(Harvest.HarvestUnit.allCases, id: \.self) { unit in
                                Text(unit.symbol).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Container count
                VStack(alignment: .leading) {
                    Text("Container Count")
                        .font(AppTheme.Typography.labelMedium)
                    TextField("Number of containers", value: $containerCount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }
        }
    }
    
    private var complianceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Compliance & Safety")
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Compliance toggles
                HStack {
                    Toggle("Buffer Zone Observed", isOn: $bufferZoneObserved)
                        .font(AppTheme.Typography.labelMedium)
                    
                    Toggle("Compliance Hold", isOn: $complianceHold)
                        .font(AppTheme.Typography.labelMedium)
                }
                
                // Risk assessments
                VStack(spacing: AppTheme.Spacing.small) {
                    compliancePicker(
                        title: "Sanitation Verified",
                        selection: $sanitationVerified
                    )
                    
                    compliancePicker(
                        title: "Commingling Risk",
                        selection: $comminglingRisk
                    )
                    
                    compliancePicker(
                        title: "Contamination Risk",
                        selection: $contaminationRisk
                    )
                }
            }
        }
    }
    
    private var workOrderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Work Order")
                
                Spacer()
                
                Toggle("Create Work Order", isOn: $createWorkOrder)
                    .font(AppTheme.Typography.labelMedium)
            }
            
            if createWorkOrder {
                VStack(spacing: AppTheme.Spacing.medium) {
                    VStack(alignment: .leading) {
                        Text("Work Order Title")
                            .font(AppTheme.Typography.labelMedium)
                        TextField("Work order title", text: $workOrderTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Instructions")
                            .font(AppTheme.Typography.labelMedium)
                        TextField("Detailed instructions for harvest crew", text: $workOrderNotes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Estimated Hours")
                                .font(AppTheme.Typography.labelMedium)
                            TextField("4.0", value: $estimatedHours, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Priority")
                                .font(AppTheme.Typography.labelMedium)
//                            Picker("Priority", selection: $workOrderPriority) {
//                                ForEach(WorkOrder.Priority.allCases, id: \.self) { priority in
//                                    Text(priority.rawValue).tag(priority)
//                                }
//                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    // Team selection
                    Button(action: { showingTeamSelection = true }) {
                        HStack {
                            Text("Assigned Team:")
                                .font(AppTheme.Typography.labelMedium)
                            
                            Spacer()
                            
                            Text(selectedTeam?.name ?? "Select Team")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(selectedTeam != nil ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .padding()
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.small)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func compliancePicker(title: String, selection: Binding<Harvest.ComplianceFlag>) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker(title, selection: selection) {
                ForEach(Harvest.ComplianceFlag.allCases, id: \.self) { flag in
                    Text(String(describing: flag).capitalized).tag(flag)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    // MARK: - Methods
    
    private func setupDefaultValues() {
        // Set default harvest title
        workOrderTitle = "Harvest \(grow.title)"
        
        // Set default notes
        workOrderNotes = "Harvest operations for \(grow.title). Follow all safety protocols and quality standards."
        
        // Set organic status from grow if available
        if let seed = grow.seed {
            isCertifiedOrganic = seed.isCertifiedOrganic
        }
        
        // Set default harvest end date to same day
        harvestEndDate = harvestDate
    }
    
    private func createHarvestRecord() {
        isCreatingHarvest = true
        
        // Create the harvest record
        let harvest = Harvest(context: viewContext)
        harvest.id = UUID()
        harvest.harvestDate = harvestDate
        harvest.harvestDateEnd = harvestEndDate
        harvest.quantityValue = quantity
        harvest.netQuantityValue = netQuantity
        harvest.quantityUnit = quantityUnit
        harvest.containerCount = containerCount
        harvest.harvestDestinationRaw =  1
        harvest.notes = notes
        harvest.buyer = buyer
        harvest.lotCdoe = lotCode.isEmpty ? generateLotCode() : lotCode
        harvest.isCertifiedOrganic = isCertifiedOrganic
        harvest.createdby = "Current User" // TODO: Get from user context
        
        // Set compliance flags
        harvest.sanitationVerified = sanitationVerified
        harvest.comminglingRisk = comminglingRisk
        harvest.contaminationRisk = contaminationRisk
        harvest.complianceHold = complianceHold
        harvest.bufferZoneObserved = bufferZoneObserved
        
        // Create work order if requested
        if createWorkOrder {
//            let workOrder = WorkOrder.createForHarvest(grow, in: viewContext)
//            workOrder.title = workOrderTitle
//            workOrder.notes = workOrderNotes
//            workOrder.totalEstimatedHours = estimatedHours
//            workOrder.priorityLevel = workOrderPriority
//            workOrder.assignedTeam = selectedTeam
//            workOrder.dueDate = harvestDate
            
            // Link harvest to work order (if relationship exists)
            // Note: You may need to add this relationship to the data model
        }
        
        // Save the context
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving harvest: \(error)")
            // TODO: Show error alert
        }
        
        isCreatingHarvest = false
    }
    
    private func generateLotCode() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd"
        let dateString = formatter.string(from: harvestDate)
        
        // Generate format: YYYY-FARM-CROP-####
        let farmCode = "FARM" // TODO: Get from farm configuration
        let cropCode = String(grow.cultivar?.name?.prefix(3).uppercased() ?? "UNK")
        let sequence = String(format: "%04d", Int.random(in: 1...9999))
        
        return "\(year)-\(farmCode)-\(cropCode)-\(sequence)"
    }
}



struct TeamSelectionView: View {
    @Binding var selectedTeam: WorkTeam?
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: WorkTeam.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkTeam.name, ascending: true)]
    ) private var workTeams: FetchedResults<WorkTeam>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(workTeams, id: \.objectID) { team in
                    Button(action: {
                        selectedTeam = team
                        dismiss()
                    }) {
                        HStack {
                            Text(team.name ?? "Unnamed Team")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            if selectedTeam == team {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct HarvestCreationView_Previews: PreviewProvider {
    static var previews: some View {
        HarvestCreationView(
            isPresented: .constant(true),
            grow: Grow() // TODO: Create proper preview grow
        )
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
