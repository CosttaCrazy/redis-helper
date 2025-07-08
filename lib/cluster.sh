#!/bin/bash

# Redis Helper - Cluster Management Module v1.1
# Licensed under GPLv3

# Cluster management menu
cluster_management_menu() {
    while true; do
        show_header
        echo -e "${CYAN}┌─ Cluster Management ────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Cluster Status Overview                                 ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) Node Health Check                                       ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Slot Distribution Analysis                              ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Failover Monitoring                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Replication Status                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Cluster Configuration                                   ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 7) Add/Remove Nodes                                        ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 8) Cluster Rebalancing                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 9) Cross-Node Backup                                       ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) show_cluster_overview ;;
            2) check_node_health ;;
            3) analyze_slot_distribution ;;
            4) monitor_failover ;;
            5) check_replication_status ;;
            6) show_cluster_configuration ;;
            7) manage_cluster_nodes ;;
            8) rebalance_cluster ;;
            9) cross_node_backup ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Check if Redis is running in cluster mode
is_cluster_enabled() {
    local cluster_enabled=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get cluster-enabled 2>/dev/null | tail -1)
    [[ "$cluster_enabled" == "yes" ]]
}

# Show cluster overview
show_cluster_overview() {
    echo -e "${YELLOW}Redis Cluster Overview${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Redis cluster mode is not enabled${NC}"
        echo "This Redis instance is running in standalone mode."
        echo
        echo "To enable cluster mode:"
        echo "1. Set cluster-enabled yes in redis.conf"
        echo "2. Set cluster-config-file nodes.conf"
        echo "3. Restart Redis"
        return 1
    fi
    
    echo -e "${GREEN}✓ Redis cluster mode enabled${NC}"
    echo
    
    # Get cluster info
    local cluster_info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster info 2>/dev/null)
    
    if [[ -z "$cluster_info" ]]; then
        echo -e "${RED}✗ Unable to retrieve cluster information${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Cluster Information:${NC}"
    echo "-------------------"
    
    # Parse cluster info
    local cluster_state=$(echo "$cluster_info" | grep "cluster_state:" | cut -d: -f2 | tr -d '\r')
    local cluster_slots_assigned=$(echo "$cluster_info" | grep "cluster_slots_assigned:" | cut -d: -f2 | tr -d '\r')
    local cluster_slots_ok=$(echo "$cluster_info" | grep "cluster_slots_ok:" | cut -d: -f2 | tr -d '\r')
    local cluster_slots_pfail=$(echo "$cluster_info" | grep "cluster_slots_pfail:" | cut -d: -f2 | tr -d '\r')
    local cluster_slots_fail=$(echo "$cluster_info" | grep "cluster_slots_fail:" | cut -d: -f2 | tr -d '\r')
    local cluster_known_nodes=$(echo "$cluster_info" | grep "cluster_known_nodes:" | cut -d: -f2 | tr -d '\r')
    local cluster_size=$(echo "$cluster_info" | grep "cluster_size:" | cut -d: -f2 | tr -d '\r')
    
    # Display cluster state with color coding
    echo -n "Cluster State: "
    if [[ "$cluster_state" == "ok" ]]; then
        echo -e "${GREEN}$cluster_state${NC}"
    else
        echo -e "${RED}$cluster_state${NC}"
    fi
    
    echo "Known Nodes: $cluster_known_nodes"
    echo "Cluster Size: $cluster_size"
    echo "Slots Assigned: $cluster_slots_assigned/16384"
    echo "Slots OK: $cluster_slots_ok"
    
    if [[ "$cluster_slots_pfail" != "0" ]]; then
        echo -e "Slots PFAIL: ${YELLOW}$cluster_slots_pfail${NC}"
    fi
    
    if [[ "$cluster_slots_fail" != "0" ]]; then
        echo -e "Slots FAIL: ${RED}$cluster_slots_fail${NC}"
    fi
    
    # Show slot coverage
    local slot_coverage=$(( (cluster_slots_assigned * 100) / 16384 ))
    echo "Slot Coverage: $slot_coverage%"
    
    if [[ $slot_coverage -lt 100 ]]; then
        echo -e "${YELLOW}⚠ Warning: Not all slots are assigned${NC}"
    fi
    
    # Get cluster nodes
    echo
    echo -e "${CYAN}Cluster Nodes:${NC}"
    echo "-------------"
    
    local cluster_nodes=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes 2>/dev/null)
    
    if [[ -n "$cluster_nodes" ]]; then
        echo "$cluster_nodes" | while read -r line; do
            local node_id=$(echo "$line" | awk '{print $1}')
            local node_addr=$(echo "$line" | awk '{print $2}')
            local node_flags=$(echo "$line" | awk '{print $3}')
            local node_master=$(echo "$line" | awk '{print $4}')
            local node_slots=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s ", $i}')
            
            echo -n "Node: ${node_addr} "
            
            if [[ "$node_flags" == *"master"* ]]; then
                echo -e "${GREEN}[MASTER]${NC}"
            elif [[ "$node_flags" == *"slave"* ]]; then
                echo -e "${BLUE}[SLAVE]${NC}"
            else
                echo -e "${YELLOW}[${node_flags}]${NC}"
            fi
            
            if [[ "$node_flags" == *"fail"* ]]; then
                echo -e "  ${RED}Status: FAILED${NC}"
            elif [[ "$node_flags" == *"pfail"* ]]; then
                echo -e "  ${YELLOW}Status: POSSIBLY FAILED${NC}"
            else
                echo -e "  ${GREEN}Status: OK${NC}"
            fi
            
            if [[ -n "$node_slots" ]] && [[ "$node_slots" != "-" ]]; then
                local slot_count=$(echo "$node_slots" | wc -w)
                echo "  Slots: $slot_count ranges"
            fi
            
            echo
        done
    else
        echo "No cluster nodes information available"
    fi
}

