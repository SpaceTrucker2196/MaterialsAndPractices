# MaterialsAndPractices

## Farm Management & Organic Certification Made Simple

MaterialsAndPractices is a comprehensive iOS app designed specifically for small farms to streamline crop management, ensure organic compliance, and simplify the organic certification process. Built with SwiftUI, this app leverages official USDA data to provide accurate, up-to-date information for informed farming decisions.

### Why Use MaterialsAndPractices?

**For Small Farm Operators:**
- Centralize all crop tracking in one easy-to-use mobile app
- Access a comprehensive database of USDA-approved vegetable cultivars with detailed growing information
- Maintain accurate records required for organic certification with minimal paperwork
- Ensure compliance with federal organic standards through guided safety checklists
- Track soil amendments, work practices, and harvest safety protocols
- Streamline the often complex organic certification documentation process

**Key Benefits:**
- **USDA Data Integration**: Built-in database of hundreds of vegetable cultivars with family classifications, growing seasons, hardy zones, and optimal planting schedules
- **Organic Compliance**: Pre-built safety checklists referencing specific USDA Organic Standards (§112 regulations)
- **Record Keeping**: Comprehensive logging of materials, practices, and grow cycles for certification audits
- **Mobile-First**: Designed for use in the field on iPhone and iPad
- **Offline Capable**: Core functionality works without internet connectivity

## Features Overview

### 🌱 Grow Management
Track complete crop lifecycles from planting to harvest with detailed record-keeping for each growing cycle.

### 📚 USDA Cultivar Database
Access hundreds of vegetable cultivars organized by plant family, with detailed information including:
- Growing seasons and optimal planting windows
- Hardy zone compatibility
- Plant family classifications (Brassicaceae, Solanaceae, etc.)

### ✅ Harvest Safety Compliance
Comprehensive safety checklists based on USDA Organic Standards to ensure:
- Worker safety training compliance
- Proper sanitation practices
- Equipment maintenance standards
- Contamination prevention protocols

### 🧪 Materials & Amendments Tracking
Log and track all soil amendments and materials applied to crops for organic certification documentation.

### 📋 Work Practices Documentation
Record farming practices and work performed for complete audit trails.

## App Structure & View Hierarchy

```
MaterialsAndPractices App
├── Main Tab Navigation
│   ├── 📱 Grows Tab
│   │   ├── CurrentGrowsView (Active Grows List)
│   │   │   ├── GrowDetailView (Individual Grow Details)
│   │   │   │   ├── EditGrowView (Create/Edit Grow Form)
│   │   │   │   │   ├── Cultivar Selection (USDA Database)
│   │   │   │   │   ├── Property Information
│   │   │   │   │   ├── Planting & Harvest Dates
│   │   │   │   │   └── Location & Notes
│   │   │   │   ├── HarvestSafetyChecklist (Organic Compliance)
│   │   │   │   │   ├── Farm Information
│   │   │   │   │   ├── Worker Training Requirements
│   │   │   │   │   ├── Hand Washing Protocols
│   │   │   │   │   ├── Equipment Safety
│   │   │   │   │   └── Sanitation Practices
│   │   │   │   ├── Amendments (Materials Tracking)
│   │   │   │   └── WorkPractices (Work Documentation)
│   │   │   └── [Add New Grow Button]
│   └── 📖 Cultivars Tab
│       ├── CultivarListView (USDA Database Browser)
│       │   ├── [Search & Filter by Family]
│       │   └── CultivarDetailView (Detailed Cultivar Info)
│       │       ├── Plant Family & Scientific Classification
│       │       ├── Growing Season Information
│       │       ├── Hardy Zone Compatibility
│       │       └── Optimal Planting Schedule
└── Data Management
    ├── Core Data Storage
    ├── USDA Cultivar Seeding
    └── Offline Synchronization
```

## View Details

### Main Navigation (ContentView)
Two-tab interface providing access to active grow management and cultivar database browsing.

### Grows Tab
**CurrentGrowsView**: Displays all active growing cycles with quick access to:
- Cultivar information
- Planting dates
- Expected harvest dates
- Location details

**GrowDetailView**: Comprehensive view of individual grows showing:
- Cultivar details with images
- Planting and harvest timeline
- Location and property information
- Applied amendments and materials
- Work practices performed
- Harvest safety compliance status

**EditGrowView**: Form interface for creating new grows with:
- USDA cultivar selection from dropdown
- Property owner and manager information
- Address and location details
- Planting size and dates
- Driving directions and notes

**HarvestSafetyChecklist**: USDA-compliant safety checklist covering:
- Farm and contact information
- Contract harvester details
- Worker safety training verification
- Hand washing protocol compliance
- Equipment safety and maintenance
- Sanitation practice documentation

### Cultivars Tab
**CultivarListView**: Browse the complete USDA vegetable cultivar database with:
- Organization by plant family
- Search and filter capabilities
- Count of cultivars per family
- Visual cultivar representations

**CultivarDetailView**: Detailed cultivar information including:
- Scientific family classification
- Common and scientific names
- Growing season recommendations
- Hardy zone compatibility
- Optimal planting week windows

### Supporting Views
**Amendments**: Grid-based view for tracking soil amendments and materials applied to specific grows.

**WorkPractices**: Documentation interface for recording farming practices and work performed.

## Technical Implementation

- **Framework**: SwiftUI for modern iOS development
- **Data Storage**: Core Data for local persistence
- **Architecture**: MVVM pattern with environment-managed contexts
- **Compatibility**: iOS 14+ (iPhone and iPad)
- **Data Source**: USDA National Organic Program standards and vegetable cultivar database

## Getting Started

1. Clone the repository
2. Open `MaterialsAndPractices.xcodeproj` in Xcode
3. Build and run on iOS simulator or device
4. The app will automatically seed the USDA cultivar database on first launch
5. Create your first grow cycle using the "+" button in the Grows tab

## Data Sources

This app integrates official USDA data including:
- **Vegetable Cultivar Database**: Comprehensive list of approved vegetable varieties with growing specifications
- **Organic Standards**: Safety and compliance requirements from USDA National Organic Program (Title 7, Part 112)
- **Hardy Zone Information**: USDA Plant Hardiness Zone compatibility data
- **Planting Schedules**: Optimal planting windows based on USDA agricultural guidelines

## Organic Certification Support

MaterialsAndPractices simplifies organic certification by:
- Providing pre-built compliance checklists based on federal regulations
- Maintaining detailed records of all materials and practices
- Organizing documentation in certification-ready formats
- Ensuring traceability from planting to harvest
- Supporting audit trail requirements for organic inspectors

---

*Built with ❤️ for small farms using SwiftUI*
