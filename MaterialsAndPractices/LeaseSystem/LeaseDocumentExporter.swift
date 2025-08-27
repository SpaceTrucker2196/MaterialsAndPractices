//
//  LeaseDocumentExporter.swift
//  MaterialsAndPractices
//
//  Exports lease agreements as markdown files for property owners and
//  accounting purposes. Provides standardized documentation for tax
//  records and generally accepted accounting practices.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CoreData

/// Service for exporting lease agreements as markdown documents
class LeaseDocumentExporter {
    
    // MARK: - Properties
    
    private let leaseDirectoryManager = LeaseDirectoryManager.shared
    
    // MARK: - Export Methods
    
    /// Exports a lease agreement as a formatted markdown document for property owners
    /// - Parameters:
    ///   - lease: The lease to export
    ///   - context: Core Data context for fetching related data
    /// - Returns: URL of the exported document
    /// - Throws: Export errors
    func exportLeaseForPropertyOwner(_ lease: Lease, context: NSManagedObjectContext) throws -> URL {
        let documentContent = generatePropertyOwnerDocument(for: lease)
        
        // Create filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let propertyName = lease.property?.displayName?.replacingOccurrences(of: " ", with: "_") ?? "Unknown_Property"
        let fileName = "\(dateString)_Lease_Agreement_\(propertyName).md"
        
        // Save to Documents directory for easy access
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportURL = documentsURL.appendingPathComponent("LeaseExports").appendingPathComponent(fileName)
        
        // Ensure export directory exists
        try FileManager.default.createDirectory(at: exportURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        // Write document
        try documentContent.write(to: exportURL, atomically: true, encoding: .utf8)
        
        print("✅ Exported lease agreement for property owner: \(fileName)")
        return exportURL
    }
    
    /// Exports all active leases for a specific growing year
    /// - Parameters:
    ///   - growingYear: The year to export leases for
    ///   - context: Core Data context
    /// - Returns: Array of exported document URLs
    /// - Throws: Export errors
    func exportAllActiveLeasesForYear(_ growingYear: Int, context: NSManagedObjectContext) throws -> [URL] {
        let request: NSFetchRequest<Lease> = Lease.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "active")
        
        let leases = try context.fetch(request)
        let yearLeases = leases.filter { lease in
            guard let startDate = lease.startDate else { return false }
            let calendar = Calendar.current
            return calendar.component(.year, from: startDate) == growingYear
        }
        
        var exportedURLs: [URL] = []
        
        for lease in yearLeases {
            let exportURL = try exportLeaseForPropertyOwner(lease, context: context)
            exportedURLs.append(exportURL)
        }
        
        return exportedURLs
    }
    
    // MARK: - Document Generation
    