# Check node health
check_node_health() {
    echo -e "${YELLOW}Node Health Check${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        return 1
    fi
    
    echo "Checking health of all cluster nodes..."
    echo
    
    # Get cluster nodes
    local cluster_nodes=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes 2>/dev/null)
    
    if [[ -z "$cluster_nodes" ]]; then
        echo -e "${RED}✗ Unable to retrieve cluster nodes${NC}"
        return 1
    fi
    
    local healthy_nodes=0
    local total_nodes=0
    local failed_nodes=()
    
    echo -e "${CYAN}Individual Node Health:${NC}"
    echo "----------------------"
    
    echo "$cluster_nodes" | while read -r line; do
        local node_addr=$(echo "$line" | awk '{print $2}' | cut -d'@' -f1)
        local node_flags=$(echo "$line" | awk '{print $3}')
        local node_id=$(echo "$line" | awk '{print $1}')
        
        total_nodes=$((total_nodes + 1))
        
        echo -n "Checking $node_addr... "
        
        # Extract host and port
        local node_host=$(echo "$node_addr" | cut -d: -f1)
        local node_port=$(echo "$node_addr" | cut -d: -f2)
        
        # Test connectivity
        if redis-cli -h "$node_host" -p "$node_port" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ping >/dev/null 2>&1; then
            echo -e "${GREEN}✓ HEALTHY${NC}"
            healthy_nodes=$((healthy_nodes + 1))
            
            # Get additional health metrics
            local memory_info=$(redis-cli -h "$node_host" -p "$node_port" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} info memory 2>/dev/null)
            local used_memory=$(echo "$memory_info" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
            
            if [[ -n "$used_memory" ]]; then
                echo "  Memory: $used_memory"
            fi
            
            # Check if node is in failed state according to cluster
            if [[ "$node_flags" == *"fail"* ]]; then
                echo -e "  ${RED}⚠ Marked as FAILED in cluster${NC}"
            elif [[ "$node_flags" == *"pfail"* ]]; then
                echo -e "  ${YELLOW}⚠ Marked as POSSIBLY FAILED${NC}"
            fi
            
        else
            echo -e "${RED}✗ UNREACHABLE${NC}"
            failed_nodes+=("$node_addr")
        fi
        
        echo
    done
    
    # Health summary
    echo -e "${CYAN}Health Summary:${NC}"
    echo "--------------"
    echo "Total nodes: $total_nodes"
    echo "Healthy nodes: $healthy_nodes"
    echo "Failed nodes: $((total_nodes - healthy_nodes))"
    
    if [[ ${#failed_nodes[@]} -gt 0 ]]; then
        echo
        echo -e "${RED}Failed nodes:${NC}"
        for failed_node in "${failed_nodes[@]}"; do
            echo "  • $failed_node"
        done
    fi
    
    # Calculate health percentage
    if [[ $total_nodes -gt 0 ]]; then
        local health_percentage=$(( (healthy_nodes * 100) / total_nodes ))
        echo
        echo -n "Cluster Health: "
        
        if [[ $health_percentage -eq 100 ]]; then
            echo -e "${GREEN}$health_percentage% (Excellent)${NC}"
        elif [[ $health_percentage -ge 80 ]]; then
            echo -e "${YELLOW}$health_percentage% (Good)${NC}"
        else
            echo -e "${RED}$health_percentage% (Critical)${NC}"
        fi
    fi
}

# Analyze slot distribution
analyze_slot_distribution() {
    echo -e "${YELLOW}Slot Distribution Analysis${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        return 1
    fi
    
    echo "Analyzing Redis cluster slot distribution..."
    echo
    
    # Get cluster nodes
    local cluster_nodes=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes 2>/dev/null)
    
    if [[ -z "$cluster_nodes" ]]; then
        echo -e "${RED}✗ Unable to retrieve cluster nodes${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Slot Distribution by Node:${NC}"
    echo "-------------------------"
    
    local total_slots=0
    local master_nodes=0
    declare -A node_slots
    
    # Parse slot information
    echo "$cluster_nodes" | while read -r line; do
        local node_addr=$(echo "$line" | awk '{print $2}' | cut -d'@' -f1)
        local node_flags=$(echo "$line" | awk '{print $3}')
        local node_slots_raw=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s ", $i}')
        
        # Only process master nodes
        if [[ "$node_flags" == *"master"* ]]; then
            master_nodes=$((master_nodes + 1))
            
            # Count slots for this node
            local slot_count=0
            if [[ -n "$node_slots_raw" ]] && [[ "$node_slots_raw" != "-" ]]; then
                # Count individual slots and ranges
                for slot_range in $node_slots_raw; do
                    if [[ "$slot_range" == *"-"* ]]; then
                        # Range of slots
                        local start_slot=$(echo "$slot_range" | cut -d'-' -f1)
                        local end_slot=$(echo "$slot_range" | cut -d'-' -f2)
                        slot_count=$((slot_count + end_slot - start_slot + 1))
                    else
                        # Single slot
                        slot_count=$((slot_count + 1))
                    fi
                done
            fi
            
            total_slots=$((total_slots + slot_count))
            node_slots["$node_addr"]=$slot_count
            
            # Display node slot information
            echo -n "$node_addr: "
            if [[ $slot_count -gt 0 ]]; then
                local percentage=$(( (slot_count * 100) / 16384 ))
                echo -e "${GREEN}$slot_count slots ($percentage%)${NC}"
            else
                echo -e "${RED}0 slots${NC}"
            fi
        fi
    done
    
    echo
    echo -e "${CYAN}Distribution Summary:${NC}"
    echo "-------------------"
    echo "Total slots assigned: $total_slots/16384"
    echo "Master nodes: $master_nodes"
    
    if [[ $master_nodes -gt 0 ]]; then
        local avg_slots_per_node=$(( 16384 / master_nodes ))
        echo "Expected slots per node: $avg_slots_per_node"
        
        # Check for imbalanced distribution
        local max_deviation=0
        for node in "${!node_slots[@]}"; do
            local node_slot_count=${node_slots[$node]}
            local deviation=$(( node_slot_count - avg_slots_per_node ))
            local abs_deviation=${deviation#-}  # Absolute value
            
            if [[ $abs_deviation -gt $max_deviation ]]; then
                max_deviation=$abs_deviation
            fi
        done
        
        echo "Maximum deviation: $max_deviation slots"
        
        if [[ $max_deviation -gt $(( avg_slots_per_node / 10 )) ]]; then
            echo -e "${YELLOW}⚠ Cluster appears to be imbalanced${NC}"
            echo "Consider running cluster rebalancing"
        else
            echo -e "${GREEN}✓ Cluster is well balanced${NC}"
        fi
    fi
    
    # Check for unassigned slots
    local unassigned_slots=$(( 16384 - total_slots ))
    if [[ $unassigned_slots -gt 0 ]]; then
        echo -e "${RED}⚠ $unassigned_slots slots are unassigned${NC}"
        echo "This may cause cluster to be in 'fail' state"
    else
        echo -e "${GREEN}✓ All slots are assigned${NC}"
    fi
    
    # Slot coverage visualization
    echo
    echo -e "${CYAN}Slot Coverage Visualization:${NC}"
    echo "---------------------------"
    
    local coverage_percentage=$(( (total_slots * 100) / 16384 ))
    local bar_length=50
    local filled_length=$(( (coverage_percentage * bar_length) / 100 ))
    local bar=""
    
    for ((i=0; i<filled_length; i++)); do bar+="█"; done
    for ((i=filled_length; i<bar_length; i++)); do bar+="░"; done
    
    if [[ $coverage_percentage -eq 100 ]]; then
        echo -e "${GREEN}[$bar] $coverage_percentage%${NC}"
    else
        echo -e "${RED}[$bar] $coverage_percentage%${NC}"
    fi
}
# Monitor failover
monitor_failover() {
    echo -e "${YELLOW}Failover Monitoring${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        return 1
    fi
    
    echo "Monitoring cluster for failover events..."
    echo "Press Ctrl+C to stop monitoring"
    echo
    
    local previous_state=""
    local failover_count=0
    
    while true; do
        # Get current cluster state
        local cluster_info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster info 2>/dev/null)
        local cluster_state=$(echo "$cluster_info" | grep "cluster_state:" | cut -d: -f2 | tr -d '\r')
        local cluster_nodes=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes 2>/dev/null)
        
        local timestamp=$(date '+%H:%M:%S')
        
        # Check for state changes
        if [[ -n "$previous_state" ]] && [[ "$cluster_state" != "$previous_state" ]]; then
            echo -e "[$timestamp] ${YELLOW}Cluster state changed: $previous_state → $cluster_state${NC}"
            failover_count=$((failover_count + 1))
        fi
        
        # Check for failed nodes
        local failed_nodes=$(echo "$cluster_nodes" | grep -c "fail" || echo "0")
        local pfail_nodes=$(echo "$cluster_nodes" | grep -c "pfail" || echo "0")
        
        # Display current status
        echo -n "[$timestamp] State: "
        if [[ "$cluster_state" == "ok" ]]; then
            echo -e "${GREEN}$cluster_state${NC}"
        else
            echo -e "${RED}$cluster_state${NC}"
        fi
        
        if [[ $failed_nodes -gt 0 ]]; then
            echo -e "  ${RED}Failed nodes: $failed_nodes${NC}"
        fi
        
        if [[ $pfail_nodes -gt 0 ]]; then
            echo -e "  ${YELLOW}Possibly failed nodes: $pfail_nodes${NC}"
        fi
        
        # Check for recent failovers in cluster nodes output
        local recent_failovers=$(echo "$cluster_nodes" | grep -E "master|slave" | while read -r line; do
            local node_flags=$(echo "$line" | awk '{print $3}')
            if [[ "$node_flags" == *"fail"* ]] || [[ "$node_flags" == *"pfail"* ]]; then
                echo "$line"
            fi
        done)
        
        if [[ -n "$recent_failovers" ]]; then
            echo -e "${RED}Nodes in failed state detected:${NC}"
            echo "$recent_failovers"
        fi
        
        previous_state="$cluster_state"
        sleep 5
    done
}

# Check replication status
check_replication_status() {
    echo -e "${YELLOW}Replication Status Check${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        return 1
    fi
    
    echo "Checking replication status across cluster..."
    echo
    
    # Get cluster nodes
    local cluster_nodes=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes 2>/dev/null)
    
    if [[ -z "$cluster_nodes" ]]; then
        echo -e "${RED}✗ Unable to retrieve cluster nodes${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Master-Slave Relationships:${NC}"
    echo "--------------------------"
    
    local master_count=0
    local slave_count=0
    declare -A master_slaves
    
    # First pass: identify masters and slaves
    echo "$cluster_nodes" | while read -r line; do
        local node_id=$(echo "$line" | awk '{print $1}')
        local node_addr=$(echo "$line" | awk '{print $2}' | cut -d'@' -f1)
        local node_flags=$(echo "$line" | awk '{print $3}')
        local master_id=$(echo "$line" | awk '{print $4}')
        
        if [[ "$node_flags" == *"master"* ]]; then
            master_count=$((master_count + 1))
            echo -e "${GREEN}Master: $node_addr${NC} (ID: ${node_id:0:8}...)"
            
            # Find slaves for this master
            local slaves=$(echo "$cluster_nodes" | grep "$node_id" | grep "slave")
            if [[ -n "$slaves" ]]; then
                echo "$slaves" | while read -r slave_line; do
                    local slave_addr=$(echo "$slave_line" | awk '{print $2}' | cut -d'@' -f1)
                    local slave_id=$(echo "$slave_line" | awk '{print $1}')
                    echo -e "  └─ ${BLUE}Slave: $slave_addr${NC} (ID: ${slave_id:0:8}...)"
                done
            else
                echo -e "  ${YELLOW}⚠ No slaves found${NC}"
            fi
            echo
            
        elif [[ "$node_flags" == *"slave"* ]]; then
            slave_count=$((slave_count + 1))
        fi
    done
    
    echo -e "${CYAN}Replication Summary:${NC}"
    echo "-------------------"
    echo "Master nodes: $master_count"
    echo "Slave nodes: $slave_count"
    
    if [[ $slave_count -eq 0 ]]; then
        echo -e "${RED}⚠ WARNING: No slave nodes found${NC}"
        echo "Cluster has no redundancy - single point of failure"
    elif [[ $slave_count -lt $master_count ]]; then
        echo -e "${YELLOW}⚠ WARNING: Not all masters have slaves${NC}"
        echo "Some masters lack redundancy"
    else
        echo -e "${GREEN}✓ Replication appears to be configured${NC}"
    fi
    
    # Check replication lag for accessible nodes
    echo
    echo -e "${CYAN}Replication Lag Analysis:${NC}"
    echo "------------------------"
    
    echo "$cluster_nodes" | grep "slave" | while read -r line; do
        local slave_addr=$(echo "$line" | awk '{print $2}' | cut -d'@' -f1)
        local slave_host=$(echo "$slave_addr" | cut -d: -f1)
        local slave_port=$(echo "$slave_addr" | cut -d: -f2)
        
        echo -n "Checking $slave_addr... "
        
        # Try to get replication info from slave
        local repl_info=$(redis-cli -h "$slave_host" -p "$slave_port" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} info replication 2>/dev/null)
        
        if [[ -n "$repl_info" ]]; then
            local master_link_status=$(echo "$repl_info" | grep "master_link_status:" | cut -d: -f2 | tr -d '\r')
            local master_last_io_seconds=$(echo "$repl_info" | grep "master_last_io_seconds_ago:" | cut -d: -f2 | tr -d '\r')
            
            if [[ "$master_link_status" == "up" ]]; then
                echo -e "${GREEN}✓ Connected${NC}"
                if [[ -n "$master_last_io_seconds" ]] && [[ "$master_last_io_seconds" != "-1" ]]; then
                    if [[ $master_last_io_seconds -gt 10 ]]; then
                        echo -e "  ${YELLOW}⚠ Last I/O: ${master_last_io_seconds}s ago${NC}"
                    else
                        echo -e "  ${GREEN}✓ Last I/O: ${master_last_io_seconds}s ago${NC}"
                    fi
                fi
            else
                echo -e "${RED}✗ Disconnected${NC}"
            fi
        else
            echo -e "${RED}✗ Unreachable${NC}"
        fi
    done
}

