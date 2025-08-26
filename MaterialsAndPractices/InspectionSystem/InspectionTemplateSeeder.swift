//
//  InspectionTemplateSeeder.swift
//  MaterialsAndPractices
//
//  Generates markdown inspection templates from the existing inspection seeder data.
//  Creates comprehensive inspection templates with parsable variables and checklist
//  items organized by sections and rows for systematic inspection workflows.
//
//  Created by GitHub Copilot on 12/19/24.
//

import Foundation
import CoreData

/// Seeds inspection templates as markdown files with parsable variables
/// Converts existing inspection data into structured markdown templates
class InspectionTemplateSeeder {
    
    // MARK: - Properties
    
    private let directoryManager = InspectionDirectoryManager.shared
    
    // MARK: - Public Methods
    
    /// Seeds all inspection templates if the templates directory is empty
    func seedTemplatesIfNeeded() {
        let existingTemplates = directoryManager.listFiles(in: .templates)
        
        if existingTemplates.isEmpty {
            print("🌱 Seeding inspection templates...")
            seedAllOrganicComplianceTemplates()
        } else {
            print("📋 Inspection templates already exist: \(existingTemplates.count) templates found")
        }
    }
    
    // MARK: - Template Generation
    
    /// Seeds all organic compliance inspection templates
    private func seedAllOrganicComplianceTemplates() {
        let templateData = [
            ("Soil_Fertility_Management", soilFertilityTemplate()),
            ("Pest_Management_Compliance", pestManagementTemplate()),
            ("Seeds_and_Planting_Materials", seedAndPlantingTemplate()),
            ("Harvest_and_Storage", harvestAndStorageTemplate()),
            ("Record_Keeping_Compliance", recordKeepingTemplate()),
            ("Buffer_Zone_Compliance", bufferZoneTemplate()),
            ("Water_Quality_Management", waterQualityTemplate()),
            ("Equipment_Cleanliness", equipmentCleanlinessTemplate()),
            ("Organic_System_Integrity", organicIntegrityTemplate()),
            ("Certification_Compliance", certificationComplianceTemplate())
        ]
        
        for (fileName, content) in templateData {
            saveTemplateToFile(fileName: fileName, content: content)
        }
        
        print("✅ Successfully seeded \(templateData.count) inspection templates")
    }
    
    /// Saves a template to the templates directory
    /// - Parameters:
    ///   - fileName: Name of the template file
    ///   - content: Markdown content of the template
    private func saveTemplateToFile(fileName: String, content: String) {
        let templateURL = directoryManager.directoryURL(for: .templates).appendingPathComponent("\(fileName).md")
        
        do {
            try content.write(to: templateURL, atomically: true, encoding: .utf8)
            print("📝 Created template: \(fileName).md")
        } catch {
            print("❌ Error creating template \(fileName): \(error)")
        }
    }
    
    // MARK: - Template Content Generation
    
    /// Generates soil fertility management inspection template
    private func soilFertilityTemplate() -> String {
        return """
# Soil Fertility Management Inspection

**Template Version:** 1.0
**Category:** Grow
**Inspection Type:** Soil Fertility Management
**Requirement Level:** Critical for Organic Certification

## Template Variables
- `{{inspection_id}}` - Unique inspection identifier
- `{{inspection_date}}` - Date of inspection
- `{{inspector_name}}` - Name of inspector
- `{{farm_name}}` - Name of farm being inspected
- `{{field_name}}` - Specific field if applicable
- `{{lot_id}}` - Lot tracking identifier

## Inspection Overview
This inspection verifies compliance with organic soil fertility and management standards, ensuring proper soil health maintenance and organic amendment usage.

## Section 1: Soil Testing and Analysis
### 1.1 Current Soil Test Results
- [ ] **[CRITICAL]** Soil test results current within 3 years
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 1.2 Organic Matter Content
- [ ] **[CRITICAL]** Organic matter content meets minimum requirements (>3%)
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 1.3 pH and Nutrient Levels
- [ ] **[MEDIUM]** pH levels appropriate for planned crops (6.0-7.0)
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[LOW]** Micronutrient levels adequate
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 2: Fertilizer and Amendment Compliance
### 2.1 Prohibited Substances
- [ ] **[CRITICAL]** Prohibited synthetic fertilizers not used
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[CRITICAL]** Soil amendment sources verified organic
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 2.2 Composting Procedures
- [ ] **[HIGH]** Composting procedures follow organic standards
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 3: Soil Building Practices
### 3.1 Cover Crops and Rotation
- [ ] **[MEDIUM]** Cover crops used for soil building
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[HIGH]** Crop rotation plan documented and followed
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 3.2 Green Manure and Tillage
- [ ] **[MEDIUM]** Green manure crops incorporated properly
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[MEDIUM]** Tillage practices minimize soil disturbance
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 4: Erosion Control
### 4.1 Erosion Prevention
- [ ] **[MEDIUM]** Soil erosion control measures in place
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Inspector Summary
**Total Items:** 12
**Critical Items:** 3
**High Priority Items:** 2
**Medium Priority Items:** 6
**Low Priority Items:** 1

**Overall Compliance Status:** ⬜ Pass ⬜ Conditional ⬜ Fail
**Inspector Signature:** _________________________
**Date Completed:** ____________________
"""
    }
    
