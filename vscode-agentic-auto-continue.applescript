-- AppleScript to automatically continue VSCode windows in agentic mode
-- This script looks for VSCode windows and attempts to send continue commands

on findVSCodeWindows()
    set vscodeWindows to {}
    tell application "System Events"
        set allProcesses to every process whose background only is false
        repeat with proc in allProcesses
            if name of proc is "Visual Studio Code" or name of proc is "Code" then
                set procWindows to every window of proc
                repeat with win in procWindows
                    set end of vscodeWindows to {process:proc, window:win}
                end repeat
            end if
        end repeat
    end tell
    return vscodeWindows
end findVSCodeWindows

on isWindowInAgenticMode(windowTitle)
    set agenticPatterns to {"agentic", "agent", "waiting", "confirm", "continue", "AI", "assistant"}
    set lowerTitle to my toLower(windowTitle)
    
    repeat with pattern in agenticPatterns
        if lowerTitle contains pattern then
            return true
        end if
    end repeat
    return false
end isWindowInAgenticMode

on toLower(str)
    set lowerStr to ""
    repeat with char in str
        set charCode to (ASCII number char)
        if charCode >= 65 and charCode <= 90 then
            set lowerStr to lowerStr & (ASCII character (charCode + 32))
        else
            set lowerStr to lowerStr & char
        end if
    end repeat
    return lowerStr
end toLower

on sendContinueCommand(windowInfo)
    set proc to process of windowInfo
    set win to window of windowInfo
    
    tell application "System Events"
        -- Focus the window
        tell proc
            set frontmost to true
            tell win to set index to 1
        end tell
        
        delay 0.2
        
        -- Try Command+Shift+P to open command palette
        key code 35 using {command down, shift down} -- P key
        delay 0.3
        
        -- Type "continue"
        keystroke "continue"
        delay 0.2
        
        -- Press Enter
        key code 36 -- Return key
        
        delay 1
        
        -- Alternative: Try Tab navigation to find continue button
        repeat 5 times
            key code 48 -- Tab key
            delay 0.1
        end repeat
        key code 36 -- Return key
        
    end tell
end sendContinueCommand

on checkAndContinueVSCode()
    set vscodeWindows to my findVSCodeWindows()
    set foundAgenticWindow to false
    
    repeat with windowInfo in vscodeWindows
        tell application "System Events"
            set windowTitle to name of (window of windowInfo)
        end tell
        
        if my isWindowInAgenticMode(windowTitle) then
            set foundAgenticWindow to true
            log "Found VSCode window in potential agentic mode: " & windowTitle
            my sendContinueCommand(windowInfo)
        end if
    end repeat
    
    if foundAgenticWindow then
        display notification "Attempted to continue VSCode agentic mode" with title "VSCode Auto-Continue"
    end if
end checkAndContinueVSCode

-- Main execution
on run
    display notification "Starting VSCode Agentic Auto-Continue monitoring" with title "VSCode Auto-Continue"
    
    -- Run once immediately
    my checkAndContinueVSCode()
    
    return "VSCode Agentic Auto-Continue script executed"
end run

-- For manual execution
my checkAndContinueVSCode()