# Show cluster configuration
show_cluster_configuration() {
    echo -e "${YELLOW}Cluster Configuration${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        echo
        echo "To enable cluster mode, add these settings to redis.conf:"
        echo "  cluster-enabled yes"
        echo "  cluster-config-file nodes-6379.conf"
        echo "  cluster-node-timeout 15000"
        echo "  appendonly yes"
        return 1
    fi
    
    echo "Current cluster configuration:"
    echo
    
    # Get cluster-related configuration
    local cluster_configs=(
        "cluster-enabled"
        "cluster-config-file"
        "cluster-node-timeout"
        "cluster-slave-validity-factor"
        "cluster-migration-barrier"
        "cluster-require-full-coverage"
        "cluster-slave-no-failover"
    )
    
    echo -e "${CYAN}Cluster Settings:${NC}"
    echo "-----------------"
    
    for config in "${cluster_configs[@]}"; do
        local value=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get "$config" 2>/dev/null | tail -1)
        
        if [[ -n "$value" ]]; then
            case "$config" in
                "cluster-enabled")
                    if [[ "$value" == "yes" ]]; then
                        echo -e "$config: ${GREEN}$value${NC}"
                    else
                        echo -e "$config: ${RED}$value${NC}"
                    fi
                    ;;
                "cluster-require-full-coverage")
                    if [[ "$value" == "yes" ]]; then
                        echo -e "$config: ${YELLOW}$value${NC} (strict mode)"
                    else
                        echo -e "$config: ${GREEN}$value${NC} (partial coverage allowed)"
                    fi
                    ;;
                *)
                    echo "$config: $value"
                    ;;
            esac
        else
            echo "$config: Not set"
        fi
    done
    
    # Show cluster info
    echo
    echo -e "${CYAN}Runtime Cluster Information:${NC}"
    echo "---------------------------"
    
    local cluster_info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster info 2>/dev/null)
    
    if [[ -n "$cluster_info" ]]; then
        echo "$cluster_info" | while IFS=: read -r key value; do
            case "$key" in
                "cluster_state")
                    echo -n "Cluster State: "
                    if [[ "$value" == "ok" ]]; then
                        echo -e "${GREEN}$value${NC}"
                    else
                        echo -e "${RED}$value${NC}"
                    fi
                    ;;
                "cluster_slots_assigned"|"cluster_slots_ok"|"cluster_slots_pfail"|"cluster_slots_fail")
                    echo "$key: $value"
                    ;;
                "cluster_known_nodes"|"cluster_size")
                    echo "$key: $value"
                    ;;
            esac
        done
    fi
    
    # Configuration recommendations
    echo
    echo -e "${CYAN}Configuration Recommendations:${NC}"
    echo "-----------------------------"
    
    local node_timeout=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get cluster-node-timeout 2>/dev/null | tail -1)
    
    if [[ -n "$node_timeout" ]]; then
        if [[ $node_timeout -lt 5000 ]]; then
            echo -e "${YELLOW}⚠ Node timeout is quite low ($node_timeout ms)${NC}"
            echo "  Consider increasing for network stability"
        elif [[ $node_timeout -gt 30000 ]]; then
            echo -e "${YELLOW}⚠ Node timeout is quite high ($node_timeout ms)${NC}"
            echo "  Consider decreasing for faster failover"
        else
            echo -e "${GREEN}✓ Node timeout is reasonable ($node_timeout ms)${NC}"
        fi
    fi
    
    local full_coverage=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get cluster-require-full-coverage 2>/dev/null | tail -1)
    
    if [[ "$full_coverage" == "yes" ]]; then
        echo -e "${YELLOW}⚠ Full coverage required${NC}"
        echo "  Cluster will stop accepting writes if any slots are unassigned"
    else
        echo -e "${GREEN}✓ Partial coverage allowed${NC}"
        echo "  Cluster can operate with some unassigned slots"
    fi
}

