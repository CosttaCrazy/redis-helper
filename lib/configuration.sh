#!/bin/bash

# Redis Helper - Configuration Management Module v1.1
# Licensed under GPLv3

# Configuration management menu
configuration_management_menu() {
    while true; do
        show_header
        echo -e "${CYAN}┌─ Configuration Management ──────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Redis Connection Settings                               ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) Environment Management                                  ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Monitoring Thresholds                                   ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Backup Configuration                                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Redis Server Configuration                              ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Export/Import Settings                                  ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 7) Reset to Defaults                                       ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 8) Configuration Validation                                ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 9) View Current Configuration                              ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) configure_redis_connection ;;
            2) manage_environments ;;
            3) configure_monitoring_thresholds ;;
            4) configure_backup_settings ;;
            5) manage_redis_server_config ;;
            6) export_import_settings ;;
            7) reset_to_defaults ;;
            8) validate_configuration ;;
            9) view_current_configuration ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Configure Redis connection
configure_redis_connection() {
    echo -e "${YELLOW}Redis Connection Configuration${NC}"
    echo "================================"
    
    echo "Current Redis connection settings:"
    echo "Host: $REDIS_HOST"
    echo "Port: $REDIS_PORT"
    echo "Password: $(if [[ -n "$REDIS_PASSWORD" ]]; then echo "***SET***"; else echo "Not set"; fi)"
    echo "Database: $REDIS_DB"
    echo
    
    echo "What would you like to configure?"
    echo "1) Change Redis host"
    echo "2) Change Redis port"
    echo "3) Set/change password"
    echo "4) Change database number"
    echo "5) Test connection with new settings"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r config_choice
    
    case $config_choice in
        1)
            echo -n "Enter new Redis host [$REDIS_HOST]: "
            read -r new_host
            if [[ -n "$new_host" ]]; then
                update_config_value "REDIS_HOST" "$new_host"
                REDIS_HOST="$new_host"
                echo -e "${GREEN}✓ Redis host updated to: $new_host${NC}"
            fi
            ;;
        2)
            echo -n "Enter new Redis port [$REDIS_PORT]: "
            read -r new_port
            if [[ -n "$new_port" ]] && [[ "$new_port" =~ ^[0-9]+$ ]]; then
                update_config_value "REDIS_PORT" "$new_port"
                REDIS_PORT="$new_port"
                echo -e "${GREEN}✓ Redis port updated to: $new_port${NC}"
            else
                echo -e "${RED}✗ Invalid port number${NC}"
            fi
            ;;
        3)
            echo -n "Enter Redis password (leave empty to remove): "
            read -rs new_password
            echo
            update_config_value "REDIS_PASSWORD" "$new_password"
            REDIS_PASSWORD="$new_password"
            if [[ -n "$new_password" ]]; then
                echo -e "${GREEN}✓ Redis password updated${NC}"
            else
                echo -e "${GREEN}✓ Redis password removed${NC}"
            fi
            ;;
        4)
            echo -n "Enter database number [$REDIS_DB]: "
            read -r new_db
            if [[ -n "$new_db" ]] && [[ "$new_db" =~ ^[0-9]+$ ]]; then
                update_config_value "REDIS_DB" "$new_db"
                REDIS_DB="$new_db"
                echo -e "${GREEN}✓ Database number updated to: $new_db${NC}"
            else
                echo -e "${RED}✗ Invalid database number${NC}"
            fi
            ;;
        5)
            echo "Testing connection with current settings..."
            if test_redis_connection; then
                echo -e "${GREEN}✓ Connection successful!${NC}"
            else
                echo -e "${RED}✗ Connection failed!${NC}"
                echo "Please check your settings and Redis server status."
            fi
            ;;
        0)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Manage environments
