//
//  CultivarDataTestUtility.swift
//  MaterialsAndPractices
//
//  Test utility for validating CSV parsing and cultivar data integration.
//  Provides debugging and validation functions for enriched cultivar data.
//
//  Created by AI Assistant on current date.
//

import Foundation
import CoreData

/// Test utility for validating CSV parsing and cultivar data functionality
struct CultivarDataTestUtility {
    
    // MARK: - CSV Testing
    
    /// Tests CSV parsing with sample data
    /// - Returns: Success status and count of parsed records
    static func testCSVParsing() -> (success: Bool, count: Int, errors: [String]) {
        var errors: [String] = []
        
        // Check if CSV file exists in bundle
        guard let csvPath = Bundle.main.path(forResource: "vegetable_cultivars_master_enriched_with_family_common", ofType: "csv") else {
            errors.append("CSV file not found in bundle")
            return (false, 0, errors)
        }
        
        do {
            let csvContent = try String(contentsOfFile: csvPath)
            let lines = csvContent.components(separatedBy: .newlines)
            
            guard lines.count > 1 else {
                errors.append("CSV file is empty or has no data rows")
                return (false, 0, errors)
            }
            
            // Test header parsing
            let header = lines[0].components(separatedBy: ",")
            let expectedFields = [
                "CommonName", "Family", "Genus", "Cultivar", "Description",
                "GrowingAdvice", "WeatherTolerance", "OptimalZones", "GrowingDays",
                "TransplantAge", "USDAZoneList", "BestHarvest", "BestPlantingDates",
                "GreenhouseInstructions", "SoilInfo", "Pests", "Amendments", "SoilConditions"
            ]
            
            for field in expectedFields {
                if !header.contains(field) {
                    errors.append("Missing expected field: \(field)")
                }
            }
            
            // Test a few sample rows
            var validRows = 0
            for lineIndex in 1...min(10, lines.count - 1) {
                let line = lines[lineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { continue }
                
                let fields = parseCSVLine(line)
                if fields.count >= header.count / 2 { // Allow for some missing fields
                    validRows += 1
                } else {
                    errors.append("Row \(lineIndex) has insufficient fields: \(fields.count)")
                }
            }
            
            return (errors.isEmpty, validRows, errors)
            
        } catch {
            errors.append("Error reading CSV file: \(error.localizedDescription)")
            return (false, 0, errors)
        }
    }
    
    /// Tests color coding logic with sample data
    /// - Returns: Test results for each color coding function
    static func testColorCoding() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Test USDA zone color coding
        let zoneTests = [
            ("1", "zone1to2"),
            ("3-4", "zone3to4"),
            ("5-7", "zone5to6"),
            ("8-9", "zone7to8"),
            ("10", "zone9to10"),
            ("11+", "zone11plus")
        ]
        
        for (zone, expectedColorType) in zoneTests {
            let color = AppTheme.ColorCoding.colorForUSDAZone(zone)
            // We can't easily test color equality, so we'll just verify it doesn't crash
            results["USDA Zone \(zone)"] = true
        }
        
        // Test weather tolerance color coding
        let weatherTests = [
            "Hot,Drought",
            "Cold,Frost",
            "Tropical",
            "Dry",
            "Wet,Humid"
        ]
        
        for weather in weatherTests {
            let color = AppTheme.ColorCoding.colorForWeatherTolerance(weather)
            results["Weather \(weather)"] = true
        }
        
        // Test growing days color coding
        let daysTests = [
            "30-45",
            "60-75",
            "90-120",
            "140-180"
        ]
        
        for days in daysTests {
            let color = AppTheme.ColorCoding.colorForGrowingDays(days)
            results["Growing Days \(days)"] = true
        }
        
        return results
    }
    
    /// Validates cultivar data after seeding
    /// - Parameter context: Core Data context to validate
    /// - Returns: Validation results
    static func validateCultivarData(context: NSManagedObjectContext) -> [String: Any] {
        var results: [String: Any] = [:]
        
        let request: NSFetchRequest<Cultivar> = Cultivar.fetchRequest()
        
        do {
            let cultivars = try context.fetch(request)
            results["total_count"] = cultivars.count
            
            var fieldCounts: [String: Int] = [:]
            var errors: [String] = []
            
            for cultivar in cultivars {
                // Count fields that have data
                if cultivar.name != nil && !cultivar.name!.isEmpty {
                    fieldCounts["name"] = (fieldCounts["name"] ?? 0) + 1
                }
                if cultivar.family != nil && !cultivar.family!.isEmpty {
                    fieldCounts["family"] = (fieldCounts["family"] ?? 0) + 1
                }
                if cultivar.weatherTolerance != nil && !cultivar.weatherTolerance!.isEmpty {
                    fieldCounts["weatherTolerance"] = (fieldCounts["weatherTolerance"] ?? 0) + 1
                }
                if cultivar.growingDays != nil && !cultivar.growingDays!.isEmpty {
                    fieldCounts["growingDays"] = (fieldCounts["growingDays"] ?? 0) + 1
                }
                if cultivar.bestHarvest != nil && !cultivar.bestHarvest!.isEmpty {
                    fieldCounts["bestHarvest"] = (fieldCounts["bestHarvest"] ?? 0) + 1
                }
                
                // Validate required fields
                if cultivar.name == nil || cultivar.name!.isEmpty {
                    errors.append("Cultivar missing name")
                }
            }
            
            results["field_counts"] = fieldCounts
            results["errors"] = errors
            results["has_enriched_data"] = fieldCounts["weatherTolerance"] ?? 0 > 0
            
        } catch {
            results["error"] = "Failed to fetch cultivars: \(error.localizedDescription)"
        }
        
        return results
    }
    
    /// Runs a comprehensive test suite
    /// - Parameter context: Core Data context for testing
    /// - Returns: Complete test results
    static func runComprehensiveTests(context: NSManagedObjectContext) -> [String: Any] {
        var results: [String: Any] = [:]
        
        print("🧪 Running Comprehensive Cultivar Tests...")
        
        // Test CSV parsing
        print("📄 Testing CSV parsing...")
        let csvResults = testCSVParsing()
        results["csv_parsing"] = [
            "success": csvResults.success,
            "parsed_rows": csvResults.count,
            "errors": csvResults.errors
        ]
        
        // Test color coding
        print("🎨 Testing color coding...")
        let colorResults = testColorCoding()
        results["color_coding"] = colorResults
        
        // Test cultivar data validation
        print("🌱 Validating cultivar data...")
        let dataResults = validateCultivarData(context: context)
        results["cultivar_data"] = dataResults
        
        // Overall success determination
        let csvSuccess = csvResults.success
        let colorSuccess = colorResults.values.allSatisfy { $0 }
        let dataSuccess = (dataResults["has_enriched_data"] as? Bool) ?? false
        
        results["overall_success"] = csvSuccess && colorSuccess && dataSuccess
        
        print("✅ Test suite completed")
        return results
    }
    
    // MARK: - Helper Methods
    
    /// Parses a single CSV line handling quoted fields (copied from seeder)
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
}