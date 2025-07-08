#!/bin/bash

# Redis Helper - Utilities & Tools Module v1.1
# Licensed under GPLv3

# Utilities and tools menu
utilities_tools_menu() {
    while true; do
        show_header
        echo -e "${CYAN}┌─ Utilities & Tools ─────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Key Pattern Analysis                                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) TTL Management                                          ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Bulk Operations                                         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Data Migration Tools                                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Redis CLI Enhanced                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Memory Analyzer                                         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 7) Configuration Validator                                 ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 8) Health Check Suite                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 9) Maintenance Tools                                       ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) analyze_key_patterns ;;
            2) ttl_management ;;
            3) bulk_operations ;;
            4) data_migration_tools ;;
            5) enhanced_redis_cli ;;
            6) memory_analyzer ;;
            7) configuration_validator ;;
            8) health_check_suite ;;
            9) maintenance_tools ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Analyze key patterns
analyze_key_patterns() {
    echo -e "${YELLOW}Key Pattern Analysis${NC}"
    echo "================================"
    
    echo "Analyzing Redis key patterns and distribution..."
    echo
    
    # Get sample of keys
    echo -e "${CYAN}Sampling Keys:${NC}"
    echo "--------------"
    
    local sample_keys=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --scan --pattern "*" 2>/dev/null | head -1000)
    
    if [[ -z "$sample_keys" ]]; then
        echo "No keys found or unable to scan keys"
        return
    fi
    
    local total_keys=$(echo "$sample_keys" | wc -l)
    echo "Analyzed $total_keys keys (sample)"
    
    # Analyze key patterns
    echo
    echo -e "${CYAN}Key Pattern Analysis:${NC}"
    echo "--------------------"
    
    # Common patterns
    local patterns=(
        "user:"
        "session:"
        "cache:"
        "queue:"
        "lock:"
        "config:"
        "temp:"
        "data:"
    )
    
    for pattern in "${patterns[@]}"; do
        local count=$(echo "$sample_keys" | grep -c "^$pattern" || echo "0")
        if [[ $count -gt 0 ]]; then
            local percentage=$(( (count * 100) / total_keys ))
            echo "$pattern $count keys ($percentage%)"
        fi
    done
    
    # Key length analysis
    echo
    echo -e "${CYAN}Key Length Distribution:${NC}"
    echo "----------------------"
    
    local short_keys=0
    local medium_keys=0
    local long_keys=0
    local very_long_keys=0
    
    echo "$sample_keys" | while read -r key; do
        local key_length=${#key}
        
        if [[ $key_length -lt 20 ]]; then
            short_keys=$((short_keys + 1))
        elif [[ $key_length -lt 50 ]]; then
            medium_keys=$((medium_keys + 1))
        elif [[ $key_length -lt 100 ]]; then
            long_keys=$((long_keys + 1))
        else
            very_long_keys=$((very_long_keys + 1))
        fi
    done
    
    echo "Short keys (<20 chars): $short_keys"
    echo "Medium keys (20-49 chars): $medium_keys"
    echo "Long keys (50-99 chars): $long_keys"
    echo "Very long keys (100+ chars): $very_long_keys"
    
    # Key type analysis
    echo
    echo -e "${CYAN}Key Type Distribution:${NC}"
    echo "---------------------"
    
    local string_count=0
    local list_count=0
    local set_count=0
    local hash_count=0
    local zset_count=0
    
    echo "$sample_keys" | head -100 | while read -r key; do
        local key_type=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} type "$key" 2>/dev/null)
        
        case "$key_type" in
            "string") string_count=$((string_count + 1)) ;;
            "list") list_count=$((list_count + 1)) ;;
            "set") set_count=$((set_count + 1)) ;;
            "hash") hash_count=$((hash_count + 1)) ;;
            "zset") zset_count=$((zset_count + 1)) ;;
        esac
    done
    
    echo "Strings: $string_count"
    echo "Lists: $list_count"
    echo "Sets: $set_count"
    echo "Hashes: $hash_count"
    echo "Sorted Sets: $zset_count"
    
    # Recommendations
    echo
    echo -e "${CYAN}Recommendations:${NC}"
    echo "----------------"
    echo "• Use consistent naming conventions"
    echo "• Keep key names short but descriptive"
    echo "• Use namespaces (prefixes) to organize keys"
    echo "• Avoid very long key names (>100 chars)"
    echo "• Consider using hashes for related data"
}

