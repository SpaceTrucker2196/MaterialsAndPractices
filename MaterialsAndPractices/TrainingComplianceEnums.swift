//
//  TrainingComplianceEnums.swift
//  MaterialsAndPractices
//
//  Enums used across training and compliance tracking features.
//  Ensures consistent data entry and audit-ready standardization
//

import Foundation

// MARK: - Compliance Categories

enum ComplianceCategory: String, CaseIterable, Identifiable {
    case organicCertification = "Organic Certification"
    case fsma = "FSMA"
    case gap = "GAP"
    case osha = "OSHA Compliance"
    case workerSafety = "Worker Safety"
    case equipmentUse = "Equipment Use"
    case emergencyPreparedness = "Emergency Preparedness"
    case visitorPolicy = "Visitor Policy"
    case compostSafety = "Compost & Soil Safety"

    var id: String { rawValue }
}

// MARK: - Training Delivery Methods

enum DeliveryMethod: String, CaseIterable, Identifiable {
    case inPerson = "In-person"
    case video = "Video"
    case online = "Online"
    case documentReview = "Document Review"
    case onsiteDemo = "Onsite Demonstration"

    var id: String { rawValue }
}

// MARK: - Recertification Intervals

enum RecertificationInterval: String, CaseIterable, Identifiable {
    case oneTime = "One Time"
    case annual = "Annual"
    case every3Years = "Every 3 Years"
    case every5Years = "Every 5 Years"
    case asNeeded = "As Needed"

    var id: String { rawValue }
}

// MARK: - Training Topics

enum TrainingTopic: String, CaseIterable, Identifiable {
    case workerHygiene = "Worker Hygiene and Health"
    case organicHandling = "Organic Handling Procedures"
    case foodSafety = "Food Safety (FSMA)"
    case compostUse = "Compost & Manure Safety"
    case ppe = "Proper Use of PPE"
    case emergencyResponse = "Emergency Response & First Aid"
    case equipmentSanitation = "Equipment Cleaning Procedures"
    case harvestSanitation = "Harvest Hygiene & Cross-contamination"
    case traceability = "Recordkeeping & Traceability"

    var id: String { rawValue }
}

// MARK: - Training Methods

enum TrainingMethod: String, CaseIterable, Identifiable {
    case inPerson = "In-person"
    case video = "Video"
    case written = "Written Material"
    case online = "Online Module"

    var id: String { rawValue }
}

// MARK: - Comprehension Check Methods

enum ComprehensionCheckMethod: String, CaseIterable, Identifiable {
    case quiz = "Quiz"
    case verbal = "Verbal Questions"
    case observation = "On-the-job Observation"
    case none = "None"

    var id: String { rawValue }
}

// MARK: - Job Roles

enum JobRole: String, CaseIterable, Identifiable {
    case harvester = "Harvester"
    case handler = "Post-Harvest Handler"
    case packer = "Packer"
    case irrigator = "Irrigation Worker"
    case compostManager = "Compost Manager"
    case fieldWorker = "Field Worker"
    case foodSafetyCoordinator = "Food Safety Coordinator"
    case mechanic = "Mechanic / Equipment Operator"
    case supervisor = "Supervisor"

    var id: String { rawValue }
}

// MARK: - Default Training Courses Data

struct DefaultTrainingCourse {
    let courseID: String
    let courseName: String
    let courseDescription: String
    let complianceCategory: ComplianceCategory
    let requiredForRoles: [JobRole]
    let regulatoryReferences: [String]
    let deliveryMethod: DeliveryMethod
    let courseMaterials: [String]
    let languageOptions: [String]
    let estimatedDurationMin: Int
    let trainerQualification: String
    let assessmentMethod: ComprehensionCheckMethod?
    let passingScore: Double?
    let recertificationInterval: RecertificationInterval
    let lastUpdated: Date
    let active: Bool
}

// MARK: - Default Course Data

