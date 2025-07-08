#!/bin/bash

# Redis Helper - Backup & Restore Module
# Licensed under GPLv3

# Backup and restore menu
backup_restore_menu() {
    while true; do
        show_header
        echo -e "${CYAN}┌─ Backup & Restore ──────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC} 1) Create Backup                                           ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 2) List Backups                                            ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 3) Restore from Backup                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 4) Schedule Automatic Backup                               ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 5) Backup Configuration                                    ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 6) Export Data (JSON/CSV)                                  ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 7) Import Data                                             ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 8) Cleanup Old Backups                                     ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} 0) Back to Main Menu                                       ${CYAN}│${NC}"
        echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
        
        echo -n "Select option: "
        read -r choice
        
        case $choice in
            1) create_backup ;;
            2) list_backups ;;
            3) restore_backup ;;
            4) schedule_backup ;;
            5) backup_configuration ;;
            6) export_data ;;
            7) import_data ;;
            8) cleanup_backups ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
        
        [[ $choice != 0 ]] && { echo; read -p "Press Enter to continue..."; }
    done
}

# Create backup
create_backup() {
    echo -e "${YELLOW}Creating Redis Backup${NC}"
    echo "================================"
    
    if ! test_redis_connection; then
        echo -e "${RED}✗ Cannot connect to Redis${NC}"
        return 1
    fi
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="redis_backup_${ENVIRONMENT}_${timestamp}"
    local backup_file="$BACKUP_DIR/${backup_name}.rdb"
    local backup_info="$BACKUP_DIR/${backup_name}.info"
    
    echo "Backup name: $backup_name"
    echo "Backup location: $backup_file"
    echo
    
    # Get Redis info before backup
    local info_server=$(get_redis_info server)
    local info_memory=$(get_redis_info memory)
    local redis_version=$(echo "$info_server" | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
    local used_memory=$(echo "$info_memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local dbsize=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} dbsize 2>/dev/null)
    
    # Create backup info file
    cat > "$backup_info" << EOF
# Redis Backup Information
BACKUP_DATE=$(date '+%Y-%m-%d %H:%M:%S')
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT
REDIS_VERSION=$redis_version
ENVIRONMENT=$ENVIRONMENT
DATABASE_SIZE=$dbsize
MEMORY_USAGE=$used_memory
BACKUP_TYPE=RDB
COMPRESSION=$BACKUP_COMPRESSION
EOF
    
    echo "Creating backup..."
    
    # Method 1: Try BGSAVE (non-blocking)
    echo "Attempting background save..."
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} bgsave 2>/dev/null | grep -q "Background saving started"; then
        echo "Background save initiated..."
        
        # Wait for background save to complete
        local max_wait=300  # 5 minutes
        local wait_time=0
        
        while [[ $wait_time -lt $max_wait ]]; do
            local last_save=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} lastsave 2>/dev/null)
            sleep 2
            local current_save=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} lastsave 2>/dev/null)
            
            if [[ "$current_save" != "$last_save" ]]; then
                echo -e "${GREEN}✓ Background save completed${NC}"
                break
            fi
            
            wait_time=$((wait_time + 2))
            echo -n "."
        done
        
        if [[ $wait_time -ge $max_wait ]]; then
            echo -e "${RED}✗ Background save timeout${NC}"
            return 1
        fi
        
        # Copy the RDB file
        local rdb_dir=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get dir 2>/dev/null | tail -1)
        local rdb_filename=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get dbfilename 2>/dev/null | tail -1)
        local source_rdb="$rdb_dir/$rdb_filename"
        
        if [[ -f "$source_rdb" ]]; then
            cp "$source_rdb" "$backup_file"
            echo -e "${GREEN}✓ RDB file copied${NC}"
        else
            echo -e "${RED}✗ Could not find RDB file at $source_rdb${NC}"
            return 1
        fi
    else
        # Method 2: Use redis-cli --rdb (if available)
        echo "Trying redis-cli --rdb method..."
        if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --rdb "$backup_file" 2>/dev/null; then
            echo -e "${GREEN}✓ Backup created using redis-cli --rdb${NC}"
        else
            echo -e "${RED}✗ Backup failed${NC}"
            return 1
        fi
    fi
    
    # Compress backup if enabled
    if [[ "$BACKUP_COMPRESSION" == "true" ]]; then
        echo "Compressing backup..."
        if command -v gzip >/dev/null 2>&1; then
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
            echo "COMPRESSED=true" >> "$backup_info"
            echo -e "${GREEN}✓ Backup compressed${NC}"
        else
            echo -e "${YELLOW}⚠ gzip not available, backup not compressed${NC}"
        fi
    fi
    
    # Calculate backup size
    local backup_size=$(du -h "$backup_file" 2>/dev/null | cut -f1)
    echo "BACKUP_SIZE=$backup_size" >> "$backup_info"
    
    echo
    echo -e "${GREEN}✓ Backup completed successfully${NC}"
    echo "Backup file: $backup_file"
    echo "Backup size: $backup_size"
    echo "Info file: $backup_info"
    
    log "INFO" "Backup created: $backup_name ($backup_size)"
}

