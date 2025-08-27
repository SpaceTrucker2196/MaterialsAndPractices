//
//  LeaseRenewalsView.swift
//  MaterialsAndPractices
//
//  Lease renewals management allowing copying leases from previous years
//  and updating them for the current year.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Lease renewals view for managing lease renewals and copying from previous years
struct LeaseRenewalsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date()) - 1
    @State private var targetYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showingRenewalForm = false
    @State private var selectedLease: Lease?
    
    // Fetch leases for the selected year
    @FetchRequest private var leasesForYear: FetchedResults<Lease>
    
    init() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let previousYear = currentYear - 1
        
        _selectedYear = State(initialValue: previousYear)
        _targetYear = State(initialValue: currentYear)
        
        // Set up fetch request for leases from previous year
        let startOfYear = Calendar.current.date(from: DateComponents(year: previousYear, month: 1, day: 1)) ?? Date()
        let endOfYear = Calendar.current.date(from: DateComponents(year: previousYear, month: 12, day: 31)) ?? Date()
        
        let predicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@", startOfYear as NSDate, endOfYear as NSDate)
        
        _leasesForYear = FetchRequest(
            entity: Lease.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Lease.startDate, ascending: true),
                NSSortDescriptor(keyPath: \Lease.property?.displayName, ascending: true)
            ],
            predicate: predicate
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                renewalHeaderSection
                
                yearSelectionSection
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.medium) {
                        if leasesForYear.isEmpty {
                            emptyStateSection
                        } else {
                            ForEach(Array(leasesForYear), id: \.objectID) { lease in
                                RenewalLeaseCardView(
                                    lease: lease,
                                    targetYear: targetYear
                                ) {
                                    selectedLease = lease
                                    showingRenewalForm = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Lease Renewals")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingRenewalForm) {
                if let lease = selectedLease {
                    LeaseRenewalFormView(
                        originalLease: lease,
                        targetYear: targetYear,
                        isPresented: $showingRenewalForm
                    )
                }
            }
        }
        .onChange(of: selectedYear) { _ in
            updateFetchRequest()
        }
    }
    
    // MARK: - UI Sections
    
    /// Header section with renewal summary
    private var renewalHeaderSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                RenewalSummaryCard(
                    title: "Available",
                    count: leasesForYear.count,
                    subtitle: "From \(selectedYear)",
                    color: AppTheme.Colors.primary,
                    icon: "doc.text"
                )
                
                RenewalSummaryCard(
                    title: "Renewed",
                    count: renewedLeasesCount,
                    subtitle: "For \(targetYear)",
                    color: AppTheme.Colors.success,
                    icon: "checkmark.circle"
                )
                
                RenewalSummaryCard(
                    title: "Pending",
                    count: pendingRenewalsCount,
                    subtitle: "To Renew",
                    color: AppTheme.Colors.warning,
                    icon: "clock"
                )
            }
            
            Divider()
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    /// Year selection section
    private var yearSelectionSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Copy From")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Menu {
                        ForEach(availableYears, id: \.self) { year in
                            Button("\(year)") {
                                selectedYear = year
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(selectedYear)")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding()
                        .background(AppTheme.Colors.backgroundPrimary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Renew To")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Menu {
                        ForEach(futureYears, id: \.self) { year in
                            Button("\(year)") {
                                targetYear = year
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(targetYear)")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding()
                        .background(AppTheme.Colors.backgroundPrimary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    /// Empty state when no leases available
    private var emptyStateSection: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No Leases Found")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("No lease agreements found for \(selectedYear). Try selecting a different year.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Select Different Year") {
                // Year selection is handled by the menu above
            }
            .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Computed Properties
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear - 1))
    }
    
    private var futureYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 2))
    }
    
    private var renewedLeasesCount: Int {
        // Count leases already created for target year
        let startOfTargetYear = Calendar.current.date(from: DateComponents(year: targetYear, month: 1, day: 1)) ?? Date()
        let endOfTargetYear = Calendar.current.date(from: DateComponents(year: targetYear, month: 12, day: 31)) ?? Date()
        
        let targetYearPredicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@", startOfTargetYear as NSDate, endOfTargetYear as NSDate)
        
        let fetchRequest: NSFetchRequest<Lease> = Lease.fetchRequest()
        fetchRequest.predicate = targetYearPredicate
        
        do {
            let targetYearLeases = try viewContext.fetch(fetchRequest)
            return targetYearLeases.count
        } catch {
            return 0
        }
    }
    
    private var pendingRenewalsCount: Int {
        max(0, leasesForYear.count - renewedLeasesCount)
    }
    
    // MARK: - Helper Methods
    
    private func updateFetchRequest() {
        // Update the fetch request when year changes
        let startOfYear = Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? Date()
        let endOfYear = Calendar.current.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) ?? Date()
        
        let predicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@", startOfYear as NSDate, endOfYear as NSDate)
        leasesForYear.nsPredicate = predicate
    }
}