manage_environments() {
    echo -e "${YELLOW}Environment Management${NC}"
    echo "================================"
    
    echo "Current environment: $ENVIRONMENT"
    echo
    echo "Available environments:"
    
    # Show configured environments
    local env_count=1
    for env in development staging production; do
        local env_config="ENVIRONMENTS[$env]"
        echo "$env_count) $env"
        env_count=$((env_count + 1))
    done
    
    echo "4) Add new environment"
    echo "5) Switch environment"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r env_choice
    
    case $env_choice in
        1|2|3)
            local envs=(development staging production)
            local selected_env=${envs[$((env_choice - 1))]}
            echo "Environment: $selected_env"
            # Show environment details if configured
            ;;
        4)
            echo -n "Enter new environment name: "
            read -r new_env
            if [[ -n "$new_env" ]]; then
                echo -n "Enter Redis host:port for $new_env: "
                read -r env_config
                if [[ -n "$env_config" ]]; then
                    # Add to configuration
                    echo "ENVIRONMENTS[$new_env]=\"$env_config\"" >> "$CONFIG_FILE"
                    echo -e "${GREEN}✓ Environment $new_env added${NC}"
                fi
            fi
            ;;
        5)
            echo "Available environments:"
            echo "1) development"
            echo "2) staging" 
            echo "3) production"
            echo -n "Select environment to switch to: "
            read -r switch_choice
            
            case $switch_choice in
                1) switch_environment "development" ;;
                2) switch_environment "staging" ;;
                3) switch_environment "production" ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
        0)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Switch environment
switch_environment() {
    local new_env="$1"
    
    echo "Switching to environment: $new_env"
    
    # Update environment in config
    update_config_value "ENVIRONMENT" "$new_env"
    ENVIRONMENT="$new_env"
    
    # Load environment-specific settings if available
    case "$new_env" in
        "development")
            update_config_value "REDIS_HOST" "localhost"
            update_config_value "REDIS_PORT" "6379"
            REDIS_HOST="localhost"
            REDIS_PORT="6379"
            ;;
        "staging")
            update_config_value "REDIS_HOST" "redis-staging.local"
            update_config_value "REDIS_PORT" "6379"
            REDIS_HOST="redis-staging.local"
            REDIS_PORT="6379"
            ;;
        "production")
            update_config_value "REDIS_HOST" "redis.cilia-oficinas.local"
            update_config_value "REDIS_PORT" "6379"
            REDIS_HOST="redis.cilia-oficinas.local"
            REDIS_PORT="6379"
            ;;
    esac
    
    echo -e "${GREEN}✓ Switched to $new_env environment${NC}"
    echo "Host: $REDIS_HOST:$REDIS_PORT"
}

# Configure monitoring thresholds
configure_monitoring_thresholds() {
    echo -e "${YELLOW}Monitoring Thresholds Configuration${NC}"
    echo "================================"
    
    echo "Current thresholds:"
    echo "Memory threshold: $MEMORY_THRESHOLD%"
    echo "Connection threshold: $CONNECTION_THRESHOLD"
    echo "Latency threshold: $LATENCY_THRESHOLD ms"
    echo
    
    echo "What would you like to configure?"
    echo "1) Memory usage threshold"
    echo "2) Connection count threshold"
    echo "3) Latency threshold"
    echo "4) Reset to defaults"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r threshold_choice
    
    case $threshold_choice in
        1)
            echo -n "Enter memory threshold percentage (current: $MEMORY_THRESHOLD): "
            read -r new_memory_threshold
            if [[ "$new_memory_threshold" =~ ^[0-9]+$ ]] && [[ $new_memory_threshold -ge 1 ]] && [[ $new_memory_threshold -le 100 ]]; then
                update_config_value "MEMORY_THRESHOLD" "$new_memory_threshold"
                MEMORY_THRESHOLD="$new_memory_threshold"
                echo -e "${GREEN}✓ Memory threshold updated to: $new_memory_threshold%${NC}"
            else
                echo -e "${RED}✗ Invalid threshold (must be 1-100)${NC}"
            fi
            ;;
        2)
            echo -n "Enter connection threshold (current: $CONNECTION_THRESHOLD): "
            read -r new_connection_threshold
            if [[ "$new_connection_threshold" =~ ^[0-9]+$ ]] && [[ $new_connection_threshold -gt 0 ]]; then
                update_config_value "CONNECTION_THRESHOLD" "$new_connection_threshold"
                CONNECTION_THRESHOLD="$new_connection_threshold"
                echo -e "${GREEN}✓ Connection threshold updated to: $new_connection_threshold${NC}"
            else
                echo -e "${RED}✗ Invalid threshold (must be > 0)${NC}"
            fi
            ;;
        3)
            echo -n "Enter latency threshold in ms (current: $LATENCY_THRESHOLD): "
            read -r new_latency_threshold
            if [[ "$new_latency_threshold" =~ ^[0-9]+$ ]] && [[ $new_latency_threshold -gt 0 ]]; then
                update_config_value "LATENCY_THRESHOLD" "$new_latency_threshold"
                LATENCY_THRESHOLD="$new_latency_threshold"
                echo -e "${GREEN}✓ Latency threshold updated to: $new_latency_threshold ms${NC}"
            else
                echo -e "${RED}✗ Invalid threshold (must be > 0)${NC}"
            fi
            ;;
        4)
            update_config_value "MEMORY_THRESHOLD" "80"
            update_config_value "CONNECTION_THRESHOLD" "100"
            update_config_value "LATENCY_THRESHOLD" "100"
            MEMORY_THRESHOLD="80"
            CONNECTION_THRESHOLD="100"
            LATENCY_THRESHOLD="100"
            echo -e "${GREEN}✓ Thresholds reset to defaults${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Configure backup settings
