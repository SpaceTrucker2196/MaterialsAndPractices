//
//  LeaseTemplateSeeder.swift
//  MaterialsAndPractices
//
//  Generates markdown lease templates from common agricultural lease agreements.
//  Creates comprehensive lease templates with parsable variables and payment
//  terms organized for systematic lease workflow management.
//
//  Created by GitHub Copilot on current date.
//

import Foundation
import CoreData

/// Seeds lease templates as markdown files with parsable variables
/// Converts common agricultural lease examples into structured markdown templates
class LeaseTemplateSeeder {
    
    // MARK: - Properties
    
    private let directoryManager = LeaseDirectoryManager.shared
    
    // MARK: - Public Methods
    
    /// Seeds all lease templates if the templates directory is empty
    func seedTemplatesIfNeeded() {
        let existingTemplates = directoryManager.listFiles(in: .templates)
        
        if existingTemplates.isEmpty {
            print("🌱 Seeding lease templates...")
            seedAllAgriculturalLeaseTemplates()
        } else {
            print("📋 Lease templates already exist: \(existingTemplates.count) templates found")
        }
    }
    
    // MARK: - Template Generation
    
    /// Seeds all agricultural lease templates
    private func seedAllAgriculturalLeaseTemplates() {
        let templateData = [
            ("Cash_Rent_Agricultural_Lease", cashRentTemplate()),
            ("Crop_Share_Agricultural_Lease", cropShareTemplate()),
            ("Flexible_Cash_Rent_Lease", flexibleCashRentTemplate()),
            ("Pasture_Grazing_Lease", pastureGrazingTemplate()),
            ("Custom_Farming_Agreement", customFarmingTemplate())
        ]
        
        for (fileName, content) in templateData {
            saveTemplateToFile(fileName: fileName, content: content)
        }
        
        print("✅ Successfully seeded \(templateData.count) lease templates")
    }
    
    /// Saves a template to the templates directory
    /// - Parameters:
    ///   - fileName: Name of the template file
    ///   - content: Markdown content of the template
    private func saveTemplateToFile(fileName: String, content: String) {
        let templateURL = directoryManager.directoryURL(for: .templates).appendingPathComponent("\(fileName).md")
        
        do {
            try content.write(to: templateURL, atomically: true, encoding: .utf8)
            print("📝 Created lease template: \(fileName).md")
        } catch {
            print("❌ Error creating lease template \(fileName): \(error)")
        }
    }
    
    // MARK: - Template Content Generation
    
