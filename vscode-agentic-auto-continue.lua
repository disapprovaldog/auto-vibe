-- Hammerspoon script to automatically continue VSCode windows in agentic mode
-- This script looks for VSCode windows and sends the "Continue" command when waiting for confirmation

local function findVSCodeWindows()
    local vscodeWindows = {}
    local allWindows = hs.window.allWindows()
    
    for _, window in ipairs(allWindows) do
        local app = window:application()
        if app and (app:name() == "Visual Studio Code" or app:name() == "Code") then
            table.insert(vscodeWindows, window)
        end
    end
    
    return vscodeWindows
end

local function isWindowInAgenticMode(window)
    -- Check if the window title contains indicators of agentic mode
    local title = window:title()
    if not title then return false end
    
    -- Common patterns that might indicate agentic mode or waiting state
    local patterns = {
        "agentic",
        "agent",
        "waiting",
        "confirm",
        "continue",
        "AI",
        "assistant"
    }
    
    title = title:lower()
    for _, pattern in ipairs(patterns) do
        if title:find(pattern) then
            return true
        end
    end
    
    return false
end

local function sendContinueCommand(window)
    -- Focus the window first
    window:focus()
    hs.timer.usleep(100000) -- Wait 100ms for focus
    
    -- Try different approaches to send "continue" command
    
    -- Approach 1: Try Command+Shift+P to open command palette and search for continue
    hs.eventtap.keyStroke({"cmd", "shift"}, "p")
    hs.timer.usleep(200000) -- Wait 200ms
    hs.eventtap.keyStrokes("continue")
    hs.timer.usleep(100000)
    hs.eventtap.keyStroke({}, "return")
    
    -- Approach 2: If there's a continue button visible, we could try Tab navigation
    -- This is more speculative but might work in some UI states
    hs.timer.doAfter(1, function()
        -- Try pressing Tab a few times to navigate to continue button, then Enter
        for i = 1, 5 do
            hs.eventtap.keyStroke({}, "tab")
            hs.timer.usleep(50000)
        end
        hs.eventtap.keyStroke({}, "return")
    end)
end

local function checkAndContinueVSCode()
    local vscodeWindows = findVSCodeWindows()
    
    for _, window in ipairs(vscodeWindows) do
        if isWindowInAgenticMode(window) then
            print("Found VSCode window in potential agentic mode: " .. (window:title() or "Unknown"))
            sendContinueCommand(window)
        end
    end
end

-- Set up a timer to check periodically (every 30 seconds)
local checkTimer = hs.timer.new(30, checkAndContinueVSCode)

-- Function to start monitoring
local function startMonitoring()
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
    checkTimer:stop()
    print("VSCode Agentic Auto-Continue: Monitoring stopped")
    hs.notify.new({
        title = "VSCode Auto-Continue",
        informativeText = "Monitoring stopped",
        autoWithdraw = true,
        withdrawAfter = 3
    }):send()
end

-- Manual trigger function
local function triggerNow()
    print("VSCode Agentic Auto-Continue: Manual trigger")
    checkAndContinueVSCode()
end

-- Hotkey bindings (optional - uncomment to use)
-- hs.hotkey.bind({"ctrl", "alt", "cmd"}, "v", triggerNow) -- Ctrl+Alt+Cmd+V to trigger manually
-- hs.hotkey.bind({"ctrl", "alt", "cmd"}, "s", startMonitoring) -- Ctrl+Alt+Cmd+S to start monitoring
-- hs.hotkey.bind({"ctrl", "alt", "cmd"}, "x", stopMonitoring) -- Ctrl+Alt+Cmd+X to stop monitoring

-- Auto-start monitoring when script loads
startMonitoring()

-- Return module for manual control
return {
    start = startMonitoring,
    stop = stopMonitoring,
    triggerNow = triggerNow,
    checkAndContinue = checkAndContinueVSCode
}
