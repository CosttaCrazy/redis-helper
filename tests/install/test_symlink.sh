#!/bin/bash

# Test Redis Helper Symlink Detection
echo "=== Redis Helper Symlink Detection Test ==="

# Go to project root
cd "$(dirname "$0")/../.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "Testing symlink detection logic..."

# Test the logic from redis-helper.sh
test_script_dir_detection() {
    local test_script="$1"
    
    echo -n "Testing with $test_script... "
    
    # Simulate the detection logic
    if [[ -L "$test_script" ]]; then
        # If script is a symlink, follow it to get the real path
        DETECTED_DIR="$(cd "$(dirname "$(readlink -f "$test_script")")" && pwd)"
        echo -e "${BLUE}(symlink)${NC}"
    else
        # If script is not a symlink, use normal detection
        DETECTED_DIR="$(cd "$(dirname "$test_script")" && pwd)"
        echo -e "${BLUE}(regular file)${NC}"
    fi
    
    echo "  Detected directory: $DETECTED_DIR"
    
    # Check if lib directory exists in detected directory
    if [[ -d "$DETECTED_DIR/lib" ]]; then
        echo -e "  ${GREEN}✓ lib directory found${NC}"
        
        # Count modules
        local module_count=$(find "$DETECTED_DIR/lib" -name "*.sh" | wc -l)
        echo "  Found $module_count modules"
        
        if [[ $module_count -eq 8 ]]; then
            echo -e "  ${GREEN}✓ All 8 modules present${NC}"
            return 0
        else
            echo -e "  ${YELLOW}⚠ Expected 8 modules, found $module_count${NC}"
            return 1
        fi
    else
        echo -e "  ${RED}✗ lib directory not found${NC}"
        return 1
    fi
}

echo
echo -e "${BLUE}Test 1: Current script (regular file)${NC}"
test_script_dir_detection "./redis-helper.sh"

echo
echo -e "${BLUE}Test 2: Simulated symlink test${NC}"
# Create a temporary symlink for testing
temp_link="/tmp/redis-helper-test-link"
ln -sf "$(pwd)/redis-helper.sh" "$temp_link"

test_script_dir_detection "$temp_link"

# Cleanup
rm -f "$temp_link"

echo
echo -e "${BLUE}Test 3: Check if readlink command is available${NC}"
if command -v readlink >/dev/null 2>&1; then
    echo -e "${GREEN}✓ readlink command available${NC}"
    
    # Test readlink with current script
    if readlink -f "./redis-helper.sh" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ readlink -f works correctly${NC}"
    else
        echo -e "${RED}✗ readlink -f failed${NC}"
    fi
else
    echo -e "${RED}✗ readlink command not available${NC}"
    echo -e "${YELLOW}⚠ This may cause issues with symlink detection${NC}"
fi

echo
echo -e "${BLUE}Test 4: Verify current installation structure${NC}"
echo "Current directory: $(pwd)"
echo "Script location: $(pwd)/redis-helper.sh"
echo "Modules directory: $(pwd)/lib"

if [[ -d "lib" ]]; then
    echo -e "${GREEN}✓ lib directory exists${NC}"
    echo "Modules found:"
    ls -la lib/*.sh | while read -r line; do
        echo "  $line"
    done
else
    echo -e "${RED}✗ lib directory missing${NC}"
fi

echo
echo -e "${GREEN}✅ Symlink detection test completed!${NC}"
echo
echo -e "${YELLOW}Note: The corrected redis-helper.sh should now:${NC}"
echo "• Properly detect the real script directory even when run via symlink"
echo "• Find modules in /opt/redis-helper/lib when installed system-wide"
echo "• Work correctly both in development and installed environments"
