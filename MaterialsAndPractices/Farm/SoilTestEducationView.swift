//
//  SoilTestEducationView.swift
//  MaterialsAndPractices
//
//  Educational introduction to soil testing for first-time users.
//  Explains importance of soil health monitoring and testing procedures.
//
//  Created by AI Assistant on current date.
//

import SwiftUI

/// Educational view that introduces users to soil testing concepts and procedures
struct SoilTestEducationView: View {
    @Binding var isPresented: Bool
    let onGetStarted: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    
                    // Header with soil icon
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "flask.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Understanding Soil Health")
                            .font(AppTheme.Typography.displayMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, AppTheme.Spacing.large)
                    
                    // Why soil testing matters
                    SectionHeader(title: "Why Monitor Soil Health?")
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        BulletPoint(text: "Optimize plant nutrition and crop yields")
                        BulletPoint(text: "Prevent nutrient deficiencies and toxicities")
                        BulletPoint(text: "Maintain soil pH in optimal range (6.0-7.0 for most crops)")
                        BulletPoint(text: "Track organic matter content for soil biology")
                        BulletPoint(text: "Support beneficial soil microorganisms")
                        BulletPoint(text: "Meet organic certification requirements")
                    }
                    
                    // Soil sampling section
                    SectionHeader(title: "How to Take Soil Samples")
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        Text("For accurate results, follow these USDA guidelines:")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        BulletPoint(text: "Sample when soil is at field moisture capacity (not too wet or dry)")
                        BulletPoint(text: "Take 15-20 random samples across the field")
                        BulletPoint(text: "Sample to 6-8 inch depth for most crops")
                        BulletPoint(text: "Mix samples thoroughly in clean container")
                        BulletPoint(text: "Submit 1-2 cups of mixed soil to certified lab")
                        BulletPoint(text: "Test every 2-3 years or when problems arise")
                    }
                    
                    // Key soil metrics
                    SectionHeader(title: "Understanding Soil Test Results")
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        SoilMetricInfo(
                            name: "pH Level",
                            description: "Measures soil acidity/alkalinity. Most crops prefer 6.0-7.0.",
                            icon: "thermometer"
                        )
                        
                        SoilMetricInfo(
                            name: "Organic Matter",
                            description: "Indicates soil biological activity. Target 3-5% for healthy soil.",
                            icon: "leaf.fill"
                        )
                        
                        SoilMetricInfo(
                            name: "Phosphorus (P)",
                            description: "Essential for root development and flowering. Measured in ppm.",
                            icon: "flowerchart.fill"
                        )
                        
                        SoilMetricInfo(
                            name: "Potassium (K)",
                            description: "Important for disease resistance and water regulation.",
                            icon: "shield.fill"
                        )
                        
                        SoilMetricInfo(
                            name: "CEC",
                            description: "Cation Exchange Capacity - soil's ability to hold nutrients.",
                            icon: "arrow.up.arrow.down"
                        )
                    }
                    
                    // Soil microbes section
                    SectionHeader(title: "Soil Microbe Health")
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        Text("Healthy soil is alive with billions of beneficial microorganisms that:")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        BulletPoint(text: "Break down organic matter into plant-available nutrients")
                        BulletPoint(text: "Form symbiotic relationships with plant roots")
                        BulletPoint(text: "Improve soil structure and water retention")
                        BulletPoint(text: "Suppress harmful pathogens naturally")
                        
                        Text("⚠️ Chemical fertilizers can disrupt soil microbe communities")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.warning)
                            .padding(.top, AppTheme.Spacing.small)
                        
                        Text("Organic farming practices promote diverse, healthy soil biology through compost, cover crops, and minimal tillage.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Get started button
                    CommonActionButton(title: "Let's Get Started") {
                        onGetStarted()
                    }
                    .padding(.top, AppTheme.Spacing.large)
                }
                .padding()
            }
            .navigationTitle("Soil Testing Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// Component for displaying bullet points with consistent styling
struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Text("•")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(text)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

/// Component for displaying soil metric information
struct SoilMetricInfo: View {
    let name: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(name)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Preview Provider

struct SoilTestEducationView_Previews: PreviewProvider {
    static var previews: some View {
        SoilTestEducationView(isPresented: .constant(true)) {
            // Preview action
        }
    }
}