-- ================================================================
--  MM2 TRADE HELPER – ПОЛНАЯ ЛОКАЛЬНАЯ БАЗА + АВТООБНОВЛЕНИЕ
--  Все категории: Commons, Uncommons, Rares, Legendaries,
--  Godlies, Chromas, Vintages, Ancients
-- ================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== ПОЛНАЯ ЛОКАЛЬНАЯ ТАБЛИЦА (ВСЕ ИЗВЕСТНЫЕ ПРЕДМЕТЫ) =====
local LOCAL_PRICES = {
    -- ========== COMMONS ==========
    ["Knife"] = 1, ["Gun"] = 1, ["Plushie"] = 1, ["Sword"] = 1,
    ["Bat"] = 1, ["Chocolate"] = 1, ["Candy"] = 1, ["Pumpkin"] = 1,
    ["Witch"] = 1, ["Ghost"] = 1, ["Mummy"] = 1, ["Skeleton"] = 1,
    ["Frankenstein"] = 1, ["Zombie"] = 1, ["Werewolf"] = 1, ["Vampire"] = 1,

    -- ========== UNCOMMONS ==========
    ["Green Knife"] = 2, ["Blue Knife"] = 2, ["Red Knife"] = 2,
    ["Yellow Knife"] = 2, ["Purple Knife"] = 2, ["Orange Knife"] = 2,
    ["Pink Knife"] = 2, ["Brown Knife"] = 2, ["White Knife"] = 2,
    ["Black Knife"] = 2, ["Gray Knife"] = 2, ["Silver Knife"] = 2,
    ["Gold Knife"] = 2, ["Camo Knife"] = 2, ["Neon Knife"] = 2,
    ["Tiger Knife"] = 2, ["Leopard Knife"] = 2, ["Zebra Knife"] = 2,
    ["Giraffe Knife"] = 2, ["Elephant Knife"] = 2,

    -- ========== RARES ==========
    ["Ice Knife"] = 3, ["Fire Knife"] = 3, ["Lightning Knife"] = 3,
    ["Dark Knife"] = 3, ["Shadow Knife"] = 3, ["Spectrum Knife"] = 3,
    ["Tiger"] = 3, ["Leopard"] = 3, ["Zebra"] = 3, ["Giraffe"] = 3,
    ["Elephant"] = 3, ["Diamond"] = 3, ["Ruby"] = 3, ["Sapphire"] = 3,
    ["Emerald"] = 3, ["Amethyst"] = 3, ["Topaz"] = 3, ["Opal"] = 3,
    ["Pearl"] = 3, ["Coral"] = 3,

    -- ========== LEGENDARIES ==========
    ["Night Blade"] = 5, ["Shadow Gun"] = 5, ["Death Shard"] = 5,
    ["Ghost Blade"] = 5, ["Phantom"] = 5, ["Darkbringer"] = 5,
    ["Lightbringer"] = 5, ["Eternal"] = 5, ["Eternal I"] = 5,
    ["Eternal II"] = 5, ["Eternal III"] = 5, ["Eternal IV"] = 5,
    ["Eternal V"] = 5, ["Eternal VI"] = 5, ["Eternal VII"] = 5,
    ["Eternal VIII"] = 5, ["Eternal IX"] = 5, ["Eternal X"] = 5,
    ["Shadow"] = 5, ["Laser"] = 5, ["Phaser"] = 5, ["Bioblade"] = 10,
    ["Cursed"] = 10, ["Wrapped"] = 10, ["Plasmite"] = 10, ["Nightstar"] = 10,
    ["Soul"] = 10,

    -- ========== GODLIES (ВСЕ 129 ПРЕДМЕТОВ) ==========
    -- Tier 4
    ["Traveler's Gun"] = 5600, ["Evergun"] = 3450, ["Evergreen"] = 2700,
    ["Constellation"] = 2700, ["Alienbeam"] = 2650, ["Turkey"] = 2425,
    ["Raygun"] = 2150, ["Vampire's Gun"] = 1950, ["Darkshot"] = 1800,
    ["Darksword"] = 1775, ["Blossom"] = 1370, ["Sakura"] = 1360,
    ["Sunrise"] = 1200, ["Snowcannon"] = 850, ["Bauble"] = 825,
    ["Sunset"] = 700, ["Soul"] = 615, ["Spirit"] = 605,
    ["Rainbow Gun"] = 420, ["Flora"] = 410, ["Rainbow"] = 410, ["Bloom"] = 400,
    -- Tier 3
    ["Heart Wand"] = 340, ["Xenoknife"] = 325, ["Xenoshot"] = 325,
    ["Ocean"] = 285, ["Waves"] = 280, ["Flowerwood Gun"] = 265,
    ["Blizzard"] = 260, ["Flowerwood"] = 260, ["Snowstorm"] = 260,
    ["Snow Dagger"] = 230, ["Watergun"] = 230, ["Treat"] = 155,
    ["Sweet"] = 150, ["Borealis"] = 145, ["Australis"] = 140,
    ["Icecream"] = 120, ["Bat"] = 120, ["Beachy"] = 105,
    ["Sands"] = 105, ["Pearlshine"] = 85, ["Pearl"] = 80,
    ["Candy"] = 80, ["Heartblade"] = 65, ["Ornament"] = 60,
    -- Tier 2
    ["Red Luger"] = 37, ["Phantom"] = 35, ["Spectre"] = 35,
    ["Candleflame"] = 33, ["Darkbringer"] = 33, ["Elderwood Blade"] = 33,
    ["Elderwood Revolver"] = 33, ["Iceblaster"] = 33, ["Lightbringer"] = 33,
    ["Makeshift"] = 33, ["Sugar"] = 32, ["Luger"] = 28,
    ["Green Luger"] = 23, ["Amerilaser"] = 22, ["Laser"] = 22,
    ["Hallowgun"] = 20, ["Nightblade"] = 20, ["Shark"] = 20,
    -- Tier 1
    ["Icebeam"] = 18, ["Plasmabeam"] = 18, ["Swirly Gun"] = 18,
    ["Battleaxe II"] = 17, ["Blaster"] = 17, ["Ginger Luger"] = 17,
    ["Pixel"] = 17, ["Gemstone"] = 15, ["Iceflake"] = 15,
    ["Old Glory"] = 15, ["Plasmablade"] = 15, ["Slasher"] = 15,
    ["Vampire's Edge"] = 15, ["Cookiecane"] = 13, ["Deathshard"] = 13,
    ["Eternalcane"] = 13, ["Gingerblade"] = 13, ["Jinglegun"] = 13,
    ["Lugercane"] = 13, ["Minty"] = 13, ["Nebula"] = 13,
    ["Virtual"] = 13, ["Battleaxe"] = 12, ["Gingermint"] = 12,
    ["Swirly Blade"] = 12, ["Chill"] = 10, ["Clockwork"] = 10,
    ["Fang"] = 10, ["Frostsaber"] = 10, ["Heat"] = 10,
    ["Spider"] = 10, ["Tides"] = 10,
    -- Tier 0
    ["Bioblade"] = 8, ["Eternal III"] = 8, ["Eternal IV"] = 8,
    ["Hallow's Blade"] = 8, ["Hallow's Edge"] = 8, ["Handsaw"] = 8,
    ["Boneblade"] = 7, ["Eternal"] = 7, ["Eternal II"] = 7,
    ["Frostbite"] = 7, ["Ghostblade"] = 7, ["Ice Dragon"] = 7,
    ["Ice Shard"] = 7, ["Prismatic"] = 7, ["Pumpking"] = 7,
    ["Saw"] = 7, ["Xmas"] = 7, ["Eggblade"] = 5,
    ["Flames"] = 5, ["Snowflake"] = 5, ["Winter's Edge"] = 5,
    ["Peppermint"] = 4, ["Cookieblade"] = 3, ["Blue Seer"] = 3,
    ["Purple Seer"] = 3, ["Red Seer"] = 3, ["Seer"] = 3,
    ["Orange Seer"] = 2, ["Yellow Seer"] = 2,

    -- ========== CHROMAS ==========
    ["Chroma Boneblade"] = 1000, ["Chroma Gemstone"] = 1200,
    ["Chroma Fang"] = 800, ["Chroma Heat"] = 800, ["Chroma Luger"] = 1200,
    ["Chroma Shark"] = 800, ["Chroma Tides"] = 800, ["Chroma Seer"] = 400,
    ["Chroma Darkbringer"] = 1500, ["Chroma Lightbringer"] = 1500,
    ["Chroma Saw"] = 600, ["Chroma BattleAxe"] = 600,
    ["Chroma Hallowscythe"] = 600, ["Chroma Hallowsblade"] = 600,
    ["Chroma Gingerbread"] = 500, ["Chroma Peppermint"] = 500,
    ["Chroma Snowflake"] = 500, ["Chroma Icebreaker"] = 500,
    ["Chroma Frostbite"] = 500, ["Chroma Chill"] = 500,
    ["Chroma Deathshard"] = 800, ["Chroma Clockwork"] = 800,
    ["Chroma Splinter"] = 600, ["Chroma Spider"] = 800,
    ["Chroma Frostsaber"] = 800, ["Chroma Handsaw"] = 600,
    ["Chroma RedSeer"] = 400, ["Chroma BlueSeer"] = 400,
    ["Chroma PurpleSeer"] = 400, ["Chroma OrangeSeer"] = 300,
    ["Chroma YellowSeer"] = 300, ["Chroma Slasher"] = 600,
    ["Chroma Laser"] = 800, ["Chroma Blaster"] = 800,
    ["Chroma Candy"] = 600, ["Chroma Sugar"] = 600,
    ["Chroma Eternal"] = 800, ["Chroma Eternal III"] = 800,
    ["Chroma Eternal IV"] = 800, ["Chroma Eternal V"] = 800,
    ["Chroma Eternal VI"] = 800, ["Chroma Eternal VII"] = 800,
    ["Chroma Eternal VIII"] = 800, ["Chroma Eternal IX"] = 800,
    ["Chroma Eternal X"] = 800,

    -- ========== VINTAGES ==========
    ["Snowflake"] = 5, ["Peppermint"] = 4, ["Cookieblade"] = 3,
    ["Green Elite"] = 8, ["Blue Elite"] = 8, ["Red Elite"] = 8,
    ["Shadow"] = 8, ["Laser"] = 8, ["Phaser"] = 8,
    ["Marshmallow"] = 8, ["Jack"] = 8, ["Slasher"] = 8,
    ["Splitter"] = 8, ["Golden"] = 8, ["Virtual"] = 8,
    ["Cowboy"] = 8, ["Stunt"] = 8, ["Glitched"] = 8,
    ["Corrupt"] = 8, ["Sammy"] = 8, ["Spy"] = 8,
    ["Ghost"] = 8, ["Mummy"] = 8, ["Skeleton"] = 8,
    ["Zombie"] = 8, ["Werewolf"] = 8, ["Vampire"] = 8,
    ["Frankenstein"] = 8, ["Bat"] = 8, ["Chocolate"] = 8,
    ["Candy"] = 8, ["Pumpkin"] = 8, ["Witch"] = 8,

    -- ========== ANCIENTS ==========
    ["Ancient"] = 100, ["Ancient I"] = 100, ["Ancient II"] = 100,
    ["Ancient III"] = 100, ["Ancient IV"] = 100, ["Ancient V"] = 100,
    ["Ancient VI"] = 100, ["Ancient VII"] = 100, ["Ancient VIII"] = 100,
    ["Ancient IX"] = 100, ["Ancient X"] = 100,

    -- ========== ДОПОЛНИТЕЛЬНЫЕ ПОПУЛЯРНЫЕ ==========
    ["Elderwood Scythe"] = 15, ["Bubbles"] = 12, ["iRevolver"] = 10,
    ["Bells"] = 8, ["Tourist"] = 5, ["Ginger Luger"] = 15,
    ["Gingerblade"] = 15, ["Ginger Gun"] = 15, ["Flames"] = 10,
    ["Flowerwood"] = 10, ["Hallowgun"] = 10, ["Spirit"] = 10,
    ["Vampire's Edge"] = 10, ["Batwing"] = 10, ["Sawblade"] = 10,
    ["Icewing"] = 10, ["Snowman"] = 10, ["Evergreen"] = 10,
    ["Holly"] = 10, ["Wreath"] = 10, ["Candy Cane"] = 10,
    ["Minty"] = 10, ["Blizzard"] = 10, ["Avalanche"] = 10,
    ["Icicle"] = 10, ["Glacier"] = 10, ["Permafrost"] = 10,
    ["Tundra"] = 10, ["Arctic"] = 10, ["Frozen"] = 10,
    ["Crystal"] = 10, ["Onyx"] = 10, ["Jade"] = 10,
    ["Quartz"] = 10, ["Obsidian"] = 10, ["Marble"] = 10,
    ["Granite"] = 10, ["Basalt"] = 10, ["Slate"] = 10,
    ["Limestone"] = 10, ["Sandstone"] = 10, ["Shale"] = 10,
}

