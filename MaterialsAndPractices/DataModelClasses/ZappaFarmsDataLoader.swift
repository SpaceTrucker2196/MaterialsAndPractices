//
//  ZappaFarmsDataLoader.swift
//  MaterialsAndPractices
//
//  Zappa Farms test data loader for properties, fields, and ledger entries.
//  Provides functionality to load comprehensive farm test data for development and testing.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CoreData

extension Array {
    subscript(safe index: Int) -> Element? {
        return (startIndex..<endIndex).contains(index) ? self[index] : nil
    }
}

/// Zappa Farms test data loader
class ZappaFarmsDataLoader {
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    /// Load complete Zappa Farms dataset
    func loadZappaFarmsData() throws {
        // Load properties first
        try loadProperties()
        
        // Load fields for each property
       // try loadFields()
        
        // Load ledger entries
        try loadLedgerEntries()
        
        print("✅ Successfully loaded complete Zappa Farms dataset")
    }
    
    /// Load properties from ZappaFarmsDataset.csv
    private func loadProperties() throws {
        // Clear existing properties first
        try clearExistingProperties()
        
        // Load CSV data
        guard let csvPath = Bundle.main.path(forResource: "ZappaFarmsDataset", ofType: "csv" ),
              let csvContent = try? String(contentsOfFile: csvPath) else {
            throw ZappaFarmsDataError.propertiesCSVNotFound
        }
        
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ZappaFarmsDataError.invalidCSVFormat
        }
        
        // Parse header to get column indices
        let headers = parseCSVLine(lines[1])
        let columnMap = createColumnMap(headers: headers)
        
