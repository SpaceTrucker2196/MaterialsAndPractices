//
//  InfrastructureCatalogSeeder.swift
//  MaterialsAndPractices
//
//  Provides infrastructure catalog seeding functionality with common farm equipment,
//  buildings, and systems. Includes maintenance procedures, safety training,
//  and inspection protocols for comprehensive farm infrastructure management.
//
//  Created by GitHub Copilot on 12/19/24.
//

import Foundation
import CoreData

/// Infrastructure catalog seeder for common farm infrastructure items
/// Provides comprehensive database of equipment, buildings, and systems with maintenance guidance
class InfrastructureCatalogSeeder {
    
    // MARK: - Seeder Main Function
    
    /// Seeds the infrastructure catalog with common farm infrastructure items
    /// - Parameter context: Core Data managed object context
    static func seedInfrastructureCatalog(context: NSManagedObjectContext) {
        
        // Check if catalog is already seeded
        let request: NSFetchRequest<InfrastructureCatalog> = InfrastructureCatalog.fetchRequest()
        
        do {
            let existingItems = try context.fetch(request)
            if !existingItems.isEmpty {
                print("Infrastructure catalog already seeded")
                return
            }
        } catch {
            print("Error checking existing infrastructure catalog: \(error)")
            return
        }
        
        // Seed all infrastructure categories
        seedTractorsAndMachinery(context: context)
        seedTransportationEquipment(context: context)
        seedBuildingsAndStructures(context: context)
        seedIrrigationSystems(context: context)
        seedStorageAndHandling(context: context)
        seedHandToolsAndEquipment(context: context)
        
        // Save context
        do {
            try context.save()
            print("Infrastructure catalog seeded successfully")
        } catch {
            print("Error saving infrastructure catalog: \(error)")
        }
    }
    
    // MARK: - Tractors and Machinery
    
    private static func seedTractorsAndMachinery(context: NSManagedObjectContext) {
        
        createInfrastructureItem(
            context: context,
            name: "Tractor",
            type: "tractor",
            category: "Machinery",
            maintenanceProcedures: """
            Daily Checks:
            • Check engine oil level and condition
            • Inspect hydraulic fluid levels
            • Check tire pressure and condition
            • Test lights and safety equipment
            
            Weekly Maintenance:
            • Grease all fittings per manual
            • Check air filter condition
            • Inspect belts for wear and proper tension
            • Clean radiator and cooling system
            
            Monthly Service:
            • Change engine oil and filter (per hours)
            • Service transmission and hydraulic filters
            • Check battery condition and connections
            • Inspect PTO shaft and guards
            
            Seasonal Preparation:
            • Full safety inspection
            • Calibrate implements
            • Service cooling system
            • Check exhaust system
            """,
            safetyTraining: """
            Tractor Safety Training Required:
            
            Pre-Operation:
            • Circle check for loose parts, leaks, or damage
            • Adjust seat and mirrors
            • Test brakes and steering
            • Ensure ROPS/FOPS protection is in place
            
            Operating Safety:
            • Always wear seatbelt with ROPS
            • Maintain safe speeds for conditions
            • Use proper ballast and tire pressure
            • Keep bystanders clear of work area
            
            PTO Safety:
            • Ensure all guards are in place
            • Never reach over rotating PTO
            • Shut off PTO before dismounting
            • Keep clothing away from rotating parts
            
            Hydraulic Safety:
            • Never search for leaks with hands
            • Use cardboard to locate hydraulic leaks
            • Relieve pressure before servicing
            • Wear safety glasses when working on hydraulics
            """,
            rodentInspectionProcedure: """
            Monthly Rodent Inspection for Tractors:
            
            Interior Inspection:
            • Check cab for droppings or nesting material
            • Inspect seat cushions for damage
            • Look for chewed wiring in dashboard
            • Check air filter housing for debris
            
            Engine Compartment:
            • Inspect wiring harnesses for damage
            • Check air intake for nesting material
            • Look for droppings on engine surfaces
            • Inspect rubber components for chewing
            
            Prevention Measures:
            • Store with windows closed
            • Remove food sources from cab
            • Use rodent deterrent sachets
            • Maintain clean storage area
            
            Action if Evidence Found:
            • Document location and extent of damage
            • Clean affected areas with disinfectant
            • Repair or replace damaged components
            • Implement additional prevention measures
            """
        )
        
        createInfrastructureItem(
            context: context,
            name: "Mower",
            type: "mower",
            category: "Machinery",
            maintenanceProcedures: """
            Pre-Season Setup:
            • Sharpen or replace cutting blades
            • Check gear box oil level
            • Grease all fittings
            • Inspect guards and safety devices
            
            Daily Checks:
            • Inspect cutting blades for damage
            • Check for loose bolts or hardware
            • Look for signs of excessive wear
            • Ensure guards are properly secured
            
            Weekly Maintenance:
            • Clean cutting deck of debris
            • Check belt tension and condition
            • Inspect PTO driveline
            • Grease slip clutch if equipped
            
            End of Season:
            • Clean and inspect thoroughly
            • Touch up paint to prevent rust
            • Store in dry location
            • Apply rust preventative to exposed metal
            """,
            safetyTraining: """
            Mower Safety Guidelines:
            
            Before Operating:
            • Walk field to remove debris and obstacles
            • Check that all guards are in place
            • Ensure slip clutch is properly adjusted
            • Verify proper hitch pin installation
            
            During Operation:
            • Maintain safe ground speed
            • Avoid steep slopes and wet conditions
            • Keep bystanders at least 300 feet away
            • Stop immediately if unusual vibration occurs
            
            When Servicing:
            • Shut off PTO and engine
            • Wait for all motion to stop
            • Use lock-out procedures
            • Never work under raised equipment without proper support
            """,
            rodentInspectionProcedure: """
            Not applicable for field mowers - open design limits rodent habitation.
            Focus on storage area cleanliness and proper equipment positioning.
            """
        )
    }
    
