//
//  CreateInfrastructureView.swift
//  MaterialsAndPractices
//
//  Form for creating new infrastructure within a property.
//  Follows app conventions for editing views with proper validation.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Form for creating new infrastructure
struct CreateInfrastructureView: View {
    let property: Property
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var type = ""
    @State private var status = "good"
    @State private var installDate = Date()
    @State private var notes = ""
    
    private let infrastructureTypes = ["fence", "gate", "barn", "storage", "water system", "drainage", "road", "other"]
    private let statusOptions = ["excellent", "good", "fair", "poor", "damaged", "maintenance needed"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Infrastructure Details") {
                    Picker("Type", selection: $type) {
                        Text("Select Type").tag("")
                        ForEach(infrastructureTypes, id: \.self) { infraType in
                            Text(infraType.capitalized).tag(infraType)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { statusOption in
                            Text(statusOption.capitalized).tag(statusOption)
                        }
                    }
                    
                    DatePicker("Install Date", selection: $installDate, displayedComponents: .date)
                    
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
            .navigationTitle("New Infrastructure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveInfrastructure()
                    }
                    .disabled(type.isEmpty)
                }
            }
        }
    }
    
    private func saveInfrastructure() {
        let newInfrastructure = Infrastructure(context: viewContext)
        newInfrastructure.id = UUID()
        newInfrastructure.type = type.isEmpty ? nil : type
        newInfrastructure.status = status
        newInfrastructure.installDate = installDate
        newInfrastructure.notes = notes.isEmpty ? nil : notes
        newInfrastructure.property = property
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving infrastructure: \(error)")
        }
    }
}

// MARK: - Preview Provider

struct CreateInfrastructureView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let property = Property(context: context)
        property.displayName = "Test Property"
        
        return CreateInfrastructureView(property: property)
            .environment(\.managedObjectContext, context)
    }
}