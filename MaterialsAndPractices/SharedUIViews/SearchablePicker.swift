//
//  SearchablePicker.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 8/31/25.
//


import SwiftUI
import CoreData

struct SearchablePickerView<T: NSManagedObject>: View {
    // MARK: - Typealiases

    typealias LabelProvider = (T) -> String
    typealias SubtitleProvider = (T) -> String?

    // MARK: - Inputs

    @Binding var selectedItem: T?
    @Binding var isPresented: Bool

    var title: String
    var fetchRequest: FetchRequest<T>
    var label: LabelProvider
    var subtitle: SubtitleProvider?

    @State private var searchText = ""

    // MARK: - Computed

    private var items: [T] { Array(fetchRequest.wrappedValue) }
    
    private var filteredItems: [T] {
        if searchText.isEmpty { return items }
        return items.filter {
            let labelText = label($0)
            return labelText.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            List(filteredItems, id: \.objectID) { item in
                Button(action: {
                    selectedItem = item
                    isPresented = false
                }) {
                    VStack(alignment: .leading) {
                        Text(label(item))
                            .font(.headline)
                        if let subtitleText = subtitle?(item) {
                            Text(subtitleText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle(title)
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
        }
    }
}