// MARK: - Supporting Views

/// Summary card for renewal statistics
struct RenewalSummaryCard: View {
    let title: String
    let count: Int
    let subtitle: String
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
            
            Text(title)
                .font(AppTheme.Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(subtitle)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

/// Card view for individual lease renewal
struct RenewalLeaseCardView: View {
    let lease: Lease
    let targetYear: Int
    let onRenew: () -> Void
    
    var isAlreadyRenewed: Bool {
        // Check if this lease has already been renewed for target year
        // This would need to be implemented based on your business logic
        false
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(lease.property?.displayName ?? "Unknown Property")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Farmer: \(lease.farmer?.name ?? "Unknown")")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("Type: \(lease.leaseType?.capitalized ?? "Unknown")")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.small) {
                    Text(formatCurrency(lease.rentAmount ?? 0))
                        .font(AppTheme.Typography.headlineSmall)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(lease.rentFrequency?.capitalized ?? "Annual")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if isAlreadyRenewed {
                        Text("Renewed")
                            .font(AppTheme.Typography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, AppTheme.Spacing.tiny)
                            .background(AppTheme.Colors.success)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
            }
            
            HStack {
                if let startDate = lease.startDate, let endDate = lease.endDate {
                    Label("\(startDate, style: .date) - \(endDate, style: .date)", systemImage: "calendar")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                if !isAlreadyRenewed {
                    Button("Renew for \(targetYear)") {
                        onRenew()
                    }
                    .font(AppTheme.Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundPrimary)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(isAlreadyRenewed ? AppTheme.Colors.success : AppTheme.Colors.border, lineWidth: 1)
        )
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

/// Lease renewal form view
struct LeaseRenewalFormView: View {
    let originalLease: Lease
    let targetYear: Int
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var rentAmount: String = ""
    @State private var rentFrequency: String = ""
    @State private var notes: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(originalLease: Lease, targetYear: Int, isPresented: Binding<Bool>) {
        self.originalLease = originalLease
        self.targetYear = targetYear
        self._isPresented = isPresented
        
        // Initialize dates for the target year
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: targetYear, month: 1, day: 1)) ?? Date()
        let endOfYear = calendar.date(from: DateComponents(year: targetYear, month: 12, day: 31)) ?? Date()
        
        _startDate = State(initialValue: startOfYear)
        _endDate = State(initialValue: endOfYear)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Original lease information
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        Text("Original Lease (\(Calendar.current.component(.year, from: originalLease.startDate ?? Date())))")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        VStack(spacing: AppTheme.Spacing.small) {
                            RenewalFormRow(label: "Property", value: originalLease.property?.displayName ?? "Unknown")
                            RenewalFormRow(label: "Farmer", value: originalLease.farmer?.name ?? "Unknown")
                            RenewalFormRow(label: "Type", value: originalLease.leaseType?.capitalized ?? "Unknown")
                            RenewalFormRow(label: "Original Rent", value: formatCurrency(originalLease.rentAmount ?? 0))
                        }
                        .padding()
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    
                    // New lease details
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        Text("New Lease (\(targetYear))")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        VStack(spacing: AppTheme.Spacing.medium) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Start Date")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("End Date")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Rent Amount")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                TextField("Rent Amount", text: $rentAmount)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Payment Frequency")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Picker("Frequency", selection: $rentFrequency) {
                                    Text("Monthly").tag("monthly")
                                    Text("Quarterly").tag("quarterly")
                                    Text("Semi-Annual").tag("semi-annual")
                                    Text("Annual").tag("annual")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Notes")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                TextEditor(text: $notes)
                                    .frame(height: 80)
                                    .padding()
                                    .background(AppTheme.Colors.backgroundSecondary)
                                    .cornerRadius(AppTheme.CornerRadius.medium)
                            }
                        }
                        .padding()
                        .background(AppTheme.Colors.backgroundPrimary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                }
                .padding()
            }
            .navigationTitle("Renew Lease")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Renewal") {
                        createRenewalLease()
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                setupFormDefaults()
            }
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK") { }
            }, message: {
                Text(errorMessage)
            })
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupFormDefaults() {
        rentAmount = formatDecimalForInput(originalLease.rentAmount ?? 0)
        rentFrequency = originalLease.rentFrequency ?? "annual"
        notes = "Renewed from \(Calendar.current.component(.year, from: originalLease.startDate ?? Date())) lease"
    }
    
    private func createRenewalLease() {
        do {
            // Create new lease entity
            let newLease = Lease(context: viewContext)
            newLease.id = UUID()
            newLease.leaseType = originalLease.leaseType
            newLease.startDate = startDate
            newLease.endDate = endDate
            newLease.rentAmount = NSDecimalNumber(string: rentAmount)
            newLease.rentFrequency = rentFrequency
            newLease.status = "active"
            newLease.property = originalLease.property
            newLease.farmer = originalLease.farmer
            newLease.owner = originalLease.owner
            newLease.notes = notes
            
            // Copy other relevant fields
            newLease.cropSharePct = originalLease.cropSharePct
            newLease.insuranceResponsibility = originalLease.insuranceResponsibility
            newLease.propertyTaxResponsibility = originalLease.propertyTaxResponsibility
            newLease.renewalTerms = originalLease.renewalTerms
            newLease.restrictions = originalLease.restrictions
            newLease.terminationTerms = originalLease.terminationTerms
            
            // Create payment schedule
            createPaymentSchedule(for: newLease)
            
            // Save context
            try viewContext.save()
            
            print("✅ Successfully created renewed lease for \(targetYear)")
            isPresented = false
            
        } catch {
            errorMessage = "Failed to create renewed lease: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func createPaymentSchedule(for lease: Lease) {
        guard let rentAmount = lease.rentAmount,
              let startDate = lease.startDate,
              let endDate = lease.endDate,
              let frequency = lease.rentFrequency else { return }
        
        let calendar = Calendar.current
        var paymentDates: [Date] = []
        
        // Calculate payment dates based on frequency
        switch frequency.lowercased() {
        case "monthly":
            var currentDate = startDate
            while currentDate <= endDate {
                paymentDates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
            }
        case "quarterly":
            var currentDate = startDate
            while currentDate <= endDate {
                paymentDates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 3, to: currentDate) ?? endDate
            }
        case "semi-annual":
            var currentDate = startDate
            while currentDate <= endDate {
                paymentDates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 6, to: currentDate) ?? endDate
            }
        case "annual":
            paymentDates.append(startDate)
        default:
            paymentDates.append(startDate)
        }
        
        // Create payment entities
        let paymentAmount = rentAmount.dividing(by: NSDecimalNumber(value: paymentDates.count))
        
        for (index, dueDate) in paymentDates.enumerated() {
            let payment = Payment(context: viewContext)
            payment.id = UUID()
            payment.amount = paymentAmount.decimalValue
            payment.dueDate = dueDate
            payment.isPaid = false
            payment.paymentStatus = "pending"
            payment.sequence = Int16(index + 1)
            payment.memo = "Lease payment \(index + 1) of \(paymentDates.count) (Renewed)"
            payment.lease = lease
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    private func formatDecimalForInput(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}

/// Form row for renewal details
struct RenewalFormRow: View {
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