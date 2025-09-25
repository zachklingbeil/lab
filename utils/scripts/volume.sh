#!/bin/bash
# filepath: /home/zk/lab/volume.sh

# Docker Volume Backup/Restore Script
# Usage: ./volume.sh <i|o> <volume_name|all>

set -e

# List of volumes to backup/restore
VOLUMES=(
   "actions"
   "authentik"
   "factory"
   "pgadmin"
   "postgres"
   "redis"
   "registry"    
)

OPERATION=$1
VOLUME_NAME=$2
BACKUP_DIR="$HOME/.config/volume"
TIMESTAMP=$(date -u +%s)

# Function to backup a single volume
backup_volume() {
    local vol_name=$1
    local vol_backup_dir="${BACKUP_DIR}/${vol_name}"
    local backup_file="${vol_backup_dir}/${TIMESTAMP}.tar.gz"
    
    echo "Backing up volume: $vol_name"
    
    # Create volume-specific backup directory
    mkdir -p "$vol_backup_dir"
    
    docker run --rm \
        -v "$vol_name":/data:ro \
        -v "$vol_backup_dir":/backup \
        alpine:latest \
        tar czf "/backup/$(basename "$backup_file")" -C /data .
    
    echo "✓ Backup completed: $(du -h "$backup_file" | cut -f1)"
}

# Function to get latest backup file for a volume
get_latest_backup() {
    local vol_name=$1
    local vol_backup_dir="${BACKUP_DIR}/${vol_name}"
    
    if [ ! -d "$vol_backup_dir" ]; then
        return 1
    fi
    
    ls -t "$vol_backup_dir"/*.tar.gz 2>/dev/null | head -n1
}


# Function to restore a single volume
restore_volume() {
    local vol_name=$1
    local vol_backup_dir="${BACKUP_DIR}/${vol_name}"
    local backup_file=$(get_latest_backup "$vol_name")
    
    if [ -z "$backup_file" ]; then
        echo "⚠ No backup found for volume '$vol_name', skipping..."
        return 1
    fi
    
    echo "Restoring volume: $vol_name"
    echo "From backup: $(basename "$backup_file")"
    
    # Create volume if it doesn't exist
    if ! docker volume inspect "$vol_name" >/dev/null 2>&1; then
        docker volume create "$vol_name"
    fi
    
    # Restore backup using temporary container
    docker run --rm \
        -v "$vol_name":/data \
        -v "$vol_backup_dir":/backup \
        alpine:latest \
        tar xzf "/backup/$(basename "$backup_file")" -C /data
    
    echo "✓ Restore completed: $(basename "$backup_file")"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check arguments
if [ -z "$OPERATION" ] || [ -z "$VOLUME_NAME" ]; then
    echo "Usage: $0 <i|o> <volume_name|all>"
    echo "  i - import/restore volumes"
    echo "  o - output/backup volumes"
    echo ""
    echo "Examples:"
    echo "  $0 o all       # Backup all volumes"
    echo "  $0 o postgres  # Backup postgres volume"
    echo "  $0 i all       # Restore all volumes"
    echo "  $0 i postgres  # Restore postgres volume"
    echo ""
    echo "Available volumes: ${VOLUMES[*]}"
    exit 1
fi

# Export/Backup operation
if [ "$OPERATION" = "o" ]; then
    if [ "$VOLUME_NAME" = "all" ]; then
        echo "Backing up all volumes..."
        for volume in "${VOLUMES[@]}"; do
            if docker volume inspect "$volume" >/dev/null 2>&1; then
                backup_volume "$volume"
            else
                echo "⚠ Volume '$volume' does not exist, skipping..."
            fi
        done
    else
        if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
            backup_volume "$VOLUME_NAME"
        else
            echo "Error: Volume '$VOLUME_NAME' does not exist"
            exit 1
        fi
    fi

# Import/Restore operation
elif [ "$OPERATION" = "i" ]; then
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Error: Backup directory '$BACKUP_DIR' does not exist"
        exit 1
    fi
    
    if [ "$VOLUME_NAME" = "all" ]; then
        echo "Restoring all volumes..."
        for volume in "${VOLUMES[@]}"; do
            restore_volume "$volume"
        done
    else
        restore_volume "$VOLUME_NAME"
    fi

else
    echo "Error: Invalid operation '$OPERATION'. Use 'i' for import or 'o' for output"
    exit 1
fi