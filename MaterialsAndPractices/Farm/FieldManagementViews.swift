import SwiftUI
import CoreData

// MARK: - Field Row Component

/// Row component for displaying field information in lists
struct FieldRow: View {
    let field: Field
    @State private var latestSoilTest: SoilTest?
    
    var body: some View {
        NavigationLink(destination: FieldDetailView(field: field)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(field.name ?? "Unnamed Field")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        Text("\(field.acres, specifier: "%.1f") acres")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if field.hasDrainTile {
                            MetadataTag(
                                text: "Drain Tile",
                                backgroundColor: AppTheme.Colors.info
                            )
                        }
                        
                        // Soil test status tag
                        if let soilTest = latestSoilTest {
                            // Show pH with appropriate color if recent test exists
                            if isRecentTest(soilTest) {
                                MetadataTag(
                                    text: String(format: "pH %.1f", soilTest.ph),
                                    backgroundColor: colorForPH(soilTest.ph)
                                )
                            } else {
                                // Old test - show warning
                                MetadataTag(
                                    text: "Old Test",
                                    backgroundColor: AppTheme.Colors.warning
                                )
                            }
                        } else {
                            // No test - show yellow warning
                            MetadataTag(
                                text: "No pH Test",
                                backgroundColor: AppTheme.Colors.warning
                            )
                        }
                    }
                }
                
                Spacer()
                
                if field.photoData != nil {
                    Image(systemName: "photo.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.caption)
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
        .onAppear {
            loadLatestSoilTest()
        }
    }
    
    private func loadLatestSoilTest() {
        if let soilTests = field.soilTests?.allObjects as? [SoilTest] {
            latestSoilTest = soilTests
                .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
                .first
        }
    }
    
    private func isRecentTest(_ soilTest: SoilTest) -> Bool {
        guard let testDate = soilTest.date else { return false }
        let daysSinceTest = Calendar.current.dateComponents([.day], from: testDate, to: Date()).day ?? 0
        return daysSinceTest <= 1095 // 3 years
    }
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5, 8.0...: return AppTheme.Colors.error
        case 5.5..<6.0, 7.5..<8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
}

/// Enhanced field row component that ensures proper data prefetching for navigation
struct FieldRowWithPrefetch: View {
    let field: Field
    @Environment(\.managedObjectContext) private var viewContext
    @State private var latestSoilTest: SoilTest?
    @State private var prefetchedField: Field?
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(field.name ?? "Unnamed Field")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        Text("\(field.acres, specifier: "%.1f") acres")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if field.hasDrainTile {
                            MetadataTag(
                                text: "Drain Tile",
                                backgroundColor: AppTheme.Colors.info
                            )
                        }
                        