configure_backup_settings() {
    echo -e "${YELLOW}Backup Configuration${NC}"
    echo "================================"
    
    echo "Current backup settings:"
    echo "Retention days: $BACKUP_RETENTION_DAYS"
    echo "Compression: $BACKUP_COMPRESSION"
    echo "Auto backup: $AUTO_BACKUP"
    echo "Schedule: $BACKUP_SCHEDULE"
    echo
    
    echo "What would you like to configure?"
    echo "1) Backup retention period"
    echo "2) Toggle compression"
    echo "3) Configure automatic backup"
    echo "4) Set backup schedule"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r backup_choice
    
    case $backup_choice in
        1)
            echo -n "Enter retention period in days (current: $BACKUP_RETENTION_DAYS): "
            read -r new_retention
            if [[ "$new_retention" =~ ^[0-9]+$ ]] && [[ $new_retention -gt 0 ]]; then
                update_config_value "BACKUP_RETENTION_DAYS" "$new_retention"
                BACKUP_RETENTION_DAYS="$new_retention"
                echo -e "${GREEN}✓ Retention period updated to: $new_retention days${NC}"
            else
                echo -e "${RED}✗ Invalid retention period${NC}"
            fi
            ;;
        2)
            if [[ "$BACKUP_COMPRESSION" == "true" ]]; then
                update_config_value "BACKUP_COMPRESSION" "false"
                BACKUP_COMPRESSION="false"
                echo -e "${GREEN}✓ Backup compression disabled${NC}"
            else
                update_config_value "BACKUP_COMPRESSION" "true"
                BACKUP_COMPRESSION="true"
                echo -e "${GREEN}✓ Backup compression enabled${NC}"
            fi
            ;;
        3)
            if [[ "$AUTO_BACKUP" == "true" ]]; then
                update_config_value "AUTO_BACKUP" "false"
                AUTO_BACKUP="false"
                echo -e "${GREEN}✓ Automatic backup disabled${NC}"
            else
                update_config_value "AUTO_BACKUP" "true"
                AUTO_BACKUP="true"
                echo -e "${GREEN}✓ Automatic backup enabled${NC}"
            fi
            ;;
        4)
            echo "Current schedule: $BACKUP_SCHEDULE"
            echo "Examples:"
            echo "  0 2 * * *     - Daily at 2 AM"
            echo "  0 */6 * * *   - Every 6 hours"
            echo "  0 3 * * 0     - Weekly on Sunday at 3 AM"
            echo
            echo -n "Enter new cron schedule: "
            read -r new_schedule
            if [[ -n "$new_schedule" ]]; then
                update_config_value "BACKUP_SCHEDULE" "$new_schedule"
                BACKUP_SCHEDULE="$new_schedule"
                echo -e "${GREEN}✓ Backup schedule updated${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Manage Redis server configuration
