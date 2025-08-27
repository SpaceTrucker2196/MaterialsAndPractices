//
//  LeaseManagementView.swift
//  MaterialsAndPractices
//
//  Comprehensive lease management interface providing access to lease creation,
//  monitoring, and management. Follows established UI patterns and provides
//  comprehensive lease workflow management.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Main lease management view for the utilities section
/// Provides comprehensive lease workflow management and monitoring
struct LeaseManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingLeaseCreation = false
    @State private var selectedFilter: LeaseFilter = .all
    
    // Fetch leases from Core Data
    @FetchRequest(
        entity: Lease.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Lease.startDate, ascending: false)
        ]
    ) private var allLeases: FetchedResults<Lease>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                leaseHeaderSection
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.large) {
                        quickActionsSection
                        
                        leaseFilterSection
                        
                        activeLeasesSection
                        
                        upcomingLeasesSection
                        
                        expiredLeasesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Lease Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Lease") {
                        showingLeaseCreation = true
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingLeaseCreation) {
                LeaseCreationWorkflowView(isPresented: $showingLeaseCreation)
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Header section with overview statistics
    private var leaseHeaderSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                LeaseStatCard(
                    title: "Active",
                    value: "\(activeLeases.count)",
                    subtitle: "Leases",
                    color: AppTheme.Colors.success
                )
                
                NavigationLink(destination: PaymentManagementView()) {
                    PaymentStatCard(
                        title: "Payments",
                        value: "\(paymentsDue.count)",
                        subtitle: "Need Attention",
                        color: paymentsDue.isEmpty ? AppTheme.Colors.success : AppTheme.Colors.warning
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                LeaseStatCard(
                    title: "Expiring",
                    value: "\(expiringSoonLeases.count)",
                    subtitle: "This Month",
                    color: AppTheme.Colors.warning
                )
            }
            
            // Payments requiring attention tiles
            if !paymentsDue.isEmpty {
                paymentsRequiringAttentionSection
            }
            
            Divider()
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    /// Quick actions section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Quick Actions")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                
                LeaseActionCard(
                    title: "New Lease",
                    description: "Create a new property lease agreement",
                    icon: "doc.badge.plus",
                    color: AppTheme.Colors.primary
                ) {
                    showingLeaseCreation = true
                }
                
                NavigationLink(destination: LeaseRenewalsView()) {
                    LeaseActionCardView(
                        title: "Renewals",
                        description: "Manage lease renewals and extensions",
                        icon: "arrow.clockwise.circle.fill",
                        color: AppTheme.Colors.secondary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: PaymentManagementView()) {
                    LeaseActionCardView(
                        title: "Payments",
                        description: "Track lease payments and history",
                        icon: "dollarsign.circle.fill",
                        color: AppTheme.Colors.compliance
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                LeaseActionCard(
                    title: "Reports",
                    description: "Generate lease and revenue reports",
                    icon: "chart.bar.doc.horizontal.fill",
                    color: AppTheme.Colors.warning
                ) {
                    // Navigate to reports view
                }
            }
        }
    }
    
    /// Lease filter section
    private var leaseFilterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Filter Leases")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(LeaseFilter.allCases, id: \.self) { filter in
                        LeaseFilterCard(
                            filter: filter,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// Active leases section with navigation to detail view
    private var activeLeasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Active Leases")
                Spacer()
                if activeLeases.count > 3 {
                    NavigationLink("View All", destination: AllLeasesListView(leases: activeLeases))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if activeLeases.isEmpty {
                LeaseEmptyStateView(
                    icon: "doc.text",
                    title: "No Active Leases",
                    description: "Create a lease to get started",
                    actionTitle: "Create Lease"
                ) {
                    showingLeaseCreation = true
                }
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(activeLeases.prefix(3)), id: \.objectID) { lease in
                        NavigationLink(destination: LeaseDetailView(lease: lease)) {
                            LeaseRowView(lease: lease)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    /// Upcoming leases section as rows
    private var upcomingLeasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Expiring Soon")
                Spacer()
                if expiringSoonLeases.count > 3 {
                    NavigationLink("View All", destination: AllLeasesListView(leases: expiringSoonLeases))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if expiringSoonLeases.isEmpty {
                Text("No leases expiring in the next 30 days")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(expiringSoonLeases.prefix(3)), id: \.objectID) { lease in
                        NavigationLink(destination: LeaseDetailView(lease: lease)) {
                            LeaseRowView(lease: lease, showExpirationWarning: true)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    /// Expired leases section as rows
    private var expiredLeasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Recently Expired")
                Spacer()
                if expiredLeases.count > 2 {
                    NavigationLink("View All", destination: AllLeasesListView(leases: expiredLeases))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if expiredLeases.isEmpty {
                Text("No recently expired leases")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(expiredLeases.prefix(2)), id: \.objectID) { lease in
                        NavigationLink(destination: LeaseDetailView(lease: lease)) {
                            LeaseRowView(lease: lease, isExpired: true)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var activeLeases: [Lease] {
        allLeases.filter { lease in
            lease.status?.lowercased() == "active"
        }
    }
    
    private var expiringSoonLeases: [Lease] {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return allLeases.filter { lease in
            guard let endDate = lease.endDate else { return false }
            return endDate > Date() && endDate <= thirtyDaysFromNow
        }
    }
    
    private var expiredLeases: [Lease] {
        allLeases.filter { lease in
            guard let endDate = lease.endDate else { return false }
            return endDate < Date()
        }
    }
    
    /// Fetch payments that need attention (overdue or due soon)
    private var paymentsDue: [Payment] {
        let fetchRequest: NSFetchRequest<Payment> = Payment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isPaid == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.dueDate, ascending: true)]
        
        do {
            let allPayments = try viewContext.fetch(fetchRequest)
            let now = Date()
            let thirtyDaysFromNow = now.addingTimeInterval(30 * 24 * 60 * 60)
            
            return allPayments.filter { payment in
                guard let dueDate = payment.dueDate else { return false }
                return dueDate <= thirtyDaysFromNow
            }
        } catch {
            print("❌ Failed to fetch payments: \(error)")
            return []
        }
    }
    
    /// Payments requiring attention section
    private var paymentsRequiringAttentionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Payments Requiring Attention")
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(Array(paymentsDue.prefix(5)), id: \.objectID) { payment in
                        NavigationLink(destination: LeaseDetailView(lease: payment.lease!)) {
                            PaymentTileView(payment: payment)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if paymentsDue.count > 5 {
                        NavigationLink(destination: PaymentManagementView()) {
                            MorePaymentsTileView(count: paymentsDue.count - 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Supporting Types

enum LeaseFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case expiring = "Expiring"
    case expired = "Expired"
    case cash = "Cash Rent"
    case share = "Share Rent"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.text"
        case .active: return "checkmark.circle.fill"
        case .expiring: return "clock.badge.exclamationmark"
        case .expired: return "xmark.circle.fill"
        case .cash: return "dollarsign.circle"
        case .share: return "percent"
        }
    }
}

// MARK: - Supporting Views

/// Statistics card for lease overview
struct LeaseStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.tiny) {
            Text(title)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(value)
                .font(AppTheme.Typography.displaySmall)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Action card for quick actions
struct LeaseActionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                }
                
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .frame(height: 120)
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Filter card for lease categories
struct LeaseFilterCard: View {
    let filter: LeaseFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: filter.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.primary)
                
                Text(filter.displayName)
                    .font(AppTheme.Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Row view for leases
struct LeaseRowView: View {
    let lease: Lease
    var showExpirationWarning: Bool = false
    var isExpired: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(lease.leaseType?.capitalized ?? "Lease")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let property = lease.property {
                    Text(property.displayName ?? "Unknown Property")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                if let startDate = lease.startDate, let endDate = lease.endDate {
                    Text("\(startDate, style: .date) - \(endDate, style: .date)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                if showExpirationWarning {
                    MetadataTag(
                        text: "Expiring Soon",
                        backgroundColor: AppTheme.Colors.warning.opacity(0.2),
                        textColor: AppTheme.Colors.warning
                    )
                } else if isExpired {
                    MetadataTag(
                        text: "Expired",
                        backgroundColor: AppTheme.Colors.error.opacity(0.2),
                        textColor: AppTheme.Colors.error
                    )
                } else {
                    MetadataTag(
                        text: lease.status?.capitalized ?? "Unknown",
                        backgroundColor: AppTheme.Colors.success.opacity(0.2),
                        textColor: AppTheme.Colors.success
                    )
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.caption)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}



/// Empty state view for leases
struct LeaseEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text(title)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(description)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(actionTitle, action: action)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Action card view for navigation links
struct LeaseActionCardView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(title)
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Text(description)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .frame(height: 120)
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .contentShape(Rectangle())
    }
}

/// Payment statistics card for overview
struct PaymentStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.tiny) {
            Text(title)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(value)
                .font(AppTheme.Typography.displaySmall)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(color, lineWidth: 2)
        )
    }
}

/// Payment tile view for horizontal scrolling
struct PaymentTileView: View {
    let payment: Payment
    
    private var statusColor: Color {
        if let dueDate = payment.dueDate, dueDate < Date() {
            return AppTheme.Colors.error
        } else {
            return AppTheme.Colors.warning
        }
    }
    
    private var statusText: String {
        if let dueDate = payment.dueDate, dueDate < Date() {
            return "Overdue"
        } else {
            return "Due Soon"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(statusText)
                    .font(AppTheme.Typography.labelSmall)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.tiny)
                    .background(statusColor)
                    .cornerRadius(AppTheme.CornerRadius.small)
                
                Spacer()
            }
            
            Text(payment.lease?.property?.displayName ?? "Unknown Property")
                .font(AppTheme.Typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
            
            Text(formatCurrency(payment.amount! as Decimal))
                .font(AppTheme.Typography.headlineSmall)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if let dueDate = payment.dueDate {
                Text("Due \(dueDate, style: .date)")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(width: 140)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(statusColor, lineWidth: 2)
        )
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// More payments tile view
struct MorePaymentsTileView: View {
    let count: Int
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "plus.circle.fill")
                .font(.largeTitle)
                .foregroundColor(AppTheme.Colors.primary)
            
            Text("+\(count) more")
                .font(AppTheme.Typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("View All")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.primary)
        }
        .frame(width: 140)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(
                    AppTheme.Colors.primary,
                    style: StrokeStyle(
                        lineWidth: 1,
                        lineCap: .round,
                        dash: [5]
                    )
                )
        )
    }
}

/// Placeholder for all leases list
struct AllLeasesListView: View {
    let leases: [Lease]
    
    var body: some View {
        List {
            ForEach(leases, id: \.objectID) { lease in
                LeaseRowView(lease: lease)
            }
        }
        .navigationTitle("All Leases")
    }
}
