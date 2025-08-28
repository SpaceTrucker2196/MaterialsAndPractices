# 🧾 Farm Training Compliance Schemas

This document defines two interrelated schemas for tracking **employee training** and **course requirements** on a farm to ensure **compliance with USDA Organic, FSMA, OSHA, and GAP standards**.

---

## 📘 `TrainingCourse` Schema

Tracks the definition of each training course required for food safety, worker hygiene, organic certification, and more.

| **Field Name**            | **Type**       | **Required** | **Description** |
|---------------------------|----------------|--------------|------------------|
| `courseID`                | UUID           | ✅ Yes       | Unique identifier for the training course |
| `courseName`              | String         | ✅ Yes       | Title of the course (e.g., “Worker Hygiene and Food Safety”) |
| `courseDescription`       | Text           | ✅ Yes       | Summary of training content and goals |
| `complianceCategory`      | Enum           | ✅ Yes       | Regulatory category this course fulfills (e.g., Organic, FSMA) |
| `requiredForRoles`        | [String]       | ✅ Yes       | List of job titles that require this training |
| `regulatoryReferences`    | [String]       | Optional     | Reference documents like FSMA Subpart E, USDA NOP Handbook |
| `deliveryMethod`          | Enum           | ✅ Yes       | Method of delivery: In-person, Online, Document Review |
| `courseMaterials`         | FileRef[]      | ✅ Yes       | Training materials or links to documents/slides |
| `languageOptions`         | [String]       | ✅ Yes       | Languages available for the course |
| `estimatedDurationMin`    | Integer        | ✅ Yes       | Duration of training in minutes |
| `trainerQualification`    | String         | ✅ Yes       | Required credentials or background of trainers |
| `assessmentMethod`        | Enum           | Optional     | How comprehension is verified: quiz, observation |
| `passingScore`            | Float (0–1.0)  | Optional     | Passing threshold, e.g., 0.8 for 80% |
| `recertificationInterval` | Enum/Integer   | ✅ Yes       | Frequency of retraining: Annual, 3 years, etc. |
| `lastUpdated`             | Date           | ✅ Yes       | Date when training content was last reviewed |
| `active`                  | Boolean        | ✅ Yes       | Indicates if the course is actively in use |

---

## 📗 `TrainingRecord` Schema

Captures a specific instance of an employee receiving training. This is what auditors will review for compliance.

| **Field Name**              | **Type**     | **Required** | **Description** |
|-----------------------------|--------------|--------------|------------------|
| `trainingID`                | UUID         | ✅ Yes       | Unique ID for each training record |
| `employeeID`                | UUID         | ✅ Yes       | Links to employee record |
| `fullName`                  | String       | ✅ Yes       | Trainee’s legal name |
| `jobTitle`                  | String       | ✅ Yes       | Trainee’s role on the farm |
| `trainingTopic`             | Enum/String  | ✅ Yes       | Topic covered in the session |
| `trainingDescription`       | Text         | ✅ Yes       | What was taught and expected outcomes |
| `trainingDate`              | Date         | ✅ Yes       | Date of training |
| `trainerName`               | String       | ✅ Yes       | Name of person who delivered the training |
| `trainingMethod`            | Enum         | ✅ Yes       | “In-person”, “Video”, “Document Review”, etc. |
| `trainingMaterials`         | FileRef[]    | Optional     | Supporting materials |
| `trainingDurationMinutes`   | Integer      | ✅ Yes       | Duration of the training |
| `languageProvided`          | String       | ✅ Yes       | Language in which the course was delivered |
| `employeeSignature`         | File/Image   | ✅ Yes       | Signature of trainee |
| `trainerSignature`          | File/Image   | ✅ Yes       | Signature of trainer |
| `comprehensionCheckMethod` | String       | Optional     | “Quiz”, “Verbal Check”, “Observation”, etc. |
| `passStatus`                | Boolean      | ✅ Yes       | Did the employee pass or fail? |
| `notes`                     | Text         | Optional     | Observations or follow-up required |
| `followUpDate`              | Date         | Optional     | Scheduled refresher or make-up training |
| `requiresAnnualReview`      | Boolean      | ✅ Yes       | Whether the topic must be reviewed annually |
| `nextScheduledReview`       | Date         | Optional     | Planned next training |
| `complianceCategory`        | Enum         | ✅ Yes       | e.g., FSMA, Organic, GAP, Worker Safety |
| `associatedPolicyID`        | UUID         | Optional     | Link to relevant policy document |

---

## ✅ Usage Notes

- These schemas are designed for integration in mobile apps, spreadsheets, or farm compliance databases.
- All records should be **digitally archived for at least 5 years** for audit and traceability.
- If you are working toward **organic certification**, tie each course to **NOP 205 references**.

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