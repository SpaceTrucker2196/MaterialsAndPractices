//
//  Persistence.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Seed cultivars first
        CultivarSeeder.seedCultivars(context: viewContext)
        
        // Fetch some cultivars to use in preview data
        let cultivarRequest: NSFetchRequest<Cultivar> = Cultivar.fetchRequest()
        let cultivars = try? viewContext.fetch(cultivarRequest)
        
        for itemNum in 0..<10 {
            let newGrow = Grow(context: viewContext)
            let newMaterial = Amendment(context: viewContext)
            newGrow.timestamp = Date()
            
            switch itemNum {
            case 0:
                newGrow.title = "Back 40"
                if let cornCultivar = cultivars?.first(where: { $0.name == "Golden Bantam" }) {
                    newGrow.cultivar = cornCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Azomite"
            case 1:
                newGrow.title = "Turkey Foot"
                if let cornCultivar = cultivars?.first(where: { $0.name == "Silver Queen" }) {
                    newGrow.cultivar = cornCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Bone Meal"
            case 2:
                newGrow.title = "Radio Hill"
                if let tomatoCultivar = cultivars?.first(where: { $0.name == "Early Girl" }) {
                    newGrow.cultivar = tomatoCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Fish Meal"
            case 3:
                if let turnipCultivar = cultivars?.first(where: { $0.name == "Purple Top White Globe" }) {
                    newGrow.cultivar = turnipCultivar
                }
                newGrow.title = "Pines"
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Compost"
                
            case 4:
                newGrow.title = "Cabin Field"
                if let beetCultivar = cultivars?.first(where: { $0.name == "Detroit Dark Red" }) {
                    newGrow.cultivar = beetCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Tiger Bloom"
            case 5:
                newGrow.title = "Garden"
                if let carrotCultivar = cultivars?.first(where: { $0.name == "Nantes" }) {
                    newGrow.cultivar = carrotCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "MycoGro"
            case 6:
                newGrow.title = "Block 10"
                if let onionCultivar = cultivars?.first(where: { $0.name == "Yellow Globe" }) {
                    newGrow.cultivar = onionCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Oyster Shells"
                
            case 7:
                newGrow.title = "Block 20"
                if let onionCultivar = cultivars?.first(where: { $0.name == "Red Wethersfield" }) {
                    newGrow.cultivar = onionCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Manure"
            case 8:
                newGrow.title = "Block 40"
                if let onionCultivar = cultivars?.first(where: { $0.name == "Sweet Spanish" }) {
                    newGrow.cultivar = onionCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                
                newMaterial.name = "Gypsum"
            case 9:
                newGrow.title = "Block 50"
                if let onionCultivar = cultivars?.first(where: { $0.name == "White Sweet Spanish" }) {
                    newGrow.cultivar = onionCultivar
                }
                newGrow.address = "N20545 County Rd DD"
                newGrow.city = "Ettrick"
                newGrow.county = "Trempealeau"
                newGrow.drivingDirections = "2nd Right on the Left"
                newGrow.growType = "Field"
                newGrow.locationName = "Kunzelman Farm"
                newGrow.manager = "Brady"
                newGrow.managerPhone = "555-111-2233"
                newGrow.notes = "a lot of clay in the soil"
                newGrow.propertyOwner = "Kunzelman"
                newGrow.size = 10.0
                newGrow.state = "Wi"
                newGrow.zip = "54627"
                newMaterial.name = "Miracle Grow"
                
            default:
                newGrow.title = "unknown"
            }
            
        }
        
        // Add sample farm management data for preview
        addSampleFarmData(context: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "MaterialsAndPractices")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Store the context in a local variable before the escaping closure
        let viewContext = container.viewContext
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Use the locally captured viewContext instead of self.container.viewContext
            CultivarSeeder.seedCultivars(context: viewContext)
        })
    }
}

// MARK: - Sample Farm Data

/// Adds sample farm management data for preview and testing
private func addSampleFarmData(context: NSManagedObjectContext) {
    // Create sample owner
    let owner = Owner(context: context)
    owner.id = UUID()
    owner.name = "John Smith"
    owner.email = "john.smith@example.com"
    owner.phone = "555-123-4567"
    owner.notes = "Local farm owner"
    
    // Create sample farmer
    let farmer = Farmer(context: context)
    farmer.id = UUID()
    farmer.name = "Brady Johnson"
    farmer.email = "brady@farmcorp.com"
    farmer.phone = "555-987-6543"
    farmer.orgName = "Johnson Farming Corp"
    farmer.notes = "Experienced organic farmer"
    
    // Create sample properties
    let property1 = Property(context: context)
    property1.id = UUID()
    property1.displayName = "North Field"
    property1.county = "Trempealeau"
    property1.state = "Wisconsin"
    property1.totalAcres = 120.5
    property1.tillableAcres = 100.0
    property1.pastureAcres = 15.0
    property1.woodlandAcres = 5.5
    property1.wetlandAcres = 0.0
    property1.hasIrrigation = true
    property1.notes = "Prime farmland with excellent soil"
    property1.owner = owner
    
    let property2 = Property(context: context)
    property2.id = UUID()
    property2.displayName = "South Pasture"
    property2.county = "Trempealeau"
    property2.state = "Wisconsin"
    property2.totalAcres = 80.0
    property2.tillableAcres = 20.0
    property2.pastureAcres = 55.0
    property2.woodlandAcres = 5.0
    property2.wetlandAcres = 0.0
    property2.hasIrrigation = false
    property2.notes = "Primarily pasture land"
    property2.owner = owner
    
    // Create sample fields
    let field1 = Field(context: context)
    field1.id = UUID()
    field1.name = "Field A"
    field1.acres = 40.0
    field1.hasDrainTile = true
    field1.notes = "High productivity field"
    field1.property = property1
    
    let field2 = Field(context: context)
    field2.id = UUID()
    field2.name = "Field B"
    field2.acres = 35.0
    field2.hasDrainTile = false
    field2.notes = "Organic field"
    field2.property = property1
    
    // Create sample lease
    let lease = Lease(context: context)
    lease.id = UUID()
    lease.startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
    lease.endDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())
    lease.leaseType = "cash"
    lease.rentAmount = NSDecimalNumber(value: 250.00)
    lease.rentFrequency = "annual"
    lease.status = "active"
    lease.notes = "Standard cash lease agreement"
    lease.owner = owner
    lease.farmer = farmer
    lease.properties = NSSet(array: [property1])
    
    // Create sample infrastructure
    let infrastructure = Infrastructure(context: context)
    infrastructure.id = UUID()
    infrastructure.type = "fence"
    infrastructure.status = "good"
    infrastructure.installDate = Calendar.current.date(byAdding: .year, value: -5, to: Date())
    infrastructure.notes = "Perimeter fencing"
    infrastructure.property = property1
    
    // Create sample workers
    let worker1 = Worker(context: context)
    worker1.id = UUID()
    worker1.name = "John Smith"
    worker1.position = "Farm Supervisor"
    worker1.email = "john@farm.com"
    worker1.phone = "555-123-4567"
    worker1.hireDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())
    worker1.isActive = true
    
    let worker2 = Worker(context: context)
    worker2.id = UUID()
    worker2.name = "Maria Garcia"
    worker2.position = "Field Worker"
    worker2.email = "maria@farm.com"
    worker2.phone = "555-234-5678"
    worker2.hireDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())
    worker2.isActive = true
    
    // Create sample time clock entry (worker1 clocked in)
    let timeClock = TimeClock(context: context)
    timeClock.id = UUID()
    timeClock.worker = worker1
    timeClock.date = Calendar.current.startOfDay(for: Date())
    timeClock.clockInTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
    timeClock.isActive = true
    let calendar = Calendar.current
    timeClock.year = Int16(calendar.component(.yearForWeekOfYear, from: Date()))
    timeClock.weekNumber = Int16(calendar.component(.weekOfYear, from: Date()))
    
    // Create sample health safety training
    let training = HealthSafetyTraining(context: context)
    training.id = UUID()
    training.trainingName = "Harvest Safety"
    training.trainingType = "Required"
    training.completedDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())
    training.expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
    training.farmer = farmer
    training.notes = "Annual harvest safety training completed"
    
    // Create sample well
    let well = Well(context: context)
    well.id = UUID()
    well.name = "North Well"
    well.wellType = "irrigation"
    well.status = "active"
    well.depth = 120.0
    well.drillDate = Calendar.current.date(byAdding: .year, value: -3, to: Date())
    well.property = property1
    well.field = field1
    well.notes = "Primary irrigation well"
}
