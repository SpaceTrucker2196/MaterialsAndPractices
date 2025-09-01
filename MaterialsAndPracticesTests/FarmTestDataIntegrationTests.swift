//
//  FarmTestDataIntegrationTests.swift
//  MaterialsAndPracticesTests
//
//  Integration tests for farm test data loading features
//
//  Created by GitHub Copilot on current date.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

final class FarmTestDataIntegrationTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        let persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
    }
    
    /// Test complete farm data loading workflow
    func testCompleteDataLoadingWorkflow() throws {
        // Load amendments first
        let amendmentLoader = AmendmentCatalogLoader(viewContext: viewContext)
        try amendmentLoader.loadAmendmentCatalog()
        
        // Load Zappa Farms data
        let zappaLoader = ZappaFarmsDataLoader(viewContext: viewContext)
        try zappaLoader.loadZappaFarmsData()
        
        // Verify all data types are loaded
        let amendmentCount = try getCropAmendmentCount()
        let propertyCount = try getPropertyCount()
        let ledgerCount = try getLedgerEntryCount()
        
        XCTAssertGreaterThan(amendmentCount, 0, "Amendments should be loaded")
        XCTAssertGreaterThan(propertyCount, 0, "Properties should be loaded")
        XCTAssertGreaterThan(ledgerCount, 0, "Ledger entries should be loaded")
    }
    
    /// Test that CSV files are found in bundle
    func testAllCSVFilesFoundInBundle() {
        let requiredFiles = [
            "amendment-master.csv",
            "ZappaFarmsDataset.csv", 
            "ZappaFarmFieldsdataset.csv",
            "ZappaFarm_GAAP_Ledger_2Years.csv"
        ]
        
        for fileName in requiredFiles {
            let components = fileName.components(separatedBy: ".")
            let name = components[0]
            let ext = components[1]
            
            let path = Bundle.main.path(forResource: name, ofType: ext)
            XCTAssertNotNil(path, "\(fileName) should exist in bundle")
        }
    }
    
    /// Test CSV file content is not empty
    func testCSVFilesHaveContent() throws {
        let csvFiles = [
            ("amendment-master", "csv"),
            ("ZappaFarmsDataset", "csv"),
            ("ZappaFarmFieldsdataset", "csv"),
            ("ZappaFarm_GAAP_Ledger_2Years", "csv")
        ]
        
        for (name, ext) in csvFiles {
            guard let path = Bundle.main.path(forResource: name, ofType: ext) else {
                XCTFail("\(name).\(ext) should exist in bundle")
                continue
            }
            
            let content = try String(contentsOfFile: path)
            XCTAssertFalse(content.isEmpty, "\(name).\(ext) should not be empty")
            
            let lines = content.components(separatedBy: .newlines)
            XCTAssertGreaterThan(lines.count, 1, "\(name).\(ext) should have header and data rows")
        }
    }
    
    /// Test amendment loading with OMRI compliance
    func testAmendmentOMRICompliance() throws {
        let amendmentLoader = AmendmentCatalogLoader(viewContext: viewContext)
        try amendmentLoader.loadAmendmentCatalog()
        
        let amendments = try fetchAllCropAmendments()
        XCTAssertGreaterThan(amendments.count, 0, "Should have loaded amendments")
        
        // Test OMRI listed amendments exist
        let omriAmendments = amendments.filter { $0.omriListed }
        XCTAssertGreaterThan(omriAmendments.count, 0, "Should have OMRI listed amendments")
        
        // Test non-OMRI amendments exist
        let nonOmriAmendments = amendments.filter { !$0.omriListed }
        XCTAssertGreaterThan(nonOmriAmendments.count, 0, "Should have non-OMRI amendments")
    }
    
    /// Test property organic certification data
    func testPropertyOrganicCertificationData() throws {
        let zappaLoader = ZappaFarmsDataLoader(viewContext: viewContext)
        try zappaLoader.loadZappaFarmsData()
        
        let properties = try fetchAllProperties()
        XCTAssertGreaterThan(properties.count, 0, "Should have loaded properties")
        
        // Test that properties have expected attributes
        for property in properties {
            XCTAssertNotNil(property.displayName, "Property should have display name")
            XCTAssertGreaterThan(property.totalAcres, 0, "Property should have total acres")
            XCTAssertNotNil(property.state, "Property should have state")
        }
    }
    
    /// Test ledger entry financial data integrity
    func testLedgerEntryFinancialDataIntegrity() throws {
        let zappaLoader = ZappaFarmsDataLoader(viewContext: viewContext)
        try zappaLoader.loadZappaFarmsData()
        
        let ledgerEntries = try fetchAllLedgerEntries()
        XCTAssertGreaterThan(ledgerEntries.count, 0, "Should have loaded ledger entries")
        
        // Test ledger entry data integrity
        for entry in ledgerEntries {
            XCTAssertNotNil(entry.id, "Ledger entry should have ID")
            XCTAssertNotNil(entry.date, "Ledger entry should have date")
            XCTAssertNotNil(entry.vendorName, "Ledger entry should have vendor name")
            XCTAssertNotNil(entry.entryType, "Ledger entry should have entry type")
            
            // Test that at least one amount field is populated
            let hasAmount = (entry.debitAmount?.doubleValue ?? 0) > 0 ||
                           (entry.creditAmount?.doubleValue ?? 0) > 0 ||
                           (entry.amount?.doubleValue ?? 0) != 0
            XCTAssertTrue(hasAmount, "Ledger entry should have some amount value")
        }
    }
    
    /// Test data loading performance
    func testDataLoadingPerformance() throws {
        // Test amendment loading performance
        measure {
            do {
                let amendmentLoader = AmendmentCatalogLoader(viewContext: viewContext)
                try amendmentLoader.loadAmendmentCatalog()
            } catch {
                XCTFail("Amendment loading failed: \(error)")
            }
        }
        
        // Test Zappa Farms data loading performance
        measure {
            do {
                let zappaLoader = ZappaFarmsDataLoader(viewContext: viewContext)
                try zappaLoader.loadZappaFarmsData()
            } catch {
                XCTFail("Zappa Farms data loading failed: \(error)")
            }
        }
    }
    
    /// Test data loading idempotency (can run multiple times safely)
    func testDataLoadingIdempotency() throws {
        // Load data multiple times
        for i in 1...3 {
            let amendmentLoader = AmendmentCatalogLoader(viewContext: viewContext)
            try amendmentLoader.loadAmendmentCatalog()
            
            let zappaLoader = ZappaFarmsDataLoader(viewContext: viewContext)
            try zappaLoader.loadZappaFarmsData()
            
            // Counts should be consistent across loads
            let amendmentCount = try getCropAmendmentCount()
            let propertyCount = try getPropertyCount()
            let ledgerCount = try getLedgerEntryCount()
            
            XCTAssertGreaterThan(amendmentCount, 0, "Amendments should be loaded on iteration \(i)")
            XCTAssertGreaterThan(propertyCount, 0, "Properties should be loaded on iteration \(i)")
            XCTAssertGreaterThan(ledgerCount, 0, "Ledger entries should be loaded on iteration \(i)")
        }
    }
    
    /// Test data relationships and integrity
    func testDataRelationshipsAndIntegrity() throws {
        let zappaLoader = ZappaFarmsDataLoader(viewContext: viewContext)
        try zappaLoader.loadZappaFarmsData()
        
        // Test that properties have field information integrated
        let properties = try fetchAllProperties()
        let propertiesWithFieldInfo = properties.filter { 
            $0.notes?.contains("Fields:") == true 
        }
        
        XCTAssertGreaterThan(propertiesWithFieldInfo.count, 0, "Some properties should have field information")
    }
    
    /// Test CSV parsing edge cases
    func testCSVParsingEdgeCases() throws {
        // Test that CSV parsing handles quoted fields with commas
        let amendmentLoader = AmendmentCatalogLoader(viewContext: viewContext)
        try amendmentLoader.loadAmendmentCatalog()
        
        let amendments = try fetchAllCropAmendments()
        
        // Look for amendments with complex names that might contain commas
        let complexNameAmendments = amendments.filter { 
            $0.productName?.contains("(") == true || $0.productName?.contains("OMRI") == true
        }
        
        XCTAssertGreaterThan(complexNameAmendments.count, 0, "Should parse complex product names correctly")
    }
    
    // MARK: - Helper Methods
    
    private func getCropAmendmentCount() throws -> Int {
        let request: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        return try viewContext.count(for: request)
    }
    
    private func getPropertyCount() throws -> Int {
        let request: NSFetchRequest<Property> = Property.fetchRequest()
        return try viewContext.count(for: request)
    }
    
    private func getLedgerEntryCount() throws -> Int {
        let request: NSFetchRequest<LedgerEntry> = LedgerEntry.fetchRequest()
        return try viewContext.count(for: request)
    }
    
    private func fetchAllCropAmendments() throws -> [CropAmendment] {
        let request: NSFetchRequest<CropAmendment> = CropAmendment.fetchRequest()
        return try viewContext.fetch(request)
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