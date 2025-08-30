//
//  CultivarSeeder.swift
//  MaterialsAndPractices
//
//  Provides enriched USDA plant cultivar data seeding functionality for initial application setup.
//  Implements comprehensive vegetable cultivar database population from CSV data source
//  with proper error handling and duplicate prevention mechanisms.
//
//  Updated to use enriched CSV data with weather tolerance, growing days, harvest timing, and more.
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import CoreData
import Foundation

/// Utility structure for seeding Core Data with enriched USDA vegetable cultivar information
/// Ensures application has comprehensive plant database for organic farming operations
struct CultivarSeeder {
    
    // MARK: - Public Methods
    
    /// Seeds the Core Data context with enriched USDA vegetable cultivar data from CSV
    /// Implements duplicate prevention and proper error handling
    /// - Parameter context: The NSManagedObjectContext to seed with data
    static func seedCultivars(context: NSManagedObjectContext) {
        guard !cultivarsAlreadySeeded(in: context) else {
            print("Cultivars already seeded, skipping...")
            return
        }
        
        seedEnrichedCultivarsFromCSV(in: context)
    }
    
    // MARK: - Private Implementation Methods
    
    /// Checks if cultivars have already been seeded to prevent duplicate data
    /// - Parameter context: The Core Data context to check
    /// - Returns: Boolean indicating if cultivars exist in the database
    private static func cultivarsAlreadySeeded(in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<Cultivar> = Cultivar.fetchRequest()
        
        do {
            let existingCultivars = try context.fetch(request)
            return !existingCultivars.isEmpty
        } catch {
            print("Error checking existing cultivars: \(error)")
            return false
        }
    }
    
    /// Performs the actual seeding of enriched cultivar data from CSV
    /// Creates Cultivar entities with comprehensive plant information including weather tolerance,
    /// growing days, harvest timing, and planting schedules
    /// - Parameter context: The Core Data context for entity creation
    private static func seedEnrichedCultivarsFromCSV(in context: NSManagedObjectContext) {
        guard let csvPath = Bundle.main.path(forResource: "vegetable_cultivars_master", ofType: "csv") else {
            print("Error: Could not find CSV file in bundle")
            seedFallbackCultivars(in: context)
            return
        }
        
        do {
            let csvContent = try String(contentsOfFile: csvPath)
            let cultivarData = parseCSVContent(csvContent)
            
            for cultivarInfo in cultivarData {
                let cultivar = Cultivar(context: context)
                
                // Basic information
                cultivar.name = cultivarInfo.commonName ?? cultivarInfo.cultivarName ?? "Unknown"
                cultivar.commonName = cultivarInfo.commonName
                cultivar.cultivarName = cultivarInfo.cultivarName
                cultivar.family = cultivarInfo.family
                cultivar.genus = cultivarInfo.genus
                cultivar.cultivarDescription = cultivarInfo.description
                
                // Growing information
                cultivar.growingAdvice = cultivarInfo.growingAdvice
                cultivar.growingDays = cultivarInfo.growingDays
          
                cultivar.transplantAge = cultivarInfo.transplantAge
                cultivar.season = determineSeasonFromData(cultivarInfo)
                
                // Zone and weather information
                cultivar.weatherTolerance = cultivarInfo.weatherTolerance
                cultivar.optimalZones = cultivarInfo.optimalZones
                cultivar.usdaZoneList = cultivarInfo.usdaZoneList
                cultivar.hardyZone = extractHardyZone(from: cultivarInfo.optimalZones)
                
                // Planting and harvest timing
                cultivar.bestPlantingDates = cultivarInfo.bestPlantingDates
                cultivar.bestHarvest = cultivarInfo.bestHarvest
                cultivar.plantingWeek = extractPlantingWeek(from: cultivarInfo.bestPlantingDates)
                
                // Growing conditions
                cultivar.soilInfo = cultivarInfo.soilInfo
                cultivar.soilConditions = cultivarInfo.soilConditions
                cultivar.greenhouseInstructions = cultivarInfo.greenhouseInstructions
                
                // Additional information
                cultivar.pests = cultivarInfo.pests
                cultivar.amendments = cultivarInfo.amendments
                
                // New enriched metadata
                cultivar.approvedCommonName = cultivarInfo.approvedCommonName
                cultivar.emoji = cultivarInfo.emoji
                cultivar.iosColor = cultivarInfo.iosColor
                cultivar.fruitName = cultivarInfo.fruitName
                cultivar.harvestInstructions = cultivarInfo.harvestInstructions
                cultivar.ripenessIndicators = cultivarInfo.ripenessIndicators
            }

            
            try context.save()
            print("Successfully seeded \(cultivarData.count) enriched cultivars from CSV")
            
        } catch {
            print("Error seeding cultivars from CSV: \(error)")
            print("Falling back to basic cultivar data...")
            seedFallbackCultivars(in: context)
        }
    }
    
