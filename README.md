# MaterialsAndPractices

## Executive Summary

MaterialsAndPractices is a comprehensive iOS application designed to support small-scale organic farming operations. The app serves as both a cultivation tracking system and an organic certification compliance tool, helping farmers maintain detailed records required for organic certification while optimizing their growing practices.

### Key Features
- **Plant Cultivar Database**: Utilizes USDA open source data to provide detailed information on plant cultivars including growing seasons, hardy zones, and planting schedules
- **Organic Certification Tracking**: Maintains comprehensive records of all activities, amendments, and safety practices required for organic certification compliance
- **Grow Management**: Track active and completed growing operations with detailed timelines and outcomes
- **Safety Compliance**: Built-in harvest safety checklists based on FDA Food Safety Modernization Act (FSMA) requirements
- **Amendment Tracking**: Record and track all soil amendments and organic inputs with full traceability

## Application Architecture

### Technology Stack
- **Platform**: iOS (SwiftUI)
- **Data Persistence**: Core Data
- **Architecture Pattern**: MVVM with Clean Architecture principles
- **Design System**: Custom theming with light/dark mode support

### View Hierarchy
```
MaterialsAndPracticesApp (Root)
├── ContentView (TabView Container)
│   ├── CurrentGrowsView (Active Grows Management)
│   │   ├── GrowRow (Individual Grow Display)
│   │   ├── EditGrowView (Create/Edit Grows)
│   │   └── GrowDetailView (Detailed Grow Information)
│   │       ├── WorkPractices (Work Activity Tracking)
│   │       ├── Amendments (Amendment Applications)
│   │       └── HarvestSafetyChecklistView (Safety Compliance)
│   └── CultivarListView (Plant Cultivar Database)
│       └── CultivarDetailView (Detailed Cultivar Information)
│           ├── Active Grows Grid (Current Cultivations)
│           └── Completed Grows Grid (Historical Data)
```

### Core Data Models
- **Cultivar**: Plant variety information (USDA sourced)
- **Grow**: Individual growing operation tracking
- **Work**: Work activities and practices performed
- **Amendment**: Soil amendments and organic inputs applied

### Key Components
- **CultivarSeeder**: Populates database with USDA vegetable cultivar data
- **Theme System**: Centralized color and typography management
- **Safety Compliance**: FDA FSMA harvest safety checklist implementation

## Development Guidelines

This codebase follows Apple's recommended architectural patterns and Clean Code principles as outlined by Robert C. Martin. The application is designed to be maintainable by AI agents through:

- Clear separation of concerns with MVVM architecture
- Comprehensive inline documentation
- Consistent naming conventions following Swift API design guidelines
- Modular component structure
- Declarative SwiftUI view composition

## Data Sources

Plant cultivar information is sourced from USDA open data initiatives, providing accurate and up-to-date information on:
- Plant families and varieties
- Growing seasons and climate zones
- Optimal planting schedules
- Hardy zone compatibility

## Organic Certification Support

The application maintains detailed records supporting organic certification requirements including:
- Complete input tracking and traceability
- Worker safety training documentation
- Harvest safety protocol compliance
- Amendment application records with timing and quantities
