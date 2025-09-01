//  CropAmendmentCatalogView.swift
//  MaterialsAndPractices

import SwiftUI
import CoreData

/// ViewModel that wraps an NSFetchedResultsController to support sectioned viewing in SwiftUI
class AmendmentsSectionedFetcher: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var sections: [NSFetchedResultsSectionInfo] = []

    private var controller: NSFetchedResultsController<CropAmendment>

    init(context: NSManagedObjectContext, predicate: NSPredicate? = nil) {
        let request: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CropAmendment.productType, ascending: true),
            NSSortDescriptor(keyPath: \CropAmendment.productName, ascending: true)
        ]
        request.predicate = predicate

        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: #keyPath(CropAmendment.productType),
            cacheName: nil
        )

        super.init()
        controller.delegate = self

        do {
            try controller.performFetch()
            sections = controller.sections ?? []
        } catch {
            print("Failed to fetch amendments: \(error.localizedDescription)")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sections = self.controller.sections ?? []
    }
}

struct CropAmendmentCatalogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var fetcher: AmendmentsSectionedFetcher

    @State private var searchText = ""
    @State private var selectedProductType: String? = nil
    @State private var omriOnly = false
    @State private var lowStockOnly = false
    @State private var showingFilters = false
    @State private var showingNewAmendment = false
    @State private var selectedAmendment: CropAmendment?
    @State private var showingAmendmentDetail = false

    init(context: NSManagedObjectContext) {
        _fetcher = StateObject(wrappedValue: AmendmentsSectionedFetcher(context: context))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterSection

                if fetcher.sections.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(fetcher.sections, id: \ .name) { section in
                            sectionView(section)
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
            }
            .navigationTitle("Amendment Catalog")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewAmendment = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                filterSheet
            }
            .sheet(isPresented: $showingNewAmendment) {
               // CreateAmendmentView(isPresented: $showingNewAmendment)
            }
            .sheet(isPresented: $showingAmendmentDetail) {
                if let amendment = selectedAmendment {
                    AmendmentDetailView(amendment: amendment)
                }
            }
        }
    }

    private func sectionView(_ section: NSFetchedResultsSectionInfo) -> some View {
        Section(header: Text(section.name)) {
            let amendments = section.objects as? [CropAmendment] ?? []
            ForEach(amendments, id: \.amendmentID) { amendment in
                AmendmentRowView(amendment: amendment) {
                    selectedAmendment = amendment
                    showingAmendmentDetail = true
                }
            }
        }
    }

    private var searchAndFilterSection: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
        }
    }

    private var filterSheet: some View {
        Text("Filters go here")
    }

    private var emptyStateView: some View {
        Text("No Amendments Found")
            .foregroundColor(.secondary)
    }
}
/// Individual amendment row view with status indicators
struct AmendmentRowView: View {
    let amendment: CropAmendment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "flask.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 24, height: 24)

                // Main Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(amendment.productName ?? "Unknown Amendment")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()

