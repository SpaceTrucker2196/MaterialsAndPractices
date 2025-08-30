//
//  WorkOrderTypeEnum.swift
//  MaterialsAndPractices
//
//  Defines common types of work orders on a farm for efficient task categorization
//  and management. Supports standardized work order creation workflows.
//
//  Created by GitHub Copilot on 12/18/24.
//

import Foundation

/// Enumeration of common work order types found on farms
/// Provides standardized categorization for agricultural tasks
enum WorkOrderType: String, CaseIterable {
    case planting = "planting"
    case weeding = "weeding"
    case watering = "watering"
    case harvesting = "harvesting"
    case soilPreparation = "soil_preparation"
    case fertilizing = "fertilizing"
    case pestApplication = "pest_application"
    case pruning = "pruning"
    case transplanting = "transplanting"
    case mulching = "mulching"
    case cultivating = "cultivating"
    case thinning = "thinning"
    case irrigation = "irrigation"
    case fieldMaintenance = "field_maintenance"
    case equipmentMaintenance = "equipment_maintenance"
    case inspection = "inspection"
    case packaging = "packaging"
    case cleaning = "cleaning"
    case recordKeeping = "record_keeping"
    case other = "other"
    
    /// Display name for the work order type
    var displayName: String {
        switch self {
        case .planting: return "Planting"
        case .weeding: return "Weeding"
        case .watering: return "Watering"
        case .harvesting: return "Harvesting"
        case .soilPreparation: return "Soil Preparation"
        case .fertilizing: return "Fertilizing"
        case .pestApplication: return "Pest Application"
        case .pruning: return "Pruning"
        case .transplanting: return "Transplanting"
        case .mulching: return "Mulching"
        case .cultivating: return "Cultivating"
        case .thinning: return "Thinning"
        case .irrigation: return "Irrigation"
        case .fieldMaintenance: return "Field Maintenance"
        case .equipmentMaintenance: return "Equipment Maintenance"
        case .inspection: return "Inspection"
        case .packaging: return "Packaging"
        case .cleaning: return "Cleaning"
        case .recordKeeping: return "Record Keeping"
        case .other: return "Other"
        }
    }
    
    /// Emoji representation for visual identification
    var emoji: String {
        switch self {
        case .planting: return "🌱"
        case .weeding: return "🌿"
        case .watering: return "💧"
        case .harvesting: return "🌾"
        case .soilPreparation: return "🏞️"
        case .fertilizing: return "🧪"
        case .pestApplication: return "🚿"
        case .pruning: return "✂️"
        case .transplanting: return "🪴"
        case .mulching: return "🍂"
        case .cultivating: return "⚒️"
        case .thinning: return "🌿"
        case .irrigation: return "🚰"
        case .fieldMaintenance: return "🔧"
        case .equipmentMaintenance: return "⚙️"
        case .inspection: return "🔍"
        case .packaging: return "📦"
        case .cleaning: return "🧹"
        case .recordKeeping: return "📝"
        case .other: return "📋"
        }
    }
    
    /// Display text with emoji for picker presentation
    var displayWithEmoji: String {
        return "\(emoji) \(displayName)"
    }
}