                        // Soil test status tag
                        if let soilTest = latestSoilTest {
                            // Show pH with appropriate color if recent test exists
                            if isRecentTest(soilTest) {
                                MetadataTag(
                                    text: String(format: "pH %.1f", soilTest.ph),
                                    backgroundColor: colorForPH(soilTest.ph)
                                )
                            } else {
                                // Old test - show warning
                                MetadataTag(
                                    text: "Old Test",
                                    backgroundColor: AppTheme.Colors.warning
                                )
                            }
                        } else {
                            // No test - show yellow warning
                            MetadataTag(
                                text: "No pH Test",
                                backgroundColor: AppTheme.Colors.warning
                            )
                        }
                    }
                }
                
                Spacer()
                
                if field.photoData != nil {
                    Image(systemName: "photo.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.caption)
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
        .onAppear {
            loadLatestSoilTest()
            prefetchFieldData()
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let prefetched = prefetchedField {
            FieldDetailView(field: prefetched)
        } else {
            FieldDetailView(field: field)
        }
    }
    
    private func prefetchFieldData() {
        // Ensure field data and relationships are loaded before navigation
        guard let fieldID = field.id else { return }
        
        let fetchRequest: NSFetchRequest<Field> = Field.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", fieldID as CVarArg)
        fetchRequest.relationshipKeyPathsForPrefetching = [
            "property", "grows", "soilTests", "wells", "grows.workOrders", "grows.harvests"
        ]
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let fetchedField = results.first {
                // Force load relationships to prevent lazy loading issues
                _ = fetchedField.property?.displayName
                _ = fetchedField.grows?.count
                _ = fetchedField.soilTests?.count
                _ = fetchedField.wells?.count
                
                // Force load grow relationships
                if let grows = fetchedField.grows?.allObjects as? [Grow] {
                    for grow in grows {
                        _ = grow.workOrders?.count
                        _ = grow.harvest?.count
                    }
                }
                
                prefetchedField = fetchedField
            }
        } catch {
            print("Error prefetching field data: \(error)")
            // Fall back to original field
        }
    }
    
    private func loadLatestSoilTest() {
        if let soilTests = field.soilTests?.allObjects as? [SoilTest] {
            latestSoilTest = soilTests
                .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
                .first
        }
    }
    
    private func isRecentTest(_ soilTest: SoilTest) -> Bool {
        guard let testDate = soilTest.date else { return false }
        let daysSinceTest = Calendar.current.dateComponents([.day], from: testDate, to: Date()).day ?? 0
        return daysSinceTest <= 1095 // 3 years
    }
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5, 8.0...: return AppTheme.Colors.error
        case 5.5..<6.0, 7.5..<8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
}

// MARK: - Field Detail View

/// Detailed view for field information and management
struct FieldDetailView: View {
    let field: Field
    @State private var isEditing = false
    @State private var showingPhotoCapture = false
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var loadingState = ViewLoadingStateManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Organic Certification Banner
                organicCertificationBanner
                
                // Field Information Section
                fieldInformationSection
                
                // Photo Section
                photoSection
                
                // Soil Tests Section
                soilTestsSection
                
                // Wells Section
                wellsSection
                
                // Grows Section
                growsSection
                
                // Amendments Section
                amendmentsSection
                
