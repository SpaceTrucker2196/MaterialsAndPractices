//
//  FarmPracticeSelectionView.swift
//  MaterialsAndPractices
//
//  Farm practice selection view for work orders with detailed practice information
//  Replaces the existing simple practice system with structured FarmPractice entities
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// View for selecting farm practices in work orders
struct FarmPracticeSelectionView: View {
    // MARK: - Properties
    
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedPractices: Set<FarmPractice>
    @State private var showingPracticeDetail: FarmPractice?
    
    // Fetch all available farm practices
    @FetchRequest(
        entity: FarmPractice.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FarmPractice.name, ascending: true)]
    ) private var availablePractices: FetchedResults<FarmPractice>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                Text("Farm Practices")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(selectedPractices.count) selected")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Practice selection list
            if availablePractices.isEmpty {
                // Show empty state with option to create practices
                VStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("No Farm Practices Available")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Create farm practices in Utilities > Practice Management")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.Spacing.large)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    ForEach(availablePractices, id: \.practiceID) { practice in
                        FarmPracticeRow(
                            practice: practice,
                            isSelected: selectedPractices.contains(practice),
                            onToggle: { togglePractice(practice) },
                            onShowDetail: { showingPracticeDetail = practice }
                        )
                    }
                }
            }
        }
        .sheet(item: $showingPracticeDetail) { practice in
            FarmPracticeDetailView(practice: practice)
        }
    }
    
    // MARK: - Private Methods
    
    private func togglePractice(_ practice: FarmPractice) {
        if selectedPractices.contains(practice) {
            selectedPractices.remove(practice)
        } else {
            selectedPractices.insert(practice)
        }
    }
}

/// Individual farm practice row
struct FarmPracticeRow: View {
    let practice: FarmPractice
    let isSelected: Bool
    let onToggle: () -> Void
    let onShowDetail: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Selection checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
            }
            
            // Practice content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(practice.name ?? "Unknown Practice")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(practice.frequency ?? "weekly")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(practice.certification ?? "yes")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.secondary)
            }
            
            Spacer()
            
            // Detail button
            Button(action: onShowDetail) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            isSelected 
                ? AppTheme.Colors.primary.opacity(0.1)
                : AppTheme.Colors.backgroundSecondary
        )
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(
                    isSelected ? AppTheme.Colors.primary : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Preview

struct FarmPracticeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        FarmPracticeSelectionView(selectedPractices: .constant(Set<FarmPractice>()))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .padding()
    }
}
