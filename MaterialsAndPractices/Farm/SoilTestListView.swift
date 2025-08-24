//
//  SoilTestListView.swift
//  MaterialsAndPractices
//
//  View for displaying soil test information for a specific field.
//  Provides navigation from grows to related soil data.
//
//  Created by AI Assistant on current date.
//

import SwiftUI
import CoreData

/// View for displaying soil test information for a field
struct SoilTestListView: View {
    let field: Field
    
    var body: some View {
        List {
            if let soilTests = field.soilTests?.allObjects as? [SoilTest],
               !soilTests.isEmpty {
                ForEach(soilTests.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }), id: \.id) { soilTest in
                    SoilTestDetailRow(soilTest: soilTest)
                }
            } else {
                EmptyStateView(
                    title: "No Soil Tests",
                    message: "No soil test data available for this field",
                    systemImage: "flask"
                )
            }
        }
        .navigationTitle("Soil Tests")
        .navigationSubtitle(field.name ?? "Field")
    }
}

/// Detailed row for soil test information
struct SoilTestDetailRow: View {
    let soilTest: SoilTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    if let date = soilTest.date {
                        Text(date, style: .date)
                            .font(AppTheme.Typography.bodyLarge)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    
                    if let labName = soilTest.labName {
                        Text(labName)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    Text("pH: \(soilTest.ph, specifier: "%.1f")")
                        .font(AppTheme.Typography.bodyMedium)
                    
                    Text("OM: \(soilTest.omPct, specifier: "%.1f")%")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // Nutrient information in a grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.small) {
                NutrientInfo(label: "P", value: soilTest.p_ppm, unit: "ppm")
                NutrientInfo(label: "K", value: soilTest.k_ppm, unit: "ppm")
                NutrientInfo(label: "CEC", value: soilTest.cec, unit: "")
            }
            
            if let recNotes = soilTest.recNotes, !recNotes.isEmpty {
                Text(recNotes)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.top, AppTheme.Spacing.small)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

/// Component for displaying nutrient information
struct NutrientInfo: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.tiny) {
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("\(value, specifier: "%.1f")\(unit.isEmpty ? "" : " \(unit)")")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Preview Provider

struct SoilTestListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let field = Field(context: context)
        field.name = "Test Field"
        
        return SoilTestListView(field: field)
            .environment(\.managedObjectContext, context)
    }
}