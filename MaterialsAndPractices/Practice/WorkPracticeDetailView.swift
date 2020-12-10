//
//  PracticeDetailView.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/10/20.
//

import SwiftUI

struct WorkPracticeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var work : Work
    @State private var selectedPracticeIndex = 0
    
    var practices = ["Disk","Weed","Burn","Mow","Plastic Multch"]
    
    var body: some View {
        VStack {
                Form {
                    Section(header: Text("Details")) {
                        
                        TextField("New Practice", text:Binding($work.name, ""))
                        TextField("Work:", text:Binding($work.practice, ""))
                       
                        Picker(selection:$selectedPracticeIndex, label: Text("Perform Work:").foregroundColor(Color("OrganicPracticeColor"))) {
                                   ForEach(0 ..< practices.count) {
                                      Text(self.practices[$0])
                                   }
                        }.onChange(of:selectedPracticeIndex, perform: { value in
                            work.practice = practices[selectedPracticeIndex]
                            
                            if work.name == "" {
                                work.name = "\(practices[selectedPracticeIndex])"
                            }
                        })
                    }
                    
                    Section(header: Text("Labor")) {
                       
                    }
                    
                    Button(action: {
                        work.practiceIndex = Int32(selectedPracticeIndex)
                        work.practice = "\(practices[selectedPracticeIndex])"
                        do {
                            try viewContext.save()
                        } catch {
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        
                        self.presentationMode.wrappedValue.dismiss()
                        
                    }, label: {
                        Text("Update")
                            .font(.headline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.all, 4.0)
                            .frame(maxWidth: .infinity)
                        
                    }).border(Color.accentColor, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    .cornerRadius(4.0) .padding()
                }
        }
    }
}

struct PracticeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WorkPracticeDetailView(work:Work(context:PersistenceController.preview.container.viewContext))
    }
}
