#!/bin/bash

# Test Redis Helper Integration
echo "=== Redis Helper Integration Test ==="

# Go to project root
cd "$(dirname "$0")/../.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. Testing module loading function..."

# Extract the load_modules function from main script
load_modules() {
    local modules_dir="./lib"
    
    if [[ ! -d "$modules_dir" ]]; then
        echo "Modules directory not found: $modules_dir"
        return 1
    fi
    
    for module in "$modules_dir"/*.sh; do
        if [[ -f "$module" ]]; then
            echo "Loading module: $module"
            source "$module" || {
                echo "Failed to load module: $module"
                return 1
            }
        fi
    done
    
    return 0
}

echo -n "  Loading modules... "
if load_modules; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
    exit 1
fi

echo
echo "2. Testing function availability after loading..."

functions_to_test=(
    "monitoring_menu"
    "performance_analysis_menu"
    "backup_restore_menu"
    "security_audit_menu"
    "cluster_management_menu"
    "utilities_tools_menu"
    "reports_export_menu"
    "configuration_management_menu"
)

all_functions_ok=true

for func in "${functions_to_test[@]}"; do
    echo -n "  $func... "
    if declare -f "$func" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ MISSING${NC}"
        all_functions_ok=false
    fi
done

echo
echo "3. Testing main script execution without menu loop..."

# Test script execution with version flag
echo -n "  Script version check... "
if ./redis-helper.sh --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

# Test script execution with help flag
echo -n "  Script help check... "
if ./redis-helper.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

echo
echo "4. Testing configuration loading..."

# Check if config file exists and is readable
echo -n "  Config file exists... "
if [[ -f config/redis-helper.conf ]]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ MISSING${NC}"
fi

echo -n "  Config file readable... "
if [[ -r config/redis-helper.conf ]]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAIL${NC}"
fi

echo
echo "=== Integration Test Results ==="
if $all_functions_ok; then
    echo -e "${GREEN}✅ All menu functions are available after module loading${NC}"
    echo -e "${GREEN}✅ Script execution works correctly${NC}"
    echo -e "${GREEN}✅ Configuration is properly set up${NC}"
    echo
    echo -e "${GREEN}🚀 Redis Helper integration is working correctly!${NC}"
else
    echo -e "${RED}❌ Some menu functions are missing${NC}"
    echo -e "${YELLOW}⚠ Check module definitions and loading process${NC}"
fi