    /// Generates pest management compliance inspection template
    private func pestManagementTemplate() -> String {
        return """
# Pest Management Compliance Inspection

**Template Version:** 1.0
**Category:** Grow
**Inspection Type:** Pest Management Compliance
**Requirement Level:** Critical for Organic Certification

## Template Variables
- `{{inspection_id}}` - Unique inspection identifier
- `{{inspection_date}}` - Date of inspection
- `{{inspector_name}}` - Name of inspector
- `{{farm_name}}` - Name of farm being inspected
- `{{field_name}}` - Specific field if applicable
- `{{lot_id}}` - Lot tracking identifier

## Inspection Overview
This inspection ensures compliance with organic pest and disease management standards, verifying proper implementation of Integrated Pest Management (IPM) principles.

## Section 1: IPM Plan and Documentation
### 1.1 IPM Plan Requirements
- [ ] **[CRITICAL]** Integrated Pest Management plan documented
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[HIGH]** Pest monitoring records current
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 1.2 Emergency Protocols
- [ ] **[MEDIUM]** Emergency treatment protocols documented
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 2: Pesticide Compliance
### 2.1 Prohibited Substances
- [ ] **[CRITICAL]** Prohibited pesticides not used or stored
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 2.2 Approved Pesticides
- [ ] **[CRITICAL]** Organic-approved pesticides properly documented
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[HIGH]** Application records complete and accurate
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 3: Alternative Control Methods
### 3.1 Biological Controls
- [ ] **[MEDIUM]** Biological control methods implemented
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[LOW]** Beneficial insect habitats maintained
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 3.2 Cultural and Mechanical Controls
- [ ] **[MEDIUM]** Cultural control practices in use
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[MEDIUM]** Mechanical control methods employed
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 4: Buffer Zones and Equipment
### 4.1 Contamination Prevention
- [ ] **[CRITICAL]** Buffer zones maintained from conventional treatments
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 4.2 Equipment Management
- [ ] **[HIGH]** Equipment cleaning records for pesticide application
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Inspector Summary
**Total Items:** 12
**Critical Items:** 4
**High Priority Items:** 3
**Medium Priority Items:** 4
**Low Priority Items:** 1

**Overall Compliance Status:** ⬜ Pass ⬜ Conditional ⬜ Fail
**Inspector Signature:** _________________________
**Date Completed:** ____________________
"""
    }
    
    /// Generates equipment cleanliness inspection template
    private func equipmentCleanlinessTemplate() -> String {
        return """
# Equipment Cleanliness Inspection

**Template Version:** 1.0
**Category:** Equipment
**Inspection Type:** Equipment Cleanliness
**Requirement Level:** Critical for Organic Certification

## Template Variables
- `{{inspection_id}}` - Unique inspection identifier
- `{{inspection_date}}` - Date of inspection
- `{{inspector_name}}` - Name of inspector
- `{{farm_name}}` - Name of farm being inspected
- `{{equipment_name}}` - Specific equipment being inspected
- `{{lot_id}}` - Lot tracking identifier

## Inspection Overview
This inspection verifies that all farm equipment meets organic cleanliness standards and prevents cross-contamination between organic and conventional operations.

## Section 1: Cleaning Procedures
### 1.1 Cleaning Protocols
- [ ] **[CRITICAL]** Cleaning procedures prevent cross-contamination
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[CRITICAL]** Cleaning materials approved for organic use
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 1.2 Shared Equipment Protocols
- [ ] **[HIGH]** Shared equipment cleaning protocols followed
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 2: Equipment Storage and Maintenance
### 2.1 Storage Conditions
- [ ] **[HIGH]** Equipment storage prevents contamination
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

- [ ] **[MEDIUM]** Storage areas clean and organized
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 2.2 Maintenance Records
- [ ] **[MEDIUM]** Maintenance records complete and current
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 3: Harvest Equipment
### 3.1 Harvest Cleanliness
- [ ] **[HIGH]** Harvest equipment cleaned between uses
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 3.2 Application Equipment
- [ ] **[MEDIUM]** Application equipment properly calibrated
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Section 4: Personal Equipment
### 4.1 Safety Equipment
- [ ] **[MEDIUM]** Personal protective equipment clean and functional
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

### 4.2 Tool Management
- [ ] **[LOW]** Tool and equipment inventory current
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

## Inspector Summary
**Total Items:** 10
**Critical Items:** 2
**High Priority Items:** 3
**Medium Priority Items:** 4
**Low Priority Items:** 1

**Overall Compliance Status:** ⬜ Pass ⬜ Conditional ⬜ Fail
**Inspector Signature:** _________________________
**Date Completed:** ____________________
"""
    }
    