# List backups
list_backups() {
    echo -e "${YELLOW}Available Backups${NC}"
    echo "================================"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        echo "No backups found"
        return
    fi
    
    local backup_count=0
    
    # List all backup info files
    for info_file in "$BACKUP_DIR"/*.info; do
        [[ ! -f "$info_file" ]] && continue
        
        backup_count=$((backup_count + 1))
        local backup_name=$(basename "$info_file" .info)
        
        echo -e "${CYAN}[$backup_count] $backup_name${NC}"
        
        # Read backup info
        if [[ -f "$info_file" ]]; then
            local backup_date=$(grep "BACKUP_DATE=" "$info_file" | cut -d= -f2)
            local environment=$(grep "ENVIRONMENT=" "$info_file" | cut -d= -f2)
            local db_size=$(grep "DATABASE_SIZE=" "$info_file" | cut -d= -f2)
            local backup_size=$(grep "BACKUP_SIZE=" "$info_file" | cut -d= -f2)
            local redis_version=$(grep "REDIS_VERSION=" "$info_file" | cut -d= -f2)
            
            echo "  Date: $backup_date"
            echo "  Environment: $environment"
            echo "  Database Size: $db_size keys"
            echo "  Backup Size: $backup_size"
            echo "  Redis Version: $redis_version"
            
            # Check if backup file exists
            local backup_file="$BACKUP_DIR/${backup_name}.rdb"
            local compressed_file="$BACKUP_DIR/${backup_name}.rdb.gz"
            
            if [[ -f "$backup_file" ]]; then
                echo -e "  Status: ${GREEN}Available${NC}"
            elif [[ -f "$compressed_file" ]]; then
                echo -e "  Status: ${GREEN}Available (compressed)${NC}"
            else
                echo -e "  Status: ${RED}Missing${NC}"
            fi
        fi
        
        echo
    done
    
    if [[ $backup_count -eq 0 ]]; then
        echo "No backup info files found"
    else
        echo "Total backups: $backup_count"
    fi
}

# Restore backup
restore_backup() {
    echo -e "${YELLOW}Restore from Backup${NC}"
    echo "================================"
    
    # List available backups
    list_backups
    
    echo
    echo -n "Enter backup name to restore (without extension): "
    read -r backup_name
    
    if [[ -z "$backup_name" ]]; then
        echo "No backup name provided"
        return
    fi
    
    local backup_file="$BACKUP_DIR/${backup_name}.rdb"
    local compressed_file="$BACKUP_DIR/${backup_name}.rdb.gz"
    local info_file="$BACKUP_DIR/${backup_name}.info"
    
    # Check if backup exists
    if [[ -f "$compressed_file" ]]; then
        backup_file="$compressed_file"
        echo "Found compressed backup: $backup_file"
    elif [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}✗ Backup file not found${NC}"
        return 1
    fi
    
    # Show backup info
    if [[ -f "$info_file" ]]; then
        echo
        echo -e "${CYAN}Backup Information:${NC}"
        cat "$info_file" | grep -E "(BACKUP_DATE|ENVIRONMENT|DATABASE_SIZE|REDIS_VERSION)" | while IFS= read -r line; do
            echo "  $line"
        done
    fi
    
    echo
    echo -e "${RED}WARNING: This will replace all current data in Redis!${NC}"
    echo -n "Are you sure you want to continue? (type 'yes' to confirm): "
    read -r confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo "Restore cancelled"
        return
    fi
    
    echo
    echo "Starting restore process..."
    
    # Method 1: Try to restore using redis-cli if server supports it
    if [[ "$backup_file" == *.gz ]]; then
        echo "Decompressing backup..."
        local temp_file="/tmp/redis_restore_$$.rdb"
        gunzip -c "$backup_file" > "$temp_file"
        backup_file="$temp_file"
    fi
    
    # Get Redis configuration
    local rdb_dir=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get dir 2>/dev/null | tail -1)
    local rdb_filename=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config get dbfilename 2>/dev/null | tail -1)
    local target_rdb="$rdb_dir/$rdb_filename"
    
    echo "Target RDB file: $target_rdb"
    
    # Stop Redis writes
    echo "Stopping Redis writes..."
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} config set save "" 2>/dev/null
    
    # Flush current data
    echo "Flushing current data..."
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} flushall 2>/dev/null
    
    # Copy backup file
    echo "Copying backup file..."
    if cp "$backup_file" "$target_rdb"; then
        echo -e "${GREEN}✓ Backup file copied${NC}"
    else
        echo -e "${RED}✗ Failed to copy backup file${NC}"
        return 1
    fi
    
    # Restart Redis (this step depends on your setup)
    echo
    echo -e "${YELLOW}Note: You may need to restart Redis server to load the restored data${NC}"
    echo "The backup has been copied to the Redis data directory."
    
    # Cleanup temporary file
    [[ -f "/tmp/redis_restore_$$.rdb" ]] && rm "/tmp/redis_restore_$$.rdb"
    
    echo -e "${GREEN}✓ Restore process completed${NC}"
    log "INFO" "Backup restored: $backup_name"
}

# Schedule automatic backup
schedule_backup() {
    echo -e "${YELLOW}Schedule Automatic Backup${NC}"
    echo "================================"
    
    echo "Current backup schedule: $BACKUP_SCHEDULE"
    echo "Auto backup enabled: $AUTO_BACKUP"
    echo
    
    echo "Schedule options:"
    echo "1) Daily at 2 AM (0 2 * * *)"
    echo "2) Every 6 hours (0 */6 * * *)"
    echo "3) Weekly on Sunday at 3 AM (0 3 * * 0)"
    echo "4) Custom cron expression"
    echo "5) Disable automatic backup"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r choice
    
    local new_schedule=""
    case $choice in
        1) new_schedule="0 2 * * *" ;;
        2) new_schedule="0 */6 * * *" ;;
        3) new_schedule="0 3 * * 0" ;;
        4) 
            echo -n "Enter cron expression: "
            read -r new_schedule
            ;;
        5) 
            new_schedule=""
            echo "Automatic backup will be disabled"
            ;;
        0) return ;;
        *) echo "Invalid option"; return ;;
    esac
    
    # Update configuration
    if [[ -n "$new_schedule" ]]; then
        sed -i "s/BACKUP_SCHEDULE=.*/BACKUP_SCHEDULE=\"$new_schedule\"/" "$CONFIG_FILE"
        sed -i "s/AUTO_BACKUP=.*/AUTO_BACKUP=\"true\"/" "$CONFIG_FILE"
        
        # Create cron job
        local cron_command="$SCRIPT_DIR/redis-helper.sh backup-auto"
        local cron_entry="$new_schedule $cron_command"
        
        # Add to crontab
        (crontab -l 2>/dev/null | grep -v "redis-helper.sh backup-auto"; echo "$cron_entry") | crontab -
        
        echo -e "${GREEN}✓ Automatic backup scheduled: $new_schedule${NC}"
        log "INFO" "Backup schedule updated: $new_schedule"
    else
        sed -i "s/AUTO_BACKUP=.*/AUTO_BACKUP=\"false\"/" "$CONFIG_FILE"
        
        # Remove from crontab
        crontab -l 2>/dev/null | grep -v "redis-helper.sh backup-auto" | crontab -
        
        echo -e "${GREEN}✓ Automatic backup disabled${NC}"
        log "INFO" "Automatic backup disabled"
    fi
}

