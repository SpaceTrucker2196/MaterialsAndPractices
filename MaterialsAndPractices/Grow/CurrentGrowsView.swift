//
//  ContentView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

struct CurrentGrowsView: View {
    
    @State private var showCreateGrow = false
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity:Grow.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Grow.title, ascending: true)],
        animation: .default)
    
    private var grows: FetchedResults<Grow>

    var body: some View {
        NavigationView {
                List {
                    ForEach(grows) { grow in
                        GrowRow(grow: grow)
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    Button(action: {
                        showCreateGrow = true
                    }) {
                        Label("Add New Grow", systemImage: "plus")
                    }
                }.navigationTitle("Active Grows")
        }.sheet(isPresented: $showCreateGrow, content: {
            EditGrowView(isPresented:$showCreateGrow)
        })
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { grows[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct GrowRow: View {
    var grow:Grow
    var body: some View {
        NavigationLink(
            destination: GrowDetailView(grow: GrowDetailViewModel.init(grow: grow)),
            label: {
                VStack(alignment: .leading, spacing: 1.0) {
                    HStack(alignment: .center) {
                        Grow.Image(grow:grow)
                        VStack(alignment: .leading) {
                            Text("\(grow.title ?? "My Grow")")
                                .font(.headline)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)

                            Text("Planted Date")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.green)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(grow.plantedDate!, formatter: itemFormatter)")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.black)
                                .multilineTextAlignment(.leading)
                                
                            Text("Location")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.green)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(grow.locationName ?? "")")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.black)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.leading, 2.0)
                    }
                    .padding([.top, .leading, .bottom], 4.0)
                }
                .padding(.all, 4.0)
            })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CurrentGrowsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
