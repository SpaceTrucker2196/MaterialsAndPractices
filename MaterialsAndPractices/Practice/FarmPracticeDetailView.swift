//
//  FarmPracticeDetailView.swift
//  MaterialsAndPractices
//
//  Detailed view for farm practice information including instructions and requirements
//  Provides comprehensive information about practice implementation and compliance
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Detailed view for a specific farm practice
struct FarmPracticeDetailView: View {
    // MARK: - Properties
    
    let practice: FarmPractice
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Practice header
                    practiceHeaderSection
                    
                    // Description section
                    descriptionSection
                    
                    // Training requirements section
                    trainingSection
                    
                    // Frequency and certification section
                    frequencyCertificationSection
                    
                    // Last updated information
                    lastUpdatedSection
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("Practice Details")
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
    
    // MARK: - Section Views
    
    private var practiceHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(practice.name)
                .font(AppTheme.Typography.headingLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("Practice Guidelines")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.title2)
                
                Text("Description")
                    .font(AppTheme.Typography.headingMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            Text(practice.descriptionText)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: "graduationcap")
                    .foregroundColor(AppTheme.Colors.warning)
                    .font(.title2)
                
                Text("Training Required")
                    .font(AppTheme.Typography.headingMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            Text(practice.trainingRequired)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.warning.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var frequencyCertificationSection: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Frequency
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.Colors.secondary)
                    
                    Text("Frequency")
                        .font(AppTheme.Typography.headingSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                Text(practice.frequency)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            
            // Certification
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: "checkmark.seal")
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Text("Certification")
                        .font(AppTheme.Typography.headingSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                Text(practice.certification)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.success.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.success.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var lastUpdatedSection: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("Last Updated:")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(practice.lastUpdated, style: .date)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.backgroundTertiary)
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Preview

struct FarmPracticeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let practice = FarmPractice(context: context)
        practice.practiceID = UUID()
        practice.name = "🧪 Soil Amendment Recordkeeping"
        practice.descriptionText = "Track all soil inputs including compost, manure, and other amendments. Include source, rate, application method, and dates."
        practice.trainingRequired = "Organic soil health, OMRI-compliant materials handling."
        practice.frequency = "Every amendment event."
        practice.certification = "NOP Organic Certification."
        practice.lastUpdated = Date()
        
        return FarmPracticeDetailView(practice: practice)
    }
}