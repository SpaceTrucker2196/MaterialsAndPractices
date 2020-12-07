//
//  GrowDetailView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

struct GrowDetailViewModel  {
    var cultivar = "New Cultivar"
    var name = "My Grow"
    var plantedDate = Date()
    var harvestDate = Date()
    var daysTillHarvest = 90
    var locationName = "My Location"
    var materials : [Material] = []
    var practices : [Practice] = []
}

struct GrowDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var grow:GrowDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading){
                Text("Cultivar:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                    
                Text("\(grow.cultivar )")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .multilineTextAlignment(.leading)
                Text("Planted Date:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4.0)
                Text("\(grow.plantedDate.description)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                Text("Expected Harvest:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                Text("\(grow.harvestDate.description)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                Text("Remaining:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                Text("90 Days")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
            
            Text("Location:")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.leading)
                .padding(.top, 2.0)
            Text("\(grow.locationName)")
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                
            Text("Material Applications:")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.leading)
                .padding(.top)
            List {
                VStack{
                    Text("Material")
                }
                VStack{
                    Text("Material")
                }
                VStack{
                    Text("Material")
                }
            }
            
            Text("Practices:")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.leading)
                .padding(.top)
            List {
                Text("Till")
                Text("Cover")
                Text("Till")
            }
            Spacer()
        }.padding(.leading).navigationTitle("\(grow.name)")
    }
}

struct GrowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GrowDetailView(grow: GrowDetailViewModel()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
