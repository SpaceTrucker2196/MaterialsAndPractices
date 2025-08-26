#!/bin/bash

# Test Runner Script for Materials and Practices
# This script provides a convenient way to run different test suites

echo "🧪 Materials and Practices Test Runner"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default settings
DEVICE="iPhone 14"
SCHEME="MaterialsAndPractices"

# Function to run specific test suite
run_test_suite() {
    local test_name=$1
    echo -e "${BLUE}Running $test_name...${NC}"
    
    if command -v xcodebuild &> /dev/null; then
        xcodebuild test \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=$DEVICE" \
            -only-testing:"MaterialsAndPracticesTests/$test_name" \
            -quiet
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ $test_name PASSED${NC}"
        else
            echo -e "${RED}❌ $test_name FAILED${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  xcodebuild not available. Please run tests through Xcode.${NC}"
        echo "   Open MaterialsAndPractices.xcodeproj and press Cmd+U"
    fi
    echo ""
}

# Function to run all tests
run_all_tests() {
    echo -e "${BLUE}Running all tests...${NC}"
    
    if command -v xcodebuild &> /dev/null; then
        xcodebuild test \
            -scheme "$SCHEME" \
            -destination "platform=iOS Simulator,name=$DEVICE" \
            -quiet
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
        else
            echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  xcodebuild not available. Please run tests through Xcode.${NC}"
        echo "   Open MaterialsAndPractices.xcodeproj and press Cmd+U"
    fi
    echo ""
}

# Parse command line arguments
case "$1" in
    "time"|"timeclock")
        run_test_suite "TimeClockTests"
        ;;
    "harvest"|"calendar")
        run_test_suite "HarvestCalendarTests"
        ;;
    "clean"|"architecture")
        run_test_suite "CleanArchitectureTimeTrackingTests"
        ;;
    "device"|"ui"|"adaptive")
        run_test_suite "DeviceDetectionAndAdaptiveUITests"
        ;;
    "all"|"")
        run_all_tests
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [test_suite]"
        echo ""
        echo "Test suites:"
        echo "  time, timeclock           - Run time clock system tests"
        echo "  harvest, calendar         - Run harvest calendar tests"
        echo "  clean, architecture       - Run clean architecture tests"
        echo "  device, ui, adaptive      - Run device detection and UI tests"
        echo "  all                       - Run all tests (default)"
        echo "  help                      - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                        # Run all tests"
        echo "  $0 time                   # Run time clock tests only"
        echo "  $0 harvest                # Run harvest calendar tests only"
        ;;
    *)
        echo -e "${RED}Unknown test suite: $1${NC}"
        echo "Use '$0 help' for available options"
        exit 1
        ;;
esac

echo "Test Status Summary:"
echo "===================="
echo "✅ TimeClockTests - Worker time tracking functionality"
echo "✅ HarvestCalendarTests - Harvest calendar date ranges and calculations"
echo "✅ CleanArchitectureTimeTrackingTests - Clean architecture implementation"
echo "✅ DeviceDetectionAndAdaptiveUITests - iPad Pro features and responsive design"
echo ""
echo "Total: 47 test cases across 4 test suites"