//
//  TrainingCourseSeeder.swift
//  MaterialsAndPractices
//
//  Seeds default training courses into Core Data on first app launch.
//  Provides compliance-ready training courses for farm operations.
//

import Foundation
import CoreData

class TrainingCourseSeeder {
    
    /// Seeds training courses if none exist in the database
    func seedCoursesIfNeeded() {
        let context = PersistenceController.shared.container.viewContext
        
        // Check if training courses already exist
        let request: NSFetchRequest<TrainingCourse> = TrainingCourse.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let existingCourses = try context.fetch(request)
            if !existingCourses.isEmpty {
                print("✅ Training courses already exist, skipping seeding")
                return
            }
            
            // Seed default courses
            seedDefaultCourses(context: context)
            
            // Save context
            try context.save()
            print("✅ Default training courses seeded successfully")
            
        } catch {
            print("❌ Error seeding training courses: \(error)")
        }
    }
    
    private func seedDefaultCourses(context: NSManagedObjectContext) {
        for courseData in DefaultTrainingData.courses {
            let course = TrainingCourse(context: context)
            
            course.courseID = UUID(uuidString: courseData.courseID) ?? UUID()
            course.courseName = courseData.courseName
            course.courseDescription = courseData.courseDescription
            course.complianceCategory = courseData.complianceCategory.rawValue
            course.deliveryMethod = courseData.deliveryMethod.rawValue
            course.estimatedDurationMin = Int32(courseData.estimatedDurationMin)
            course.trainerQualification = courseData.trainerQualification
            course.recertificationInterval = courseData.recertificationInterval.rawValue
            course.lastUpdated = courseData.lastUpdated
            course.active = courseData.active
            
            // Convert arrays to comma-separated strings for Core Data storage
            course.requiredForRoles = courseData.requiredForRoles.map { $0.rawValue }.joined(separator: ",")
            course.regulatoryReferences = courseData.regulatoryReferences.joined(separator: ",")
            course.languageOptions = courseData.languageOptions.joined(separator: ",")
            
            // Set optional fields
            if let assessmentMethod = courseData.assessmentMethod {
                course.assessmentMethod = assessmentMethod.rawValue
            }
            
            if let passingScore = courseData.passingScore {
                course.passingScore = passingScore
            }
        }
    }
}

// MARK: - TrainingCourse Extensions

extension TrainingCourse {
    
    /// Get required roles as an array of JobRole enums
    var requiredRolesArray: [JobRole] {
        guard let rolesString = requiredForRoles else { return [] }
        return rolesString.components(separatedBy: ",")
            .compactMap { JobRole(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
    }
    
    /// Get regulatory references as an array of strings
    var regulatoryReferencesArray: [String] {
        guard let referencesString = regulatoryReferences else { return [] }
        return referencesString.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Get language options as an array of strings
    var languageOptionsArray: [String] {
        guard let languagesString = languageOptions else { return [] }
        return languagesString.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Get compliance category as enum
    var complianceCategoryEnum: ComplianceCategory? {
        guard let categoryString = complianceCategory else { return nil }
        return ComplianceCategory(rawValue: categoryString)
    }
    
    /// Get delivery method as enum
    var deliveryMethodEnum: DeliveryMethod? {
        guard let methodString = deliveryMethod else { return nil }
        return DeliveryMethod(rawValue: methodString)
    }
    
    /// Get recertification interval as enum
    var recertificationIntervalEnum: RecertificationInterval? {
        guard let intervalString = recertificationInterval else { return nil }
        return RecertificationInterval(rawValue: intervalString)
    }
    
    /// Get assessment method as enum
    var assessmentMethodEnum: ComprehensionCheckMethod? {
        guard let methodString = assessmentMethod else { return nil }
        return ComprehensionCheckMethod(rawValue: methodString)
    }
}

// MARK: - TrainingRecord Extensions

extension TrainingRecord {
    
    /// Get compliance category as enum
    var complianceCategoryEnum: ComplianceCategory? {
        guard let categoryString = complianceCategory else { return nil }
        return ComplianceCategory(rawValue: categoryString)
    }
    
    /// Get training method as enum
    var trainingMethodEnum: TrainingMethod? {
        guard let methodString = trainingMethod else { return nil }
        return TrainingMethod(rawValue: methodString)
    }
    
    /// Get comprehension check method as enum
    var comprehensionCheckMethodEnum: ComprehensionCheckMethod? {
        guard let methodString = comprehensionCheckMethod else { return nil }
        return ComprehensionCheckMethod(rawValue: methodString)
    }
    
    /// Check if this training record is expired based on the course recertification interval
    var isExpired: Bool {
        guard let trainingDate = trainingDate,
              let course = trainingCourse,
              let intervalEnum = course.recertificationIntervalEnum else {
            return false
        }
        
        let calendar = Calendar.current
        let expirationDate: Date
        
        switch intervalEnum {
        case .oneTime, .asNeeded:
            return false
        case .annual:
            expirationDate = calendar.date(byAdding: .year, value: 1, to: trainingDate) ?? trainingDate
        case .every3Years:
            expirationDate = calendar.date(byAdding: .year, value: 3, to: trainingDate) ?? trainingDate
        case .every5Years:
            expirationDate = calendar.date(byAdding: .year, value: 5, to: trainingDate) ?? trainingDate
        }
        
        return Date() > expirationDate
    }
    
    /// Check if this training record expires within 30 days
    var expiresWithin30Days: Bool {
        guard let trainingDate = trainingDate,
              let course = trainingCourse,
              let intervalEnum = course.recertificationIntervalEnum else {
            return false
        }
        
        let calendar = Calendar.current
        let expirationDate: Date
        
        switch intervalEnum {
        case .oneTime, .asNeeded:
            return false
        case .annual:
            expirationDate = calendar.date(byAdding: .year, value: 1, to: trainingDate) ?? trainingDate
        case .every3Years:
            expirationDate = calendar.date(byAdding: .year, value: 3, to: trainingDate) ?? trainingDate
        case .every5Years:
            expirationDate = calendar.date(byAdding: .year, value: 5, to: trainingDate) ?? trainingDate
        }
        
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return expirationDate <= thirtyDaysFromNow && expirationDate >= Date()
    }
}