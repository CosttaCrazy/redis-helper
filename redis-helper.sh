#!/bin/bash

# Redis Helper v1.0
# Advanced Redis monitoring, management and optimization tool
# Licensed under GPLv3
# Author: Community Project

VERSION="1.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/redis-helper.conf"
LOG_FILE="$SCRIPT_DIR/logs/redis-helper.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
METRICS_DIR="$SCRIPT_DIR/metrics"

# Create necessary directories
mkdir -p "$SCRIPT_DIR/config" "$SCRIPT_DIR/logs" "$SCRIPT_DIR/backups" "$SCRIPT_DIR/metrics" "$SCRIPT_DIR/lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# Redis Helper Configuration File

# Default Redis Connection
REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD=""
REDIS_DB="0"

# Environment Settings
ENVIRONMENT="development"
LOG_LEVEL="INFO"
MAX_LOG_SIZE="10M"

# Monitoring Thresholds
MEMORY_THRESHOLD="80"
CONNECTION_THRESHOLD="100"
LATENCY_THRESHOLD="100"

# Backup Settings
BACKUP_RETENTION_DAYS="7"
BACKUP_COMPRESSION="true"
AUTO_BACKUP="false"
BACKUP_SCHEDULE="0 2 * * *"

# Performance Settings
SLOWLOG_THRESHOLD="10000"
MAX_CLIENTS_WARNING="50"

# Multiple Environments Support
declare -A ENVIRONMENTS
ENVIRONMENTS[development]="localhost:6379"
ENVIRONMENTS[staging]="redis-staging.local:6379"
ENVIRONMENTS[production]="redis-prod.local:6379"
EOF
    echo -e "${GREEN}✓ Default configuration created at $CONFIG_FILE${NC}"
}

# Load modules
load_modules() {
    local modules=("monitoring" "performance" "backup" "security" "cluster" "utilities" "reports")
    
    for module in "${modules[@]}"; do
        local module_file="$SCRIPT_DIR/lib/${module}.sh"
        if [[ -f "$module_file" ]]; then
            source "$module_file"
        else
            log "WARN" "Module not found: $module_file"
        fi
    done
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR") echo -e "${RED}[ERROR] $message${NC}" ;;
        "WARN")  echo -e "${YELLOW}[WARN] $message${NC}" ;;
        "INFO")  echo -e "${GREEN}[INFO] $message${NC}" ;;
        "DEBUG") [[ "$LOG_LEVEL" == "DEBUG" ]] && echo -e "${BLUE}[DEBUG] $message${NC}" ;;
    esac
}

# Redis connection test
test_redis_connection() {
    local host="${1:-$REDIS_HOST}"
    local port="${2:-$REDIS_PORT}"
    local password="${3:-$REDIS_PASSWORD}"
    
    local cmd="redis-cli -h $host -p $port"
    [[ -n "$password" ]] && cmd="$cmd -a $password"
    
    if $cmd ping > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get Redis info
get_redis_info() {
    local section="${1:-all}"
    local cmd="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
    [[ -n "$REDIS_PASSWORD" ]] && cmd="$cmd -a $REDIS_PASSWORD"
    
    $cmd info "$section" 2>/dev/null
}

# Header display
show_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Redis Helper v$VERSION                     ║${NC}"
    echo -e "${BLUE}║              Advanced Redis Management Tool                  ║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║ Environment: ${WHITE}$ENVIRONMENT${BLUE}                                    ║${NC}"
    echo -e "${BLUE}║ Host: ${WHITE}$REDIS_HOST:$REDIS_PORT${BLUE}                               ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Connection status
show_connection_status() {
    if test_redis_connection; then
        echo -e "${GREEN}● Redis Status: CONNECTED${NC}"
        local version=$(get_redis_info server | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
        echo -e "${GREEN}● Redis Version: $version${NC}"
    else
        echo -e "${RED}● Redis Status: DISCONNECTED${NC}"
        return 1
    fi
}

# Main menu
show_main_menu() {
    echo -e "${CYAN}┌─ Main Menu ─────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} 1)  Connection & Basic Info                                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 2)  Real-time Monitoring                                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 3)  Performance Analysis                                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 4)  Backup & Restore                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 5)  Security & Audit                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 6)  Cluster Management                                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 7)  Configuration Management                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 8)  Utilities & Tools                                      ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 9)  Reports & Export                                       ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} 0)  Exit                                                   ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Connection & Basic Info Menu
connection_menu() {
    while true; do
        show_header
        show_connection_status || { read -p "Press Enter to continue..."; return; }
        
        echo -e "${CYAN}┌─ Connection & Basic Info ───────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Test Connection                                         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) Server Information                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Memory Usage                                            ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Client Connections                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Database Statistics                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Connect to Redis CLI                                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) test_connection_detailed ;;
            2) show_server_info ;;
            3) show_memory_usage ;;
            4) show_client_connections ;;
            5) show_database_stats ;;
            6) connect_redis_cli ;;
            0) return ;;
            *) log "WARN" "Invalid option: $choice" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Detailed connection test
