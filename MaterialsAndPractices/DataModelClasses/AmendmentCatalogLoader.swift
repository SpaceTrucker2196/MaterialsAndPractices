//
//  AmendmentCatalogLoader.swift
//  MaterialsAndPractices
//
//  Amendment catalog loader for loading crop amendments from CSV file.
//  Provides functionality to load amendment test data for development and testing.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CoreData

/// Amendment catalog loader for crop amendments
class AmendmentCatalogLoader {
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    /// Load amendment catalog from CSV file
    func loadAmendmentCatalog() throws {
        // Clear existing amendments first (optional - ask user)
        try clearExistingAmendments()
        
        // Load CSV data
        guard let csvPath = Bundle.main.path(forResource: "amendment-master", ofType: "csv"),
              let csvContent = try? String(contentsOfFile: csvPath) else {
            throw AmendmentCatalogError.csvFileNotFound
        }
        
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw AmendmentCatalogError.invalidCSVFormat
        }
        
        // Parse header to get column indices
        let headers = parseCSVLine(lines[0])
        let columnMap = createColumnMap(headers: headers)
        
        // Process each amendment row
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty {
                try createAmendmentFromCSVLine(line, columnMap: columnMap)
            }
        }
        
        // Save the context
        try viewContext.save()
        
        print("✅ Successfully loaded \(lines.count - 1) amendments to catalog")
    }
    
    /// Clear all existing crop amendments
    private func clearExistingAmendments() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CropAmendment.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        try viewContext.execute(deleteRequest)
        try viewContext.save()
        
        print("🗑️ Cleared existing crop amendments")
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
    
    /// Create crop amendment from CSV line
    private func createAmendmentFromCSVLine(_ line: String, columnMap: [String: Int]) throws {
        let fields = parseCSVLine(line)
        
        let amendment = CropAmendment(context: viewContext)
        amendment.amendmentID = UUID()
        amendment.dateApplied = Date() // Current date for catalog import
        
        // Map basic fields
        if let productNameIndex = columnMap["productname"], productNameIndex < fields.count {
            amendment.productName = fields[productNameIndex]
        }
        
        if let applicationRateIndex = columnMap["applicationrate"], applicationRateIndex < fields.count {
            amendment.applicationRate = fields[applicationRateIndex]
        }
        
        if let unitOfMeasureIndex = columnMap["unitofmeasure"], unitOfMeasureIndex < fields.count {
            amendment.unitOfMeasure = fields[unitOfMeasureIndex]
        }
        
        if let cropTreatedIndex = columnMap["croptreated"], cropTreatedIndex < fields.count {
            amendment.cropTreated = fields[cropTreatedIndex]
        }
        
        if let locationIndex = columnMap["location"], locationIndex < fields.count {
            amendment.location = fields[locationIndex]
        }
        
        if let applicationMethodIndex = columnMap["applicationmethod"], applicationMethodIndex < fields.count {
            amendment.applicationMethod = fields[applicationMethodIndex]
        }
        
        if let productTypeIndex = columnMap["producttype"], productTypeIndex < fields.count {
            amendment.productType = fields[productTypeIndex]
        }
        
        if let omriListedIndex = columnMap["omrilisted"], omriListedIndex < fields.count {
            amendment.omriListed = fields[omriListedIndex].lowercased() == "true"
        }
        
        if let epaRegistrationIndex = columnMap["eparegistrationnumber"], epaRegistrationIndex < fields.count {
            let epaNumber = fields[epaRegistrationIndex]
            if !epaNumber.isEmpty {
                amendment.epaRegistrationNumber = epaNumber
            }
        }
        
        if let reEntryIntervalIndex = columnMap["reentryintervalhours"], reEntryIntervalIndex < fields.count {
            let interval = fields[reEntryIntervalIndex]
            if let intervalValue = Int16(interval) {
                amendment.reEntryIntervalHours = intervalValue
            }
        }
        
        if let preHarvestIntervalIndex = columnMap["preharvestintervaldays"], preHarvestIntervalIndex < fields.count {
            let interval = fields[preHarvestIntervalIndex]
            if let intervalValue = Int16(interval) {
                amendment.preHarvestIntervalDays = intervalValue
            }
        }
        
        if let weatherConditionsIndex = columnMap["weatherconditions"], weatherConditionsIndex < fields.count {
            amendment.weatherConditions = fields[weatherConditionsIndex]
        }
        
        if let applicatorNameIndex = columnMap["applicatorname"], applicatorNameIndex < fields.count {
            amendment.applicatorName = fields[applicatorNameIndex]
        }
        
        if let applicatorCertIndex = columnMap["applicatorcertificationid"], applicatorCertIndex < fields.count {
            let certId = fields[applicatorCertIndex]
            if !certId.isEmpty {
                amendment.applicatorCertificationID = certId
            }
        }
        
        if let batchLotIndex = columnMap["batchlotnumber"], batchLotIndex < fields.count {
            let batchLot = fields[batchLotIndex]
            if !batchLot.isEmpty {
                amendment.batchLotNumber = batchLot
            }
        }
        
        if let notesIndex = columnMap["notes"], notesIndex < fields.count {
            amendment.notes = fields[notesIndex]
        }
    }
}

/// Errors for amendment catalog loading
enum AmendmentCatalogError: LocalizedError {
    case csvFileNotFound
    case invalidCSVFormat
    case dataProcessingError(String)
    
    var errorDescription: String? {
        switch self {
        case .csvFileNotFound:
            return "amendment-master.csv file not found in bundle resources"
        case .invalidCSVFormat:
            return "Invalid amendment catalog CSV format"
        case .dataProcessingError(let message):
            return "Amendment data processing error: \(message)"
        }
    }
}