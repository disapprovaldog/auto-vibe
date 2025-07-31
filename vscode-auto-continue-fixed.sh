#!/bin/bash

# VSCode Agentic Auto-Continue Shell Script Wrapper
# This script provides easy ways to run the automation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLESCRIPT_FILE="$SCRIPT_DIR/vscode-agentic-auto-continue.applescript"
HAMMERSPOON_FILE="$SCRIPT_DIR/vscode-agentic-auto-continue.lua"

show_help() {
    echo "VSCode Agentic Auto-Continue Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -a, --applescript    Run the AppleScript version once"
    echo "  -h, --hammerspoon    Install/reload Hammerspoon script"
    echo "  -r, --run            Run AppleScript version once (default)"
    echo "  -w, --watch          Run AppleScript in watch mode (every 30 seconds)"
    echo "  -s, --stop           Stop any running watch processes"
    echo "  --reload-hs          Force reload Hammerspoon configuration"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                   # Run once with AppleScript"
    echo "  $0 -w                # Start watching mode"
    echo "  $0 -h                # Install Hammerspoon script"
    echo "  $0 --reload-hs       # Force reload Hammerspoon"
}

run_applescript_once() {
    echo "Running AppleScript version once..."
    osascript "$APPLESCRIPT_FILE"
}

install_hammerspoon() {
    local hammerspoon_config_dir="$HOME/.hammerspoon"
    
    if [ ! -d "$hammerspoon_config_dir" ]; then
        echo "Hammerspoon config directory not found. Please install Hammerspoon first."
        echo "Download from: https://www.hammerspoon.org/"
        exit 1
    fi
    
    echo "Installing Hammerspoon script..."
    cp "$HAMMERSPOON_FILE" "$hammerspoon_config_dir/"
    
    # Add to init.lua if it exists
    local init_file="$hammerspoon_config_dir/init.lua"
    local require_line="require('vscode-agentic-auto-continue')"
    
    if [ -f "$init_file" ]; then
        if ! grep -q "vscode-agentic-auto-continue" "$init_file"; then
            echo "$require_line" >> "$init_file"
            echo "Added script to existing init.lua"
        else
            echo "Script already exists in init.lua"
        fi
    else
        echo "$require_line" > "$init_file"
        echo "Created new init.lua with script"
    fi
    
    echo "Reloading Hammerspoon configuration..."
    if osascript -e 'tell application "Hammerspoon" to reload()' 2>/dev/null; then
        echo "Hammerspoon script installed and loaded!"
    else
        echo "Warning: Hammerspoon reload failed. You may need to manually restart Hammerspoon."
        echo "You can also try opening Hammerspoon and clicking 'Reload Config' from the menu."
        echo "Or restart Hammerspoon completely with: $0 --reload-hs"
    fi
}

reload_hammerspoon() {
    echo "Force reloading Hammerspoon configuration..."
    # Try to reload
    if osascript -e 'tell application "Hammerspoon" to reload()' 2>/dev/null; then
        echo "Hammerspoon reloaded successfully!"
    else
        echo "Direct reload failed. Trying alternative method..."
        # Try to restart Hammerspoon entirely
        osascript -e 'tell application "Hammerspoon" to quit'
        sleep 2
        open -a Hammerspoon
        echo "Hammerspoon restarted. The script should be loaded automatically."
    fi
}

run_watch_mode() {
    echo "Starting watch mode (checking every 30 seconds)..."
    echo "Press Ctrl+C to stop"
    
    # Create a PID file to track the watch process
    local pid_file="/tmp/vscode-agentic-watch.pid"
    echo $$ > "$pid_file"
    
    # Trap to clean up on exit
    trap 'rm -f "$pid_file"; echo "Watch mode stopped."; exit 0' INT TERM
    
    while true; do
        osascript "$APPLESCRIPT_FILE" > /dev/null 2>&1
        sleep 30
    done
}

stop_watch_mode() {
    local pid_file="/tmp/vscode-agentic-watch.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$pid_file"
            echo "Stopped watch mode (PID: $pid)"
        else
            rm -f "$pid_file"
            echo "No active watch mode found"
        fi
    else
        echo "No watch mode PID file found"
    fi
    
    # Also try to kill any running instances
    pkill -f "vscode-agentic-auto-continue.applescript" && echo "Killed running AppleScript instances"
}

# Parse command line arguments
case "${1:-}" in
    -a|--applescript|-r|--run)
        run_applescript_once
        ;;
    -h|--hammerspoon)
        install_hammerspoon
        ;;
    -w|--watch)
        run_watch_mode
        ;;
    -s|--stop)
        stop_watch_mode
        ;;
    --reload-hs)
        reload_hammerspoon
        ;;
    --help)
        show_help
        ;;
    "")
        # Default action
        run_applescript_once
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