# Manage cluster nodes (add/remove)
manage_cluster_nodes() {
    echo -e "${YELLOW}Cluster Node Management${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        return 1
    fi
    
    echo "Cluster node management options:"
    echo
    echo "1) Add new node to cluster"
    echo "2) Remove node from cluster"
    echo "3) View current nodes"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r choice
    
    case $choice in
        1) add_cluster_node ;;
        2) remove_cluster_node ;;
        3) show_cluster_overview ;;
        0) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Add cluster node
add_cluster_node() {
    echo -e "${YELLOW}Add Node to Cluster${NC}"
    echo "================================"
    
    echo "To add a node to the cluster:"
    echo
    echo "1. Ensure the new Redis instance is running"
    echo "2. Configure it with cluster-enabled yes"
    echo "3. The new node should be empty (no data)"
    echo
    
    echo -n "Enter new node address (host:port): "
    read -r new_node_addr
    
    if [[ -z "$new_node_addr" ]]; then
        echo "No address provided"
        return
    fi
    
    echo -n "Add as slave to existing master? (y/N): "
    read -r add_as_slave
    
    if [[ "$add_as_slave" =~ ^[Yy]$ ]]; then
        echo "Available masters:"
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes | grep "master" | while read -r line; do
            local master_addr=$(echo "$line" | awk '{print $2}' | cut -d'@' -f1)
            local master_id=$(echo "$line" | awk '{print $1}')
            echo "  $master_addr (ID: ${master_id:0:8}...)"
        done
        
        echo -n "Enter master node ID: "
        read -r master_id
        
        if [[ -n "$master_id" ]]; then
            echo "Command to add slave node:"
            echo "redis-cli --cluster add-node $new_node_addr $REDIS_HOST:$REDIS_PORT --cluster-slave --cluster-master-id $master_id"
        fi
    else
        echo "Command to add master node:"
        echo "redis-cli --cluster add-node $new_node_addr $REDIS_HOST:$REDIS_PORT"
        echo
        echo "After adding, you may need to rebalance slots:"
        echo "redis-cli --cluster rebalance $REDIS_HOST:$REDIS_PORT"
    fi
    
    echo
    echo -e "${YELLOW}Note: These commands should be run from a machine with redis-cli and cluster support${NC}"
}

