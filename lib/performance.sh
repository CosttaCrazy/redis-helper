#!/bin/bash

# Redis Helper - Performance Analysis Module
# Licensed under GPLv3

# Performance analysis menu
performance_analysis_menu() {
    while true; do
        show_header
        echo -e "${CYAN}┌─ Performance Analysis ──────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Slowlog Analysis                                        ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) Hot Keys Detection                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Memory Analysis                                         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Command Statistics                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Latency Analysis                                        ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Performance Benchmark                                   ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 7) Optimization Recommendations                            ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) analyze_slowlog ;;
            2) detect_hot_keys ;;
            3) analyze_memory ;;
            4) show_command_stats ;;
            5) analyze_latency ;;
            6) run_benchmark ;;
            7) show_optimization_recommendations ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Analyze slowlog
analyze_slowlog() {
    echo -e "${YELLOW}Slowlog Analysis${NC}"
    echo "================================"
    
    local slowlog_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog len 2>/dev/null)
    echo -e "Total slow queries: ${WHITE}$slowlog_len${NC}"
    
    if [[ $slowlog_len -eq 0 ]]; then
        echo -e "${GREEN}✓ No slow queries found${NC}"
        return
    fi
    
    echo
    echo -e "${YELLOW}Recent slow queries:${NC}"
    echo "-------------------"
    
    # Get slowlog entries
    local slowlog=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog get 10 2>/dev/null)
    
    # Parse and display slowlog
    local entry_count=0
    echo "$slowlog" | while read -r line; do
        if [[ $line =~ ^[0-9]+\)$ ]]; then
            entry_count=$((entry_count + 1))
            echo -e "\n${CYAN}Entry #$entry_count:${NC}"
        elif [[ $line =~ ^[0-9]+$ ]] && [[ ${#line} -gt 8 ]]; then
            # Timestamp
            local timestamp=$(date -d "@$line" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Invalid timestamp")
            echo -e "  Time: ${WHITE}$timestamp${NC}"
        elif [[ $line =~ ^\([0-9]+\)$ ]]; then
            # Duration in microseconds
            local duration=${line//[()]/}
            local duration_ms=$((duration / 1000))
            if [[ $duration_ms -gt 100 ]]; then
                echo -e "  Duration: ${RED}${duration_ms}ms${NC}"
            else
                echo -e "  Duration: ${YELLOW}${duration_ms}ms${NC}"
            fi
        elif [[ $line =~ ^\".*\"$ ]]; then
            # Command
            echo -e "  Command: ${WHITE}$line${NC}"
        fi
    done
    
    # Slowlog statistics
    echo
    echo -e "${YELLOW}Slowlog Configuration:${NC}"
    local slowlog_max_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get slowlog-max-len 2>/dev/null | tail -1)
    local slowlog_threshold=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get slowlog-log-slower-than 2>/dev/null | tail -1)
    
    echo "Max entries: $slowlog_max_len"
    echo "Threshold: ${slowlog_threshold}μs ($((slowlog_threshold / 1000))ms)"
    
    # Recommendations
    if [[ $slowlog_len -gt 50 ]]; then
        echo
        echo -e "${RED}⚠ Recommendations:${NC}"
        echo "• High number of slow queries detected"
        echo "• Consider optimizing frequently slow commands"
        echo "• Review data structures and query patterns"
    fi
}

# Detect hot keys
detect_hot_keys() {
    echo -e "${YELLOW}Hot Keys Detection${NC}"
    echo "================================"
    
    echo "This feature requires Redis 4.0+ with --hotkeys option"
    echo "Attempting to detect hot keys..."
    echo
    
    # Try to use --hotkeys if available
    local hotkeys_output=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --hotkeys 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$hotkeys_output" ]]; then
        echo -e "${GREEN}Hot keys found:${NC}"
        echo "$hotkeys_output"
    else
        echo -e "${YELLOW}Hot keys detection not available or no hot keys found${NC}"
        echo "Alternative: Monitor with MONITOR command (use with caution in production)"
        
        echo -n "Run MONITOR for 10 seconds to detect active keys? (y/N): "
        read -r confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo "Monitoring for 10 seconds..."
            timeout 10 redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} monitor 2>/dev/null | \
            grep -o '"[^"]*"' | sort | uniq -c | sort -nr | head -20
        fi
    fi
}

# Analyze memory usage
analyze_memory() {
    echo -e "${YELLOW}Memory Analysis${NC}"
    echo "================================"
    
    local info_memory=$(get_redis_info memory)
    
    # Parse memory information
    local used_memory=$(echo "$info_memory" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(echo "$info_memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local used_memory_rss=$(echo "$info_memory" | grep "used_memory_rss:" | cut -d: -f2 | tr -d '\r')
    local used_memory_peak=$(echo "$info_memory" | grep "used_memory_peak:" | cut -d: -f2 | tr -d '\r')
    local used_memory_peak_human=$(echo "$info_memory" | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$info_memory" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    local mem_fragmentation_ratio=$(echo "$info_memory" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')
    
    echo -e "Current Usage:    ${WHITE}$used_memory_human${NC}"
    echo -e "RSS Memory:       ${WHITE}$(numfmt --to=iec $used_memory_rss)B${NC}"
    echo -e "Peak Usage:       ${WHITE}$used_memory_peak_human${NC}"
    echo -e "Fragmentation:    ${WHITE}$mem_fragmentation_ratio${NC}"
    
    if [[ "$maxmemory" != "0" ]]; then
        local usage_percent=$(( (used_memory * 100) / maxmemory ))
        echo -e "Usage Percentage: ${WHITE}$usage_percent%${NC}"
        
        local bar=$(create_progress_bar $usage_percent 40)
        if [[ $usage_percent -gt 80 ]]; then
            echo -e "Memory Bar:       ${RED}$bar${NC}"
        elif [[ $usage_percent -gt 60 ]]; then
            echo -e "Memory Bar:       ${YELLOW}$bar${NC}"
        else
            echo -e "Memory Bar:       ${GREEN}$bar${NC}"
        fi
    fi
    
    # Memory breakdown by data type
    echo
    echo -e "${YELLOW}Memory Usage by Data Type:${NC}"
    
    # This requires Redis 4.0+ with MEMORY USAGE command
    local sample_keys=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --scan --pattern "*" 2>/dev/null | head -10)
    
    if [[ -n "$sample_keys" ]]; then
        echo "Sample key memory usage:"
        echo "$sample_keys" | while read -r key; do
            local key_type=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} type "$key" 2>/dev/null)
            local key_memory=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} memory usage "$key" 2>/dev/null)
            
            if [[ -n "$key_memory" ]]; then
                printf "  %-30s %-10s %s bytes\n" "$key" "($key_type)" "$key_memory"
            fi
        done
    fi
    
    # Memory recommendations
    echo
    echo -e "${YELLOW}Memory Recommendations:${NC}"
    
    if (( $(echo "$mem_fragmentation_ratio > 1.5" | bc -l 2>/dev/null || echo 0) )); then
        echo -e "${RED}• High memory fragmentation detected${NC}"
        echo "  Consider restarting Redis during low traffic"
    fi
    
    if [[ "$maxmemory" == "0" ]]; then
        echo -e "${YELLOW}• No memory limit set${NC}"
        echo "  Consider setting maxmemory for production"
    fi
    
    local usage_percent_check=$(( (used_memory * 100) / (used_memory_peak + 1) ))
    if [[ $usage_percent_check -lt 70 ]]; then
        echo -e "${GREEN}• Memory usage is healthy${NC}"
    fi
}

# Show command statistics
show_command_stats() {
    echo -e "${YELLOW}Command Statistics${NC}"
    echo "================================"
    
    local info_commandstats=$(get_redis_info commandstats)
    
    if [[ -z "$info_commandstats" ]]; then
        echo "No command statistics available"
        return
    fi
    
    echo -e "${CYAN}Top Commands by Call Count:${NC}"
    echo "$info_commandstats" | grep "cmdstat_" | \
    sed 's/cmdstat_\([^:]*\):calls=\([^,]*\),usec=\([^,]*\),usec_per_call=\(.*\)/\2 \1 \3 \4/' | \
    sort -nr | head -10 | \
    while read -r calls cmd total_usec usec_per_call; do
        local avg_ms=$(echo "scale=2; $usec_per_call / 1000" | bc -l 2>/dev/null || echo "0")
        printf "%-15s: %10s calls, %8s ms avg\n" "$cmd" "$calls" "$avg_ms"
    done
    
    echo
    echo -e "${CYAN}Commands by Total Time:${NC}"
    echo "$info_commandstats" | grep "cmdstat_" | \
    sed 's/cmdstat_\([^:]*\):calls=\([^,]*\),usec=\([^,]*\),usec_per_call=\(.*\)/\3 \1 \2 \4/' | \
    sort -nr | head -10 | \
    while read -r total_usec cmd calls usec_per_call; do
        local total_ms=$(echo "scale=2; $total_usec / 1000" | bc -l 2>/dev/null || echo "0")
        local avg_ms=$(echo "scale=2; $usec_per_call / 1000" | bc -l 2>/dev/null || echo "0")
        printf "%-15s: %10s ms total, %8s ms avg\n" "$cmd" "$total_ms" "$avg_ms"
    done
}

# Analyze latency
analyze_latency() {
    echo -e "${YELLOW}Latency Analysis${NC}"
    echo "================================"
    
    # Test basic latency
    echo "Testing basic latency..."
    local total_latency=0
    local samples=10
    
    for ((i=1; i<=samples; i++)); do
        local start_time=$(date +%s%N)
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ping > /dev/null 2>&1
        local end_time=$(date +%s%N)
        local latency=$(( (end_time - start_time) / 1000000 ))
        total_latency=$((total_latency + latency))
        
        echo "Sample $i: ${latency}ms"
    done
    
    local avg_latency=$((total_latency / samples))
    echo
    echo -e "Average Latency: ${WHITE}${avg_latency}ms${NC}"
    
    if [[ $avg_latency -gt 100 ]]; then
        echo -e "${RED}⚠ High latency detected${NC}"
    elif [[ $avg_latency -gt 50 ]]; then
        echo -e "${YELLOW}⚠ Moderate latency${NC}"
    else
        echo -e "${GREEN}✓ Low latency${NC}"
    fi
    
    # Latency history (if available)
    echo
    echo "Checking latency history..."
    local latency_latest=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} latency latest 2>/dev/null)
    
    if [[ -n "$latency_latest" ]]; then
        echo -e "${CYAN}Latency Events:${NC}"
        echo "$latency_latest"
    else
        echo "No latency events recorded"
        echo "Enable latency monitoring with: CONFIG SET latency-monitor-threshold 100"
    fi
}