    /// Generates a comprehensive markdown document for property owners
    private func generatePropertyOwnerDocument(for lease: Lease) -> String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        return """
# Lease Agreement Summary for Property Owner

**Generated:** \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))
**Property:** \(lease.property?.displayName ?? "Unknown Property")
**Tenant:** \(lease.farmer?.name ?? "Unknown Farmer")

---

## Lease Details

### Property Information
- **Property Name:** \(lease.property?.displayName ?? "N/A")
- **County:** \(lease.property?.county ?? "N/A")
- **State:** \(lease.property?.state ?? "N/A")
- **Total Acres:** \(String(format: "%.1f", lease.property?.totalAcres ?? 0)) acres
- **Tillable Acres:** \(String(format: "%.1f", lease.property?.tillableAcres ?? 0)) acres

### Tenant Information
- **Farmer/Tenant:** \(lease.farmer?.name ?? "N/A")
- **Organization:** \(lease.farmer?.orgName ?? "N/A")
- **Phone:** \(lease.farmer?.phone ?? "N/A")
- **Email:** \(lease.farmer?.email ?? "N/A")

### Lease Terms
- **Lease Type:** \(lease.leaseType?.capitalized ?? "N/A")
- **Start Date:** \(lease.startDate.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "N/A")
- **End Date:** \(lease.endDate.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? "N/A")
- **Status:** \(lease.status?.capitalized ?? "N/A")

### Financial Terms
- **Rent Amount:** $\(String(format: "%.2f", lease.rentAmount?.doubleValue ?? 0))
- **Payment Frequency:** \(lease.rentFrequency?.replacingOccurrences(of: "_", with: " ").capitalized ?? "N/A")
- **Crop Share Percentage:** \(String(format: "%.1f", lease.cropSharePct))%

### Responsibilities
- **Property Tax:** \(lease.propertyTaxResponsibility ?? "Not specified")
- **Insurance:** \(lease.insuranceResponsibility ?? "Not specified")

## Payment Record for \(currentYear)

\(generatePaymentRecord(for: lease))

## Notes and Restrictions

\(lease.notes ?? "No additional notes")

\(lease.restrictions.map { _ in "**Restrictions:** \\($0)" } ?? "")

---

## For Tax and Accounting Purposes

This document serves as a summary of the lease agreement for the above-mentioned property. It should be retained for tax reporting and accounting purposes in accordance with generally accepted accounting practices.

### Recommended Record Keeping
- [ ] Maintain copy of signed lease agreement
- [ ] Keep records of all payments received
- [ ] Document any property improvements or maintenance
- [ ] Track expenses related to property management
- [ ] Consult with tax professional for proper reporting

### Important Notes
- This is a computer-generated summary for reference purposes
- Refer to the original signed lease agreement for complete terms
- Consult with legal and tax professionals as needed
- Retain all documentation for the required statutory period

---

**Document ID:** \(UUID().uuidString.prefix(8))
**Generated by:** MaterialsAndPractices Farm Management System
"""
    }
    
    /// Generates payment record section for the lease
    private func generatePaymentRecord(for lease: Lease) -> String {
        guard let startDate = lease.startDate,
              let endDate = lease.endDate,
              let frequency = lease.rentFrequency else {
            return "Payment schedule not available"
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // Generate payment schedule for current year
        let yearStart = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        let yearEnd = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31))!
        
        let actualStart = max(yearStart, startDate)
        let actualEnd = min(yearEnd, endDate)
        
        let payments = LeasePaymentTracker.upcomingPayments(
            for: [lease],
            within: Int(actualEnd.timeIntervalSince(actualStart) / 86400) // Days
        )
        
        if payments.isEmpty {
            return """
| Payment Date | Amount Due | Amount Paid | Status | Notes |
|--------------|------------|-------------|--------|-------|
| No payments scheduled for this period | | | | |

**Total Annual Rent:** $\(String(format: "%.2f", lease.rentAmount?.doubleValue ?? 0))
"""
        }
        
        var paymentTable = """
| Payment Date | Amount Due | Amount Paid | Status | Notes |
|--------------|------------|-------------|--------|-------|
"""
        
        for payment in payments {
            let dateString = DateFormatter.localizedString(from: payment.dueDate, dateStyle: .short, timeStyle: .none)
            let amountString = String(format: "%.2f", payment.amount.doubleValue)
            paymentTable += "\n| \(dateString) | $\(amountString) | $______ | ⬜ | _____________ |"
        }
        
        paymentTable += """

**Payment Frequency:** \(frequency.replacingOccurrences(of: "_", with: " ").capitalized)
**Total Annual Rent:** $\(String(format: "%.2f", lease.rentAmount?.doubleValue ?? 0))
**Payments Received to Date:** $______
**Balance Due:** $______
"""
        
        return paymentTable
    }
    
    /// Creates a lease summary report for multiple properties
    func createLeaseSummaryReport(for properties: [Property], context: NSManagedObjectContext) throws -> URL {
        let reportContent = generateLeaseSummaryReport(for: properties, context: context)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "\(dateString)_Lease_Summary_Report.md"
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportURL = documentsURL.appendingPathComponent("LeaseExports").appendingPathComponent(fileName)
        
        // Ensure export directory exists
        try FileManager.default.createDirectory(at: exportURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        
        try reportContent.write(to: exportURL, atomically: true, encoding: .utf8)
        
        print("✅ Generated lease summary report: \(fileName)")
        return exportURL
    }
    
    /// Generates comprehensive lease summary report
    private func generateLeaseSummaryReport(for properties: [Property], context: NSManagedObjectContext) -> String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        var reportContent = """
# Lease Summary Report - \(currentYear)

**Generated:** \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))
**Properties Included:** \(properties.count)

---

## Executive Summary

"""
        
        // Calculate totals
        var totalRentAmount: Double = 0
        var totalAcres: Double = 0
        var activeLeaseCount = 0
        
        for property in properties {
            let leases = property.leases?.allObjects as? [Lease] ?? []
            let activeLeases = leases.filter { $0.status == "active" }
            
            if !activeLeases.isEmpty {
                activeLeaseCount += activeLeases.count
                totalAcres += property.totalAcres
                
                for lease in activeLeases {
                    totalRentAmount += lease.rentAmount?.doubleValue ?? 0
                }
            }
        }
        
        reportContent += """
- **Active Leases:** \(activeLeaseCount)
- **Total Leased Acres:** \(String(format: "%.1f", totalAcres)) acres
- **Total Annual Rent:** $\(String(format: "%.2f", totalRentAmount))
- **Average Rent per Acre:** $\(String(format: "%.2f", totalAcres > 0 ? totalRentAmount / totalAcres : 0))

## Property Details

"""
        
        for property in properties {
            let leases = property.leases?.allObjects as? [Lease] ?? []
            let activeLeases = leases.filter { $0.status == "active" }
            
            reportContent += """
### \(property.displayName ?? "Unknown Property")

- **Location:** \(property.county ?? "N/A"), \(property.state ?? "N/A")
- **Total Acres:** \(String(format: "%.1f", property.totalAcres)) acres
- **Active Leases:** \(activeLeases.count)

"""
            
            for lease in activeLeases {
                reportContent += """
#### Lease with \(lease.farmer?.name ?? "Unknown Farmer")
- **Type:** \(lease.leaseType?.capitalized ?? "N/A")
- **Rent:** $\(String(format: "%.2f", lease.rentAmount?.doubleValue ?? 0)) (\(lease.rentFrequency ?? "N/A"))
- **Period:** \(lease.startDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "N/A") - \(lease.endDate.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "N/A")

"""
            }
        }
        
        reportContent += """
---

**Report ID:** \(UUID().uuidString.prefix(8))
**Generated by:** MaterialsAndPractices Farm Management System
"""
        
        return reportContent
    }
}