# Remove cluster node
remove_cluster_node() {
    echo -e "${YELLOW}Remove Node from Cluster${NC}"
    echo "================================"
    
    echo "Current cluster nodes:"
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes | while read -r line; do
        local node_addr=$(echo "$line" | awk '{print $2}' | cut -d'@' -f1)
        local node_id=$(echo "$line" | awk '{print $1}')
        local node_flags=$(echo "$line" | awk '{print $3}')
        echo "  $node_addr (ID: ${node_id:0:8}...) [$node_flags]"
    done
    
    echo
    echo -n "Enter node ID to remove: "
    read -r node_id
    
    if [[ -z "$node_id" ]]; then
        echo "No node ID provided"
        return
    fi
    
    echo
    echo -e "${RED}WARNING: Removing a node is a destructive operation${NC}"
    echo "Make sure to:"
    echo "1. Move slots away from master nodes before removal"
    echo "2. Ensure slaves are properly handled"
    echo
    
    echo "Commands to remove node:"
    echo "1. If master with slots, first move slots:"
    echo "   redis-cli --cluster reshard $REDIS_HOST:$REDIS_PORT"
    echo "2. Remove the node:"
    echo "   redis-cli --cluster del-node $REDIS_HOST:$REDIS_PORT $node_id"
    
    echo
    echo -e "${YELLOW}Note: Execute these commands carefully and ensure data safety${NC}"
}

