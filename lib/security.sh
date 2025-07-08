#!/bin/bash

# Redis Helper - Security & Audit Module v1.1
# Licensed under GPLv3

# Security and audit menu
security_audit_menu() {
    while true; do
        show_header
        echo -e "${CYAN}┌─ Security & Audit ──────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Security Assessment                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) Configuration Security Check                            ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Access Pattern Analysis                                 ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Authentication Audit                                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Network Security Check                                  ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Compliance Report                                       ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 7) Security Recommendations                                ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 8) Audit Log Analysis                                      ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) run_security_assessment ;;
            2) check_configuration_security ;;
            3) analyze_access_patterns ;;
            4) audit_authentication ;;
            5) check_network_security ;;
            6) generate_compliance_report ;;
            7) show_security_recommendations ;;
            8) analyze_audit_logs ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Run comprehensive security assessment
run_security_assessment() {
    echo -e "${YELLOW}Redis Security Assessment${NC}"
    echo "================================"
    
    local security_score=100
    local issues=()
    local warnings=()
    local recommendations=()
    
    echo "Running security checks..."
    echo
    
    # Check 1: Authentication
    echo -e "${CYAN}1. Authentication Security${NC}"
    local auth_info=$(get_redis_info server | grep "auth")
    
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2>/dev/null | grep -q "NOAUTH"; then
        issues+=("No authentication required")
        security_score=$((security_score - 20))
        echo -e "   ${RED}✗ No authentication configured${NC}"
    elif [[ -z "$REDIS_PASSWORD" ]]; then
        warnings+=("Password not configured in helper")
        security_score=$((security_score - 5))
        echo -e "   ${YELLOW}⚠ Password not set in configuration${NC}"
    else
        echo -e "   ${GREEN}✓ Authentication configured${NC}"
    fi
    
    # Check 2: Network binding
    echo -e "${CYAN}2. Network Security${NC}"
    local bind_info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get bind 2>/dev/null)
    
    if echo "$bind_info" | grep -q "0.0.0.0"; then
        issues+=("Redis bound to all interfaces")
        security_score=$((security_score - 15))
        echo -e "   ${RED}✗ Redis bound to all interfaces (0.0.0.0)${NC}"
    elif echo "$bind_info" | grep -q "127.0.0.1"; then
        echo -e "   ${GREEN}✓ Redis bound to localhost${NC}"
    else
        echo -e "   ${YELLOW}⚠ Custom bind configuration${NC}"
    fi
    
    # Check 3: Protected mode
    echo -e "${CYAN}3. Protected Mode${NC}"
    local protected_mode=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get protected-mode 2>/dev/null | tail -1)
    
    if [[ "$protected_mode" == "no" ]]; then
        issues+=("Protected mode disabled")
        security_score=$((security_score - 10))
        echo -e "   ${RED}✗ Protected mode is disabled${NC}"
    else
        echo -e "   ${GREEN}✓ Protected mode enabled${NC}"
    fi
    
    # Check 4: Dangerous commands
    echo -e "${CYAN}4. Dangerous Commands${NC}"
    local dangerous_commands=("FLUSHDB" "FLUSHALL" "KEYS" "CONFIG" "EVAL" "DEBUG")
    local blocked_commands=0
    
    for cmd in "${dangerous_commands[@]}"; do
        local cmd_info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get "rename-command" 2>/dev/null | grep -i "$cmd" || echo "")
        if [[ -n "$cmd_info" ]]; then
            blocked_commands=$((blocked_commands + 1))
        fi
    done
    
    if [[ $blocked_commands -eq 0 ]]; then
        warnings+=("No dangerous commands renamed/disabled")
        security_score=$((security_score - 10))
        echo -e "   ${YELLOW}⚠ No dangerous commands disabled${NC}"
    else
        echo -e "   ${GREEN}✓ $blocked_commands dangerous commands secured${NC}"
    fi
    
    # Check 5: SSL/TLS
    echo -e "${CYAN}5. Encryption${NC}"
    local tls_port=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get tls-port 2>/dev/null | tail -1)
    
    if [[ "$tls_port" == "0" ]] || [[ -z "$tls_port" ]]; then
        warnings+=("TLS not configured")
        security_score=$((security_score - 15))
        echo -e "   ${YELLOW}⚠ TLS/SSL not configured${NC}"
    else
        echo -e "   ${GREEN}✓ TLS configured on port $tls_port${NC}"
    fi
    
    # Check 6: Log level
    echo -e "${CYAN}6. Logging Configuration${NC}"
    local loglevel=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get loglevel 2>/dev/null | tail -1)
    
    if [[ "$loglevel" == "debug" ]]; then
        warnings+=("Debug logging enabled")
        security_score=$((security_score - 5))
        echo -e "   ${YELLOW}⚠ Debug logging enabled${NC}"
    else
        echo -e "   ${GREEN}✓ Appropriate log level: $loglevel${NC}"
    fi
    
    # Display results
    echo
    echo -e "${CYAN}Security Assessment Results:${NC}"
    echo "================================"
    
    # Security score with color coding
    if [[ $security_score -ge 90 ]]; then
        echo -e "Security Score: ${GREEN}$security_score/100 (Excellent)${NC}"
    elif [[ $security_score -ge 70 ]]; then
        echo -e "Security Score: ${YELLOW}$security_score/100 (Good)${NC}"
    elif [[ $security_score -ge 50 ]]; then
        echo -e "Security Score: ${YELLOW}$security_score/100 (Fair)${NC}"
    else
        echo -e "Security Score: ${RED}$security_score/100 (Poor)${NC}"
    fi
    
    # Display issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo
        echo -e "${RED}Critical Issues:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  ${RED}• $issue${NC}"
        done
    fi
    
    # Display warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo
        echo -e "${YELLOW}Warnings:${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}• $warning${NC}"
        done
    fi
    
    # Log assessment
    log "INFO" "Security assessment completed - Score: $security_score/100"
}

