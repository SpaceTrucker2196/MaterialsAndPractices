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
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Seed cultivars after stores are loaded
            CultivarSeeder.seedCultivars(context: self.container.viewContext)
        })
    }
}
