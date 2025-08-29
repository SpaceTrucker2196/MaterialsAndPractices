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
        }
    }

    private func sectionView(_ section: NSFetchedResultsSectionInfo) -> some View {
        Section(header: Text(section.name ?? "Unknown")) {
            let amendments = section.objects as? [CropAmendment] ?? []
            ForEach(amendments, id: \.amendmentID) { amendment in
                AmendmentRowView(amendment: amendment)
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

    var body: some View {
        HStack(spacing: 12) {
            // Icon
//            Image(systemName: amendment.productTypeIcon)
//                .foregroundColor(amendment.statusColor)
//                .frame(width: 24, height: 24)

            // Main Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(amendment.productName ?? "Taco Sauce")
                        .font(.body)
                        .fontWeight(.medium)

                    Spacer()

                    HStack(spacing: 4) {
                        if amendment.omriListed {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        }

//                        if amendment.isLowStock {
//                            Image(systemName: "exclamationmark.triangle.fill")
//                                .foregroundColor(.orange)
//                        }
                    }
                }

                HStack {
                    if let productType = amendment.productType {
                        Text(productType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let supplier = amendment.supplier {
                        Text("• \(supplier.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

//                Text(amendment.inventoryStatusText)
//                    .font(.caption)
//                    .foregroundColor(amendment.isLowStock ? .orange : .secondary)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
    }
}
struct AmendmentCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CropAmendmentCatalogView(context: PersistenceController.preview.container.viewContext)
    }
}
