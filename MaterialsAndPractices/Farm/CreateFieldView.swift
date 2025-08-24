//
//  CreateFieldView.swift
//  MaterialsAndPractices
//
//  Form for creating new fields within a property.
//  Follows app conventions for editing views with proper validation.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Form for creating new fields
struct CreateFieldView: View {
    let property: Property
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var acres = ""
    @State private var hasDrainTile = false
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Field Details") {
                    TextField("Field Name", text: $name)
                    
                    TextField("Acres", text: $acres)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Has Drain Tile", isOn: $hasDrainTile)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Property") {
                    HStack {
                        Text("Property:")
                        Spacer()
                        Text(property.displayName ?? "Unnamed Property")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("New Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveField()
                    }
                    .disabled(name.isEmpty || acres.isEmpty)
                }
            }
        }
    }
    
    private func saveField() {
        let newField = Field(context: viewContext)
        newField.id = UUID()
        newField.name = name.isEmpty ? nil : name
        newField.acres = Double(acres) ?? 0.0
        newField.hasDrainTile = hasDrainTile
        newField.notes = notes.isEmpty ? nil : notes
        newField.property = property
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving field: \(error)")
        }
    }
}

// MARK: - Preview Provider

struct CreateFieldView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let property = Property(context: context)
        property.displayName = "Test Property"
        
        return CreateFieldView(property: property)
            .environment(\.managedObjectContext, context)
    }
}