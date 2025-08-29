//
//  TrainingWorkflowTests.swift
//  MaterialsAndPracticesTests
//
//  Tests for training course assignment and completion workflows.
//  Validates compliance tracking and training record management.
//

import XCTest
import CoreData
@testable import MaterialsAndPractices

class TrainingWorkflowTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    var trainingSeeder: TrainingCourseSeeder!
    var worker: Worker!
    var trainingCourse: TrainingCourse!
    
    override func setUpWithError() throws {
        // Set up in-memory Core Data context for testing
        let container = NSPersistentContainer(name: "MaterialsAndPractices")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        context = container.viewContext
        trainingSeeder = TrainingCourseSeeder()
        
        // Create test worker
        worker = Worker(context: context)
        worker.id = UUID()
        worker.name = "Test Worker"
        worker.position = "Harvester"
        worker.isActive = true
        
        try context.save()
        
        // Seed default training courses
        trainingSeeder.seedCoursesIfNeeded()
        
        // Get first training course for testing
        let request: NSFetchRequest<TrainingCourse> = TrainingCourse.fetchRequest()
        request.fetchLimit = 1
        let courses = try context.fetch(request)
        XCTAssertFalse(courses.isEmpty, "Should have seeded training courses")
        trainingCourse = courses.first!
    }
    
    override func tearDownWithError() throws {
        context = nil
        trainingSeeder = nil
        worker = nil
        trainingCourse = nil
    }
    
    // MARK: - Training Course Seeding Tests
    
    func testTrainingCourseSeeding() throws {
        let request: NSFetchRequest<TrainingCourse> = TrainingCourse.fetchRequest()
        let courses = try context.fetch(request)
        
        // Should have 5 default courses
        XCTAssertEqual(courses.count, 5)
        
        // Verify specific courses exist
        let courseNames = courses.compactMap { $0.courseName }
        XCTAssertTrue(courseNames.contains("Worker Hygiene and Health"))
        XCTAssertTrue(courseNames.contains("Organic Handling Procedures"))
        XCTAssertTrue(courseNames.contains("Compost and Manure Use"))
        XCTAssertTrue(courseNames.contains("Food Handling Permit & Safety"))
        XCTAssertTrue(courseNames.contains("Harvest Tool Sanitation"))
        
        // Verify all courses are active
        let activeCourses = courses.filter { $0.active }
        XCTAssertEqual(activeCourses.count, 5)
    }
    
    func testTrainingCourseProperties() throws {
        XCTAssertNotNil(trainingCourse.courseID)
        XCTAssertNotNil(trainingCourse.courseName)
        XCTAssertNotNil(trainingCourse.courseDescription)
        XCTAssertNotNil(trainingCourse.complianceCategory)
        XCTAssertTrue(trainingCourse.estimatedDurationMin > 0)
        XCTAssertTrue(trainingCourse.active)
        
        // Test extension methods
        let complianceEnum = trainingCourse.complianceCategoryEnum
        XCTAssertNotNil(complianceEnum)
        
        let deliveryEnum = trainingCourse.deliveryMethodEnum
        XCTAssertNotNil(deliveryEnum)
        
        let requiredRoles = trainingCourse.requiredRolesArray
        XCTAssertFalse(requiredRoles.isEmpty)
    }
    
    // MARK: - Training Record Creation Tests
    
    func testCreateTrainingRecord() throws {
        let trainingRecord = TrainingRecord(context: context)
        trainingRecord.trainingID = UUID()
        trainingRecord.worker = worker
        trainingRecord.trainingCourse = trainingCourse
        trainingRecord.trainingDate = Date()
        trainingRecord.passStatus = true
        trainingRecord.trainingDurationMinutes = Int32(trainingCourse.estimatedDurationMin)
        trainingRecord.trainerName = "Test Trainer"
        trainingRecord.languageProvided = "English"
        trainingRecord.complianceCategory = trainingCourse.complianceCategory
        trainingRecord.requiresAnnualReview = true
        
        try context.save()
        
        // Verify training record was created and linked
        XCTAssertEqual(trainingRecord.worker, worker)
        XCTAssertEqual(trainingRecord.trainingCourse, trainingCourse)
        XCTAssertTrue(trainingRecord.passStatus)
        
        // Verify worker has training record
        let workerTrainingRecords = worker.trainingRecords?.allObjects as? [TrainingRecord]
        XCTAssertEqual(workerTrainingRecords?.count, 1)
        XCTAssertEqual(workerTrainingRecords?.first, trainingRecord)
    }
    
    func testTrainingRecordExpiration() throws {
        let calendar = Calendar.current
        
        // Create training record from 2 years ago
        let oldTrainingDate = calendar.date(byAdding: .year, value: -2, to: Date())!
        
        let trainingRecord = TrainingRecord(context: context)
        trainingRecord.trainingID = UUID()
        trainingRecord.worker = worker
        trainingRecord.trainingCourse = trainingCourse
        trainingRecord.trainingDate = oldTrainingDate
        trainingRecord.passStatus = true
        trainingRecord.complianceCategory = trainingCourse.complianceCategory
        
        // Set course to require annual recertification
        trainingCourse.recertificationInterval = RecertificationInterval.annual.rawValue
        
        try context.save()
        
        // Test expiration logic
        XCTAssertTrue(trainingRecord.isExpired, "Training from 2 years ago should be expired for annual recertification")
        XCTAssertFalse(trainingRecord.expiresWithin30Days, "Already expired training should not be 'expiring within 30 days'")
    }
    
    func testTrainingRecordExpiresWithin30Days() throws {
        let calendar = Calendar.current
        
        // Create training record from 11 months ago (expiring soon for annual recertification)
        let recentTrainingDate = calendar.date(byAdding: .month, value: -11, to: Date())!
        
        let trainingRecord = TrainingRecord(context: context)
        trainingRecord.trainingID = UUID()
        trainingRecord.worker = worker
        trainingRecord.trainingCourse = trainingCourse
        trainingRecord.trainingDate = recentTrainingDate
        trainingRecord.passStatus = true
        trainingRecord.complianceCategory = trainingCourse.complianceCategory
        
        // Set course to require annual recertification
        trainingCourse.recertificationInterval = RecertificationInterval.annual.rawValue
        
        try context.save()
        
        // Test expiration logic
        XCTAssertFalse(trainingRecord.isExpired, "Training from 11 months ago should not be expired yet")
        XCTAssertTrue(trainingRecord.expiresWithin30Days, "Training from 11 months ago should expire within 30 days")
    }
    
    // MARK: - Training Assignment Workflow Tests
    
    func testWorkerTrainingAssignment() throws {
        // Verify worker starts with no training
        let initialTrainingRecords = worker.trainingRecords?.allObjects as? [TrainingRecord] ?? []
        XCTAssertEqual(initialTrainingRecords.count, 0)
        
        // Assign training to worker
        let trainingRecord = TrainingRecord(context: context)
        trainingRecord.trainingID = UUID()
        trainingRecord.worker = worker
        trainingRecord.trainingCourse = trainingCourse
        trainingRecord.trainingDate = Date()
        trainingRecord.passStatus = true
        trainingRecord.trainingDurationMinutes = Int32(trainingCourse.estimatedDurationMin)
        trainingRecord.trainerName = "Farm Supervisor"
        trainingRecord.languageProvided = "English"
        trainingRecord.complianceCategory = trainingCourse.complianceCategory
        trainingRecord.trainingMethod = TrainingMethod.inPerson.rawValue
        trainingRecord.comprehensionCheckMethod = ComprehensionCheckMethod.verbal.rawValue
        
        try context.save()
        
        // Verify assignment
        let finalTrainingRecords = worker.trainingRecords?.allObjects as? [TrainingRecord] ?? []
        XCTAssertEqual(finalTrainingRecords.count, 1)
        
        let assignedRecord = finalTrainingRecords.first!
        XCTAssertEqual(assignedRecord.trainingCourse?.courseName, trainingCourse.courseName)
        XCTAssertTrue(assignedRecord.passStatus)
        XCTAssertEqual(assignedRecord.trainerName, "Farm Supervisor")
    }
    
    func testMultipleTrainingAssignments() throws {
        // Get multiple training courses
        let request: NSFetchRequest<TrainingCourse> = TrainingCourse.fetchRequest()
        let allCourses = try context.fetch(request)
        XCTAssertGreaterThanOrEqual(allCourses.count, 2, "Need at least 2 courses for this test")
        
        // Assign first two courses to worker
        for (index, course) in allCourses.prefix(2).enumerated() {
            let trainingRecord = TrainingRecord(context: context)
            trainingRecord.trainingID = UUID()
            trainingRecord.worker = worker
            trainingRecord.trainingCourse = course
            trainingRecord.trainingDate = Calendar.current.date(byAdding: .day, value: -index, to: Date())
            trainingRecord.passStatus = true
            trainingRecord.trainingDurationMinutes = Int32(course.estimatedDurationMin)
            trainingRecord.trainerName = "Test Trainer \(index + 1)"
            trainingRecord.languageProvided = "English"
            trainingRecord.complianceCategory = course.complianceCategory
        }
        
        try context.save()
        
        // Verify both trainings are assigned
        let trainingRecords = worker.trainingRecords?.allObjects as? [TrainingRecord] ?? []
        XCTAssertEqual(trainingRecords.count, 2)
        
        // Verify different trainers
        let trainerNames = Set(trainingRecords.compactMap { $0.trainerName })
        XCTAssertEqual(trainerNames.count, 2)
    }
    
    // MARK: - Compliance Category Tests
    
    func testComplianceCategoryFiltering() throws {
        // Create training records for different compliance categories
        let fsmaRecord = TrainingRecord(context: context)
        fsmaRecord.trainingID = UUID()
        fsmaRecord.worker = worker
        fsmaRecord.trainingCourse = trainingCourse
        fsmaRecord.trainingDate = Date()
        fsmaRecord.passStatus = true
        fsmaRecord.complianceCategory = ComplianceCategory.fsma.rawValue
        
        let organicRecord = TrainingRecord(context: context)
        organicRecord.trainingID = UUID()
        organicRecord.worker = worker
        organicRecord.trainingDate = Date()
        organicRecord.passStatus = true
        organicRecord.complianceCategory = ComplianceCategory.organicCertification.rawValue
        
        try context.save()
        
        // Test filtering by compliance category
        let request: NSFetchRequest<TrainingRecord> = TrainingRecord.fetchRequest()
        request.predicate = NSPredicate(format: "complianceCategory == %@", ComplianceCategory.fsma.rawValue)
        
        let fsmaRecords = try context.fetch(request)
        XCTAssertEqual(fsmaRecords.count, 1)
        XCTAssertEqual(fsmaRecords.first?.complianceCategoryEnum, .fsma)
    }
    
    // MARK: - Training Record Extension Tests
    
    func testTrainingRecordEnumConversions() throws {
        let trainingRecord = TrainingRecord(context: context)
        trainingRecord.complianceCategory = ComplianceCategory.osha.rawValue
        trainingRecord.trainingMethod = TrainingMethod.online.rawValue
        trainingRecord.comprehensionCheckMethod = ComprehensionCheckMethod.quiz.rawValue
        
        // Test enum conversions
        XCTAssertEqual(trainingRecord.complianceCategoryEnum, .osha)
        XCTAssertEqual(trainingRecord.trainingMethodEnum, .online)
        XCTAssertEqual(trainingRecord.comprehensionCheckMethodEnum, .quiz)
    }
}