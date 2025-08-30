//
//  LocationSelectionView.swift
//  MaterialsAndPractices
//
//  Created by Spacetrucker on 8/29/25.
//

import SwiftUI

struct LocationSelectionView: View {
    @Binding var selectedProperty: Property?
    @Binding var selectedField: Field?
    @Binding var showingPropertySelection: Bool
    @Binding var showingFieldSelection: Bool

    var body: some View {
        Section(header: Text("Location")) {
            VStack(alignment: .leading, spacing: 12) {
                // Property selector
                HStack {
                    Text("Property")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { showingPropertySelection = true }) {
                        Text(selectedProperty?.displayName ?? "Select Property")
                            .foregroundColor(selectedProperty == nil ? .blue : .primary)
                    }
                }

                if let property = selectedProperty {
                    if let address = property.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let city = property.city, let state = property.state {
                        Text("\(city), \(state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Field selector
                if selectedProperty != nil {
                    Divider()
                    HStack {
                        Text("Field")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { showingFieldSelection = true }) {
                            Text(selectedField?.name ?? "Select Field")
                                .foregroundColor(selectedField == nil ? .blue : .primary)
                        }
                    }

                    if let field = selectedField {
                      let size = field.acres
                            Text("Size: \(size) acres")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        
                        if let soilType = field.soilType {
                            Text("Soil: \(soilType)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}