    /// Parses CSV content into structured cultivar data
    /// - Parameter csvContent: Raw CSV file content
    /// - Returns: Array of CultivarInfo structures
    private static func parseCSVContent(_ csvContent: String) -> [CultivarInfo] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { return [] }
        
        // Extract header to determine column indices
        let header = lines[0].components(separatedBy: ",")
        var cultivars: [CultivarInfo] = []
        
        for lineIndex in 1..<lines.count {
            let line = lines[lineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count >= header.count else { continue }
            
            let cultivarInfo = CultivarInfo(
                // Identity
                commonName: getField(fields, header: header, name: "CommonName"),
                family: getField(fields, header: header, name: "Family"),
                genus: getField(fields, header: header, name: "Genus"),
                cultivarName: getField(fields, header: header, name: "Cultivar"),
                description: getField(fields, header: header, name: "Description"),
                
                // Naming enrichments
                approvedCommonName: getField(fields, header: header, name: "ApprovedCommonName"),
                fruitName: getField(fields, header: header, name: "FruitName"),
                emoji: getField(fields, header: header, name: "Emoji"),
                iosColor: getField(fields, header: header, name: "iosColor"),
                
                // Growing information
                growingAdvice: getField(fields, header: header, name: "GrowingAdvice"),
                growingDays: getField(fields, header: header, name: "GrowingDays"),
                growingDaysEarly: getField(fields, header: header, name: "GrowingDaysEarly"),
                growingDaysLate: getField(fields, header: header, name: "GrowingDaysLate"),
                transplantAge: getField(fields, header: header, name: "TransplantAge"),
                transplantAgeEarly: getField(fields, header: header, name: "TransplantAgeEarly"),
                transplantAgeLate: getField(fields, header: header, name: "TransplantAgeLate"),
                season: getField(fields, header: header, name: "Season"),
                
                // Zone and weather information
                weatherTolerance: getField(fields, header: header, name: "WeatherTolerance"),
                optimalZones: getField(fields, header: header, name: "OptimalZones"),
                usdaZoneList: getField(fields, header: header, name: "USDAZoneList"),
                hardyZone: getField(fields, header: header, name: "HardyZone"),
                
                // Planting and harvest timing
                bestHarvest: getField(fields, header: header, name: "BestHarvest"),
                bestPlantingDates: getField(fields, header: header, name: "BestPlantingDates"),
                harvestInstructions: getField(fields, header: header, name: "HarvestInstructions"),
                ripenessIndicators: getField(fields, header: header, name: "RipenessIndicators"),
                
                // Growing conditions
                greenhouseInstructions: getField(fields, header: header, name: "GreenhouseInstructions"),
                soilInfo: getField(fields, header: header, name: "SoilInfo"),
                soilConditions: getField(fields, header: header, name: "SoilConditions"),
                
                // Additional information
                pests: getField(fields, header: header, name: "Pests"),
                amendments: getField(fields, header: header, name: "Amendments"),
                
                // Optional extras
                notes: getField(fields, header: header, name: "Notes"),
                sources: getField(fields, header: header, name: "Sources")
            )

            cultivars.append(cultivarInfo)
        }
        
        return cultivars
    }
    
