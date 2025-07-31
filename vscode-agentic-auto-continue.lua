-- Hammerspoon script to automatically continue VSCode windows in agentic mode
-- This script looks for VSCode windows and sends the "Continue" command when waiting for confirmation

-- Enable AppleScript support for remote testing
hs.allowAppleScript(true)

local function findVSCodeWindows()
    local vscodeWindows = {}
    local allWindows = hs.window.allWindows()
    
    print("=== Scanning all windows ===")
    print("Total windows found: " .. #allWindows)
    
    for _, window in ipairs(allWindows) do
        local app = window:application()
        if app then
            local appName = app:name()
            local windowTitle = window:title() or "No Title"
            local bundleID = app:bundleID() or "No Bundle ID"
            
            print("Window: '" .. windowTitle .. "' | App: '" .. appName .. "' | Bundle: '" .. bundleID .. "'")
            
            -- Check for VSCode by multiple criteria
            local isVSCode = false
            
            -- Check application name
            if appName == "Visual Studio Code" or 
               appName == "Code" or 
               appName == "VSCode" or
               appName == "Code - Insiders" then
                isVSCode = true
                print("  → Matched by app name")
            end
            
            -- Check bundle ID
            if bundleID and (bundleID:find("com.microsoft.VSCode") or 
                           bundleID:find("com.microsoft.VSCodeInsiders") or
                           bundleID:find("vscode")) then
                isVSCode = true
                print("  → Matched by bundle ID")
            end
            
            -- Check window title for VSCode indicators
            if windowTitle:find("Visual Studio Code") or 
               windowTitle:find("VSCode") or
               windowTitle:find("- vscode") then
                isVSCode = true
                print("  → Matched by window title")
            end
            
            if isVSCode then
                table.insert(vscodeWindows, window)
                print("  ✓ Added to VSCode windows list")
            end
        else
            print("Window with no application found")
        end
    end
    
    print("=== Found " .. #vscodeWindows .. " VSCode windows ===")
    return vscodeWindows
end

local function hasAgenticUIElements(window)
    -- Check if the window has UI elements that indicate agentic mode
    -- This looks for actual Continue buttons, not just window titles
    
    local app = window:application()
    if not app then return false end
    
    local axApp = hs.axuielement.applicationElement(app)
    local axWindow = hs.axuielement.windowElement(window)
    
    if not axWindow then return false end
    
    print("  → Checking UI elements for Continue buttons...")
    
    local foundAgenticText = false
    local foundContinueButton = false
    
    -- Function to recursively search for Continue buttons and agentic text
    local function findUIElements(element, depth)
        if not element or depth > 15 then return false end -- Increased depth for deeper search
        
        local role = element:attributeValue("AXRole")
        local title = element:attributeValue("AXTitle") or ""
        local value = element:attributeValue("AXValue") or ""
        local description = element:attributeValue("AXDescription") or ""
        local label = element:attributeValue("AXLabel") or ""
        local help = element:attributeValue("AXHelp") or ""
        
        -- Combine all text fields for searching
        local allText = (title .. " " .. value .. " " .. description .. " " .. label .. " " .. help):lower()
        
        -- Check for Continue button indicators - be more flexible
        if role and (role == "AXButton" or role == "AXGenericElement" or role:find("Button")) then
            if allText:find("continue", 1, true) or
               allText:find("proceed", 1, true) or
               allText:find("accept", 1, true) or
               allText:find("confirm", 1, true) or
               allText:find("apply", 1, true) or
               allText:find("yes", 1, true) or
               allText:find("ok", 1, true) then
                print("    ✓ Found potential Continue button: '" .. allText:sub(1, 100) .. "' (" .. role .. ")")
                foundContinueButton = true
            end
        end
        
        -- Look for any element containing Continue text (even if not a button)
        if allText:find("continue", 1, true) and allText:find("cancel", 1, true) then
            print("    ✓ Found Continue/Cancel UI: '" .. allText:sub(1, 100) .. "'")
            foundContinueButton = true
        end
        
        -- Check for text that indicates waiting state or agentic mode
        if allText:find("waiting", 1, true) or
           allText:find("confirm", 1, true) or
           allText:find("continue", 1, true) or
           allText:find("copilot", 1, true) or
           allText:find("agent", 1, true) or
           allText:find("assistant", 1, true) or
           allText:find("approval", 1, true) or
           allText:find("permission", 1, true) then
            foundAgenticText = true
            print("    → Found agentic text: " .. allText:sub(1, 50) .. "...")
        end
        
        -- Recursively search children
        local children = element:attributeValue("AXChildren") or {}
        for _, child in ipairs(children) do
            findUIElements(child, depth + 1)
        end
        
        return false
    end
    
    -- Search the window for Continue buttons and agentic text
    findUIElements(axWindow, 0)
    
    -- If we found Continue/Cancel pattern or agentic text, consider it agentic mode
    if foundContinueButton then
        print("  ✓ Window has Continue button elements")
        return true
    elseif foundAgenticText then
        print("  ✓ Window has agentic text (likely waiting for user input)")
        return true
    else
        print("  ✗ No agentic UI elements found")
        return false
    end
end

local function isWindowInAgenticMode(window)
    -- Check if the window title contains indicators of agentic mode
    local title = window:title()
    if not title then return false end
    
    -- More specific patterns for agentic mode - these should be more precise
    local patterns = {
        "agentic mode",
        "agentic",
        "agent is waiting",
        "agent waiting", 
        "waiting for confirmation",
        "waiting for user",
        "continue with",
        "confirm and continue",
        "github copilot",
        "copilot is waiting",
        "copilot waiting",
        "assistant is waiting",
        "assistant waiting",
        "ai is waiting",
        "waiting for input",
        "user confirmation",
        "confirm to continue",
        "press continue",
        "click continue"
    }
    
    title = title:lower()
    print("Checking window title: " .. title)
    
    -- First check title patterns
    for _, pattern in ipairs(patterns) do
        if title:find(pattern, 1, true) then -- Use plain text search, not regex
            print("Matched title pattern: " .. pattern)
            return true
        end
    end
    
    -- Additional check: look for common VSCode agentic UI indicators
    if (title:find("continue", 1, true) and (title:find("waiting", 1, true) or title:find("confirm", 1, true))) or
       (title:find("agent", 1, true) and title:find("waiting", 1, true)) or
       (title:find("copilot", 1, true) and (title:find("waiting", 1, true) or title:find("continue", 1, true))) then
        print("Matched title combination pattern")
        return true
    end
    
    print("No agentic mode patterns found in title")
    
    -- If title doesn't match, check UI elements
    print("Checking UI elements for agentic state...")
    if hasAgenticUIElements(window) then
        return true
    end
    
    return false
end

local function sendContinueCommand(window)
    -- Focus the window first and ensure it stays focused
    window:focus()
    hs.timer.usleep(500000) -- Wait 500ms for focus to settle
    
    print("Sending continue command to window: " .. (window:title() or "Unknown"))
    
    -- Make sure the window is still focused
    local focusedWindow = hs.window.focusedWindow()
    if not focusedWindow or focusedWindow ~= window then
        print("  ⚠ Window focus lost, refocusing...")
        window:focus()
        hs.timer.usleep(300000)
    end
    
    -- Approach 1: Look for Continue button and click it directly
    local app = window:application()
    local clickedButton = false
    
    if app then
        local axWindow = hs.axuielement.windowElement(window)
        
        if axWindow then
            -- Function to find and click Continue button - more aggressive search
            local function findAndClickContinueButton(element, depth)
                if not element or depth > 15 then return false end
                
                local role = element:attributeValue("AXRole")
                local title = element:attributeValue("AXTitle") or ""
                local description = element:attributeValue("AXDescription") or ""
                local label = element:attributeValue("AXLabel") or ""
                local value = element:attributeValue("AXValue") or ""
                
                local allText = (title .. " " .. description .. " " .. label .. " " .. value):lower()
                
                -- Check if this is a continue button - be more aggressive
                if (role and (role == "AXButton" or role:find("Button") or role == "AXGenericElement")) and (
                    allText:find("continue", 1, true) or
                    allText:find("proceed", 1, true) or
                    allText:find("accept", 1, true) or
                    allText:find("confirm", 1, true) or
                    allText:find("apply", 1, true) or
                    allText:find("yes", 1, true) or
                    allText:find("ok", 1, true)
                ) then
                    print("  → Attempting to click: '" .. allText:sub(1, 50) .. "' (" .. role .. ")")
                    local success = element:performAction("AXPress")
                    if success then
                        print("  ✓ Successfully clicked Continue element")
                        return true
                    else
                        print("  ⚠ Click failed, trying alternative actions...")
                        -- Try alternative actions
                        element:performAction("AXDecrement") -- Sometimes works for buttons
                        element:performAction("AXIncrement")
                        element:performAction("AXPick")
                    end
                end
                
                -- Recursively search children
                local children = element:attributeValue("AXChildren") or {}
                for _, child in ipairs(children) do
                    if findAndClickContinueButton(child, depth + 1) then
                        return true
                    end
                end
                
                return false
            end
            
            clickedButton = findAndClickContinueButton(axWindow, 0)
            if clickedButton then
                print("Successfully found and clicked Continue button via accessibility")
                return
            else
                print("No accessible Continue button found, trying targeted keyboard/mouse methods")
            end
        end
    end
    
    -- Approach 2: Targeted keyboard shortcuts using application-specific events
    print("Trying keyboard shortcuts targeted to VSCode window...")
    
    -- Ensure window is focused before each keystroke
    window:focus()
    hs.timer.usleep(200000)
    
    -- Use application-specific keystroke sending when possible
    if app then
        -- Try using CGEvent to send keystrokes directly to the application
        local function sendKeyToApp(modifiers, key)
            window:focus()
            hs.timer.usleep(100000)
            
            print("  → Sending " .. table.concat(modifiers, "+") .. (next(modifiers) and "+" or "") .. key .. " to " .. app:name())
            
            -- Create key down and key up events
            local keycode = hs.keycodes.map[key]
            if keycode then
                local keyDownEvent = hs.eventtap.event.newKeyEvent(modifiers, key, true)
                local keyUpEvent = hs.eventtap.event.newKeyEvent(modifiers, key, false)
                
                -- Send to the specific application
                keyDownEvent:setProperty(hs.eventtap.event.properties.eventTargetProcessSerialNumber, app:pid())
                keyUpEvent:setProperty(hs.eventtap.event.properties.eventTargetProcessSerialNumber, app:pid())
                
                keyDownEvent:post()
                hs.timer.usleep(50000)
                keyUpEvent:post()
                hs.timer.usleep(200000)
                return true
            end
            return false
        end
        
        -- Try application-targeted shortcuts
        local appShortcuts = {
            {{"cmd"}, "return"},
            {{"ctrl"}, "return"},
            {{}, "return"},
            {{}, "space"},
            {{}, "y"}
        }
        
        for _, shortcut in ipairs(appShortcuts) do
            if sendKeyToApp(shortcut[1], shortcut[2]) then
                -- Wait and check if window is still in agentic mode
                hs.timer.usleep(500000)
                if not isWindowInAgenticMode(window) then
                    print("  ✓ Shortcut appears to have worked - window no longer in agentic mode")
                    return
                end
            end
        end
    end
    
    -- Approach 3: Mouse click approach in VSCode window coordinates
    print("Trying targeted mouse clicks within VSCode window...")
    local windowFrame = window:frame()
    if windowFrame then
        -- Ensure window is focused
        window:focus()
        hs.timer.usleep(200000)
        
        -- Click in common Continue button areas within the VSCode window
        local clickPositions = {
            {windowFrame.x + windowFrame.w * 0.8, windowFrame.y + windowFrame.h * 0.85}, -- Bottom right area
            {windowFrame.x + windowFrame.w * 0.6, windowFrame.y + windowFrame.h * 0.85}, -- Bottom center-right
            {windowFrame.x + windowFrame.w * 0.5, windowFrame.y + windowFrame.h * 0.9},  -- Bottom center
            {windowFrame.x + windowFrame.w * 0.7, windowFrame.y + windowFrame.h * 0.8},  -- Right side
        }
        
        for i, pos in ipairs(clickPositions) do
            print("  → Clicking position " .. i .. ": (" .. math.floor(pos[1]) .. ", " .. math.floor(pos[2]) .. ")")
            
            -- Move mouse and click
            hs.mouse.setAbsolutePosition({x = pos[1], y = pos[2]})
            hs.timer.usleep(200000)
            hs.eventtap.leftClick({x = pos[1], y = pos[2]})
            hs.timer.usleep(500000)
            
            -- Check if the click worked
            if not isWindowInAgenticMode(window) then
                print("  ✓ Mouse click appears to have worked")
                return
            end
        end
    end
    
    -- Approach 4: VSCode-specific command palette commands
    print("Trying VSCode command palette with specific commands...")
    window:focus()
    hs.timer.usleep(200000)
    
    local commands = {"continue", "accept", "confirm", "approve", "proceed"}
    
    for _, cmd in ipairs(commands) do
        print("  → Trying command: " .. cmd)
        
        -- Open command palette
        hs.eventtap.keyStroke({"cmd", "shift"}, "p")
        hs.timer.usleep(800000) -- Wait longer for command palette
        
        -- Type the command
        hs.eventtap.keyStrokes(cmd)
        hs.timer.usleep(300000)
        
        -- Press Enter
        hs.eventtap.keyStroke({}, "return")
        hs.timer.usleep(500000)
        
        -- Check if it worked
        if not isWindowInAgenticMode(window) then
            print("  ✓ Command '" .. cmd .. "' appears to have worked")
            return
        end
        
        -- Press Escape to close command palette if it didn't work
        hs.eventtap.keyStroke({}, "escape")
        hs.timer.usleep(200000)
    end
    
    print("All targeted continue command attempts completed")
end

local function checkAndContinueVSCode()
    local vscodeWindows = findVSCodeWindows()
    
    print("Found " .. #vscodeWindows .. " VSCode windows")
    
    for _, window in ipairs(vscodeWindows) do
        local title = window:title() or "Unknown"
        print("Checking window: " .. title)
        
        if isWindowInAgenticMode(window) then
            print("Found VSCode window in agentic mode: " .. title)
            sendContinueCommand(window)
            -- Only process one window at a time to avoid conflicts
            break
        end
    end
end

-- Set up a timer to check periodically (every 30 seconds)
local checkTimer = nil

-- Function to start monitoring
local function startMonitoring()
    -- Stop any existing timer first
    if checkTimer then
        checkTimer:stop()
        checkTimer = nil
    end
    
    checkTimer = hs.timer.new(30, checkAndContinueVSCode)
    checkTimer:start()
    print("VSCode Agentic Auto-Continue: Monitoring started")
    hs.notify.new({
        title = "VSCode Auto-Continue",
        informativeText = "Monitoring for VSCode agentic mode windows",
        autoWithdraw = true,
        withdrawAfter = 3
    }):send()
end

-- Function to stop monitoring
local function stopMonitoring()
    if checkTimer then
        checkTimer:stop()
        checkTimer = nil
    end
    print("VSCode Agentic Auto-Continue: Monitoring stopped")
    hs.notify.new({
        title = "VSCode Auto-Continue",
        informativeText = "Monitoring stopped",
        autoWithdraw = true,
        withdrawAfter = 3
    }):send()
end

-- Test function to verify pattern matching
local function testPatterns()
    print("=== Testing Agentic Mode Pattern Detection ===")
    
    local testTitles = {
        "vscode-auto-continue.sh — vibe",
        "GitHub Copilot is waiting for confirmation",
        "Agent is waiting for user input",
        "Continue with agentic mode",
        "Copilot waiting for confirmation", 
        "Assistant is waiting",
        "Waiting for user confirmation",
        "AI is waiting for input",
        "Normal file editing window",
        "Agentic mode - confirm to continue"
    }
    
    for _, testTitle in ipairs(testTitles) do
        print("\nTesting title: '" .. testTitle .. "'")
        
        -- Create a mock window object
        local mockWindow = {
            title = function() return testTitle end
        }
        
        local result = isWindowInAgenticMode(mockWindow)
        print("Result: " .. (result and "MATCH ✓" or "NO MATCH ✗"))
    end
    
    print("\n=== Pattern Test Complete ===")
end

-- Manual trigger function with verbose output
local function triggerNow()
    print("=== VSCode Agentic Auto-Continue: Manual trigger ===")
    checkAndContinueVSCode()
    print("=== Manual trigger complete ===")
end

-- New test function that includes pattern testing
local function triggerTest()
    print("=== VSCode Agentic Auto-Continue: Test Mode ===")
    testPatterns()
    print("\n=== Now checking real windows ===")
    checkAndContinueVSCode()
    print("=== Test complete ===")
end

-- Hotkey bindings (optional - uncomment to use)
-- hs.hotkey.bind({"ctrl", "alt", "cmd"}, "v", triggerNow) -- Ctrl+Alt+Cmd+V to trigger manually
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "t", triggerNow) -- Ctrl+Alt+Cmd+T to test manually  
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "p", triggerTest) -- Ctrl+Alt+Cmd+P to test patterns
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "s", startMonitoring) -- Ctrl+Alt+Cmd+S to start monitoring
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "x", stopMonitoring) -- Ctrl+Alt+Cmd+X to stop monitoring

-- Auto-start monitoring when script loads
startMonitoring()

-- Return module for manual control
return {
    start = startMonitoring,
    stop = stopMonitoring,
    triggerNow = triggerNow,
    triggerTest = triggerTest,
    testPatterns = testPatterns,
    checkAndContinue = checkAndContinueVSCode
}
