//
//  CultivarSeeder.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import CoreData
import Foundation

struct CultivarSeeder {
    
    static func seedCultivars(context: NSManagedObjectContext) {
        // Check if cultivars are already seeded
        let request: NSFetchRequest<Cultivar> = Cultivar.fetchRequest()
        
        do {
            let existingCultivars = try context.fetch(request)
            if !existingCultivars.isEmpty {
                // Already seeded
                return
            }
        } catch {
            print("Error checking existing cultivars: \(error)")
            return
        }
        
        // Seed USDA vegetable cultivar data
        let cultivarData = getUSDAVegetableCultivars()
        
        for cultivarInfo in cultivarData {
            let cultivar = Cultivar(context: context)
            cultivar.name = cultivarInfo.name
            cultivar.family = cultivarInfo.family
            cultivar.season = cultivarInfo.season
            cultivar.hardyZone = cultivarInfo.hardyZone
            cultivar.plantingWeek = cultivarInfo.plantingWeek
        }
        
        do {
            try context.save()
            print("Successfully seeded \(cultivarData.count) cultivars")
        } catch {
            print("Error seeding cultivars: \(error)")
        }
    }
    
    private static func getUSDAVegetableCultivars() -> [(name: String, family: String, season: String, hardyZone: String, plantingWeek: String)] {
        return [
            // AMARANTH
            ("All Red Leaf", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Burgundy", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Callaloo Amaranth", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Chinese Giant Orange", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Chinese Multicolor Spinach", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Golden Giant", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Green Callaloo", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Green Leaf", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Green Leaf Callaloo", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Green Tails Amaranth", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Hopi Red Dye", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Love Lies Bleeding", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Miriah Leaf", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Molten Fire", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Montana Popping", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Opopeo Amaranth", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Polish", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Red Beauty", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Red Garnet", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Red Leaf", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Red Leaf Amaranth", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Red Spike", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Rodale Red Leaf Grain", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("Virdis Amaranth", "Amaranthaceae", "Summer", "3-10", "12-20"),
            ("White Leaf", "Amaranthaceae", "Summer", "3-10", "12-20"),
            
            // ASPARAGUS
            ("DePaoli", "Asparagaceae", "Spring", "3-8", "8-12"),
            ("Early California", "Asparagaceae", "Spring", "3-8", "8-12"),
            ("Guelph Eclipse", "Asparagaceae", "Spring", "3-8", "8-12"),
            ("Guelph Equinox", "Asparagaceae", "Spring", "3-8", "8-12"),
            ("Guelph Millennium", "Asparagaceae", "Spring", "3-8", "8-12"),
            ("Spartacus", "Asparagaceae", "Spring", "3-8", "8-12"),
            
            // BEAN-DRY
            ("0863 PER", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Adams", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Alpena", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Aries", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Aspen", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Avalanche", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Baja", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Bandit", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Bella", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Bellagio", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Beryl R", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Big Red", "Fabaceae", "Summer", "3-9", "16-20"),
            ("BigHorn", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Black Bear", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Black Cat", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Black Tails", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Blackhawk", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Blackjack", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Blizzard", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Canario 707", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Capri", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Cayenne", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Centennial", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Chaparral", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Charro", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Cisco", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Clouseau", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Coho", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Condor", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Cowboy", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Coyne", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Cran 09", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Croissant", "Fabaceae", "Summer", "3-9", "16-20"),
            
            // BEAN-GARDEN
            ("Blue Lake", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Cherokee Trail", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Provider", "Fabaceae", "Summer", "3-9", "16-20"),
            ("Top Crop", "Fabaceae", "Summer", "3-9", "16-20"),
            
            // BEAN-LIMA
            ("Fordhook 242", "Fabaceae", "Summer", "4-9", "16-20"),
            ("Henderson Bush", "Fabaceae", "Summer", "4-9", "16-20"),
            ("King of the Garden", "Fabaceae", "Summer", "4-9", "16-20"),
            
            // BEAN-MUNG
            ("Berken", "Fabaceae", "Summer", "5-10", "16-20"),
            ("Oklahoma 1", "Fabaceae", "Summer", "5-10", "16-20"),
            
            // BEET
            ("Chioggia", "Amaranthaceae", "Cool Season", "2-9", "8-16"),
            ("Detroit Dark Red", "Amaranthaceae", "Cool Season", "2-9", "8-16"),
            ("Early Wonder", "Amaranthaceae", "Cool Season", "2-9", "8-16"),
            ("Golden", "Amaranthaceae", "Cool Season", "2-9", "8-16"),
            ("Red Ace", "Amaranthaceae", "Cool Season", "2-9", "8-16"),
            
            // BRUSSELS SPROUT
            ("Jade Cross", "Brassicaceae", "Cool Season", "3-8", "12-16"),
            ("Long Island Improved", "Brassicaceae", "Cool Season", "3-8", "12-16"),
            ("Prince Marvel", "Brassicaceae", "Cool Season", "3-8", "12-16"),
            
            // CABBAGE
            ("Copenhagen Market", "Brassicaceae", "Cool Season", "2-9", "8-12"),
            ("Early Jersey Wakefield", "Brassicaceae", "Cool Season", "2-9", "8-12"),
            ("Golden Acre", "Brassicaceae", "Cool Season", "2-9", "8-12"),
            ("Late Flat Dutch", "Brassicaceae", "Cool Season", "2-9", "8-12"),
            ("Red Acre", "Brassicaceae", "Cool Season", "2-9", "8-12"),
            
            // CABBAGE-CHINESE
            ("Bok Choy", "Brassicaceae", "Cool Season", "3-9", "8-16"),
            ("Michihili", "Brassicaceae", "Cool Season", "3-9", "8-16"),
            ("Napa", "Brassicaceae", "Cool Season", "3-9", "8-16"),
            ("Wong Bok", "Brassicaceae", "Cool Season", "3-9", "8-16"),
            
            // CARROT
            ("Chantenay", "Apiaceae", "Cool Season", "3-9", "8-20"),
            ("Danvers", "Apiaceae", "Cool Season", "3-9", "8-20"),
            ("Imperator", "Apiaceae", "Cool Season", "3-9", "8-20"),
            ("Nantes", "Apiaceae", "Cool Season", "3-9", "8-20"),
            ("Paris Market", "Apiaceae", "Cool Season", "3-9", "8-20"),
            
            // CELERY
            ("Golden Self-Blanching", "Apiaceae", "Cool Season", "3-8", "8-12"),
            ("Pascal", "Apiaceae", "Cool Season", "3-8", "8-12"),
            ("Utah 52-70", "Apiaceae", "Cool Season", "3-8", "8-12"),
            
            // CHICKPEA
            ("Desi", "Fabaceae", "Cool Season", "3-9", "8-12"),
            ("Kabuli", "Fabaceae", "Cool Season", "3-9", "8-12"),
            
            // COLLARD
            ("Champion", "Brassicaceae", "Cool Season", "3-9", "8-20"),
            ("Georgia", "Brassicaceae", "Cool Season", "3-9", "8-20"),
            ("Vates", "Brassicaceae", "Cool Season", "3-9", "8-20"),
            
            // CUCUMBER
            ("Boston Pickling", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Burpee Hybrid", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Marketmore", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Straight Eight", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            
            // EGGPLANT
            ("Black Beauty", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Dusky", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Japanese Long", "Solanaceae", "Summer", "5-10", "16-20"),
            
            // LEEK
            ("American Flag", "Amaryllidaceae", "Cool Season", "3-8", "8-12"),
            ("King Richard", "Amaryllidaceae", "Cool Season", "3-8", "8-12"),
            
            // LETTUCE
            ("Black Seeded Simpson", "Asteraceae", "Cool Season", "2-9", "8-20"),
            ("Buttercrunch", "Asteraceae", "Cool Season", "2-9", "8-20"),
            ("Great Lakes", "Asteraceae", "Cool Season", "2-9", "8-20"),
            ("Iceberg", "Asteraceae", "Cool Season", "2-9", "8-20"),
            ("Oak Leaf", "Asteraceae", "Cool Season", "2-9", "8-20"),
            ("Red Sails", "Asteraceae", "Cool Season", "2-9", "8-20"),
            ("Romaine", "Asteraceae", "Cool Season", "2-9", "8-20"),
            
            // MELON
            ("Cantaloupe", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Honeydew", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Watermelon", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            
            // ONION
            ("Red Wethersfield", "Amaryllidaceae", "Cool Season", "3-9", "8-12"),
            ("Sweet Spanish", "Amaryllidaceae", "Cool Season", "3-9", "8-12"),
            ("White Sweet Spanish", "Amaryllidaceae", "Cool Season", "3-9", "8-12"),
            ("Yellow Globe", "Amaryllidaceae", "Cool Season", "3-9", "8-12"),
            
            // PARSNIP
            ("Hollow Crown", "Apiaceae", "Cool Season", "3-8", "8-12"),
            
            // PEA-GREEN
            ("Alaska", "Fabaceae", "Cool Season", "2-8", "4-8"),
            ("Green Arrow", "Fabaceae", "Cool Season", "2-8", "4-8"),
            ("Little Marvel", "Fabaceae", "Cool Season", "2-8", "4-8"),
            ("Sugar Snap", "Fabaceae", "Cool Season", "2-8", "4-8"),
            ("Wando", "Fabaceae", "Cool Season", "2-8", "4-8"),
            
            // POTATO
            ("Katahdin", "Solanaceae", "Cool Season", "3-8", "8-12"),
            ("Kennebec", "Solanaceae", "Cool Season", "3-8", "8-12"),
            ("Red Pontiac", "Solanaceae", "Cool Season", "3-8", "8-12"),
            ("Russet Burbank", "Solanaceae", "Cool Season", "3-8", "8-12"),
            ("Yukon Gold", "Solanaceae", "Cool Season", "3-8", "8-12"),
            
            // PUMPKIN
            ("Big Max", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Connecticut Field", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Jack O'Lantern", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Small Sugar", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            
            // RUTABAGA
            ("American Purple Top", "Brassicaceae", "Cool Season", "2-8", "12-16"),
            
            // SHALLOT
            ("French Red", "Amaryllidaceae", "Cool Season", "3-8", "8-12"),
            
            // SOUTHERN PEA (COWPEA)
            ("Black-Eyed Pea", "Fabaceae", "Summer", "5-10", "16-20"),
            ("Crowder", "Fabaceae", "Summer", "5-10", "16-20"),
            ("Pink Eye Purple Hull", "Fabaceae", "Summer", "5-10", "16-20"),
            
            // SOYBEAN
            ("Envy", "Fabaceae", "Summer", "4-9", "16-20"),
            ("Prize", "Fabaceae", "Summer", "4-9", "16-20"),
            
            // SPINACH
            ("Bloomsdale", "Amaranthaceae", "Cool Season", "2-9", "4-16"),
            ("Melody", "Amaranthaceae", "Cool Season", "2-9", "4-16"),
            ("Space", "Amaranthaceae", "Cool Season", "2-9", "4-16"),
            ("Tyee", "Amaranthaceae", "Cool Season", "2-9", "4-16"),
            
            // SQUASH
            ("Acorn", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Butternut", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Hubbard", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Patty Pan", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Yellow Crookneck", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            ("Zucchini", "Cucurbitaceae", "Summer", "4-9", "16-20"),
            
            // SWEET CORN
            ("Golden Bantam", "Poaceae", "Summer", "4-9", "16-20"),
            ("Honey and Cream", "Poaceae", "Summer", "4-9", "16-20"),
            ("Silver Queen", "Poaceae", "Summer", "4-9", "16-20"),
            ("Stowell's Evergreen", "Poaceae", "Summer", "4-9", "16-20"),
            
            // SWEET POTATO
            ("Beauregard", "Convolvulaceae", "Summer", "5-10", "16-20"),
            ("Centennial", "Convolvulaceae", "Summer", "5-10", "16-20"),
            ("Georgia Jet", "Convolvulaceae", "Summer", "5-10", "16-20"),
            
            // SWISS CHARD
            ("Bright Lights", "Amaranthaceae", "Cool Season", "3-9", "8-20"),
            ("Fordhook Giant", "Amaranthaceae", "Cool Season", "3-9", "8-20"),
            ("Ruby Red", "Amaranthaceae", "Cool Season", "3-9", "8-20"),
            
            // TOMATO
            ("Better Boy", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Big Beef", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Celebrity", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Cherokee Purple", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Early Girl", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Heirloom Brandywine", "Solanaceae", "Summer", "5-10", "16-20"),
            ("Roma", "Solanaceae", "Summer", "5-10", "16-20"),
            
            // TURNIP
            ("Purple Top White Globe", "Brassicaceae", "Cool Season", "2-9", "8-16"),
            ("Tokyo Cross", "Brassicaceae", "Cool Season", "2-9", "8-16"),
        ]
    }
}