# TTL management
ttl_management() {
    echo -e "${YELLOW}TTL Management${NC}"
    echo "================================"
    
    echo "TTL (Time To Live) management tools:"
    echo
    echo "1) Analyze TTL distribution"
    echo "2) Find keys without TTL"
    echo "3) Set TTL on keys"
    echo "4) Clean expired keys"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r choice
    
    case $choice in
        1) analyze_ttl_distribution ;;
        2) find_keys_without_ttl ;;
        3) set_ttl_on_keys ;;
        4) clean_expired_keys ;;
        0) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Analyze TTL distribution
analyze_ttl_distribution() {
    echo -e "${YELLOW}TTL Distribution Analysis${NC}"
    echo "================================"
    
    echo "Analyzing TTL distribution across keys..."
    echo
    
    local sample_keys=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --scan --pattern "*" 2>/dev/null | head -500)
    
    if [[ -z "$sample_keys" ]]; then
        echo "No keys found"
        return
    fi
    
    local no_ttl=0
    local short_ttl=0    # < 1 hour
    local medium_ttl=0   # 1 hour - 1 day
    local long_ttl=0     # > 1 day
    local expired=0
    
    echo -e "${CYAN}TTL Categories:${NC}"
    echo "---------------"
    
    echo "$sample_keys" | while read -r key; do
        local ttl=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ttl "$key" 2>/dev/null)
        
        case "$ttl" in
            "-1") no_ttl=$((no_ttl + 1)) ;;
            "-2") expired=$((expired + 1)) ;;
            *)
                if [[ $ttl -lt 3600 ]]; then
                    short_ttl=$((short_ttl + 1))
                elif [[ $ttl -lt 86400 ]]; then
                    medium_ttl=$((medium_ttl + 1))
                else
                    long_ttl=$((long_ttl + 1))
                fi
                ;;
        esac
    done
    
    echo "No TTL set: $no_ttl keys"
    echo "Short TTL (<1h): $short_ttl keys"
    echo "Medium TTL (1h-1d): $medium_ttl keys"
    echo "Long TTL (>1d): $long_ttl keys"
    echo "Expired: $expired keys"
    
    # Show keys without TTL
    if [[ $no_ttl -gt 0 ]]; then
        echo
        echo -e "${YELLOW}Sample keys without TTL:${NC}"
        echo "$sample_keys" | head -10 | while read -r key; do
            local ttl=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ttl "$key" 2>/dev/null)
            if [[ "$ttl" == "-1" ]]; then
                echo "  $key"
            fi
        done
    fi
}

# Find keys without TTL
find_keys_without_ttl() {
    echo -e "${YELLOW}Keys Without TTL${NC}"
    echo "================================"
    
    echo "Searching for keys without TTL..."
    echo
    
    local keys_without_ttl=()
    local sample_keys=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --scan --pattern "*" 2>/dev/null | head -100)
    
    echo "$sample_keys" | while read -r key; do
        local ttl=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ttl "$key" 2>/dev/null)
        
        if [[ "$ttl" == "-1" ]]; then
            keys_without_ttl+=("$key")
            echo "$key"
        fi
    done
    
    echo
    echo "Found ${#keys_without_ttl[@]} keys without TTL (from sample)"
    
    if [[ ${#keys_without_ttl[@]} -gt 0 ]]; then
        echo
        echo "Consider setting appropriate TTL values to:"
        echo "• Prevent memory bloat"
        echo "• Implement data lifecycle management"
        echo "• Improve cache efficiency"
    fi
}

# Bulk operations
bulk_operations() {
    echo -e "${YELLOW}Bulk Operations${NC}"
    echo "================================"
    
    echo "Bulk operation tools:"
    echo
    echo "1) Bulk delete by pattern"
    echo "2) Bulk set TTL"
    echo "3) Bulk rename keys"
    echo "4) Bulk export keys"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r choice
    
    case $choice in
        1) bulk_delete_by_pattern ;;
        2) bulk_set_ttl ;;
        3) bulk_rename_keys ;;
        4) bulk_export_keys ;;
        0) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Bulk delete by pattern