# Backup configuration
backup_configuration() {
    echo -e "${YELLOW}Backup Configuration${NC}"
    echo "================================"
    
    echo "Current settings:"
    echo "  Backup directory: $BACKUP_DIR"
    echo "  Retention days: $BACKUP_RETENTION_DAYS"
    echo "  Compression: $BACKUP_COMPRESSION"
    echo "  Auto backup: $AUTO_BACKUP"
    echo "  Schedule: $BACKUP_SCHEDULE"
    echo
    
    echo "Configuration options:"
    echo "1) Change backup directory"
    echo "2) Change retention period"
    echo "3) Toggle compression"
    echo "4) View backup statistics"
    echo "0) Back"
    
    echo -n "Select option: "
    read -r choice
    
    case $choice in
        1)
            echo -n "Enter new backup directory: "
            read -r new_dir
            if [[ -n "$new_dir" ]]; then
                mkdir -p "$new_dir"
                sed -i "s|BACKUP_DIR=.*|BACKUP_DIR=\"$new_dir\"|" "$CONFIG_FILE"
                BACKUP_DIR="$new_dir"
                echo -e "${GREEN}✓ Backup directory updated${NC}"
            fi
            ;;
        2)
            echo -n "Enter retention period (days): "
            read -r new_retention
            if [[ "$new_retention" =~ ^[0-9]+$ ]]; then
                sed -i "s/BACKUP_RETENTION_DAYS=.*/BACKUP_RETENTION_DAYS=\"$new_retention\"/" "$CONFIG_FILE"
                BACKUP_RETENTION_DAYS="$new_retention"
                echo -e "${GREEN}✓ Retention period updated${NC}"
            fi
            ;;
        3)
            if [[ "$BACKUP_COMPRESSION" == "true" ]]; then
                sed -i "s/BACKUP_COMPRESSION=.*/BACKUP_COMPRESSION=\"false\"/" "$CONFIG_FILE"
                echo -e "${GREEN}✓ Compression disabled${NC}"
            else
                sed -i "s/BACKUP_COMPRESSION=.*/BACKUP_COMPRESSION=\"true\"/" "$CONFIG_FILE"
                echo -e "${GREEN}✓ Compression enabled${NC}"
            fi
            ;;
        4)
            show_backup_statistics
            ;;
    esac
}

