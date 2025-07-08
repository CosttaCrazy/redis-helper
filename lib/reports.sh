#!/bin/bash

# Redis Helper - Reports & Export Module v1.1
# Licensed under GPLv3

# Reports and export menu
reports_export_menu() {
    while true; do
        show_header
        echo -e "${CYAN}┌─ Reports & Export ──────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Performance Report                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) Security Report                                         ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Capacity Planning Report                                ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Historical Analysis                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Custom Report Builder                                   ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Export Metrics (CSV/JSON)                               ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 7) Generate Executive Summary                              ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 8) Trend Analysis                                          ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 9) Automated Reporting                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) generate_performance_report ;;
            2) generate_security_report ;;
            3) generate_capacity_report ;;
            4) historical_analysis ;;
            5) custom_report_builder ;;
            6) export_metrics ;;
            7) generate_executive_summary ;;
            8) trend_analysis ;;
            9) automated_reporting ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Generate performance report
generate_performance_report() {
    echo -e "${YELLOW}Performance Report Generation${NC}"
    echo "================================"
    
    local report_file="$METRICS_DIR/performance_report_$(date +%Y%m%d_%H%M%S).txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "Generating comprehensive performance report..."
    echo "Report will be saved to: $report_file"
    echo
    
    # Create report header
    cat > "$report_file" << EOF
Redis Performance Report
Generated: $timestamp
Redis Host: $REDIS_HOST:$REDIS_PORT
Environment: $ENVIRONMENT

================================
EXECUTIVE SUMMARY
================================

EOF
    
    # Get current metrics
    local info_server=$(get_redis_info server)
    local info_memory=$(get_redis_info memory)
    local info_stats=$(get_redis_info stats)
    local info_clients=$(get_redis_info clients)
    local info_persistence=$(get_redis_info persistence)
    
    # Parse key metrics
    local redis_version=$(echo "$info_server" | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
    local uptime_seconds=$(echo "$info_server" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(echo "$info_memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local used_memory_peak_human=$(echo "$info_memory" | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')
    local total_commands=$(echo "$info_stats" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
    local ops_per_sec=$(echo "$info_stats" | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | tr -d '\r')
    local connected_clients=$(echo "$info_clients" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    
    # Calculate uptime
    local uptime_days=$((uptime_seconds / 86400))
    local uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
    
    # Add summary to report
    cat >> "$report_file" << EOF
Redis Version: $redis_version
Uptime: $uptime_days days, $uptime_hours hours
Current Memory Usage: $used_memory_human
Peak Memory Usage: $used_memory_peak_human
Total Commands Processed: $total_commands
Current Operations/sec: $ops_per_sec
Connected Clients: $connected_clients

================================
DETAILED METRICS
================================

Memory Information:
$(echo "$info_memory" | grep -E "(used_memory|maxmemory|mem_fragmentation)")

Performance Statistics:
$(echo "$info_stats" | grep -E "(total_commands|instantaneous_ops|keyspace_hits|keyspace_misses)")

Client Information:
$(echo "$info_clients")

Persistence Information:
$(echo "$info_persistence" | grep -E "(rdb_|aof_)")

================================
PERFORMANCE ANALYSIS
================================

EOF
    
    # Performance analysis
    local hit_rate=0
    local keyspace_hits=$(echo "$info_stats" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
    local keyspace_misses=$(echo "$info_stats" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')
    
    if [[ -n "$keyspace_hits" ]] && [[ -n "$keyspace_misses" ]] && [[ $((keyspace_hits + keyspace_misses)) -gt 0 ]]; then
        hit_rate=$(( (keyspace_hits * 100) / (keyspace_hits + keyspace_misses) ))
    fi
    
    echo "Cache Hit Rate: $hit_rate%" >> "$report_file"
    
    if [[ $hit_rate -lt 80 ]]; then
        echo "⚠ WARNING: Low cache hit rate detected" >> "$report_file"
    else
        echo "✓ Cache hit rate is healthy" >> "$report_file"
    fi
    
    # Memory fragmentation analysis
    local mem_fragmentation=$(echo "$info_memory" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')
    if [[ -n "$mem_fragmentation" ]]; then
        echo "" >> "$report_file"
        echo "Memory Fragmentation Ratio: $mem_fragmentation" >> "$report_file"
        
        if (( $(echo "$mem_fragmentation > 1.5" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠ WARNING: High memory fragmentation detected" >> "$report_file"
        else
            echo "✓ Memory fragmentation is acceptable" >> "$report_file"
        fi
    fi
    
    # Slowlog analysis
    local slowlog_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog len 2>/dev/null)
    echo "" >> "$report_file"
    echo "Slow Query Count: $slowlog_len" >> "$report_file"
    
    if [[ $slowlog_len -gt 10 ]]; then
        echo "⚠ WARNING: Multiple slow queries detected" >> "$report_file"
        echo "" >> "$report_file"
        echo "Recent Slow Queries:" >> "$report_file"
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog get 5 >> "$report_file"
    else
        echo "✓ No significant slow query issues" >> "$report_file"
    fi
    
    # Recommendations
    cat >> "$report_file" << EOF

================================
RECOMMENDATIONS
================================

Performance Optimization:
EOF
    
    if [[ $hit_rate -lt 80 ]]; then
        echo "• Investigate cache miss patterns and optimize data access" >> "$report_file"
    fi
    
    if [[ $ops_per_sec -gt 10000 ]]; then
        echo "• High operations rate - consider read replicas or clustering" >> "$report_file"
    fi
    
    if [[ $connected_clients -gt 100 ]]; then
        echo "• High client connection count - implement connection pooling" >> "$report_file"
    fi
    
    echo "• Regular monitoring and alerting setup recommended" >> "$report_file"
    echo "• Consider implementing backup and disaster recovery procedures" >> "$report_file"
    
    echo -e "${GREEN}✓ Performance report generated: $report_file${NC}"
    log "INFO" "Performance report generated: $report_file"
}

# Generate capacity planning report
generate_capacity_report() {
    echo -e "${YELLOW}Capacity Planning Report${NC}"
    echo "================================"
    
    local report_file="$METRICS_DIR/capacity_report_$(date +%Y%m%d_%H%M%S).txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "Generating capacity planning report..."
    echo "Report will be saved to: $report_file"
    echo
    
    # Get current metrics
    local info_memory=$(get_redis_info memory)
    local info_stats=$(get_redis_info stats)
    local info_server=$(get_redis_info server)
    
    # Parse metrics
    local used_memory=$(echo "$info_memory" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(echo "$info_memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$info_memory" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    local total_commands=$(echo "$info_stats" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
    local uptime_seconds=$(echo "$info_server" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r')
    
    # Create report
    cat > "$report_file" << EOF
Redis Capacity Planning Report
Generated: $timestamp
Redis Host: $REDIS_HOST:$REDIS_PORT
Environment: $ENVIRONMENT

================================
CURRENT CAPACITY STATUS
================================

Memory Usage:
  Current: $used_memory_human ($used_memory bytes)
  Maximum: $(if [[ "$maxmemory" != "0" ]]; then echo "$(numfmt --to=iec $maxmemory)B"; else echo "No limit set"; fi)
  Usage: $(if [[ "$maxmemory" != "0" ]]; then echo "$(( (used_memory * 100) / maxmemory ))%"; else echo "N/A"; fi)

Command Processing:
  Total Commands: $total_commands
  Uptime: $((uptime_seconds / 86400)) days
  Average Commands/Day: $(if [[ $uptime_seconds -gt 86400 ]]; then echo $((total_commands / (uptime_seconds / 86400))); else echo "N/A"; fi)

================================
GROWTH PROJECTIONS
================================

EOF
    
    # Calculate growth projections
    if [[ $uptime_seconds -gt 86400 ]]; then
        local daily_commands=$((total_commands / (uptime_seconds / 86400)))
        local monthly_commands=$((daily_commands * 30))
        local yearly_commands=$((daily_commands * 365))
        
        echo "Projected Command Volume:" >> "$report_file"
        echo "  Daily: $daily_commands commands" >> "$report_file"
        echo "  Monthly: $monthly_commands commands" >> "$report_file"
        echo "  Yearly: $yearly_commands commands" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    # Memory growth estimation
    if [[ $uptime_seconds -gt 86400 ]]; then
        local daily_memory_growth=$((used_memory / (uptime_seconds / 86400)))
        local monthly_memory_growth=$((daily_memory_growth * 30))
        local yearly_memory_growth=$((daily_memory_growth * 365))
        
        echo "Estimated Memory Growth:" >> "$report_file"
        echo "  Daily: $(numfmt --to=iec $daily_memory_growth)B" >> "$report_file"
        echo "  Monthly: $(numfmt --to=iec $monthly_memory_growth)B" >> "$report_file"
        echo "  Yearly: $(numfmt --to=iec $yearly_memory_growth)B" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    # Capacity recommendations
    cat >> "$report_file" << EOF
================================
CAPACITY RECOMMENDATIONS
================================

Memory Planning:
EOF
    
    if [[ "$maxmemory" == "0" ]]; then
        echo "• Set a memory limit to prevent OOM conditions" >> "$report_file"
        echo "• Recommended: Set maxmemory to 80% of available system RAM" >> "$report_file"
    else
        local usage_percent=$(( (used_memory * 100) / maxmemory ))
        if [[ $usage_percent -gt 80 ]]; then
            echo "• Consider increasing memory limit or optimizing data structures" >> "$report_file"
        elif [[ $usage_percent -lt 50 ]]; then
            echo "• Current memory allocation appears sufficient" >> "$report_file"
        fi
    fi
    
    echo "" >> "$report_file"
    echo "Scaling Recommendations:" >> "$report_file"
    echo "• Monitor memory usage trends over time" >> "$report_file"
    echo "• Plan for 2x current usage as safety margin" >> "$report_file"
    echo "• Consider Redis clustering for horizontal scaling" >> "$report_file"
    echo "• Implement data archiving for old/unused keys" >> "$report_file"
    
    echo -e "${GREEN}✓ Capacity planning report generated: $report_file${NC}"
    log "INFO" "Capacity planning report generated: $report_file"
}

# Export metrics
export_metrics() {
    echo -e "${YELLOW}Export Metrics${NC}"
    echo "================================"
    
    echo "Export format options:"
    echo "1) CSV format"
    echo "2) JSON format"
    echo "3) Both formats"
    echo "0) Back"
    
    echo -n "Select format: "
    read -r format_choice
    
    case $format_choice in
        1) export_metrics_csv ;;
        2) export_metrics_json ;;
        3) 
            export_metrics_csv
            export_metrics_json
            ;;
        0) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Export metrics to CSV
export_metrics_csv() {
    local csv_file="$METRICS_DIR/redis_metrics_$(date +%Y%m%d_%H%M%S).csv"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "Exporting metrics to CSV: $csv_file"
    
    # Create CSV header
    cat > "$csv_file" << EOF
timestamp,redis_version,uptime_seconds,used_memory,used_memory_human,maxmemory,total_commands,ops_per_sec,connected_clients,keyspace_hits,keyspace_misses,mem_fragmentation_ratio
EOF
    
    # Get current metrics
    local info_server=$(get_redis_info server)
    local info_memory=$(get_redis_info memory)
    local info_stats=$(get_redis_info stats)
    local info_clients=$(get_redis_info clients)
    
    # Parse metrics
    local redis_version=$(echo "$info_server" | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
    local uptime_seconds=$(echo "$info_server" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r')
    local used_memory=$(echo "$info_memory" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(echo "$info_memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$info_memory" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    local mem_fragmentation=$(echo "$info_memory" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')
    local total_commands=$(echo "$info_stats" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
    local ops_per_sec=$(echo "$info_stats" | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | tr -d '\r')
    local keyspace_hits=$(echo "$info_stats" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
    local keyspace_misses=$(echo "$info_stats" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')
    local connected_clients=$(echo "$info_clients" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    
    # Add data row
    echo "$timestamp,$redis_version,$uptime_seconds,$used_memory,$used_memory_human,$maxmemory,$total_commands,$ops_per_sec,$connected_clients,$keyspace_hits,$keyspace_misses,$mem_fragmentation" >> "$csv_file"
    
    echo -e "${GREEN}✓ CSV export completed: $csv_file${NC}"
}

# Export metrics to JSON
export_metrics_json() {
    local json_file="$METRICS_DIR/redis_metrics_$(date +%Y%m%d_%H%M%S).json"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "Exporting metrics to JSON: $json_file"
    
    # Get current metrics
    local info_server=$(get_redis_info server)
    local info_memory=$(get_redis_info memory)
    local info_stats=$(get_redis_info stats)
    local info_clients=$(get_redis_info clients)
    local info_persistence=$(get_redis_info persistence)
    
    # Create JSON structure
    cat > "$json_file" << EOF
{
  "export_info": {
    "timestamp": "$timestamp",
    "redis_host": "$REDIS_HOST:$REDIS_PORT",
    "environment": "$ENVIRONMENT"
  },
  "server_info": {
$(echo "$info_server" | sed 's/:/": "/' | sed 's/$/",/' | sed 's/^/    "/' | sed '$s/,$//')
  },
  "memory_info": {
$(echo "$info_memory" | sed 's/:/": "/' | sed 's/$/",/' | sed 's/^/    "/' | sed '$s/,$//')
  },
  "stats_info": {
$(echo "$info_stats" | sed 's/:/": "/' | sed 's/$/",/' | sed 's/^/    "/' | sed '$s/,$//')
  },
  "clients_info": {
$(echo "$info_clients" | sed 's/:/": "/' | sed 's/$/",/' | sed 's/^/    "/' | sed '$s/,$//')
  },
  "persistence_info": {
$(echo "$info_persistence" | sed 's/:/": "/' | sed 's/$/",/' | sed 's/^/    "/' | sed '$s/,$//')
  }
}
EOF
    
    echo -e "${GREEN}✓ JSON export completed: $json_file${NC}"
}

# Generate executive summary
generate_executive_summary() {
    echo -e "${YELLOW}Executive Summary Generation${NC}"
    echo "================================"
    
    local summary_file="$METRICS_DIR/executive_summary_$(date +%Y%m%d_%H%M%S).txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "Generating executive summary..."
    echo "Summary will be saved to: $summary_file"
    echo
    
    # Get current metrics
    local info_server=$(get_redis_info server)
    local info_memory=$(get_redis_info memory)
    local info_stats=$(get_redis_info stats)
    
    # Parse key metrics
    local redis_version=$(echo "$info_server" | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
    local uptime_seconds=$(echo "$info_server" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(echo "$info_memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local total_commands=$(echo "$info_stats" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
    local ops_per_sec=$(echo "$info_stats" | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | tr -d '\r')
    
    # Calculate uptime
    local uptime_days=$((uptime_seconds / 86400))
    
    # Create executive summary
    cat > "$summary_file" << EOF
Redis Infrastructure Executive Summary
Generated: $timestamp
Environment: $ENVIRONMENT

================================
KEY METRICS OVERVIEW
================================

System Status: OPERATIONAL
Redis Version: $redis_version
Uptime: $uptime_days days
Memory Usage: $used_memory_human
Total Operations: $total_commands
Current Load: $ops_per_sec ops/sec

================================
HEALTH ASSESSMENT
================================

EOF
    
    # Health assessment
    local health_status="HEALTHY"
    local issues=()
    
    # Check memory usage
    local used_memory=$(echo "$info_memory" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    local maxmemory=$(echo "$info_memory" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    
    if [[ "$maxmemory" != "0" ]]; then
        local usage_percent=$(( (used_memory * 100) / maxmemory ))
        if [[ $usage_percent -gt 90 ]]; then
            health_status="AT RISK"
            issues+=("High memory usage: $usage_percent%")
        fi
    fi
    
    # Check slow queries
    local slowlog_len=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} slowlog len 2>/dev/null)
    if [[ $slowlog_len -gt 20 ]]; then
        health_status="NEEDS ATTENTION"
        issues+=("Multiple slow queries detected: $slowlog_len")
    fi
    
    echo "Overall Health: $health_status" >> "$summary_file"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "" >> "$summary_file"
        echo "Issues Requiring Attention:" >> "$summary_file"
        for issue in "${issues[@]}"; do
            echo "• $issue" >> "$summary_file"
        done
    fi
    
    # Recommendations
    cat >> "$summary_file" << EOF

================================
STRATEGIC RECOMMENDATIONS
================================

Immediate Actions:
• Continue regular monitoring and maintenance
• Ensure backup procedures are in place
• Review security configurations

Medium-term Planning:
• Capacity planning for expected growth
• Performance optimization opportunities
• Disaster recovery testing

Long-term Strategy:
• Consider clustering for high availability
• Implement automated monitoring and alerting
• Regular security audits and updates

================================
BUSINESS IMPACT
================================

Current Performance: $(if [[ $ops_per_sec -gt 1000 ]]; then echo "HIGH THROUGHPUT"; elif [[ $ops_per_sec -gt 100 ]]; then echo "MODERATE LOAD"; else echo "LOW LOAD"; fi)
Availability: $(if [[ $uptime_days -gt 30 ]]; then echo "EXCELLENT"; elif [[ $uptime_days -gt 7 ]]; then echo "GOOD"; else echo "RECENT RESTART"; fi)
Resource Utilization: $(if [[ "$maxmemory" != "0" ]]; then echo "$(( (used_memory * 100) / maxmemory ))% of allocated memory"; else echo "No memory limits set"; fi)

Risk Assessment: $(if [[ "$health_status" == "HEALTHY" ]]; then echo "LOW RISK"; elif [[ "$health_status" == "NEEDS ATTENTION" ]]; then echo "MEDIUM RISK"; else echo "HIGH RISK"; fi)
EOF
    
    echo -e "${GREEN}✓ Executive summary generated: $summary_file${NC}"
    log "INFO" "Executive summary generated: $summary_file"
}