# Check configuration security
check_configuration_security() {
    echo -e "${YELLOW}Configuration Security Check${NC}"
    echo "================================"
    
    echo "Analyzing Redis configuration for security issues..."
    echo
    
    # Get all configuration
    local config_output=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get "*" 2>/dev/null)
    
    # Security-relevant configurations
    local security_configs=(
        "requirepass"
        "bind"
        "protected-mode"
        "port"
        "tcp-keepalive"
        "timeout"
        "maxclients"
        "maxmemory"
        "save"
        "appendonly"
        "dir"
        "logfile"
        "loglevel"
    )
    
    echo -e "${CYAN}Security-Relevant Configurations:${NC}"
    echo "--------------------------------"
    
    for config in "${security_configs[@]}"; do
        local value=$(echo "$config_output" | grep -A1 "^$config$" | tail -1)
        
        case "$config" in
            "requirepass")
                if [[ -z "$value" ]] || [[ "$value" == "" ]]; then
                    echo -e "${RED}$config: Not set (CRITICAL)${NC}"
                else
                    echo -e "${GREEN}$config: Configured${NC}"
                fi
                ;;
            "bind")
                if [[ "$value" == "0.0.0.0" ]]; then
                    echo -e "${RED}$config: $value (INSECURE)${NC}"
                else
                    echo -e "${GREEN}$config: $value${NC}"
                fi
                ;;
            "protected-mode")
                if [[ "$value" == "no" ]]; then
                    echo -e "${RED}$config: $value (INSECURE)${NC}"
                else
                    echo -e "${GREEN}$config: $value${NC}"
                fi
                ;;
            "maxclients")
                if [[ "$value" == "0" ]]; then
                    echo -e "${YELLOW}$config: Unlimited (WARNING)${NC}"
                else
                    echo -e "${GREEN}$config: $value${NC}"
                fi
                ;;
            *)
                echo -e "${WHITE}$config: $value${NC}"
                ;;
        esac
    done
    
    # Check for renamed commands
    echo
    echo -e "${CYAN}Command Security:${NC}"
    echo "----------------"
    
    local rename_commands=$(echo "$config_output" | grep -A1 "rename-command" 2>/dev/null || echo "")
    if [[ -n "$rename_commands" ]]; then
        echo -e "${GREEN}✓ Some commands have been renamed/disabled${NC}"
        echo "$rename_commands"
    else
        echo -e "${YELLOW}⚠ No commands renamed or disabled${NC}"
    fi
}

