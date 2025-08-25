//
//  CreateSoilTestView.swift
//  MaterialsAndPractices
//
//  Comprehensive soil test data entry form with lab management.
//  Prefills data from previous tests and provides picker interfaces.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Comprehensive soil test creation and editing view
struct CreateSoilTestView: View {
    let field: Field
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest private var labs: FetchedResults<Lab>
    
    // Form state
    @State private var testDate = Date()
    @State private var ph: Double = 6.5
    @State private var organicMatter: Double = 3.0
    @State private var phosphorus: Double = 25.0
    @State private var potassium: Double = 150.0
    @State private var cec: Double = 12.0
    @State private var recommendationNotes = ""
    
    // Lab selection state
    @State private var selectedLab: Lab?
    @State private var showingLabPicker = false
    @State private var showingNewLabForm = false
    
    // UI state
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    init(field: Field) {
        self.field = field
        
        // Setup fetch request for labs
        self._labs = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Lab.name, ascending: true)],
            animation: .default
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Field info section
                Section("Field Information") {
                    HStack {
                        Text("Field:")
                        Spacer()
                        Text(field.name ?? "Unnamed Field")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    HStack {
                        Text("Acres:")
                        Spacer()
                        Text("\(field.acres, specifier: "%.1f")")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Test information
                Section("Test Information") {
                    DatePicker("Test Date", selection: $testDate, displayedComponents: .date)
                    
                    // Lab selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("Laboratory")
                            Spacer()
                            Button(action: { showingLabPicker = true }) {
                                HStack {
                                    Text(selectedLab?.name ?? "Select Lab")
                                        .foregroundColor(selectedLab == nil ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                        }
                        
                        if selectedLab == nil {
                            Text("Select or create a laboratory")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                
                // Soil chemistry section
                Section("Soil Chemistry") {
                    // pH with visual indicator
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("pH Level")
                            Spacer()
                            Text("\(ph, specifier: "%.1f")")
                                .foregroundColor(colorForPH(ph))
                                .fontWeight(.semibold)
                        }
                        
                        Slider(value: $ph, in: 4.0...9.0, step: 0.1)
                            .accentColor(colorForPH(ph))
                        
                        Text(phInterpretation(ph))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Organic Matter
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("Organic Matter (%)")
                            Spacer()
                            Text("\(organicMatter, specifier: "%.1f")%")
                                .foregroundColor(colorForOM(organicMatter))
                                .fontWeight(.semibold)
                        }
                        
                        Slider(value: $organicMatter, in: 0.0...10.0, step: 0.1)
                            .accentColor(colorForOM(organicMatter))
                        
                        Text(omInterpretation(organicMatter))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Nutrients section
                Section("Nutrient Levels") {
                    // Phosphorus
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("Phosphorus (ppm)")
                            Spacer()
                            Text("\(phosphorus, specifier: "%.0f")")
                                .foregroundColor(colorForNutrient(phosphorus, ranges: phosphorusRanges))
                                .fontWeight(.semibold)
                        }
                        
                        Slider(value: $phosphorus, in: 0...200, step: 1)
                            .accentColor(colorForNutrient(phosphorus, ranges: phosphorusRanges))
                        
                        Text(nutrientInterpretation(phosphorus, ranges: phosphorusRanges))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Potassium
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("Potassium (ppm)")
                            Spacer()
                            Text("\(potassium, specifier: "%.0f")")
                                .foregroundColor(colorForNutrient(potassium, ranges: potassiumRanges))
                                .fontWeight(.semibold)
                        }
                        
                        Slider(value: $potassium, in: 0...500, step: 5)
                            .accentColor(colorForNutrient(potassium, ranges: potassiumRanges))
                        
                        Text(nutrientInterpretation(potassium, ranges: potassiumRanges))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // CEC
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("CEC (meq/100g)")
                            Spacer()
                            Text("\(cec, specifier: "%.1f")")
                                .foregroundColor(colorForNutrient(cec, ranges: cecRanges))
                                .fontWeight(.semibold)
                        }
                        
                        Slider(value: $cec, in: 1...40, step: 0.5)
                            .accentColor(colorForNutrient(cec, ranges: cecRanges))
                        
                        Text(nutrientInterpretation(cec, ranges: cecRanges))
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Recommendations
                Section("Lab Recommendations") {
                    TextField("Notes and recommendations from lab", text: $recommendationNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Soil Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSoilTest()
                    }
                    .disabled(selectedLab == nil)
                }
            }
            .onAppear {
                prefillFromPreviousTest()
            }
            .sheet(isPresented: $showingLabPicker) {
                LabSelectionView(
                    selectedLab: $selectedLab,
                    onNewLab: { showingNewLabForm = true }
                )
            }
            .sheet(isPresented: $showingNewLabForm) {
                CreateLabView { newLab in
                    selectedLab = newLab
                    showingNewLabForm = false
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func prefillFromPreviousTest() {
        // Get the most recent soil test for this field
        if let soilTests = field.soilTests?.allObjects as? [SoilTest],
           let latestTest = soilTests.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }).first {
            
            ph = latestTest.ph
            organicMatter = latestTest.omPct
            phosphorus = latestTest.p_ppm
            potassium = latestTest.k_ppm
            cec = latestTest.cec
            selectedLab = latestTest.lab
            recommendationNotes = latestTest.recNotes ?? ""
        }
    }
    
    private func saveSoilTest() {
        guard let lab = selectedLab else {
            validationMessage = "Please select a laboratory"
            showingValidationAlert = true
            return
        }
        
        let soilTest = SoilTest(context: viewContext)
        soilTest.id = UUID()
        soilTest.date = testDate
        soilTest.ph = ph
        soilTest.omPct = organicMatter
        soilTest.p_ppm = phosphorus
        soilTest.k_ppm = potassium
        soilTest.cec = cec
        soilTest.recNotes = recommendationNotes.isEmpty ? nil : recommendationNotes
        soilTest.field = field
        soilTest.lab = lab
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            validationMessage = "Failed to save soil test: \(error.localizedDescription)"
            showingValidationAlert = true
        }
    }
    
    // MARK: - Interpretation Methods
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5: return AppTheme.Colors.error
        case 5.5..<6.0: return AppTheme.Colors.warning
        case 6.0...7.5: return AppTheme.Colors.success
        case 7.5...8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.error
        }
    }
    
    private func phInterpretation(_ ph: Double) -> String {
        switch ph {
        case 0..<5.5: return "Very acidic - may limit nutrient availability"
        case 5.5..<6.0: return "Slightly acidic - good for blueberries, potatoes"
        case 6.0...7.0: return "Optimal range for most crops"
        case 7.0...7.5: return "Slightly alkaline - good for brassicas"
        case 7.5...8.0: return "Alkaline - may reduce iron availability"
        default: return "Very alkaline - significant nutrient limitations"
        }
    }
    
    private func colorForOM(_ om: Double) -> Color {
        switch om {
        case 0..<2.0: return AppTheme.Colors.error
        case 2.0..<3.0: return AppTheme.Colors.warning
        case 3.0...5.0: return AppTheme.Colors.success
        default: return AppTheme.Colors.info
        }
    }
    
    private func omInterpretation(_ om: Double) -> String {
        switch om {
        case 0..<2.0: return "Low - needs organic matter additions"
        case 2.0..<3.0: return "Moderate - continue building with compost"
        case 3.0...5.0: return "Good - maintain with organic practices"
        default: return "Very high - excellent soil biology"
        }
    }
    
    // Nutrient range definitions
    private let phosphorusRanges = [(0..<15.0, "Low"), (15.0..<30.0, "Medium"), (30.0...200.0, "High")]
    private let potassiumRanges = [(0..<100.0, "Low"), (100.0..<200.0, "Medium"), (200.0...500.0, "High")]
    private let cecRanges = [(0..<10.0, "Low"), (10.0..<20.0, "Medium"), (20.0...40.0, "High")]
    
    private func colorForNutrient(_ value: Double, ranges: [(Range<Double>, String)]) -> Color {
        for (range, level) in ranges {
            if range.contains(value) {
                switch level {
                case "Low": return AppTheme.Colors.error
                case "Medium": return AppTheme.Colors.warning
                case "High": return AppTheme.Colors.success
                default: return AppTheme.Colors.textSecondary
                }
            }
        }
        return AppTheme.Colors.textSecondary
    }
    
    private func nutrientInterpretation(_ value: Double, ranges: [(Range<Double>, String)]) -> String {
        for (range, level) in ranges {
            if range.contains(value) {
                return "\(level) level"
            }
        }
        return "Out of range"
    }
}

// MARK: - Preview Provider

struct CreateSoilTestView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let field = Field(context: context)
        field.name = "Test Field"
        field.acres = 10.0
        
        return CreateSoilTestView(field: field)
            .environment(\.managedObjectContext, context)
    }
}