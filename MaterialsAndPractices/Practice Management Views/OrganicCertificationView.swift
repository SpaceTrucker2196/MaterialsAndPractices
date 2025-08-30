//
//  OrganicCertificationView.swift
//  MaterialsAndPractices
//
//  Organic certification view showing checklist of Good Farming Practices
//  with compliance tracking and detailed practice information
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Organic certification view with GoodFarmingPractices checklist
struct OrganicCertificationView: View {
    // MARK: - Properties
    
    let farm: Property
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPractice: GoodFarmingPractices?
    @State private var showingPracticeDetail = false
    @State private var practiceCompletionStatus: [GoodFarmingPractices: Bool] = [:]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Farm header
                    farmHeaderSection
                    
                    // Certification summary
                    certificationSummarySection
                    
                    // Practices by category
                    practicesByCategorySection
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("Organic Certification")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadPracticeCompletionStatus()
        }
        .sheet(isPresented: $showingPracticeDetail) {
            if let practice = selectedPractice {
                PracticeInstructionDetailView(practice: practice, farm: farm)
            }
        }
    }
    
    // MARK: - View Components
    
    private var farmHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.Colors.primary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(farm.displayName ?? "Unnamed Farm")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let address = farm.county {
                        Text(address)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    let location = "\(farm.county ?? "Unknown County"), \(farm.state ?? "Unknown State")"
                    Text(location)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var certificationSummarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text("Certification Requirements")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(completedPracticesCount)/\(GoodFarmingPractices.allCases.count)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Progress bar
            ProgressView(value: practiceCompletionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.organicPractice))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Certification status indicator
            HStack {
                Image(systemName: farm.isOrganicCertified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(farm.isOrganicCertified ? AppTheme.Colors.organicPractice : AppTheme.Colors.warning)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(farm.isOrganicCertified ? "Certified Organic" : "Certification Pending")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let expirationDate = farm.certificationExpirationDate {
                        Text("Expires: \(formattedDate(expirationDate))")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    } else if let inspectionDate = farm.nextInspectionDate {
                        Text("Next Inspection: \(formattedDate(inspectionDate))")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                farm.isOrganicCertified 
                    ? AppTheme.Colors.organicPractice.opacity(0.1)
                    : AppTheme.Colors.warning.opacity(0.1)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private var practicesByCategorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            ForEach(PracticeCategory.allCases, id: \.self) { category in
                practicesCategorySection(for: category)
            }
        }
    }
    
    private func practicesCategorySection(for category: PracticeCategory) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Category header
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)
                
                Text(category.rawValue)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                let categoryPractices = category.practices
                let completedInCategory = categoryPractices.filter { practiceCompletionStatus[$0] == true }.count
                Text("\(completedInCategory)/\(categoryPractices.count)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Practices in category
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(category.practices, id: \.self) { practice in
                    PracticeRequirementRow(
                        practice: practice,
                        isCompleted: practiceCompletionStatus[practice] ?? false,
                        onToggle: { togglePracticeCompletion(practice) },
                        onShowDetail: { showPracticeDetail(practice) }
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var completedPracticesCount: Int {
        practiceCompletionStatus.values.filter { $0 }.count
    }
    
    private var practiceCompletionProgress: Double {
        let total = GoodFarmingPractices.allCases.count
        guard total > 0 else { return 0 }
        return Double(completedPracticesCount) / Double(total)
    }
    
    // MARK: - Methods
    
    private func loadPracticeCompletionStatus() {
        // TODO: Load actual completion status from database
        // For now, initialize with some demo data
        for practice in GoodFarmingPractices.allCases {
            practiceCompletionStatus[practice] = true
        }
    }
    
    private func togglePracticeCompletion(_ practice: GoodFarmingPractices) {
        practiceCompletionStatus[practice] = !(practiceCompletionStatus[practice] ?? false)
        // TODO: Save completion status to database
    }
    
    private func showPracticeDetail(_ practice: GoodFarmingPractices) {
        selectedPractice = practice
        showingPracticeDetail = true
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

/// Individual practice requirement row with checkbox and info button
struct PracticeRequirementRow: View {
    let practice: GoodFarmingPractices
    let isCompleted: Bool
    let onToggle: () -> Void
    let onShowDetail: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Checkbox
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? AppTheme.Colors.organicPractice : AppTheme.Colors.textSecondary)
                
                // Practice content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(practice.name)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(practice.frequency)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text(practice.certification)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(practice.color)
                    }
                }
                
                Spacer()
                
                // Info button
                Button(action: onShowDetail) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(AppTheme.Colors.info)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                isCompleted 
                    ? AppTheme.Colors.organicPractice.opacity(0.1)
                    : AppTheme.Colors.backgroundSecondary
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        isCompleted ? AppTheme.Colors.organicPractice : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Practice Instruction Detail View (Placeholder)

/// Detailed practice instruction view (placeholder implementation)
struct PracticeInstructionDetailView: View {
    let practice: GoodFarmingPractices
    let farm: Property
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Practice header
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        Text(practice.name)
                            .font(AppTheme.Typography.displayMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(practice.description)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Practice details
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        practiceDetailSection("Training Required", practice.trainingRequired)
                        practiceDetailSection("Frequency", practice.frequency)
                        practiceDetailSection("Certification", practice.certification)
                    }
                    
                    // Common farming methods section (placeholder)
                    commonFarmingMethodsSection
                    
                    // Record keeping data section (placeholder)
                    recordKeepingDataSection
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("Practice Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func practiceDetailSection(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(content)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var commonFarmingMethodsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Common Farming Methods")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Detailed instructions using common farming methods to meet this practice will be implemented here. This will include step-by-step guidance, best practices, and compliance tips specific to \(practice.name.dropFirst(3)).")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private var recordKeepingDataSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Record Keeping Data")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            NavigationLink(destination: PracticeReportingView(practice: practice, farm: farm)) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("View Practice Reports")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Access detailed record keeping data and compliance reports for this practice")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Practice Reporting View (Placeholder)

/// Practice reporting view for record keeping data (placeholder implementation)
struct PracticeReportingView: View {
    let practice: GoodFarmingPractices
    let farm: Property
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("Practice Reporting")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Detailed record keeping data and compliance reports for \(practice.name.dropFirst(3)) will be implemented here.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.extraLarge)
        .navigationTitle("Practice Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct OrganicCertificationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleFarm = Property(context: context)
        sampleFarm.displayName = "Montana Floss Farm"
        sampleFarm.county = "Trempealeau"
        sampleFarm.state = "Wisconsin"
        
        return OrganicCertificationView(farm: sampleFarm)
            .environment(\.managedObjectContext, context)
    }
}