class DefaultTrainingData {
    static let courses: [DefaultTrainingCourse] = [
        DefaultTrainingCourse(
            courseID: "2a2d37fe-bff9-4690-94c2-adb5126b2aad",
            courseName: "Worker Hygiene and Health",
            courseDescription: "Training on proper hygiene, handwashing, illness reporting, and clean work clothing.",
            complianceCategory: .fsma,
            requiredForRoles: [.harvester, .handler, .packer],
            regulatoryReferences: ["FSMA Subpart E", "GAP Section 4"],
            deliveryMethod: .inPerson,
            courseMaterials: ["worker_hygiene_presentation.pdf"],
            languageOptions: ["English", "Spanish"],
            estimatedDurationMin: 45,
            trainerQualification: "Food Safety Coordinator",
            assessmentMethod: .quiz,
            passingScore: 0.8,
            recertificationInterval: .annual,
            lastUpdated: Date(),
            active: true
        ),
        DefaultTrainingCourse(
            courseID: "3275efbc-1f42-465a-89f2-821ed9accdcf",
            courseName: "Organic Handling Procedures",
            courseDescription: "Training on organic certification requirements, buffer zones, and prohibited substances.",
            complianceCategory: .organicCertification,
            requiredForRoles: [.handler, .fieldWorker, .supervisor],
            regulatoryReferences: ["NOP 205.105", "205.272"],
            deliveryMethod: .inPerson,
            courseMaterials: ["organic_handling_manual.pdf"],
            languageOptions: ["English", "Spanish"],
            estimatedDurationMin: 60,
            trainerQualification: "Organic Compliance Officer",
            assessmentMethod: .verbal,
            passingScore: nil,
            recertificationInterval: .annual,
            lastUpdated: Date(),
            active: true
        ),
        DefaultTrainingCourse(
            courseID: "6cd56035-7a77-4c8b-8c55-7b78fba8ba1b",
            courseName: "Compost and Manure Use",
            courseDescription: "Covers safe application of compost and manure for organic production and pathogen prevention.",
            complianceCategory: .organicCertification,
            requiredForRoles: [.compostManager, .fieldWorker],
            regulatoryReferences: ["NOP 205.203(c)", "FSMA Produce Rule"],
            deliveryMethod: .documentReview,
            courseMaterials: ["compost_use_guidelines.pdf"],
            languageOptions: ["English"],
            estimatedDurationMin: 30,
            trainerQualification: "Farm Manager",
            assessmentMethod: .observation,
            passingScore: nil,
            recertificationInterval: .every3Years,
            lastUpdated: Date(),
            active: true
        ),
        DefaultTrainingCourse(
            courseID: "81acb468-acfb-4aff-94f1-8ec7ba1bdf4c",
            courseName: "Food Handling Permit & Safety",
            courseDescription: "Prepares workers for local food handler permits, cross-contamination prevention, and food safety laws.",
            complianceCategory: .fsma,
            requiredForRoles: [.handler, .packer, .supervisor],
            regulatoryReferences: ["FDA Food Code", "Local Permit Office"],
            deliveryMethod: .online,
            courseMaterials: ["food_handler_training_module.pdf"],
            languageOptions: ["English", "Spanish"],
            estimatedDurationMin: 90,
            trainerQualification: "Certified Food Safety Instructor",
            assessmentMethod: .quiz,
            passingScore: 0.75,
            recertificationInterval: .every3Years,
            lastUpdated: Date(),
            active: true
        ),
        DefaultTrainingCourse(
            courseID: "229df45d-87f5-4ead-a254-83bfe719eae8",
            courseName: "Harvest Tool Sanitation",
            courseDescription: "Procedures for cleaning and sanitizing knives, bins, and containers used in harvesting.",
            complianceCategory: .gap,
            requiredForRoles: [.harvester, .handler],
            regulatoryReferences: ["GAP Section 2.2", "FSMA Subpart L"],
            deliveryMethod: .onsiteDemo,
            courseMaterials: ["harvest_sanitation_checklist.pdf"],
            languageOptions: ["English", "Spanish"],
            estimatedDurationMin: 30,
            trainerQualification: "Harvest Supervisor",
            assessmentMethod: .observation,
            passingScore: nil,
            recertificationInterval: .annual,
            lastUpdated: Date(),
            active: true
        )
    ]
}