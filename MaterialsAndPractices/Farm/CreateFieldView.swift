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
    
    @State private var fieldName = ""
    @State private var fieldAcres = ""
    @State private var fieldHasDrainTile = false
    @State private var fieldNotes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Field Details") {
                    TextField("Field Name", text: $fieldName)
                    
                    TextField("Acres", text: $fieldAcres)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Has Drain Tile", isOn: $fieldHasDrainTile)
                    
                    TextField("Notes", text: $fieldNotes, axis: .vertical)
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
                    .disabled(fieldName.isEmpty || fieldAcres.isEmpty)
                }
            }
        }
    }
    
    private func saveField() {
        let newField = Field(context: viewContext)
        newField.id = UUID()
        newField.name = fieldName.isEmpty ? nil : fieldName
        newField.acres = Double(fieldAcres) ?? 0.0
        newField.hasDrainTile = fieldHasDrainTile
        newField.notes = fieldNotes.isEmpty ? nil : fieldNotes
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