bulk_delete_by_pattern() {
    echo -e "${YELLOW}Bulk Delete by Pattern${NC}"
    echo "================================"
    
    echo -n "Enter key pattern to delete (e.g., temp:*): "
    read -r pattern
    
    if [[ -z "$pattern" ]]; then
        echo "No pattern provided"
        return
    fi
    
    echo "Searching for keys matching pattern: $pattern"
    
    local matching_keys=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --scan --pattern "$pattern" 2>/dev/null)
    local key_count=$(echo "$matching_keys" | wc -l)
    
    if [[ -z "$matching_keys" ]]; then
        echo "No keys found matching pattern"
        return
    fi
    
    echo "Found $key_count keys matching pattern"
    echo
    echo "Sample keys:"
    echo "$matching_keys" | head -5
    
    if [[ $key_count -gt 5 ]]; then
        echo "... and $((key_count - 5)) more"
    fi
    
    echo
    echo -e "${RED}WARNING: This will permanently delete all matching keys!${NC}"
    echo -n "Are you sure? Type 'DELETE' to confirm: "
    read -r confirmation
    
    if [[ "$confirmation" == "DELETE" ]]; then
        echo "Deleting keys..."
        
        local deleted_count=0
        echo "$matching_keys" | while read -r key; do
            if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} del "$key" >/dev/null 2>&1; then
                deleted_count=$((deleted_count + 1))
            fi
        done
        
        echo -e "${GREEN}✓ Deleted $deleted_count keys${NC}"
        log "INFO" "Bulk delete completed: $deleted_count keys deleted with pattern $pattern"
    else
        echo "Operation cancelled"
    fi
}

# Enhanced Redis CLI
enhanced_redis_cli() {
    echo -e "${YELLOW}Enhanced Redis CLI${NC}"
    echo "================================"
    
    echo "Enhanced Redis CLI with additional features:"
    echo
    echo "1) Interactive CLI with history"
    echo "2) Command templates"
    echo "3) Batch command execution"
    echo "4) Query builder"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r choice
    
    case $choice in
        1) interactive_cli_with_history ;;
        2) show_command_templates ;;
        3) batch_command_execution ;;
        4) query_builder ;;
        0) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Interactive CLI with history
interactive_cli_with_history() {
    echo -e "${YELLOW}Enhanced Interactive Redis CLI${NC}"
    echo "================================"
    
    echo "Starting enhanced Redis CLI session..."
    echo "Additional commands:"
    echo "  .help     - Show help"
    echo "  .info     - Show server info"
    echo "  .memory   - Show memory usage"
    echo "  .clients  - Show connected clients"
    echo "  .exit     - Exit CLI"
    echo
    
    local history_file="$SCRIPT_DIR/logs/redis_cli_history.txt"
    
    while true; do
        echo -n "redis> "
        read -r command
        
        # Save to history
        echo "$(date '+%Y-%m-%d %H:%M:%S') $command" >> "$history_file"
        
        case "$command" in
            ".help")
                echo "Enhanced Redis CLI Help:"
                echo "  .help     - Show this help"
                echo "  .info     - Show Redis server information"
                echo "  .memory   - Show memory usage"
                echo "  .clients  - Show connected clients"
                echo "  .history  - Show command history"
                echo "  .exit     - Exit CLI"
                echo "  Any Redis command - Execute directly"
                ;;
            ".info")
                redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} info server
                ;;
            ".memory")
                redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} info memory
                ;;
            ".clients")
                redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} client list
                ;;
            ".history")
                echo "Recent commands:"
                tail -10 "$history_file" 2>/dev/null || echo "No history available"
                ;;
            ".exit"|"quit"|"exit")
                echo "Goodbye!"
                break
                ;;
            "")
                # Empty command, continue
                ;;
            *)
                # Execute Redis command
                redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} $command
                ;;
        esac
    done
}