# Analyze access patterns
analyze_access_patterns() {
    echo -e "${YELLOW}Access Pattern Analysis${NC}"
    echo "================================"
    
    echo "Analyzing Redis access patterns for security anomalies..."
    echo
    
    # Get client information
    local clients=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} client list 2>/dev/null)
    
    if [[ -z "$clients" ]]; then
        echo "No client information available"
        return
    fi
    
    # Analyze client connections
    echo -e "${CYAN}Client Connection Analysis:${NC}"
    echo "-------------------------"
    
    local total_clients=$(echo "$clients" | wc -l)
    local unique_ips=$(echo "$clients" | grep -o 'addr=[^:]*' | sort | uniq | wc -l)
    local idle_clients=$(echo "$clients" | grep -o 'idle=[0-9]*' | awk -F= '{sum+=$2} END {print sum/NR}')
    
    echo "Total active clients: $total_clients"
    echo "Unique IP addresses: $unique_ips"
    echo "Average idle time: ${idle_clients:-0} seconds"
    
    # Check for suspicious patterns
    echo
    echo -e "${CYAN}Suspicious Pattern Detection:${NC}"
    echo "----------------------------"
    
    # High connection count from single IP
    local ip_connections=$(echo "$clients" | grep -o 'addr=[^:]*' | sort | uniq -c | sort -nr)
    local max_connections=$(echo "$ip_connections" | head -1 | awk '{print $1}')
    
    if [[ $max_connections -gt 10 ]]; then
        echo -e "${RED}⚠ High connection count from single IP: $max_connections${NC}"
        echo "$ip_connections" | head -5
    else
        echo -e "${GREEN}✓ Normal connection distribution${NC}"
    fi
    
    # Long-running idle connections
    local long_idle=$(echo "$clients" | awk '/idle=[0-9]+/ {match($0, /idle=([0-9]+)/, arr); if(arr[1] > 3600) print}')
    if [[ -n "$long_idle" ]]; then
        echo -e "${YELLOW}⚠ Long-running idle connections detected${NC}"
        echo "$long_idle" | head -3
    else
        echo -e "${GREEN}✓ No long-running idle connections${NC}"
    fi
    
    # Command pattern analysis
    echo
    echo -e "${CYAN}Command Pattern Analysis:${NC}"
    echo "------------------------"
    
    # Get command statistics
    local cmd_stats=$(get_redis_info commandstats)
    if [[ -n "$cmd_stats" ]]; then
        echo "Most used commands:"
        echo "$cmd_stats" | grep "cmdstat_" | \
        sed 's/cmdstat_\([^:]*\):calls=\([^,]*\).*/\2 \1/' | \
        sort -nr | head -5 | \
        while read -r calls cmd; do
            echo "  $cmd: $calls calls"
        done
    else
        echo "Command statistics not available"
    fi
}