    /// Generates cash rent agricultural lease template
    private func cashRentTemplate() -> String {
        return """
# Cash Rent Agricultural Lease Agreement

**Template Version:** 1.0
**Lease Type:** Cash Rent
**Growing Year:** {{growing_year}}

## Template Variables
- `{{lease_id}}` - Unique lease identifier
- `{{property_name}}` - Name of the leased property
- `{{farmer_name}}` - Name of the farmer/tenant
- `{{growing_year}}` - Growing season year
- `{{start_date}}` - Lease start date
- `{{end_date}}` - Lease end date
- `{{rent_amount}}` - Total rent amount
- `{{rent_frequency}}` - Payment frequency

## Lease Overview
This lease agreement establishes a cash rent arrangement for agricultural land for the growing season of {{growing_year}}.

## Section 1: Parties and Property
### 1.1 Landlord/Owner Information
- **Property Owner:** [To be filled]
- **Contact Information:** [To be filled]
- **Address:** [To be filled]

### 1.2 Tenant/Farmer Information  
- **Farmer/Tenant:** {{farmer_name}}
- **Contact Information:** [To be filled]
- **Business Name:** [To be filled]

### 1.3 Property Description
- **Property Name:** {{property_name}}
- **Legal Description:** [To be filled]
- **Total Acres:** [To be filled]
- **Tillable Acres:** [To be filled]

## Section 2: Lease Terms
### 2.1 Lease Period
- **Start Date:** {{start_date}}
- **End Date:** {{end_date}}
- **Growing Season:** {{growing_year}}

### 2.2 Rent and Payment Terms
- **Total Annual Rent:** ${{rent_amount}}
- **Payment Frequency:** {{rent_frequency}}
- **Payment Due Dates:** 
  - [ ] March 1st: $______
  - [ ] September 1st: $______
- **Late Payment Fee:** [To be specified]
- **Payment Method:** [Check/Electronic Transfer]

### 2.3 Payment Schedule Tracking
- [ ] **Q1 Payment Due:** March 1, {{growing_year}} - Amount: $______
  - **Status:** ❌ **Paid Date:** ________ **Amount:** $________
- [ ] **Q2 Payment Due:** June 1, {{growing_year}} - Amount: $______  
  - **Status:** ❌ **Paid Date:** ________ **Amount:** $________
- [ ] **Q3 Payment Due:** September 1, {{growing_year}} - Amount: $______
  - **Status:** ❌ **Paid Date:** ________ **Amount:** $________
- [ ] **Q4 Payment Due:** December 1, {{growing_year}} - Amount: $______
  - **Status:** ❌ **Paid Date:** ________ **Amount:** $________

## Section 3: Property Use and Restrictions
### 3.1 Permitted Uses
- [ ] **Row Crop Production** - Corn, soybeans, etc.
- [ ] **Small Grain Production** - Wheat, oats, barley
- [ ] **Hay Production** - Alfalfa, timothy, clover
- [ ] **Pasture/Grazing** - Livestock grazing operations
- [ ] **Other:** [Specify]

### 3.2 Restrictions
- [ ] **No Tillage of CRP/Wetlands** without written permission
- [ ] **Organic Certification Compliance** if applicable
- [ ] **Conservation Practice Requirements** [Specify]
- [ ] **Chemical Application Restrictions** [Specify]

## Section 4: Responsibilities
### 4.1 Landlord Responsibilities
- [ ] **Property Tax Payment**
- [ ] **Major Infrastructure Maintenance**
- [ ] **Insurance on Buildings/Structures**
- [ ] **Drainage System Maintenance**

### 4.2 Tenant Responsibilities  
- [ ] **All Farming Operations**
- [ ] **Field Maintenance and Upkeep**
- [ ] **Weed Control and Pest Management**
- [ ] **Liability Insurance Coverage**
- [ ] **Compliance with Conservation Plans**

## Section 5: Field Management
### 5.1 Fields Included in Lease
- [ ] **Field 1:** _____ acres - Crop: ________
- [ ] **Field 2:** _____ acres - Crop: ________
- [ ] **Field 3:** _____ acres - Crop: ________
- [ ] **Additional Fields:** [List as needed]

### 5.2 Fields NOT Included in Lease
- [ ] **Excluded Field 1:** _____ acres - Reason: ________
- [ ] **Excluded Field 2:** _____ acres - Reason: ________

## Section 6: Conservation and Environmental
### 6.1 Conservation Compliance
- [ ] **Soil Conservation Plan** - Current and followed
- [ ] **NRCS Compliance** - All requirements met
- [ ] **Buffer Strip Maintenance** - Required widths maintained
- [ ] **Erosion Control Measures** - Implemented as needed

### 6.2 Environmental Stewardship
- [ ] **Chemical Application Records** - Maintained and available
- [ ] **Nutrient Management Plan** - Following current recommendations
- [ ] **Water Quality Protection** - Best practices implemented

## Section 7: Lease Termination and Renewal
### 7.1 Termination Notice
- **Notice Period:** [30/60/90 days]
- **Termination Date Options:** [End of growing season]

### 7.2 Renewal Options
- [ ] **Automatic Renewal** - Unless notice given
- [ ] **Negotiated Renewal** - Terms to be renegotiated
- [ ] **Right of First Refusal** - Tenant has first option

## Payment Record Keeping
### Growing Year {{growing_year}} Payment History
| Payment Date | Amount | Payment Method | Receipt # | Notes |
|--------------|--------|----------------|-----------|--------|
| | $ | | | |
| | $ | | | |
| | $ | | | |
| | $ | | | |

**Total Payments Received:** $______
**Balance Due:** $______

## Signatures and Date
**Landlord Signature:** ________________________________ **Date:** ________

**Tenant Signature:** __________________________________ **Date:** ________

**Witness Signature:** _________________________________ **Date:** ________

---
*This lease agreement is generated for the {{growing_year}} growing season and should be reviewed by legal counsel before execution.*
"""
    }
    