    // MARK: - Additional Template Methods
    
    /// Creates seed and planting template
    private func seedAndPlantingTemplate() -> String {
        return createStandardTemplate(
            title: "Seeds and Planting Materials Inspection",
            category: "Grow",
            type: "Seeds and Planting Materials",
            items: [
                ("CRITICAL", "Organic seed sources documented and verified"),
                ("CRITICAL", "Non-organic seed use justified and documented"),
                ("CRITICAL", "Treated seed prohibition compliance"),
                ("CRITICAL", "GMO-free verification for all seeds"),
                ("HIGH", "Transplant production follows organic standards"),
                ("MEDIUM", "Seed storage prevents contamination"),
                ("MEDIUM", "Variety selection appropriate for organic system"),
                ("MEDIUM", "Seed testing records available"),
                ("HIGH", "Propagation methods comply with standards"),
                ("HIGH", "Seedling media approved for organic use")
            ]
        )
    }
    
    private func harvestAndStorageTemplate() -> String {
        return createStandardTemplate(
            title: "Harvest and Storage Inspection",
            category: "Infrastructure",
            type: "Harvest and Storage",
            items: [
                ("CRITICAL", "Harvest equipment clean and contamination-free"),
                ("CRITICAL", "Storage facilities prevent organic/conventional mixing"),
                ("CRITICAL", "Post-harvest treatments comply with organic standards"),
                ("HIGH", "Processing aids approved for organic use"),
                ("HIGH", "Cleaning and sanitizing procedures documented"),
                ("MEDIUM", "Packaging materials meet organic requirements"),
                ("MEDIUM", "Temperature and humidity control systems functional"),
                ("HIGH", "Pest control in storage areas organic-compliant"),
                ("HIGH", "Traceability systems in place"),
                ("MEDIUM", "Quality control procedures documented")
            ]
        )
    }
    
    private func recordKeepingTemplate() -> String {
        return createStandardTemplate(
            title: "Record Keeping Compliance Inspection",
            category: "Organic Management",
            type: "Record Keeping Compliance",
            items: [
                ("CRITICAL", "Production records complete for past 3 years"),
                ("CRITICAL", "Input purchase receipts and documentation"),
                ("CRITICAL", "Application records with dates, rates, and areas"),
                ("HIGH", "Harvest records with quantities and dates"),
                ("HIGH", "Sales records with buyer information"),
                ("MEDIUM", "Land use history documented"),
                ("MEDIUM", "Equipment cleaning logs maintained"),
                ("MEDIUM", "Training records for staff"),
                ("HIGH", "Inspection and audit records filed"),
                ("CRITICAL", "Organic system plan current and implemented"),
                ("HIGH", "Change notifications submitted timely"),
                ("MEDIUM", "Financial records support organic premium")
            ]
        )
    }
    
    private func bufferZoneTemplate() -> String {
        return createStandardTemplate(
            title: "Buffer Zone Compliance Inspection",
            category: "Infrastructure",
            type: "Buffer Zone Compliance",
            items: [
                ("CRITICAL", "Adequate buffer zones established and maintained"),
                ("CRITICAL", "Drift prevention measures in place"),
                ("HIGH", "Neighboring land use documented"),
                ("MEDIUM", "Buffer zone vegetation managed organically"),
                ("MEDIUM", "Physical barriers effective where needed"),
                ("MEDIUM", "Communication with neighbors documented"),
                ("HIGH", "Monitoring for contamination incidents"),
                ("HIGH", "Emergency response plan for contamination"),
                ("CRITICAL", "Buffer zone width adequate for all sources"),
                ("LOW", "Seasonal management of buffer areas")
            ]
        )
    }
    
