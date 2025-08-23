//
//  HarvestSafetyChecklist.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 12/6/20.
//

import SwiftUI

struct HarvestSafetyChecklistItem {
    let id = UUID()
    let text: String
    let reference: String
    var isCompleted: Bool = false
    var isNotApplicable: Bool = false
}

struct HarvestSafetySection {
    let title: String
    var items: [HarvestSafetyChecklistItem]
}

class HarvestSafetyChecklistData: ObservableObject {
    @Published var sections: [HarvestSafetySection] = []
    @Published var farmName: String = ""
    @Published var farmContact: String = ""
    @Published var contractHarvesterName: String = ""
    @Published var contractHarvesterAddress: String = ""
    @Published var contractHarvesterPhone: String = ""
    @Published var contractHarvesterEmail: String = ""
    @Published var fieldLocation: String = ""
    @Published var commoditiesHarvested: String = ""
    @Published var estimatedHarvestDates: String = ""
    
    init() {
        setupChecklistData()
    }
    
    private func setupChecklistData() {
        sections = [
            HarvestSafetySection(title: "Health and Hygiene Training – All Employees", items: [
                HarvestSafetyChecklistItem(text: "Health and hygiene training upon hire.", reference: "§112.21(a)"),
                HarvestSafetyChecklistItem(text: "Training on health and hygiene practices annually after hire.", reference: "§112.21(a)"),
                HarvestSafetyChecklistItem(text: "Training in a language and format that they can understand.", reference: "§112.21(c)"),
                HarvestSafetyChecklistItem(text: "Training to report illness to a supervisor when they are not feeling well.", reference: "§112.31"),
                HarvestSafetyChecklistItem(text: "Training to stop working when injury occurs and report their injuries to a supervisor.", reference: "§112.31"),
                HarvestSafetyChecklistItem(text: "Training to wear clean clothing and footwear to work every day.", reference: "§112.32(b)(1)"),
                HarvestSafetyChecklistItem(text: "Training to not handle livestock before coming to work with produce.", reference: "§112.32(b)(2)"),
                HarvestSafetyChecklistItem(text: "Training to remove or cover any jewelry that cannot be cleaned and sanitized before handling covered produce.", reference: "§112.32(b)(5)"),
                HarvestSafetyChecklistItem(text: "Training to take breaks, eat meals and smoke in a designated area outside of all areas used for growing produce.", reference: "§112.32(b)(6)"),
                HarvestSafetyChecklistItem(text: "Training on proper use of toilets (disposal of waste into toilet).", reference: "§112.129(b)"),
                HarvestSafetyChecklistItem(text: "All employees have a combination of education, training and experience necessary to perform their assigned jobs.", reference: "§112.21(b)"),
                HarvestSafetyChecklistItem(text: "Re-training occurs when employees are not following policies or meeting the standards of the Produce Safety Rule.", reference: "§112.21(d)")
            ]),
            
            HarvestSafetySection(title: "Hand Washing Training", items: [
                HarvestSafetyChecklistItem(text: "Before starting work", reference: "§112.32(b)(3)"),
                HarvestSafetyChecklistItem(text: "Before putting on gloves (only if using gloves)", reference: "§112.32(b)(3)"),
                HarvestSafetyChecklistItem(text: "After using the toilet/restroom", reference: "§112.32(b)(3)"),
                HarvestSafetyChecklistItem(text: "After all breaks, eating, and/or smoking", reference: "§112.32(b)(3)"),
                HarvestSafetyChecklistItem(text: "After touching or handling animals (livestock and pets) or handling animal waste", reference: "§112.32(b)(3)"),
                HarvestSafetyChecklistItem(text: "Any other times when hands might have become contaminated", reference: "§112.32(b)(3)")
            ]),
            
            HarvestSafetySection(title: "Glove Training", items: [
                HarvestSafetyChecklistItem(text: "Remove gloves before using the restroom", reference: "§112.32(b)(4)"),
                HarvestSafetyChecklistItem(text: "Wash hands before putting on gloves", reference: "§112.32(b)(4)"),
                HarvestSafetyChecklistItem(text: "Maintain gloves in a sanitary manner", reference: "§112.32(b)(4)"),
                HarvestSafetyChecklistItem(text: "Replace gloves when damaged or unable to be cleaned", reference: "§112.32(b)(4)"),
                HarvestSafetyChecklistItem(text: "Leave gloves at farm and not take them home", reference: "§112.32(b)(4)")
            ]),
            
            HarvestSafetySection(title: "Harvest Training", items: [
                HarvestSafetyChecklistItem(text: "Recognize and not harvest produce that is contaminated.", reference: "§112.22(b)(1)"),
                HarvestSafetyChecklistItem(text: "Inspect harvest containers and equipment to ensure they are clean and in proper working order.", reference: "§112.22(b)(2)"),
                HarvestSafetyChecklistItem(text: "Correct any problems with harvest containers/equipment or to notify their supervisor of any problems.", reference: "§112.22(b)(3)"),
                HarvestSafetyChecklistItem(text: "Identify and not harvest any dropped covered produce.", reference: "§112.114"),
                HarvestSafetyChecklistItem(text: "All employees are trained to store any tools used for harvesting in manner that prevents them from being contaminated during breaks and at the end of the day.", reference: "§112.123(b)(2)")
            ]),
            
            HarvestSafetySection(title: "Sanitation Practices", items: [
                HarvestSafetyChecklistItem(text: "A pre-harvest assessment of the growing areas is performed prior to harvest.", reference: "§112.112"),
                HarvestSafetyChecklistItem(text: "Contaminated produce is identified and not harvested.", reference: "§112.83(b)(2)"),
                HarvestSafetyChecklistItem(text: "Produce is harvested to ensure it is not contaminated during harvest.", reference: "§112.113"),
                HarvestSafetyChecklistItem(text: "Produce that drops to the ground before harvest is discarded and not sold.", reference: "§112.114"),
                HarvestSafetyChecklistItem(text: "Equipment and tools are maintained and inspected to ensure they are clean and in good repair prior to use.", reference: "§112.123(a)"),
                HarvestSafetyChecklistItem(text: "All trash, litter and waste are removed from fields and properly disposed of.", reference: "§112.132")
            ])
        ]
    }
}

