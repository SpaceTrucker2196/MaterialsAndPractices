//
//  ApplySoilAmendmentDetailView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 9/5/25.
//


import SwiftUI
import CoreData


struct ApplySoilAmendmentDetailView: View {
    @ObservedObject var application: SoilAmendmentApplication
    @ObservedObject var grow: Grow
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    

    // Stable UI state (no direct Core Data bindings)
    @State private var method: ApplicationMethod = .other
    @State private var date: Date = Date()
    @State private var qty: Double = 0
    @State private var unit: String = ""
    

    init(application: SoilAmendmentApplication, grow:Grow, isPresented: Binding<Bool>) {
        self._application = ObservedObject(wrappedValue: application)
        self._grow = ObservedObject(wrappedValue: grow)
        
        // Seed @State from Core Data (INT32 ↔︎ enum conversion here)
        let initialMethod = ApplicationMethod(rawValue: application.applicationMethodRaw) ?? .other
        let initialDate = application.applicationDate ?? Date()
        let initialQty = application.quantity
        let initialUnit = application.quantityUnit ?? ""

        self._method = State(initialValue: initialMethod)
        self._date = State(initialValue: initialDate)
        self._qty = State(initialValue: initialQty)
        self._unit = State(initialValue: initialUnit)
        self._isPresented = isPresented // Assign the binding
    }

    private static let qtyFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 3
        nf.minimumFractionDigits = 0
        return nf
    }()

    var body: some View {
        Form {
            Section("Application Details") {
                Picker("Application Method", selection: $method) {
                    ForEach(ApplicationMethod.allCases) { m in
                        Text(m.displayName).tag(m)
                    }
                }

                DatePicker("Application Date", selection: $date, displayedComponents: .date)

                TextField("Quantity", value: $qty, formatter: Self.qtyFormatter)
                    .keyboardType(.decimalPad)

                TextField("Quantity Unit", text: $unit)
            }

            Section {
                Button("Save Changes") { saveChanges() }
                    .buttonStyle(.borderedProminent)
                Button("Cancel", role: .cancel) { dismiss() }
            }
        }
        .navigationTitle("Soil Amendment Application")
    }

    private func saveChanges() {
        // Write @State back to Core Data (enum.rawValue is Int32)
        application.applicationMethodRaw = method.rawValue
        application.applicationDate = date
        application.quantity = qty
        application.quantityUnit = unit

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving SoilAmendmentApplication: \(error)")
        }
    }
}
