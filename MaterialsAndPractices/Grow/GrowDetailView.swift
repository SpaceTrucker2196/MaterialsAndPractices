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
    var previewImage = Grow.Image(grow:Grow())
    init(grow:Grow) {
        cultivar = grow.cultivar ?? ""
        name = grow.title ?? ""
        plantedDate = grow.plantedDate ?? Date()
        harvestDate = grow.harvestDate ?? Date()
        locationName = grow.locationName ?? ""
        previewImage = Grow.Image(grow:grow)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct GrowDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var grow:GrowDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading){
                HStack {
                    grow.previewImage
                    VStack(alignment: .leading) {
                        Text("Cultivar:")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.green)
                            .multilineTextAlignment(.leading)
                        Text("\(grow.cultivar )")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Text("Planted Date:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4.0)
                Text("\(grow.plantedDate, formatter: itemFormatter)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                Text("Expected Harvest:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                Text("\(grow.harvestDate, formatter: itemFormatter)")
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
                
            HStack {
                Text("Material Applications:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                    .padding(.top)
                
                Button(action: {
                    let newMaterial = Material(context: viewContext)
                    newMaterial.name = "New Application"
                    
                }, label: {
                    Text("New Application")
                })
            }
                MaterialsView()
                        
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
            GrowDetailView(grow: GrowDetailViewModel(grow: Grow(context:PersistenceController.preview.container.viewContext)))
        }
    }
}