    /// Generates crop share agricultural lease template
    private func cropShareTemplate() -> String {
        return """
# Crop Share Agricultural Lease Agreement

**Template Version:** 1.0
**Lease Type:** Crop Share
**Growing Year:** {{growing_year}}

## Template Variables
- `{{lease_id}}` - Unique lease identifier
- `{{property_name}}` - Name of the leased property
- `{{farmer_name}}` - Name of the farmer/tenant
- `{{growing_year}}` - Growing season year
- `{{start_date}}` - Lease start date
- `{{end_date}}` - Lease end date

## Lease Overview
This crop share lease agreement establishes a percentage-based sharing arrangement for agricultural production for the growing season of {{growing_year}}.

## Section 1: Share Arrangement
### 1.1 Crop Share Percentages
- **Landlord Share:** _____%
- **Tenant Share:** _____%
- **Crops Covered:** All crops produced on leased acres

### 1.2 Expense Sharing
- **Seed Costs:** Landlord ____% / Tenant ____%
- **Fertilizer:** Landlord ____% / Tenant ____%
- **Chemical Costs:** Landlord ____% / Tenant ____%
- **Drying/Storage:** Landlord ____% / Tenant ____%
- **Crop Insurance:** Landlord ____% / Tenant ____%

## Section 2: Production and Marketing
### 2.1 Harvest Division
- [ ] **Physical Division** - Crops divided at harvest
- [ ] **Elevator Division** - Division at point of sale
- [ ] **Marketing Agreement** - Joint marketing decisions

### 2.2 Marketing Decisions
- [ ] **Joint Marketing** - Both parties must agree
- [ ] **Tenant Marketing** - Tenant has marketing authority
- [ ] **Landlord Consultation** - Tenant consults landlord

## Section 3: Payment Tracking (Share Payments)
### 3.1 Harvest Settlements
- [ ] **Corn Harvest Settlement** - Date: ________ 
  - **Total Bushels:** ________ **Landlord Share:** ________ **Value:** $________
- [ ] **Soybean Harvest Settlement** - Date: ________
  - **Total Bushels:** ________ **Landlord Share:** ________ **Value:** $________
- [ ] **Other Crop Settlement** - Date: ________
  - **Total Units:** ________ **Landlord Share:** ________ **Value:** $________

### 3.2 Cash Settlements (if applicable)
- [ ] **Q1 Cash Settlement:** $________ **Date:** ________
- [ ] **Q2 Cash Settlement:** $________ **Date:** ________
- [ ] **Q3 Cash Settlement:** $________ **Date:** ________
- [ ] **Q4 Cash Settlement:** $________ **Date:** ________

## Section 4: Record Keeping Requirements
### 4.1 Production Records
- [ ] **Yield Records** - Maintained by field and crop
- [ ] **Input Applications** - Fertilizer, chemical records
- [ ] **Harvest Documentation** - Scale tickets, moisture tests

### 4.2 Financial Records
- [ ] **Expense Documentation** - Receipts for shared costs
- [ ] **Marketing Records** - Sales documentation
- [ ] **Settlement Statements** - Annual profit/loss sharing

## Signatures and Date
**Landlord Signature:** ________________________________ **Date:** ________

**Tenant Signature:** __________________________________ **Date:** ________

---
*This crop share lease agreement is generated for the {{growing_year}} growing season.*
"""
    }
    
    /// Generates flexible cash rent lease template
    private func flexibleCashRentTemplate() -> String {
        return """
# Flexible Cash Rent Agricultural Lease Agreement

**Template Version:** 1.0
**Lease Type:** Flexible Cash Rent
**Growing Year:** {{growing_year}}

## Template Variables
- `{{lease_id}}` - Unique lease identifier
- `{{property_name}}` - Name of the leased property
- `{{farmer_name}}` - Name of the farmer/tenant
- `{{growing_year}}` - Growing season year
- `{{start_date}}` - Lease start date
- `{{end_date}}` - Lease end date
- `{{rent_amount}}` - Base rent amount

## Lease Overview
This flexible cash rent lease provides for rent adjustments based on commodity prices and/or yields for the growing season of {{growing_year}}.

## Section 1: Base Rent and Adjustments
### 1.1 Base Rent
- **Base Cash Rent:** ${{rent_amount}} per acre
- **Total Base Rent:** $________ (Base rent × total acres)

### 1.2 Price Adjustment Formula
- **Base Corn Price:** $________ per bushel
- **Base Soybean Price:** $________ per bushel
- **Adjustment Trigger:** Price variance > ± $________ per bushel

### 1.3 Yield Adjustment (if applicable)
- **Base Yield:** ________ bushels per acre
- **Yield Adjustment:** $________ per bushel above/below base

## Section 2: Payment Structure
### 2.1 Initial Payments
- [ ] **March Payment:** $________ **Date Due:** March 1, {{growing_year}}
- [ ] **September Payment:** $________ **Date Due:** September 1, {{growing_year}}

### 2.2 Final Settlement
- [ ] **Final Settlement Due:** December 31, {{growing_year}}
- [ ] **Settlement Calculation Method:** [Price-based/Yield-based/Combined]

## Section 3: Payment Tracking
### 3.1 Base Payments
- [ ] **Q1 Base Payment:** $________ **Status:** ❌ **Date Paid:** ________
- [ ] **Q2 Base Payment:** $________ **Status:** ❌ **Date Paid:** ________

### 3.2 Adjustment Payments
- [ ] **Price Adjustment:** $________ **Status:** ❌ **Date Paid:** ________
- [ ] **Yield Adjustment:** $________ **Status:** ❌ **Date Paid:** ________

**Total Rent for {{growing_year}}:** $________

## Signatures and Date
**Landlord Signature:** ________________________________ **Date:** ________

**Tenant Signature:** __________________________________ **Date:** ________

---
*This flexible cash rent lease is generated for the {{growing_year}} growing season.*
"""
    }
    
