//
//  AmendmentSelectionView.swift
//  MaterialsAndPractices
//
//  Provides interface for selecting multiple crop amendments for work orders.
//  Supports organic certification compliance tracking and amendment details.
//
//  Created by GitHub Copilot on 12/18/24.
//

import SwiftUI
import CoreData

/// View for selecting multiple crop amendments for work order application
struct AmendmentSelectionView: View {
    // MARK: - Properties
    
    @Binding var selectedAmendments: Set<CropAmendment>
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // State for search and filtering
    @State private var searchText = ""
    @State private var filterByOrganic = false
    
    // Fetch all available amendments
    @FetchRequest(
        entity: CropAmendment.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CropAmendment.omriListed, ascending: false),
            NSSortDescriptor(keyPath: \CropAmendment.productName, ascending: true)
        ]
    ) private var allAmendments: FetchedResults<CropAmendment>
    
    // MARK: - Computed Properties
    
    /// Filtered amendments based on search and filter criteria
    private var filteredAmendments: [CropAmendment] {
        var amendments = Array(allAmendments)
        
        // Apply organic filter
        if filterByOrganic {
            amendments = amendments.filter { $0.omriListed }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            amendments = amendments.filter { amendment in
                amendment.productName.localizedCaseInsensitiveContains(searchText) ||
                amendment.productType.localizedCaseInsensitiveContains(searchText) ||
                amendment.applicationMethod.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return amendments
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
                // Amendments list
                amendmentsList
            }
            .navigationTitle("Select Amendments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            seedAmendmentsIfNeeded()
        }
    }
    
    // MARK: - UI Components
    
    /// Search and filter controls section
    private var searchAndFilterSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                TextField("Search amendments...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(AppTheme.Colors.surfaceSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            
            // Filter toggle
            HStack {
                Toggle("Show only organic (OMRI listed)", isOn: $filterByOrganic)
                    .font(AppTheme.Typography.bodyMedium)
                
                Spacer()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.surface)
    }
    
    /// List of selectable amendments
    private var amendmentsList: some View {
        List {
            if filteredAmendments.isEmpty {
                EmptyStateView()
            } else {
                ForEach(filteredAmendments, id: \.amendmentID) { amendment in
                    AmendmentSelectionRow(
                        amendment: amendment,
                        isSelected: selectedAmendments.contains(amendment),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedAmendments.insert(amendment)
                            } else {
                                selectedAmendments.remove(amendment)
                            }
                        }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Helper Methods
    
    /// Seeds amendments if none exist
    private func seedAmendmentsIfNeeded() {
        if allAmendments.isEmpty {
            CropAmendmentSeeder.seedAmendments(in: viewContext)
        }
    }
}

// MARK: - Amendment Selection Row

/// Individual row for amendment selection with details
struct AmendmentSelectionRow: View {
    let amendment: CropAmendment
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
                    .font(.title3)
                
                // Amendment information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    // Product name and OMRI status
                    HStack {
                        Text(amendment.productName)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Organic certification badge
                        OrganicCertificationBadge(isOMRIListed: amendment.omriListed)
                    }
                    
                    // Product type and application method
                    HStack {
                        Text(amendment.productType)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        
                        Text(amendment.applicationMethod)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Application rate
                    if !amendment.applicationRate.isEmpty && !amendment.unitOfMeasure.isEmpty {
                        Text("Rate: \(amendment.applicationRate) \(amendment.unitOfMeasure)")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.info)
                    }
                    
                    // Safety intervals (if any)
                    if amendment.reEntryIntervalHours > 0 || amendment.preHarvestIntervalDays > 0 {
                        Text(amendment.safetyIntervalInfo)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Organic Certification Badge

/// Badge showing organic certification status
struct OrganicCertificationBadge: View {
    let isOMRIListed: Bool
    
    var body: some View {
        Text(isOMRIListed ? "OMRI" : "CONV")
            .font(AppTheme.Typography.labelSmall)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color(isOMRIListed ? "requiredForOrganic" : "failedForOrganic"))
            )
    }
}

// MARK: - Empty State View

/// View displayed when no amendments match the filter criteria
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No Amendments Found")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Try adjusting your search or filter criteria")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.Spacing.extraLarge)
    }
}

// MARK: - Preview

struct AmendmentSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        return AmendmentSelectionView(
            selectedAmendments: .constant(Set<CropAmendment>()),
            isPresented: .constant(true)
        )
        .environment(\.managedObjectContext, context)
    }
}