# MaterialsAndPractices - GitHub Copilot Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites
- **CRITICAL**: This is an iOS SwiftUI application that REQUIRES macOS and Xcode for development
- **Environment**: You must be on macOS with Xcode 16.2 or later installed
- **No external dependencies**: This project has no CocoaPods, Swift Package Manager, or npm dependencies

### Essential Commands - Bootstrap and Build
Execute these commands in exact order. NEVER CANCEL any of these operations:

```bash
# 1. Navigate to project directory
cd /path/to/MaterialsAndPractices

# 2. Open Xcode project (required for iOS development)
open MaterialsAndPractices.xcodeproj

# 3. Build the project (NEVER CANCEL - takes 2-5 minutes)
xcodebuild build \
  -project MaterialsAndPractices.xcodeproj \
  -scheme MaterialsAndPractices \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0' \
  -configuration Debug \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

# 4. Run all tests (NEVER CANCEL - takes 3-7 minutes)
xcodebuild test \
  -project MaterialsAndPractices.xcodeproj \
  -scheme MaterialsAndPractices \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0' \
  -configuration Debug \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  -enableCodeCoverage YES
```

**CRITICAL TIMING**: Set timeout to 10+ minutes for build commands and 15+ minutes for test commands. iOS builds and tests are slow.

### Running Tests - Use Test Runner Script
The project includes a comprehensive test runner script that provides convenient access to different test suites:

```bash
# Make script executable (first time only)
chmod +x run_tests.sh

# Run all tests (NEVER CANCEL - takes 5-10 minutes)
./run_tests.sh

# Run specific test suites
./run_tests.sh time          # Time clock system tests
./run_tests.sh harvest       # Harvest calendar tests  
./run_tests.sh clean         # Clean architecture tests
./run_tests.sh device        # Device detection and UI tests

# Get help
./run_tests.sh help
```

### iOS Simulator Requirements
- **Primary Target**: iPhone 15 with iOS 18.0 (as defined in GitHub workflow)
- **Alternative**: iPhone 14 with iOS 17.0+ (as used in documentation)
- **iPad Testing**: iPad Pro 11" or 12.9" for adaptive UI testing
- **CRITICAL**: Always specify exact simulator name and OS version in xcodebuild commands

### Expected Build and Test Times
- **Clean Build**: 2-5 minutes (NEVER CANCEL)
- **Incremental Build**: 30-90 seconds
- **Full Test Suite**: 5-10 minutes (47 tests across 4 suites)
- **Individual Test Suite**: 1-3 minutes each

## Application Architecture

### Technology Stack
- **Platform**: iOS (SwiftUI) with iPad Pro optimizations
- **Data**: Core Data with CloudKit sync capability
- **Architecture**: Clean Architecture with MVVM presentation layer
- **UI Framework**: SwiftUI with adaptive layouts for iPhone and iPad
- **No External Dependencies**: Pure iOS/Swift implementation

### Test Coverage (47 Tests Total)
1. **TimeClockTests** (8 tests) - Worker time tracking functionality
2. **HarvestCalendarTests** (12 tests) - Harvest calendar date ranges and calculations  
3. **CleanArchitectureTimeTrackingTests** (15 tests) - Clean architecture implementation
4. **DeviceDetectionAndAdaptiveUITests** (12 tests) - iPad Pro features and responsive design

## Validation Scenarios

### ALWAYS Run These Validation Steps After Changes

#### 1. Core Functionality Validation
```bash
# Test time clock system (critical for worker management)
./run_tests.sh time

# Verify harvest calendar calculations
./run_tests.sh harvest
```

#### 2. Architecture Validation  
```bash
# Ensure clean architecture compliance
./run_tests.sh clean

# Validate device-specific adaptations
./run_tests.sh device
```

#### 3. Build Validation
```bash
# Always build before committing changes
xcodebuild build \
  -project MaterialsAndPractices.xcodeproj \
  -scheme MaterialsAndPractices \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0'
```

#### 4. Manual UI Testing (CRITICAL)
After making any UI changes, you MUST manually test:

1. **Launch the app in iOS Simulator**:
   - Open MaterialsAndPractices.xcodeproj in Xcode
   - Select iPhone 15 simulator
   - Press Cmd+R to run
   - **WAIT for complete startup** (takes 30-60 seconds)

2. **Test Core Workflows**:
   - Navigate through all 4 main tabs: Grows, Cultivars, Dashboard, Utilities
   - Create a new grow and verify it saves properly
   - Test time clock functionality (clock in/out)
   - Verify responsive design by testing on both iPhone and iPad simulators

3. **iPad Pro Testing** (if UI changes affect adaptive layout):
   - Test on iPad Pro 11" simulator
   - Test on iPad Pro 12.9" simulator  
   - Verify sidebar navigation works properly
   - Check tile-based dashboard layout

## Common Development Tasks

### Running the Application
```bash
# Option 1: Through Xcode (RECOMMENDED)
open MaterialsAndPractices.xcodeproj
# Then press Cmd+R in Xcode

# Option 2: Command line (for automation)
xcodebuild build-for-testing \
  -project MaterialsAndPractices.xcodeproj \
  -scheme MaterialsAndPractices \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0'
```

