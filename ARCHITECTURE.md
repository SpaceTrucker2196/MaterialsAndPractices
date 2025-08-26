# MaterialsAndPractices iOS App Architecture

## Overview

MaterialsAndPractices is a comprehensive farm management iOS application built with SwiftUI and Core Data. The app implements clean architecture principles with separation of concerns, providing farmers with tools for crop management, worker coordination, and compliance tracking.

## Architecture Patterns

### Clean Architecture Implementation
- **Separation of Concerns**: Clear boundaries between UI, business logic, and data layers
- **Dependency Injection**: Core Data context provided through SwiftUI environment
- **SOLID Principles**: Single responsibility, open/closed, dependency inversion
- **Repository Pattern**: Core Data entities serve as data repositories

### Design Patterns Used
- **MVVM (Model-View-ViewModel)**: SwiftUI views with `@StateObject`, `@ObservedObject`
- **Observer Pattern**: Core Data `@FetchRequest` for reactive data updates
- **Factory Pattern**: `PersistenceController` for Core Data stack creation
- **Strategy Pattern**: Different work order status handling via enums

## Application Structure

### Root Level Architecture

```
MaterialsAndPracticesApp (App Entry Point)
├── ContentView (Main Navigation Container)
│   ├── Profile Validation Logic
│   ├── Onboarding Flow
│   └── TabView Navigation
├── PersistenceController (Core Data Stack)
└── AppTheme (Centralized Design System)
```

### Core Components

#### 1. Application Entry Point
- **MaterialsAndPracticesApp.swift**: Main app structure conforming to `App` protocol
- **ContentView.swift**: Primary navigation container with tab-based interface
- **Profile Management**: Automatic farmer profile validation and guided setup

#### 2. Navigation Architecture
**Tab-Based Navigation Structure:**
```
TabView
├── Tab 1: Grows (CurrentGrowsView)
│   ├── Tile-based grow overview
│   ├── Farm categorization
│   └── Worker assignment indicators
├── Tab 2: Cultivars (CultivarListView)
│   ├── Plant database management
│   ├── Search and filtering
│   └── Detailed cultivar information
├── Tab 3: Dashboard (FarmDashboardView)
│   ├── Worker productivity metrics
│   ├── Weekly summaries
│   └── Work order tracking
└── Tab 4: Utilities (UtilitiesView)
    ├── Settings management
    ├── Data utilities
    └── System preferences
```

#### 3. Data Layer Architecture

**Core Data Stack:**
- **PersistenceController**: Singleton managing NSPersistentCloudKitContainer
- **CloudKit Integration**: Automatic sync across devices
- **Model Versioning**: Currently on version 6 with migration support
- **Preview Data**: Comprehensive seed data for development

**Entity Relationships:**
```
Farmer ←→ Leases ←→ Properties ←→ Fields ←→ Grows
Worker ←→ TimeClock ←→ WorkOrders ←→ WorkTeams
Cultivar ←→ Grows ←→ Amendments
SoilTest ←→ Fields
```

## Module Organization

### 1. Common Module
**Purpose**: Shared utilities and reusable components
```
Common/
├── Persistence.swift (Core Data management)
├── CommonUIComponents.swift (Reusable UI elements)
├── PhotoCaptureView.swift (Camera integration)
├── PhotoGalleryView.swift (Image management)
├── PhotoOverlay.swift (Photo annotations)
├── GenericPhotoCaptureView.swift (Generic photo capture)
└── ProduceColors.swift (Color management for crops)
```

### 2. Configuration Module
**Purpose**: App-wide configuration and theming
```
Configuration/
├── AppTheme.swift (Comprehensive design system)
└── SecureConfiguration.swift (Security settings)
```

### 3. Farm Module
**Purpose**: Farm management and property operations
```
Farm/
├── FarmDashboardView.swift (Main dashboard)
├── FarmListView.swift (Property listings)
├── PropertyDetailView.swift (Property information)
├── FieldManagementViews.swift (Field operations)
├── WorkerManagementViews.swift (Employee management)
├── SoilTestViews.swift (Soil analysis)
├── InfrastructureViews.swift (Farm infrastructure)
├── LabManagementViews.swift (Testing facilities)
└── WeeklyWorkerSummaryViews.swift (Analytics)
```

### 4. Grow Module
**Purpose**: Crop cultivation and tracking
```
Grow/
├── CurrentGrowsView.swift (Active grows overview)
├── GrowDetailView.swift (Individual grow management)
├── EditGrowView.swift (Grow editing interface)
├── EnhancedEditGrowView.swift (Advanced editing)
├── GrowViews.swift (Supporting grow views)
└── HarvestSafetyChecklist.swift (Safety compliance)
```

### 5. Material Module
**Purpose**: Cultivar database and plant information
```
Material/
├── CultivarViews.swift (Plant database interface)
├── CultivarExtensions.swift (Data model extensions)
├── CultivarSeeder.swift (Database seeding)
├── AmendmentViews.swift (Soil amendment management)
├── Amendments.swift (Amendment data models)
├── HarvestCalendarHeatMap.swift (Seasonal planning)
├── HarvestHeatMapView.swift (Harvest visualization)
└── GrowingSeasonTimelineView.swift (Timeline visualization)
```

### 6. Practice Module
**Purpose**: Work order and practice management
```
Practice/
├── WorkOrderSystem.swift (Work order core logic)
├── PerformWorkView.swift (Work execution interface)
├── WorkPractices.swift (Practice definitions)
├── WorkPracticeDetailView.swift (Practice details)
├── WorkViews.swift (Work-related views)
└── WorkOrderHelpDocumentation.swift (Help system)
```

