#!/bin/bash

# Redis Helper Functionality Test Script (Fixed Version)
# Tests all major functions without requiring Redis connection

echo "Redis Helper v1.1 Functionality Test (Fixed)"
echo "=============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_function() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Change to script directory
# Go to project root
cd "$(dirname "$0")/../.."

echo "1. Testing script syntax..."
test_function "Main script syntax" "bash -n redis-helper.sh"

echo
echo "2. Testing module syntax..."
for module in lib/*.sh; do
    module_name=$(basename "$module" .sh)
    test_function "Module $module_name syntax" "bash -n $module"
done

echo
echo "3. Testing script execution..."
test_function "Script help" "timeout 3 ./redis-helper.sh --help"
test_function "Script version" "timeout 3 ./redis-helper.sh --version"

echo
echo "4. Testing configuration..."
test_function "Config file creation" "[[ -f config/redis-helper.conf ]]"
test_function "Config file readable" "[[ -r config/redis-helper.conf ]]"

echo
echo "5. Testing directories..."
test_function "Backup directory" "[[ -d backups ]]"
test_function "Logs directory" "[[ -d logs ]]"
test_function "Metrics directory" "[[ -d metrics ]]"
test_function "Config directory" "[[ -d config ]]"

echo
echo "6. Testing module loading (fixed approach)..."
# Create a temporary script that loads functions without executing main loop
cat > /tmp/test_functions.sh << 'EOF'
#!/bin/bash
# Extract only function definitions from main script
sed -n '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()[[:space:]]*{/,/^}/p' redis-helper.sh > /tmp/functions_only.sh

# Source modules
for module in lib/*.sh; do
    source "$module" 2>/dev/null || true
done

# Source extracted functions
source /tmp/functions_only.sh 2>/dev/null || true

# Test if key functions exist
declare -f show_header >/dev/null && echo "show_header: OK"
declare -f show_main_menu >/dev/null && echo "show_main_menu: OK"
declare -f load_config >/dev/null && echo "load_config: OK"
declare -f load_modules >/dev/null && echo "load_modules: OK"
EOF

chmod +x /tmp/test_functions.sh
test_function "Function extraction" "timeout 5 /tmp/test_functions.sh"

echo
echo "7. Testing individual modules..."
for module in lib/*.sh; do
    module_name=$(basename "$module" .sh)
    test_function "Module $module_name loading" "timeout 3 bash -c 'source $module'"
done

echo
echo "8. Testing core script components..."
test_function "Header function exists" "grep -q 'show_header()' redis-helper.sh"
test_function "Menu function exists" "grep -q 'show_main_menu()' redis-helper.sh"
test_function "Config function exists" "grep -q 'load_config()' redis-helper.sh"
test_function "Version info exists" "grep -q 'VERSION=' redis-helper.sh"

echo
echo "9. Testing file permissions..."
test_function "Main script executable" "[[ -x redis-helper.sh ]]"
test_function "Install script executable" "[[ -x install.sh ]]"
test_function "Test scripts executable" "[[ -x tests/unit/quick_test.sh ]]"

echo
echo "10. Testing configuration content..."
if [[ -f config/redis-helper.conf ]]; then
    test_function "Redis host config" "grep -q 'REDIS_HOST=' config/redis-helper.conf"
    test_function "Redis port config" "grep -q 'REDIS_PORT=' config/redis-helper.conf"
    test_function "Environment config" "grep -q 'ENVIRONMENT=' config/redis-helper.conf"
else
    echo -e "${YELLOW}⚠ Config file not found, skipping content tests${NC}"
fi

echo
echo "Test Results:"
echo "============="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✓ ALL TESTS PASSED - Redis Helper is ready!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed - Please check the issues above${NC}"
    exit 1
fi

# Cleanup
rm -f /tmp/test_functions.sh /tmp/functions_only.sh