    /// Generates pasture grazing lease template
    private func pastureGrazingTemplate() -> String {
        return """
# Pasture Grazing Lease Agreement

**Template Version:** 1.0
**Lease Type:** Pasture Grazing
**Growing Year:** {{growing_year}}

## Section 1: Grazing Terms
### 1.1 Grazing Period
- **Grazing Start Date:** {{start_date}}
- **Grazing End Date:** {{end_date}}
- **Total Grazing Days:** ________ days

### 1.2 Stocking Rates
- **Maximum Animal Units:** ________ AUs
- **Recommended Stocking Rate:** ________ AUs per acre
- **Rotational Grazing Required:** [ ] Yes [ ] No

## Section 2: Payment Terms
### 2.1 Rent Structure
- **Rate per Animal Unit per Month:** $________ 
- **Or Fixed Annual Rate:** ${{rent_amount}}
- **Payment Schedule:** {{rent_frequency}}

### 2.2 Payment Tracking
- [ ] **Spring Payment:** $________ **Due:** ________ **Paid:** ________
- [ ] **Summer Payment:** $________ **Due:** ________ **Paid:** ________
- [ ] **Fall Payment:** $________ **Due:** ________ **Paid:** ________

## Section 3: Grazing Management
### 3.1 Fence and Water Responsibilities
- [ ] **Fence Maintenance:** [Landlord/Tenant responsibility]
- [ ] **Water System Maintenance:** [Landlord/Tenant responsibility]
- [ ] **Gates and Handling Facilities:** [Landlord/Tenant responsibility]

### 3.2 Pasture Care
- [ ] **Weed Control:** [Landlord/Tenant responsibility]
- [ ] **Fertilization:** [Landlord/Tenant responsibility]
- [ ] **Overseeding:** [Landlord/Tenant responsibility]

## Signatures and Date
**Landlord Signature:** ________________________________ **Date:** ________

**Tenant Signature:** __________________________________ **Date:** ________

---
*This pasture grazing lease is generated for the {{growing_year}} season.*
"""
    }
    
    /// Generates custom farming agreement template
    private func customFarmingTemplate() -> String {
        return """
# Custom Farming Agreement

**Template Version:** 1.0
**Lease Type:** Custom Farming
**Growing Year:** {{growing_year}}

## Section 1: Custom Services
### 1.1 Services Provided
- [ ] **Field Preparation:** $________ per acre
- [ ] **Planting:** $________ per acre  
- [ ] **Spraying:** $________ per acre
- [ ] **Harvesting:** $________ per acre or _____ % of crop
- [ ] **Tillage:** $________ per acre

### 1.2 Payment Terms
- **Payment Schedule:** [Per service/Seasonal/Annual]
- **Total Estimated Cost:** $________

## Section 2: Payment Tracking
### 2.1 Service Payments
- [ ] **Spring Operations:** $________ **Completed:** ________ **Paid:** ________
- [ ] **Growing Season:** $________ **Completed:** ________ **Paid:** ________  
- [ ] **Harvest Operations:** $________ **Completed:** ________ **Paid:** ________

## Signatures and Date
**Landowner Signature:** ________________________________ **Date:** ________

**Custom Operator Signature:** ______________________________ **Date:** ________

---
*This custom farming agreement is generated for the {{growing_year}} season.*
"""
    }
}