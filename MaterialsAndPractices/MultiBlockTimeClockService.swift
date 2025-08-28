//
//  MultiBlockTimeClockService.swift
//  MaterialsAndPractices
//
//  Enhanced time clock service supporting multiple time blocks per day.
//  Allows workers to clock in and out multiple times during a single work day.
//

import Foundation
import CoreData

class MultiBlockTimeClockService {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Clock in a worker, creating a new time block for the day
    func clockIn(worker: Worker, date: Date = Date()) throws {
        // Check if worker is already clocked in for any block today
        if let activeBlock = getActiveTimeBlock(for: worker, on: date) {
            throw TimeClockError.alreadyClockedIn
        }
        
        // Get the next block number for this day
        let blockNumber = getNextBlockNumber(for: worker, on: date)
        
        // Create new time block
        let timeEntry = TimeClock(context: context)
        timeEntry.id = UUID()
        timeEntry.worker = worker
        timeEntry.date = Calendar.current.startOfDay(for: date)
        timeEntry.clockInTime = date
        timeEntry.isActive = true
        timeEntry.blockNumber = Int16(blockNumber)
        
        // Set week and year for tracking
        let calendar = Calendar.current
        timeEntry.year = Int16(calendar.component(.yearForWeekOfYear, from: date))
        timeEntry.weekNumber = Int16(calendar.component(.weekOfYear, from: date))
        
        try context.save()
    }
    
    /// Clock out a worker from their active time block
    func clockOut(worker: Worker, date: Date = Date()) throws {
        guard let activeBlock = getActiveTimeBlock(for: worker, on: date) else {
            throw TimeClockError.notClockedIn
        }
        
        activeBlock.clockOutTime = date
        activeBlock.isActive = false
        
        // Calculate hours worked for this block
        if let clockInTime = activeBlock.clockInTime {
            let interval = date.timeIntervalSince(clockInTime)
            activeBlock.hoursWorked = interval / 3600.0 // Convert to hours
        }
        
        try context.save()
    }
    
    /// Get all time blocks for a worker on a specific date
    func getTimeBlocks(for worker: Worker, on date: Date) -> [TimeClock] {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(format: "worker == %@ AND date >= %@ AND date < %@", worker, dayStart as NSDate, dayEnd as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeClock.blockNumber, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching time blocks: \(error)")
            return []
        }
    }
    
    /// Get the active time block for a worker (currently clocked in)
    func getActiveTimeBlock(for worker: Worker, on date: Date) -> TimeClock? {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        let request: NSFetchRequest<TimeClock> = TimeClock.fetchRequest()
        request.predicate = NSPredicate(format: "worker == %@ AND date >= %@ AND date < %@ AND isActive == YES", 
                                      worker, dayStart as NSDate, dayEnd as NSDate)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching active time block: \(error)")
            return nil
        }
    }
    
    /// Get total hours worked for a worker on a specific date (all blocks combined)
    func getTotalHoursWorked(for worker: Worker, on date: Date) -> Double {
        let timeBlocks = getTimeBlocks(for: worker, on: date)
        return timeBlocks.reduce(0) { total, block in
            if block.isActive {
                // Calculate current hours for active block
                if let clockInTime = block.clockInTime {
                    let currentHours = Date().timeIntervalSince(clockInTime) / 3600.0
                    return total + currentHours
                }
            }
            return total + block.hoursWorked
        }
    }
    
    /// Get the next block number for a worker on a specific date
    private func getNextBlockNumber(for worker: Worker, on date: Date) -> Int {
        let existingBlocks = getTimeBlocks(for: worker, on: date)
        let maxBlockNumber = existingBlocks.map { Int($0.blockNumber) }.max() ?? 0
        return maxBlockNumber + 1
    }
    
    /// Check if a worker is currently clocked in
    func isWorkerClockedIn(_ worker: Worker) -> Bool {
        return getActiveTimeBlock(for: worker, on: Date()) != nil
    }
}

// MARK: - Time Clock Errors

enum TimeClockError: LocalizedError {
    case alreadyClockedIn
    case notClockedIn
    case invalidWorker
    case dataAccessError
    
    var errorDescription: String? {
        switch self {
        case .alreadyClockedIn:
            return "Worker is already clocked in"
        case .notClockedIn:
            return "Worker is not currently clocked in"
        case .invalidWorker:
            return "Invalid worker"
        case .dataAccessError:
            return "Error accessing time clock data"
        }
    }
}

// MARK: - TimeClock Extensions for Multiple Blocks

extension TimeClock {
    
    /// Format the time block for display (e.g., "Block 1: 7:00 AM - 10:00 AM")
    var formattedTimeBlock: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let blockText = "Block \(blockNumber)"
        
        if let clockIn = clockInTime {
            let clockInText = formatter.string(from: clockIn)
            
            if let clockOut = clockOutTime {
                let clockOutText = formatter.string(from: clockOut)
                return "\(blockText): \(clockInText) - \(clockOutText)"
            } else if isActive {
                return "\(blockText): \(clockInText) - Active"
            } else {
                return "\(blockText): \(clockInText) - Not completed"
            }
        }
        
        return "\(blockText): No time recorded"
    }
    
    /// Get the duration of this time block as a formatted string
    var formattedDuration: String {
        if isActive, let clockInTime = clockInTime {
            let currentDuration = Date().timeIntervalSince(clockInTime) / 3600.0
            return String(format: "%.1f hours", currentDuration)
        } else {
            return String(format: "%.1f hours", hoursWorked)
        }
    }
}