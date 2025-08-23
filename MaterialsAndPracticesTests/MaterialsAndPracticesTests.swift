//
//  MaterialsAndPracticesTests.swift
//  MaterialsAndPracticesTests
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class MaterialsAndPracticesTests: XCTestCase {
    
    var mockPersistenceController: PersistenceController!
    var mockContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        mockPersistenceController = PersistenceController(inMemory: true)
        mockContext = mockPersistenceController.container.viewContext
    }

    override func tearDownWithError() throws {
        mockPersistenceController = nil
        mockContext = nil
    }

    func testCultivarSeeding() throws {
        // Given: A fresh context
        let request: NSFetchRequest<Cultivar> = Cultivar.fetchRequest()
        let initialCount = try mockContext.fetch(request).count
        XCTAssertEqual(initialCount, 0, "Context should start empty")
        
        // When: Seeding cultivars
        CultivarSeeder.seedCultivars(context: mockContext)
        
        // Then: Cultivars should be created
        let cultivars = try mockContext.fetch(request)
        XCTAssertGreaterThan(cultivars.count, 0, "Cultivars should be seeded")
        
        // Verify some specific cultivars exist
        let amaranthCultivars = cultivars.filter { $0.family == "Amaranthaceae" }
        XCTAssertGreaterThan(amaranthCultivars.count, 0, "Should have amaranth family cultivars")
        
        let tomatoCultivars = cultivars.filter { $0.family == "Solanaceae" && $0.name?.contains("tomato") == true }
        XCTAssertGreaterThan(tomatoCultivars.count, 0, "Should have tomato cultivars")
    }
    
    func testCultivarRequiredFields() throws {
        // Given: Seeded cultivars
        CultivarSeeder.seedCultivars(context: mockContext)
        let request: NSFetchRequest<Cultivar> = Cultivar.fetchRequest()
        let cultivars = try mockContext.fetch(request)
        
        // Then: All cultivars should have required fields
        for cultivar in cultivars {
            XCTAssertNotNil(cultivar.name, "Cultivar name should not be nil")
            XCTAssertFalse(cultivar.name?.isEmpty ?? true, "Cultivar name should not be empty")
        }
    }
    
    func testGrowCultivarRelationship() throws {
        // Given: Seeded cultivars and a new grow
        CultivarSeeder.seedCultivars(context: mockContext)
        let cultivarRequest: NSFetchRequest<Cultivar> = Cultivar.fetchRequest()
        let cultivars = try mockContext.fetch(cultivarRequest)
        let testCultivar = cultivars.first!
        
        let grow = Grow(context: mockContext)
        grow.title = "Test Grow"
        grow.cultivar = testCultivar
        grow.timestamp = Date()
        
        try mockContext.save()
        
        // When: Fetching grows
        let growRequest: NSFetchRequest<Grow> = Grow.fetchRequest()
        let grows = try mockContext.fetch(growRequest)
        let savedGrow = grows.first!
        
        // Then: Relationship should be maintained
        XCTAssertEqual(savedGrow.cultivar, testCultivar, "Grow should maintain cultivar relationship")
        XCTAssertTrue(testCultivar.grows?.contains(savedGrow) ?? false, "Cultivar should have inverse relationship")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            CultivarSeeder.seedCultivars(context: mockContext)
        }
    }

}