                        HStack(spacing: 4) {
                            if amendment.omriListed {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(AppTheme.Colors.organicPractice)
                            }

                            // Current inventory indicator
                            let currentInventory = amendment.currentInventoryAmount
                                if currentInventory < 10 { // Low stock threshold
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppTheme.Colors.warning)
                                }
                            
                        }
                    }

                    HStack {
                        if let productType = amendment.productType {
                            Text(productType)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let supplier = amendment.supplierSource {
                            Text("• \(supplier.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        
                        // Current inventory display
                        let currentInventory = amendment.currentInventoryAmount
                        Text("Stock: \(currentInventory, specifier: "%.1f")")
                                .font(.caption)
                                .foregroundColor(currentInventory < 10 ? AppTheme.Colors.warning : .secondary)
                        
                    }
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
struct AmendmentCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CropAmendmentCatalogView(context: PersistenceController.preview.container.viewContext)
    }
}
//
//// MARK: - Amendment Detail View
//
///// Detailed view for individual amendment with editing capabilities
//struct AmendmentDetailView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    let amendment: CropAmendment
//    @Binding var isPresented: Bool
//    @State private var isEditing = false
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
//                    // Header Section
//                    amendmentHeaderSection
//                    
//                    // Product Information Section
//                    productInformationSection
//                    
//                    // Supplier Information Section
//                    if let supplier = amendment.supplierSource {
//                        supplierInformationSection(supplier)
//                    }
//                    
//                    // Inventory Section
//                    inventorySection
//                    
//                    // Application Information Section
//                    applicationInformationSection
//                }
//                .padding()
//            }
//            .navigationTitle(amendment.productName ?? "Amendment")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Close") {
//                        isPresented = false
//                    }
//                }
//                
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Edit") {
//                        isEditing = true
//                    }
//                }
//            }
//            .sheet(isPresented: $isEditing) {
//                EditAmendmentView(amendment: amendment, isPresented: $isEditing)
//            }
//        }
//    }
//    
//    private var amendmentHeaderSection: some View {
//        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
//            HStack {
//                Image(systemName: "flask.fill")
//                    .foregroundColor(AppTheme.Colors.primary)
//                    .font(.title)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(amendment.productName ?? "Unknown Amendment")
//                        .font(AppTheme.Typography.displaySmall)
//                        .fontWeight(.bold)
//                        .foregroundColor(AppTheme.Colors.textPrimary)
//                    
//                    if let productType = amendment.productType {
//                        Text(productType)
//                            .font(AppTheme.Typography.bodyLarge)
//                            .foregroundColor(AppTheme.Colors.textSecondary)
//                    }
//                }
//                
//                Spacer()
//                
//                if amendment.omriListed {
//                    Label("OMRI Listed", systemImage: "checkmark.seal.fill")
//                        .font(AppTheme.Typography.labelMedium)
//                        .foregroundColor(AppTheme.Colors.organicPractice)
//                }
//            }
//        }
//    }
//    
//    private var productInformationSection: some View {
//        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
//            Text("Product Information")
//                .font(AppTheme.Typography.headlineMedium)
//                .fontWeight(.semibold)
//                .foregroundColor(AppTheme.Colors.textPrimary)
//            
//            VStack(spacing: AppTheme.Spacing.small) {
//                if let brand = amendment.brand {
//                    InfoRow(label: "Brand", value: brand)
//                }
//                
//                if let rate = amendment.applicationRate {
//                    InfoRow(label: "Application Rate", value: rate)
//                }
//                
//                if let method = amendment.applicationMethod {
//                    InfoRow(label: "Application Method", value: method)
//                }
//                
//                if let timing = amendment.applicationTiming {
//                    InfoRow(label: "Application Timing", value: timing)
//                }
//            }
//        }
//    }
//    
//    private func supplierInformationSection(_ supplier: SupplierSource) -> some View {
//        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
//            Text("Supplier")
//                .font(AppTheme.Typography.headlineMedium)
//                .fontWeight(.semibold)
//                .foregroundColor(AppTheme.Colors.textPrimary)
//            
//            VStack(spacing: AppTheme.Spacing.small) {
//                InfoRow(label: "Name", value: supplier.name ?? "Unknown")
//                
//                if let contact = supplier.contactName {
//                    InfoRow(label: "Contact", value: contact)
//                }
//                
//                if let phone = supplier.phoneNumber {
//                    InfoRow(label: "Phone", value: phone)
//                }
//                
//                if let email = supplier.email {
//                    InfoRow(label: "Email", value: email)
//                }
//                
//                if supplier.isOrganicCertified {
//                    InfoRow(label: "Organic Certified", value: "Yes")
//                }
//            }
//        }
//    }
//    
//    private var inventorySection: some View {
//        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
//            Text("Inventory")
//                .font(AppTheme.Typography.headlineMedium)
//                .fontWeight(.semibold)
//                .foregroundColor(AppTheme.Colors.textPrimary)
//            
//            VStack(spacing: AppTheme.Spacing.small) {
//                if amendment.currentInventoryAmount > 0 {
//                    InfoRow(
//                        label: "Current Stock",
//                        value: "\(String(format: "%.1f", amendment.currentInventoryAmount)) units"
//                    )
//                    
//                    HStack {
//                        Text("Stock Status:")
//                            .font(AppTheme.Typography.bodyMedium)
//                            .foregroundColor(AppTheme.Colors.textSecondary)
//                        
//                        Spacer()
//                        
//                        Text(amendment.currentInventoryAmount < 10 ? "Low Stock" : "In Stock")
//                            .font(AppTheme.Typography.bodyMedium)
//                            .foregroundColor(amendment.currentInventoryAmount < 10 ? AppTheme.Colors.warning : AppTheme.Colors.success)
//                    }
//                } else {
//                    InfoRow(label: "Current Stock", value: "Not tracked")
//                }
//            }
//        }
//    }
//    
//    private var applicationInformationSection: some View {
//        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
//            Text("Application Information")
//                .font(AppTheme.Typography.headlineMedium)
//                .fontWeight(.semibold)
//                .foregroundColor(AppTheme.Colors.textPrimary)
//            
//            VStack(spacing: AppTheme.Spacing.small) {
//                if let restrictions = amendment.restrictions {
//                    InfoRow(label: "Restrictions", value: restrictions)
//                }
//                
//                if let compatibility = amendment.compatibility {
//                    InfoRow(label: "Compatibility", value: compatibility)
//                }
//                
//                if let notes = amendment.notes {
//                    InfoRow(label: "Notes", value: notes)
//                }
//            }
//        }
//    }
//    
//    
//    // MARK: - Create Amendment View
//    
//    /// View for creating new amendments
//    struct CreateAmendmentView: View {
//        @Environment(\.managedObjectContext) private var viewContext
//        @Binding var isPresented: Bool
//        
//        @State private var productName = ""
//        @State private var productType = ""
//        @State private var brand = ""
//        @State private var applicationRate = ""
//        @State private var applicationMethod = ""
//        @State private var applicationTiming = ""
//        @State private var currentInventory = ""
//        @State private var omriListed = false
//        @State private var notes = ""
//        @State private var selectedSupplier: SupplierSource?
//        @State private var showingSupplierSelection = false
//        
//        // Fetch suppliers for amendment type
//        @FetchRequest(
//            entity: SupplierSource.entity(),
//            sortDescriptors: [NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)],
//            predicate: NSPredicate(format: "supplierType == %@", SupplierKind.amendment.rawValue)
//        ) private var suppliers: FetchedResults<SupplierSource>
//        
//        var isFormValid: Bool {
//            !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
//            !productType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        }
//        
//        var body: some View {
//            NavigationView {
//                Form {
//                    Section("Product Information") {
//                        TextField("Product Name", text: $productName)
//                        TextField("Product Type", text: $productType)
//                        TextField("Brand", text: $brand)
//                    }
//                    
//                    Section("Application") {
//                        TextField("Application Rate", text: $applicationRate)
//                        TextField("Application Method", text: $applicationMethod)
//                        TextField("Application Timing", text: $applicationTiming)
//                    }
//                    
//                    Section("Inventory") {
//                        TextField("Current Inventory Amount", text: $currentInventory)
//                            .keyboardType(.decimalPad)
//                    }
//                    
//                    Section("Supplier") {
//                        HStack {
//                            Text("Supplier")
//                            Spacer()
//                            Button(selectedSupplier?.name ?? "Select Supplier") {
//                                showingSupplierSelection = true
//                            }
//                            .foregroundColor(selectedSupplier == nil ? .blue : .primary)
//                        }
//                        
//                        if let supplier = selectedSupplier {
//                            VStack(alignment: .leading, spacing: 4) {
//                                if let contact = supplier.contactName {
//                                    Text("Contact: \(contact)")
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                }
//                                if supplier.isOrganicCertified {
//                                    Text("Organic Certified")
//                                        .font(.caption)
//                                        .foregroundColor(AppTheme.Colors.organicPractice)
//                                }
//                            }
//                        }
//                    }
//                    
//                    Section("Certification") {
//                        Toggle("OMRI Listed", isOn: $omriListed)
//                    }
//                    
//                    Section("Notes") {
//                        TextField("Additional notes", text: $notes, axis: .vertical)
//                            .lineLimit(3...6)
//                    }
//                    
//                    Section {
//                        Button("Create Amendment") {
//                            createAmendment()
//                        }
//                        .disabled(!isFormValid)
//                    }
//                }
//                .navigationTitle("New Amendment")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button("Cancel") {
//                            isPresented = false
//                        }
//                    }
//                }
//                .sheet(isPresented: $showingSupplierSelection) {
//                    SupplierSelectionForAmendmentView(
//                        suppliers: Array(suppliers),
//                        selectedSupplier: $selectedSupplier,
//                        isPresented: $showingSupplierSelection
//                    )
//                }
//            }
//        }
//        
//        private func createAmendment() {
//            let newAmendment = CropAmendment(context: viewContext)
//            //newAmendment.amendmentID = UUID().uuidString
//            newAmendment.productName = productName.trimmingCharacters(in: .whitespacesAndNewlines)
//            newAmendment.productType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
//            newAmendment.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
//            newAmendment.applicationRate = applicationRate.trimmingCharacters(in: .whitespacesAndNewlines)
//            newAmendment.applicationMethod = applicationMethod.trimmingCharacters(in: .whitespacesAndNewlines)
//            newAmendment.applicationTiming = applicationTiming.trimmingCharacters(in: .whitespacesAndNewlines)
//            newAmendment.omriListed = omriListed
//            newAmendment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
//            newAmendment.supplierSource = selectedSupplier
//            
//            if let inventoryValue = Double(currentInventory.trimmingCharacters(in: .whitespacesAndNewlines)) {
//                newAmendment.currentInventoryAmount = inventoryValue
//            }
//            
//            do {
//                try viewContext.save()
//                isPresented = false
//            } catch {
//                print("Error creating amendment: \(error)")
//            }
//        }
//    }
//    
//    // MARK: - Edit Amendment View
//    
//    /// View for editing existing amendments
//    struct EditAmendmentView: View {
//        @Environment(\.managedObjectContext) private var viewContext
//        let amendment: CropAmendment
//        @Binding var isPresented: Bool
//        
//        @State private var productName = ""
//        @State private var productType = ""
//        @State private var brand = ""
//        @State private var applicationRate = ""
//        @State private var applicationMethod = ""
//        @State private var applicationTiming = ""
//        @State private var currentInventory = ""
//        @State private var omriListed = false
//        @State private var notes = ""
//        @State private var selectedSupplier: SupplierSource?
//        @State private var showingSupplierSelection = false
//        
//        // Fetch suppliers for amendment type
//        @FetchRequest(
//            entity: SupplierSource.entity(),
//            sortDescriptors: [NSSortDescriptor(keyPath: \SupplierSource.name, ascending: true)],
//            predicate: NSPredicate(format: "supplierType == %@", SupplierKind.amendment.rawValue)
//        ) private var suppliers: FetchedResults<SupplierSource>
//        
//        var isFormValid: Bool {
//            !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
//            !productType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//        }
//        
//        var body: some View {
//            NavigationView {
//                Form {
//                    Section("Product Information") {
//                        TextField("Product Name", text: $productName)
//                        TextField("Product Type", text: $productType)
//                        TextField("Brand", text: $brand)
//                    }
//                    
//                    Section("Application") {
//                        TextField("Application Rate", text: $applicationRate)
//                        TextField("Application Method", text: $applicationMethod)
//                        TextField("Application Timing", text: $applicationTiming)
//                    }
//                    
//                    Section("Inventory") {
//                        TextField("Current Inventory Amount", text: $currentInventory)
//                            .keyboardType(.decimalPad)
//                    }
//                    
//                    Section("Supplier") {
//                        HStack {
//                            Text("Supplier")
//                            Spacer()
//                            Button(selectedSupplier?.name ?? "Select Supplier") {
//                                showingSupplierSelection = true
//                            }
//                            .foregroundColor(selectedSupplier == nil ? .blue : .primary)
//                        }
//                        
//                        if let supplier = selectedSupplier {
//                            VStack(alignment: .leading, spacing: 4) {
//                                if let contact = supplier.contactName {
//                                    Text("Contact: \(contact)")
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                }
//                                if supplier.isOrganicCertified {
//                                    Text("Organic Certified")
//                                        .font(.caption)
//                                        .foregroundColor(AppTheme.Colors.organicPractice)
//                                }
//                            }
//                        }
//                    }
//                    
//                    Section("Certification") {
//                        Toggle("OMRI Listed", isOn: $omriListed)
//                    }
//                    
//                    Section("Notes") {
//                        TextField("Additional notes", text: $notes, axis: .vertical)
//                            .lineLimit(3...6)
//                    }
//                    
//                    Section {
//                        Button("Save Changes") {
//                            saveChanges()
//                        }
//                        .disabled(!isFormValid)
//                    }
//                }
//                .navigationTitle("Edit Amendment")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button("Cancel") {
//                            isPresented = false
//                        }
//                    }
//                }
//                .sheet(isPresented: $showingSupplierSelection) {
//                    SupplierSelectionForAmendmentView(
//                        suppliers: Array(suppliers),
//                        selectedSupplier: $selectedSupplier,
//                        isPresented: $showingSupplierSelection
//                    )
//                }
//                .onAppear {
//                    loadAmendmentData()
//                }
//            }
//        }
//        
//        private func loadAmendmentData() {
//            productName = amendment.productName ?? ""
//            productType = amendment.productType ?? ""
//            brand = amendment.brand ?? ""
//            applicationRate = amendment.applicationRate ?? ""
//            applicationMethod = amendment.applicationMethod ?? ""
//            applicationTiming = amendment.applicationTiming ?? ""
//            omriListed = amendment.omriListed
//            notes = amendment.notes ?? ""
//            selectedSupplier = amendment.supplierSource
//            
//            let inventory = amendment.currentInventoryAmount
//            currentInventory = "\(inventory)"
//            
//        }
//        
//        private func saveChanges() {
//            amendment.productName = productName.trimmingCharacters(in: .whitespacesAndNewlines)
//            amendment.productType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
//            amendment.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
//            amendment.applicationRate = applicationRate.trimmingCharacters(in: .whitespacesAndNewlines)
//            amendment.applicationMethod = applicationMethod.trimmingCharacters(in: .whitespacesAndNewlines)
//            amendment.applicationTiming = applicationTiming.trimmingCharacters(in: .whitespacesAndNewlines)
//            amendment.omriListed = omriListed
//            amendment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
//            amendment.supplierSource = selectedSupplier
//            
//            if let inventoryValue = Double(currentInventory.trimmingCharacters(in: .whitespacesAndNewlines)) {
//                amendment.currentInventoryAmount = inventoryValue
//            }
//            
//            do {
//                try viewContext.save()
//                isPresented = false
//            } catch {
//                print("Error saving amendment changes: \(error)")
//            }
//        }
//    }
//    
//    // MARK: - Helper Views
//    
//    /// Information row component
//    struct InfoRow: View {
//        let label: String
//        let value: String
//        
//        var body: some View {
//            HStack {
//                Text(label)
//                    .font(AppTheme.Typography.bodyMedium)
//                    .foregroundColor(AppTheme.Colors.textSecondary)
//                
//                Spacer()
//                
//                Text(value)
//                    .font(AppTheme.Typography.bodyMedium)
//                    .foregroundColor(AppTheme.Colors.textPrimary)
//                    .multilineTextAlignment(.trailing)
//            }
//        }
//    }
//    
//    /// Supplier selection view for amendments
//    struct SupplierSelectionForAmendmentView: View {
//        let suppliers: [SupplierSource]
//        @Binding var selectedSupplier: SupplierSource?
//        @Binding var isPresented: Bool
//        
//        var body: some View {
//            NavigationView {
//                List(suppliers, id: \.id) { supplier in
//                    Button {
//                        selectedSupplier = supplier
//                        isPresented = false
//                    } label: {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(supplier.name ?? "Unknown Supplier")
//                                .font(.headline)
//                                .foregroundColor(.primary)
//                            
//                            if let contact = supplier.contactName {
//                                Text("Contact: \(contact)")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                            }
//                            
//                            if supplier.isOrganicCertified {
//                                Text("Organic Certified")
//                                    .font(.caption)
//                                    .foregroundColor(AppTheme.Colors.organicPractice)
//                            }
//                        }
//                        .padding(.vertical, 4)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//                .navigationTitle("Select Supplier")
//                .navigationBarTitleDisplayMode(.large)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button("Cancel") {
//                            isPresented = false
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
