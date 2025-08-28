//
//  LedgerView.swift
//  MaterialsAndPractices
//
//  GAAP-compliant ledger view for agricultural business accounting.
//  Provides comprehensive ledger management with detailed entry views.
//  Optimized for efficient data display with tight layout and date-based organization.
//  Internationalized date handling for UI, exports, and filenames.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData
import UIKit

// MARK: - Shared Currency Formatter

private enum CurrencyFormatter {
    static let shared: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()
}

@inline(__always)
private func formatCurrency(_ amount: Decimal) -> String {
    CurrencyFormatter.shared.string(from: amount as NSDecimalNumber) ?? "$0.00"
}

// MARK: - Date / Time Formatters (International-Friendly)

fileprivate let dayTitleFormatter: DateFormatter = {
    // Localized long-ish day label for section headers and Markdown (reader-friendly)
    let f = DateFormatter()
    f.locale = .current
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

fileprivate let longDayHeaderFormatter: DateFormatter = {
    // Used in Markdown section headers
    let f = DateFormatter()
    f.locale = .current
    f.dateStyle = .full
    f.timeStyle = .none
    return f
}()

fileprivate let uiTimeFormatter: DateFormatter = {
    // Localized short time for UI rows
    let f = DateFormatter()
    f.locale = .current
    f.dateStyle = .none
    f.timeStyle = .short
    return f
}()

fileprivate let csvISODateFormatter: DateFormatter = {
    // ISO 8601 date for CSV (unambiguous, machine-friendly)
    // Use en_US_POSIX to ensure stable formatting regardless of user locale.
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = Calendar(identifier: .iso8601)
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

fileprivate let csvISOTimeFormatter: DateFormatter = {
    // 24-hour time for CSV, UTC; adjust to local if preferred
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = Calendar(identifier: .iso8601)
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "HH:mm"
    return f
}()

fileprivate let isoFilenameDateFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withFullDate]
    f.timeZone = TimeZone(secondsFromGMT: 0)
    return f
}()

// MARK: - CSV Helpers

fileprivate func csvEscape(_ s: String) -> String {
    "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
}

fileprivate func csvNumber(_ d: NSDecimalNumber?) -> String {
    guard let d = d else { return "" }
    let nf = NumberFormatter()
    nf.locale = Locale(identifier: "en_US_POSIX")
    nf.numberStyle = .decimal
    nf.minimumFractionDigits = 2
    nf.maximumFractionDigits = 2
    return csvEscape(nf.string(from: d) ?? "")
}

// MARK: - Date Grouping Helper

struct DateSection: Identifiable {
    // Use a stable Date (start of day) for identity and sorting across locales
    let id: Date
    let title: String
    let entries: [LedgerEntry]
    let totalDebits: Decimal
    let totalCredits: Decimal
    let netAmount: Decimal
}

