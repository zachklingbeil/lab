#!/bin/bash
# ~/.lab/utils/scripts/zshrc-sync.sh
# ZSH configuration file synchronization script

# Configuration
REMOTE_USER="zk"
REMOTE_HOST="timefactory"
SCRIPT_NAME="zshrc-sync"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Sync function
sync_file() {
    logger -t "$SCRIPT_NAME" "Syncing .zshrc changes..."
    
    # Check if local file exists
    if [ ! -f "$HOME/.config/zsh/.zshrc" ]; then
        logger -t "$SCRIPT_NAME" "Local .zshrc not found at $HOME/.config/zsh/.zshrc"
        echo -e "${RED}Local .zshrc not found at $HOME/.config/zsh/.zshrc${NC}"
        return 1
    fi
    
    # Create remote directory structure if it doesn't exist
    ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ~/.config/zsh" 2>&1 | logger -t "$SCRIPT_NAME"
    
    # Sync the file
    rsync -avz "$HOME/.config/zsh/.zshrc" "$REMOTE_USER@$REMOTE_HOST:~/.config/zsh/.zshrc" 2>&1 | logger -t "$SCRIPT_NAME"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        logger -t "$SCRIPT_NAME" "Sync completed successfully"
        echo -e "${GREEN}✓ .zshrc synced to $REMOTE_HOST${NC}"
        
        # Optional: reload zsh on remote if session exists
        ssh "$REMOTE_USER@$REMOTE_HOST" "pgrep -x zsh >/dev/null && echo 'ZSH processes found on remote. Run \"source ~/.config/zsh/.zshrc\" to reload.'" 2>/dev/null | logger -t "$SCRIPT_NAME"
    else
        logger -t "$SCRIPT_NAME" "Sync failed"
        echo -e "${RED}✗ Sync failed${NC}"
        return 1
    fi
}

# Get running sync process PID using process list
get_sync_pid() {
    pgrep -f "fswatch.*\.zshrc" | head -1
}

# Start function
start_sync() {
    # Check if local file exists
    if [ ! -f "$HOME/.config/zsh/.zshrc" ]; then
        echo -e "${RED}Local .zshrc not found at $HOME/.config/zsh/.zshrc${NC}"
        echo "Please ensure your .zshrc is located at $HOME/.config/zsh/.zshrc"
        return 1
    fi
    
    PID=$(get_sync_pid)
    if [ -n "$PID" ]; then
        echo -e "${YELLOW}ZSH config sync is already running (PID: $PID)${NC}"
        return 1
    fi

    echo -e "${GREEN}Starting .zshrc sync in background...${NC}"
    logger -t "$SCRIPT_NAME" "Starting zshrc sync"

    # Do initial sync
    echo "Performing initial sync..."
    sync_file

    # Start fswatch in background to watch the specific file
    nohup fswatch -o "$HOME/.config/zsh/.zshrc" | while read event; do
        sync_file
    done >/dev/null 2>&1 &

    # Give it a moment to start
    sleep 1
    
    PID=$(get_sync_pid)
    if [ -n "$PID" ]; then
        echo -e "${GREEN}ZSH config sync started (PID: $PID)${NC}"
        echo "Watching: $HOME/.config/zsh/.zshrc"
        echo "Syncing to: $REMOTE_USER@$REMOTE_HOST:~/.config/zsh/.zshrc"
        echo ""
        echo "View logs: $0 log"
        echo "To stop: $0 stop"
    else
        echo -e "${RED}Failed to start zshrc sync${NC}"
        return 1
    fi
}

# Stop function
stop_sync() {
    PID=$(get_sync_pid)
    
    if [ -z "$PID" ]; then
        echo -e "${YELLOW}No zshrc sync process running${NC}"
        return 1
    fi

    echo -e "${GREEN}Stopping zshrc sync (PID: $PID)${NC}"
    
    # Kill the fswatch process and its children
    pkill -f "fswatch.*\.zshrc"
    
    # Wait a moment and check if it's really stopped
    sleep 1
    PID=$(get_sync_pid)
    
    if [ -z "$PID" ]; then
        logger -t "$SCRIPT_NAME" "ZSH config sync stopped"
        echo -e "${GREEN}ZSH config sync stopped successfully${NC}"
    else
        echo -e "${RED}Failed to stop zshrc sync (PID: $PID still running)${NC}"
        return 1
    fi
}

