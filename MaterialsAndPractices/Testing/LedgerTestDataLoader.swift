//
//  LedgerTestDataLoader.swift
//  MaterialsAndPractices
//
//  Test data loader for ledger entries from CSV file.
//  Provides functionality to load ledger test data for development and testing.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CoreData

/// Test data loader for ledger entries
class LedgerTestDataLoader {
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    /// Load ledger test data from CSV file
    func loadLedgerTestData() throws {
        // Clear existing ledger entries first
        try clearExistingLedgerEntries()
        
        // Load CSV data
        guard let csvPath = Bundle.main.path(forResource: "ZappaFarm_Ledger_2Year_Full", ofType: "csv"),
              let csvContent = try? String(contentsOfFile: csvPath) else {
            throw LedgerTestDataError.csvFileNotFound
        }
        
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw LedgerTestDataError.invalidCSVFormat
        }
        
        // Parse header to get column indices
        let headers = parseCSVLine(lines[0])
        let columnMap = createColumnMap(headers: headers)
        
        // Process each ledger entry row
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty {
                try createLedgerEntryFromCSVLine(line, columnMap: columnMap)
            }
        }
        
        // Save the context
        try viewContext.save()
        
        print("✅ Successfully loaded \(lines.count - 1) test ledger entries")
    }
    
    /// Clear all existing ledger entries
    private func clearExistingLedgerEntries() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = LedgerEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        try viewContext.execute(deleteRequest)
        try viewContext.save()
        
        print("🗑️ Cleared existing ledger entries")
    }
    
    /// Parse CSV line handling quoted fields
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
    
    /// Create column mapping from headers
    private func createColumnMap(headers: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            map[header.lowercased()] = index
        }
        return map
    }
    
    /// Create ledger entry from CSV line
    private func createLedgerEntryFromCSVLine(_ line: String, columnMap: [String: Int]) throws {
        let fields = parseCSVLine(line)
        
        let ledgerEntry = LedgerEntry(context: viewContext)
        
        // Map ID field first
        if let idIndex = columnMap["id"], idIndex < fields.count {
            let idString = fields[idIndex]
            if let id = Int64(idString) {
                // Create a UUID from the numeric ID for consistency
                ledgerEntry.id = UUID(uuidString: String(format: "%08d-0000-0000-0000-000000000000", id)) ?? UUID()
            } else {
                ledgerEntry.id = UUID()
            }
        } else {
            ledgerEntry.id = UUID()
        }
        
        // Map basic fields
        if let vendorNameIndex = columnMap["vendorname"], vendorNameIndex < fields.count {
            ledgerEntry.vendorName = fields[vendorNameIndex]
        }
        
        if let taxCategoryIndex = columnMap["taxcategory"], taxCategoryIndex < fields.count {
            ledgerEntry.taxCategory = fields[taxCategoryIndex]
        }
        
        if let referenceNumberIndex = columnMap["referencenumber"], referenceNumberIndex < fields.count {
            ledgerEntry.referenceNumber = fields[referenceNumberIndex]
        }
        
        if let reconciledIndex = columnMap["reconciled"], reconciledIndex < fields.count {
            ledgerEntry.reconciled = fields[reconciledIndex].lowercased() == "true"
        }
        
        if let notesIndex = columnMap["notes"], notesIndex < fields.count {
            ledgerEntry.notes = fields[notesIndex]
        }
        
        if let descriptionIndex = columnMap["ledgerdescription"], descriptionIndex < fields.count {
            ledgerEntry.ledgerDescription = fields[descriptionIndex]
        }
        
        if let entryTypeIndex = columnMap["entrytype"], entryTypeIndex < fields.count {
            ledgerEntry.entryType = fields[entryTypeIndex]
        }
        
        if let accountNameIndex = columnMap["accountname"], accountNameIndex < fields.count {
            ledgerEntry.accountName = fields[accountNameIndex]
        }
        
        if let accountCodeIndex = columnMap["accountcode"], accountCodeIndex < fields.count {
            ledgerEntry.accountCode = fields[accountCodeIndex]
        }
        
        if let checkNumberIndex = columnMap["checknumber"], checkNumberIndex < fields.count {
            let checkNumber = fields[checkNumberIndex]
            if !checkNumber.isEmpty {
                ledgerEntry.checkNumber = checkNumber
            }
        }
        
        // Map new emoji and symbol fields
        if let emojiIndex = columnMap["emoji"], emojiIndex < fields.count {
            ledgerEntry.emoji = fields[emojiIndex]
        }
        
        if let symbolIndex = columnMap["iossymbol"], symbolIndex < fields.count {
            ledgerEntry.iosSymbol = fields[symbolIndex]
        }
        
        // Parse numeric fields
        if let debitAmountIndex = columnMap["debitamount"], debitAmountIndex < fields.count {
            let debitString = fields[debitAmountIndex]
            if !debitString.isEmpty, let debitValue = Decimal(string: debitString) {
                ledgerEntry.debitAmount = NSDecimalNumber(decimal: debitValue)
            }
        }
        
        if let creditAmountIndex = columnMap["creditamount"], creditAmountIndex < fields.count {
            let creditString = fields[creditAmountIndex]
            if !creditString.isEmpty, let creditValue = Decimal(string: creditString) {
                ledgerEntry.creditAmount = NSDecimalNumber(decimal: creditValue)
            }
        }
        
        if let amountIndex = columnMap["amount"], amountIndex < fields.count {
            let amountString = fields[amountIndex]
            if !amountString.isEmpty, let amountValue = Decimal(string: amountString) {
                ledgerEntry.amount = NSDecimalNumber(decimal: amountValue)
            }
        }
        
        if let balanceIndex = columnMap["balance"], balanceIndex < fields.count {
            let balanceString = fields[balanceIndex]
            if !balanceString.isEmpty, let balanceValue = Decimal(string: balanceString) {
                ledgerEntry.balance = NSDecimalNumber(decimal: balanceValue)
            }
        }
        
        // Parse date field
        if let dateIndex = columnMap["date"], dateIndex < fields.count {
            let dateString = fields[dateIndex]
            if !dateString.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                ledgerEntry.date = formatter.date(from: dateString)
            }
        }
    }
}

/// Errors for ledger test data loading
enum LedgerTestDataError: LocalizedError {
    case csvFileNotFound
    case invalidCSVFormat
    case dataProcessingError(String)
    
    var errorDescription: String? {
        switch self {
        case .csvFileNotFound:
            return "Ledger CSV file not found in bundle resources"
        case .invalidCSVFormat:
            return "Invalid ledger CSV format"
        case .dataProcessingError(let message):
            return "Ledger data processing error: \(message)"
        }
    }
}