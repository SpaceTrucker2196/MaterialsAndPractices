//
//  PaymentManagementView.swift
//  MaterialsAndPractices
//
//  Comprehensive payment management system for lease payments.
//  Handles payment tracking, status visualization, and payment entry.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Main payment management view for lease payments
struct PaymentManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedFilter: PaymentFilter = .needingAttention
    @State private var showingPaymentEntry = false
    
    // Fetch all payments with proper sorting
    @FetchRequest(
        entity: Payment.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Payment.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Payment.sequence, ascending: true)
        ]
    ) private var allPayments: FetchedResults<Payment>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                paymentSummarySection
                
                filterSection
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(filteredPayments, id: \.objectID) { payment in
                            PaymentCardView(payment: payment) {
                                // Handle payment action
                                handlePaymentAction(payment)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Payment Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Payment") {
                        showingPaymentEntry = true
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingPaymentEntry) {
                NewPaymentEntryView()
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Summary section showing payment statistics
    private var paymentSummarySection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                PaymentSummaryCard(
                    title: "Overdue",
                    count: overduePayments.count,
                    amount: totalAmount(for: overduePayments),
                    color: AppTheme.Colors.error,
                    icon: "exclamationmark.triangle.fill"
                )
                
                PaymentSummaryCard(
                    title: "Due Soon",
                    count: dueSoonPayments.count,
                    amount: totalAmount(for: dueSoonPayments),
                    color: AppTheme.Colors.warning,
                    icon: "clock.fill"
                )
                
                PaymentSummaryCard(
                    title: "Paid YTD",
                    count: paidYTDPayments.count,
                    amount: totalAmount(for: paidYTDPayments),
                    color: AppTheme.Colors.success,
                    icon: "checkmark.circle.fill"
                )
            }
            
            Divider()
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    /// Filter section for payment categories
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.medium) {
                ForEach(PaymentFilter.allCases, id: \.self) { filter in
                    PaymentFilterChip(
                        filter: filter,
                        count: paymentCount(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
    
    // MARK: - Computed Properties
    
    private var filteredPayments: [Payment] {
        switch selectedFilter {
        case .all:
            return Array(allPayments)
        case .needingAttention:
            return overduePayments + dueSoonPayments
        case .overdue:
            return overduePayments
        case .dueSoon:
            return dueSoonPayments
        case .paid:
            return Array(allPayments.filter { $0.isPaid })
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            return Array(allPayments.filter { payment in
                guard let dueDate = payment.dueDate else { return false }
                return calendar.isDate(dueDate, equalTo: now, toGranularity: .month)
            })
        }
    }
    
    private var overduePayments: [Payment] {
        Array(allPayments.filter { payment in
            !payment.isPaid && (payment.dueDate ?? Date()) < Date()
        })
    }
    
    private var dueSoonPayments: [Payment] {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return Array(allPayments.filter { payment in
            !payment.isPaid &&
            (payment.dueDate ?? Date()) >= Date() &&
            (payment.dueDate ?? Date()) <= thirtyDaysFromNow
        })
    }
    
    private var paidYTDPayments: [Payment] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(allPayments.filter { payment in
            payment.isPaid &&
            Calendar.current.component(.year, from: payment.paidDate ?? Date()) == currentYear
        })
    }
    
    // MARK: - Helper Methods
    
    private func paymentCount(for filter: PaymentFilter) -> Int {
        switch filter {
        case .all: return allPayments.count
        case .needingAttention: return overduePayments.count + dueSoonPayments.count
        case .overdue: return overduePayments.count
        case .dueSoon: return dueSoonPayments.count
        case .paid: return allPayments.filter { $0.isPaid }.count
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            return allPayments.filter { payment in
                guard let dueDate = payment.dueDate else { return false }
                return calendar.isDate(dueDate, equalTo: now, toGranularity: .month)
            }.count
        }
    }
    
    private func totalAmount(for payments: [Payment]) -> Decimal {
        payments.reduce(0) { $0 + $1.amount }
    }
    
    private func handlePaymentAction(_ payment: Payment) {
        if !payment.isPaid {
            markPaymentPaid(payment)
        }
    }
    
    private func markPaymentPaid(_ payment: Payment) {
        payment.isPaid = true
        payment.paidDate = Date()
        payment.paymentStatus = "paid"
        
        // Create ledger entry
        createLedgerEntry(for: payment)
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to mark payment as paid: \(error)")
        }
    }
    
    private func createLedgerEntry(for payment: Payment) {
        let ledgerEntry = LedgerEntry(context: viewContext)
        ledgerEntry.id = UUID()
        ledgerEntry.date = payment.paidDate
        ledgerEntry.amount = payment.amount
        ledgerEntry.debitAmount = payment.amount
        ledgerEntry.creditAmount = 0
        ledgerEntry.accountCode = "4000" // Revenue account
        ledgerEntry.accountName = "Lease Revenue"
        ledgerEntry.description = "Lease payment for \(payment.lease?.property?.displayName ?? "property")"
        ledgerEntry.entryType = "revenue"
        ledgerEntry.referenceNumber = payment.referenceNumber
        ledgerEntry.lease = payment.lease
        ledgerEntry.payment = payment
        
        payment.ledgerEntry = ledgerEntry
    }
}

// MARK: - Supporting Types

enum PaymentFilter: String, CaseIterable {
    case all = "All"
    case needingAttention = "Needs Attention"
    case overdue = "Overdue"
    case dueSoon = "Due Soon"
    case paid = "Paid"
    case thisMonth = "This Month"
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .needingAttention: return "exclamationmark.circle"
        case .overdue: return "exclamationmark.triangle.fill"
        case .dueSoon: return "clock.fill"
        case .paid: return "checkmark.circle.fill"
        case .thisMonth: return "calendar"
        }
    }
}

