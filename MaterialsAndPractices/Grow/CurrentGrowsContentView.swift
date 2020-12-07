//
//  ContentView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI
import CoreData

struct CurrentGrowsContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
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
                    Button(action: addItem) {
                        Label("Add New Grow", systemImage: "plus")
                    }
                }.navigationTitle("Active Grows")
        }
    }

    private func addItem() {
        withAnimation {
            let newGrow = Grow(context: viewContext)
            newGrow.timestamp = Date()
            newGrow.title = "My New Grow"
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { grows[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
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
            destination: GrowDetailView(grow: GrowDetailViewModel()),
            label: {
                VStack(alignment: .leading, spacing: 1.0) {
                    HStack(alignment: .center) {
                        Grow.Image(title:grow.cultivar ?? "G")
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
                            
                            Text("\(grow.timestamp!, formatter: itemFormatter)")
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
            CurrentGrowsContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
