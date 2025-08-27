//
//  LedgerView.swift
//  MaterialsAndPractices
//
//  GAAP-compliant ledger view for agricultural business accounting.
//  Provides comprehensive ledger management with detailed entry views.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// GAAP-compliant ledger view for agricultural business accounting
struct LedgerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedAccount: String = "All"
    @State private var selectedDateRange: DateRange = .thisMonth
    @State private var showingNewEntry = false
    @State private var searchText = ""
    
    // Fetch ledger entries
    @FetchRequest(
        entity: LedgerEntry.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \LedgerEntry.date, ascending: false),
            NSSortDescriptor(keyPath: \LedgerEntry.accountCode, ascending: true)
        ]
    ) private var allLedgerEntries: FetchedResults<LedgerEntry>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ledgerSummarySection
                
                filterSection
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(filteredEntries, id: \.objectID) { entry in
                            LedgerEntryRowView(entry: entry)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("General Ledger")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Entry") {
                        showingNewEntry = true
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .searchable(text: $searchText, prompt: "Search entries...")
            .sheet(isPresented: $showingNewEntry) {
                NewLedgerEntryView()
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Summary section showing account balances
    private var ledgerSummarySection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                AccountSummaryCard(
                    title: "Total Assets",
                    amount: calculateBalance(for: .asset),
                    color: AppTheme.Colors.success,
                    icon: "building.columns"
                )
                
                AccountSummaryCard(
                    title: "Total Revenue",
                    amount: calculateBalance(for: .revenue),
                    color: AppTheme.Colors.primary,
                    icon: "arrow.up.circle"
                )
                
                AccountSummaryCard(
                    title: "Total Expenses",
                    amount: calculateBalance(for: .expense),
                    color: AppTheme.Colors.warning,
                    icon: "arrow.down.circle"
                )
            }
            
            Divider()
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    /// Filter section for accounts and date ranges
    private var filterSection: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Account filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(availableAccounts, id: \.self) { account in
                        AccountFilterChip(
                            account: account,
                            isSelected: selectedAccount == account
                        ) {
                            selectedAccount = account
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Date range filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        DateRangeChip(
                            range: range,
                            isSelected: selectedDateRange == range
                        ) {
                            selectedDateRange = range
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [LedgerEntry] {
        var entries = Array(allLedgerEntries)
        
        // Filter by account
        if selectedAccount != "All" {
            entries = entries.filter { $0.accountName == selectedAccount }
        }
        
        // Filter by date range
        entries = entries.filter { entry in
            guard let entryDate = entry.date else { return false }
            return selectedDateRange.contains(entryDate)
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                (entry.ledgerDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.accountName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.vendorName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return entries
    }
    
    private var availableAccounts: [String] {
        let accounts = Set(allLedgerEntries.compactMap { $0.accountName })
        return ["All"] + Array(accounts).sorted()
    }
    
    // MARK: - Helper Methods
    
    private func calculateBalance(for type: AccountType) -> Decimal {
        let entries = allLedgerEntries.filter { entry in
            guard let entryType = entry.entryType else { return false }
            switch type {
            case .asset:
                return entryType.lowercased() == "asset"
            case .revenue:
                return entryType.lowercased() == "revenue"
            case .expense:
                return entryType.lowercased() == "expense"
            case .liability:
                return entryType.lowercased() == "liability"
            case .equity:
                return entryType.lowercased() == "equity"
            }
        }
        
        return entries.reduce(0) { result, entry in
            if type == .expense || type == .asset {
                return result + (entry.debitAmount?.decimalValue ?? 0) - (entry.creditAmount?.decimalValue ?? 0)
            } else {
                return result + (entry.creditAmount?.decimalValue ?? 0) - (entry.debitAmount?.decimalValue ?? 0)
            }
        }
    }
}

// MARK: - Supporting Types

enum AccountType {
    case asset, liability, equity, revenue, expense
}

enum DateRange: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisQuarter = "This Quarter"
    case thisYear = "This Year"
    case all = "All Time"
    
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .thisQuarter:
            let nowQuarter = calendar.component(.quarter, from: now)
            let dateQuarter = calendar.component(.quarter, from: date)
            let nowYear = calendar.component(.year, from: now)
            let dateYear = calendar.component(.year, from: date)
            return nowQuarter == dateQuarter && nowYear == dateYear
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .all:
            return true
        }
    }
}

// MARK: - Supporting Views

/// Account summary card showing balance information
struct AccountSummaryCard: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(formatCurrency(amount))
                .font(AppTheme.Typography.headlineSmall)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(title)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// Account filter chip
struct AccountFilterChip: View {
    let account: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(account)
                .font(AppTheme.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Date range filter chip
struct DateRangeChip: View {
    let range: DateRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(range.rawValue)
                .font(AppTheme.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(isSelected ? AppTheme.Colors.secondary : AppTheme.Colors.backgroundPrimary)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Individual ledger entry row
struct LedgerEntryRowView: View {
    let entry: LedgerEntry
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    HStack {
                        Text(entry.accountCode ?? "")
                            .font(AppTheme.Typography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text(entry.accountName ?? "Unknown Account")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Spacer()
                    }
                    
                    Text(entry.description ?? "No description")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                    
                    if let date = entry.date {
                        Text(date, style: .date)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    if let debit = entry.debitAmount, debit.decimalValue > 0{
                        Text(formatCurrency(debit.decimalValue))
                            .font(AppTheme.Typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.error)
                    }
                    
                    if let credit = entry.creditAmount?.decimalValue, credit > 0 {
                        Text(formatCurrency(credit))
                            .font(AppTheme.Typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                    
                    if entry.reconciled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.success)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            LedgerEntryDetailView(entry: entry)
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// Detailed view for a single ledger entry
struct LedgerEntryDetailView: View {
    let entry: LedgerEntry
    @Environment(\.presentationMode) var presentationMode
    @State private var notes: String = ""
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Entry header
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Ledger Entry Detail")
                            .font(AppTheme.Typography.displaySmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if let date = entry.date {
                            Text(date, style: .date)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    // Account information
                    LedgerDetailSection(title: "Account Information") {
                        LedgerDetailRow(label: "Account Code", value: entry.accountCode ?? "N/A")
                        LedgerDetailRow(label: "Account Name", value: entry.accountName ?? "N/A")
                        LedgerDetailRow(label: "Entry Type", value: entry.entryType?.capitalized ?? "N/A")
                    }
                    
                    // Financial information
                    LedgerDetailSection(title: "Financial Details") {
                        LedgerDetailRow(label: "Debit Amount", value: formatCurrency(entry.debitAmount?.decimalValue ?? 0))
                        LedgerDetailRow(label: "Credit Amount", value: formatCurrency(entry.creditAmount?.decimalValue ?? 0))
                        LedgerDetailRow(label: "Net Amount", value: formatCurrency(entry.amount?.decimalValue ?? 0))
                    }
                    
                    // Reference information
                    LedgerDetailSection(title: "Reference Information") {
                        LedgerDetailRow(label: "Description", value: entry.ledgerDescription ?? "N/A")
                        LedgerDetailRow(label: "Reference Number", value: entry.referenceNumber ?? "N/A")
                        LedgerDetailRow(label: "Check Number", value: entry.checkNumber ?? "N/A")
                        LedgerDetailRow(label: "Vendor", value: entry.vendorName ?? "N/A")
                    }
                    
                    // Notes section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        HStack {
                            Text("Notes")
                                .font(AppTheme.Typography.headlineSmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button(isEditing ? "Save" : "Edit") {
                                if isEditing {
                                    saveNotes()
                                }
                                isEditing.toggle()
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        if isEditing {
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding()
                                .background(AppTheme.Colors.backgroundSecondary)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        } else {
                            Text(notes.isEmpty ? "No notes" : notes)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(AppTheme.Colors.backgroundSecondary)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                notes = entry.notes ?? ""
            }
        }
    }
    
    private func saveNotes() {
        entry.notes = notes
        
        do {
            try entry.managedObjectContext?.save()
        } catch {
            print("❌ Failed to save notes: \(error)")
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// Ledger detail section container
struct LedgerDetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(title)
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                content
            }
            .padding()
            .background(AppTheme.Colors.backgroundSecondary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
}

/// Ledger detail row
struct LedgerDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// New ledger entry view (placeholder)
struct NewLedgerEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("New Ledger Entry")
                    .font(AppTheme.Typography.displayMedium)
                
                Text("Create a new ledger entry")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