# Audit authentication
audit_authentication() {
    echo -e "${YELLOW}Authentication Audit${NC}"
    echo "================================"
    
    echo "Auditing Redis authentication configuration..."
    echo
    
    # Check authentication requirement
    echo -e "${CYAN}Authentication Status:${NC}"
    echo "---------------------"
    
    # Test connection without password
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2>/dev/null | grep -q "PONG"; then
        echo -e "${RED}✗ CRITICAL: No authentication required${NC}"
        echo -e "${RED}  Anyone can connect to Redis without credentials${NC}"
        
        # Test some commands
        echo
        echo -e "${CYAN}Testing unauthorized access:${NC}"
        local info_result=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" info server 2>/dev/null | head -3)
        if [[ -n "$info_result" ]]; then
            echo -e "${RED}✗ Can execute INFO command without auth${NC}"
        fi
        
        local keys_result=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" keys "*" 2>/dev/null | head -3)
        if [[ -n "$keys_result" ]]; then
            echo -e "${RED}✗ Can execute KEYS command without auth${NC}"
        fi
        
    else
        echo -e "${GREEN}✓ Authentication required${NC}"
        
        # Test with configured password
        if [[ -n "$REDIS_PASSWORD" ]]; then
            if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
                echo -e "${GREEN}✓ Configured password works${NC}"
            else
                echo -e "${RED}✗ Configured password is incorrect${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ No password configured in helper${NC}"
        fi
    fi
    
    # Check password strength (if we can access it)
    echo
    echo -e "${CYAN}Password Security:${NC}"
    echo "-----------------"
    
    local requirepass=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get requirepass 2>/dev/null | tail -1)
    
    if [[ -n "$requirepass" ]] && [[ "$requirepass" != "" ]]; then
        local pass_length=${#requirepass}
        
        if [[ $pass_length -lt 8 ]]; then
            echo -e "${RED}✗ Password too short ($pass_length characters)${NC}"
        elif [[ $pass_length -lt 12 ]]; then
            echo -e "${YELLOW}⚠ Password could be longer ($pass_length characters)${NC}"
        else
            echo -e "${GREEN}✓ Password length adequate ($pass_length characters)${NC}"
        fi
        
        # Basic password complexity check
        if [[ "$requirepass" =~ [0-9] ]] && [[ "$requirepass" =~ [a-zA-Z] ]]; then
            echo -e "${GREEN}✓ Password contains letters and numbers${NC}"
        else
            echo -e "${YELLOW}⚠ Password should contain letters and numbers${NC}"
        fi
        
    else
        echo -e "${RED}✗ No password set${NC}"
    fi
    
    # Check for default passwords
    echo
    echo -e "${CYAN}Default Password Check:${NC}"
    echo "----------------------"
    
    local common_passwords=("password" "123456" "redis" "admin" "root" "test")
    local weak_password_found=false
    
    for weak_pass in "${common_passwords[@]}"; do
        if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$weak_pass" ping 2>/dev/null | grep -q "PONG"; then
            echo -e "${RED}✗ CRITICAL: Weak password detected: $weak_pass${NC}"
            weak_password_found=true
        fi
    done
    
    if [[ "$weak_password_found" == "false" ]]; then
        echo -e "${GREEN}✓ No common weak passwords detected${NC}"
    fi
}
# Check network security
check_network_security() {
    echo -e "${YELLOW}Network Security Check${NC}"
    echo "================================"
    
    echo "Analyzing network security configuration..."
    echo
    
    # Check binding configuration
    echo -e "${CYAN}Network Binding:${NC}"
    echo "---------------"
    
    local bind_config=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get bind 2>/dev/null)
    local bind_value=$(echo "$bind_config" | tail -1)
    
    if [[ "$bind_value" == "0.0.0.0" ]]; then
        echo -e "${RED}✗ CRITICAL: Redis bound to all interfaces${NC}"
        echo -e "${RED}  This allows connections from any network${NC}"
    elif [[ "$bind_value" == "127.0.0.1" ]]; then
        echo -e "${GREEN}✓ Redis bound to localhost only${NC}"
    elif [[ -n "$bind_value" ]]; then
        echo -e "${YELLOW}⚠ Redis bound to: $bind_value${NC}"
        echo -e "${YELLOW}  Verify this is the intended interface${NC}"
    else
        echo -e "${YELLOW}⚠ No explicit bind configuration${NC}"
    fi
    
    # Check port configuration
    echo
    echo -e "${CYAN}Port Configuration:${NC}"
    echo "------------------"
    
    local port=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get port 2>/dev/null | tail -1)
    
    if [[ "$port" == "6379" ]]; then
        echo -e "${YELLOW}⚠ Using default Redis port (6379)${NC}"
        echo -e "${YELLOW}  Consider using a non-standard port${NC}"
    else
        echo -e "${GREEN}✓ Using non-default port: $port${NC}"
    fi
    
    # Check TLS configuration
    echo
    echo -e "${CYAN}TLS/SSL Configuration:${NC}"
    echo "---------------------"
    
    local tls_port=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get tls-port 2>/dev/null | tail -1)
    local tls_cert=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get tls-cert-file 2>/dev/null | tail -1)
    
    if [[ "$tls_port" != "0" ]] && [[ -n "$tls_port" ]]; then
        echo -e "${GREEN}✓ TLS enabled on port: $tls_port${NC}"
        
        if [[ -n "$tls_cert" ]] && [[ "$tls_cert" != "" ]]; then
            echo -e "${GREEN}✓ TLS certificate configured: $tls_cert${NC}"
        else
            echo -e "${YELLOW}⚠ TLS enabled but no certificate file configured${NC}"
        fi
    else
        echo -e "${RED}✗ TLS/SSL not configured${NC}"
        echo -e "${RED}  Data transmitted in plain text${NC}"
    fi
    
    # Network connectivity test
    echo
    echo -e "${CYAN}Network Connectivity Test:${NC}"
    echo "-------------------------"
    
    # Test connection timeout
    local start_time=$(date +%s%N)
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} ping >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local latency=$(( (end_time - start_time) / 1000000 ))
    
    echo "Connection latency: ${latency}ms"
    
    if [[ $latency -gt 1000 ]]; then
        echo -e "${RED}✗ High latency detected (>1000ms)${NC}"
    elif [[ $latency -gt 100 ]]; then
        echo -e "${YELLOW}⚠ Moderate latency (>100ms)${NC}"
    else
        echo -e "${GREEN}✓ Low latency${NC}"
    fi
    
    # Check timeout configuration
    local timeout=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get timeout 2>/dev/null | tail -1)
    
    if [[ "$timeout" == "0" ]]; then
        echo -e "${YELLOW}⚠ No client timeout configured${NC}"
        echo -e "${YELLOW}  Idle connections will persist indefinitely${NC}"
    else
        echo -e "${GREEN}✓ Client timeout: ${timeout}s${NC}"
    fi
}

