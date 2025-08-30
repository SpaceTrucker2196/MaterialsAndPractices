//
//  PaymentDetailView.swift
//  MaterialsAndPractices
//
//  Detailed payment view showing comprehensive payment information,
//  farm details, fields in lease, and equipment on leased farm.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Comprehensive payment detail view with farm information
struct PaymentDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let payment: Payment
    
    @State private var showingMarkPaidAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Payment Information Section
                paymentInformationSection
                
                // Farm Details Section
                farmDetailsSection
                
                // Fields in Lease Section
                fieldsInLeaseSection
                
                // Equipment Section
                equipmentSection
                
                // Actions Section
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Payment Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .alert("Mark as Paid", isPresented: $showingMarkPaidAlert) {
            Button("Mark Paid", role: .destructive) {
                markPaymentAsPaid()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Mark this payment as paid? This will update the payment status and create a ledger entry.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - UI Sections
    
    /// Payment information section
    private var paymentInformationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Payment Information")
            
            VStack(spacing: AppTheme.Spacing.medium) {
                // Payment status card
                PaymentDetailStatusCard(payment: payment)
                
                // Payment details
                VStack(spacing: AppTheme.Spacing.small) {
                    InfoBlock(label: "Amount:") {
                        Text(formatCurrency(payment.amount! as Decimal))
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Colors.primary)
                            .fontWeight(.bold)
                    }
                    
                    if let dueDate = payment.dueDate {
                        InfoBlock(label: "Due Date:") {
                            Text(dueDate, style: .date)
                                .foregroundColor(dueDate < Date() ? AppTheme.Colors.error : AppTheme.Colors.textPrimary)
                        }
                    }
                    
                    if let paidDate = payment.paidDate {
                        InfoBlock(label: "Paid Date:") {
                            Text(paidDate, style: .date)
                        }
                    }
                    
                    if let method = payment.method {
                        InfoBlock(label: "Payment Method:") {
                            Text(method)
                        }
                    }
                    
                    if let referenceNumber = payment.referenceNumber {
                        InfoBlock(label: "Reference:") {
                            Text(referenceNumber)
                        }
                    }
                    
                    InfoBlock(label: "Sequence:") {
                        Text("#\(payment.sequence)")
                    }
                }
            }
        }
    }
    
    /// Farm details section
    private var farmDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Farm Details")
            
            if let lease = payment.lease, let property = lease.property {
                VStack(spacing: AppTheme.Spacing.small) {
                    InfoBlock(label: "Property:") {
                        Text(property.displayName ?? "Unknown Property")
                            .fontWeight(.medium)
                    }
                    
                    if let county = property.county {
                        InfoBlock(label: "County:") {
                            Text(county)
                        }
                    }
                    
                    if let state = property.state {
                        InfoBlock(label: "State:") {
                            Text(state)
                        }
                    }
                    
                    InfoBlock(label: "Total Acres:") {
                        Text("\(property.totalAcres, specifier: "%.1f") acres")
                    }
                    
                    InfoBlock(label: "Tillable Acres:") {
                        Text("\(property.tillableAcres, specifier: "%.1f") acres")
                    }
                    
                    if property.pastureAcres > 0 {
                        InfoBlock(label: "Pasture Acres:") {
                            Text("\(property.pastureAcres, specifier: "%.1f") acres")
                        }
                    }
                    
                    if property.woodlandAcres > 0 {
                        InfoBlock(label: "Woodland Acres:") {
                            Text("\(property.woodlandAcres, specifier: "%.1f") acres")
                        }
                    }
                    
                    if property.wetlandAcres > 0 {
                        InfoBlock(label: "Wetland Acres:") {
                            Text("\(property.wetlandAcres, specifier: "%.1f") acres")
                        }
                    }
                    
                    if property.hasIrrigation {
                        InfoBlock(label: "Irrigation:") {
                            Text("Available")
                                .foregroundColor(AppTheme.Colors.success)
                        }
                    }
                    
                    if let certificationStatus = property.certificationStatus {
                        InfoBlock(label: "Certification:") {
                            Text(certificationStatus)
                        }
                    }
                }
            } else {
                Text("No farm details available")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Fields in lease section
    private var fieldsInLeaseSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Fields in Lease")
            
            if let lease = payment.lease, 
               let property = lease.property,
               let fields = property.fields?.allObjects as? [Field],
               !fields.isEmpty {
                
                VStack(spacing: AppTheme.Spacing.small) {
//                    ForEach(fields.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.objectID) { field in
//                        FieldRowView(field: field)
//                    }
                }
            } else {
                Text("No fields information available")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Equipment section
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(title: "Equipment on Leased Farm")
            
            if let lease = payment.lease,
               let property = lease.property,
               let infrastructure = property.infrastructure?.allObjects as? [Infrastructure],
               !infrastructure.isEmpty {
                
                let equipment = infrastructure.filter { $0.category?.lowercased().contains("equipment") == true || $0.type?.lowercased().contains("equipment") == true }
                
                if !equipment.isEmpty {
                    VStack(spacing: AppTheme.Spacing.small) {
                        ForEach(equipment.sorted(by: { ($0.name ?? "") < ($1.name ?? "") }), id: \.objectID) { item in
                            EquipmentRowView(equipment: item)
                        }
                    }
                } else {
                    Text("No equipment information available")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            } else {
                Text("No equipment information available")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    /// Actions section
    private var actionsSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if !payment.isPaid {
                CommonActionButton(title: "Mark as Paid", style: .primary) {
                    showingMarkPaidAlert = true
                }
            }
            
            if let lease = payment.lease {
                NavigationLink(destination: LeaseDetailView(lease: lease)) {
                    CommonActionButton(title: "View Lease Details", style: .secondary) {
                        // Navigation handled by NavigationLink
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    private func markPaymentAsPaid() {
        payment.isPaid = true
        payment.paidDate = Date()
        payment.paymentStatus = "paid"
        
        // Create ledger entry
        let ledgerEntry = LedgerEntry(context: viewContext)
        ledgerEntry.id = UUID()
        ledgerEntry.date = Date()
        ledgerEntry.amount = payment.amount!
        ledgerEntry.debitAmount = payment.amount!
        ledgerEntry.ledgerDescription = "Payment received for lease"
        ledgerEntry.entryType = "Payment"
        ledgerEntry.accountCode = "1000" // Accounts Receivable
        ledgerEntry.accountName = "Lease Payments"
        ledgerEntry.payment = payment
        ledgerEntry.lease = payment.lease
        
        do {
            try viewContext.save()
        } catch {
            errorMessage = "Failed to mark payment as paid: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - Supporting Views

/// Payment status card
struct PaymentDetailStatusCard: View {
    let payment: Payment
    
    private var statusColor: Color {
        if payment.isPaid {
            return AppTheme.Colors.success
        } else if let dueDate = payment.dueDate, dueDate < Date() {
            return AppTheme.Colors.error
        } else {
            return AppTheme.Colors.warning
        }
    }
    
    private var statusText: String {
        if payment.isPaid {
            return "Paid"
        } else if let dueDate = payment.dueDate, dueDate < Date() {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private var statusIcon: String {
        if payment.isPaid {
            return "checkmark.circle.fill"
        } else if let dueDate = payment.dueDate, dueDate < Date() {
            return "exclamationmark.triangle.fill"
        } else {
            return "clock.fill"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text("Payment Status")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(statusText)
                    .font(AppTheme.Typography.headlineSmall)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(statusColor, lineWidth: 1)
        )
    }
}

/// Field row view
struct PaymentFieldRowView: View {
    let field: Field
    
    var body: some View {
        HStack {
            Image(systemName: "square.dashed")
                .foregroundColor(AppTheme.Colors.primary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(field.name ?? "Unnamed Field")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("\(field.acres, specifier: "%.1f") acres")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            if field.hasDrainTile {
                Image(systemName: "drop.fill")
                    .foregroundColor(AppTheme.Colors.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}

/// Equipment row view
struct EquipmentRowView: View {
    let equipment: Infrastructure
    
    var body: some View {
        HStack {
            Image(systemName: "wrench.and.screwdriver.fill")
                .foregroundColor(AppTheme.Colors.compliance)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(equipment.name ?? "Unnamed Equipment")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let type = equipment.type {
                    Text(type)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let status = equipment.status {
                MetadataTag(
                    text: status,
                    backgroundColor: status.lowercased() == "active" ? AppTheme.Colors.success.opacity(0.2) : AppTheme.Colors.warning.opacity(0.2),
                    textColor: status.lowercased() == "active" ? AppTheme.Colors.success : AppTheme.Colors.warning
                )
            }
        }
        .padding(.vertical, AppTheme.Spacing.tiny)
    }
}