    private func waterQualityTemplate() -> String {
        return createStandardTemplate(
            title: "Water Quality Management Inspection",
            category: "Infrastructure",
            type: "Water Quality Management",
            items: [
                ("CRITICAL", "Water source testing results current"),
                ("CRITICAL", "Irrigation water meets organic standards"),
                ("MEDIUM", "Water conservation practices implemented"),
                ("HIGH", "Runoff prevention measures in place"),
                ("MEDIUM", "Water storage systems clean and maintained"),
                ("HIGH", "Cross-contamination prevention in water systems"),
                ("MEDIUM", "Drainage systems prevent standing water"),
                ("MEDIUM", "Well head protection adequate"),
                ("MEDIUM", "Water distribution system integrity maintained"),
                ("LOW", "Emergency water supply plan documented")
            ]
        )
    }
    
    private func organicIntegrityTemplate() -> String {
        return createStandardTemplate(
            title: "Organic System Integrity Inspection",
            category: "Organic Management",
            type: "Organic System Integrity",
            items: [
                ("CRITICAL", "Organic system plan implemented as written"),
                ("CRITICAL", "All inputs approved for organic production"),
                ("CRITICAL", "Prohibited substances not present on farm"),
                ("HIGH", "Organic practices consistently applied"),
                ("MEDIUM", "Staff training on organic requirements current"),
                ("HIGH", "Supplier verification procedures followed"),
                ("HIGH", "Change approval process followed"),
                ("MEDIUM", "Emergency use procedures documented"),
                ("LOW", "Continuous improvement processes in place"),
                ("CRITICAL", "Organic integrity maintained throughout system")
            ]
        )
    }
    
    private func certificationComplianceTemplate() -> String {
        return createStandardTemplate(
            title: "Certification Compliance Inspection",
            category: "Organic Management",
            type: "Certification Compliance",
            items: [
                ("CRITICAL", "Annual update submitted timely"),
                ("CRITICAL", "Certification fees current"),
                ("CRITICAL", "Previous inspection findings addressed"),
                ("HIGH", "Corrective actions implemented and documented"),
                ("HIGH", "Organic system plan reflects current operations"),
                ("HIGH", "Label compliance verified"),
                ("HIGH", "Sales documentation supports organic claims"),
                ("MEDIUM", "Inspector access procedures documented"),
                ("MEDIUM", "Emergency contact information current"),
                ("MEDIUM", "Certification documents displayed appropriately"),
                ("MEDIUM", "Complaint handling procedures in place"),
                ("CRITICAL", "Audit trail complete and verifiable")
            ]
        )
    }
    
    /// Creates a standard inspection template
    private func createStandardTemplate(
        title: String,
        category: String,
        type: String,
        items: [(priority: String, description: String)]
    ) -> String {
        var template = """
# \(title)

**Template Version:** 1.0
**Category:** \(category)
**Inspection Type:** \(type)
**Requirement Level:** Critical for Organic Certification

## Template Variables
- `{{inspection_id}}` - Unique inspection identifier
- `{{inspection_date}}` - Date of inspection
- `{{inspector_name}}` - Name of inspector
- `{{farm_name}}` - Name of farm being inspected
- `{{field_name}}` - Specific field if applicable
- `{{lot_id}}` - Lot tracking identifier

## Inspection Overview
This inspection verifies compliance with organic \(type.lowercased()) standards.

## Checklist Items

"""
        
        for (index, item) in items.enumerated() {
            let sectionNumber = (index / 3) + 1
            let itemNumber = (index % 3) + 1
            
            if index % 3 == 0 {
                template += "\n## Section \(sectionNumber): Items \(index + 1)-\(min(index + 3, items.count))\n"
            }
            
            template += """
### \(sectionNumber).\(itemNumber) \(item.description)
- [ ] **[\(item.priority)]** \(item.description)
  - **Notes:** ________________________________
  - **Completed:** ❌ **Time:** ________ **Inspector:** ________

"""
        }
        
        let criticalCount = items.filter { $0.priority == "CRITICAL" }.count
        let highCount = items.filter { $0.priority == "HIGH" }.count
        let mediumCount = items.filter { $0.priority == "MEDIUM" }.count
        let lowCount = items.filter { $0.priority == "LOW" }.count
        
        template += """

## Inspector Summary
**Total Items:** \(items.count)
**Critical Items:** \(criticalCount)
**High Priority Items:** \(highCount)
**Medium Priority Items:** \(mediumCount)
**Low Priority Items:** \(lowCount)

**Overall Compliance Status:** ⬜ Pass ⬜ Conditional ⬜ Fail
**Inspector Signature:** _________________________
**Date Completed:** ____________________
"""
        
        return template
    }
}