// MARK: - Supporting Views

/// Payment summary card showing key metrics
struct PaymentSummaryCard: View {
    let title: String
    let count: Int
    let amount: Decimal
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(AppTheme.Typography.headlineSmall)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(formatCurrency(amount))
                .font(AppTheme.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(title)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
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

/// Filter chip for payment categories
struct PaymentFilterChip: View {
    let filter: PaymentFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(AppTheme.Typography.bodySmall)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(isSelected ? .white : AppTheme.Colors.textSecondary)
                }
            }
            .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Individual payment card view
struct PaymentCardView: View {
    let payment: Payment
    let onAction: () -> Void
    
    var statusColor: Color {
        if payment.isPaid {
            return AppTheme.Colors.success
        } else if let dueDate = payment.dueDate, dueDate < Date() {
            return AppTheme.Colors.error
        } else if let dueDate = payment.dueDate, dueDate <= Date().addingTimeInterval(30 * 24 * 60 * 60) {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.textSecondary
        }
    }
    
    var statusText: String {
        if payment.isPaid {
            return "Paid"
        } else if let dueDate = payment.dueDate, dueDate < Date() {
            return "Overdue"
        } else if let dueDate = payment.dueDate, dueDate <= Date().addingTimeInterval(7 * 24 * 60 * 60) {
            return "Due Soon"
        } else {
            return "Pending"
        }
    }
    
    var body: some View {
        NavigationLink(destination: LeaseDetailView(lease: payment.lease!)) {
            VStack(spacing: AppTheme.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Payment #\(payment.sequence)")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if let lease = payment.lease {
                            Text(lease.property?.displayName ?? "Unknown Property")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Text("Farmer: \(lease.farmer?.name ?? "Unknown")")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.small) {
                        Text(formatCurrency(payment.amount))
                            .font(AppTheme.Typography.headlineSmall)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        StatusBadge(text: statusText, color: statusColor)
                    }
                }
                
                HStack {
                    if let dueDate = payment.dueDate {
                        Label("\(dueDate, style: .date)", systemImage: "calendar")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if !payment.isPaid {
                        Button("Mark Paid") {
                            onAction()
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    } else if let paidDate = payment.paidDate {
                        Text("Paid \(paidDate, style: .date)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                }
            }
            .padding()
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(statusColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// Status badge component
struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(AppTheme.Typography.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(color)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

/// New payment entry view (placeholder)
struct NewPaymentEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("New Payment Entry")
                    .font(AppTheme.Typography.displayMedium)
                
                Text("Create a new payment entry")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Payment")
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