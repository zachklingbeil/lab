#!/bin/bash
# ~/.lab/utils/scripts/lab-sync.sh
# Lab directory synchronization script

# Configuration
REMOTE_USER="zk"
REMOTE_HOST="timefactory"
SCRIPT_NAME="lab-sync"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Sync function
sync_files() {
    logger -t "$SCRIPT_NAME" "Syncing changes..."
    rsync -avz --delete \
        --exclude='.DS_Store' \
        --exclude='*.swp' \
        --exclude='*.tmp' \
        --exclude='.lab-sync.*' \
        "$HOME/.lab/" \
        "$REMOTE_USER@$REMOTE_HOST:~/.lab" 2>&1 | logger -t "$SCRIPT_NAME"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        logger -t "$SCRIPT_NAME" "Sync completed successfully"
    else
        logger -t "$SCRIPT_NAME" "Sync failed"
    fi
}

# Get running sync process PID using process list
get_sync_pid() {
    pgrep -f "fswatch.*\.lab" | head -1
}

# Start function
start_sync() {
    PID=$(get_sync_pid)
    if [ -n "$PID" ]; then
        echo -e "${YELLOW}Lab sync is already running (PID: $PID)${NC}"
        return 1
    fi

    echo -e "${GREEN}Starting lab directory sync in background...${NC}"
    logger -t "$SCRIPT_NAME" "Starting lab sync"

    # Start fswatch in background
    nohup fswatch -o "$HOME/.lab" | while read event; do
        sync_files
    done >/dev/null 2>&1 &

    # Give it a moment to start
    sleep 1
    
    PID=$(get_sync_pid)
    if [ -n "$PID" ]; then
        echo -e "${GREEN}Lab sync started (PID: $PID)${NC}"
        echo "View logs: $0 log"
        echo "To stop: $0 stop"
    else
        echo -e "${RED}Failed to start lab sync${NC}"
        return 1
    fi
}

# Stop function
stop_sync() {
    PID=$(get_sync_pid)
    
    if [ -z "$PID" ]; then
        echo -e "${YELLOW}No lab sync process running${NC}"
        return 1
    fi

    echo -e "${GREEN}Stopping lab sync (PID: $PID)${NC}"
    
    # Kill the fswatch process and its children
    pkill -f "fswatch.*\.lab"
    
    # Wait a moment and check if it's really stopped
    sleep 1
    PID=$(get_sync_pid)
    
    if [ -z "$PID" ]; then
        logger -t "$SCRIPT_NAME" "Lab sync stopped"
        echo -e "${GREEN}Lab sync stopped successfully${NC}"
    else
        echo -e "${RED}Failed to stop lab sync (PID: $PID still running)${NC}"
        return 1
    fi
}

# Status function
status_sync() {
    PID=$(get_sync_pid)
    
    if [ -n "$PID" ]; then
        echo -e "${GREEN}Lab sync is running (PID: $PID)${NC}"
        echo ""
        echo "Recent log entries:"
        show_recent_logs 5
    else
        echo -e "${YELLOW}Lab sync is not running${NC}"
    fi
}

# Show recent logs from system log
show_recent_logs() {
    local lines=${1:-20}
    
    # Try different log locations based on OS
    if command -v log >/dev/null 2>&1; then
        # macOS unified logging
        log show --predicate 'senderImagePath contains "logger" and messageText contains "lab-sync"' --last 1h --style compact 2>/dev/null | tail -$lines
    elif [ -f /var/log/syslog ]; then
        # Linux syslog
        grep "$SCRIPT_NAME" /var/log/syslog 2>/dev/null | tail -$lines
    elif [ -f /var/log/messages ]; then
        # Alternative Linux log location
        grep "$SCRIPT_NAME" /var/log/messages 2>/dev/null | tail -$lines
    else
        echo -e "${YELLOW}System logs not accessible${NC}"
    fi
}

# Log function
show_log() {
    if [ "$1" = "-f" ]; then
        echo "Following system logs for $SCRIPT_NAME (Ctrl+C to exit):"
        if command -v log >/dev/null 2>&1; then
            # macOS - stream logs
            log stream --predicate 'senderImagePath contains "logger" and messageText contains "lab-sync"' --style compact
        else
            # Linux - tail syslog
            tail -f /var/log/syslog 2>/dev/null | grep --line-buffered "$SCRIPT_NAME" || \
            tail -f /var/log/messages 2>/dev/null | grep --line-buffered "$SCRIPT_NAME" || \
            echo -e "${YELLOW}Cannot follow system logs${NC}"
        fi
    else
        echo "Recent log entries (use -f to follow):"
        show_recent_logs 20
    fi
}

# Manual sync function
manual_sync() {
    echo -e "${GREEN}Running manual sync...${NC}"
    sync_files
    echo -e "${GREEN}Manual sync completed${NC}"
}

# Usage function
usage() {
    echo "Usage: $0 {start|stop|status|log|sync}"
    echo ""
    echo "Commands:"
    echo "  start   - Start background sync"
    echo "  stop    - Stop background sync"
    echo "  status  - Show sync status"
    echo "  log     - Show recent log entries"
    echo "  log -f  - Follow log stream"
    echo "  sync    - Run manual sync once"
    echo ""
    echo "Configuration:"
    echo "  ~/.lab/ syncs to: $REMOTE_USER@$REMOTE_HOST:~/.lab/"
    echo "  Logs go to system log (use 'log' command to view)"
}

# Main logic
case "$1" in
    start)
        start_sync
        ;;
    stop)
        stop_sync
        ;;
    status)
        status_sync
        ;;
    log)
        show_log "$2"
        ;;
    sync)
        manual_sync
        ;;
    *)
        usage
        exit 1
        ;;
esac