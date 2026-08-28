--[[
    MM2 Trade Value Display - GODLIES ONLY
    Fetches from supremevalues.com
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local UPDATE_INTERVAL = 300 -- 5 minutes
local API_URL = "https://supremevalues.com/api/mm2/godlies"

-- State
local godlyValues = {}
local isEnabled = false
local lastUpdate = 0
local displayObjects = {}
local updateCounter = 0

--[[ FETCH GODLY VALUES FROM API ]]

local function fetchGodlyValues()
    local success, data = pcall(function()
        return HttpService:GetAsync(API_URL)
    end)
    
    if success and data then
        local decoded = HttpService:JSONDecode(data)
        if decoded then
            godlyValues = {}
            for itemName, value in pairs(decoded) do
                if type(value) == "number" then
                    godlyValues[itemName:lower()] = value
                end
            end
            lastUpdate = tick()
            print("✅ Loaded " .. #godlyValues .. " godly values from API")
            return true
        end
    end
    
    print("❌ Failed to fetch from API")
    return false
end

--[[ VALUE HELPERS ]]

local function formatValue(value)
    if value >= 1000 then
        return string.format("%.1fk", value/1000)
    end
    return tostring(math.floor(value))
end

local function getGodlyValue(itemName)
    if not itemName then return nil end
    local clean = itemName:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return godlyValues[clean]
end

--[[ SCAN FOR TRADE ITEMS ]]

local function findTradeItems()
    local items = {}
    local screens = playerGui:GetChildren()
    
    for _, screen in pairs(screens) do
        if screen:IsA("ScreenGui") then
            local allObjects = screen:GetDescendants()
            for _, obj in pairs(allObjects) do
                if obj:IsA("Frame") or obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
                    local objName = obj.Name:lower()
                    if objName:find("slot") or objName:find("item") or objName:find("trade") then
                        for _, child in pairs(obj:GetChildren()) do
                            if child:IsA("TextLabel") and child.Text ~= "" and #child.Text > 2 then
                                local text = child.Text:gsub("^%s+", ""):gsub("%s+$", "")
                                if getGodlyValue(text) then
                                    table.insert(items, {
                                        frame = obj,
                                        name = text,
                                        label = child
                                    })
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return items
end

--[[ UPDATE DISPLAY ]]

local function updateTradeDisplay()
    if not isEnabled then return end
    
    -- Clear old displays
    for _, obj in pairs(displayObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    displayObjects = {}
    
    local items = findTradeItems()
    if #items == 0 then return end
    
    -- Show values on each item
    for _, item in pairs(items) do
        local value = getGodlyValue(item.name)
        if value then
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Name = "GodlyValue"
            valueLabel.Size = UDim2.new(1, 0, 0, 20)
            valueLabel.Position = UDim2.new(0, 0, 1.2, 0)
            valueLabel.BackgroundTransparency = 0.6
            valueLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            valueLabel.Text = "⭐ " .. formatValue(value)
            valueLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            valueLabel.TextScaled = true
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextStrokeTransparency = 0.3
            valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            valueLabel.ZIndex = 999
            valueLabel.Parent = item.frame
            
            table.insert(displayObjects, valueLabel)
        end
    end
    
    -- Calculate totals
    if #items >= 2 then
        local myTotal = 0
        local theirTotal = 0
        
        for _, item in pairs(items) do
            local value = getGodlyValue(item.name) or 0
            local pos = item.frame.AbsolutePosition.X
            
            if pos < 500 then
                myTotal = myTotal + value
            else
                theirTotal = theirTotal + value
            end
        end
        
        -- Create totals display
        local totalFrame = Instance.new("Frame")
        totalFrame.Name = "TradeTotals"
        totalFrame.Size = UDim2.new(0.4, 0, 0, 80)
        totalFrame.Position = UDim2.new(0.3, 0, 0.75, 0)
        totalFrame.BackgroundTransparency = 0.4
        totalFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        totalFrame.ZIndex = 1000
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = totalFrame
        
        totalFrame.Parent = playerGui:FindFirstChild("ScreenGui") or playerGui
        
        -- My total
        local myLabel = Instance.new("TextLabel")
        myLabel.Size = UDim2.new(1, 0, 0.33, 0)
        myLabel.Position = UDim2.new(0, 0, 0, 0)
        myLabel.BackgroundTransparency = 1
        myLabel.Text = "👤 You: " .. formatValue(myTotal)
        myLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        myLabel.TextScaled = true
        myLabel.Font = Enum.Font.GothamBold
        myLabel.ZIndex = 1001
        myLabel.Parent = totalFrame
        
        -- Their total
        local theirLabel = Instance.new("TextLabel")
        theirLabel.Size = UDim2.new(1, 0, 0.33, 0)
        theirLabel.Position = UDim2.new(0, 0, 0.33, 0)
        theirLabel.BackgroundTransparency = 1
        theirLabel.Text = "👤 Them: " .. formatValue(theirTotal)
        theirLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        theirLabel.TextScaled = true
        theirLabel.Font = Enum.Font.GothamBold
        theirLabel.ZIndex = 1001
        theirLabel.Parent = totalFrame
        
        -- Difference
        local diff = myTotal - theirTotal
        local diffLabel = Instance.new("TextLabel")
        diffLabel.Size = UDim2.new(1, 0, 0.33, 0)
        diffLabel.Position = UDim2.new(0, 0, 0.66, 0)
        diffLabel.BackgroundTransparency = 1
        if diff > 0 then
            diffLabel.Text = "👍 +" .. formatValue(diff)
            diffLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif diff < 0 then
            diffLabel.Text = "👎 " .. formatValue(math.abs(diff))
            diffLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        else
            diffLabel.Text = "⚖️ Fair Trade"
            diffLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
        diffLabel.TextScaled = true
        diffLabel.Font = Enum.Font.GothamBold
        diffLabel.ZIndex = 1001
        diffLabel.Parent = totalFrame
        
        table.insert(displayObjects, totalFrame)
    end
end

--[[ CREATE MAIN GUI ]]

local function createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MM2Values"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 170, 0, 130)
    mainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "⭐ GODLY VALUES"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.85, 0, 0, 35)
    toggleBtn.Position = UDim2.new(0.075, 0, 0.25, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleBtn.Text = "🔴 OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = toggleBtn
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 18)
    status.Position = UDim2.new(0, 0, 0.55, 0)
    status.BackgroundTransparency = 1
    status.Text = "⏳ Loading..."
    status.TextColor3 = Color3.fromRGB(150, 150, 200)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.Parent = mainFrame
    
    -- Item count
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, 0, 0, 18)
    countLabel.Position = UDim2.new(0, 0, 0.72, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "0 godlies loaded"
    countLabel.TextColor3 = Color3.fromRGB(100, 100, 150)
    countLabel.TextScaled = true
    countLabel.Font = Enum.Font.Gotham
    countLabel.Parent = mainFrame
    
    -- Toggle
    toggleBtn.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        if isEnabled then
            toggleBtn.Text = "🟢 ON"
            toggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
            status.Text = "✅ Active"
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            if tick() - lastUpdate > UPDATE_INTERVAL then
                status.Text = "🔄 Updating..."
                fetchGodlyValues()
                countLabel.Text = #godlyValues .. " godlies loaded"
                status.Text = "✅ Active"
            end
            
            pcall(updateTradeDisplay)
        else
            toggleBtn.Text = "🔴 OFF"
            toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
            status.Text = "⏸️ Paused"
            status.TextColor3 = Color3.fromRGB(150, 150, 200)
            
            for _, obj in pairs(displayObjects) do
                if obj and obj.Parent then
                    obj:Destroy()
                end
            end
            displayObjects = {}
        end
    end)
    
    -- Update loop
    RunService.Heartbeat:Connect(function()
        if isEnabled then
            updateCounter = updateCounter + 1
            
            if tick() - lastUpdate > UPDATE_INTERVAL then
                status.Text = "🔄 Updating..."
                fetchGodlyValues()
                countLabel.Text = #godlyValues .. " godlies loaded"
                status.Text = "✅ Active"
            end
            
            if updateCounter % 2 == 0 then
                pcall(updateTradeDisplay)
            end
        end
    end)
    
    -- Initial fetch
    fetchGodlyValues()
    countLabel.Text = #godlyValues .. " godlies loaded"
    
    return screenGui
end

-- Start
task.wait(1)
pcall(createMainGUI)
print("✅ MM2 Godly Values Loaded - API Only")