struct HarvestSafetyChecklistView: View {
    @StateObject private var checklistData = HarvestSafetyChecklistData()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Farm Information")) {
                    TextField("Farm Name", text: $checklistData.farmName)
                    TextField("Farm Contact", text: $checklistData.farmContact)
                    TextField("Field Location", text: $checklistData.fieldLocation)
                    TextField("Commodities Harvested", text: $checklistData.commoditiesHarvested)
                    TextField("Estimated Harvest Dates", text: $checklistData.estimatedHarvestDates)
                }
                
                Section(header: Text("Contract Harvester Information")) {
                    TextField("Name", text: $checklistData.contractHarvesterName)
                    TextField("Address", text: $checklistData.contractHarvesterAddress)
                    TextField("Phone Number", text: $checklistData.contractHarvesterPhone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $checklistData.contractHarvesterEmail)
                        .keyboardType(.emailAddress)
                }
                
                ForEach(Array(checklistData.sections.enumerated()), id: \.offset) { sectionIndex, section in
                    Section(header: Text(section.title)) {
                        ForEach(Array(section.items.enumerated()), id: \.offset) { itemIndex, item in
                            HarvestChecklistItemView(
                                item: item,
                                onCompletedChange: { isCompleted in
                                    checklistData.sections[sectionIndex].items[itemIndex].isCompleted = isCompleted
                                    if isCompleted {
                                        checklistData.sections[sectionIndex].items[itemIndex].isNotApplicable = false
                                    }
                                },
                                onNotApplicableChange: { isNotApplicable in
                                    checklistData.sections[sectionIndex].items[itemIndex].isNotApplicable = isNotApplicable
                                    if isNotApplicable {
                                        checklistData.sections[sectionIndex].items[itemIndex].isCompleted = false
                                    }
                                }
                            )
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        // Here you could save the checklist data or generate a report
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Complete Checklist")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Harvest Safety Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct HarvestChecklistItemView: View {
    let item: HarvestSafetyChecklistItem
    let onCompletedChange: (Bool) -> Void
    let onNotApplicableChange: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    onCompletedChange(!item.isCompleted)
                }) {
                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                        .foregroundColor(item.isCompleted ? .green : .gray)
                }
                
                Text(item.text)
                    .font(.body)
                    .strikethrough(item.isCompleted, color: .gray)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
                
                Spacer()
                
                Button(action: {
                    onNotApplicableChange(!item.isNotApplicable)
                }) {
                    Text("N/A")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.isNotApplicable ? Color.orange : Color.gray.opacity(0.3))
                        .foregroundColor(item.isNotApplicable ? .white : .gray)
                        .cornerRadius(4)
                }
            }
            
            Text("Reference: \(item.reference)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct HarvestSafetyChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        HarvestSafetyChecklistView()
    }
}