### Debugging Failed Tests
```bash
# Run tests with verbose output
xcodebuild test \
  -project MaterialsAndPractices.xcodeproj \
  -scheme MaterialsAndPractices \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.0' \
  -only-testing:MaterialsAndPracticesTests/[TestSuiteName] \
  | xcpretty --test

# Check test results in Xcode
# Navigate to Test Navigator (Cmd+6) after running tests
```

### Key Project Locations

#### Core Source Files
- `MaterialsAndPractices/MaterialsAndPracticesApp.swift` - Main app entry point
- `MaterialsAndPractices/Configuration/AppTheme.swift` - Centralized design system (colors, typography)
- `MaterialsAndPractices/Configuration/SecureConfiguration.swift` - App configuration and settings
- `MaterialsAndPractices/Farm/` - Farm management views and logic
- `MaterialsAndPractices/TimeKeeping/` - Time clock system implementation
- `MaterialsAndPractices/Material/` - Harvest and cultivation tracking

#### Test Files  
- `MaterialsAndPracticesTests/TimeClockTests.swift` - Time tracking tests
- `MaterialsAndPracticesTests/HarvestCalendarTests.swift` - Calendar functionality
- `MaterialsAndPracticesTests/CleanArchitectureTimeTrackingTests.swift` - Architecture tests
- `MaterialsAndPracticesTests/DeviceDetectionAndAdaptiveUITests.swift` - UI adaptation tests

#### Important Data Files
- `vegetable_cultivars_master.csv` - USDA plant cultivar data (303KB)
- `vegetable_cultivars_master_enriched_with_family_common.csv` - Enhanced cultivar data (210KB)

#### Documentation Files (Reference These)
- `README.md` - Comprehensive project overview and test coverage details
- `ARCHITECTURE.md` - Detailed architecture patterns and clean architecture implementation
- `COLOR_THEME_DOCUMENTATION.md` - Dual-theme system (light/dark mode) documentation
- `USER_GUIDE.md` - Complete user guide for application features
- `HELP_SYSTEM_INTEGRATION.md` - Localization and help system integration details

### Performance Expectations
- **App Launch**: 30-60 seconds in simulator (includes Core Data setup)
- **Test Execution**: Individual test suites run in 1-3 minutes
- **Build Performance**: Incremental builds in 30-90 seconds
- **Memory Usage**: Normal iOS app footprint (~50-100MB in simulator)

## CI/CD Integration

### GitHub Actions Workflow
The project includes `.github/workflows/ios-build.yml` which:
- Runs on macOS-latest with Xcode 16.2
- Builds for iPhone 15 with iOS 18.0
- Executes full test suite with code coverage
- Archives build artifacts

### Expected CI Timing
- **Total Workflow**: 15-25 minutes
- **Build Phase**: 5-8 minutes
- **Test Phase**: 8-12 minutes  
- **Archive Phase**: 2-5 minutes

## Troubleshooting

### Common Issues and Solutions

#### "xcodebuild not available"
- **Cause**: Not running on macOS or Xcode not installed
- **Solution**: This project REQUIRES macOS with Xcode 16.2+
- **Alternative**: Use Xcode GUI (open MaterialsAndPractices.xcodeproj, press Cmd+U for tests)

#### Build Failures
- **First Step**: Clean build folder (Cmd+Shift+K in Xcode)
- **Check**: Ensure iOS 18.0 simulator is available
- **Verify**: Target iOS version compatibility

#### Test Failures
- **Individual Test**: Run specific test suite with `./run_tests.sh [suite_name]`
- **Simulator Issues**: Reset iOS Simulator (Device > Erase All Content and Settings)
- **Core Data Issues**: Delete app from simulator and reinstall

#### Simulator Not Found
```bash
# List available simulators
xcrun simctl list devices

# Install iOS 18.0 if missing
sudo xcodebuild -downloadPlatform iOS
```

## Code Quality Standards

### Before Committing Changes
1. **Build successfully**: No build errors or warnings
2. **Pass all tests**: All 47 tests must pass
3. **Manual testing**: Verify core functionality works
4. **Architecture compliance**: Follow Clean Architecture patterns
5. **Device testing**: Test on both iPhone and iPad if UI changes

### Architecture Guidelines
- Follow Clean Architecture with Domain, Use Cases, Interface Adapters, and Frameworks layers
- Use SwiftUI for all UI components with adaptive layouts
- **Theme System**: Always use `AppTheme.Colors` and `AppTheme.Typography` instead of hardcoded values
- **Dual Themes**: Support both light mode (farm theme) and dark mode (retro phosphor theme)
- Implement proper Core Data relationships and migrations
- Maintain device-aware responsive design for iPhone and iPad
- Use `SecureConfiguration` for app settings and user preferences

This comprehensive guide ensures efficient development while maintaining the high-quality standards expected for iOS applications targeting organic farming operations.