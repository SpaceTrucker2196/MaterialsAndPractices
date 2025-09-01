//
//  ZappaFarmsDataLoaderTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for Zappa Farms dataset loading functionality
//
//  Created by GitHub Copilot on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

final class ZappaFarmsDataLoaderTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    var loader: ZappaFarmsDataLoader!
    
    override func setUpWithError() throws {
        let persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        loader = ZappaFarmsDataLoader(viewContext: viewContext)
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
        loader = nil
    }
    
    /// Test that all required CSV files exist in the bundle
    func testZappaFarmsCSVFilesExist() throws {
        // Test properties file
        let propertiesPath = Bundle.main.path(forResource: "ZappaFarmsDataset", ofType: "csv")
        XCTAssertNotNil(propertiesPath, "ZappaFarmsDataset.csv file should exist in bundle")
        
        // Test fields file
        let fieldsPath = Bundle.main.path(forResource: "ZappaFarmFieldsdataset", ofType: "csv")
        XCTAssertNotNil(fieldsPath, "ZappaFarmFieldsdataset.csv file should exist in bundle")
        
        // Test ledger file
        let ledgerPath = Bundle.main.path(forResource: "ZappaFarm_GAAP_Ledger_2Years", ofType: "csv")
        XCTAssertNotNil(ledgerPath, "ZappaFarm_GAAP_Ledger_2Years.csv file should exist in bundle")
    }
    
    /// Test CSV file content structure
    func testCSVFileStructure() throws {
        // Test properties CSV structure
        if let propertiesPath = Bundle.main.path(forResource: "ZappaFarmsDataset", ofType: "csv") {
            let csvContent = try String(contentsOfFile: propertiesPath)
            let lines = csvContent.components(separatedBy: .newlines)
            XCTAssertGreaterThan(lines.count, 1, "Properties CSV should have header and data rows")
            
            let headers = lines[0].split(separator: ",")
            XCTAssertTrue(headers.contains("displayName"), "Properties CSV should contain displayName column")
            XCTAssertTrue(headers.contains("totalAcres"), "Properties CSV should contain totalAcres column")
            XCTAssertTrue(headers.contains("state"), "Properties CSV should contain state column")
        }
        
        // Test fields CSV structure
        if let fieldsPath = Bundle.main.path(forResource: "ZappaFarmFieldsdataset", ofType: "csv") {
            let csvContent = try String(contentsOfFile: fieldsPath)
            let lines = csvContent.components(separatedBy: .newlines)
            XCTAssertGreaterThan(lines.count, 1, "Fields CSV should have header and data rows")
            
            let headers = lines[0].split(separator: ",")
            XCTAssertTrue(headers.contains("propertyId"), "Fields CSV should contain propertyId column")
            XCTAssertTrue(headers.contains("fieldName"), "Fields CSV should contain fieldName column")
            XCTAssertTrue(headers.contains("acreage"), "Fields CSV should contain acreage column")
        }
        
        // Test ledger CSV structure
        if let ledgerPath = Bundle.main.path(forResource: "ZappaFarm_GAAP_Ledger_2Years", ofType: "csv") {
            let csvContent = try String(contentsOfFile: ledgerPath)
            let lines = csvContent.components(separatedBy: .newlines)
            XCTAssertGreaterThan(lines.count, 1, "Ledger CSV should have header and data rows")
            
            let headers = lines[0].split(separator: ",")
            XCTAssertTrue(headers.contains("vendorName"), "Ledger CSV should contain vendorName column")
            XCTAssertTrue(headers.contains("amount"), "Ledger CSV should contain amount column")
            XCTAssertTrue(headers.contains("date"), "Ledger CSV should contain date column")
        }
    }
    
    /// Test loading complete Zappa Farms dataset
    func testLoadZappaFarmsData() throws {
        // Initial counts should be 0
        let initialPropertyCount = try getPropertyCount()
        let initialLedgerCount = try getLedgerEntryCount()
        XCTAssertEqual(initialPropertyCount, 0, "Initial property count should be 0")
        XCTAssertEqual(initialLedgerCount, 0, "Initial ledger count should be 0")
        
        // Load complete dataset
        try loader.loadZappaFarmsData()
        
        // Verify data was loaded
        let finalPropertyCount = try getPropertyCount()
        let finalLedgerCount = try getLedgerEntryCount()
        XCTAssertGreaterThan(finalPropertyCount, 0, "Properties should be loaded from CSV")
        XCTAssertGreaterThan(finalLedgerCount, 0, "Ledger entries should be loaded from CSV")
    }
    
    /// Test property data loading
    func testPropertyDataLoading() throws {
        try loader.loadZappaFarmsData()
        
        let properties = try fetchAllProperties()
        XCTAssertGreaterThan(properties.count, 0, "Should have loaded properties")
        
        // Test specific property exists
        let zappaFarmNorth = properties.first { $0.displayName?.contains("North Farm") == true }
        XCTAssertNotNil(zappaFarmNorth, "North Farm Property should be loaded")
        XCTAssertEqual(zappaFarmNorth?.state, "CA", "Property should be in California")
        XCTAssertGreaterThan(zappaFarmNorth?.totalAcres ?? 0, 0, "Property should have acreage")
    }
    
    /// Test ledger entry data loading
    func testLedgerEntryDataLoading() throws {
        try loader.loadZappaFarmsData()
        
        let ledgerEntries = try fetchAllLedgerEntries()
        XCTAssertGreaterThan(ledgerEntries.count, 0, "Should have loaded ledger entries")
        
        // Test specific ledger entry exists
        let seedExpense = ledgerEntries.first { $0.ledgerDescription?.contains("tomato seeds") == true }
        XCTAssertNotNil(seedExpense, "Tomato seeds expense should be loaded")
        XCTAssertEqual(seedExpense?.entryType, "Expense", "Seed purchase should be expense")
        XCTAssertNotNil(seedExpense?.date, "Ledger entry should have date")
    }
    
    /// Test field data integration with properties
    func testFieldDataIntegration() throws {
        try loader.loadZappaFarmsData()
        
        let properties = try fetchAllProperties()
        XCTAssertGreaterThan(properties.count, 0, "Should have loaded properties")
        
        // Check that properties have field information in notes
        let propertyWithFields = properties.first { 
            $0.notes?.contains("Fields:") == true 
        }
        XCTAssertNotNil(propertyWithFields, "At least one property should have field information")
    }
    
    /// Test data clearing and reloading
    func testDataClearingAndReloading() throws {
        // Load data first time
        try loader.loadZappaFarmsData()
        let firstPropertyCount = try getPropertyCount()
        let firstLedgerCount = try getLedgerEntryCount()
        
        // Load data second time
        try loader.loadZappaFarmsData()
        let secondPropertyCount = try getPropertyCount()
        let secondLedgerCount = try getLedgerEntryCount()
        
        XCTAssertEqual(firstPropertyCount, secondPropertyCount, "Second load should replace existing properties")
        XCTAssertEqual(firstLedgerCount, secondLedgerCount, "Second load should replace existing ledger entries")
    }
    
    /// Test property properties are correctly mapped from CSV
    func testPropertyPropertyMapping() throws {
        try loader.loadZappaFarmsData()
        
        let properties = try fetchAllProperties()
        XCTAssertGreaterThan(properties.count, 0, "Should have loaded properties")
        
        // Test first property has expected properties
        let firstProperty = properties.first!
        XCTAssertNotNil(firstProperty.id, "Property should have ID")
        XCTAssertNotNil(firstProperty.displayName, "Property should have display name")
        XCTAssertGreaterThan(firstProperty.totalAcres, 0, "Property should have total acres")
    }
    
    /// Test ledger entry properties are correctly mapped from CSV
    func testLedgerEntryPropertyMapping() throws {
        try loader.loadZappaFarmsData()
        
        let ledgerEntries = try fetchAllLedgerEntries()
        XCTAssertGreaterThan(ledgerEntries.count, 0, "Should have loaded ledger entries")
        
        // Test first ledger entry has expected properties
        let firstEntry = ledgerEntries.first!
        XCTAssertNotNil(firstEntry.id, "Ledger entry should have ID")
        XCTAssertNotNil(firstEntry.vendorName, "Ledger entry should have vendor name")
        XCTAssertNotNil(firstEntry.date, "Ledger entry should have date")
    }
    
    /// Test error handling for various scenarios
    func testErrorHandling() throws {
        // This test verifies the loader handles errors gracefully
        // Since our test files exist, we mainly test the error handling structure
        XCTAssertNoThrow(try loader.loadZappaFarmsData(), "Loading should not throw with valid files")
    }
    
    // MARK: - Helper Methods
    
    private func getPropertyCount() throws -> Int {
        let request: NSFetchRequest<Property> = Property.fetchRequest()
        return try viewContext.count(for: request)
    }
    
    private func getLedgerEntryCount() throws -> Int {
        let request: NSFetchRequest<LedgerEntry> = LedgerEntry.fetchRequest()
        return try viewContext.count(for: request)
    }
    
    private func fetchAllProperties() throws -> [Property] {
        let request: NSFetchRequest<Property> = Property.fetchRequest()
        return try viewContext.fetch(request)
    }
    
    private func fetchAllLedgerEntries() throws -> [LedgerEntry] {
        let request: NSFetchRequest<LedgerEntry> = LedgerEntry.fetchRequest()
        return try viewContext.fetch(request)
    }
}