# Run performance benchmark
run_benchmark() {
    echo -e "${YELLOW}Performance Benchmark${NC}"
    echo "================================"
    
    echo -e "${RED}Warning: This will run performance tests that may impact Redis performance${NC}"
    echo -n "Continue? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo
    echo "Running benchmark tests..."
    
    # Basic benchmark
    local benchmark_cmd="redis-benchmark -h $REDIS_HOST -p $REDIS_PORT"
    [[ -n "$REDIS_PASSWORD" ]] && benchmark_cmd="$benchmark_cmd -a $REDIS_PASSWORD"
    
    echo -e "${CYAN}SET Performance:${NC}"
    $benchmark_cmd -t set -n 1000 -q 2>/dev/null | head -5
    
    echo -e "${CYAN}GET Performance:${NC}"
    $benchmark_cmd -t get -n 1000 -q 2>/dev/null | head -5
    
    echo -e "${CYAN}INCR Performance:${NC}"
    $benchmark_cmd -t incr -n 1000 -q 2>/dev/null | head -5
    
    echo -e "${CYAN}LPUSH Performance:${NC}"
    $benchmark_cmd -t lpush -n 1000 -q 2>/dev/null | head -5
    
    echo -e "${CYAN}LPOP Performance:${NC}"
    $benchmark_cmd -t lpop -n 1000 -q 2>/dev/null | head -5
}