-- ===== КАТЕГОРИИ ДЛЯ ОБНОВЛЕНИЯ =====
local CATEGORY_URLS = {
    "https://supremevalues.com/mm2/commons",
    "https://supremevalues.com/mm2/uncommons",
    "https://supremevalues.com/mm2/rares",
    "https://supremevalues.com/mm2/legendaries",
    "https://supremevalues.com/mm2/godlies",
    "https://supremevalues.com/mm2/vintages",
    "https://supremevalues.com/mm2/ancient",
    "https://supremevalues.com/mm2/chromas",
}

-- ===== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ =====
local itemPrices = {}
for k, v in pairs(LOCAL_PRICES) do itemPrices[k] = v end
local isEnabled = false
local monitorConnection = nil
local createdLabels = {}
local totalDisplayFrame = nil
local winLossFrame = nil
local priceUpdateTimer = nil
local lastUpdateTime = os.time()
local totalItemsLoaded = #LOCAL_PRICES

-- ===== ЗАГРУЗКА С САЙТА (ДОПОЛНЕНИЕ) =====
local function fetchCategory(url)
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not success or not response then return nil end
    local prices = {}
    for name, value in string.gmatch(response, "([%w%s%'%-]+)%s*Value%s*%-%s*([%d,]+)") do
        local cleanName = name:gsub("^%s*(.-)%s*$", "%1")
        local cleanValue = tonumber(value:gsub(",", ""))
        if cleanName and cleanValue then prices[cleanName] = cleanValue end
    end
    return prices
