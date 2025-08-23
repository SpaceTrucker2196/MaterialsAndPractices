//
//  CultivarViews.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI

extension Cultivar {
    struct Image: View {
        let cultivar: Cultivar
        
        var body: some View {
            let symbol = SwiftUI.Image(cultivar: cultivar) ?? .init(systemName: "leaf.fill")
            
            symbol
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .font(Font.title.weight(.light))
                .foregroundColor(.green)
        }
    }
}

extension SwiftUI.Image {
    init?(cultivar: Cultivar) {
        guard let name = cultivar.name,
              let firstChar = name.first,
              case let symbolName = "\(firstChar.lowercased()).square",
              UIImage(systemName: symbolName) != nil
        else {
            return nil
        }
        self.init(systemName: symbolName)
    }
}

struct CultivarDetailView: View {
    let cultivar: Cultivar
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Cultivar.Image(cultivar: cultivar)
                    VStack(alignment: .leading) {
                        Text(cultivar.name ?? "Unknown Cultivar")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let family = cultivar.family, !family.isEmpty {
                            Text("Family: \(family)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    
                    if let season = cultivar.season, !season.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Season")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text(season)
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    if let hardyZone = cultivar.hardyZone, !hardyZone.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Hardy Zone")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text(hardyZone)
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    if let plantingWeek = cultivar.plantingWeek, !plantingWeek.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Planting Week")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text(plantingWeek)
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(cultivar.name ?? "Cultivar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CultivarListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Cultivar.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Cultivar.family, ascending: true),
                         NSSortDescriptor(keyPath: \Cultivar.name, ascending: true)]
    ) var cultivars: FetchedResults<Cultivar>
    
    @State private var searchText = ""
    
    var filteredCultivars: [Cultivar] {
        if searchText.isEmpty {
            return Array(cultivars)
        } else {
            return cultivars.filter { cultivar in
                (cultivar.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (cultivar.family?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Dictionary(grouping: filteredCultivars) { $0.family ?? "Unknown" }.sorted(by: { $0.key < $1.key }), id: \.key) { family, cultivarsInFamily in
                    
                    Section(header: 
                        HStack {
                            Text(family)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(cultivarsInFamily.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    ) {
                        ForEach(cultivarsInFamily.sorted { ($0.name ?? "") < ($1.name ?? "") }, id: \.self) { cultivar in
                            NavigationLink(destination: CultivarDetailView(cultivar: cultivar)) {
                                    HStack(spacing: 12) {
                                        Cultivar.Image(cultivar: cultivar)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(cultivar.name ?? "Unknown")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            HStack(spacing: 6) {
                                                if let season = cultivar.season, !season.isEmpty {
                                                    Text(season)
                                                        .font(.caption2)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.2))
                                                        .cornerRadius(4)
                                                }
                                                
                                                if let hardyZone = cultivar.hardyZone, !hardyZone.isEmpty {
                                                    Text("Zone \(hardyZone)")
                                                        .font(.caption2)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.green.opacity(0.2))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        }
                                        Spacer()
                                    }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search cultivars...")
            .navigationTitle("Cultivars")
        }
    }
}

struct CultivarViews_Previews: PreviewProvider {
    static var previews: some View {
        CultivarListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}