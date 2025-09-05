import SwiftUI
import CoreData


struct ApplyWeedAndPestManagmetnDetailView: View {
    @ObservedObject var managment: WeedAndPestManagment
    @ObservedObject var grow: Grow
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    

    // Stable UI state (no direct Core Data bindings)
    @State private var method: WeedAndPestManagmentMethod = .other
    @State private var date: Date = Date()
    @State private var qty: Double = 0
    @State private var unit: String = ""
    @State private var notes: String = ""
    

    init(managment: WeedAndPestManagment, grow:Grow, isPresented: Binding<Bool>) {
        self._managment = ObservedObject(wrappedValue: managment)
        self._grow = ObservedObject(wrappedValue: grow)
        
        // Seed @State from Core Data (INT32 ↔︎ enum conversion here)
        let initialMethod = WeedAndPestManagmentMethod(rawValue: managment.methodRaw) ?? .other
        let initialDate = managment.applicationDate ?? Date()
        let initialQty = managment.quantity
        let initialUnit = managment.quantityUnits ?? ""

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
            Section("Weed and Pest Managment Details") {
                Picker(" Method", selection: $method) {
                    ForEach(WeedAndPestManagmentMethod.allCases) { m in
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
        managment.methodRaw = method.rawValue
        managment.applicationDate = date
        managment.quantity = qty
        managment.quantityUnits = unit

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving Weed and Pest Managment: \(error)")
        }
    }
}