# Generate compliance report
generate_compliance_report() {
    echo -e "${YELLOW}Compliance Report Generation${NC}"
    echo "================================"
    
    local report_file="$METRICS_DIR/compliance_report_$(date +%Y%m%d_%H%M%S).txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "Generating compliance report..."
    echo "Report will be saved to: $report_file"
    echo
    
    # Create report header
    cat > "$report_file" << EOF
Redis Security Compliance Report
Generated: $timestamp
Redis Host: $REDIS_HOST:$REDIS_PORT
Environment: $ENVIRONMENT

================================
EXECUTIVE SUMMARY
================================

EOF
    
    # Run security checks and capture results
    local security_score=100
    local critical_issues=0
    local warnings=0
    
    echo "Collecting security data..."
    
    # Authentication check
    echo "Authentication and Access Control:" >> "$report_file"
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2>/dev/null | grep -q "NOAUTH"; then
        echo "  ✗ FAIL: No authentication required" >> "$report_file"
        critical_issues=$((critical_issues + 1))
        security_score=$((security_score - 20))
    else
        echo "  ✓ PASS: Authentication required" >> "$report_file"
    fi
    
    # Network security
    echo "" >> "$report_file"
    echo "Network Security:" >> "$report_file"
    local bind_info=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get bind 2>/dev/null | tail -1)
    
    if [[ "$bind_info" == "0.0.0.0" ]]; then
        echo "  ✗ FAIL: Bound to all interfaces" >> "$report_file"
        critical_issues=$((critical_issues + 1))
        security_score=$((security_score - 15))
    else
        echo "  ✓ PASS: Restricted network binding" >> "$report_file"
    fi
    
    # Protected mode
    local protected_mode=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get protected-mode 2>/dev/null | tail -1)
    if [[ "$protected_mode" == "no" ]]; then
        echo "  ✗ FAIL: Protected mode disabled" >> "$report_file"
        critical_issues=$((critical_issues + 1))
        security_score=$((security_score - 10))
    else
        echo "  ✓ PASS: Protected mode enabled" >> "$report_file"
    fi
    
    # Add summary
    cat >> "$report_file" << EOF

================================
COMPLIANCE SUMMARY
================================

Security Score: $security_score/100
Critical Issues: $critical_issues
Warnings: $warnings

Compliance Status: $(if [[ $security_score -ge 80 ]]; then echo "COMPLIANT"; else echo "NON-COMPLIANT"; fi)

