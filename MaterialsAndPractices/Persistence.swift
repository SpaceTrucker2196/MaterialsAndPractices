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
        for itemNum in 0..<10 {
            let newGrow = Grow(context: viewContext)
            newGrow.timestamp = Date()
            
            switch itemNum {
            case 0:
                newGrow.title = "Back 40"
                newGrow.cultivar = "Corn"
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
            case 1:
                newGrow.title = "Turkey Foot"
                newGrow.cultivar = "Corn"
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
            case 2:
                newGrow.title = "Radio Hill"
                newGrow.cultivar = "Wheat"
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
            case 3:
                newGrow.cultivar = "Turnip"
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
            case 4:
                newGrow.title = "Cabin Field"
                newGrow.cultivar = "Raddish"
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
            case 5:
                newGrow.title = "Garden"
                newGrow.cultivar = "Carrot"
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
            case 6:
                newGrow.title = "Block 10"
                newGrow.cultivar = "Onion"
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
            case 7:
                newGrow.title = "Block 20"
                newGrow.cultivar = "Onion"
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
            case 8:
                newGrow.title = "Block 40"
                newGrow.cultivar = "Onion"
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
            case 9:
                newGrow.title = "Block 50"
                newGrow.cultivar = "Onion"
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
        })
    }
}