    /// Parses a single CSV line handling quoted fields
    /// - Parameter line: CSV line to parse
    /// - Returns: Array of field values
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Add the last field
        fields.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return fields
    }
    
    /// Gets field value by header name
    /// - Parameters:
    ///   - fields: Array of field values
    ///   - header: Array of header names
    ///   - name: Field name to retrieve
    /// - Returns: Field value or nil if not found
    private static func getField(_ fields: [String], header: [String], name: String) -> String? {
        guard let index = header.firstIndex(of: name), index < fields.count else {
            return nil
        }
        let value = fields[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    
    /// Determines season from cultivar data
    /// - Parameter info: CultivarInfo with weather and timing data
    /// - Returns: Season string
    private static func determineSeasonFromData(_ info: CultivarInfo) -> String {
        if let weather = info.weatherTolerance {
            if weather.lowercased().contains("hot") || weather.lowercased().contains("tropical") {
                return "Summer"
            } else if weather.lowercased().contains("cold") {
                return "Cool Season"
            }
        }
        return "All Season"
    }
    
    /// Extracts hardy zone from optimal zones string
    /// - Parameter optimalZones: Optimal zones string
    /// - Returns: Hardy zone string
    private static func extractHardyZone(from optimalZones: String?) -> String? {
        guard let zones = optimalZones else { return nil }
        let components = zones.components(separatedBy: ",")
        if components.count >= 2 {
            return "\(components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")-\(components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")"
        }
        return zones
    }
    
    /// Extracts planting week from best planting dates
    /// - Parameter bestPlantingDates: Best planting dates JSON string
    /// - Returns: Planting week range string
    private static func extractPlantingWeek(from bestPlantingDates: String?) -> String? {
        // This would parse JSON to extract week ranges, simplified for now
        guard let dates = bestPlantingDates, !dates.isEmpty else { return nil }
        return "12-20" // Default range, could be enhanced to parse actual JSON
    }
    
    /// Fallback method to seed basic cultivar data if CSV parsing fails
    /// - Parameter context: Core Data context
    private static func seedFallbackCultivars(in context: NSManagedObjectContext) {
        let basicCultivars = [
            ("Tomato", "Solanaceae", "Summer", "5-9", "16-20"),
            ("Lettuce", "Asteraceae", "Cool Season", "3-9", "8-16"),
            ("Basil", "Lamiaceae", "Summer", "4-10", "16-20"),
            ("Carrot", "Apiaceae", "Cool Season", "3-9", "8-20"),
            ("Spinach", "Amaranthaceae", "Cool Season", "2-9", "8-16")
        ]
        
        for (name, family, season, zone, week) in basicCultivars {
            let cultivar = Cultivar(context: context)
            cultivar.name = name
            cultivar.family = family
            cultivar.season = season
            cultivar.hardyZone = zone
            cultivar.plantingWeek = week
        }
        
        do {
            try context.save()
            print("Successfully seeded \(basicCultivars.count) fallback cultivars")
        } catch {
            print("Error seeding fallback cultivars: \(error)")
        }
    }
}

// MARK: - Supporting Structures

/// Structure to hold parsed cultivar information from CSV
private struct CultivarInfo {
    // Identity
    let commonName: String?
    let family: String?
    let genus: String?
    let cultivarName: String?
    let description: String?
    
    // Naming enrichments
    let approvedCommonName: String?
    let fruitName: String?
    let emoji: String?
    let iosColor: String?
    
    // Growing information
    let growingAdvice: String?
    let growingDays: String?
    let growingDaysEarly: String?
    let growingDaysLate: String?
    let transplantAge: String?
    let transplantAgeEarly: String?
    let transplantAgeLate: String?
    let season: String?
    
    // Zone and weather information
    let weatherTolerance: String?
    let optimalZones: String?
    let usdaZoneList: String?
    let hardyZone: String?
    
    // Planting and harvest timing
    let bestHarvest: String?
    let bestPlantingDates: String?
    let harvestInstructions: String?
    let ripenessIndicators: String?
    
    // Growing conditions
    let greenhouseInstructions: String?
    let soilInfo: String?
    let soilConditions: String?
    
    // Additional information
    let pests: String?
    let amendments: String?
    
    // Optional extras
    let notes: String?
    let sources: String?
}