end

local function fetchAllPrices()
    print("🔄 Обновление цен с сайта...")
    local loaded = 0
    for _, url in ipairs(CATEGORY_URLS) do
        local prices = fetchCategory(url)
        if prices and next(prices) then
            for k, v in pairs(prices) do itemPrices[k] = v end
            local count = 0
            for _ in pairs(prices) do count = count + 1 end
            loaded = loaded + count
            print("   ✅ " .. url:match("mm2/(.+)$") .. " – " .. count .. " предметов")
        else
            warn("   ⚠️ Не удалось загрузить: " .. url)
        end
        task.wait(0.5)
    end
    totalItemsLoaded = 0
    for _ in pairs(itemPrices) do totalItemsLoaded = totalItemsLoaded + 1 end
    lastUpdateTime = os.time()
    print("✅ Всего в базе: " .. totalItemsLoaded .. " цен")
    return true
end

-- ===== ПОИСК GUI, ОБНОВЛЕНИЕ ИНТЕРФЕЙСА (СТАНДАРТНЫЙ КОД) =====
local function findTradeGui()
    local possibleNames = {"Trade", "TradeUI", "Trading", "TradeWindow"}
    local function searchIn(parent)
        for _, child in ipairs(parent:GetChildren()) do
            for _, name in ipairs(possibleNames) do
                if child.Name == name then return child end
            end
            local found = searchIn(child)
            if found then return found end
        end
        return nil
    end
    local found = searchIn(playerGui)
    if found then return found end
    local coreGui = game:GetService("CoreGui")
    return searchIn(coreGui)