    // MARK: - Transportation Equipment
    
    private static func seedTransportationEquipment(context: NSManagedObjectContext) {
        
        createInfrastructureItem(
            context: context,
            name: "Farm Truck",
            type: "truck",
            category: "Transportation",
            maintenanceProcedures: """
            Daily Pre-Trip Inspection:
            • Check engine oil, coolant, and brake fluid
            • Inspect tires for proper inflation and damage
            • Test lights and turn signals
            • Check mirror adjustment and cleanliness
            
            Weekly Maintenance:
            • Check tire tread depth and wear patterns
            • Inspect belts and hoses
            • Clean air filter if dusty conditions
            • Check battery terminals and charging system
            
            Monthly Service:
            • Change oil and filter per schedule
            • Inspect brakes and brake lines
            • Check steering and suspension components
            • Service air filter and cabin filter
            
            DOT Compliance:
            • Annual DOT inspection if required
            • Maintain driver logs if applicable
            • Keep maintenance records current
            • Ensure proper licensing and insurance
            """,
            safetyTraining: """
            Farm Truck Safety Training:
            
            Pre-Trip Safety:
            • Complete thorough vehicle inspection
            • Adjust mirrors and seat position
            • Ensure load is properly secured
            • Check that tailgate is functional
            
            Loading Safety:
            • Never exceed weight capacity
            • Distribute load evenly
            • Secure all cargo with appropriate restraints
            • Ensure rear visibility is not blocked
            
            Operating Safety:
            • Maintain safe following distance
            • Reduce speed when loaded
            • Use turn signals early and clearly
            • Be aware of height and width restrictions
            
            Hazardous Materials:
            • Know regulations for agricultural chemicals
            • Use proper labeling and documentation
            • Carry appropriate safety equipment
            • Understand spill response procedures
            """,
            rodentInspectionProcedure: """
            Monthly Vehicle Rodent Inspection:
            
            Cab Interior:
            • Check for droppings under seats
            • Inspect upholstery for damage
            • Look for nesting material in storage areas
            • Check air vents for blockages
            
            Engine Compartment:
            • Inspect wiring for chew damage
            • Check air filter housing
            • Look for nests in crevices
            • Examine rubber components
            
            Prevention:
            • Keep cab clean and food-free
            • Park away from grain storage when possible
            • Use rodent deterrent products
            • Seal any entry points found
            """
        )
        
        createInfrastructureItem(
            context: context,
            name: "Trailer/Wagon",
            type: "trailer",
            category: "Transportation",
            maintenanceProcedures: """
            Pre-Season Inspection:
            • Check tire condition and inflation
            • Inspect wheel bearings and repack if needed
            • Test brakes and brake controller
            • Examine hitch and safety chains
            
            Regular Maintenance:
            • Grease wheel bearings annually
            • Check brake adjustment and fluid
            • Inspect frame for cracks or damage
            • Maintain proper tire pressure
            
            Electrical System:
            • Test all lights and turn signals
            • Check wiring connections for corrosion
            • Ensure breakaway system functions
            • Verify brake controller operation
            
            Storage Preparation:
            • Clean thoroughly before storage
            • Block up to relieve tire pressure
            • Disconnect battery if equipped
            • Cover to protect from weather
            """,
            safetyTraining: """
            Trailer Safety Protocol:
            
            Hitching Procedures:
            • Use proper hitch capacity for load
            • Secure safety chains in X pattern
            • Connect breakaway cable properly
            • Test electrical connections
            
            Loading Safety:
            • Load heavier items forward
            • Secure all cargo properly
            • Check that trailer is level
            • Verify adequate tongue weight
            
            Towing Safety:
            • Allow extra stopping distance
            • Take turns wider and slower
            • Check mirrors frequently
            • Be aware of trailer swing
            """,
            rodentInspectionProcedure: """
            Trailer Rodent Prevention:
            
            Since trailers are typically open, focus on:
            • Removing any stored materials that attract rodents
            • Checking for nests in frame members
            • Ensuring storage area is clean
            • Positioning away from grain storage
            """
        )
    }
    