# Show command templates
show_command_templates() {
    echo -e "${YELLOW}Redis Command Templates${NC}"
    echo "================================"
    
    echo "Common Redis command templates:"
    echo
    
    echo -e "${CYAN}String Operations:${NC}"
    echo "SET key value                    - Set string value"
    echo "GET key                          - Get string value"
    echo "MSET key1 val1 key2 val2        - Set multiple strings"
    echo "INCR key                         - Increment number"
    echo "EXPIRE key seconds               - Set expiration"
    
    echo
    echo -e "${CYAN}List Operations:${NC}"
    echo "LPUSH key value                  - Push to list head"
    echo "RPUSH key value                  - Push to list tail"
    echo "LRANGE key 0 -1                 - Get all list items"
    echo "LLEN key                         - Get list length"
    
    echo
    echo -e "${CYAN}Hash Operations:${NC}"
    echo "HSET key field value             - Set hash field"
    echo "HGET key field                   - Get hash field"
    echo "HGETALL key                      - Get all hash fields"
    echo "HDEL key field                   - Delete hash field"
    
    echo
    echo -e "${CYAN}Set Operations:${NC}"
    echo "SADD key member                  - Add to set"
    echo "SMEMBERS key                     - Get all set members"
    echo "SCARD key                        - Get set size"
    echo "SINTER key1 key2                 - Set intersection"
    
    echo
    echo -e "${CYAN}Sorted Set Operations:${NC}"
    echo "ZADD key score member            - Add to sorted set"
    echo "ZRANGE key 0 -1                 - Get range by rank"
    echo "ZRANGEBYSCORE key min max        - Get range by score"
    echo "ZCARD key                        - Get sorted set size"
    
    echo
    echo -e "${CYAN}Administrative:${NC}"
    echo "INFO                             - Server information"
    echo "DBSIZE                           - Number of keys"
    echo "FLUSHDB                          - Clear current database"
    echo "CONFIG GET parameter             - Get configuration"
    echo "CLIENT LIST                      - List connected clients"
}