manage_redis_server_config() {
    echo -e "${YELLOW}Redis Server Configuration${NC}"
    echo "================================"
    
    if ! test_redis_connection; then
        echo -e "${RED}✗ Cannot connect to Redis server${NC}"
        return 1
    fi
    
    echo "Redis server configuration options:"
    echo "1) View current configuration"
    echo "2) Modify configuration parameter"
    echo "3) Save configuration to file"
    echo "4) Configuration recommendations"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r server_choice
    
    case $server_choice in
        1)
            echo "Current Redis configuration:"
            redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get "*" | head -20
            echo "... (showing first 20 parameters)"
            ;;
        2)
            echo -n "Enter parameter name: "
            read -r param_name
            if [[ -n "$param_name" ]]; then
                local current_value=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get "$param_name" | tail -1)
                echo "Current value: $current_value"
                echo -n "Enter new value: "
                read -r new_value
                if [[ -n "$new_value" ]]; then
                    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config set "$param_name" "$new_value" >/dev/null 2>&1; then
                        echo -e "${GREEN}✓ Parameter $param_name updated to: $new_value${NC}"
                    else
                        echo -e "${RED}✗ Failed to update parameter${NC}"
                    fi
                fi
            fi
            ;;
        3)
            local config_file="$METRICS_DIR/redis_config_$(date +%Y%m%d_%H%M%S).conf"
            echo "Saving configuration to: $config_file"
            redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get "*" > "$config_file"
            echo -e "${GREEN}✓ Configuration saved${NC}"
            ;;
        4)
            show_config_recommendations
            ;;
        0)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Show configuration recommendations
show_config_recommendations() {
    echo -e "${CYAN}Redis Configuration Recommendations:${NC}"
    echo "-----------------------------------"
    
    # Check maxmemory
    local maxmemory=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get maxmemory | tail -1)
    if [[ "$maxmemory" == "0" ]]; then
        echo -e "${YELLOW}• Set maxmemory to prevent OOM issues${NC}"
    fi
    
    # Check save configuration
    local save_config=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get save | tail -1)
    if [[ -z "$save_config" ]]; then
        echo -e "${YELLOW}• Configure RDB persistence with 'save' parameter${NC}"
    fi
    
    # Check timeout
    local timeout=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get timeout | tail -1)
    if [[ "$timeout" == "0" ]]; then
        echo -e "${YELLOW}• Set client timeout to prevent idle connections${NC}"
    fi
    
    echo -e "${GREEN}• Regular configuration review recommended${NC}"
}

# View current configuration
view_current_configuration() {
    echo -e "${YELLOW}Current Redis Helper Configuration${NC}"
    echo "================================"
    
    echo -e "${CYAN}Connection Settings:${NC}"
    echo "Host: $REDIS_HOST"
    echo "Port: $REDIS_PORT"
    echo "Password: $(if [[ -n "$REDIS_PASSWORD" ]]; then echo "***SET***"; else echo "Not set"; fi)"
    echo "Database: $REDIS_DB"
    echo "Environment: $ENVIRONMENT"
    
    echo
    echo -e "${CYAN}Monitoring Thresholds:${NC}"
    echo "Memory: $MEMORY_THRESHOLD%"
    echo "Connections: $CONNECTION_THRESHOLD"
    echo "Latency: $LATENCY_THRESHOLD ms"
    
    echo
    echo -e "${CYAN}Backup Settings:${NC}"
    echo "Retention: $BACKUP_RETENTION_DAYS days"
    echo "Compression: $BACKUP_COMPRESSION"
    echo "Auto backup: $AUTO_BACKUP"
    echo "Schedule: $BACKUP_SCHEDULE"
    
    echo
    echo -e "${CYAN}System Settings:${NC}"
    echo "Log level: $LOG_LEVEL"
    echo "Config file: $CONFIG_FILE"
    echo "Log file: $LOG_FILE"
    echo "Backup directory: $BACKUP_DIR"
}

