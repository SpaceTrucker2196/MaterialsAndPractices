//
//  ActivePractices.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 9/1/25.
//

import SwiftUI

// MARK: - Lightweight placeholder models you can replace later

struct ActiveSeed: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var cultivar: String?
    var quantity: String?
    var emoji: String = "🌱"
}

struct ActiveAmendment: Identifiable, Hashable {
    let id = UUID()
    var productName: String
    var rateDisplay: String?
    var isOMRI: Bool = false
}

struct ActiveHarvest: Identifiable, Hashable {
    let id = UUID()
    var cropName: String
    var windowDisplay: String?   // e.g., "Weeks 31–34"
    var status: String?          // e.g., "Best", "Good"
    var emoji: String = "🧺"
}

// MARK: - Main View

struct ActivePracticesView: View {
    // Injection points so you can plug in Core Data later
    var seeds: [ActiveSeed] = []
    var amendments: [ActiveAmendment] = []
    var harvests: [ActiveHarvest] = []

    // UI state
    @State private var searchText: String = ""

    // Actions (stubs) you can hook to navigation or creation flows
    var onTapSeed: (ActiveSeed) -> Void = { _ in }
    var onTapAmendment: (ActiveAmendment) -> Void = { _ in }
    var onTapHarvest: (ActiveHarvest) -> Void = { _ in }
    var onSeeAllSeeds: () -> Void = {}
    var onSeeAllAmendments: () -> Void = {}
    var onSeeAllHarvests: () -> Void = {}

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            header
            searchField

            List {
                Section {
                    if filteredSeeds.isEmpty {
                        emptyRow(title: "No active seeds", subtitle: "Add seed lots or import from suppliers.")
                    } else {
                        ForEach(filteredSeeds.prefix(5)) { seed in
                            SeedRow(seed: seed)
                                .contentShape(Rectangle())
                                .onTapGesture { onTapSeed(seed) }
                        }
                    }
                } header: {
                    sectionHeader(title: "Active Seeds", actionTitle: "See all", action: onSeeAllSeeds)
                }

                Section {
                    if filteredAmendments.isEmpty {
                        emptyRow(title: "No active amendments", subtitle: "Track nutrients and applications here.")
                    } else {
                        ForEach(filteredAmendments.prefix(5)) { item in
                            AmendmentRow(amendment: item)
                                .contentShape(Rectangle())
                                .onTapGesture { onTapAmendment(item) }
                        }
                    }
                } header: {
                    sectionHeader(title: "Active Amendments", actionTitle: "See all", action: onSeeAllAmendments)
                }

                Section {
                    if filteredHarvests.isEmpty {
                        emptyRow(title: "No active harvests", subtitle: "Harvest windows will appear as they open.")
                    } else {
                        ForEach(filteredHarvests.prefix(5)) { hv in
                            HarvestRow(harvest: hv)
                                .contentShape(Rectangle())
                                .onTapGesture { onTapHarvest(hv) }
                        }
                    }
                } header: {
                    sectionHeader(title: "Active Harvests", actionTitle: "See all", action: onSeeAllHarvests)
                }
            }
            .listStyle(.insetGrouped)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Active Practices")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Filtering

    private var filteredSeeds: [ActiveSeed] {
        guard !searchText.isEmpty else { return seeds }
        return seeds.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.cultivar?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var filteredAmendments: [ActiveAmendment] {
        guard !searchText.isEmpty else { return amendments }
        return amendments.filter {
            $0.productName.localizedCaseInsensitiveContains(searchText)
            || ($0.rateDisplay?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var filteredHarvests: [ActiveHarvest] {
        guard !searchText.isEmpty else { return harvests }
        return harvests.filter {
            $0.cropName.localizedCaseInsensitiveContains(searchText)
            || ($0.windowDisplay?.localizedCaseInsensitiveContains(searchText) ?? false)
            || ($0.status?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Text("Overview")
                .font(AppTheme.Typography.dataLarge)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
        }
    }

    private var searchField: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textTertiary)
            TextField("Search seeds, amendments, harvests", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func sectionHeader(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
            Button(actionTitle, action: action)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.accent)
                .buttonStyle(.plain)
        }
        .padding(.top, AppTheme.Spacing.small)
    }

    private func emptyRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            Text(title)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            Text(subtitle)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

// MARK: - Row Views

private struct SeedRow: View {
    var seed: ActiveSeed

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Text(seed.emoji)
                .font(.title3)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.surface)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(seed.name)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                if let cultivar = seed.cultivar, !cultivar.isEmpty {
                    Text(cultivar)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let qty = seed.quantity {
                Text(qty)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct AmendmentRow: View {
    var amendment: ActiveAmendment

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: amendment.isOMRI ? "leaf.fill" : "leaf")
                .foregroundColor(amendment.isOMRI ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.surface)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(amendment.productName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                if let rate = amendment.rateDisplay {
                    Text(rate)
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if amendment.isOMRI {
                Text("OMRI")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.success)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(AppTheme.Colors.success.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct HarvestRow: View {
    var harvest: ActiveHarvest

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Text(harvest.emoji)
                .font(.title3)
                .frame(width: 28, height: 28)
                .background(AppTheme.Colors.surface)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(harvest.cropName)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let window = harvest.windowDisplay {
                        Text(window)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    if let status = harvest.status, !status.isEmpty {
                        Text(status)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.accent)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview with sample data

struct ActivePracticesView_Previews: PreviewProvider {
    static var previews: some View {
        let demoSeeds: [ActiveSeed] = [
            .init(name: "Tomato – Cherry Sweet 100", cultivar: "Solanum lycopersicum", quantity: "120 g", emoji: "🍅"),
            .init(name: "Carrot – Nantes", cultivar: "Daucus carota", quantity: "2.0 kg", emoji: "🥕"),
            .init(name: "Basil – Genovese", cultivar: "Ocimum basilicum", quantity: "400 g", emoji: "🌿"),
        ]

        let demoAmendments: [ActiveAmendment] = [
            .init(productName: "Down To Earth – Kelp Meal", rateDisplay: "50 lb/acre", isOMRI: true),
            .init(productName: "Gypsum (Calcium Sulfate)", rateDisplay: "300 lb/acre", isOMRI: false),
            .init(productName: "Compost (Windrowed)", rateDisplay: "5 ton/acre", isOMRI: true),
        ]

        let demoHarvests: [ActiveHarvest] = [
            .init(cropName: "Tomato – Sungold", windowDisplay: "Weeks 30–33", status: "Best", emoji: "🧺"),
            .init(cropName: "Cucumber – Marketmore", windowDisplay: "Weeks 27–31", status: "Good", emoji: "🥒"),
            .init(cropName: "Lettuce – Butterhead", windowDisplay: "Weeks 20–22", status: "Fair", emoji: "🥬"),
        ]

        NavigationView {
            ActivePracticesView(
                seeds: demoSeeds,
                amendments: demoAmendments,
                harvests: demoHarvests
            )
        }
        .preferredColorScheme(.light)

        NavigationView {
            ActivePracticesView(
                seeds: demoSeeds,
                amendments: demoAmendments,
                harvests: demoHarvests
            )
        }
        .preferredColorScheme(.dark)
    }
}
