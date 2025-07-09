#!/bin/bash

# Quick Redis Helper Test
echo "=== Redis Helper v1.1 Quick Test ==="

# Go to project root
cd "$(dirname "$0")/../.."

# Test 1: Script syntax
echo -n "1. Script syntax... "
if bash -n redis-helper.sh; then
    echo "✓ OK"
else
    echo "✗ FAIL"
    exit 1
fi

# Test 2: Module syntax
echo -n "2. Module syntax... "
error_count=0
for module in lib/*.sh; do
    if ! bash -n "$module"; then
        echo "✗ Error in $module"
        error_count=$((error_count + 1))
    fi
done

if [[ $error_count -eq 0 ]]; then
    echo "✓ OK (8 modules)"
else
    echo "✗ FAIL ($error_count errors)"
    exit 1
fi

# Test 3: Basic execution
echo -n "3. Basic execution... "
if timeout 3 ./redis-helper.sh --version >/dev/null 2>&1; then
    echo "✓ OK"
else
    echo "✗ FAIL"
    exit 1
fi

# Test 4: Configuration creation
echo -n "4. Configuration... "
if [[ -f config/redis-helper.conf ]]; then
    echo "✓ OK"
else
    echo "✗ FAIL"
    exit 1
fi

# Test 5: Directory structure
echo -n "5. Directories... "
if [[ -d config && -d logs && -d backups && -d metrics && -d lib ]]; then
    echo "✓ OK"
else
    echo "✗ FAIL"
    exit 1
fi

# Test 6: Module files
echo -n "6. Module files... "
expected_modules=("monitoring" "performance" "backup" "security" "cluster" "utilities" "reports" "configuration")
missing_modules=0

for module in "${expected_modules[@]}"; do
    if [[ ! -f "lib/${module}.sh" ]]; then
        echo "Missing: lib/${module}.sh"
        missing_modules=$((missing_modules + 1))
    fi
done

if [[ $missing_modules -eq 0 ]]; then
    echo "✓ OK (${#expected_modules[@]} modules)"
else
    echo "✗ FAIL ($missing_modules missing)"
    exit 1
fi

echo
echo "✅ All basic tests passed!"
echo "📋 Summary:"
echo "   - Script syntax: OK"
echo "   - 8 modules: OK"
echo "   - Execution: OK"
echo "   - Configuration: OK"
echo "   - Directory structure: OK"
echo "   - All modules present: OK"
echo
echo "🚀 Redis Helper v1.1 is ready to use!"
echo "   Run: ./redis-helper.sh"
