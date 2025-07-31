# VSCode Agentic Mode Auto-Continue Scripts

This project contains scripts to automatically detect VSCode windows running in agentic mode and send continue commands when they're waiting for confirmation.

## Files

- `vscode-agentic-auto-continue.lua` - Hammerspoon script for continuous monitoring
- `vscode-agentic-auto-continue.applescript` - AppleScript for one-time or scheduled execution
- `vscode-auto-continue.sh` - Shell script wrapper for easy execution

## Installation and Usage

### Option 1: Hammerspoon (Recommended)

Hammerspoon provides the most robust solution with continuous monitoring.

1. **Install Hammerspoon** (if not already installed):
   ```bash
   brew install hammerspoon
   # OR download from https://www.hammerspoon.org/
   ```

2. **Install the script**:
   ```bash
   ./vscode-auto-continue.sh --hammerspoon
   ```

3. **The script will automatically**:
   - Monitor VSCode windows every 30 seconds
   - Look for windows with titles containing: "agentic", "agent", "waiting", "confirm", "continue", "AI", "assistant"
   - Send continue commands when found

4. **Manual controls** (uncomment hotkey bindings in the .lua file):
   - `Ctrl+Alt+Cmd+V` - Trigger check now
   - `Ctrl+Alt+Cmd+S` - Start monitoring
   - `Ctrl+Alt+Cmd+X` - Stop monitoring

### Option 2: AppleScript

For simpler, one-time execution or cron-based scheduling.

1. **Run once**:
   ```bash
   ./vscode-auto-continue.sh
   # OR
   ./vscode-auto-continue.sh --applescript
   ```

2. **Run in watch mode** (checks every 30 seconds):
   ```bash
   ./vscode-auto-continue.sh --watch
   ```

3. **Stop watch mode**:
   ```bash
   ./vscode-auto-continue.sh --stop
   ```

4. **Schedule with cron** (check every 5 minutes):
   ```bash
   crontab -e
   # Add line:
   */5 * * * * /path/to/vscode-auto-continue.sh >/dev/null 2>&1
   ```

## How It Works

### Detection
The scripts look for VSCode windows with titles containing keywords that suggest agentic mode:
- "agentic"
- "agent" 
- "waiting"
- "confirm"
- "continue"
- "AI"
- "assistant"

### Continue Actions
When a matching window is found, the scripts attempt to:

1. **Command Palette Approach**:
   - Press `Cmd+Shift+P` to open command palette
   - Type "continue"
   - Press Enter

2. **Tab Navigation Approach**:
   - Use Tab key to navigate through UI elements
   - Press Enter to activate focused element (hoping it's a Continue button)

### Customization

You can modify the detection patterns by editing the `patterns` array in the Hammerspoon script or `agenticPatterns` in the AppleScript.

## Troubleshooting

### Accessibility Permissions
On macOS, you may need to grant accessibility permissions:

1. Go to **System Preferences > Security & Privacy > Privacy > Accessibility**
2. Add and enable:
   - **Hammerspoon** (for the Lua script)
   - **osascript** or **Terminal** (for AppleScript)

### VSCode-Specific Issues
- Make sure VSCode is actually waiting for confirmation (the scripts work best when there's a clear "Continue" button or command available)
- The detection relies on window titles, so if VSCode doesn't update the title to reflect agentic mode, you may need to adjust the detection patterns

### Testing
Run the script manually first to see if it works:
```bash
./vscode-auto-continue.sh
```

Check the Console app (macOS) for any error messages from the scripts.

## Advanced Usage

### Modify Detection Patterns
Edit the pattern arrays in either script to match your specific VSCode setup:

**Hammerspoon (vscode-agentic-auto-continue.lua)**:
```lua
local patterns = {
    "your_custom_pattern",
    "another_pattern"
}
```

**AppleScript (vscode-agentic-auto-continue.applescript)**:
```applescript
set agenticPatterns to {"your_pattern", "another_pattern"}
```

### Adjust Timing
- Hammerspoon: Modify the timer interval (default 30 seconds)
- AppleScript watch mode: Change the sleep duration in the shell script

## License

Free to use and modify as needed.
# auto-vibe
