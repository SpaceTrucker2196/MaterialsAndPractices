//
//  GrowExtensions.swift
//  MaterialsAndPractices
//
//  Created by Jeffrey Kunzelman on 9/1/25.
//
import Foundation

extension Grow {
    var daysSincePlanting: Int? {
        guard let plantedDate = plantedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: plantedDate, to: Date()).day
    }
}