### 7. Settings Module
**Purpose**: Application configuration
```
Settings/
├── SoilTestSettingsView.swift (Testing preferences)
└── UtilitiesView.swift (General utilities)
```

## View Hierarchy

### Primary View Controllers

#### CurrentGrowsView (Main Grows Interface)
```
NavigationView
├── ScrollView
│   └── LazyVStack (Farm sections)
│       └── ForEach (Grows by farm)
│           └── LazyVGrid (2-column tile layout)
│               └── GrowTileView
│                   ├── Crop emoji
│                   ├── Worker indicators (3/5 format)
│                   ├── Harvest countdown
│                   └── Timing estimates
├── Navigation Toolbar
│   ├── Add button
│   └── Search functionality
└── Sheet Presentations
    ├── Create grow flow
    └── Edit grow interface
```

#### FarmDashboardView (Analytics & Management)
```
NavigationView
├── ScrollView
│   ├── Worker summary cards
│   ├── Active work orders
│   ├── Weekly hour tracking
│   └── Productivity metrics
├── Filtering controls
└── Navigation links to detail views
```

#### Work Order System Architecture
```
WorkOrder Management
├── Status Enum (AgricultureWorkStatus)
│   ├── Standard statuses (not started, in progress, completed)
│   ├── Agriculture-specific (weather delay, too wet, equipment issue)
│   └── Visual indicators (emojis, colors)
├── Team Management (WorkTeam entity)
│   ├── Member assignment
│   ├── Team coordination
│   └── Workload distribution
├── Time Tracking Integration
│   ├── TimeClock entity linkage
│   ├── Hour calculation
│   └── Overtime detection
└── Work Item Breakdown
    ├── Individual tasks
    ├── Practice associations
    └── Completion tracking
```

## Data Flow Architecture

### State Management
- **@StateObject**: For view-owned observable objects
- **@ObservedObject**: For parent-owned observable objects
- **@FetchRequest**: For Core Data reactive queries
- **@Environment**: For dependency injection (managedObjectContext)
- **@State**: For local view state

### Data Persistence Flow
```
UI Layer (Views)
    ↓ (User Actions)
Core Data Context
    ↓ (Save Operations)
Persistent Store Coordinator
    ↓ (CloudKit Sync)
iCloud Database
```

### Update Propagation
```
Core Data Change
    ↓ (NSManagedObjectContext notifications)
@FetchRequest Updates
    ↓ (Automatic view invalidation)
SwiftUI View Refresh
```

## Key Architectural Components

### 1. Theme System (AppTheme)
```swift
AppTheme
├── Colors (Semantic color system)
│   ├── Primary/Secondary colors
│   ├── Background hierarchy
│   ├── Text hierarchy
│   ├── Status colors
│   ├── USDA zone color coding
│   └── Agriculture-specific colors
├── Typography (Text style hierarchy)
├── Spacing (Consistent spacing system)
└── Component Styles (Reusable component styling)
```

### 2. Harvest Calculation System
```swift
HarvestCalculator
├── Growing days parsing (single values, ranges)
├── Date calculations (planting + growing period)
├── Seasonal timing (early/mid/late month)
├── Weather considerations
└── User-friendly formatting
```

### 3. Work Order Management
```swift
Work Order System
├── AgricultureWorkStatus (Status enumeration)
├── WorkTeam (Team management)
├── Priority levels (High, Medium, Low)
├── Time estimation and tracking
└── Integration with TimeClock system
```

## Security & Performance

### Security Considerations
- **CloudKit Integration**: Secure cloud synchronization
- **Data Encryption**: Core Data encryption at rest
- **Photo Management**: Secure local storage
- **Configuration**: Secure configuration management

### Performance Optimizations
- **Lazy Loading**: LazyVStack/LazyVGrid for large datasets
- **Fetch Request Optimization**: Predicates and sort descriptors
- **Image Handling**: Efficient photo loading and caching
- **Core Data Faulting**: Automatic memory management

## Testing Architecture

### Test Structure
```
Tests/
├── Unit Tests (MaterialsAndPracticesTests)
│   ├── ColorAssetTests
│   ├── FarmDashboardTests
│   ├── FarmerProfileTests
│   ├── TimeClockTests
│   └── WorkerManagementTests
├── UI Tests (MaterialsAndPracticesUITests)
└── Preview Data (PersistenceController.preview)
```

## Deployment Architecture

### Build Configuration
- **Xcode Project**: Standard iOS project structure
- **Target SDK**: iOS with SwiftUI
- **Core Data Model**: Versioned with migration support
- **CloudKit**: Production and development environments

### Asset Management
- **Images**: Asset catalog organization
- **Colors**: Semantic color assets supporting dark mode
- **Data**: CSV files for cultivar seeding

## Future Architecture Considerations

### Scalability
- Modular architecture supports feature additions
- Clean separation allows for team development
- Core Data schema versioning enables data model evolution

### Extensibility
- Protocol-oriented design for new cultivar sources
- Pluggable work order status systems
- Extensible theme system for customization

### Performance
- Efficient data fetching with predicates
- Lazy loading for large datasets
- Image optimization for photo management

This architecture provides a solid foundation for a comprehensive farm management system while maintaining clean code principles and scalability for future enhancements.