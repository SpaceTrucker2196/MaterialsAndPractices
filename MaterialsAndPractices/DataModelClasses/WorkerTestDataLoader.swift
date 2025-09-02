//
//  WorkerTestDataLoader.swift
//  MaterialsAndPractices
//
//  Test data loader for worker profiles from CSV file.
//  Provides functionality to load worker test data for development and testing.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CoreData
import UIKit

/// Test data loader for worker profiles
class WorkerTestDataLoader {
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    /// Load worker test data from CSV file
    func loadWorkerTestData() throws {
        // Clear existing workers first
        try clearExistingWorkers()
        
        // Load CSV data
        guard let csvPath = Bundle.main.path(forResource: "Zappa_Worker_Profiles_with_ProfilePhotoData", ofType: "csv"),
              let csvContent = try? String(contentsOfFile: csvPath) else {
            throw WorkerTestDataError.csvFileNotFound
        }
        
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw WorkerTestDataError.invalidCSVFormat
        }
        
        // Parse header to get column indices
        let headers = parseCSVLine(lines[0])
        let columnMap = createColumnMap(headers: headers)
        
        // Process each worker row
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty {
                try createWorkerFromCSVLine(line, columnMap: columnMap)
            }
        }
        
        // Save the context
        try viewContext.save()
        
        print("✅ Successfully loaded \(lines.count - 1) test workers")
    }
    
    /// Clear all existing workers
    private func clearExistingWorkers() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Worker.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        try viewContext.execute(deleteRequest)
        try viewContext.save()
        
        print("🗑️ Cleared existing workers")
    }
    
    /// Parse CSV line handling quoted fields
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
    
    /// Create column mapping from headers
    private func createColumnMap(headers: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            map[header.lowercased()] = index
        }
        return map
    }
    
    /// Create worker from CSV line
    private func createWorkerFromCSVLine(_ line: String, columnMap: [String: Int]) throws {
        let fields = parseCSVLine(line)
        
        let worker = Worker(context: viewContext)
        worker.id = UUID()
        
        // Map basic fields
        if let nameIndex = columnMap["name"], nameIndex < fields.count {
            worker.name = fields[nameIndex]
        }
        
        if let positionIndex = columnMap["position"], positionIndex < fields.count {
            worker.position = fields[positionIndex]
        }
        
        if let emailIndex = columnMap["email"], emailIndex < fields.count {
            worker.email = fields[emailIndex]
        }
        
        if let phoneIndex = columnMap["phone"], phoneIndex < fields.count {
            worker.phone = fields[phoneIndex]
        }
        
        if let notesIndex = columnMap["notes"], notesIndex < fields.count {
            worker.notes = fields[notesIndex]
        }
        
        if let isActiveIndex = columnMap["isactive"], isActiveIndex < fields.count {
            worker.isActive = fields[isActiveIndex].lowercased() == "true"
        } else {
            worker.isActive = true
        }
        
        if let canInspectIndex = columnMap["caninspect"], canInspectIndex < fields.count {
            worker.canInspect = fields[canInspectIndex].lowercased() == "true"
        }
        
        // Map emergency contact fields
        if let emergencyContactIndex = columnMap["emergancycontact"], emergencyContactIndex < fields.count {
            worker.emergencyContact = fields[emergencyContactIndex]
        }
        
        if let emergencyPhoneIndex = columnMap["emergancyphone"], emergencyPhoneIndex < fields.count {
            worker.emergencyPhone = fields[emergencyPhoneIndex]
        }
        
        // Map new emoji and symbol fields
        if let emojiIndex = columnMap["emoji"], emojiIndex < fields.count {
            worker.emoji = fields[emojiIndex]
        }
        
        if let symbolIndex = columnMap["symbol"], symbolIndex < fields.count {
            worker.iosSymbol = fields[symbolIndex]
        }
        
        // Set random imagePath for test worker
       // worker.imagePath = ZappaProfile.getRandomImagePath()
        
        // Parse hire date
        if let hireDateIndex = columnMap["hiredate"], hireDateIndex < fields.count {
            let dateString = fields[hireDateIndex]
            if !dateString.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                worker.hireDate = formatter.date(from: dateString)
            }
        }
        
        // Load profile photo if available
        if let photoIndex = columnMap["profilephotodata"], photoIndex < fields.count {
            let photoFilename = fields[photoIndex]
            if !photoFilename.isEmpty {
                
                if let url = Bundle.main.url(forResource: photoFilename, withExtension: "png", subdirectory: "PhotoLibrary") {
                    worker.imagePath = url.absoluteString
                } else if  let url = Bundle.main.url(forResource: photoFilename, withExtension: "jpeg", subdirectory: "PhotoLibrary") {
                    worker.imagePath = url.absoluteString
                } else if let url = Bundle.main.url(forResource: photoFilename, withExtension: "jpg", subdirectory: "PhotoLibrary") {
                    worker.imagePath = url.absoluteString
                }
                loadProfilePhoto(filename: worker.imagePath ?? "profile.jpg", for: worker)
            }
        }
    }
    
    
    
    /// Load profile photo from bundle resources
    private func loadProfilePhoto(filename: String, for worker: Worker) {
        // Create a simple placeholder image for now since we don't have the actual images
        let size = CGSize(width: 120, height: 120)
//        UIGraphicsBeginImageContextWithOptions(size, false, 0)
//        
//        // Draw a colored circle as placeholder
//        let rect = CGRect(origin: .zero, size: size)
//        let path = UIBezierPath(ovalIn: rect)
//        
//        // Use worker name hash to generate consistent colors
//        let nameHash = worker.name?.hashValue ?? 0
//        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemRed, .systemYellow]
//        let color = colors[abs(nameHash) % colors.count]
//        
//        color.setFill()
//        path.fill()
//        
//        // Add text overlay with initials
//        if let name = worker.name {
//            let components = name.components(separatedBy: " ")
//            let initials = components.compactMap { $0.first }.prefix(2).map(String.init).joined()
//            
//            let attributes: [NSAttributedString.Key: Any] = [
//                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
//                .foregroundColor: UIColor.white
//            ]
//            
//            let textSize = initials.size(withAttributes: attributes)
//            let textRect = CGRect(
//                x: (size.width - textSize.width) / 2,
//                y: (size.height - textSize.height) / 2,
//                width: textSize.width,
//                height: textSize.height
//            )
//            
//            initials.draw(in: textRect, withAttributes: attributes)
//        }
//        
//        //let image = UIGraphicsGetImageFromCurrentImageContext()
//       // UIGraphicsEndImageContext()
        let image = UIImage(contentsOfFile: filename)
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.7) {
            worker.profilePhotoData = imageData
        }
    }
}

/// Errors for worker test data loading
enum WorkerTestDataError: LocalizedError {
    case csvFileNotFound
    case invalidCSVFormat
    case dataProcessingError(String)
    
    var errorDescription: String? {
        switch self {
        case .csvFileNotFound:
            return "CSV file not found in bundle resources"
        case .invalidCSVFormat:
            return "Invalid CSV format"
        case .dataProcessingError(let message):
            return "Data processing error: \(message)"
        }
    }
}
