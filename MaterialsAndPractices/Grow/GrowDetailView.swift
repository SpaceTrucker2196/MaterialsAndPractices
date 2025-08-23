//
//  GrowDetailView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

struct GrowDetailViewModel  {
    var grow : Grow
    var cultivar = "New Cultivar"
    var cultivarFamily = ""
    var hardyZone = ""
    var season = ""
    var plantingWeek = ""
    var name = "My Grow"
    var plantedDate = Date()
    var harvestDate = Date()
    var daysTillHarvest = 90
    var locationName = "My Location"
    var previewImage = Grow.Image(grow:Grow())
    init(grow:Grow) {
        self.grow = grow
        cultivar = grow.cultivar?.name ?? "No Cultivar Selected"
        cultivarFamily = grow.cultivar?.family ?? ""
        hardyZone = grow.cultivar?.hardyZone ?? ""
        season = grow.cultivar?.season ?? ""
        plantingWeek = grow.cultivar?.plantingWeek ?? ""
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
    @State var growViewModel:GrowDetailViewModel
    
    var body: some View {
        ScrollView {
            
        VStack(alignment: .leading) {
            VStack(alignment: .leading){
                HStack {
                    growViewModel.previewImage
                    VStack(alignment: .leading) {
                        Text("Cultivar:")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.green)
                            .multilineTextAlignment(.leading)
                        Text("\(growViewModel.cultivar )")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .multilineTextAlignment(.leading)
                        
                        if !growViewModel.cultivarFamily.isEmpty {
                            Text("Family: \(growViewModel.cultivarFamily)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            if !growViewModel.season.isEmpty {
                                Text("Season: \(growViewModel.season)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            if !growViewModel.hardyZone.isEmpty {
                                Text("Zone: \(growViewModel.hardyZone)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        
                        if !growViewModel.plantingWeek.isEmpty {
                            Text("Planting Week: \(growViewModel.plantingWeek)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text("Planted Date:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4.0)
                Text("\(growViewModel.plantedDate, formatter: itemFormatter)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                Text("Expected Harvest:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .multilineTextAlignment(.leading)
                Text("\(growViewModel.harvestDate, formatter: itemFormatter)")
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
            Text("\(growViewModel.locationName)")
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
             
            Text("Work:")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.leading)
                .padding(.top)
           
            WorkPractices(selectedGrow:growViewModel.grow).frame(maxWidth:.infinity)
            
            Button(action: {
                let newWork = Work(context: viewContext)
                growViewModel.grow.addToWork(newWork)
                
            }, label: {
                Text("Perform").font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
                    .padding(.all, 4.0)
                    .frame(maxWidth: .infinity)
                    
            }).border(Color.accentColor, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .cornerRadius(4.0) .padding()
            Spacer()
            
            Text("Ammendment Applications:")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
                .multilineTextAlignment(.leading)
                .padding(.top)
 
            Amendments(selectedGrow:growViewModel.grow).frame(maxWidth: .infinity)
            
            Button(action: {
                let newAmendment = Amendment(context: viewContext)
                growViewModel.grow.addToAmendments(newAmendment)
            }, label: {
                Text("Apply")
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.all, 4.0)
                    .frame(maxWidth: .infinity)
                    
            }).border(Color.accentColor, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .cornerRadius(4.0) .padding()
            
            
        }.padding(.all).navigationTitle("\(growViewModel.name)")
    }
    }
}

struct GrowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GrowDetailView(growViewModel: GrowDetailViewModel(grow: Grow(context:PersistenceController.preview.container.viewContext)))
        }
    }
}
