//
//  LeaseDetailView.swift
//  MaterialsAndPractices
//
//  Comprehensive lease detail view displaying full lease content with payment management.
//  Shows markdown lease content, payment actions, and lease management options.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Comprehensive lease detail view with full content display and management
struct LeaseDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let lease: Lease
    
    @State private var leaseContent: String = ""
    @State private var showingPaymentSheet = false
    @State private var showingVoidConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = true
    
    // Fetch payments for this lease
    @FetchRequest private var payments: FetchedResults<Payment>
    
    init(lease: Lease) {
        self.lease = lease
        
        // Set up fetch request for payments
        let predicate = NSPredicate(format: "lease == %@", lease)
        self._payments = FetchRequest(
            entity: Payment.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Payment.dueDate, ascending: true)
            ],
            predicate: predicate
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.large) {
                            leaseHeaderSection
                            
                            paymentStatusSection
                            
                            leaseContentSection
                            
                            paymentHistorySection
                            
                            leaseActionsSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Lease Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Make Payment") {
                            showingPaymentSheet = true
                        }
                        
                        Button("Export Lease") {
                            exportLease()
                        }
                        
                        Divider()
                        
                        Button("Void Lease", role: .destructive) {
                            showingVoidConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadLeaseContent()
            }
            .sheet(isPresented: $showingPaymentSheet) {
                PaymentEntryView(lease: lease)
            }
            .alert("Void Lease", isPresented: $showingVoidConfirmation, actions: {
                Button("Cancel", role: .cancel) { }
                Button("Void", role: .destructive) {
                    voidLease()
                }
            }, message: {
                Text("Are you sure you want to void this lease? This action cannot be undone.")
            })
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK") { }
            }, message: {
                Text(errorMessage)
            })
        }
    }
    
    // MARK: - UI Sections
    
    /// Header section with basic lease information
    private var leaseHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(lease.leaseType?.capitalized ?? "Lease Agreement")
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let property = lease.property {
                        Text(property.displayName ?? "Unknown Property")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    if let farmer = lease.farmer {
                        Text("Farmer: \(farmer.name ?? "Unknown")")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                LeaseStatusBadge(status: lease.status ?? "active")
            }
            
            if let startDate = lease.startDate, let endDate = lease.endDate {
                HStack {
                    Label("\(startDate, style: .date)", systemImage: "calendar")
                    Text("to")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Label("\(endDate, style: .date)", systemImage: "calendar")
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    /// Payment status overview section
    private var paymentStatusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Payment Status")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.medium) {
                
                PaymentStatusCard(
                    title: "Total Due",
                    value: formatCurrency(totalDueAmount),
                    status: .due,
                    icon: "dollarsign.circle"
                )
                
                PaymentStatusCard(
                    title: "Overdue",
                    value: formatCurrency(overdueAmount),
                    status: .overdue,
                    icon: "exclamationmark.triangle"
                )
                
                PaymentStatusCard(
                    title: "Paid YTD",
                    value: formatCurrency(paidYTDAmount),
                    status: .paid,
                    icon: "checkmark.circle"
                )
            }
        }
    }
    
    /// Lease content section showing the full markdown content
    private var leaseContentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Lease Agreement")
            
            ScrollView {
                Text(leaseContent)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 400)
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
    }
    
    /// Payment history section
    private var paymentHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                SectionHeader(title: "Payment Schedule")
                Spacer()
                Button("Make Payment") {
                    showingPaymentSheet = true
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.primary)
            }
            
            if payments.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: "No Payments Scheduled",
                    description: "Payment schedule will appear here once created"
                )
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(payments), id: \.objectID) { payment in
                        PaymentRowView(payment: payment) {
                            markPaymentPaid(payment)
                        }
                    }
                }
            }
        }
    }
    
    /// Lease management actions section
    private var leaseActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Lease Actions")
            
            VStack(spacing: AppTheme.Spacing.small) {
                LeaseActionButton(
                    title: "Make Payment",
                    description: "Record a new lease payment",
                    icon: "creditcard.fill",
                    color: AppTheme.Colors.success
                ) {
                    showingPaymentSheet = true
                }
                
                LeaseActionButton(
                    title: "Export Lease",
                    description: "Download lease document",
                    icon: "square.and.arrow.up",
                    color: AppTheme.Colors.primary
                ) {
                    exportLease()
                }
                
                LeaseActionButton(
                    title: "Void Lease",
                    description: "Cancel this lease agreement",
                    icon: "xmark.circle.fill",
                    color: AppTheme.Colors.error
                ) {
                    showingVoidConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalDueAmount: Decimal {
        payments.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    private var overdueAmount: Decimal {
        payments.filter { 
            !$0.isPaid && ($0.dueDate ?? Date()) < Date() 
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var paidYTDAmount: Decimal {
        let currentYear = Calendar.current.component(.year, from: Date())
        return payments.filter { 
            $0.isPaid && 
            Calendar.current.component(.year, from: $0.paidDate ?? Date()) == currentYear 
        }.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Actions
    
    /// Loads the lease content from the markdown file
    private func loadLeaseContent() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var content = "Lease content not available"
                
                // Try to load from lease document path if available
                if let documentPath = lease.leaseDocumentPath,
                   FileManager.default.fileExists(atPath: documentPath) {
                    content = try String(contentsOfFile: documentPath)
                } else {
                    // Generate basic lease content from lease data
                    content = generateBasicLeaseContent()
                }
                
                DispatchQueue.main.async {
                    self.leaseContent = content
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load lease content: \(error.localizedDescription)"
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Generates basic lease content from lease data
    private func generateBasicLeaseContent() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        return """
        # \(lease.leaseType?.capitalized ?? "Lease") Agreement
        
        ## Property Information
        - **Property:** \(lease.property?.displayName ?? "Unknown")
        - **Farmer:** \(lease.farmer?.name ?? "Unknown")
        - **Lease Type:** \(lease.leaseType?.capitalized ?? "Unknown")
        
        ## Term
        - **Start Date:** \(lease.startDate.map(formatter.string) ?? "Not specified")
        - **End Date:** \(lease.endDate.map(formatter.string) ?? "Not specified")
        
        ## Financial Terms
        - **Rent Amount:** \(formatCurrency(lease.rentAmount ?? 0))
        - **Payment Frequency:** \(lease.rentFrequency?.capitalized ?? "Not specified")
        
        ## Status
        - **Current Status:** \(lease.status?.capitalized ?? "Unknown")
        
        ## Notes
        \(lease.notes ?? "No additional notes")
        """
    }
    
    /// Marks a payment as paid
    private func markPaymentPaid(_ payment: Payment) {
        payment.isPaid = true
        payment.paidDate = Date()
        payment.paymentStatus = "paid"
        
        // Create ledger entry
        createLedgerEntry(for: payment)
        
        do {
            try viewContext.save()
        } catch {
            errorMessage = "Failed to update payment: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    /// Creates a ledger entry for a payment
    private func createLedgerEntry(for payment: Payment) {
        let ledgerEntry = LedgerEntry(context: viewContext)
        ledgerEntry.id = UUID()
        ledgerEntry.date = payment.paidDate
        ledgerEntry.amount = payment.amount
        ledgerEntry.debitAmount = payment.amount
        ledgerEntry.creditAmount = 0
        ledgerEntry.accountCode = "4000" // Revenue account
        ledgerEntry.accountName = "Lease Revenue"
        ledgerEntry.description = "Lease payment for \(lease.property?.displayName ?? "property")"
        ledgerEntry.entryType = "revenue"
        ledgerEntry.referenceNumber = payment.referenceNumber
        ledgerEntry.lease = lease
        ledgerEntry.payment = payment
        
        payment.ledgerEntry = ledgerEntry
    }
    
    /// Exports the lease document
    private func exportLease() {
        // Implementation for lease export
        // This would typically use the LeaseDocumentExporter
        print("Exporting lease document...")
    }
    
    /// Voids the lease
    private func voidLease() {
        lease.status = "void"
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = "Failed to void lease: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    /// Formats a decimal as currency
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Supporting Views

/// Status badge for lease status
struct LeaseStatusBadge: View {
    let status: String
    
    var color: Color {
        switch status.lowercased() {
        case "active": return AppTheme.Colors.success
        case "expired": return AppTheme.Colors.warning
        case "void": return AppTheme.Colors.error
        default: return AppTheme.Colors.textSecondary
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(AppTheme.Typography.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(color)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

/// Payment status card
struct PaymentStatusCard: View {
    let title: String
    let value: String
    let status: PaymentStatus
    let icon: String
    
    enum PaymentStatus {
        case due, overdue, paid
        
        var color: Color {
            switch self {
            case .due: return AppTheme.Colors.warning
            case .overdue: return AppTheme.Colors.error
            case .paid: return AppTheme.Colors.success
            }
        }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status.color)
            
            Text(value)
                .font(AppTheme.Typography.headlineSmall)
                .fontWeight(.bold)
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
}

/// Payment row view
struct PaymentRowView: View {
    let payment: Payment
    let onMarkPaid: () -> Void
    
    var statusColor: Color {
        if payment.isPaid {
            return AppTheme.Colors.success
        } else if let dueDate = payment.dueDate, dueDate < Date() {
            return AppTheme.Colors.error
        } else {
            return AppTheme.Colors.warning
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text("Payment #\(payment.sequence)")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let dueDate = payment.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.tiny) {
                Text(formatCurrency(payment.amount))
                    .font(AppTheme.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if payment.isPaid {
                    Text("Paid")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.success)
                } else {
                    Button("Mark Paid") {
                        onMarkPaid()
                    }
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Colors.primary)
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
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// Lease action button
struct LeaseActionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                    Text(title)
                        .font(AppTheme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(description)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding()
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Loading view
struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading lease details...")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text(title)
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(description)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

/// Payment entry view (placeholder)
struct PaymentEntryView: View {
    let lease: Lease
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Payment Entry")
                    .font(AppTheme.Typography.displayMedium)
                
                Text("Payment entry form for lease")
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
                        // Implementation for saving payment
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}