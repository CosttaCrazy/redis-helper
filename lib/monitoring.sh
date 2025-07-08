#!/bin/bash

# Redis Helper - Real-time Monitoring Module
# Licensed under GPLv3

# Real-time monitoring dashboard
realtime_dashboard() {
    local refresh_rate="${1:-2}"
    
    while true; do
        clear
        show_header
        echo -e "${CYAN}┌─ Real-time Dashboard (Refresh: ${refresh_rate}s) ──────────────────┐${NC}"
        
        # Connection status
        if test_redis_connection; then
            echo -e "${CYAN}│${NC} ${GREEN}● Connected${NC}                                              ${CYAN}│${NC}"
        else
            echo -e "${CYAN}│${NC} ${RED}● Disconnected${NC}                                           ${CYAN}│${NC}"
            echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
            read -t 5 -p "Connection lost. Press Enter to retry or wait 5s..."
            continue
        fi
        
        # Get current metrics
        local info_stats=$(get_redis_info stats)
        local info_memory=$(get_redis_info memory)
        local info_clients=$(get_redis_info clients)
        local info_server=$(get_redis_info server)
        
        # Parse metrics
        local ops_per_sec=$(echo "$info_stats" | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | tr -d '\r')
        local used_memory_human=$(echo "$info_memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
        local connected_clients=$(echo "$info_clients" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
        local uptime=$(echo "$info_server" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r')
        local total_commands=$(echo "$info_stats" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
        
        # Display metrics
        echo -e "${CYAN}│${NC} Operations/sec:   ${WHITE}$ops_per_sec${NC}                                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} Memory Used:      ${WHITE}$used_memory_human${NC}                                ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} Connections:      ${WHITE}$connected_clients${NC}                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} Total Commands:   ${WHITE}$total_commands${NC}                              ${CYAN}│${NC}"
        
        # Memory usage bar
        local used_memory=$(echo "$info_memory" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
        local maxmemory=$(echo "$info_memory" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
        
        if [[ "$maxmemory" != "0" ]]; then
            local usage_percent=$(( (used_memory * 100) / maxmemory ))
            local bar=$(create_progress_bar $usage_percent 40)
            
            if [[ $usage_percent -gt $MEMORY_THRESHOLD ]]; then
                echo -e "${CYAN}│${NC} Memory Usage:     ${RED}$bar ${usage_percent}%${NC}                ${CYAN}│${NC}"
            else
                echo -e "${CYAN}│${NC} Memory Usage:     ${GREEN}$bar ${usage_percent}%${NC}                ${CYAN}│${NC}"
            fi
        fi
        
        echo -e "${CYAN}├─ Recent Activity ──────────────────────────────────────────┤${NC}"
        
        # Show recent slow queries
        local slowlog=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog get 3 2>/dev/null)
        if [[ -n "$slowlog" ]]; then
            echo -e "${CYAN}│${NC} Recent Slow Queries:                                    ${CYAN}│${NC}"
            echo "$slowlog" | head -6 | while read -r line; do
                [[ ${#line} -gt 55 ]] && line="${line:0:52}..."
                echo -e "${CYAN}│${NC} ${YELLOW}$line${NC}                                                ${CYAN}│${NC}"
            done
        fi
        
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        echo -e "${YELLOW}Press 'q' to quit, 'r' to change refresh rate, or wait...${NC}"
        
        # Check for user input
        if read -t $refresh_rate -n 1 key; then
            case "$key" in
                'q'|'Q') return ;;
                'r'|'R') 
                    echo -n "Enter new refresh rate (seconds): "
                    read -r new_rate
                    [[ "$new_rate" =~ ^[0-9]+$ ]] && refresh_rate="$new_rate"
                    ;;
            esac
        fi
    done
}

# Create progress bar
create_progress_bar() {
    local percentage=$1
    local width=${2:-20}
    local filled_length=$(( (percentage * width) / 100 ))
    local bar=""
    
    for ((i=0; i<filled_length; i++)); do bar+="█"; done
    for ((i=filled_length; i<width; i++)); do bar+="░"; done
    
    echo "$bar"
}

# Monitor specific metrics
monitor_metrics() {
    echo -e "${YELLOW}Available Metrics to Monitor:${NC}"
    echo "1) Memory Usage"
    echo "2) Operations per Second"
    echo "3) Client Connections"
    echo "4) Slow Queries"
    echo "5) Key Expiration"
    echo "6) Network I/O"
    echo "0) Back"
    
    echo -n "Select metric: "
    read -r choice
    
    case $choice in
        1) monitor_memory ;;
        2) monitor_ops ;;
        3) monitor_connections ;;
        4) monitor_slow_queries ;;
        5) monitor_key_expiration ;;
        6) monitor_network_io ;;
        0) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Monitor memory usage over time
