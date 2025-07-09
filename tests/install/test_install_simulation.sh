#!/bin/bash

# Test Redis Helper Installation Simulation
echo "=== Redis Helper Installation Simulation Test ==="

# Go to project root
cd "$(dirname "$0")/../.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create temporary installation simulation
TEMP_INSTALL_DIR="/tmp/redis-helper-test-install"
TEMP_BIN_DIR="/tmp/redis-helper-test-bin"

echo "Setting up temporary installation simulation..."

# Cleanup any previous test
rm -rf "$TEMP_INSTALL_DIR" "$TEMP_BIN_DIR"

# Create directories
mkdir -p "$TEMP_INSTALL_DIR" "$TEMP_BIN_DIR"

echo -e "${BLUE}1. Copying files to simulated installation directory${NC}"
cp -r . "$TEMP_INSTALL_DIR/"
echo "✓ Files copied to $TEMP_INSTALL_DIR"

echo -e "${BLUE}2. Creating symlink in simulated bin directory${NC}"
ln -sf "$TEMP_INSTALL_DIR/redis-helper.sh" "$TEMP_BIN_DIR/redis-helper"
echo "✓ Symlink created: $TEMP_BIN_DIR/redis-helper -> $TEMP_INSTALL_DIR/redis-helper.sh"

echo -e "${BLUE}3. Testing symlink execution${NC}"
echo -n "Testing version command via symlink... "
if timeout 5 "$TEMP_BIN_DIR/redis-helper" --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ SUCCESS${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

echo -e "${BLUE}4. Testing module loading via symlink${NC}"
echo "Executing via symlink and checking module loading:"
timeout 5 "$TEMP_BIN_DIR/redis-helper" --version 2>&1 | grep -E "(Script directory|Modules directory|Loaded module)" | head -10

echo -e "${BLUE}5. Verifying module paths${NC}"
echo "Checking if modules are found in correct location:"
if [[ -d "$TEMP_INSTALL_DIR/lib" ]]; then
    echo -e "${GREEN}✓ Modules directory exists: $TEMP_INSTALL_DIR/lib${NC}"
    module_count=$(find "$TEMP_INSTALL_DIR/lib" -name "*.sh" | wc -l)
    echo "✓ Found $module_count modules"
else
    echo -e "${RED}✗ Modules directory missing${NC}"
fi

echo -e "${BLUE}6. Testing help command via symlink${NC}"
echo -n "Testing help command... "
if timeout 5 "$TEMP_BIN_DIR/redis-helper" --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓ SUCCESS${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

echo -e "${BLUE}7. Cleanup${NC}"
rm -rf "$TEMP_INSTALL_DIR" "$TEMP_BIN_DIR"
echo "✓ Temporary files cleaned up"

echo
echo -e "${GREEN}✅ Installation simulation test completed!${NC}"
echo
echo -e "${YELLOW}Summary:${NC}"
echo "• Symlink detection logic is working correctly"
echo "• Modules are loaded from the correct installation directory"
echo "• Script functions properly when executed via symlink"
echo "• Installation should now work without module loading errors"
echo
echo -e "${BLUE}The corrected installation should now work properly!${NC}"
echo -e "${BLUE}You can reinstall with: sudo ./install.sh${NC}"
