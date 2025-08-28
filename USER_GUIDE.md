# Materials and Practices User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Dashboard Overview](#dashboard-overview)
4. [Farm Management](#farm-management)
5. [Lease Management](#lease-management)
6. [Soil Health & Testing](#soil-health--testing)
7. [Materials Management](#materials-management)
8. [Worker Tracking](#worker-tracking)
9. [Health and Safety Training](#health-and-safety-training)
10. [Organic Certification Compliance](#organic-certification-compliance)
11. [Lot Tracking & Traceability](#lot-tracking--traceability)
12. [Reports and Documentation](#reports-and-documentation)
13. [Troubleshooting](#troubleshooting)
14. [FAQ](#faq)
15. [Contact Support](#contact-support)

## Introduction

Materials and Practices is a comprehensive farm management system designed specifically for organic farmers and producers. The application streamlines compliance with USDA organic standards while providing powerful tools for tracking materials, practices, worker activities, and produce from field to market.

### Key Features
- Complete materials inventory management (inputs and outputs)
- Comprehensive lease agreement management and payment tracking
- Worker tracking and certification management
- Health and safety training documentation
- Organic certification compliance tools
- Field-to-market lot tracking system
- Visual indicators for lease status and payment issues
- Comprehensive reporting for regulatory compliance

This application bridges the gap between daily farm operations and the complex requirements of organic certification, creating a seamless experience that enhances productivity while ensuring compliance. The integrated lease management system helps farmers track property agreements, payment schedules, and generate documentation for property owners and tax purposes.

## Getting Started

### System Requirements

### Logging In
1. Navigate to the Materials and Practices login page
2. Enter your username and password
3. Select your farm profile if you manage multiple farms
4. Click "Login"

### Initial Setup
1. Complete your farm profile with location, acreage, and certification details
2. Set up user permissions for farm workers and managers
3. Import or manually enter your initial materials inventory
4. Configure notification preferences

## Dashboard Overview

The dashboard provides a snapshot of your farm's key metrics and upcoming tasks:

- **Activity Calendar**: Shows scheduled activities, applications, and harvests
- **Materials Summary**: Quick view of input inventory levels with alerts for low stock
- **Worker Status**: Overview of worker certifications and training status
- **Compliance Indicators**: Visual markers showing certification status and upcoming deadlines
- **Recent Activity Feed**: Latest actions taken within the system

Use the navigation menu on the left side to access specific modules.

## Farm Management

### Adding a New Farm
1. Navigate to "Farm Settings" → "Add New Farm"
2. Complete all required fields (name, location, certification status)
3. Add field boundaries using the mapping tool or import from existing GIS files
4. Set up crop rotation plans and field history

### Managing Fields
1. Select "Fields" from the Farm Management menu
2. Add new fields with the "+ Add Field" button
3. For each field, record:
   - Size and boundaries
   - Soil test results
   - Cropping history
   - Buffer zones for organic compliance
4. Attach relevant documents like water test results

### Crop Planning
1. Access the Crop Planning tool from the Farm Management menu
2. Create seasonal planting schedules
3. Assign crops to specific fields
4. Generate material requirement forecasts based on planned crops

## Lease Management

The lease management system provides comprehensive tools for managing agricultural lease agreements, tracking payments, and maintaining records for property owners and tax purposes.

### Overview

The lease management system includes:
- Pre-built agricultural lease agreement templates
- Payment tracking and reminder system
- Visual indicators for lease status
- Document generation for property owners
- Integration with farm dashboard for financial oversight

### Creating a New Lease Agreement

1. Navigate to "Utilities" → "Lease Management"
2. Click "New Lease" to start the lease creation workflow
3. Complete the four-step process:

#### Step 1: Template Selection
- Choose from available lease templates:
  - **Cash Rent Agricultural Lease**: Fixed annual payment
  - **Crop Share Agricultural Lease**: Percentage-based sharing
  - **Flexible Cash Rent Lease**: Rent with price/yield adjustments
  - **Pasture Grazing Lease**: Livestock grazing agreements
  - **Custom Farming Agreement**: Services-based arrangements

#### Step 2: Basic Information
- Select the **Growing Year** (current year to 3 years future)
- Choose the **Property** from your managed properties
- Select the **Farmer/Tenant** from your contacts
- Set **Start Date** and **End Date** for the lease period

#### Step 3: Payment Terms
- Enter the **Rent Amount** (annual total)
- Select **Payment Frequency**:
  - Annual (single payment)
  - Semi-Annual (two payments)
  - Quarterly (four payments)
  - Monthly (twelve payments)

#### Step 4: Review and Create
- Review all lease details for accuracy
- Click "Create Lease" to generate the agreement
- The system will create both a Core Data record and a markdown document

### Managing Existing Leases

#### Viewing Active Leases
- Access from the main Dashboard "Lease Agreements & Payments" section
- View lease details including property, farmer, and payment status
- See upcoming payments and overdue amounts

#### Payment Tracking
The system automatically calculates payment schedules based on:
- Lease start and end dates
- Payment frequency settings
- Annual rent amount

Upcoming payments appear on the Dashboard with:
- 🟠 Orange indicators for payments due within 30 days
- 🔴 Red indicators for overdue payments

### Visual Lease Status Indicators

#### Field Tiles
Field selection interfaces show lease status indicators:
- 🟠 Orange dollar sign ($): Field not covered by active lease
- No indicator: Field has active lease coverage

#### Farm Dashboard
The dashboard displays:
- Count of active lease agreements
- Number of urgent payments requiring attention
- Upcoming payment summaries

### Exporting Documents for Property Owners

#### Individual Lease Export
1. Navigate to Lease Management
2. Select a specific lease
3. Use "Export for Property Owner" option
4. Document includes:
   - Complete lease summary
   - Payment schedule for current year
   - Record-keeping sections for tax purposes
   - GAAP-compliant formatting

#### Bulk Export
1. Use "Export All Leases" for year-end reporting
2. Generates individual documents for each property owner
3. Creates summary report for your records

### Lease Documentation Features

#### Generated Documents Include:
- **Property Information**: Location, acreage, contact details
- **Tenant Information**: Farmer details and organization
- **Financial Terms**: Rent amounts, payment frequency, responsibilities
- **Payment Record Tables**: Tracking actual vs. scheduled payments
- **Tax Documentation**: GAAP-compliant record-keeping guidance
- **Legal References**: Recommendations for professional consultation

#### File Organization
- Documents saved to `Documents/LeaseExports/`
- Timestamped filenames for easy organization
- Markdown format for universal compatibility

### Best Practices

#### Record Keeping
- Export lease documents annually for tax records
- Maintain signed copies of all lease agreements
- Track all payments and property-related expenses
- Consult with tax professionals for proper reporting

#### Payment Management
- Review dashboard regularly for upcoming payments
- Set up reminders for quarterly and annual payments
- Document any payment adjustments or modifications
- Keep records of communication with tenants

#### Lease Renewal Process
- Begin renewal discussions 60-90 days before expiration
- Review and update rental rates based on market conditions
- Update lease terms to reflect any property changes
- Create new lease agreements through the system

## Soil Health & Testing

Soil health monitoring is fundamental to sustainable agriculture and organic certification. Materials and Practices provides comprehensive soil testing tools to help you understand, track, and improve your soil conditions over time.

### Understanding Soil Health

Healthy soil is the foundation of successful organic farming. It's a living ecosystem containing billions of beneficial microorganisms that:

- **Convert organic matter** into plant-available nutrients through natural decomposition processes
- **Form symbiotic relationships** with plant roots (mycorrhizae) to improve nutrient uptake
- **Improve soil structure** by creating aggregates that enhance water infiltration and root penetration
- **Suppress plant diseases** naturally by maintaining beneficial microbial diversity
- **Cycle nutrients** efficiently, reducing the need for external inputs

### Taking Soil Samples

Following USDA guidelines for accurate soil testing:

#### When to Sample
- **Every 2-3 years** for established fields under consistent management
- **Before planting** new crops or changing field management
- **When problems occur** such as poor growth, yellowing, or disease issues
- **After major amendments** to monitor changes in soil chemistry

#### Sampling Procedure
1. **Timing**: Sample when soil is at field moisture capacity (not too wet or dry)
2. **Distribution**: Take 15-20 random samples across each field or management zone
3. **Depth**: Sample to 6-8 inches for most crops (3-4 inches for pasture)
4. **Equipment**: Use clean, stainless steel tools; avoid brass or galvanized equipment
5. **Mixing**: Thoroughly combine samples in a clean plastic bucket
6. **Submission**: Submit 1-2 cups of mixed soil to a certified laboratory

#### Avoiding Contamination
- Don't sample near roads, fence lines, or areas where animals congregate
- Avoid recently fertilized or limed areas
- Keep samples separate for different fields or soil types
- Label samples clearly with field identification and date

### Understanding Soil Test Results

#### pH Level (Soil Acidity/Alkalinity)
- **Range**: 0-14 scale, with 7.0 being neutral
- **Optimal for most crops**: 6.0-7.0
- **Below 6.0**: Acidic conditions; nutrients like phosphorus become less available
- **Above 7.5**: Alkaline conditions; iron and manganese may become unavailable
- **Impact on microbes**: Most beneficial soil organisms prefer near-neutral pH

#### Organic Matter Content
- **Target range**: 3-5% for healthy agricultural soils
- **Below 2%**: Low biological activity, poor nutrient cycling
- **Above 3%**: Good soil biology, improved water retention and structure
- **Benefits**: Higher organic matter supports more diverse microbial communities

#### Phosphorus (P)
- **Role**: Essential for root development, flowering, and seed formation
- **Measurement**: Parts per million (ppm) in soil
- **Low**: <15 ppm - may need supplementation
- **Adequate**: 15-30 ppm - sufficient for most crops
- **High**: >30 ppm - adequate reserves

#### Potassium (K)
- **Role**: Water regulation, disease resistance, winter hardiness
- **Measurement**: Parts per million (ppm) in soil
- **Low**: <100 ppm - deficiency likely
- **Adequate**: 100-200 ppm - sufficient for most crops
- **High**: >200 ppm - good reserves

#### Cation Exchange Capacity (CEC)
- **Definition**: Soil's ability to hold and exchange nutrients
- **Sandy soils**: CEC 5-15 (lower nutrient holding capacity)
- **Clay soils**: CEC 15-40 (higher nutrient holding capacity)
- **Improving CEC**: Add organic matter and clay amendments

### Managing Soil Tests in the App

#### Adding a Soil Test
1. Navigate to **Settings** → **Soil Testing** → **Add Soil Test**
2. **Select Field**: Choose the field from the tile view
3. **Choose Laboratory**: Select existing lab or create new one
4. **Enter Results**: Input pH, organic matter, nutrients, and CEC values
5. **Add Notes**: Include any lab recommendations or observations
6. **Save**: Test results are immediately available for analysis

#### Laboratory Management
- **Add Labs**: Store contact information for testing laboratories
- **Track History**: View all tests performed by each laboratory
- **Compare Services**: Maintain notes about lab quality and turnaround times

#### Visual Analysis Tools
- **pH Spectrum**: Color-coded visualization showing optimal pH ranges
- **Nutrient Indicators**: Bar charts displaying nutrient levels with interpretations
- **Trend Analysis**: Track changes in soil health over time
- **Field Comparison**: Compare soil conditions across different fields

### Interpreting Results for Plant Health

#### Signs Your Plants Need Soil Changes

**Nitrogen Deficiency**:
- Yellowing of lower leaves first
- Stunted growth and pale green coloration
- Solution: Increase organic matter, add compost or blood meal

**Phosphorus Deficiency**:
- Purple or reddish coloration on leaves
- Delayed flowering and poor root development
- Solution: Add bone meal or rock phosphate; check pH

**Potassium Deficiency**:
- Brown or scorched leaf edges
- Weak stems susceptible to lodging
- Increased disease problems
- Solution: Add wood ash, granite meal, or greensand

**Iron Deficiency** (often pH-related):
- Yellow leaves with green veins (interveinal chlorosis)
- Most visible on new growth
- Solution: Lower pH if above 7.5; improve drainage

#### Soil pH Adjustments

**Raising pH** (reducing acidity):
- Apply agricultural limestone (calcium carbonate)
- Use dolomitic lime if magnesium is also low
- Wood ash provides quick but temporary pH increase
- Apply lime in fall for spring crops

**Lowering pH** (reducing alkalinity):
- Add sulfur (slow acting, long-lasting)
- Use acidic organic matter like pine needles or peat
- Apply iron sulfate for quick but temporary reduction
- Improve drainage to reduce sodium accumulation

### Soil Microbes and Chemical Fertilizers

#### The Importance of Soil Microorganisms

Healthy soil contains **billions of microorganisms per gram**, including:
- **Bacteria**: Break down organic matter, fix nitrogen, cycle nutrients
- **Fungi**: Form mycorrhizal networks, improve nutrient uptake
- **Protozoa**: Release nutrients by consuming bacteria and fungi
- **Beneficial insects**: Aerate soil and transport beneficial microbes

#### Impact of Chemical Fertilizers on Soil Biology

**Negative Effects**:
- **Kill beneficial microorganisms** through salt concentration and pH changes
- **Reduce microbial diversity** by favoring only certain species
- **Disrupt nutrient cycling** by bypassing natural biological processes
- **Increase soil compaction** over time due to reduced organic matter
- **Create dependency** on external inputs as natural systems break down

**Soil Health Decline Indicators**:
- Reduced organic matter content over time
- Increased need for fertilizer applications
- Greater susceptibility to drought and disease
- Poor soil structure and water infiltration
- Loss of earthworms and beneficial insects

#### Organic Alternatives for Soil Health

**Building Soil Biology**:
- **Compost applications**: Introduce diverse microbial communities
- **Cover crops**: Feed soil organisms year-round with living roots
- **Minimal tillage**: Preserve fungal networks and soil structure
- **Diverse rotations**: Support different microbial populations
- **Organic amendments**: Use materials that feed rather than bypass soil biology

**Beneficial Practices**:
- Apply mycorrhizal inoculants when transplanting
- Use compost tea to introduce beneficial microorganisms
- Maintain permanent soil cover to protect microbial communities
- Integrate livestock for natural fertilization when possible

### Organic Certification and Soil Testing

#### Documentation Requirements
- **Maintain records** of all soil test results for certification inspections
- **Track amendments** applied based on soil test recommendations
- **Document improvements** in soil health over time
- **Show compliance** with organic standards for soil building

#### USDA Organic Standards
- Soil tests support evidence of soil health improvement
- Results guide organic amendment programs
- Help demonstrate sustainable farming practices
- Required for transitioning conventional fields to organic

### Troubleshooting Common Soil Issues

#### Problem: Low Organic Matter
**Symptoms**: Poor water retention, quick nutrient loss, compaction
**Solutions**: 
- Increase compost applications to 2-4 inches annually
- Plant cover crops on all unused fields
- Reduce tillage intensity and frequency
- Add aged manure or other organic amendments

#### Problem: pH Too High (Alkaline)
**Symptoms**: Iron deficiency, poor phosphorus availability
**Solutions**:
- Apply elemental sulfur at 10-20 lbs per 1000 sq ft
- Use acidic organic matter like pine needles
- Improve drainage to reduce sodium buildup
- Consider acid-tolerant crop varieties

#### Problem: pH Too Low (Acidic)
**Symptoms**: Aluminum toxicity, poor bacterial activity
**Solutions**:
- Apply agricultural lime based on soil test recommendations
- Use dolomitic lime if magnesium is also low
- Add wood ash for quick pH adjustment
- Ensure adequate calcium and magnesium levels

#### Problem: Nutrient Imbalances
**Symptoms**: Deficiency signs despite adequate soil levels
**Solutions**:
- Check pH - most nutrients unavailable outside 6.0-7.0 range
- Improve soil biology with compost and cover crops
- Reduce tillage to preserve nutrient cycling
- Consider foliar feeding for immediate correction

### Best Practices for Soil Health

1. **Test Regularly**: Every 2-3 years or when problems occur
2. **Build Organic Matter**: Target 3-5% through compost and cover crops
3. **Maintain pH**: Keep in optimal range for your crops (usually 6.0-7.0)
4. **Feed the Soil Biology**: Use organic amendments that support microbial life
5. **Minimize Disturbance**: Reduce tillage to preserve soil structure
6. **Diversify**: Use crop rotations and polycultures to support soil health
7. **Monitor Changes**: Track trends in soil health over time
8. **Integrate Practices**: Combine soil testing with other sustainable practices

## Materials Management

Materials in the system refer to all inputs used in farming and all products produced by your farm.

### Input Materials
1. Navigate to "Materials" → "Inputs"
2. Categories include:
   - Seeds and transplants
   - Fertilizers
   - Pest management products
   - Soil amendments
   - Processing aids

### Adding New Input Materials
1. Click "+ Add Material"
2. Complete the material profile:
   - Material name and supplier
   - Organic certification status
   - OMRI or WSDA listing information
   - Upload certificates and documentation
   - Set inventory tracking parameters

### Output Products
1. Navigate to "Materials" → "Products"
2. Add your farm products with:
   - Product name and varieties
   - Packaging information
   - Storage requirements
   - Pricing tiers

### Inventory Management
1. Track real-time inventory levels
2. Set low-stock alerts
3. Generate purchase orders for inputs
4. Record material usage by field, date, and purpose

## Worker Tracking

The worker tracking system allows you to maintain comprehensive records of all personnel working on your farm—a critical component for organic certification and food safety compliance.

### Adding Workers
1. Navigate to "Workers" → "Add Worker"
2. Enter personal information and contact details
3. Upload required identification documents
4. Assign worker roles and permissions in the system

### Worker Certifications
1. Access "Workers" → "Certifications"
2. Record required certifications for each worker:
   - Pesticide applicator licenses
   - Equipment operation certifications
   - Food safety training
3. Set expiration notifications for certification renewals

### Time and Activity Tracking
1. Workers can log in to record their daily activities
2. For each task, document:
   - Fields worked
   - Tasks performed
   - Materials applied or harvested
   - Equipment used
   - Hours worked
3. Supervisors can approve and modify time entries

### Worker Performance Analytics
1. View productivity metrics by worker, task type, or field
2. Identify training needs based on performance data
3. Generate worker activity reports for payroll and compliance

## Health and Safety Training

Maintaining comprehensive health and safety training records protects both your workers and your certification status.

### Training Management
1. Navigate to "Workers" → "Training"
2. Schedule training sessions for:
   - Equipment operation
   - First aid
   - Proper handling of materials
   - Food safety protocols
   - Emergency procedures

### Training Documentation
1. Record completed training for each worker
2. Upload certificates of completion
3. Set automatic reminders for refresher courses
4. Generate training compliance reports for inspections

### Safety Incident Reporting
1. Document any workplace incidents or near-misses
2. Track incident investigations and corrective actions
3. Analyze incident patterns to improve safety protocols

## Organic Certification Compliance

Materials and Practices simplifies the complex process of maintaining organic certification by tracking all required documentation in real-time.

### Certification Management
1. Store current organic certificates
2. Track certification renewal dates
3. Maintain inspector contact information
4. Store previous inspection reports

### Compliance Monitoring
1. Real-time alerts for potential compliance issues:
   - Buffer zone violations
   - Non-approved material usage
   - Missing documentation
   - Incomplete records

### Preparing for Inspection
1. Generate comprehensive inspection preparation reports:
   - Materials list with all input documentation
   - Field activity logs
   - Harvest and sales records
   - Worker training documentation
   - Equipment cleaning logs

### Organic System Plan (OSP)
1. Digital maintenance of your Organic System Plan
2. Track changes and updates to your OSP
3. Export OSP sections for submission to certifiers

## Lot Tracking & Traceability

The system's lot tracking capabilities meet and exceed USDA standards for organic produce traceability—a key feature for food safety and organic integrity.

### Harvest Lot Creation
1. When recording harvests, create uniquely identified lots
2. For each lot, document:
   - Harvest date and time
   - Field source
   - Crop and variety
   - Quantity harvested
   - Workers involved
   - Equipment used
   - Storage location

### Complete Traceability Chain
Materials and Practices creates a comprehensive traceability record for each product:
1. Seed source and planting date
2. All inputs applied to the field (with dates and rates)
3. Workers who handled the crop during growth and harvest
4. Processing steps and handling
5. Storage conditions and duration
6. Distribution channels

### Mock Recall Testing
1. Conduct simulated recall exercises
2. Test the system's ability to trace products forward and backward
3. Generate recall reports within minutes
4. Document mock recall results for certification

## Reports and Documentation

### Standard Reports
1. Navigate to "Reports" to access pre-built report templates:
   - Material usage by field
   - Worker activities
   - Harvest yields
   - Compliance documentation
   - Inventory status

### Custom Reports
1. Use the report builder to create custom reports
2. Select data fields to include
3. Apply filters and sorting
4. Save report templates for future use

### Exporting Data
1. Export reports in multiple formats:
   - PDF for printing
   - CSV for data analysis
   - JSON for system integration

### Document Management
1. Store all farm documentation digitally:
   - Organic certificates
   - Field maps
   - Water tests
   - Soil analyses
   - Training records

## Troubleshooting

### Common Issues and Solutions
- **Data Not Saving**: Ensure you have a stable internet connection and click "Save" before navigating away
- **Missing Materials**: Check filter settings in the materials view
- **Report Generation Errors**: Verify all required fields have data for the selected date range
- **Login Problems**: Try clearing browser cache or resetting your password

### System Status
Check the status dashboard for any known issues or scheduled maintenance.

## FAQ

**Q: How often should I update my materials inventory?**  
A: For best results, update your inventory in real-time as materials are received or used. At minimum, perform a weekly reconciliation.

**Q: Can I use the system offline?**  
A: The mobile app has limited offline functionality, but will sync data when connectivity is restored.

**Q: How does the system help with organic certification?**  
A: The system automatically organizes all documentation required for certification, tracks compliance issues in real-time, and can generate complete reports for inspectors.

**Q: Who can see worker health and safety records?**  
A: Access to sensitive worker information is restricted by permission level. Farm administrators and designated safety officers typically have access.
ials and Practices - Empowering Organic Farmers with Comprehensive Management Tools