test_connection_detailed() {
    echo -e "${YELLOW}Testing Redis connection...${NC}"
    
    if test_redis_connection; then
        log "INFO" "Redis connection successful"
        echo -e "${GREEN}✓ Connection: SUCCESS${NC}"
        
        # Get basic info
        local info=$(get_redis_info server)
        local version=$(echo "$info" | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
        local uptime=$(echo "$info" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r')
        local uptime_days=$((uptime / 86400))
        
        echo -e "${GREEN}✓ Version: $version${NC}"
        echo -e "${GREEN}✓ Uptime: $uptime_days days${NC}"
        
        # Test latency
        local start_time=$(date +%s%N)
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ping > /dev/null
        local end_time=$(date +%s%N)
        local latency=$(( (end_time - start_time) / 1000000 ))
        
        echo -e "${GREEN}✓ Latency: ${latency}ms${NC}"
        
        if [[ $latency -gt $LATENCY_THRESHOLD ]]; then
            log "WARN" "High latency detected: ${latency}ms"
            echo -e "${YELLOW}⚠ Warning: High latency detected${NC}"
        fi
    else
        log "ERROR" "Redis connection failed"
        echo -e "${RED}✗ Connection: FAILED${NC}"
        echo -e "${RED}✗ Please check your configuration${NC}"
    fi
}

# Show server information
show_server_info() {
    echo -e "${YELLOW}Redis Server Information:${NC}"
    echo "================================"
    
    local info=$(get_redis_info server)
    echo "$info" | while IFS=: read -r key value; do
        case "$key" in
            "redis_version"|"redis_mode"|"os"|"arch_bits"|"process_id"|"tcp_port")
                printf "%-20s: %s\n" "$key" "$value"
                ;;
        esac
    done
}

# Show memory usage with visual indicators
show_memory_usage() {
    echo -e "${YELLOW}Redis Memory Usage:${NC}"
    echo "================================"
    
    local info=$(get_redis_info memory)
    local used_memory=$(echo "$info" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(echo "$info" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local used_memory_peak_human=$(echo "$info" | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$info" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    
    echo -e "Used Memory:      ${WHITE}$used_memory_human${NC}"
    echo -e "Peak Memory:      ${WHITE}$used_memory_peak_human${NC}"
    
    if [[ "$maxmemory" != "0" ]]; then
        local usage_percent=$(( (used_memory * 100) / maxmemory ))
        echo -e "Memory Usage:     ${WHITE}$usage_percent%${NC}"
        
        # Visual progress bar
        local bar_length=50
        local filled_length=$(( (usage_percent * bar_length) / 100 ))
        local bar=""
        
        for ((i=0; i<filled_length; i++)); do bar+="█"; done
        for ((i=filled_length; i<bar_length; i++)); do bar+="░"; done
        
        if [[ $usage_percent -gt $MEMORY_THRESHOLD ]]; then
            echo -e "${RED}[$bar] $usage_percent%${NC}"
            log "WARN" "High memory usage: $usage_percent%"
        else
            echo -e "${GREEN}[$bar] $usage_percent%${NC}"
        fi
    fi
}

# Show client connections
show_client_connections() {
    echo -e "${YELLOW}Client Connections:${NC}"
    echo "================================"
    
    local info=$(get_redis_info clients)
    local connected_clients=$(echo "$info" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    local client_recent_max_input_buffer=$(echo "$info" | grep "client_recent_max_input_buffer:" | cut -d: -f2 | tr -d '\r')
    
    echo -e "Connected Clients: ${WHITE}$connected_clients${NC}"
    
    if [[ $connected_clients -gt $MAX_CLIENTS_WARNING ]]; then
        echo -e "${YELLOW}⚠ Warning: High number of connections${NC}"
        log "WARN" "High number of connections: $connected_clients"
    fi
    
    echo
    echo -e "${YELLOW}Client List:${NC}"
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} client list | head -10
}

# Connect to Redis CLI
connect_redis_cli() {
    echo -e "${GREEN}Connecting to Redis CLI...${NC}"
    echo -e "${YELLOW}Type 'quit' or press Ctrl+C to exit${NC}"
    echo
    
    local cmd="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
    [[ -n "$REDIS_PASSWORD" ]] && cmd="$cmd -a $REDIS_PASSWORD"
    [[ "$REDIS_DB" != "0" ]] && cmd="$cmd -n $REDIS_DB"
    
    $cmd
}

# Load configuration and start
load_config

# Main execution
case "${1:-menu}" in
    "menu"|"")
        while true; do
            show_header
            show_connection_status
            echo
            show_main_menu
            echo -n "Select option: "
            read -r choice
            
            case $choice in
                1) connection_menu ;;
                2) monitoring_menu ;;
                3) performance_analysis_menu ;;
                4) backup_restore_menu ;;
                5) security_audit_menu ;;
                6) cluster_management_menu ;;
                7) echo "Configuration management - Coming soon" ;;
                8) utilities_tools_menu ;;
                9) reports_export_menu ;;
                0) 
                    echo -e "${GREEN}Thank you for using Redis Helper!${NC}"
                    exit 0
                    ;;
                *) 
                    log "WARN" "Invalid menu option: $choice"
                    echo -e "${RED}Invalid option!${NC}"
                    ;;
            esac
            
            [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
        done
        ;;
    "--version"|"-v")
        echo "Redis Helper v$VERSION"
        ;;
    "--help"|"-h")
        echo "Redis Helper v$VERSION - Advanced Redis Management Tool"
        echo "Usage: $0 [option]"
        echo "Options:"
        echo "  menu, (default)  - Interactive menu"
        echo "  --version, -v    - Show version"
        echo "  --help, -h       - Show this help"
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