# Show optimization recommendations
show_optimization_recommendations() {
    echo -e "${YELLOW}Optimization Recommendations${NC}"
    echo "================================"
    
    local recommendations=()
    
    # Check memory usage
    local info_memory=$(get_redis_info memory)
    local used_memory=$(echo "$info_memory" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$info_memory" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    local mem_fragmentation_ratio=$(echo "$info_memory" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')
    
    if [[ "$maxmemory" == "0" ]]; then
        recommendations+=("Set maxmemory limit to prevent OOM issues")
    fi
    
    if (( $(echo "$mem_fragmentation_ratio > 1.5" | bc -l 2>/dev/null || echo 0) )); then
        recommendations+=("High memory fragmentation - consider restart during low traffic")
    fi
    
    # Check slowlog
    local slowlog_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog len 2>/dev/null)
    if [[ $slowlog_len -gt 10 ]]; then
        recommendations+=("Optimize slow queries - $slowlog_len slow queries found")
    fi
    
    # Check connections
    local info_clients=$(get_redis_info clients)
    local connected_clients=$(echo "$info_clients" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    if [[ $connected_clients -gt 100 ]]; then
        recommendations+=("High connection count - consider connection pooling")
    fi
    
    # Check persistence
    local info_persistence=$(get_redis_info persistence)
    local rdb_last_save_time=$(echo "$info_persistence" | grep "rdb_last_save_time:" | cut -d: -f2 | tr -d '\r')
    local current_time=$(date +%s)
    local time_since_save=$((current_time - rdb_last_save_time))
    
    if [[ $time_since_save -gt 3600 ]]; then
        recommendations+=("No recent backup - last save was $((time_since_save / 3600)) hours ago")
    fi
    
    # Display recommendations
    if [[ ${#recommendations[@]} -gt 0 ]]; then
        echo -e "${RED}Recommendations:${NC}"
        for rec in "${recommendations[@]}"; do
            echo -e "${YELLOW}• $rec${NC}"
        done
    else
        echo -e "${GREEN}✓ No major optimization issues found${NC}"
    fi
    
    echo
    echo -e "${CYAN}General Best Practices:${NC}"
    echo "• Use appropriate data structures for your use case"
    echo "• Set TTL on keys that don't need to persist"
    echo "• Monitor memory usage and set maxmemory policies"
    echo "• Use connection pooling in applications"
    echo "• Regular backups and monitoring"
    echo "• Keep Redis version updated"
    echo "• Use Redis Cluster for horizontal scaling"
}
