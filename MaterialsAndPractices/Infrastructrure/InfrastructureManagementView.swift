//  InfrastructureManagementView.swift
//  MaterialsAndPractices
//
//  Provides comprehensive infrastructure management interface for farm equipment,
//  buildings, and systems. Supports infrastructure catalog integration,
//  maintenance tracking, and farm assignment.
//
//  Created by GitHub Copilot on 12/19/24.

import SwiftUI
import CoreData

/// Main infrastructure management view for utilities section
/// Provides access to infrastructure catalog and farm infrastructure management
struct InfrastructureManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingInfrastructureCreation = false
    @State private var showingCatalogBrowser = false

    // Fetch existing infrastructure
    @FetchRequest(
        entity: Infrastructure.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Infrastructure.category, ascending: true),
            NSSortDescriptor(keyPath: \Infrastructure.name, ascending: true)
        ]
    ) private var existingInfrastructure: FetchedResults<Infrastructure>

    // Fetch farms for assignment
    @FetchRequest(
        entity: Property.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Property.displayName, ascending: true)]
    ) private var farmProperties: FetchedResults<Property>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                infrastructureHeaderSection

                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.large) {
                        quickActionsSection

                        if !existingInfrastructure.isEmpty {
                            infrastructureByCategorySection

                            NavigationLink(destination: AllInfrastructureListView()) {
                                HStack {
                                    Text("View All Infrastructure")
                                        .font(AppTheme.Typography.bodyMedium)
                                        .foregroundColor(AppTheme.Colors.primary)
                                    Spacer()
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(AppTheme.Colors.primary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.Colors.textTertiary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(AppTheme.Colors.primary.opacity(0.1))
                                .cornerRadius(AppTheme.CornerRadius.medium)
                            }
                            .padding(.horizontal)
                        } else {
                            infrastructureEmptyState
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Manage Infrastructure")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingInfrastructureCreation) {
                InfrastructureCreationView(isPresented: $showingInfrastructureCreation)
            }
            .sheet(isPresented: $showingCatalogBrowser) {
                InfrastructureCatalogBrowserView(isPresented: $showingCatalogBrowser)
            }
        }
    }

    private var infrastructureHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Infrastructure Overview")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("\(existingInfrastructure.count) items across \(infrastructureCategories.count) categories")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                Spacer()
                if maintenanceDueCount > 0 {
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                        Text("\(maintenanceDueCount)")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.warning)
                        Text("maintenance due")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.Colors.primary.opacity(0.1), AppTheme.Colors.secondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Quick Actions")
            HStack(spacing: AppTheme.Spacing.medium) {
                InfastructureQuickActionButton(
                    title: "Browse Catalog",
                    subtitle: "Common farm equipment",
                    icon: "books.vertical.fill",
                    color: AppTheme.Colors.primary
                ) { showingCatalogBrowser = true }

                InfastructureQuickActionButton(
                    title: "Add Custom",
                    subtitle: "Create new infrastructure",
                    icon: "plus.circle.fill",
                    color: AppTheme.Colors.secondary
                ) { showingInfrastructureCreation = true }
            }
        }
    }

    private var infrastructureByCategorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            ForEach(infrastructureCategories, id: \.self) { category in
                infrastructureCategorySection(category: category)
            }
        }
    }

    private func infrastructureCategorySection(category: String) -> some View {
        let categoryItems = existingInfrastructure.filter { $0.category == category }

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(category)
                    .font(AppTheme.Typography.labelLarge)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
                Text("\(categoryItems.count) items")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.medium) {
                ForEach(categoryItems, id: \.id) { infrastructure in
                    InfrastructureTile(infrastructure: infrastructure)
                }
            }
        }
    }

    private var infrastructureEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text("No Infrastructure Registered")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text("Start by browsing the catalog or adding custom infrastructure items")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: AppTheme.Spacing.medium) {
                CommonActionButton(title: "Browse Catalog", style: .primary) { showingCatalogBrowser = true }
                CommonActionButton(title: "Add Custom", style: .secondary) { showingInfrastructureCreation = true }
            }
        }
        .padding(.vertical, AppTheme.Spacing.extraLarge)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: AppTheme.Spacing.medium), GridItem(.flexible(), spacing: AppTheme.Spacing.medium)]
    }

    private var infrastructureCategories: [String] {
        let categories = Set(existingInfrastructure.compactMap { $0.category })
        return Array(categories).sorted()
    }

    private var maintenanceDueCount: Int {
        existingInfrastructure.filter {
            guard let last = $0.lastServiceDate else { return true }
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            return days > 90
        }.count
    }
}
