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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedAccount: String = "All"
    @State private var selectedDateRange: DateRange = .thisMonth
    @State private var showingNewEntry = false
    @State private var searchText = ""
    @State private var selectedEntry: LedgerEntry?
    
    // Fetch ledger entries
    @FetchRequest(
        entity: LedgerEntry.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \LedgerEntry.date, ascending: false),
            NSSortDescriptor(keyPath: \LedgerEntry.accountCode, ascending: true)
        ]
    ) private var allLedgerEntries: FetchedResults<LedgerEntry>
    
    var body: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .regular && geometry.size.width > 600 {
                // iPad layout with expanded view
                HSplitView {
                    // Master list view
                    VStack(spacing: 0) {
                        ledgerSummarySection
                        filterSection
                        
                        List(filteredEntries, id: \.objectID, selection: $selectedEntry) { entry in
                            LedgerEntryRowView(entry: entry, showDetailSheet: false) {
                                selectedEntry = entry
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search entries...")
                    }
                    .frame(minWidth: 300, maxWidth: 400)
                    
                    // Detail view
                    if let selectedEntry = selectedEntry {
                        LedgerEntryDetailView(entry: selectedEntry, isSheet: false)
                    } else {
                        VStack {
                            Image(systemName: "book.closed")
                                .font(.system(size: 64))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                            
                            Text("Select a ledger entry to view details")
                                .font(AppTheme.Typography.bodyLarge)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.Colors.backgroundSecondary)
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
            } else {
                // iPhone layout with navigation
                NavigationView {
                    VStack(spacing: 0) {
                        ledgerSummarySection
                        
                        filterSection
                        
                        List(filteredEntries, id: \.objectID) { entry in
                            LedgerEntryRowView(entry: entry, showDetailSheet: true) { }
                        }
                        .searchable(text: $searchText, prompt: "Search entries...")
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
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            NewLedgerEntryView()
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
                (entry.vendorName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.referenceNumber?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
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
    let showDetailSheet: Bool
    let onTap: () -> Void
    @State private var showingDetail = false
    
    init(entry: LedgerEntry, showDetailSheet: Bool = true, onTap: @escaping () -> Void = {}) {
        self.entry = entry
        self.showDetailSheet = showDetailSheet
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            if showDetailSheet {
                showingDetail = true
            } else {
                onTap()
            }
        }) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Icon and emoji/symbol
                VStack {
                    if let emoji = entry.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.title2)
                    } else if let symbol = entry.iosSymbol, !symbol.isEmpty {
                        Image(systemName: symbol)
                            .font(.title2)
                            .foregroundColor(AppTheme.Colors.primary)
                    } else {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .frame(width: 40)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    HStack {
                        // Account code with organic certification indicator
                        HStack(spacing: AppTheme.Spacing.tiny) {
                            Text(entry.accountCode ?? "")
                                .font(AppTheme.Typography.bodySmall)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.primary)
                            
                            // Organic certification indicator
                            if isOrganicRelated {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppTheme.Colors.compliance)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Spacer()
                        
                        // Transaction type indicator
                        transactionTypeIndicator
                    }
                    
                    Text(entry.accountName ?? "Unknown Account")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(entry.ledgerDescription ?? "No description")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                    
                    if let date = entry.date {
                        Text(date, style: .date)
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                    if let debit = entry.debitAmount, debit.decimalValue > 0 {
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
            LedgerEntryDetailView(entry: entry, isSheet: true)
        }
    }
    
    private var transactionTypeIndicator: some View {
        HStack(spacing: 4) {
            if let debit = entry.debitAmount, debit.decimalValue > 0 {
                Circle()
                    .fill(AppTheme.Colors.error)
                    .frame(width: 8, height: 8)
            }
            
            if let credit = entry.creditAmount?.decimalValue, credit > 0 {
                Circle()
                    .fill(AppTheme.Colors.success)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var isOrganicRelated: Bool {
        let organicKeywords = ["organic", "compost", "certification", "inspect"]
        let description = (entry.ledgerDescription ?? "").lowercased()
        let notes = (entry.notes ?? "").lowercased()
        let vendor = (entry.vendorName ?? "").lowercased()
        
        return organicKeywords.contains { keyword in
            description.contains(keyword) || notes.contains(keyword) || vendor.contains(keyword)
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
    let isSheet: Bool
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var notes: String = ""
    @State private var isEditing = false
    @State private var reconciled: Bool = false
    
    init(entry: LedgerEntry, isSheet: Bool = true) {
        self.entry = entry
        self.isSheet = isSheet
    }
    
    var body: some View {
        Group {
            if isSheet {
                NavigationView {
                    detailContent
                        .navigationTitle("Entry Details")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(isEditing ? "Save" : "Edit") {
                                    if isEditing {
                                        saveChanges()
                                    }
                                    isEditing.toggle()
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                            }
                        }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("Entry Details")
                                .font(AppTheme.Typography.headlineLarge)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Button(isEditing ? "Save" : "Edit") {
                                if isEditing {
                                    saveChanges()
                                }
                                isEditing.toggle()
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        Divider()
                    }
                    .padding()
                    .background(AppTheme.Colors.backgroundPrimary)
                    
                    // Content
                    detailContent
                }
                .background(AppTheme.Colors.backgroundSecondary)
            }
        }
        .onAppear {
            notes = entry.notes ?? ""
            reconciled = entry.reconciled
        }
    }
    
    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Entry header with emoji/icon
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    HStack {
                        if let emoji = entry.emoji, !emoji.isEmpty {
                            Text(emoji)
                                .font(.system(size: 40))
                        } else if let symbol = entry.iosSymbol, !symbol.isEmpty {
                            Image(systemName: symbol)
                                .font(.system(size: 32))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Ledger Entry")
                                .font(AppTheme.Typography.displaySmall)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            if let date = entry.date {
                                Text(date, style: .date)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }
                        
                        Spacer()
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
                    LedgerDetailRow(label: "Balance", value: formatCurrency(entry.balance?.decimalValue ?? 0))
                }
                
                // Reference information
                LedgerDetailSection(title: "Reference Information") {
                    LedgerDetailRow(label: "Description", value: entry.ledgerDescription ?? "N/A")
                    LedgerDetailRow(label: "Reference Number", value: entry.referenceNumber ?? "N/A")
                    LedgerDetailRow(label: "Check Number", value: entry.checkNumber ?? "N/A")
                    LedgerDetailRow(label: "Vendor", value: entry.vendorName ?? "N/A")
                    LedgerDetailRow(label: "Tax Category", value: entry.taxCategory ?? "N/A")
                }
                
                // Reconciliation section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HStack {
                        Text("Reconciliation")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        if isEditing {
                            Toggle("Reconciled", isOn: $reconciled)
                        } else {
                            Text("Status:")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: reconciled ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(reconciled ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                                
                                Text(reconciled ? "Reconciled" : "Unreconciled")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                // Notes section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Notes")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
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
    }
    
    private func saveChanges() {
        entry.notes = notes
        entry.reconciled = reconciled
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to save changes: \(error)")
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