# Rebalance cluster
rebalance_cluster() {
    echo -e "${YELLOW}Cluster Rebalancing${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        return 1
    fi
    
    echo "Cluster rebalancing will redistribute slots evenly across master nodes."
    echo
    
    # Show current distribution first
    analyze_slot_distribution
    
    echo
    echo -e "${YELLOW}Rebalancing Options:${NC}"
    echo "1) Show rebalance command (manual execution)"
    echo "2) Analyze what would be rebalanced"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r choice
    
    case $choice in
        1)
            echo
            echo "To rebalance the cluster, run:"
            echo "redis-cli --cluster rebalance $REDIS_HOST:$REDIS_PORT"
            echo
            echo "Additional options:"
            echo "--cluster-threshold <arg>    : Threshold for slot migration"
            echo "--cluster-use-empty-masters  : Use empty masters in rebalancing"
            echo "--cluster-simulate          : Show what would be done (dry run)"
            ;;
        2)
            echo
            echo "To see what would be rebalanced (dry run):"
            echo "redis-cli --cluster rebalance $REDIS_HOST:$REDIS_PORT --cluster-simulate"
            ;;
        0)
            return
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    echo
    echo -e "${RED}IMPORTANT:${NC}"
    echo "• Rebalancing moves data between nodes"
    echo "• This can impact performance during the operation"
    echo "• Always test in non-production first"
    echo "• Consider doing this during low-traffic periods"
}

