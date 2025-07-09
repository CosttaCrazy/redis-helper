#!/bin/bash

# Redis Helper - Test Runner
echo "=== Redis Helper v1.1.0 Test Runner ==="
echo "======================================"

cd "$(dirname "$0")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test categories
UNIT_TESTS=(
    "tests/unit/quick_test.sh"
    "tests/unit/test_functionality_fixed.sh"
    "tests/unit/test_modules.sh"
)

INTEGRATION_TESTS=(
    "tests/integration/test_integration.sh"
    "tests/integration/test_final_fixed.sh"
)

INSTALL_TESTS=(
    "tests/install/test_install_user.sh"
    "tests/install/test_install_final.sh"
    "tests/install/test_symlink.sh"
    "tests/install/test_install_simulation.sh"
)

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Run test function
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "Running $test_name... "
    
    if [[ -x "$test_file" ]] && "$test_file" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Parse arguments
case "${1:-all}" in
    "quick"|"q")
        echo -e "${BLUE}Running Quick Test Only${NC}"
        echo "========================"
        run_test "tests/unit/quick_test.sh"
        ;;
    "unit"|"u")
        echo -e "${BLUE}Running Unit Tests${NC}"
        echo "=================="
        for test in "${UNIT_TESTS[@]}"; do
            run_test "$test"
        done
        ;;
    "integration"|"i")
        echo -e "${BLUE}Running Integration Tests${NC}"
        echo "========================="
        for test in "${INTEGRATION_TESTS[@]}"; do
            run_test "$test"
        done
        ;;
    "install")
        echo -e "${BLUE}Running Installation Tests${NC}"
        echo "=========================="
        for test in "${INSTALL_TESTS[@]}"; do
            run_test "$test"
        done
        ;;
    "all"|"")
        echo -e "${BLUE}Running All Tests${NC}"
        echo "================="
        
        echo -e "\n${CYAN}Unit Tests:${NC}"
        for test in "${UNIT_TESTS[@]}"; do
            run_test "$test"
        done
        
        echo -e "\n${CYAN}Integration Tests:${NC}"
        for test in "${INTEGRATION_TESTS[@]}"; do
            run_test "$test"
        done
        
        echo -e "\n${CYAN}Installation Tests:${NC}"
        for test in "${INSTALL_TESTS[@]}"; do
            run_test "$test"
        done
        ;;
    "help"|"h")
        echo "Redis Helper Test Runner"
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  quick, q        Run quick test only"
        echo "  unit, u         Run unit tests"
        echo "  integration, i  Run integration tests"
        echo "  install         Run installation tests"
        echo "  all (default)   Run all tests"
        echo "  help, h         Show this help"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use 'help' for usage information"
        exit 1
        ;;
esac

# Show results
echo
echo "=================================="
echo -e "${CYAN}Test Results Summary${NC}"
echo "=================================="
echo -e "Total tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed${NC}"
    exit 1
fi
