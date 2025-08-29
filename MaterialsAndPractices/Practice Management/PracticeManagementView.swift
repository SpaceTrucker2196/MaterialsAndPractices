//
//  PracticeManagementView.swift
//  MaterialsAndPractices
//
//  Practice management interface for viewing work orders organized by farm practices
//  Provides comprehensive overview of practice application across work orders
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Practice management view that shows work orders sectioned by practices
struct PracticeManagementView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPractice: FarmPractice?
    @State private var showingPracticeDetail = false
    @State private var showingCreatePractice = false
    
    // Fetch all farm practices
    @FetchRequest(
        entity: FarmPractice.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FarmPractice.name, ascending: true)]
    ) private var farmPractices: FetchedResults<FarmPractice>
    
    // Fetch all work orders
    @FetchRequest(
        entity: WorkOrder.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkOrder.createdDate, ascending: false)]
    ) private var workOrders: FetchedResults<WorkOrder>
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Summary section
                summarySection
                
                // Practices sections
                if farmPractices.isEmpty {
                    emptyPracticesSection
                } else {
                    practicesSectionsView
                }
            }
            .navigationTitle("Practice Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Practice") {
                        showingCreatePractice = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreatePractice) {
            CreatePracticeView()
        }
        .sheet(item: $selectedPractice) { practice in
            FarmPracticeDetailView(practice: practice)
        }
    }
    
    // MARK: - Section Views
    
    private var summarySection: some View {
        Section {
            VStack(spacing: AppTheme.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(farmPractices.count)")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("Total Practices")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(workOrders.count)")
                            .font(AppTheme.Typography.headlineLarge)
                            .foregroundColor(AppTheme.Colors.secondary)
                        Text("Work Orders")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(practicesInUseCount)")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.success)
                        Text("Practices in Use")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(unusedPracticesCount)")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.warning)
                        Text("Unused Practices")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private var emptyPracticesSection: some View {
        Section {
            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: "doc.text.below.ecg")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text("No Farm Practices")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Create your first farm practice to start tracking compliance and training requirements.")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Create Default Practices") {
                    createDefaultPractices()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(AppTheme.Spacing.large)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var practicesSectionsView: some View {
        ForEach(farmPractices, id: \.practiceID) { practice in
            practiceSection(for: practice)
        }
    }
    
    private func practiceSection(for practice: FarmPractice) -> some View {
        let practiceWorkOrders = workOrdersForPractice(practice)
        
        return Section(header: practiceHeaderView(practice: practice)) {
            if practiceWorkOrders.isEmpty {
                HStack {
                    Text("No work orders using this practice")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("Unused")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.warning)
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.warning.opacity(0.2))
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
                .padding(.vertical, AppTheme.Spacing.small)
            } else {
                ForEach(practiceWorkOrders, id: \.id) { workOrder in
                    WorkOrderRowView(workOrder: workOrder)
                }
            }
        }
    }
    
    private func practiceHeaderView(practice: FarmPractice) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(practice.name ?? "Taco Sauce")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(practice.frequency ?? "Weekly")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: { selectedPractice = practice }) {
                Image(systemName: "info.circle")
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func workOrdersForPractice(_ practice: FarmPractice) -> [WorkOrder] {
        return workOrders.filter { workOrder in
            if let practices = workOrder.farmPractices?.allObjects as? [FarmPractice] {
                return practices.contains(practice)
            }
            return false
        }
    }
    
    private var practicesInUseCount: Int {
        farmPractices.filter { practice in
            !workOrdersForPractice(practice).isEmpty
        }.count
    }
    
    private var unusedPracticesCount: Int {
        farmPractices.count - practicesInUseCount
    }
    
    private func createDefaultPractices() {
        let defaultPractices = FarmPractice.createPredefinedPractices(in: viewContext)
        
        do {
            try viewContext.save()
            print("Created \(defaultPractices.count) default farm practices")
        } catch {
            print("Error creating default practices: \(error)")
        }
    }
}

/// Individual work order row view
struct WorkOrderRowView: View {
    let workOrder: WorkOrder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(workOrder.title ?? "Untitled Work Order")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack {
                    if let grow = workOrder.grow {
                        Text(grow.title ?? "Unknown Grow")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let createdDate = workOrder.createdDate {
                        Text(createdDate, style: .date)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            statusIndicator(for: workOrder)
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
    
    private func statusIndicator(for workOrder: WorkOrder) -> some View {
        let color: Color
        let text: String
        
        if workOrder.isCompleted {
            color = AppTheme.Colors.success
            text = "Complete"
        } else if workOrder.status == "in_progress" {
            color = AppTheme.Colors.warning
            text = "In Progress"
        } else {
            color = AppTheme.Colors.textSecondary
            text = "Pending"
        }
        
        return Text(text)
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(color)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

/// Simple create practice view
struct CreatePracticeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var practiceName = ""
    @State private var practiceDescription = ""
    @State private var trainingRequired = ""
    @State private var frequency = ""
    @State private var certification = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Practice Information") {
                    TextField("Practice Name", text: $practiceName)
                    TextField("Description", text: $practiceDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Requirements") {
                    TextField("Training Required", text: $trainingRequired, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Frequency", text: $frequency)
                    TextField("Certification", text: $certification)
                }
            }
            .navigationTitle("New Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePractice()
                    }
                    .disabled(practiceName.isEmpty || practiceDescription.isEmpty)
                }
            }
        }
    }
    
    private func savePractice() {
        let practice = FarmPractice(context: viewContext)
        practice.practiceID = UUID()
        practice.name = practiceName
        practice.descriptionText = practiceDescription
        practice.trainingRequired = trainingRequired.isEmpty ? "No specific training required" : trainingRequired
        practice.frequency = frequency.isEmpty ? "As needed" : frequency
        practice.certification = certification.isEmpty ? "No certification required" : certification
        practice.lastUpdated = Date()
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving practice: \(error)")
        }
    }
}

// MARK: - Preview

struct PracticeManagementView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeManagementView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
