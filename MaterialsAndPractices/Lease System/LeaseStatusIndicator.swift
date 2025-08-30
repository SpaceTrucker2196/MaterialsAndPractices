//
//  LeaseStatusIndicator.swift
//  MaterialsAndPractices
//
//  Visual indicators for lease status and payment issues on farm and field tiles.
//  Provides clear financial oversight for agricultural lease management.
//
//  Created by GitHub Copilot on current date.
//

import SwiftUI
import CoreData

/// Visual indicator for lease status and payment issues
struct LeaseStatusIndicator: View {
    let hasActiveLeases: Bool
    let hasOverduePayments: Bool
    let hasUpcomingPayments: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if hasOverduePayments {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            } else if hasUpcomingPayments {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else if !hasActiveLeases {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
}

/// Payment tracking utility for lease management
struct LeasePaymentTracker {
    
    /// Calculates upcoming payments for active leases
    static func upcomingPayments(for leases: [Lease], within days: Int = 30) -> [LeasePayment] {
        let calendar = Calendar.current
        let currentDate = Date()
        let futureDate = calendar.date(byAdding: .day, value: days, to: currentDate) ?? currentDate
        
        var upcomingPayments: [LeasePayment] = []
        
        for lease in leases where lease.status == "active" {
            let payments = calculatePaymentsForLease(lease, from: currentDate, to: futureDate)
            upcomingPayments.append(contentsOf: payments)
        }
        
        return upcomingPayments.sorted { $0.dueDate < $1.dueDate }
    }
    
    /// Checks if a property has active lease coverage for current growing season
    static func hasActiveLeaseCoverage(property: Property, context: NSManagedObjectContext) -> Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentDate = Date()
        
        let leaseRequest: NSFetchRequest<Lease> = Lease.fetchRequest()
        leaseRequest.predicate = NSPredicate(format: "property == %@ AND status == %@", property, "active")
        
        do {
            let leases = try context.fetch(leaseRequest)
            return leases.contains { lease in
                guard let startDate = lease.startDate,
                      let endDate = lease.endDate else { return false }
                
                return currentDate >= startDate && currentDate <= endDate
            }
        } catch {
            print("Error checking lease coverage: \(error)")
            return false
        }
    }
    
    /// Checks if a field has active lease coverage
    static func hasActiveLeaseCoverage(field: Field, context: NSManagedObjectContext) -> Bool {
        guard let property = field.property else { return false }
        return hasActiveLeaseCoverage(property: property, context: context)
    }
    
    /// Calculates payment schedule for a lease
    private static func calculatePaymentsForLease(_ lease: Lease, from startDate: Date, to endDate: Date) -> [LeasePayment] {
        guard let leaseStartDate = lease.startDate,
              let leaseEndDate = lease.endDate,
              let rentAmount = lease.rentAmount,
              let frequency = lease.rentFrequency else {
            return []
        }
        
        let calendar = Calendar.current
        var payments: [LeasePayment] = []
        
        switch frequency.lowercased() {
        case "monthly":
            let monthlyAmount = rentAmount.doubleValue / 12.0
            var currentDate = max(startDate, leaseStartDate)
            
            while currentDate <= min(endDate, leaseEndDate) {
                if calendar.compare(currentDate, to: startDate, toGranularity: .month) != .orderedAscending {
                    let dueDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
                    payments.append(LeasePayment(
                        lease: lease,
                        amount: NSDecimalNumber(value: monthlyAmount),
                        dueDate: dueDate,
                        frequency: .monthly
                    ))
                }
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
            
        case "quarterly":
            let quarterlyAmount = rentAmount.doubleValue / 4.0
            let quarters = [1, 4, 7, 10] // March, June, September, December
            
            for month in quarters {
                if let dueDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: startDate), month: month, day: 1)),
                   dueDate >= startDate && dueDate <= endDate {
                    payments.append(LeasePayment(
                        lease: lease,
                        amount: NSDecimalNumber(value: quarterlyAmount),
                        dueDate: dueDate,
                        frequency: .quarterly
                    ))
                }
            }
            
        case "semi_annual", "semi-annual":
            let semiAnnualAmount = rentAmount.doubleValue / 2.0
            let semiAnnualMonths = [3, 9] // March, September
            
            for month in semiAnnualMonths {
                if let dueDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: startDate), month: month, day: 1)),
                   dueDate >= startDate && dueDate <= endDate {
                    payments.append(LeasePayment(
                        lease: lease,
                        amount: NSDecimalNumber(value: semiAnnualAmount),
                        dueDate: dueDate,
                        frequency: .semiAnnual
                    ))
                }
            }
            
        case "annual":
            if let dueDate = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: leaseStartDate)),
               dueDate >= startDate && dueDate <= endDate {
                payments.append(LeasePayment(
                    lease: lease,
                    amount: rentAmount,
                    dueDate: dueDate,
                    frequency: .annual
                ))
            }
            
        default:
            break
        }
        
        return payments
    }
}

/// Represents a lease payment
struct LeasePayment {
    let lease: Lease
    let amount: NSDecimalNumber
    let dueDate: Date
    let frequency: PaymentFrequency
    
    var isOverdue: Bool {
        dueDate < Date()
    }
    
    var isUpcoming: Bool {
        let calendar = Calendar.current
        let daysUntilDue = calendar.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return daysUntilDue >= 0 && daysUntilDue <= 30
    }
}

enum PaymentFrequency {
    case monthly
    case quarterly
    case semiAnnual
    case annual
    
    var displayName: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        case .semiAnnual:
            return "Semi-Annual"
        case .annual:
            return "Annual"
        }
    }
}

/// Enhanced lease payment row for dashboard display
struct LeasePaymentRow: View {
    let payment: LeasePayment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payment.lease.property?.displayName ?? "Unknown Property")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    statusIndicator
                }
                
                Text(payment.lease.farmer?.name ?? "Unknown Farmer")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                HStack {
                    Text("Due: \(payment.dueDate, style: .date)")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Spacer()
                    
                    Text("$\(payment.amount.doubleValue, specifier: "%.2f")")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(backgroundcolor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var statusIndicator: some View {
        Group {
            if payment.isOverdue {
                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(.red)
            } else if payment.isUpcoming {
                Label("Due Soon", systemImage: "clock.fill")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var backgroundcolor: Color {
        if payment.isOverdue {
            return AppTheme.Colors.error.opacity(0.1)
        } else if payment.isUpcoming {
            return AppTheme.Colors.warning.opacity(0.1)
        } else {
            return AppTheme.Colors.backgroundSecondary
        }
    }
}