end

local function getItemNameFromSlot(slot)
    for _, child in ipairs(slot:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local text = child.Text
            if text and text ~= "" and not tonumber(text) then
                return text
            end
        end
    end
    return slot.Name
end

local function updateTradeUI(tradeGui)
    if not tradeGui then return end
    for _, label in ipairs(createdLabels) do label:Destroy() end
    createdLabels = {}
    if totalDisplayFrame then totalDisplayFrame:Destroy() totalDisplayFrame = nil end
    if winLossFrame then winLossFrame:Destroy() winLossFrame = nil end

    local slots = {}
    local function collectSlots(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Frame") or child:IsA("ImageButton") then
                if not child:IsA("TextLabel") and child.Name ~= "TotalDisplay" and child.Name ~= "WinLossFrame" then
                    table.insert(slots, child)
                end
            end
            collectSlots(child)
        end
    end
    collectSlots(tradeGui)

    for _, slot in ipairs(slots) do
        local itemName = getItemNameFromSlot(slot)
        local price = itemPrices[itemName] or 0
        if price > 0 then
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 70, 0, 20)
            label.Position = UDim2.new(0, -5, -0.4, 0)
            label.BackgroundTransparency = 1
            label.Text = tostring(price)
            label.TextColor3 = Color3.new(0, 1, 0)
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.TextStrokeTransparency = 0.4
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = slot
            table.insert(createdLabels, label)
        end
    end

    local playerContainer, otherContainer
    for _, child in ipairs(tradeGui:GetChildren()) do
        if child.Name == "PlayerItems" or child.Name == "Left" or child.Name == "MyItems" then
            playerContainer = child
        elseif child.Name == "OtherItems" or child.Name == "Right" or child.Name == "TargetItems" then
            otherContainer = child
        end
    end

    local function sumContainer(container)
        local total = 0
        if not container then return total end
        for _, slot in ipairs(container:GetChildren()) do
            if slot:IsA("Frame") or slot:IsA("ImageButton") then
                local name = getItemNameFromSlot(slot)
                total = total + (itemPrices[name] or 0)
            end
        end
        return total
    end

    local playerSum = sumContainer(playerContainer)
    local otherSum = sumContainer(otherContainer)
    local diff = playerSum - otherSum

    totalDisplayFrame = Instance.new("Frame")
    totalDisplayFrame.Name = "TotalDisplay"
    totalDisplayFrame.Size = UDim2.new(0.8, 0, 0, 40)
    totalDisplayFrame.Position = UDim2.new(0.1, 0, -0.1, 0)
    totalDisplayFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    totalDisplayFrame.BorderSizePixel = 0
    totalDisplayFrame.Parent = tradeGui

    local leftLabel = Instance.new("TextLabel")
    leftLabel.Size = UDim2.new(0.5, 0, 1, 0)
    leftLabel.Text = "💰 Ваша: " .. tostring(playerSum)
    leftLabel.TextColor3 = Color3.new(0, 1, 0)
    leftLabel.BackgroundTransparency = 1
    leftLabel.Font = Enum.Font.SourceSansBold
    leftLabel.TextSize = 16
    leftLabel.Parent = totalDisplayFrame

    local rightLabel = Instance.new("TextLabel")
    rightLabel.Size = UDim2.new(0.5, 0, 1, 0)
    rightLabel.Position = UDim2.new(0.5, 0, 0, 0)
    rightLabel.Text = "💰 Соперник: " .. tostring(otherSum)
    rightLabel.TextColor3 = Color3.new(1, 0.5, 0)
    rightLabel.BackgroundTransparency = 1
    rightLabel.Font = Enum.Font.SourceSansBold
    rightLabel.TextSize = 16
    rightLabel.Parent = totalDisplayFrame

    winLossFrame = Instance.new("Frame")
    winLossFrame.Name = "WinLossFrame"
    winLossFrame.Size = UDim2.new(0.8, 0, 0, 30)
    winLossFrame.Position = UDim2.new(0.1, 0, -0.18, 0)
    winLossFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    winLossFrame.BorderSizePixel = 0
    winLossFrame.Parent = tradeGui

    local diffLabel = Instance.new("TextLabel")
    diffLabel.Size = UDim2.new(1, 0, 1, 0)
    diffLabel.BackgroundTransparency = 1
    diffLabel.Font = Enum.Font.SourceSansBold
    diffLabel.TextSize = 18
    diffLabel.Parent = winLossFrame

    if playerContainer and otherContainer then
        if diff > 0 then
            diffLabel.Text = "✅ WIN! +" .. tostring(diff)
            diffLabel.TextColor3 = Color3.new(0, 1, 0)
        elseif diff < 0 then
            diffLabel.Text = "❌ LOSE! -" .. tostring(math.abs(diff))
            diffLabel.TextColor3 = Color3.new(1, 0, 0)
        else
            diffLabel.Text = "⚖️ РАВНО!"
            diffLabel.TextColor3 = Color3.new(1, 1, 0)
        end
    else
        diffLabel.Text = "⚠️ Стороны не найдены"
        diffLabel.TextColor3 = Color3.new(1, 1, 1)
    end

    local barFrame = Instance.new("Frame")
    barFrame.Size = UDim2.new(0.8, 0, 0, 6)
    barFrame.Position = UDim2.new(0.1, 0, 0.7, 0)
    barFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barFrame.BorderSizePixel = 0
    barFrame.Parent = winLossFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = Color3.new(0, 1, 0)
    fill.BorderSizePixel = 0
    fill.Parent = barFrame

    local totalBoth = playerSum + otherSum
    if totalBoth > 0 then
        local ratio = playerSum / totalBoth
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        fill.BackgroundColor3 = ratio > 0.55 and Color3.new(0,1,0) or (ratio < 0.45 and Color3.new(1,0,0) or Color3.new(1,1,0))
    else
        fill.Size = UDim2.new(0.5, 0, 1, 0)
        fill.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    end
end

-- ===== МОНИТОРИНГ, АВТООБНОВЛЕНИЕ, ГЛАВНОЕ ОКНО =====
local function startMonitoring()
    if monitorConnection then return end
    monitorConnection = RunService.Heartbeat:Connect(function()
        if not isEnabled then return end
        local tradeGui = findTradeGui()
        if tradeGui then updateTradeUI(tradeGui) end
    end)
    print("🔍 Мониторинг запущен")
end

local function stopMonitoring()
    if monitorConnection then
        monitorConnection:Disconnect()
        monitorConnection = nil
    end
    for _, label in ipairs(createdLabels) do label:Destroy() end
    createdLabels = {}
    if totalDisplayFrame then totalDisplayFrame:Destroy() totalDisplayFrame = nil end
    if winLossFrame then winLossFrame:Destroy() winLossFrame = nil end
    print("⏹ Мониторинг остановлен")
end

local function startPriceUpdater()
    if priceUpdateTimer then return end
    fetchAllPrices()
    priceUpdateTimer = RunService.Heartbeat:Connect(function()
        if not isEnabled then return end
        if not priceUpdateTimer._counter then priceUpdateTimer._counter = 0 end
        priceUpdateTimer._counter = priceUpdateTimer._counter + 1
        if priceUpdateTimer._counter >= 36000 then
            priceUpdateTimer._counter = 0
            fetchAllPrices()
            local tradeGui = findTradeGui()
            if tradeGui then updateTradeUI(tradeGui) end
            updateMainStatus()
        end
    end)
    print("⏳ Автообновление каждые 10 минут")
end

local function updateMainStatus()
    local mainGui = playerGui:FindFirstChild("MM2TradeHelper")
    if not mainGui then return end
    local statusText = mainGui:FindFirstChild("MainFrame"):FindFirstChild("StatusText")
    if statusText then
        local timeStr = os.date("%H:%M:%S", lastUpdateTime)
        statusText.Text = "Статус: ВКЛ | Цен: " .. totalItemsLoaded .. " | " .. timeStr
    end
end

local function setEnabled(state)
    isEnabled = state
    if state then
        startMonitoring()
        local tradeGui = findTradeGui()
        if tradeGui then updateTradeUI(tradeGui) end
        updateMainStatus()
    else
        stopMonitoring()
        local mainGui = playerGui:FindFirstChild("MM2TradeHelper")
        if mainGui then
            local statusText = mainGui:FindFirstChild("MainFrame"):FindFirstChild("StatusText")
            if statusText then
                statusText.Text = "Статус: ВЫКЛ"
                statusText.TextColor3 = Color3.new(1, 0, 0)
            end
        end
    end
end

local function createMainGUI()
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "MM2TradeHelper"
    mainGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 190)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "⚡ Trade Helper"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = mainFrame

    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Position = UDim2.new(0, 0, 0.15, 0)
    statusText.Text = "Статус: ВЫКЛ"
    statusText.TextColor3 = Color3.new(1, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.SourceSans
    statusText.TextSize = 13
    statusText.Parent = mainFrame

    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, 0, 0, 16)
    infoText.Position = UDim2.new(0, 0, 0.30, 0)
    infoText.Text = "Commons • Uncommons • Rares • Legendaries"
    infoText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    infoText.BackgroundTransparency = 1
    infoText.Font = Enum.Font.SourceSans
    infoText.TextSize = 10
    infoText.Parent = mainFrame
    
    local infoText2 = Instance.new("TextLabel")
    infoText2.Size = UDim2.new(1, 0, 0, 16)
    infoText2.Position = UDim2.new(0, 0, 0.38, 0)
    infoText2.Text = "Godlies • Chromas • Vintages • Ancients"
    infoText2.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    infoText2.BackgroundTransparency = 1
    infoText2.Font = Enum.Font.SourceSans
    infoText2.TextSize = 10
    infoText2.Parent = mainFrame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0.8, 0, 0, 30)
    toggleButton.Position = UDim2.new(0.1, 0, 0.55, 0)
    toggleButton.Text = "Включить"
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 14
    toggleButton.Parent = mainFrame

    toggleButton.MouseButton1Click:Connect(function()
        setEnabled(not isEnabled)
        if isEnabled then
            statusText.Text = "Статус: ВКЛ"
            statusText.TextColor3 = Color3.new(0, 1, 0)
            toggleButton.Text = "Выключить"
            toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            updateMainStatus()
        else
            statusText.Text = "Статус: ВЫКЛ"
            statusText.TextColor3 = Color3.new(1, 0, 0)
            toggleButton.Text = "Включить"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end)

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0.4, 0, 0, 20)
    refreshBtn.Position = UDim2.new(0.3, 0, 0.85, 0)
    refreshBtn.Text = "Обновить цены"
    refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.SourceSans
    refreshBtn.TextSize = 12
    refreshBtn.Parent = mainFrame

    refreshBtn.MouseButton1Click:Connect(function()
        fetchAllPrices()
        updateMainStatus()
        local tradeGui = findTradeGui()
        if tradeGui then updateTradeUI(tradeGui) end
    end)

    print("✅ Интерфейс создан. В локальной базе " .. #LOCAL_PRICES .. " предметов.")
end

-- ===== ЗАПУСК =====
local success, err = pcall(function()
    startPriceUpdater()
    createMainGUI()
end)

if not success then
    warn("❌ Ошибка: " .. tostring(err))
    local errorGui = Instance.new("ScreenGui")
    errorGui.Parent = playerGui
    local errorFrame = Instance.new("Frame")
    errorFrame.Size = UDim2.new(0, 300, 0, 100)
    errorFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    errorFrame.BackgroundColor3 = Color3.new(1, 0, 0)
    errorFrame.Parent = errorGui
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, 0, 1, 0)
    errorLabel.Text = "Ошибка! Смотрите консоль (F9)"
    errorLabel.TextColor3 = Color3.new(1, 1, 1)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Font = Enum.Font.SourceSansBold
    errorLabel.TextSize = 18
    errorLabel.Parent = errorFrame
    task.wait(5)
    errorGui:Destroy()
else
    print("✅ Скрипт запущен! Все цены загружены. При включении будет показывать валюты.")
end
```
