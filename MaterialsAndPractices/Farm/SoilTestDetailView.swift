//
//  SoilTestDetailView.swift
//  MaterialsAndPractices
//
//  Comprehensive soil test detail view with graphics and interpretations.
//  Shows full analysis of soil chemistry and health indicators.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Detailed view for individual soil test results
struct SoilTestDetailView: View {
    let soilTest: SoilTest
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                
                // Test Information Header
                testInformationSection
                
                // Visual Soil Health Summary
                SoilHealthSummary(soilTest: soilTest)
                
                // Raw Data Section
                rawDataSection
                
                // Interpretations and Recommendations
                interpretationsSection
                
                // Lab Information
                if soilTest.lab != nil {
                    labInformationSection
                }
            }
            .padding()
        }
        .navigationTitle("Soil Test Results")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditSoilTestView(soilTest: soilTest, isPresented: $isEditing)
        }
    }
    
    // MARK: - Test Information Section
    
    @ViewBuilder
    private var testInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Test Information")
            
            VStack(spacing: AppTheme.Spacing.small) {
                CommonInfoRow(label: "Field:") {
                    Text(soilTest.field?.name ?? "Unknown Field")
                }
                
                if let date = soilTest.date {
                    CommonInfoRow(label: "Test Date:") {
                        Text(date, style: .date)
                    }
                }
                
                if let lab = soilTest.lab {
                    CommonInfoRow(label: "Laboratory:") {
                        NavigationLink(destination: LabDetailView(lab: lab)) {
                            Text(lab.name ?? "Unknown Lab")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                
                CommonInfoRow(label: "Test Age:") {
                    Text(testAge)
                        .foregroundColor(testAgeColor)
                }
            }
        }
    }
    
    // MARK: - Raw Data Section
    
    @ViewBuilder
    private var rawDataSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Test Results")
            
            // Grid of raw values
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                
                RawDataTile(
                    label: "pH",
                    value: soilTest.ph,
                    format: "%.1f",
                    unit: "",
                    color: colorForPH(soilTest.ph)
                )
                
                RawDataTile(
                    label: "Organic Matter",
                    value: soilTest.omPct,
                    format: "%.1f",
                    unit: "%",
                    color: colorForOM(soilTest.omPct)
                )
                
                RawDataTile(
                    label: "Phosphorus",
                    value: soilTest.p_ppm,
                    format: "%.0f",
                    unit: " ppm",
                    color: colorForNutrient(soilTest.p_ppm, type: .phosphorus)
                )
                
                RawDataTile(
                    label: "Potassium",
                    value: soilTest.k_ppm,
                    format: "%.0f",
                    unit: " ppm",
                    color: colorForNutrient(soilTest.k_ppm, type: .potassium)
                )
                
                RawDataTile(
                    label: "CEC",
                    value: soilTest.cec,
                    format: "%.1f",
                    unit: " meq/100g",
                    color: colorForNutrient(soilTest.cec, type: .cec)
                )
            }
        }
    }
    
    // MARK: - Interpretations Section
    
    @ViewBuilder
    private var interpretationsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Soil Health Analysis")
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                
                // pH interpretation
                InterpretationCard(
                    title: "pH Level",
                    interpretation: phInterpretation,
                    recommendations: phRecommendations,
                    status: phStatus
                )
                
                // Organic matter interpretation
                InterpretationCard(
                    title: "Organic Matter",
                    interpretation: omInterpretation,
                    recommendations: omRecommendations,
                    status: omStatus
                )
                
                // Nutrient status summary
                InterpretationCard(
                    title: "Nutrient Availability",
                    interpretation: nutrientSummary,
                    recommendations: nutrientRecommendations,
                    status: overallNutrientStatus
                )
                
                // Soil biology health
                InterpretationCard(
                    title: "Soil Biology Health",
                    interpretation: soilBiologyAnalysis,
                    recommendations: biologyRecommendations,
                    status: biologyStatus
                )
            }
            
            // Lab recommendations if available
            if let recNotes = soilTest.recNotes, !recNotes.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Laboratory Recommendations")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(recNotes)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(AppTheme.Spacing.medium)
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
    }
    
    // MARK: - Lab Information Section
    
    @ViewBuilder
    private var labInformationSection: some View {
        if let lab = soilTest.lab {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                SectionHeader(title: "Laboratory Information")
                
                VStack(spacing: AppTheme.Spacing.small) {
                    CommonInfoRow(label: "Name:") {
                        Text(lab.name ?? "Unknown")
                    }
                    
                    if let phone = lab.phone, !phone.isEmpty {
                        CommonInfoRow(label: "Phone:") {
                            Button(phone) {
                                if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                    
                    if let email = lab.email, !email.isEmpty {
                        CommonInfoRow(label: "Email:") {
                            Button(email) {
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Components
    
    @ViewBuilder
    private func RawDataTile(label: String, value: Double, format: String, unit: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("\(value, specifier: format)\(unit)")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Test Age Calculation
    
    private var testAge: String {
        guard let testDate = soilTest.date else { return "Unknown" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(testDate)
        let days = Int(timeInterval / 86400) // seconds in a day
        
        if days < 30 {
            return "\(days) days ago"
        } else if days < 365 {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s") ago"
        } else {
            let years = days / 365
            return "\(years) year\(years == 1 ? "" : "s") ago"
        }
    }
    
    private var testAgeColor: Color {
        guard let testDate = soilTest.date else { return AppTheme.Colors.textSecondary }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(testDate)
        let days = Int(timeInterval / 86400)
        
        if days < 365 {
            return AppTheme.Colors.success // Recent
        } else if days < 1095 { // 3 years
            return AppTheme.Colors.warning // Getting old
        } else {
            return AppTheme.Colors.error // Very old
        }
    }
    
    // MARK: - Analysis Properties
    
    private var phInterpretation: String {
        switch soilTest.ph {
        case 0..<5.5:
            return "Very acidic soil conditions. Many nutrients become unavailable, and aluminum toxicity may occur."
        case 5.5..<6.0:
            return "Moderately acidic. Good for acid-loving crops like blueberries, potatoes, and rhododendrons."
        case 6.0...7.0:
            return "Optimal pH range for most vegetable crops. Maximum nutrient availability and beneficial microbial activity."
        case 7.0...7.5:
            return "Slightly alkaline. Good for brassicas and legumes. Most nutrients remain available."
        case 7.5...8.0:
            return "Moderately alkaline. Iron and manganese may become less available."
        default:
            return "Very alkaline conditions. Significant nutrient deficiencies likely, especially iron and phosphorus."
        }
    }
    
    private var phRecommendations: String {
        switch soilTest.ph {
        case 0..<5.5:
            return "Apply agricultural lime to raise pH. Consider sulfur for acid-loving plants only."
        case 5.5..<6.0:
            return "Light lime application if growing most vegetables. Perfect for acid-loving crops."
        case 6.0...7.5:
            return "Maintain current pH with balanced organic matter additions."
        default:
            return "Apply sulfur or organic acids to lower pH. Improve drainage if applicable."
        }
    }
    
    private var phStatus: InterpretationStatus {
        switch soilTest.ph {
        case 6.0...7.5: return .good
        case 5.5..<6.0, 7.5...8.0: return .warning
        default: return .poor
        }
    }
    
    private var omInterpretation: String {
        switch soilTest.omPct {
        case 0..<2.0:
            return "Low organic matter indicates poor soil biology and limited nutrient cycling capacity."
        case 2.0..<3.0:
            return "Moderate organic matter. Soil biology is developing but needs continued organic inputs."
        case 3.0...5.0:
            return "Good organic matter levels support healthy soil biology and natural nutrient cycling."
        default:
            return "Excellent organic matter content. Very active soil biology and superior nutrient retention."
        }
    }
    
    private var omRecommendations: String {
        switch soilTest.omPct {
        case 0..<2.0:
            return "Increase compost applications, plant cover crops, reduce tillage, and add organic amendments."
        case 2.0..<3.0:
            return "Continue building with compost, mulch heavily, and maintain cover crops."
        default:
            return "Maintain with light compost applications and organic farming practices."
        }
    }
    
    private var omStatus: InterpretationStatus {
        switch soilTest.omPct {
        case 0..<2.0: return .poor
        case 2.0..<3.0: return .warning
        default: return .good
        }
    }
    
    private var nutrientSummary: String {
        let pStatus = levelForNutrient(soilTest.p_ppm, type: .phosphorus)
        let kStatus = levelForNutrient(soilTest.k_ppm, type: .potassium)
        let cecLevel = levelForNutrient(soilTest.cec, type: .cec)
        
        return "Phosphorus: \(pStatus), Potassium: \(kStatus), CEC: \(cecLevel). CEC indicates the soil's capacity to hold and exchange nutrients."
    }
    
    private var nutrientRecommendations: String {
        var recommendations: [String] = []
        
        if soilTest.p_ppm < 15 {
            recommendations.append("Add phosphorus through bone meal or rock phosphate")
        }
        if soilTest.k_ppm < 100 {
            recommendations.append("Increase potassium with wood ash or greensand")
        }
        if soilTest.cec < 10 {
            recommendations.append("Build CEC with organic matter and clay amendments")
        }
        
        return recommendations.isEmpty ? "Maintain current nutrient levels with balanced fertilization" : recommendations.joined(separator: ". ")
    }
    
    private var overallNutrientStatus: InterpretationStatus {
        let pStatus = soilTest.p_ppm >= 15 ? 1 : 0
        let kStatus = soilTest.k_ppm >= 100 ? 1 : 0
        let cecStatus = soilTest.cec >= 10 ? 1 : 0
        
        let total = pStatus + kStatus + cecStatus
        
        switch total {
        case 3: return .good
        case 1...2: return .warning
        default: return .poor
        }
    }
    
    private var soilBiologyAnalysis: String {
        let omLevel = soilTest.omPct
        let phLevel = soilTest.ph
        
        if omLevel >= 3.0 && phLevel >= 6.0 && phLevel <= 7.5 {
            return "Excellent conditions for soil microorganisms. High organic matter and optimal pH support diverse microbial communities."
        } else if omLevel >= 2.0 && phLevel >= 5.5 && phLevel <= 8.0 {
            return "Good soil biology potential. Conditions support beneficial microorganisms with some limitations."
        } else {
            return "Soil biology may be limited by low organic matter or pH extremes. Microorganism diversity and activity likely reduced."
        }
    }
    
    private var biologyRecommendations: String {
        var recommendations: [String] = []
        
        if soilTest.omPct < 3.0 {
            recommendations.append("Increase organic matter to feed soil microorganisms")
        }
        if soilTest.ph < 6.0 || soilTest.ph > 7.5 {
            recommendations.append("Adjust pH to optimize microbial activity")
        }
        
        recommendations.append("Minimize chemical inputs that harm beneficial microbes")
        recommendations.append("Use compost and mycorrhizal inoculants")
        
        return recommendations.joined(separator: ". ")
    }
    
    private var biologyStatus: InterpretationStatus {
        let omGood = soilTest.omPct >= 3.0
        let phGood = soilTest.ph >= 6.0 && soilTest.ph <= 7.5
        
        if omGood && phGood {
            return .good
        } else if omGood || phGood {
            return .warning
        } else {
            return .poor
        }
    }
    
    // MARK: - Color and Level Helpers
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5, 8.0...: return AppTheme.Colors.error
        case 5.5..<6.0, 7.5..<8.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
    
    private func colorForOM(_ om: Double) -> Color {
        switch om {
        case 0..<2.0: return AppTheme.Colors.error
        case 2.0..<3.0: return AppTheme.Colors.warning
        default: return AppTheme.Colors.success
        }
    }
    
    private func colorForNutrient(_ value: Double, type: NutrientType) -> Color {
        let level = levelForNutrient(value, type: type)
        switch level {
        case "Low": return AppTheme.Colors.error
        case "Medium": return AppTheme.Colors.warning
        case "High": return AppTheme.Colors.success
        default: return AppTheme.Colors.textSecondary
        }
    }
    
    private func levelForNutrient(_ value: Double, type: NutrientType) -> String {
        for range in type.ranges {
            if range.range.contains(value) {
                return range.label
            }
        }
        return "Unknown"
    }
}

// MARK: - Interpretation Card

/// Card component for soil test interpretations
struct InterpretationCard: View {
    let title: String
    let interpretation: String
    let recommendations: String
    let status: InterpretationStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                StatusBadge(status: status)
            }
            
            Text(interpretation)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Recommendations:")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(recommendations)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Status Badge

/// Status indicator badge
struct StatusBadge: View {
    let status: InterpretationStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(status.color)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Interpretation Status

enum InterpretationStatus: String, CaseIterable {
    case good = "Good"
    case warning = "Caution"
    case poor = "Poor"
    
    var color: Color {
        switch self {
        case .good: return AppTheme.Colors.success
        case .warning: return AppTheme.Colors.warning
        case .poor: return AppTheme.Colors.error
        }
    }
}

// MARK: - Edit Soil Test View

/// Form for editing existing soil test data
struct EditSoilTestView: View {
    let soilTest: SoilTest
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var testDate: Date
    @State private var ph: Double
    @State private var organicMatter: Double
    @State private var phosphorus: Double
    @State private var potassium: Double
    @State private var cec: Double
    @State private var recommendationNotes: String
    
    init(soilTest: SoilTest, isPresented: Binding<Bool>) {
        self.soilTest = soilTest
        self._isPresented = isPresented
        self._testDate = State(initialValue: soilTest.date ?? Date())
        self._ph = State(initialValue: soilTest.ph)
        self._organicMatter = State(initialValue: soilTest.omPct)
        self._phosphorus = State(initialValue: soilTest.p_ppm)
        self._potassium = State(initialValue: soilTest.k_ppm)
        self._cec = State(initialValue: soilTest.cec)
        self._recommendationNotes = State(initialValue: soilTest.recNotes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Test Information") {
                    DatePicker("Test Date", selection: $testDate, displayedComponents: .date)
                }
                
                Section("Soil Chemistry") {
                    HStack {
                        Text("pH Level")
                        Spacer()
                        Text("\(ph, specifier: "%.1f")")
                    }
                    Slider(value: $ph, in: 4.0...9.0, step: 0.1)
                    
                    HStack {
                        Text("Organic Matter (%)")
                        Spacer()
                        Text("\(organicMatter, specifier: "%.1f")%")
                    }
                    Slider(value: $organicMatter, in: 0.0...10.0, step: 0.1)
                }
                
                Section("Nutrients") {
                    HStack {
                        Text("Phosphorus (ppm)")
                        Spacer()
                        Text("\(phosphorus, specifier: "%.0f")")
                    }
                    Slider(value: $phosphorus, in: 0...200, step: 1)
                    
                    HStack {
                        Text("Potassium (ppm)")
                        Spacer()
                        Text("\(potassium, specifier: "%.0f")")
                    }
                    Slider(value: $potassium, in: 0...500, step: 5)
                    
                    HStack {
                        Text("CEC (meq/100g)")
                        Spacer()
                        Text("\(cec, specifier: "%.1f")")
                    }
                    Slider(value: $cec, in: 1...40, step: 0.5)
                }
                
                Section("Recommendations") {
                    TextField("Lab recommendations", text: $recommendationNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Soil Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        soilTest.date = testDate
        soilTest.ph = ph
        soilTest.omPct = organicMatter
        soilTest.p_ppm = phosphorus
        soilTest.k_ppm = potassium
        soilTest.cec = cec
        soilTest.recNotes = recommendationNotes.isEmpty ? nil : recommendationNotes
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            print("Error saving soil test: \(error)")
        }
    }
}

// MARK: - Preview Provider

struct SoilTestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let soilTest = SoilTest(context: context)
        soilTest.ph = 6.5
        soilTest.omPct = 3.2
        soilTest.p_ppm = 25
        soilTest.k_ppm = 150
        soilTest.cec = 15
        soilTest.date = Date()
        soilTest.recNotes = "Good soil health overall. Continue current organic practices."
        
        return NavigationView {
            SoilTestDetailView(soilTest: soilTest)
        }
        .environment(\.managedObjectContext, context)
    }
}