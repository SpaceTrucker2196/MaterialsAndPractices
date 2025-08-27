//
//  FieldSelectionTileView.swift
//  MaterialsAndPractices
//
//  Tile-based field selection interface for soil test creation.
//  Shows field status and recent soil test information.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// Tile-based view for selecting fields when creating soil tests
struct FieldSelectionTileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Field.name, ascending: true)],
        animation: .default
    )
    private var fields: FetchedResults<Field>
    
    let onFieldSelected: (Field) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: AppTheme.Spacing.medium)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.medium) {
                    ForEach(fields, id: \.id) { field in
                        FieldTile(
                            field: field,
                            onTap: { onFieldSelected(field) }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Select Field")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Individual field tile component
struct FieldTile: View {
    let field: Field
    let onTap: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var latestSoilTest: SoilTest?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Header with field name and status indicators
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    HStack {
                        Text(field.name ?? "Unnamed Field")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        HStack(spacing: AppTheme.Spacing.tiny) {
                            // Lease status indicator
                            leaseStatusIndicator
                            
                            // pH status indicator
                            soilTestStatusBadge
                        }
                    }
                    
                    Text("\(field.acres, specifier: "%.1f") acres")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Recent soil test info or prompt
                if let soilTest = latestSoilTest {
                    recentSoilTestInfo(soilTest)
                } else {
                    noSoilTestPrompt
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadLatestSoilTest()
        }
    }
    
    // MARK: - Status Indicators
    
    /// Lease status indicator for the field
    @ViewBuilder
    private var leaseStatusIndicator: some View {
        let hasActiveLease = LeasePaymentTracker.hasActiveLeaseCoverage(field: field, context: viewContext)
        
        if !hasActiveLease {
            Image(systemName: "dollarsign.circle")
                .foregroundColor(.orange)
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private var soilTestStatusBadge: some View {
        if let soilTest = latestSoilTest {
            // Show pH level with appropriate color
            let phColor = colorForPH(soilTest.ph)
            Text("pH \(soilTest.ph, specifier: "%.1f")")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, AppTheme.Spacing.tiny)
                .background(phColor)
                .cornerRadius(AppTheme.CornerRadius.small)
        } else {
            // Yellow warning for no soil test
            Text("No Test")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(.black)
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, AppTheme.Spacing.tiny)
                .background(AppTheme.Colors.warning)
                .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
    
    // MARK: - Recent Soil Test Info
    
    @ViewBuilder
    private func recentSoilTestInfo(_ soilTest: SoilTest) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            if let date = soilTest.date {
                Text("Last tested: \(date, style: .date)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if let labName = soilTest.labName {
                Text("Lab: \(labName)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            HStack {
                Text("OM: \(soilTest.omPct, specifier: "%.1f")%")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                if soilTest.p_ppm > 0 {
                    Text("P: \(soilTest.p_ppm, specifier: "%.0f")")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var noSoilTestPrompt: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "flask")
                .font(.title3)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("Tap to add first soil test")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadLatestSoilTest() {
        if let soilTests = field.soilTests?.allObjects as? [SoilTest] {
            latestSoilTest = soilTests
                .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
                .first
        }
    }
    
    private func colorForPH(_ ph: Double) -> Color {
        switch ph {
        case 0..<5.5:
            return AppTheme.Colors.error // Very acidic
        case 5.5..<6.0:
            return AppTheme.Colors.warning // Slightly acidic
        case 6.0...7.5:
            return AppTheme.Colors.success // Optimal range
        case 7.5...8.0:
            return AppTheme.Colors.warning // Slightly alkaline
        default:
            return AppTheme.Colors.error // Very alkaline
        }
    }
}

// MARK: - Preview Provider

struct FieldSelectionTileView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample fields
        let field1 = Field(context: context)
        field1.name = "North Field"
        field1.acres = 12.5
        
        let field2 = Field(context: context)
        field2.name = "South Pasture"
        field2.acres = 8.0
        
        // Create sample soil test for field1
        let soilTest = SoilTest(context: context)
        soilTest.ph = 6.5
        soilTest.omPct = 3.2
        soilTest.date = Date()
        soilTest.labName = "AgriLab"
        field1.addToSoilTests(soilTest)
        
        return FieldSelectionTileView { field in
            print("Selected field: \(field.name ?? "Unknown")")
        }
        .environment(\.managedObjectContext, context)
    }
}