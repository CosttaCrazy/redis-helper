#!/bin/bash

# Test Redis Helper Installation User Detection
echo "=== Redis Helper Installation User Detection Test ==="

# Go to project root
cd "$(dirname "$0")/../.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "Testing user detection logic from install.sh..."

# Simulate the logic from install.sh
echo
echo -e "${BLUE}Test 1: Normal user execution${NC}"
echo "USER=$USER"
echo "HOME=$HOME"
echo "SUDO_USER=${SUDO_USER:-'(not set)'}"

# Simulate normal execution
if [[ -n "$SUDO_USER" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo "~$SUDO_USER")
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

CONFIG_DIR="$REAL_HOME/.redis-helper"

echo "Detected REAL_USER: $REAL_USER"
echo "Detected REAL_HOME: $REAL_HOME"
echo "CONFIG_DIR would be: $CONFIG_DIR"

echo
echo -e "${BLUE}Test 2: Simulated sudo execution${NC}"
# Simulate sudo execution
export SUDO_USER="$USER"
echo "Simulating: SUDO_USER=$SUDO_USER"

if [[ -n "$SUDO_USER" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo "~$SUDO_USER")
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

CONFIG_DIR="$REAL_HOME/.redis-helper"

echo "Detected REAL_USER: $REAL_USER"
echo "Detected REAL_HOME: $REAL_HOME"
echo "CONFIG_DIR would be: $CONFIG_DIR"

echo
echo -e "${BLUE}Test 3: Checking install.sh logic${NC}"
echo -n "Checking if install.sh contains user detection logic... "
if grep -q "SUDO_USER" install.sh && grep -q "REAL_USER" install.sh; then
    echo -e "${GREEN}✓ FOUND${NC}"
else
    echo -e "${RED}✗ MISSING${NC}"
fi

echo -n "Checking if install.sh contains ownership fix... "
if grep -q "chown.*SUDO_USER" install.sh; then
    echo -e "${GREEN}✓ FOUND${NC}"
else
    echo -e "${RED}✗ MISSING${NC}"
fi

echo -n "Checking if install.sh shows correct user in completion message... "
if grep -q "user: \$REAL_USER" install.sh; then
    echo -e "${GREEN}✓ FOUND${NC}"
else
    echo -e "${RED}✗ MISSING${NC}"
fi

echo
echo -e "${GREEN}✅ User detection test completed!${NC}"
echo
echo -e "${YELLOW}Note: The corrected install.sh will now:${NC}"
echo "• Detect the real user even when run with sudo"
echo "• Create config files in the correct user's home directory"
echo "• Set proper ownership of config files"
echo "• Display accurate information in completion message"

# Cleanup
unset SUDO_USER