# Show backup statistics
show_backup_statistics() {
    echo -e "${YELLOW}Backup Statistics${NC}"
    echo "================================"
    
    local total_backups=0
    local total_size=0
    local oldest_backup=""
    local newest_backup=""
    
    for info_file in "$BACKUP_DIR"/*.info; do
        [[ ! -f "$info_file" ]] && continue
        
        total_backups=$((total_backups + 1))
        
        local backup_date=$(grep "BACKUP_DATE=" "$info_file" | cut -d= -f2)
        local backup_size=$(grep "BACKUP_SIZE=" "$info_file" | cut -d= -f2)
        
        if [[ -z "$oldest_backup" ]] || [[ "$backup_date" < "$oldest_backup" ]]; then
            oldest_backup="$backup_date"
        fi
        
        if [[ -z "$newest_backup" ]] || [[ "$backup_date" > "$newest_backup" ]]; then
            newest_backup="$backup_date"
        fi
    done
    
    # Calculate total directory size
    if [[ -d "$BACKUP_DIR" ]]; then
        local dir_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        echo "Total backups: $total_backups"
        echo "Total size: $dir_size"
        echo "Oldest backup: $oldest_backup"
        echo "Newest backup: $newest_backup"
        echo "Backup directory: $BACKUP_DIR"
    else
        echo "Backup directory not found"
    fi
}

# Export data to JSON/CSV
export_data() {
    echo -e "${YELLOW}Export Redis Data${NC}"
    echo "================================"
    
    echo "Export formats:"
    echo "1) JSON"
    echo "2) CSV"
    echo "3) Redis Protocol (RESP)"
    echo "0) Back"
    
    echo -n "Select format: "
    read -r format_choice
    
    case $format_choice in
        1) export_to_json ;;
        2) export_to_csv ;;
        3) export_to_resp ;;
        0) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Export to JSON
export_to_json() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local export_file="$BACKUP_DIR/redis_export_${timestamp}.json"
    
    echo "Exporting to JSON: $export_file"
    
    echo "{" > "$export_file"
    echo "  \"export_info\": {" >> "$export_file"
    echo "    \"timestamp\": \"$(date)\"," >> "$export_file"
    echo "    \"redis_host\": \"$REDIS_HOST:$REDIS_PORT\"," >> "$export_file"
    echo "    \"environment\": \"$ENVIRONMENT\"" >> "$export_file"
    echo "  }," >> "$export_file"
    echo "  \"data\": {" >> "$export_file"
    
    local first_key=true
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} --scan 2>/dev/null | while read -r key; do
        local key_type=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} type "$key" 2>/dev/null)
        local key_value=""
        
        case "$key_type" in
            "string")
                key_value=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} get "$key" 2>/dev/null)
                ;;
            "list")
                key_value=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} lrange "$key" 0 -1 2>/dev/null)
                ;;
            "set")
                key_value=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} smembers "$key" 2>/dev/null)
                ;;
            "hash")
                key_value=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} hgetall "$key" 2>/dev/null)
                ;;
        esac
        
        if [[ "$first_key" == "false" ]]; then
            echo "," >> "$export_file"
        fi
        
        echo -n "    \"$key\": {\"type\": \"$key_type\", \"value\": \"$key_value\"}" >> "$export_file"
        first_key=false
    done
    
    echo "" >> "$export_file"
    echo "  }" >> "$export_file"
    echo "}" >> "$export_file"
    
    echo -e "${GREEN}✓ Export completed: $export_file${NC}"
}

# Cleanup old backups
cleanup_backups() {
    echo -e "${YELLOW}Cleanup Old Backups${NC}"
    echo "================================"
    
    echo "Retention period: $BACKUP_RETENTION_DAYS days"
    echo
    
    local cutoff_date=$(date -d "$BACKUP_RETENTION_DAYS days ago" '+%Y-%m-%d')
    local deleted_count=0
    local total_size_freed=0
    
    echo "Checking for backups older than $cutoff_date..."
    
    for info_file in "$BACKUP_DIR"/*.info; do
        [[ ! -f "$info_file" ]] && continue
        
        local backup_date=$(grep "BACKUP_DATE=" "$info_file" | cut -d= -f2 | cut -d' ' -f1)
        
        if [[ "$backup_date" < "$cutoff_date" ]]; then
            local backup_name=$(basename "$info_file" .info)
            local backup_file="$BACKUP_DIR/${backup_name}.rdb"
            local compressed_file="$BACKUP_DIR/${backup_name}.rdb.gz"
            
            echo "Deleting old backup: $backup_name ($backup_date)"
            
            # Calculate size before deletion
            local file_size=0
            [[ -f "$backup_file" ]] && file_size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null || echo 0)
            [[ -f "$compressed_file" ]] && file_size=$(stat -f%z "$compressed_file" 2>/dev/null || stat -c%s "$compressed_file" 2>/dev/null || echo 0)
            
            total_size_freed=$((total_size_freed + file_size))
            
            # Delete files
            rm -f "$info_file" "$backup_file" "$compressed_file"
            deleted_count=$((deleted_count + 1))
        fi
    done
    
    if [[ $deleted_count -gt 0 ]]; then
        local size_freed_human=$(numfmt --to=iec $total_size_freed 2>/dev/null || echo "${total_size_freed} bytes")
        echo -e "${GREEN}✓ Cleanup completed${NC}"
        echo "Deleted backups: $deleted_count"
        echo "Space freed: $size_freed_human"
        log "INFO" "Cleanup completed: $deleted_count backups deleted, $size_freed_human freed"
    else
        echo -e "${GREEN}✓ No old backups to cleanup${NC}"
    fi
}