# Status function
status_sync() {
    PID=$(get_sync_pid)
    
    if [ -n "$PID" ]; then
        echo -e "${GREEN}ZSH config sync is running (PID: $PID)${NC}"
        echo "Watching: $HOME/.config/zsh/.zshrc"
        echo "Syncing to: $REMOTE_USER@$REMOTE_HOST:~/.config/zsh/.zshrc"
        echo ""
        echo "Recent log entries:"
        show_recent_logs 5
    else
        echo -e "${YELLOW}ZSH config sync is not running${NC}"
        if [ -f "$HOME/.config/zsh/.zshrc" ]; then
            echo "Local file: $HOME/.config/zsh/.zshrc ✓"
        else
            echo "Local file: $HOME/.config/zsh/.zshrc ✗"
        fi
    fi
}

# Show recent logs from system log
show_recent_logs() {
    local lines=${1:-20}
    
    # Try different log locations based on OS
    if command -v log >/dev/null 2>&1; then
        # macOS unified logging
        log show --predicate 'senderImagePath contains "logger" and messageText contains "zshrc-sync"' --last 1h --style compact 2>/dev/null | tail -$lines
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
            log stream --predicate 'senderImagePath contains "logger" and messageText contains "zshrc-sync"' --style compact
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
    echo -e "${GREEN}Running manual .zshrc sync...${NC}"
    sync_file
    echo -e "${GREEN}Manual sync completed${NC}"
}

# Pull function - sync from remote to local
pull_config() {
    echo -e "${GREEN}Pulling .zshrc from remote server...${NC}"
    
    # Create local directory structure if it doesn't exist
    mkdir -p "$(dirname "$HOME/.config/zsh/.zshrc")"
    
    # Pull the file from remote
    rsync -avz "$REMOTE_USER@$REMOTE_HOST:~/.config/zsh/.zshrc" "$HOME/.config/zsh/.zshrc" 2>&1 | logger -t "$SCRIPT_NAME"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        logger -t "$SCRIPT_NAME" "Pull completed successfully"
        echo -e "${GREEN}✓ .zshrc pulled from $REMOTE_HOST${NC}"
        echo "Remember to run 'source ~/.config/zsh/.zshrc' or 'zeds' to reload locally"
    else
        logger -t "$SCRIPT_NAME" "Pull failed"
        echo -e "${RED}✗ Pull failed${NC}"
        return 1
    fi
}

# Test connection function
test_connection() {
    echo -e "${GREEN}Testing connection to $REMOTE_HOST...${NC}"
    
    if ssh -o ConnectTimeout=5 "$REMOTE_USER@$REMOTE_HOST" "echo 'Connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✓ SSH connection successful${NC}"
        
        # Test if remote zsh config directory exists
        if ssh "$REMOTE_USER@$REMOTE_HOST" "[ -d ~/.config/zsh ]" 2>/dev/null; then
            echo -e "${GREEN}✓ Remote ~/.config/zsh directory exists${NC}"
        else
            echo -e "${YELLOW}! Remote ~/.config/zsh directory doesn't exist (will be created)${NC}"
        fi
        
        # Test if remote .zshrc exists
        if ssh "$REMOTE_USER@$REMOTE_HOST" "[ -f ~/.config/zsh/.zshrc ]" 2>/dev/null; then
            echo -e "${GREEN}✓ Remote .zshrc exists${NC}"
        else
            echo -e "${YELLOW}! Remote .zshrc doesn't exist (will be created on first sync)${NC}"
        fi
    else
        echo -e "${RED}✗ SSH connection failed${NC}"
        echo "Please check your SSH configuration and ensure you can connect to $REMOTE_USER@$REMOTE_HOST"
        return 1
    fi
}

# Usage function
usage() {
    echo "Usage: $0 {start|stop|status|log|sync|pull|test}"
    echo ""
    echo "Commands:"
    echo "  start   - Start background sync (Mac → Ubuntu)"
    echo "  stop    - Stop background sync"
    echo "  status  - Show sync status"
    echo "  log     - Show recent log entries"
    echo "  log -f  - Follow log stream"
    echo "  sync    - Run manual sync once (Mac → Ubuntu)"
    echo "  pull    - Pull config from remote (Ubuntu → Mac)"
    echo "  test    - Test SSH connection and paths"
    echo ""
    echo "Configuration:"
    echo "  Local:  $HOME/.config/zsh/.zshrc"
    echo "  Remote: $REMOTE_USER@$REMOTE_HOST:~/.config/zsh/.zshrc"
    echo "  Logs go to system log (use 'log' command to view)"
    echo ""
    echo "Note: This syncs FROM Mac TO Ubuntu server automatically."
    echo "Use 'pull' to sync FROM Ubuntu TO Mac manually."
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
    pull)
        pull_config
        ;;
    test)
        test_connection
        ;;
    *)
        usage
        exit 1
        ;;
esac