# Health check suite
health_check_suite() {
    echo -e "${YELLOW}Redis Health Check Suite${NC}"
    echo "================================"
    
    echo "Running comprehensive health checks..."
    echo
    
    local health_score=100
    local issues=()
    local warnings=()
    
    # Check 1: Connectivity
    echo -e "${CYAN}1. Connectivity Check${NC}"
    if test_redis_connection; then
        echo -e "   ${GREEN}✓ Redis is reachable${NC}"
    else
        echo -e "   ${RED}✗ Cannot connect to Redis${NC}"
        issues+=("Connection failed")
        health_score=$((health_score - 30))
    fi
    
    # Check 2: Memory usage
    echo -e "${CYAN}2. Memory Usage Check${NC}"
    local memory_info=$(get_redis_info memory)
    local used_memory=$(echo "$memory_info" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$memory_info" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    
    if [[ "$maxmemory" != "0" ]]; then
        local usage_percent=$(( (used_memory * 100) / maxmemory ))
        if [[ $usage_percent -gt 90 ]]; then
            echo -e "   ${RED}✗ High memory usage: $usage_percent%${NC}"
            issues+=("High memory usage")
            health_score=$((health_score - 20))
        elif [[ $usage_percent -gt 80 ]]; then
            echo -e "   ${YELLOW}⚠ Moderate memory usage: $usage_percent%${NC}"
            warnings+=("Moderate memory usage")
            health_score=$((health_score - 10))
        else
            echo -e "   ${GREEN}✓ Memory usage OK: $usage_percent%${NC}"
        fi
    else
        echo -e "   ${YELLOW}⚠ No memory limit set${NC}"
        warnings+=("No memory limit")
        health_score=$((health_score - 5))
    fi
    
    # Check 3: Persistence
    echo -e "${CYAN}3. Persistence Check${NC}"
    local persistence_info=$(get_redis_info persistence)
    local rdb_last_save=$(echo "$persistence_info" | grep "rdb_last_save_time:" | cut -d: -f2 | tr -d '\r')
    local aof_enabled=$(echo "$persistence_info" | grep "aof_enabled:" | cut -d: -f2 | tr -d '\r')
    
    if [[ "$aof_enabled" == "1" ]]; then
        echo -e "   ${GREEN}✓ AOF persistence enabled${NC}"
    elif [[ -n "$rdb_last_save" ]] && [[ "$rdb_last_save" != "0" ]]; then
        local current_time=$(date +%s)
        local time_since_save=$((current_time - rdb_last_save))
        if [[ $time_since_save -gt 86400 ]]; then
            echo -e "   ${YELLOW}⚠ RDB: Last save was $((time_since_save / 3600)) hours ago${NC}"
            warnings+=("Old RDB backup")
            health_score=$((health_score - 5))
        else
            echo -e "   ${GREEN}✓ RDB persistence active${NC}"
        fi
    else
        echo -e "   ${RED}✗ No persistence configured${NC}"
        issues+=("No persistence")
        health_score=$((health_score - 15))
    fi
    
    # Check 4: Slow queries
    echo -e "${CYAN}4. Performance Check${NC}"
    local slowlog_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog len 2>/dev/null)
    
    if [[ $slowlog_len -gt 10 ]]; then
        echo -e "   ${YELLOW}⚠ $slowlog_len slow queries detected${NC}"
        warnings+=("Slow queries present")
        health_score=$((health_score - 5))
    else
        echo -e "   ${GREEN}✓ Performance looks good${NC}"
    fi
    
    # Check 5: Client connections
    echo -e "${CYAN}5. Connection Check${NC}"
    local clients_info=$(get_redis_info clients)
    local connected_clients=$(echo "$clients_info" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    
    if [[ $connected_clients -gt 100 ]]; then
        echo -e "   ${YELLOW}⚠ High connection count: $connected_clients${NC}"
        warnings+=("High connection count")
        health_score=$((health_score - 5))
    else
        echo -e "   ${GREEN}✓ Connection count OK: $connected_clients${NC}"
    fi
    
    # Health summary
    echo
    echo -e "${CYAN}Health Check Summary:${NC}"
    echo "====================="
    
    if [[ $health_score -ge 90 ]]; then
        echo -e "Overall Health: ${GREEN}$health_score/100 (Excellent)${NC}"
    elif [[ $health_score -ge 70 ]]; then
        echo -e "Overall Health: ${YELLOW}$health_score/100 (Good)${NC}"
    elif [[ $health_score -ge 50 ]]; then
        echo -e "Overall Health: ${YELLOW}$health_score/100 (Fair)${NC}"
    else
        echo -e "Overall Health: ${RED}$health_score/100 (Poor)${NC}"
    fi
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo
        echo -e "${RED}Critical Issues:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  ${RED}• $issue${NC}"
        done
    fi
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo
        echo -e "${YELLOW}Warnings:${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}• $warning${NC}"
        done
    fi
    
    log "INFO" "Health check completed - Score: $health_score/100"
}
