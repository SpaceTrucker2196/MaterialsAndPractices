//
//  WorkOrderExpenseView.swift
//  MaterialsAndPractices
//
//  View for creating ledger entries related to work orders.
//  Provides prefilled expense creation with work order context.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// View for creating expenses related to work orders
struct WorkOrderExpenseView: View {
    let workOrder: WorkOrder
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // Form state
    @State private var vendorName = ""
    @State private var amount: String = ""
    @State private var description = ""
    @State private var accountName = "Work Order Expenses"
    @State private var accountCode = "5100"
    @State private var taxCategory = "No Tax"
    @State private var notes = ""
    @State private var entryType = "Expense"
    @State private var referenceNumber = ""
    @State private var checkNumber = ""
    @State private var selectedEmoji = "💰"
    @State private var selectedSymbol = "dollarsign.circle"
    
    // Account options
    private let accountOptions = [
        ("Work Order Expenses", "5100"),
        ("Equipment Rental", "5200"),
        ("Material Costs", "5300"),
        ("Fuel", "5300"),
        ("Labor Costs", "5400"),
        ("Supplies", "5500"),
        ("Utilities", "5600")
    ]
    
    private let taxCategories = ["No Tax", "Sales Tax", "Use Tax"]
    
    // Emoji and symbol options
    private let expenseEmojis = ["💰", "🧾", "🚜", "⛽", "🔧", "🌱", "📦", "💳"]
    private let expenseSymbols = ["dollarsign.circle", "receipt", "car", "fuelpump", "wrench.and.screwdriver", "leaf", "shippingbox", "creditcard"]
    
    var body: some View {
        NavigationView {
            Form {
                // Work Order Context Section
                Section("Work Order Context") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            Text("Work Order:")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text(workOrder.title ?? "Untitled Work Order")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        
                        if let dueDate = workOrder.dueDate {
                            HStack {
                                Text("Due Date:")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Spacer()
                                
                                Text(dueDate, style: .date)
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                        }
                    }
                }
                
                // Expense Details Section
                Section("Expense Details") {
                    TextField("Vendor Name", text: $vendorName)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    Picker("Account", selection: $accountName) {
                        ForEach(accountOptions, id: \.0) { account in
                            Text(account.0).tag(account.0)
                        }
                    }
                    .onChange(of: accountName) { newAccount in
                        if let selectedAccount = accountOptions.first(where: { $0.0 == newAccount }) {
                            accountCode = selectedAccount.1
                        }
                    }
                    
                    HStack {
                        Text("Account Code:")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text(accountCode)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    
                    Picker("Tax Category", selection: $taxCategory) {
                        ForEach(taxCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                // Reference Information Section
                Section("Reference Information") {
                    TextField("Reference Number", text: $referenceNumber)
                    
                    TextField("Check Number (Optional)", text: $checkNumber)
                }
                
                // Visual Indicators Section
                Section("Visual Indicators") {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        Text("Emoji")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: AppTheme.Spacing.small) {
                            ForEach(expenseEmojis, id: \.self) { emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                }) {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(selectedEmoji == emoji ? AppTheme.Colors.primary.opacity(0.2) : Color.clear)
                                        .cornerRadius(AppTheme.CornerRadius.small)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        Text("System Symbol")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: AppTheme.Spacing.small) {
                            ForEach(expenseSymbols, id: \.self) { symbol in
                                Button(action: {
                                    selectedSymbol = symbol
                                }) {
                                    Image(systemName: symbol)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .foregroundColor(AppTheme.Colors.primary)
                                        .background(selectedSymbol == symbol ? AppTheme.Colors.primary.opacity(0.2) : Color.clear)
                                        .cornerRadius(AppTheme.CornerRadius.small)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Notes Section
                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            populateDefaultValues()
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !vendorName.isEmpty && !amount.isEmpty && !description.isEmpty && Decimal(string: amount) != nil
    }
    
    private func populateDefaultValues() {
        // Prefill description with work order context
        description = "Expense for: \(workOrder.title ?? "Work Order")"
        
        // Generate reference number based on work order
        if let workOrderId = workOrder.id {
            referenceNumber = "WO-\(workOrderId.uuidString.prefix(8).uppercased())"
        }
        
        // Add work order context to notes
        notes = "Related to work order: \(workOrder.title ?? "Untitled")"
        if let dueDate = workOrder.dueDate {
            notes += "\nDue: \(DateFormatter.localizedString(from: dueDate, dateStyle: .medium, timeStyle: .none))"
        }
    }
    
    private func saveExpense() {
        guard let amountDecimal = Decimal(string: amount) else {
            print("❌ Invalid amount format")
            return
        }
        
        let ledgerEntry = LedgerEntry(context: viewContext)
        ledgerEntry.id = UUID()
        ledgerEntry.vendorName = vendorName
        ledgerEntry.amount = NSDecimalNumber(decimal: amountDecimal)
        ledgerEntry.debitAmount = NSDecimalNumber(decimal: amountDecimal) // Expenses are debits
        ledgerEntry.creditAmount = NSDecimalNumber(decimal: 0)
        ledgerEntry.ledgerDescription = description
        ledgerEntry.accountName = accountName
        ledgerEntry.accountCode = accountCode
        ledgerEntry.taxCategory = taxCategory
        ledgerEntry.entryType = entryType
        ledgerEntry.referenceNumber = referenceNumber
        ledgerEntry.checkNumber = checkNumber.isEmpty ? nil : checkNumber
        ledgerEntry.notes = notes
        ledgerEntry.emoji = selectedEmoji
        ledgerEntry.iosSymbol = selectedSymbol
        ledgerEntry.date = Date()
        ledgerEntry.reconciled = false
        
        do {
            try viewContext.save()
            print("✅ Expense saved successfully")
            isPresented = false
        } catch {
            print("❌ Failed to save expense: \(error)")
        }
    }
}