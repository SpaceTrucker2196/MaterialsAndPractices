import Foundation
import CoreData
//
//extension WorkOrder {
//
//    /// Total debit across all ledger entries
//    var totalDebits: Double {
//        guard let entries = LedgerEntry as? Set<LedgerEntry> else { return 0.0 }
//        return entries.reduce(0.0) { $0 + ($1.debitAmount?.doubleValue ?? 0.0) }
//    }
//
//    /// Total credit across all ledger entries
//    var totalCredits: Double {
//        guard let entries = ledgerEntries as? Set<WorkOrderLedgerEntry> else { return 0.0 }
//        return entries.reduce(0.0) { $0 + ($1.creditAmount?.doubleValue ?? 0.0) }
//    }
//
//    /// Computed balance
//    var ledgerBalance: Double {
//        return totalDebits - totalCredits
//    }
//
//    /// Creates a ledger entry and links it to this work order
//    func createLedgerEntry(
//        vendorName: String,
//        amount: Double,
//        entryType: String,
//        debitAmount: Double,
//        creditAmount: Double,
//        taxCategory: String,
//        accountName: String,
//        accountCode: Int16,
//        description: String,
//        date: Date = Date(),
//        in context: NSManagedObjectContext
//    ) {
//        let entry = WorkOrderLedgerEntry(context: context)
//        entry.id = UUID()
//        entry.date = date
//        entry.vendorName = vendorName
//        entry.amount = amount as NSNumber
//        entry.entryType = entryType
//        entry.debitAmount = debitAmount as NSNumber
//        entry.creditAmount = creditAmount as NSNumber
//        entry.taxCategory = taxCategory
//        entry.accountName = accountName
//        entry.accountCode = accountCode
//        entry.ledgerDescription = description
//        entry.reconciled = false
//        entry.workOrder = self
//    }
//}