                // Harvests Section
                harvestsSection
            }
            .padding()
        }
        .navigationTitle(field.name ?? "Field")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditFieldView(field: field, isPresented: $isEditing)
        }
        .sheet(isPresented: $showingPhotoCapture) {
            FieldPhotoCaptureView(field: field, isPresented: $showingPhotoCapture)
        }
        .dataLoadingState(
            isLoading: loadingState.isLoading,
            hasError: loadingState.hasError,
            errorMessage: loadingState.errorMessage,
            retryAction: loadFieldData
        )
        .onAppear {
            loadFieldData()
        }
        .refreshable {
            loadFieldData()
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadFieldData() {
        loadingState.setLoading(true)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                FieldDataLoader.ensureFieldDataLoaded(field, in: viewContext)
                
                DispatchQueue.main.async {
                    loadingState.setLoading(false)
                }
            } catch {
                DispatchQueue.main.async {
                    loadingState.setError(error)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var organicCertificationBanner: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(AppTheme.Colors.organicMaterial)
                
                Text("Certified Organic Field")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.organicMaterial)
                
                Spacer()
                
                if let inspectionStatus = field.inspectionStatus {
                    MetadataTag(
                        text: inspectionStatus.capitalized,
                        backgroundColor: colorForInspectionStatus(inspectionStatus),
                        textColor: .white
                    )
                }
            }
            
            if let nextInspection = field.nextInspectionDue {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(.caption)
                    
                    Text("Next Inspection: \(nextInspection, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.organicMaterial.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private func colorForInspectionStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "passed", "compliant":
            return AppTheme.Colors.success
        case "pending", "scheduled":
            return AppTheme.Colors.warning
        case "failed", "non-compliant":
            return AppTheme.Colors.error
        default:
            return AppTheme.Colors.info
        }
    }
    
    private var fieldInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Field Information")
            
            VStack(spacing: AppTheme.Spacing.small) {
                InfoBlock(label: "Acres:") {
                    Text("\(field.acres, specifier: "%.1f")")
                }
                
                InfoBlock(label: "Drain Tile:") {
                    Text(field.hasDrainTile ? "Yes" : "No")
                }
                
                if let slope = field.slope, !slope.isEmpty {
                    InfoBlock(label: "Slope:") {
                        Text(slope)
                    }
                }
                
                if let soilType = field.soilType, !soilType.isEmpty {
                    InfoBlock(label: "Soil Type:") {
                        Text(soilType)
                    }
                }
                
                if let soilMapUnits = field.soilMapUnits as? [String], !soilMapUnits.isEmpty {
                    InfoBlock(label: "Soil Map Units:") {
                        Text(soilMapUnits.joined(separator: ", "))
                    }
                }
                
                if let inspectionStatus = field.inspectionStatus, !inspectionStatus.isEmpty {
                    InfoBlock(label: "Inspection Status:") {
                        Text(inspectionStatus.capitalized)
                            .foregroundColor(colorForInspectionStatus(inspectionStatus))
                    }
                }
                
                if let nextInspection = field.nextInspectionDue {
                    InfoBlock(label: "Next Inspection:") {
                        Text(nextInspection, style: .date)
                    }
                }
                
                if let property = field.property {
                    InfoBlock(label: "Property:") {
                        Text(property.displayName ?? "Unnamed Property")
                    }
                }
                
                if let notes = field.notes, !notes.isEmpty {
                    InfoBlock(label: "Notes:") {
                        Text(notes)
                    }
                }
            }
        }
    }
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Photos")
                
                Spacer()
                
                Button(action: {
                    showingPhotoCapture = true
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let photoData = field.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                EmptyStateView(
                    title: "No Photos",
                    message: "Add photos to document field conditions",
                    systemImage: "camera",
                    actionTitle: "Take Photo"
                ) {
                    showingPhotoCapture = true
                }
                .frame(height: 150)
            }
        }
    }
    
    private var soilTestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Soil Tests")
                
                Spacer()
                
                NavigationLink(destination: CreateSoilTestView(field: field)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let soilTests = field.soilTests?.allObjects as? [SoilTest],
               !soilTests.isEmpty {
                
                // Show latest soil test pH spectrum
                if let latestTest = soilTests.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }).first {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Current pH Level")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        PHSpectrumView(currentPH: latestTest.ph, showLabels: false)
                            .frame(height: 40)
                    }
                    .padding(.bottom, AppTheme.Spacing.small)
                }
                
                ForEach(soilTests.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }), id: \.id) { soilTest in
                    SoilTestRow(soilTest: soilTest)
                }
            } else {
                Text("No soil tests recorded")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var wellsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Wells")
                
                Spacer()
                
                NavigationLink(destination: CreateWellView(field: field)) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if let wells = field.wells?.allObjects as? [Well],
               !wells.isEmpty {
                ForEach(wells.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.id) { well in
                    WellRow(well: well)
                }
            } else {
                Text("No wells recorded")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var growsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Associated Grows")
            
            if let grows = field.grows?.allObjects as? [Grow],
               !grows.isEmpty {
                ForEach(grows.sorted(by: { ($0.title ?? "") < ($1.title ?? "") }), id: \.timestamp) { grow in
                    GrowSummaryRow(grow: grow)
                }
            } else {
                Text("No grows in this field")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var amendmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Applied Amendments")
            
            if let amendments = getFieldAmendments(), !amendments.isEmpty {
                ForEach(amendments, id: \.amendmentID) { amendment in
                    AmendmentSummaryRow(amendment: amendment)
                }
            } else {
                Text("No amendments applied to this field")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    private var harvestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Field Harvests")
            
            if let harvests = getFieldHarvests(), !harvests.isEmpty {
                ForEach(harvests, id: \.id) { harvest in
                    HarvestSummaryRow(harvest: harvest)
                }
            } else {
                Text("No harvests recorded for this field")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Gets all amendments applied to grows in this field
    private func getFieldAmendments() -> [CropAmendment]? {
        guard let grows = field.grows?.allObjects as? [Grow] else { return nil }
        
        var allAmendments: [CropAmendment] = []
        
        for grow in grows {
            if let workOrders = grow.workOrders?.allObjects as? [WorkOrder] {
                for workOrder in workOrders {
                    if let amendment = workOrder.amendment {
                        allAmendments.append(amendment)
                    }
                }
            }
        }
        
        return allAmendments.isEmpty ? nil : allAmendments.sorted { 
            ($0.dateApplied ?? Date.distantPast) > ($1.dateApplied ?? Date.distantPast) 
        }
    }
    
    /// Gets all harvests from grows in this field
    private func getFieldHarvests() -> [Harvest]? {
        guard let grows = field.grows?.allObjects as? [Grow] else { return nil }
        
        var allHarvests = [Harvest]()
        
        for grow in grows {
            if let harvests = grow.harvest?.allObjects as? [Harvest] {
                allHarvests.append(contentsOf: harvests)
            }
        }
        
        return allHarvests.isEmpty ? nil : allHarvests.sorted { (a: Harvest, b: Harvest) in
            (a.date ?? .distantPast) > (b.date ?? .distantPast)
        }
    }
}

// MARK: - Edit Field View

/// Form for editing field information
struct EditFieldView: View {
    let field: Field
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var fieldName: String
    @State private var fieldAcres: String
    @State private var fieldHasDrainTile: Bool
    @State private var fieldNotes: String
    @State private var fieldSlope: String
    @State private var fieldSoilType: String
    @State private var fieldInspectionStatus: String
    @State private var fieldNextInspectionDue: Date
    @State private var fieldSoilMapUnits: String
    
    init(field: Field, isPresented: Binding<Bool>) {
        self.field = field
        self._isPresented = isPresented
        self._fieldName = State(initialValue: field.name ?? "")
        self._fieldAcres = State(initialValue: String(field.acres))
        self._fieldHasDrainTile = State(initialValue: field.hasDrainTile)
        self._fieldNotes = State(initialValue: field.notes ?? "")
        self._fieldSlope = State(initialValue: field.slope ?? "")
        self._fieldSoilType = State(initialValue: field.soilType ?? "")
        self._fieldInspectionStatus = State(initialValue: field.inspectionStatus ?? "")
        self._fieldNextInspectionDue = State(initialValue: field.nextInspectionDue ?? Date())
        
        // Convert soil map units array to string for editing
        let soilMapUnitsArray = field.soilMapUnits as? [String] ?? []
        self._fieldSoilMapUnits = State(initialValue: soilMapUnitsArray.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Field Name", text: $fieldName)
                    
                    TextField("Acres", text: $fieldAcres)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Has Drain Tile", isOn: $fieldHasDrainTile)
                }
                
                Section("Soil Information") {
                    TextField("Soil Type", text: $fieldSoilType)
                    
                    TextField("Slope", text: $fieldSlope)
                    
                    TextField("Soil Map Units (comma separated)", text: $fieldSoilMapUnits)
                }
                
                Section("Organic Certification") {
                    Picker("Inspection Status", selection: $fieldInspectionStatus) {
                        Text("Not Selected").tag("")
                        Text("Passed").tag("passed")
                        Text("Pending").tag("pending")
                        Text("Failed").tag("failed")
                        Text("Scheduled").tag("scheduled")
                    }
                    
                    DatePicker("Next Inspection Due", selection: $fieldNextInspectionDue, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $fieldNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveField()
                    }
                    .disabled(fieldName.isEmpty)
                }
            }
        }
    }
    
    private func saveField() {
        field.name = fieldName.isEmpty ? nil : fieldName
        field.acres = Double(fieldAcres) ?? 0.0
        field.hasDrainTile = fieldHasDrainTile
        field.notes = fieldNotes.isEmpty ? nil : fieldNotes
        field.slope = fieldSlope.isEmpty ? nil : fieldSlope
        field.soilType = fieldSoilType.isEmpty ? nil : fieldSoilType
        field.inspectionStatus = fieldInspectionStatus.isEmpty ? nil : fieldInspectionStatus
        field.nextInspectionDue = fieldInspectionStatus.isEmpty ? nil : fieldNextInspectionDue
        
        // Convert comma-separated string back to array for soil map units
        if !fieldSoilMapUnits.isEmpty {
            let soilMapUnitsArray = fieldSoilMapUnits
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            //field.soilMapUnits = soilMapUnitsArray
        } else {
            field.soilMapUnits = nil
        }
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving field: \(error)")
        }
    }
}

// MARK: - Supporting Views

/// Row for displaying soil test information
struct SoilTestRow: View {
    let soilTest: SoilTest
    
    var body: some View {
        NavigationLink(destination: SoilTestDetailView(soilTest: soilTest)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    if let date = soilTest.date {
                        Text(date, style: .date)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    
                    if let labName = soilTest.lab?.name ?? soilTest.labName {
                        Text(labName)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    Text("pH: \(soilTest.ph, specifier: "%.1f")")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(colorForPH(soilTest.ph))
                        .fontWeight(.semibold)
                    
                    Text("OM: \(soilTest.omPct, specifier: "%.1f")%")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5, 8.0...: return AppTheme.Colors.error
        case 5.5..<6.0, 7.5..<8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
}

/// Row for displaying well information
struct WellRow: View {
    let well: Well
    
    var body: some View {
        NavigationLink(destination: WellDetailView(well: well)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(well.name ?? "Unnamed Well")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let wellType = well.wellType {
                        Text(wellType.capitalized)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let status = well.status {
                    MetadataTag(
                        text: status.capitalized,
                        backgroundColor: statusColor(for: status)
                    )
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "active":
            return AppTheme.Colors.success
        case "inactive", "abandoned":
            return AppTheme.Colors.error
        case "maintenance":
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.secondary
        }
    }
}

/// Simplified grow row for field detail view
struct GrowSummaryRow: View {
    let grow: Grow
    
    var body: some View {
        NavigationLink(destination: ActiveGrowDetailView(growViewModel: ActiveGrowViewModel(grow: grow))) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    HStack {
                        Text(grow.title ?? "Unnamed Grow")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        // Organic certification indicator
                        if isOrganicCertified {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(AppTheme.Colors.organicMaterial)
                                .font(.caption)
                        }
                    }
                    
                    if let cultivar = grow.seed?.cultivar {
                        Text(cultivar.name ?? "Unknown Cultivar")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    if let plantedDate = grow.plantedDate {
                        Text(plantedDate, style: .date)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if isOrganicCertified {
                        MetadataTag(
                            text: "Organic",
                            backgroundColor: AppTheme.Colors.organicMaterial.opacity(0.2),
                            textColor: AppTheme.Colors.organicMaterial
                        )
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    /// Determines if this grow is certified organic based on seed and field
    private var isOrganicCertified: Bool {
        // Check if the seed/cultivar is organic
        let seedIsOrganic = grow.seed?.isCertifiedOrganic ?? false
        // Assume field is organic (in real implementation, check field certification)
        let fieldIsOrganic = true
        
        return seedIsOrganic && fieldIsOrganic
    }
}

/// Row for displaying amendment information
struct AmendmentSummaryRow: View {
    let amendment: CropAmendment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                HStack {
                    Text(amendment.productName ?? "Unknown Amendment")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if amendment.omriListed {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(AppTheme.Colors.organicMaterial)
                            .font(.caption)
                    }
                }
                
                if let applicationMethod = amendment.applicationMethod {
                    Text("Applied: \(applicationMethod)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                if let rate = amendment.applicationRate {
                    Text("Rate: \(rate)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                if let date = amendment.dateApplied {
                    Text(date, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                if amendment.omriListed {
                    MetadataTag(
                        text: "OMRI",
                        backgroundColor: AppTheme.Colors.organicMaterial.opacity(0.2),
                        textColor: AppTheme.Colors.organicMaterial
                    )
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

/// Row for displaying harvest information
struct HarvestSummaryRow: View {
    let harvest: Harvest
    
    var body: some View {
        NavigationLink(destination: HarvestDetailView(harvest: harvest)) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    HStack {
                        if let grow = harvest.grow {
                            Text(grow.title ?? "Unknown Grow")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        
                        if isOrganicCertified {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(AppTheme.Colors.organicMaterial)
                                .font(.caption)
                        }
                    }
                    
//                    if let quantity = harvest.quantityUnit, quantity.rawValue > 0 {
//                        Text("Quantity: \(quantity, specifier: "%.1f") lbs")
//                            .font(AppTheme.Typography.bodySmall)
//                            .foregroundColor(AppTheme.Colors.textSecondary)
//                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    if let timestamp = harvest.date {
                        Text(timestamp, style: .date)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if isOrganicCertified {
                        MetadataTag(
                            text: "Organic",
                            backgroundColor: AppTheme.Colors.organicMaterial.opacity(0.2),
                            textColor: AppTheme.Colors.organicMaterial
                        )
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.tiny)
        }
    }
    
    /// Determines if this harvest is certified organic
    private var isOrganicCertified: Bool {
        guard let grow = harvest.grow else { return false }
        let seedIsOrganic = grow.seed?.isCertifiedOrganic ?? false
        let fieldIsOrganic = true // In real implementation, check field certification
        
        return seedIsOrganic && fieldIsOrganic
    }
}

// MARK: - Photo Capture for Fields

/// Photo capture view specifically for fields
struct FieldPhotoCaptureView: View {
    let field: Field
    @Binding var isPresented: Bool
    
    var body: some View {
        GenericPhotoCaptureView(isPresented: $isPresented) { image in
            // Compress image and save to field
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                field.photoData = imageData
                
                // Save context
                do {
                    try field.managedObjectContext?.save()
                } catch {
                    print("Error saving field photo: \(error)")
                }
            }
        }
    }
}

// MARK: - Soil Test Flow Views

/// Main soil test creation flow with education and field selection
struct SoilTestFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEducation = false
    @State private var selectedField: Field?
    @State private var hasSeenEducation = false
    
    // Check if user has seen education before
    @AppStorage("hasSeenSoilTestEducation") private var hasSeenEducationBefore = false
    
    var body: some View {
        Group {
            if shouldShowEducation {
                SoilTestEducationView(isPresented: .constant(true)) {
                    hasSeenEducation = true
                    hasSeenEducationBefore = true
                }
            } else if selectedField == nil {
                FieldSelectionTileView { field in
                    selectedField = field
                }
            } else if let field = selectedField {
                CreateSoilTestView(field: field)
            }
        }
    }
    
    private var shouldShowEducation: Bool {
        // Show education if user hasn't seen it before and hasn't seen it in this session
        return !hasSeenEducationBefore && !hasSeenEducation && !hasExistingSoilTests
    }
    
    private var hasExistingSoilTests: Bool {
        let request: NSFetchRequest<SoilTest> = SoilTest.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
}



/// Placeholder for well creation view
struct CreateWellView: View {
    let field: Field
    
    var body: some View {
        Text("Create Well - Coming Soon")
            .navigationTitle("New Well")
    }
}

/// Placeholder for well detail view
struct WellDetailView: View {
    let well: Well
    
    var body: some View {
        Text("Well Detail - Coming Soon")
            .navigationTitle(well.name ?? "Well")
    }
}

