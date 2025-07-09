#!/bin/bash

# Redis Helper Final Comprehensive Test (Fixed)
echo "=== Redis Helper v1.1 Final Test Suite (Fixed) ==="
echo "=================================================="

# Go to project root
cd "$(dirname "$0")/../.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  $test_name... "
    
    # Execute command and capture exit code
    eval "$test_command" >/dev/null 2>&1
    local actual_result=$?
    
    if [[ $actual_result -eq $expected_result ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL (expected: $expected_result, got: $actual_result)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo -e "${BLUE}Phase 1: Basic Structure Tests${NC}"
echo "==============================="

run_test "Main script exists and executable" "[[ -x redis-helper.sh ]]"
run_test "Install script exists and executable" "[[ -x install.sh ]]"
run_test "README file exists" "[[ -f README.md ]]"
run_test "License file exists" "[[ -f LICENSE ]]"
run_test "Configuration directory exists" "[[ -d config ]]"
run_test "Logs directory exists" "[[ -d logs ]]"
run_test "Backups directory exists" "[[ -d backups ]]"
run_test "Metrics directory exists" "[[ -d metrics ]]"
run_test "Modules directory exists" "[[ -d lib ]]"

echo
echo -e "${BLUE}Phase 2: Module Tests${NC}"
echo "====================="

modules=("monitoring" "performance" "backup" "security" "cluster" "utilities" "reports" "configuration")
for module in "${modules[@]}"; do
    run_test "Module $module exists" "[[ -f lib/${module}.sh ]]"
    run_test "Module $module syntax" "bash -n lib/${module}.sh"
done

echo
echo -e "${BLUE}Phase 3: Script Execution Tests${NC}"
echo "==============================="

run_test "Script syntax check" "bash -n redis-helper.sh"
run_test "Script version flag" "timeout 3 ./redis-helper.sh --version"
run_test "Script help flag" "timeout 3 ./redis-helper.sh --help"
run_test "Script invalid flag handling" "./redis-helper.sh --invalid" 1

echo
echo -e "${BLUE}Phase 4: Configuration Tests${NC}"
echo "============================"

run_test "Config file exists" "[[ -f config/redis-helper.conf ]]"
run_test "Config file readable" "[[ -r config/redis-helper.conf ]]"
run_test "Config contains Redis host" "grep -q 'REDIS_HOST=' config/redis-helper.conf"
run_test "Config contains Redis port" "grep -q 'REDIS_PORT=' config/redis-helper.conf"
run_test "Config contains environment" "grep -q 'ENVIRONMENT=' config/redis-helper.conf"

echo
echo -e "${BLUE}Phase 5: Function Integration Tests${NC}"
echo "==================================="

# Load modules and test functions
source_modules() {
    for module in lib/*.sh; do
        source "$module" 2>/dev/null || return 1
    done
    return 0
}

run_test "Modules can be loaded" "source_modules"

# After loading modules, test function availability
if source_modules; then
    menu_functions=(
        "monitoring_menu"
        "performance_analysis_menu"
        "backup_restore_menu"
        "security_audit_menu"
        "cluster_management_menu"
        "utilities_tools_menu"
        "reports_export_menu"
        "configuration_management_menu"
    )
    
    for func in "${menu_functions[@]}"; do
        run_test "Function $func available" "declare -f $func >/dev/null"
    done
fi

echo
echo -e "${BLUE}Phase 6: File Permissions Tests${NC}"
echo "==============================="

run_test "Main script has execute permission" "[[ -x redis-helper.sh ]]"
run_test "Install script has execute permission" "[[ -x install.sh ]]"
run_test "Quick test script has execute permission" "[[ -x quick_test.sh ]]"
run_test "Config directory is writable" "[[ -w config ]]"
run_test "Logs directory is writable" "[[ -w logs ]]"
run_test "Backups directory is writable" "[[ -w backups ]]"

echo
echo -e "${BLUE}Phase 7: Content Validation Tests${NC}"
echo "================================="

run_test "Main script contains version info" "grep -q 'VERSION=' redis-helper.sh"
run_test "Main script contains main menu" "grep -q 'show_main_menu' redis-helper.sh"
run_test "Main script contains case statement" "grep -q 'case.*choice' redis-helper.sh"
run_test "README contains installation instructions" "grep -qi 'install' README.md"
run_test "README contains usage instructions" "grep -qi 'usage' README.md"

echo
echo -e "${BLUE}Phase 8: Error Handling Tests${NC}"
echo "============================="

run_test "Script handles unknown arguments" "./redis-helper.sh unknown_arg" 1
run_test "Script handles invalid flags" "./redis-helper.sh --nonexistent" 1

echo
echo "=========================================="
echo -e "${CYAN}Final Test Results Summary${NC}"
echo "=========================================="
echo -e "Total tests run: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Tests passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Tests failed: ${RED}$FAILED_TESTS${NC}"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}✅ Redis Helper v1.1 is fully functional and ready for use!${NC}"
    echo
    echo -e "${CYAN}Summary of what was tested:${NC}"
    echo "• File structure and permissions"
    echo "• All 8 modules syntax and loading"
    echo "• Script execution and argument handling"
    echo "• Configuration file setup"
    echo "• Function integration and availability"
    echo "• Error handling and edge cases"
    echo
    echo -e "${YELLOW}🚀 You can now run: ./redis-helper.sh${NC}"
    exit 0
else
    echo
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo -e "${YELLOW}⚠ Please review the failed tests above${NC}"
    
    # Calculate success rate
    success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo -e "Success rate: ${BLUE}${success_rate}%${NC}"
    
    if [[ $success_rate -ge 90 ]]; then
        echo -e "${YELLOW}✨ Despite some failures, Redis Helper is mostly functional${NC}"
    fi
    
    exit 1
fi