        // Process each property row
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty {
                try createPropertyFromCSVLine(line, columnMap: columnMap)
            }
        }
        
        // Save the context
        try viewContext.save()
        
        print("✅ Successfully loaded \(lines.count - 1) properties")
    }
    
    /// Load fields from ZappaFarmFieldsdataset.csv  
    private func loadFields() throws {
        // Note: Since Field may not be a separate entity, we'll store field info in Property notes
        // or extend Property with field-related properties
        
        guard let csvPath = Bundle.main.path(forResource: "ZappaFarmFieldsdataset", ofType: "csv"),
              let csvContent = try? String(contentsOfFile: csvPath) else {
            throw ZappaFarmsDataError.fieldsCSVNotFound
        }
        
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ZappaFarmsDataError.invalidCSVFormat
        }
        
        let propertyRequest: NSFetchRequest<Property> = Property.fetchRequest()
        let properties = try viewContext.fetch(propertyRequest)
        guard properties.count > 0 else {
            return
        }
        
        
        // Parse header to get column indices4
        let headers = parseCSVLine(lines[1])
        let columnMap = createColumnMap(headers: headers)
        
        // Group fields by property ID and add to property notes
        var fieldsData: [String: [String]] = [:]
        
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty {
                let fields = parseCSVLine(line)
                let field = Field(context: viewContext)
                
                if let propertyIdIndex = columnMap["propertyid"], propertyIdIndex < fields.count {
                    let propertyId = fields[propertyIdIndex]
                    if fieldsData[propertyId] == nil {
                        fieldsData[propertyId] = []
                    }
                    
                    // Create field description
                    var fieldDescription = ""
                    if let fieldNameIndex = columnMap["fieldname"], fieldNameIndex < fields.count {
                        fieldDescription += "Field: \(fields[fieldNameIndex])"
                        field.name = fields[fieldNameIndex]
                        
                        
                    }
                    if let acreageIndex = columnMap["acreage"], acreageIndex < fields.count {
                        fieldDescription += " (\(fields[acreageIndex]) acres)"
                       // field.description = fields[acreageIndex]
                    }
                    if let primaryCropIndex = columnMap["primarycrop"], primaryCropIndex < fields.count {
                        fieldDescription += " - Primary: \(fields[primaryCropIndex])"
                       
                    }
                    
                    field.property = properties.randomElement()
                }
            }
          
        }
        try viewContext.save()
        // Update properties with field information
        for (propertyId, fieldDescriptions) in fieldsData {
            updatePropertyWithFieldData(propertyId: propertyId, fieldDescriptions: fieldDescriptions)
        }
        
        try viewContext.save()
        print("✅ Successfully loaded field data for properties")
    }
    
    /// Load ledger entries from ZappaFarm_GAAP_Ledger_2Years.csv
    private func loadLedgerEntries() throws {
        // Clear existing ledger entries first
        try clearExistingLedgerEntries()
        
        // Load CSV data
        guard let csvPath = Bundle.main.path(forResource: "ZappaFarm_GAAP_Ledger_2Years", ofType: "csv"),
              let csvContent = try? String(contentsOfFile: csvPath) else {
            throw ZappaFarmsDataError.ledgerCSVNotFound
        }
        
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ZappaFarmsDataError.invalidCSVFormat
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
        
        print("✅ Successfully loaded \(lines.count - 1) ledger entries")
    }
    
    /// Clear existing properties
    private func clearExistingProperties() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Property.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        try viewContext.execute(deleteRequest)
        try viewContext.save()
        
        print("🗑️ Cleared existing properties")
    }
    
    /// Clear existing ledger entries
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
    
    /// Create property from CSV line
    private func createPropertyFromCSVLine(_ line: String, columnMap: [String: Int]) throws {
        let fields = parseCSVLine(line)
        
        let property = Property(context: viewContext)
        property.id = UUID()
        
        // Map basic fields
        if let displayNameIndex = columnMap["displayname"], displayNameIndex < fields.count {
            property.displayName = fields[displayNameIndex]
        
        }
        
        if let countyIndex = columnMap["county"], countyIndex < fields.count {
            property.county = fields[countyIndex]
        }
        
        if let stateIndex = columnMap["state"], stateIndex < fields.count {
            property.state = fields[stateIndex]
        }
        
        if let totalAcresIndex = columnMap["totalacres"], totalAcresIndex < fields.count {
            let acresString = fields[totalAcresIndex]
            if let acresValue = Double(acresString) {
                property.totalAcres = acresValue
            }
        }
        
        if let tillableAcresIndex = columnMap["tillableacres"], tillableAcresIndex < fields.count {
            let acresString = fields[tillableAcresIndex]
            if let acresValue = Double(acresString) {
                property.tillableAcres = acresValue
            }
        }
        
        if let pastureAcresIndex = columnMap["pastureacres"], pastureAcresIndex < fields.count {
            let acresString = fields[pastureAcresIndex]
            if let acresValue = Double(acresString) {
                property.pastureAcres = acresValue
            }
        }
        
        if let woodlandAcresIndex = columnMap["woodlandacres"], woodlandAcresIndex < fields.count {
            let acresString = fields[woodlandAcresIndex]
            if let acresValue = Double(acresString) {
                property.woodlandAcres = acresValue
            }
        }
        
        if let wetlandAcresIndex = columnMap["wetlandacres"], wetlandAcresIndex < fields.count {
            let acresString = fields[wetlandAcresIndex]
            if let acresValue = Double(acresString) {
                property.wetlandAcres = acresValue
            }
        }
        
        if let hasIrrigationIndex = columnMap["hasirrigation"], hasIrrigationIndex < fields.count {
            property.hasIrrigation = fields[hasIrrigationIndex].lowercased() == "true"
        }
        
        if let notesIndex = columnMap["notes"], notesIndex < fields.count {
            property.notes = fields[notesIndex]
        }
    }
    
    /// Update property with field data
    private func updatePropertyWithFieldData(propertyId: String, fieldDescriptions: [String]) {
        // Find property by trying to match display name or create a lookup
        let fetchRequest: NSFetchRequest<Property> = Property.fetchRequest()
        
        do {
            let properties = try viewContext.fetch(fetchRequest)
            let field = Field(context: viewContext)
            
            // For now, match by array index (property 1 = first property, etc.)
            if let propertyIndex = Int(propertyId), propertyIndex > 0 && propertyIndex <= properties.count {
                let property = properties[propertyIndex - 1]
                let fieldInfo = fieldDescriptions.joined(separator: "\n")
                property.notes = (property.notes ?? "") + "\n\nFields:\n" + fieldInfo
            }
        } catch {
            print("❌ Error updating property with field data: \(error)")
        }
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
        
        // Map basic fields (using same logic as LedgerTestDataLoader)
        if let vendorNameIndex = columnMap["vendorname"], vendorNameIndex < fields.count {
            ledgerEntry.vendorName = fields[vendorNameIndex]
        }
        
        if let accountNameIndex = columnMap["accountname"], accountNameIndex < fields.count {
            ledgerEntry.accountName = fields[accountNameIndex]
        }
        
        if let accountCodeIndex = columnMap["accountcode"], accountCodeIndex < fields.count {
            ledgerEntry.accountCode = fields[accountCodeIndex]
        }
        
        if let descriptionIndex = columnMap["ledgerdescription"], descriptionIndex < fields.count {
            ledgerEntry.ledgerDescription = fields[descriptionIndex]
        }
        
        if let entryTypeIndex = columnMap["entrytype"], entryTypeIndex < fields.count {
            ledgerEntry.entryType = fields[entryTypeIndex]
        }
        
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
        
        if let taxCategoryIndex = columnMap["taxcategory"], taxCategoryIndex < fields.count {
            ledgerEntry.taxCategory = fields[taxCategoryIndex]
        }
        
        if let referenceNumberIndex = columnMap["referencenumber"], referenceNumberIndex < fields.count {
            ledgerEntry.referenceNumber = fields[referenceNumberIndex]
        }
        
        if let checkNumberIndex = columnMap["checknumber"], checkNumberIndex < fields.count {
            let checkNumber = fields[checkNumberIndex]
            if !checkNumber.isEmpty {
                ledgerEntry.checkNumber = checkNumber
            }
        }
        
        if let reconciledIndex = columnMap["reconciled"], reconciledIndex < fields.count {
            ledgerEntry.reconciled = fields[reconciledIndex].lowercased() == "true"
        }
        
        if let notesIndex = columnMap["notes"], notesIndex < fields.count {
            ledgerEntry.notes = fields[notesIndex]
        }
        
        if let emojiIndex = columnMap["emoji"], emojiIndex < fields.count {
            ledgerEntry.emoji = fields[emojiIndex]
        }
        
        if let symbolIndex = columnMap["iossymbol"], symbolIndex < fields.count {
            ledgerEntry.iosSymbol = fields[symbolIndex]
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

/// Errors for Zappa Farms data loading
enum ZappaFarmsDataError: LocalizedError {
    case propertiesCSVNotFound
    case fieldsCSVNotFound
    case ledgerCSVNotFound
    case invalidCSVFormat
    case dataProcessingError(String)
    
    var errorDescription: String? {
        switch self {
        case .propertiesCSVNotFound:
            return "ZappaFarmsDataset.csv file not found in bundle resources"
        case .fieldsCSVNotFound:
            return "ZappaFarmFieldsdataset.csv file not found in bundle resources"
        case .ledgerCSVNotFound:
            return "ZappaFarm_GAAP_Ledger_2Years.csv file not found in bundle resources"
        case .invalidCSVFormat:
            return "Invalid CSV format in Zappa Farms data files"
        case .dataProcessingError(let message):
            return "Zappa Farms data processing error: \(message)"
        }
    }
}