    // MARK: - Buildings and Structures
    
    private static func seedBuildingsAndStructures(context: NSManagedObjectContext) {
        
        createInfrastructureItem(
            context: context,
            name: "Barn",
            type: "barn",
            category: "Buildings",
            maintenanceProcedures: """
            Seasonal Roof Inspection:
            • Check for loose or missing shingles/metal
            • Inspect gutters and downspouts
            • Clear debris from roof valleys
            • Examine flashing around penetrations
            
            Structural Maintenance:
            • Inspect foundation for cracks or settling
            • Check framing for damage or pest activity
            • Examine siding for loose boards or holes
            • Maintain proper ventilation systems
            
            Electrical Systems:
            • Test all lighting and outlets
            • Inspect wiring for damage or overheating
            • Ensure proper grounding
            • Check panel box for proper operation
            
            Doors and Hardware:
            • Lubricate hinges and track systems
            • Check door alignment and operation
            • Inspect locks and latching mechanisms
            • Maintain weather sealing
            """,
            safetyTraining: """
            Barn Safety Guidelines:
            
            Electrical Safety:
            • Use GFCI outlets in wet locations
            • Keep electrical panels accessible
            • Report any damaged wiring immediately
            • Use proper extension cords for outdoor use
            
            Fire Prevention:
            • Maintain clear exit routes
            • Store flammable materials properly
            • Keep fire extinguishers charged and accessible
            • Prohibit smoking in barn areas
            
            Structural Safety:
            • Report any sagging or damage immediately
            • Use proper ladders for high work
            • Ensure adequate lighting for all work areas
            • Keep walkways clear of obstacles
            
            Ventilation:
            • Ensure proper air circulation
            • Monitor for harmful gas buildup
            • Maintain ventilation system operation
            • Be aware of confined space hazards
            """,
            rodentInspectionProcedure: """
            Monthly Barn Rodent Inspection:
            
            Interior Inspection:
            • Check corners and storage areas for droppings
            • Look for gnaw marks on wood surfaces
            • Inspect stored feed for contamination
            • Check for nests in hay or straw storage
            
            Exterior Inspection:
            • Look for entry points around foundation
            • Check for gaps around doors and windows
            • Inspect areas where utilities enter building
            • Examine drainage areas for burrows
            
            Control Measures:
            • Seal cracks and holes with steel wool and caulk
            • Remove food sources and nesting materials
            • Set traps in areas of activity
            • Maintain clean storage practices
            
            Prevention:
            • Store feed in sealed containers
            • Keep barn clean and organized
            • Remove spilled grain promptly
            • Maintain proper sanitation practices
            """
        )
        
        createInfrastructureItem(
            context: context,
            name: "Greenhouse",
            type: "greenhouse",
            category: "Buildings",
            maintenanceProcedures: """
            Daily Monitoring:
            • Check temperature and humidity levels
            • Inspect ventilation system operation
            • Monitor irrigation system function
            • Observe plants for pest or disease issues
            
            Weekly Maintenance:
            • Clean glass or plastic glazing
            • Check heating system operation
            • Inspect structural components
            • Maintain cooling and ventilation systems
            
            Monthly Tasks:
            • Service heating and cooling equipment
            • Calibrate environmental controls
            • Inspect electrical systems
            • Check foundation and drainage
            
            Seasonal Preparation:
            • Deep clean all surfaces
            • Service heating system before winter
            • Check cooling system before summer
            • Inspect and repair structural damage
            """,
            safetyTraining: """
            Greenhouse Safety Protocol:
            
            Chemical Safety:
            • Use proper PPE when applying pesticides
            • Ensure adequate ventilation during treatments
            • Store chemicals according to label instructions
            • Maintain chemical inventory and safety data sheets
            
            Electrical Safety:
            • Use GFCI protection for all outlets
            • Keep electrical components dry
            • Inspect cords for damage regularly
            • Use only greenhouse-rated electrical equipment
            
            Environmental Safety:
            • Monitor for dangerous gas buildup
            • Ensure emergency ventilation capability
            • Maintain first aid supplies
            • Know heat stress prevention measures
            
            Structural Safety:
            • Be aware of glass breakage hazards
            • Use proper ladders for high work
            • Report structural damage immediately
            • Maintain clear emergency exits
            """,
            rodentInspectionProcedure: """
            Greenhouse Rodent Management:
            
            Monthly Inspection:
            • Check for droppings near plant benches
            • Look for damage to plant materials
            • Inspect storage areas for contamination
            • Check entry points around doors and vents
            
            Prevention Strategies:
            • Keep greenhouse clean and organized
            • Remove plant debris promptly
            • Store potting materials in sealed containers
            • Maintain proper sanitation practices
            
            Control Methods:
            • Use snap traps in affected areas
            • Seal entry points with appropriate materials
            • Consider companion planting with deterrent plants
            • Monitor and document rodent activity
            """
        )
    }
    
