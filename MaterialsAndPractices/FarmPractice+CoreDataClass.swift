//
//  FarmPractice+CoreDataClass.swift
//  MaterialsAndPractices
//
//  Created by GitHub Copilot for practice management functionality
//

import Foundation
import CoreData

@objc(FarmPractice)
public class FarmPractice: NSManagedObject {
    
    /// Creates a default FarmPractice instance
    static func createDefault(in context: NSManagedObjectContext) -> FarmPractice {
        let practice = FarmPractice(context: context)
        practice.practiceID = UUID()
        practice.name = "New Practice"
        practice.descriptionText = "Describe the recordkeeping or food safety practice."
        practice.trainingRequired = "Training details not yet provided."
        practice.frequency = "As needed"
        practice.certification = "Unspecified"
        practice.lastUpdated = Date()
        return practice
    }
    
    /// Creates predefined farm practices from the problem statement
    static func createPredefinedPractices(in context: NSManagedObjectContext) -> [FarmPractice] {
        let practices = [
            (
                name: "🧪 Soil Amendment Recordkeeping",
                description: "Track all soil inputs including compost, manure, and other amendments. Include source, rate, application method, and dates.",
                training: "Organic soil health, OMRI-compliant materials handling.",
                frequency: "Every amendment event.",
                certification: "NOP Organic Certification."
            ),
            (
                name: "🌱 Seed Source Documentation",
                description: "Maintain records of seed purchases, noting organic status, treatment (if any), and supplier.",
                training: "Organic seed sourcing standards.",
                frequency: "Per purchase/order.",
                certification: "NOP Organic Certification."
            ),
            (
                name: "🐞 Pest and Weed Management Log",
                description: "Document all pest and weed control activities, including physical, biological, and allowed synthetic methods.",
                training: "Integrated Pest Management (IPM) in organic systems.",
                frequency: "Every application or activity.",
                certification: "NOP Organic Certification."
            ),
            (
                name: "🌾 Harvest Recordkeeping",
                description: "Track harvest quantities, fields, dates, and destinations for traceability.",
                training: "Organic traceability and documentation.",
                frequency: "Every harvest event.",
                certification: "NOP Organic Certification."
            ),
            (
                name: "🧼 Worker Hygiene and Food Safety Training",
                description: "Document training for all employees on proper hygiene and safe produce handling practices.",
                training: "USDA GAP worker hygiene training.",
                frequency: "Annually or upon hiring.",
                certification: "USDA GAP / Harmonized GAP."
            ),
            (
                name: "💧 Water Source and Quality Monitoring",
                description: "Record irrigation and wash water sources and periodic water testing results.",
                training: "Water safety standards and contamination prevention.",
                frequency: "Quarterly or per certifier requirement.",
                certification: "USDA GAP, Organic Certification."
            ),
            (
                name: "♻️ Manure and Compost Application Log",
                description: "Log details of raw manure or compost use including aging, C:N ratio, temperature, and application dates.",
                training: "Compost safety and NOP compliance.",
                frequency: "Every use or turn event.",
                certification: "NOP Organic Certification."
            ),
            (
                name: "🧽 Equipment Sanitation Log",
                description: "Track cleaning and sanitizing activities for harvest and processing tools and equipment.",
                training: "Food safety sanitation protocols.",
                frequency: "Daily or before/after each use.",
                certification: "USDA GAP."
            ),
            (
                name: "🔍 Traceability Lot Codes and Product Flow",
                description: "Track produce from field to customer using lot codes and detailed logs for product traceability.",
                training: "Food traceability and lot tracking systems.",
                frequency: "Per harvest and shipment.",
                certification: "USDA GAP, NOP Organic Certification."
            )
        ]
        
        return practices.map { practiceData in
            let practice = FarmPractice(context: context)
            practice.practiceID = UUID()
            practice.name = practiceData.name
            practice.descriptionText = practiceData.description
            practice.trainingRequired = practiceData.training
            practice.frequency = practiceData.frequency
            practice.certification = practiceData.certification
            practice.lastUpdated = Date()
            return practice
        }
    }
}