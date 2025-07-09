#!/bin/bash

# Test specific menu functionality
# Go to project root
cd "$(dirname "$0")/../.."

echo "=== Testing Menu Functionality ==="

# Source the main script to load functions
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""
export REDIS_DB="0"
export ENVIRONMENT="development"
export MEMORY_THRESHOLD="80"
export CONNECTION_THRESHOLD="100"
export LATENCY_THRESHOLD="100"
export BACKUP_RETENTION_DAYS="7"
export BACKUP_COMPRESSION="true"
export AUTO_BACKUP="false"
export BACKUP_SCHEDULE="0 2 * * *"
export LOG_LEVEL="INFO"

# Load configuration and modules
SCRIPT_DIR="$(pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/redis-helper.conf"
LOG_FILE="$SCRIPT_DIR/logs/redis-helper.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
METRICS_DIR="$SCRIPT_DIR/metrics"

# Create directories
mkdir -p config logs backups metrics lib

# Load functions without executing main loop
source <(sed '/^case.*menu/,$d' redis-helper.sh)

echo "Testing function availability:"

# Test core functions
functions_to_test=(
    "show_header"
    "show_main_menu"
    "load_config"
    "load_modules"
    "configuration_management_menu"
    "utilities_tools_menu"
    "reports_export_menu"
    "security_audit_menu"
    "cluster_management_menu"
    "performance_analysis_menu"
    "backup_restore_menu"
    "monitoring_menu"
)

for func in "${functions_to_test[@]}"; do
    echo -n "  $func... "
    if declare -f "$func" >/dev/null 2>&1; then
        echo "✓ Available"
    else
        echo "✗ Missing"
    fi
done

echo
echo "=== Menu 7 (Configuration Management) Test ==="
if declare -f configuration_management_menu >/dev/null 2>&1; then
    echo "✓ Configuration Management menu is available"
    echo "  Functions should include:"
    echo "  - configure_redis_connection"
    echo "  - manage_environments" 
    echo "  - configure_monitoring_thresholds"
    echo "  - configure_backup_settings"
else
    echo "✗ Configuration Management menu is NOT available"
fi

echo
echo "=== Menu 8 (Utilities & Tools) Test ==="
if declare -f utilities_tools_menu >/dev/null 2>&1; then
    echo "✓ Utilities & Tools menu is available"
    echo "  Functions should include:"
    echo "  - analyze_key_patterns"
    echo "  - ttl_management"
    echo "  - bulk_operations"
    echo "  - enhanced_redis_cli"
else
    echo "✗ Utilities & Tools menu is NOT available"
fi

echo
echo "=== Testing Configuration File ==="
if [[ -f "$CONFIG_FILE" ]]; then
    echo "✓ Configuration file exists: $CONFIG_FILE"
    echo "Content preview:"
    head -10 "$CONFIG_FILE" | sed 's/^/  /'
else
    echo "✗ Configuration file missing"
fi