/// GAAP-compliant ledger view for agricultural business accounting
struct LedgerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedAccount: String = "All"
    @State private var selectedDateRange: DateRange = .thisMonth
    @State private var showingNewEntry = false
    @State private var searchText = ""
    @State private var selectedEntryID: NSManagedObjectID? = nil
    @State private var showingExportSheet = false
    
    // Fetch ledger entries - sorted by date descending (newest first)
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
                // iPad / wide layout with split view
                NavigationSplitView {
                    // Master list view
                    VStack(spacing: 0) {
                        ledgerSummaryHeader
                        filterSection
                        
                        List(selection: $selectedEntryID) {
                            ForEach(groupedEntries) { section in
                                Section {
                                    ForEach(section.entries, id: \.objectID) { entry in
                                        CompactLedgerEntryRowView(entry: entry, showDetailSheet: false) {
                                            selectedEntryID = entry.objectID
                                        }
                                        .tag(entry.objectID as NSManagedObjectID?)
                                    }
                                } header: {
                                    DateSectionHeaderView(section: section)
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search entries...")
                    }
                    .navigationTitle("General Ledger")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Export") {
                                showingExportSheet = true
                            }
                            .foregroundColor(AppTheme.Colors.secondary)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("New Entry") {
                                showingNewEntry = true
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                } detail: {
                    if let id = selectedEntryID,
                       let selected = allLedgerEntries.first(where: { $0.objectID == id }) {
                        ReceiptStyleLedgerDetailView(entry: selected, isSheet: false)
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
                .sheet(isPresented: $showingNewEntry) {
                    NewLedgerEntryView()
                }
                .sheet(isPresented: $showingExportSheet) {
                    LedgerExportView(entries: filteredEntries)
                }
            } else {
                // iPhone layout with navigation
                NavigationView {
                    VStack(spacing: 0) {
                        ledgerSummaryHeader
                        filterSection
                        
                        List {
                            ForEach(groupedEntries) { section in
                                Section {
                                    ForEach(section.entries, id: \.objectID) { entry in
                                        CompactLedgerEntryRowView(entry: entry, showDetailSheet: true) { }
                                    }
                                } header: {
                                    DateSectionHeaderView(section: section)
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search entries...")
                    }
                    .navigationTitle("General Ledger")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Export") {
                                showingExportSheet = true
                            }
                            .foregroundColor(AppTheme.Colors.secondary)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("New Entry") {
                                showingNewEntry = true
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                .sheet(isPresented: $showingNewEntry) {
                    NewLedgerEntryView()
                }
                .sheet(isPresented: $showingExportSheet) {
                    LedgerExportView(entries: filteredEntries)
                }
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Compact header showing account balances in rows for efficient space usage
    private var ledgerSummaryHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Assets")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text(formatCurrency(calculateBalance(for: .asset)))
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.success)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("Revenue")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text(formatCurrency(calculateBalance(for: .revenue)))
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expenses")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Text(formatCurrency(calculateBalance(for: .expense)))
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.warning)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, AppTheme.Spacing.small)
            
            Divider()
        }
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
    
    private var groupedEntries: [DateSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry -> Date in
            guard let date = entry.date,
                  let dayStart = calendar.dateInterval(of: .day, for: date)?.start else {
                return Date.distantPast
            }
            return dayStart
        }
        
        return grouped.map { (dayStart, entries) in
            let totalDebits = entries.reduce(Decimal.zero) { $0 + ($1.debitAmount?.decimalValue ?? 0) }
            let totalCredits = entries.reduce(Decimal.zero) { $0 + ($1.creditAmount?.decimalValue ?? 0) }
            let netAmount = totalCredits - totalDebits
            
            return DateSection(
                id: dayStart,
                title: (dayStart == .distantPast) ? NSLocalizedString("No Date", comment: "No date section title") : dayTitleFormatter.string(from: dayStart),
                entries: entries.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) },
                totalDebits: totalDebits,
                totalCredits: totalCredits,
                netAmount: netAmount
            )
        }
        .sorted { $0.id > $1.id } // newest day first
    }
    
    private var availableAccounts: [String] {
        let accounts = Set(allLedgerEntries.compactMap { $0.accountName })
        return ["All"] + Array(accounts).sorted()
    }
    
    // MARK: - Helper Methods
    
    private func calculateBalance(for type: AccountType) -> Decimal {
        let entries = allLedgerEntries.filter { entry in
            guard let entryType = entry.entryType?.lowercased() else { return false }
            switch type {
            case .asset:
                return entryType == "asset"
            case .revenue:
                return entryType == "revenue"
            case .expense:
                return entryType == "expense"
            case .liability:
                return entryType == "liability"
            case .equity:
                return entryType == "equity"
            }
        }
        
        return entries.reduce(Decimal.zero) { result, entry in
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
            // Safer quarter calculation by month
            let nowComponents = calendar.dateComponents([.year, .month], from: now)
            let dateComponents = calendar.dateComponents([.year, .month], from: date)
            guard let nowYear = nowComponents.year,
                  let nowMonth = nowComponents.month,
                  let dateYear = dateComponents.year,
                  let dateMonth = dateComponents.month else { return false }
            
            func quarter(for month: Int) -> Int { (month - 1) / 3 + 1 }
            return nowYear == dateYear && quarter(for: nowMonth) == quarter(for: dateMonth)
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .all:
            return true
        }
    }
}

// MARK: - Supporting Views

/// Date section header showing totals
struct DateSectionHeaderView: View {
    let section: DateSection
    
    var body: some View {
        HStack {
            Text(section.title)
                .font(AppTheme.Typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                if section.totalDebits > 0 {
                    Text("Dr: \(formatCurrency(section.totalDebits))")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.error)
                }
                if section.totalCredits > 0 {
                    Text("Cr: \(formatCurrency(section.totalCredits))")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                }
                Text("Net: \(formatCurrency(section.netAmount))")
                    .font(AppTheme.Typography.labelSmall)
                    .fontWeight(.medium)
                    .foregroundColor(section.netAmount >= 0 ? AppTheme.Colors.success : AppTheme.Colors.error)
            }
        }
        .padding(.vertical, 4)
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

/// Compact ledger entry row optimized for efficient data display
struct CompactLedgerEntryRowView: View {
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
            HStack(spacing: AppTheme.Spacing.small) {
                // Transaction type indicator (no emoji/images as requested)
                transactionTypeIndicator
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.accountCode ?? "")
                            .font(AppTheme.Typography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        // Organic certification indicator
                        if isOrganicRelated {
                            Rectangle()
                                .fill(AppTheme.Colors.compliance)
                                .frame(width: 6, height: 6)
                                .cornerRadius(1)
                        }
                        
                        Spacer()
                        
                        if let date = entry.date {
                            Text(uiTimeFormatter.string(from: date))
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    Text(entry.accountName ?? "Unknown Account")
                        .font(AppTheme.Typography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(entry.ledgerDescription ?? "No description")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let debit = entry.debitAmount, debit.decimalValue > 0 {
                        Text(formatCurrency(debit.decimalValue))
                            .font(AppTheme.Typography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.error)
                    }
                    
                    if let credit = entry.creditAmount?.decimalValue, credit > 0 {
                        Text(formatCurrency(credit))
                            .font(AppTheme.Typography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                    
                    if entry.reconciled {
                        Text("✓")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.small)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ReceiptStyleLedgerDetailView(entry: entry, isSheet: true)
        }
    }
    
    private var transactionTypeIndicator: some View {
        VStack(spacing: 2) {
            if let debit = entry.debitAmount, debit.decimalValue > 0 {
                Rectangle()
                    .fill(AppTheme.Colors.error)
                    .frame(width: 3, height: 12)
                    .cornerRadius(1.5)
            }
            
            if let credit = entry.creditAmount?.decimalValue, credit > 0 {
                Rectangle()
                    .fill(AppTheme.Colors.success)
                    .frame(width: 3, height: 12)
                    .cornerRadius(1.5)
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
}

/// Receipt/Invoice style detailed view for a single ledger entry
struct ReceiptStyleLedgerDetailView: View {
    let entry: LedgerEntry
    let isSheet: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var notes: String = ""
    @State private var isEditing = false
    @State private var reconciled: Bool = false
    @State private var expenseApproval: Bool = false
    
    init(entry: LedgerEntry, isSheet: Bool = true) {
        self.entry = entry
               self.isSheet = isSheet
    }
    
    var body: some View {
        Group {
            if isSheet {
                NavigationView {
                    receiptContent
                        .navigationTitle("Ledger Entry")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") { dismiss() }
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
                            Text("Ledger Entry")
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
                    
                    receiptContent
                }
                .background(AppTheme.Colors.backgroundSecondary)
            }
        }
        .onAppear {
            notes = entry.notes ?? ""
            reconciled = entry.reconciled
            expenseApproval = entry.expenseApproval
        }
    }
    
    private var receiptContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Receipt Header - Vendor Information
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HStack {
                        Text("RECEIPT")
                            .font(AppTheme.Typography.displaySmall)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        if let date = entry.date {
                            Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    // Vendor Information
                    if let vendor = entry.vendorName, !vendor.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("VENDOR:")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(vendor)
                                .font(AppTheme.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                    }
                    
                    // Description
                    if let description = entry.ledgerDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DESCRIPTION:")
                                .font(AppTheme.Typography.labelSmall)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(description)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                    }
                    
                    Divider()
                }
                
                // Transaction Details
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    HStack {
                        Text("TRANSACTION DETAILS")
                            .font(AppTheme.Typography.headlineSmall)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Spacer()
                    }
                    
                    receiptDetailRow(label: "Account Code", value: entry.accountCode ?? "N/A")
                    receiptDetailRow(label: "Account Name", value: entry.accountName ?? "N/A")
                    receiptDetailRow(label: "Entry Type", value: entry.entryType?.capitalized ?? "N/A")
                    receiptDetailRow(label: "Reference #", value: entry.referenceNumber ?? "N/A")
                    
                    if let checkNumber = entry.checkNumber, !checkNumber.isEmpty {
                        receiptDetailRow(label: "Check #", value: checkNumber)
                    }
                    
                    if let taxCategory = entry.taxCategory, !taxCategory.isEmpty {
                        receiptDetailRow(label: "Tax Category", value: taxCategory)
                    }
                    
                    Divider()
                }
                
                // Financial Summary
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("FINANCIAL SUMMARY")
                        .font(AppTheme.Typography.headlineSmall)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let debit = entry.debitAmount, debit.decimalValue > 0 {
                        receiptDetailRow(
                            label: "Debit Amount",
                            value: formatCurrency(debit.decimalValue),
                            valueColor: AppTheme.Colors.error
                        )
                    }
                    
                    if let credit = entry.creditAmount?.decimalValue, credit > 0 {
                        receiptDetailRow(
                            label: "Credit Amount",
                            value: formatCurrency(credit),
                            valueColor: AppTheme.Colors.success
                        )
                    }
                    
                    receiptDetailRow(
                        label: "Net Amount",
                        value: formatCurrency(entry.amount?.decimalValue ?? 0),
                        isBold: true
                    )
                    
                    if let balance = entry.balance?.decimalValue {
                        receiptDetailRow(
                            label: "Running Balance",
                            value: formatCurrency(balance)
                        )
                    }
                    
                    Divider()
                }
                
                // Status Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("STATUS")
                        .font(AppTheme.Typography.headlineSmall)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack {
                        if isEditing {
                            Toggle("Reconciled", isOn: $reconciled)
                        } else {
                            Text("Reconciled:")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(reconciled ? "Yes" : "No")
                                .font(AppTheme.Typography.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(reconciled ? AppTheme.Colors.success : AppTheme.Colors.textPrimary)
                        }
                    }
                    
                    HStack {
                        if isEditing {
                            Toggle("Expense Approved", isOn: $expenseApproval)
                        } else {
                            Text("Expense Approved:")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(expenseApproval ? "Yes" : "No")
                                .font(AppTheme.Typography.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(expenseApproval ? AppTheme.Colors.success : AppTheme.Colors.warning)
                        }
                    }
                    
                    Divider()
                }
                
                // Notes Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("NOTES")
                        .font(AppTheme.Typography.headlineSmall)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if isEditing {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
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
    
    private func receiptDetailRow(label: String, value: String, valueColor: Color = AppTheme.Colors.textPrimary, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 2)
    }
    
    private func saveChanges() {
        entry.notes = notes
        entry.reconciled = reconciled
        entry.expenseApproval = expenseApproval
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to save changes: \(error)")
        }
    }
}

/// Ledger export view with markdown generation and iOS sharing
struct LedgerExportView: View {
    let entries: [LedgerEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .markdown
    @State private var showingShareSheet = false
    @State private var exportedContent = ""
    @State private var exportedURL: URL?
    
    enum ExportFormat: String, CaseIterable {
        case markdown = "Markdown"
        case csv = "CSV"
        
        var fileExtension: String {
            switch self {
            case .markdown: return "md"
            case .csv: return "csv"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Format Selection
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Export Format")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Export Summary
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Export Summary")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("\(entries.count) ledger entries")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if let dateRange = dateRange {
                        Text("Date range: \(dateRange)")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Export Button
                Button("Export Ledger") {
                    exportLedger()
                }
                .font(AppTheme.Typography.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .padding()
            .navigationTitle("Export Ledger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private var dateRange: String? {
        guard !entries.isEmpty else { return nil }
        let dates = entries.compactMap { $0.date }.sorted()
        guard let first = dates.first, let last = dates.last else { return nil }
        
        let f = DateFormatter()
        f.locale = .current
        f.dateStyle = .medium
        f.timeStyle = .none
        
        if Calendar.current.isDate(first, inSameDayAs: last) {
            return f.string(from: first)
        } else {
            return "\(f.string(from: first)) - \(f.string(from: last))"
        }
    }
    
    private func exportLedger() {
        switch selectedFormat {
        case .markdown:
            exportedContent = generateMarkdown()
        case .csv:
            exportedContent = generateCSV()
        }
        
        saveAndShare()
    }
    
    private func generateMarkdown() -> String {
        var markdown = """
        # General Ledger Export
        
        **Export Date:** \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))
        **Total Entries:** \(entries.count)
        
        """
        
        if let range = dateRange {
            markdown += "**Date Range:** \(range)\n\n"
        }
        
        // Group by date (start of day) for better organization
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }) { entry in
            guard let date = entry.date,
                  let dayStart = calendar.dateInterval(of: .day, for: date)?.start else {
                return Date.distantPast
            }
            return dayStart
        }
        
        for (date, dayEntries) in grouped.sorted(by: { $0.key > $1.key }) {
            markdown += "## \(date == .distantPast ? NSLocalizedString("No Date", comment: "No date section title") : longDayHeaderFormatter.string(from: date))\n\n"
            
            markdown += "| Time | Account | Description | Debit | Credit | Reference |\n"
            markdown += "|------|---------|-------------|-------|--------|-----------|\n"
            
            for entry in dayEntries.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }) {
                let time = entry.date.map { uiTimeFormatter.string(from: $0) } ?? ""
                let account = "\(entry.accountCode ?? "") - \(entry.accountName ?? "")"
                let description = entry.ledgerDescription ?? ""
                let debit = entry.debitAmount?.decimalValue ?? 0 > 0 ? formatCurrency(entry.debitAmount!.decimalValue) : ""
                let credit = entry.creditAmount?.decimalValue ?? 0 > 0 ? formatCurrency(entry.creditAmount!.decimalValue) : ""
                let reference = entry.referenceNumber ?? ""
                
                markdown += "| \(time) | \(account) | \(description) | \(debit) | \(credit) | \(reference) |\n"
            }
            
            markdown += "\n"
        }
        
        return markdown
    }
    
    private func generateCSV() -> String {
        var csv = "Date,Time,Account Code,Account Name,Description,Debit Amount,Credit Amount,Reference Number,Vendor,Reconciled,Approved\n"
        
        for entry in entries.sorted(by: { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }) {
            let date = entry.date.map { csvISODateFormatter.string(from: $0) } ?? ""
            let time = entry.date.map { csvISOTimeFormatter.string(from: $0) } ?? ""
            let accountCode = entry.accountCode ?? ""
            let accountName = entry.accountName ?? ""
            let description = entry.ledgerDescription ?? ""
            let reference = entry.referenceNumber ?? ""
            let vendor = entry.vendorName ?? ""
            let reconciled = entry.reconciled ? "Yes" : "No"
            let approved = entry.expenseApproval ? "Yes" : "No"
            
            csv += [
                csvEscape(date),
                csvEscape(time),
                csvEscape(accountCode),
                csvEscape(accountName),
                csvEscape(description),
                csvNumber(entry.debitAmount),
                csvNumber(entry.creditAmount),
                csvEscape(reference),
                csvEscape(vendor),
                csvEscape(reconciled),
                csvEscape(approved)
            ].joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    private func saveAndShare() {
        let fileName = "GeneralLedger_\(isoFilenameDateFormatter.string(from: Date())).\(selectedFormat.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try exportedContent.write(to: tempURL, atomically: true, encoding: .utf8)
            exportedURL = tempURL
            showingShareSheet = true
        } catch {
            print("❌ Failed to save export file: \(error)")
        }
    }
}

/// iOS Share Sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// New ledger entry view (placeholder)
struct NewLedgerEntryView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}