monitor_memory() {
    local samples=60
    local interval=1
    local memory_data=()
    
    echo -e "${YELLOW}Monitoring memory usage (${samples} samples, ${interval}s interval)...${NC}"
    echo "Press Ctrl+C to stop"
    echo
    
    for ((i=1; i<=samples; i++)); do
        local info=$(get_redis_info memory)
        local used_memory=$(echo "$info" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
        local used_memory_human=$(echo "$info" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
        
        memory_data+=("$used_memory")
        
        # Simple ASCII graph
        local timestamp=$(date '+%H:%M:%S')
        printf "[%s] Memory: %s (" "$timestamp" "$used_memory_human"
        
        # Show trend
        if [[ ${#memory_data[@]} -gt 1 ]]; then
            local prev_memory=${memory_data[-2]}
            if [[ $used_memory -gt $prev_memory ]]; then
                printf "${RED}↑${NC}"
            elif [[ $used_memory -lt $prev_memory ]]; then
                printf "${GREEN}↓${NC}"
            else
                printf "${YELLOW}→${NC}"
            fi
        fi
        printf ")\n"
        
        sleep $interval
    done
    
    # Calculate statistics
    local min_memory=${memory_data[0]}
    local max_memory=${memory_data[0]}
    local total_memory=0
    
    for memory in "${memory_data[@]}"; do
        [[ $memory -lt $min_memory ]] && min_memory=$memory
        [[ $memory -gt $max_memory ]] && max_memory=$memory
        total_memory=$((total_memory + memory))
    done
    
    local avg_memory=$((total_memory / ${#memory_data[@]}))
    
    echo
    echo -e "${CYAN}Memory Statistics:${NC}"
    echo "Minimum: $(numfmt --to=iec $min_memory)B"
    echo "Maximum: $(numfmt --to=iec $max_memory)B"
    echo "Average: $(numfmt --to=iec $avg_memory)B"
}

# Monitor operations per second
monitor_ops() {
    echo -e "${YELLOW}Monitoring operations per second...${NC}"
    echo "Press Ctrl+C to stop"
    echo
    
    local prev_commands=0
    local first_run=true
    
    while true; do
        local info=$(get_redis_info stats)
        local total_commands=$(echo "$info" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
        local ops_per_sec=$(echo "$info" | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | tr -d '\r')
        
        if [[ "$first_run" == "false" ]]; then
            local commands_diff=$((total_commands - prev_commands))
            local timestamp=$(date '+%H:%M:%S')
            
            printf "[%s] OPS: %s (Total: %s, +%s)\n" "$timestamp" "$ops_per_sec" "$total_commands" "$commands_diff"
            
            # Alert on high operations
            if [[ $ops_per_sec -gt 1000 ]]; then
                echo -e "${RED}⚠ High operations per second detected!${NC}"
            fi
        fi
        
        prev_commands=$total_commands
        first_run=false
        sleep 1
    done
}

# Monitor slow queries
monitor_slow_queries() {
    echo -e "${YELLOW}Monitoring slow queries...${NC}"
    echo "Press Ctrl+C to stop"
    echo
    
    local prev_slowlog_len=0
    
    while true; do
        local slowlog_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog len 2>/dev/null)
        
        if [[ $slowlog_len -gt $prev_slowlog_len ]]; then
            local new_entries=$((slowlog_len - prev_slowlog_len))
            echo -e "${RED}[$(date '+%H:%M:%S')] New slow queries detected: $new_entries${NC}"
            
            # Show the new slow queries
            redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog get $new_entries 2>/dev/null | head -20
            echo "---"
        fi
        
        prev_slowlog_len=$slowlog_len
        sleep 2
    done
}

# Alert system
check_alerts() {
    local alerts=()
    
    # Check memory usage
    local info_memory=$(get_redis_info memory)
    local used_memory=$(echo "$info_memory" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$info_memory" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    
    if [[ "$maxmemory" != "0" ]]; then
        local usage_percent=$(( (used_memory * 100) / maxmemory ))
        if [[ $usage_percent -gt $MEMORY_THRESHOLD ]]; then
            alerts+=("High memory usage: ${usage_percent}%")
        fi
    fi
    
    # Check connections
    local info_clients=$(get_redis_info clients)
    local connected_clients=$(echo "$info_clients" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    
    if [[ $connected_clients -gt $CONNECTION_THRESHOLD ]]; then
        alerts+=("High connection count: $connected_clients")
    fi
    
    # Check slow queries
    local slowlog_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog len 2>/dev/null)
    if [[ $slowlog_len -gt 10 ]]; then
        alerts+=("Slow queries detected: $slowlog_len")
    fi
    
    # Display alerts
    if [[ ${#alerts[@]} -gt 0 ]]; then
        echo -e "${RED}⚠ ALERTS:${NC}"
        for alert in "${alerts[@]}"; do
            echo -e "${RED}  • $alert${NC}"
            log "WARN" "$alert"
        done
        return 1
    else
        echo -e "${GREEN}✓ No alerts${NC}"
        return 0
    fi
}