# Cross-node backup
cross_node_backup() {
    echo -e "${YELLOW}Cross-Node Backup${NC}"
    echo "================================"
    
    if ! is_cluster_enabled; then
        echo -e "${RED}✗ Cluster mode not enabled${NC}"
        return 1
    fi
    
    echo "Creating backup across all cluster nodes..."
    echo
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local cluster_backup_dir="$BACKUP_DIR/cluster_backup_$timestamp"
    
    mkdir -p "$cluster_backup_dir"
    
    # Get all cluster nodes
    local cluster_nodes=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes 2>/dev/null)
    
    if [[ -z "$cluster_nodes" ]]; then
        echo -e "${RED}✗ Unable to retrieve cluster nodes${NC}"
        return 1
    fi
    
    local backup_count=0
    local failed_backups=0
    
    echo -e "${CYAN}Backing up individual nodes:${NC}"
    echo "---------------------------"
    
    echo "$cluster_nodes" | grep "master" | while read -r line; do
        local node_addr=$(echo "$line" | awk '{print $2}' | cut -d'@' -f1)
        local node_id=$(echo "$line" | awk '{print $1}')
        local node_host=$(echo "$node_addr" | cut -d: -f1)
        local node_port=$(echo "$node_addr" | cut -d: -f2)
        
        echo -n "Backing up $node_addr... "
        
        # Create backup for this node
        local node_backup_file="$cluster_backup_dir/node_${node_id:0:8}_${node_addr//:/}_backup.rdb"
        
        if redis-cli -h "$node_host" -p "$node_port" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --rdb "$node_backup_file" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Success${NC}"
            backup_count=$((backup_count + 1))
            
            # Get backup size
            local backup_size=$(du -h "$node_backup_file" 2>/dev/null | cut -f1)
            echo "  Size: $backup_size"
        else
            echo -e "${RED}✗ Failed${NC}"
            failed_backups=$((failed_backups + 1))
        fi
    done
    
    # Create cluster metadata
    local metadata_file="$cluster_backup_dir/cluster_metadata.txt"
    cat > "$metadata_file" << EOF
Cluster Backup Metadata
Generated: $(date)
Backup Directory: $cluster_backup_dir

Cluster Information:
$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster info)

Cluster Nodes:
$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} cluster nodes)
EOF
    
    echo
    echo -e "${CYAN}Backup Summary:${NC}"
    echo "--------------"
    echo "Successful backups: $backup_count"
    echo "Failed backups: $failed_backups"
    echo "Backup directory: $cluster_backup_dir"
    echo "Metadata file: $metadata_file"
    
    if [[ $backup_count -gt 0 ]]; then
        echo -e "${GREEN}✓ Cluster backup completed${NC}"
        log "INFO" "Cluster backup completed: $cluster_backup_dir ($backup_count nodes)"
    else
        echo -e "${RED}✗ Cluster backup failed${NC}"
        log "ERROR" "Cluster backup failed: no nodes backed up successfully"
    fi
}