    // MARK: - Helper Function
    
    /// Creates an infrastructure catalog item with all provided parameters
    private static func createInfrastructureItem(
        context: NSManagedObjectContext,
        name: String,
        type: String,
        category: String,
        maintenanceProcedures: String,
        safetyTraining: String,
        rodentInspectionProcedure: String
    ) {
        let item = InfrastructureCatalog(context: context)
        item.id = UUID()
        item.name = name
        item.type = type
        item.category = category
        item.maintenanceProcedures = maintenanceProcedures
        item.safetyTraining = safetyTraining
        item.rodentInspectionProcedure = rodentInspectionProcedure
    }
    
    // MARK: - Additional Infrastructure Categories (Abbreviated for space)
    
    private static func seedIrrigationSystems(context: NSManagedObjectContext) {
        createInfrastructureItem(
            context: context,
            name: "Water Pump",
            type: "pump",
            category: "Irrigation",
            maintenanceProcedures: "Regular inspection of seals, impellers, and electrical connections. Monthly testing of pressure and flow rates.",
            safetyTraining: "Electrical safety around water, proper lockout/tagout procedures, and understanding pump operation principles.",
            rodentInspectionProcedure: "Check electrical panels and control boxes for rodent damage to wiring and insulation."
        )
    }
    
    private static func seedStorageAndHandling(context: NSManagedObjectContext) {
        createInfrastructureItem(
            context: context,
            name: "Grain Bin",
            type: "storage",
            category: "Storage",
            maintenanceProcedures: "Inspect for structural integrity, check aeration systems, and maintain proper moisture control.",
            safetyTraining: "Confined space entry procedures, grain entrapment awareness, and proper use of safety equipment.",
            rodentInspectionProcedure: "Critical inspection for entry points and contamination. Implement comprehensive rodent control program."
        )
    }
    
    private static func seedHandToolsAndEquipment(context: NSManagedObjectContext) {
        createInfrastructureItem(
            context: context,
            name: "Hand Tools",
            type: "tools",
            category: "Equipment",
            maintenanceProcedures: "Regular cleaning, sharpening, and proper storage. Replace damaged handles and worn cutting edges.",
            safetyTraining: "Proper tool selection for tasks, maintenance procedures, and safe handling techniques.",
            rodentInspectionProcedure: "Check storage areas for contamination and damage to wooden handles or fabric cases."
        )
    }
}