EOF
    
    echo -e "${GREEN}✓ Compliance report generated: $report_file${NC}"
    log "INFO" "Compliance report generated: $report_file (Score: $security_score/100)"
}

# Show security recommendations
show_security_recommendations() {
    echo -e "${YELLOW}Security Recommendations${NC}"
    echo "================================"
    
    echo "Based on Redis security best practices:"
    echo
    
    echo -e "${CYAN}1. Authentication & Authorization${NC}"
    echo "   • Set a strong password: CONFIG SET requirepass 'your-strong-password'"
    echo "   • Use ACLs for fine-grained access control (Redis 6+)"
    echo "   • Rotate passwords regularly"
    
    echo
    echo -e "${CYAN}2. Network Security${NC}"
    echo "   • Bind to specific interfaces: CONFIG SET bind '127.0.0.1'"
    echo "   • Enable TLS/SSL for encrypted connections"
    echo "   • Use firewall rules to restrict access"
    echo "   • Change default port (6379) if possible"
    
    echo
    echo -e "${CYAN}3. Command Security${NC}"
    echo "   • Rename dangerous commands:"
    echo "     - CONFIG SET rename-command FLUSHDB ''"
    echo "     - CONFIG SET rename-command FLUSHALL ''"
    echo "     - CONFIG SET rename-command CONFIG 'CONFIG_9a8b7c6d'"
    
    echo
    echo -e "${CYAN}4. Data Protection${NC}"
    echo "   • Enable persistence with appropriate permissions"
    echo "   • Encrypt sensitive data at application level"
    echo "   • Regular backups with encryption"
    
    echo
    echo -e "${CYAN}5. Monitoring & Auditing${NC}"
    echo "   • Enable logging: CONFIG SET loglevel notice"
    echo "   • Monitor failed authentication attempts"
    echo "   • Set up alerts for suspicious activities"
}

# Analyze audit logs
analyze_audit_logs() {
    echo -e "${YELLOW}Audit Log Analysis${NC}"
    echo "================================"
    
    echo "Analyzing Redis and system logs for security events..."
    echo
    
    # Check Redis log file location
    local logfile=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get logfile 2>/dev/null | tail -1)
    
    echo -e "${CYAN}Log Configuration:${NC}"
    echo "------------------"
    
    if [[ -n "$logfile" ]] && [[ "$logfile" != "" ]]; then
        echo "Redis log file: $logfile"
        
        if [[ -f "$logfile" ]] && [[ -r "$logfile" ]]; then
            echo -e "${GREEN}✓ Log file accessible${NC}"
            
            # Analyze recent log entries
            echo
            echo -e "${CYAN}Recent Log Analysis:${NC}"
            echo "-------------------"
            
            local log_lines=$(tail -100 "$logfile" 2>/dev/null)
            
            # Look for authentication failures
            local auth_failures=$(echo "$log_lines" | grep -i "auth\|password\|denied" | wc -l)
            if [[ $auth_failures -gt 0 ]]; then
                echo -e "${RED}⚠ Authentication-related events: $auth_failures${NC}"
            else
                echo -e "${GREEN}✓ No authentication failures in recent logs${NC}"
            fi
            
        else
            echo -e "${RED}✗ Cannot access log file${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No log file configured${NC}"
    fi
    
    # Analyze our own helper logs
    echo
    echo -e "${CYAN}Redis Helper Log Analysis:${NC}"
    echo "-------------------------"
    
    if [[ -f "$LOG_FILE" ]]; then
        local helper_logs=$(tail -20 "$LOG_FILE")
        
        # Count different log levels
        local errors=$(echo "$helper_logs" | grep "\[ERROR\]" | wc -l)
        local warnings=$(echo "$helper_logs" | grep "\[WARN\]" | wc -l)
        local info=$(echo "$helper_logs" | grep "\[INFO\]" | wc -l)
        
        echo "Recent Redis Helper activity:"
        echo "  Errors: $errors"
        echo "  Warnings: $warnings"
        echo "  Info: $info"
        
    else
        echo "No Redis Helper logs found"
    fi
}