# Validate configuration
validate_configuration() {
    echo -e "${YELLOW}Configuration Validation${NC}"
    echo "================================"
    
    local issues=0
    
    echo "Validating Redis Helper configuration..."
    echo
    
    # Test Redis connection
    echo -n "Testing Redis connection... "
    if test_redis_connection; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        issues=$((issues + 1))
    fi
    
    # Check configuration file
    echo -n "Checking configuration file... "
    if [[ -f "$CONFIG_FILE" ]] && [[ -r "$CONFIG_FILE" ]]; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        issues=$((issues + 1))
    fi
    
    # Check directories
    echo -n "Checking directories... "
    local dirs_ok=true
    for dir in "$BACKUP_DIR" "$METRICS_DIR" "$(dirname "$LOG_FILE")"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null || dirs_ok=false
        fi
    done
    
    if [[ "$dirs_ok" == "true" ]]; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        issues=$((issues + 1))
    fi
    
    # Check thresholds
    echo -n "Validating thresholds... "
    local thresholds_ok=true
    
    if [[ ! "$MEMORY_THRESHOLD" =~ ^[0-9]+$ ]] || [[ $MEMORY_THRESHOLD -lt 1 ]] || [[ $MEMORY_THRESHOLD -gt 100 ]]; then
        thresholds_ok=false
    fi
    
    if [[ ! "$CONNECTION_THRESHOLD" =~ ^[0-9]+$ ]] || [[ $CONNECTION_THRESHOLD -lt 1 ]]; then
        thresholds_ok=false
    fi
    
    if [[ ! "$LATENCY_THRESHOLD" =~ ^[0-9]+$ ]] || [[ $LATENCY_THRESHOLD -lt 1 ]]; then
        thresholds_ok=false
    fi
    
    if [[ "$thresholds_ok" == "true" ]]; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        issues=$((issues + 1))
    fi
    
    echo
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✓ Configuration validation passed${NC}"
    else
        echo -e "${RED}✗ Configuration validation failed ($issues issues)${NC}"
    fi
}

# Reset to defaults
reset_to_defaults() {
    echo -e "${YELLOW}Reset Configuration to Defaults${NC}"
    echo "================================"
    
    echo -e "${RED}WARNING: This will reset all configuration to default values!${NC}"
    echo -n "Are you sure? Type 'RESET' to confirm: "
    read -r confirmation
    
    if [[ "$confirmation" == "RESET" ]]; then
        echo "Resetting configuration..."
        
        # Backup current config
        local backup_config="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$backup_config" 2>/dev/null
        
        # Create new default config
        create_default_config
        
        # Reload configuration
        load_config
        
        echo -e "${GREEN}✓ Configuration reset to defaults${NC}"
        echo "Previous configuration backed up to: $backup_config"
        log "INFO" "Configuration reset to defaults"
    else
        echo "Reset cancelled"
    fi
}

# Export/import settings
export_import_settings() {
    echo -e "${YELLOW}Export/Import Settings${NC}"
    echo "================================"
    
    echo "1) Export current settings"
    echo "2) Import settings from file"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r export_choice
    
    case $export_choice in
        1)
            local export_file="$METRICS_DIR/redis_helper_config_$(date +%Y%m%d_%H%M%S).conf"
            cp "$CONFIG_FILE" "$export_file"
            echo -e "${GREEN}✓ Settings exported to: $export_file${NC}"
            ;;
        2)
            echo -n "Enter path to configuration file: "
            read -r import_file
            if [[ -f "$import_file" ]] && [[ -r "$import_file" ]]; then
                cp "$import_file" "$CONFIG_FILE"
                load_config
                echo -e "${GREEN}✓ Settings imported successfully${NC}"
            else
                echo -e "${RED}✗ File not found or not readable${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Helper function to update configuration values
update_config_value() {
    local key="$1"
    local value="$2"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        # Use sed to update the value in the config file
        if grep -q "^$key=" "$CONFIG_FILE"; then
            sed -i "s/^$key=.*/$key=\"$value\"/" "$CONFIG_FILE"
        else
            echo "$key=\"$value\"" >> "$CONFIG_FILE"
        fi
    fi
}
