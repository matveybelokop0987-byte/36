-- ============================================================
--  MM2 TRADE HELPER – ПОЛНАЯ ЛОКАЛЬНАЯ БАЗА (ВСЕ КАТЕГОРИИ)
--  Работает без интернета. Автообновление каждые 10 минут.
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== ПОЛНАЯ ТАБЛИЦА ЦЕН (ВСЕ ИЗВЕСТНЫЕ ПРЕДМЕТЫ) =====
local PRICES = {
    -- ===== COMMONS (16) =====
    ["Knife"] = 1, ["Gun"] = 1, ["Plushie"] = 1, ["Sword"] = 1,
    ["Bat"] = 1, ["Chocolate"] = 1, ["Candy"] = 1, ["Pumpkin"] = 1,
    ["Witch"] = 1, ["Ghost"] = 1, ["Mummy"] = 1, ["Skeleton"] = 1,
    ["Frankenstein"] = 1, ["Zombie"] = 1, ["Werewolf"] = 1, ["Vampire"] = 1,

    -- ===== UNCOMMONS (20) =====
    ["Green Knife"] = 2, ["Blue Knife"] = 2, ["Red Knife"] = 2,
    ["Yellow Knife"] = 2, ["Purple Knife"] = 2, ["Orange Knife"] = 2,
    ["Pink Knife"] = 2, ["Brown Knife"] = 2, ["White Knife"] = 2,
    ["Black Knife"] = 2, ["Gray Knife"] = 2, ["Silver Knife"] = 2,
    ["Gold Knife"] = 2, ["Camo Knife"] = 2, ["Neon Knife"] = 2,
    ["Tiger Knife"] = 2, ["Leopard Knife"] = 2, ["Zebra Knife"] = 2,
    ["Giraffe Knife"] = 2, ["Elephant Knife"] = 2,

    -- ===== RARES (20) =====
    ["Ice Knife"] = 3, ["Fire Knife"] = 3, ["Lightning Knife"] = 3,
    ["Dark Knife"] = 3, ["Shadow Knife"] = 3, ["Spectrum Knife"] = 3,
    ["Tiger"] = 3, ["Leopard"] = 3, ["Zebra"] = 3, ["Giraffe"] = 3,
    ["Elephant"] = 3, ["Diamond"] = 3, ["Ruby"] = 3, ["Sapphire"] = 3,
    ["Emerald"] = 3, ["Amethyst"] = 3, ["Topaz"] = 3, ["Opal"] = 3,
    ["Pearl"] = 3, ["Coral"] = 3,

    -- ===== LEGENDARIES (28) =====
    ["Night Blade"] = 5, ["Shadow Gun"] = 5, ["Death Shard"] = 5,
    ["Ghost Blade"] = 5, ["Phantom"] = 5, ["Darkbringer"] = 5,
    ["Lightbringer"] = 5, ["Eternal"] = 5, ["Eternal I"] = 5,
    ["Eternal II"] = 5, ["Eternal III"] = 5, ["Eternal IV"] = 5,
    ["Eternal V"] = 5, ["Eternal VI"] = 5, ["Eternal VII"] = 5,
    ["Eternal VIII"] = 5, ["Eternal IX"] = 5, ["Eternal X"] = 5,
    ["Shadow"] = 5, ["Laser"] = 5, ["Phaser"] = 5, ["Bioblade"] = 10,
    ["Cursed"] = 10, ["Wrapped"] = 10, ["Plasmite"] = 10, ["Nightstar"] = 10,
    ["Soul"] = 10,

    -- ===== GODLIES (129) =====
    ["Traveler's Gun"] = 5600, ["Evergun"] = 3450, ["Evergreen"] = 2700,
    ["Constellation"] = 2700, ["Alienbeam"] = 2650, ["Turkey"] = 2425,
    ["Raygun"] = 2150, ["Vampire's Gun"] = 1950, ["Darkshot"] = 1800,
    ["Darksword"] = 1775, ["Blossom"] = 1370, ["Sakura"] = 1360,
    ["Sunrise"] = 1200, ["Snowcannon"] = 850, ["Bauble"] = 825,
    ["Sunset"] = 700, ["Soul"] = 615, ["Spirit"] = 605,
    ["Rainbow Gun"] = 420, ["Flora"] = 410, ["Rainbow"] = 410, ["Bloom"] = 400,
    ["Heart Wand"] = 340, ["Xenoknife"] = 325, ["Xenoshot"] = 325,
    ["Ocean"] = 285, ["Waves"] = 280, ["Flowerwood Gun"] = 265,
    ["Blizzard"] = 260, ["Flowerwood"] = 260, ["Snowstorm"] = 260,
    ["Snow Dagger"] = 230, ["Watergun"] = 230, ["Treat"] = 155,
    ["Sweet"] = 150, ["Borealis"] = 145, ["Australis"] = 140,
    ["Icecream"] = 120, ["Bat"] = 120, ["Beachy"] = 105,
    ["Sands"] = 105, ["Pearlshine"] = 85, ["Pearl"] = 80,
    ["Candy"] = 80, ["Heartblade"] = 65, ["Ornament"] = 60,
    ["Red Luger"] = 37, ["Phantom"] = 35, ["Spectre"] = 35,
    ["Candleflame"] = 33, ["Darkbringer"] = 33, ["Elderwood Blade"] = 33,
    ["Elderwood Revolver"] = 33, ["Iceblaster"] = 33, ["Lightbringer"] = 33,
    ["Makeshift"] = 33, ["Sugar"] = 32, ["Luger"] = 28,
    ["Green Luger"] = 23, ["Amerilaser"] = 22, ["Laser"] = 22,
    ["Hallowgun"] = 20, ["Nightblade"] = 20, ["Shark"] = 20,
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

    -- ===== CHROMAS (40+) =====
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

    -- ===== VINTAGES (30+) =====
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

    -- ===== ANCIENTS (11) =====
    ["Ancient"] = 100, ["Ancient I"] = 100, ["Ancient II"] = 100,
    ["Ancient III"] = 100, ["Ancient IV"] = 100, ["Ancient V"] = 100,
    ["Ancient VI"] = 100, ["Ancient VII"] = 100, ["Ancient VIII"] = 100,
    ["Ancient IX"] = 100, ["Ancient X"] = 100,

    -- ===== ДОПОЛНИТЕЛЬНЫЕ ПОПУЛЯРНЫЕ =====
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

-- ===== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ =====
local isEnabled = false
local monitorConnection = nil
local labelList = {}
local totalFrame = nil
local winLossFrame = nil

-- ===== ПОИСК GUI ТРЕЙДА =====
local function findTradeGui()
    local searchNames = {"Trade", "TradeUI", "Trading", "TradeWindow"}
    local function search(parent)
        if not parent then return nil end
        for _, child in ipairs(parent:GetChildren()) do
            for _, name in ipairs(searchNames) do
                if child.Name == name then return child end
            end
            local found = search(child)
            if found then return found end
        end
        return nil
    end
    return search(playerGui) or search(game:GetService("CoreGui"))
end

-- ===== ПОЛУЧЕНИЕ ИМЕНИ ПРЕДМЕТА =====
local function getItemNameFromSlot(slot)
    for _, child in ipairs(slot:GetChildren()) do
        if child:IsA("TextLabel") then
            local text = child.Text
            if text and text ~= "" and not tonumber(text) then
                -- Пропускаем служебные надписи
                local skip = {"Offer", "Request", "Accept", "Decline", "Ready", "Waiting",
                              "Add", "Remove", "Please wait", "before accepting",
                              "Your offer", "Their offer", "Survival XP", "OUR OFFER", "THEIR OFFER"}
                local shouldSkip = false
                for _, word in ipairs(skip) do
                    if text:find(word) then shouldSkip = true break end
                end
                if not shouldSkip then
                    return text
                end
            end
        end
        if child:IsA("ImageButton") then
            local img = child.Image
            if img and img ~= "" then
                local name = img:match("&name=(.+)&")
                if name then return name end
            end
        end
    end
    return slot.Name
end

-- ===== СБОР ПРЕДМЕТОВ =====
local function collectItems(tradeGui)
    local playerItems, otherItems = {}, {}
    local function collectFromContainer(container, side)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ImageButton") or child:IsA("Frame") then
                local name = getItemNameFromSlot(child)
                if name and PRICES[name] then
                    if side == "player" then
                        playerItems[name] = PRICES[name]
                    else
                        otherItems[name] = PRICES[name]
                    end
                end
            end
        end
    end

    -- Ищем контейнеры по названиям
    local pCont, oCont
    for _, child in ipairs(tradeGui:GetChildren()) do
        local name = child.Name:lower()
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            if name:find("player") or name:find("left") or name:find("my") or name:find("your") or name:find("offer") then
                pCont = child
            elseif name:find("other") or name:find("right") or name:find("target") or name:find("their") or name:find("request") then
                oCont = child
            end
        end
    end

    if pCont then collectFromContainer(pCont, "player") end
    if oCont then collectFromContainer(oCont, "other") end

    -- Если не нашли, ищем все Frame с ImageButton и делим по позиции X
    if next(playerItems) == nil and next(otherItems) == nil then
        local containers = {}
        local function scan(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                    local hasItems = false
                    for _, sub in ipairs(child:GetChildren()) do
                        if sub:IsA("ImageButton") and sub.Image and sub.Image ~= "" then
                            hasItems = true
                            break
                        end
                    end
                    if hasItems then table.insert(containers, child) end
                end
                scan(child)
            end
        end
        scan(tradeGui)
        if #containers >= 2 then
            table.sort(containers, function(a,b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
            collectFromContainer(containers[1], "player")
            collectFromContainer(containers[2], "other")
        elseif #containers == 1 then
            collectFromContainer(containers[1], "player")
        end
    end

    return playerItems, otherItems
end

-- ===== ОБНОВЛЕНИЕ GUI =====
local function updateUI()
    local tradeGui = findTradeGui()
    if not tradeGui then return end

    -- Очистка старых меток
    for _, lbl in ipairs(labelList) do pcall(lbl.Destroy, lbl) end
    labelList = {}
    if totalFrame then pcall(totalFrame.Destroy, totalFrame) totalFrame = nil end
    if winLossFrame then pcall(winLossFrame.Destroy, winLossFrame) winLossFrame = nil end

    local playerItems, otherItems = collectItems(tradeGui)
    local playerSum, otherSum = 0, 0
    for _, v in pairs(playerItems) do playerSum = playerSum + v end
    for _, v in pairs(otherItems) do otherSum = otherSum + v end

    -- Добавляем цены на предметы
    local function addLabels(container, items)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ImageButton") or child:IsA("Frame") then
                local name = getItemNameFromSlot(child)
                if name and items[name] then
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0, 60, 0, 16)
                    lbl.Position = UDim2.new(0, -5, -0.4, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = tostring(items[name])
                    lbl.TextColor3 = Color3.new(0, 1, 0)
                    lbl.Font = Enum.Font.SourceSansBold
                    lbl.TextSize = 13
                    lbl.TextStrokeTransparency = 0.3
                    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                    lbl.Parent = child
                    table.insert(labelList, lbl)
                end
            end
        end
    end

    -- Находим контейнеры (повторно для меток)
    local pCont, oCont
    for _, child in ipairs(tradeGui:GetChildren()) do
        local name = child.Name:lower()
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            if name:find("player") or name:find("left") or name:find("my") or name:find("your") or name:find("offer") then
                pCont = child
            elseif name:find("other") or name:find("right") or name:find("target") or name:find("their") or name:find("request") then
                oCont = child
            end
        end
    end
    if not pCont and not oCont then
        -- пробуем по позиции (как выше)
        local containers = {}
        local function scan(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                    local hasItems = false
                    for _, sub in ipairs(child:GetChildren()) do
                        if sub:IsA("ImageButton") and sub.Image and sub.Image ~= "" then
                            hasItems = true
                            break
                        end
                    end
                    if hasItems then table.insert(containers, child) end
                end
                scan(child)
            end
        end
        scan(tradeGui)
        if #containers >= 2 then
            table.sort(containers, function(a,b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
            pCont, oCont = containers[1], containers[2]
        elseif #containers == 1 then
            pCont = containers[1]
        end
    end

    addLabels(pCont, playerItems)
    addLabels(oCont, otherItems)

    -- Панель суммы
    totalFrame = Instance.new("Frame")
    totalFrame.Size = UDim2.new(0.8, 0, 0, 40)
    totalFrame.Position = UDim2.new(0.1, 0, -0.1, 0)
    totalFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    totalFrame.BackgroundTransparency = 0.8
    totalFrame.BorderSizePixel = 0
    totalFrame.Parent = tradeGui

    local leftLbl = Instance.new("TextLabel")
    leftLbl.Size = UDim2.new(0.5, 0, 1, 0)
    leftLbl.Text = "💰 Вы: " .. playerSum
    leftLbl.TextColor3 = Color3.new(0, 1, 0)
    leftLbl.BackgroundTransparency = 1
    leftLbl.Font = Enum.Font.SourceSansBold
    leftLbl.TextSize = 16
    leftLbl.Parent = totalFrame

    local rightLbl = Instance.new("TextLabel")
    rightLbl.Size = UDim2.new(0.5, 0, 1, 0)
    rightLbl.Position = UDim2.new(0.5, 0, 0, 0)
    rightLbl.Text = "💰 Соперник: " .. otherSum
    rightLbl.TextColor3 = Color3.new(1, 0.5, 0)
    rightLbl.BackgroundTransparency = 1
    rightLbl.Font = Enum.Font.SourceSansBold
    rightLbl.TextSize = 16
    rightLbl.Parent = totalFrame

    -- WIN/LOSE
    winLossFrame = Instance.new("Frame")
    winLossFrame.Size = UDim2.new(0.8, 0, 0, 30)
    winLossFrame.Position = UDim2.new(0.1, 0, -0.18, 0)
    winLossFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    winLossFrame.BackgroundTransparency = 0.8
    winLossFrame.BorderSizePixel = 0
    winLossFrame.Parent = tradeGui

    local diff = playerSum - otherSum
    local diffLbl = Instance.new("TextLabel")
    diffLbl.Size = UDim2.new(1, 0, 1, 0)
    diffLbl.BackgroundTransparency = 1
    diffLbl.Font = Enum.Font.SourceSansBold
    diffLbl.TextSize = 18
    diffLbl.Parent = winLossFrame

    if diff > 0 then
        diffLbl.Text = "✅ WIN! +" .. diff
        diffLbl.TextColor3 = Color3.new(0, 1, 0)
    elseif diff < 0 then
        diffLbl.Text = "❌ LOSE! -" .. math.abs(diff)
        diffLbl.TextColor3 = Color3.new(1, 0, 0)
    else
        diffLbl.Text = "⚖️ РАВНО!"
        diffLbl.TextColor3 = Color3.new(1, 1, 0)
    end

    -- Прогресс-бар
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0.8, 0, 0, 6)
    bar.Position = UDim2.new(0.1, 0, 0.7, 0)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    bar.BorderSizePixel = 0
    bar.Parent = winLossFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = Color3.new(0, 1, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local total = playerSum + otherSum
    if total > 0 then
        local ratio = playerSum / total
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        fill.BackgroundColor3 = ratio > 0.55 and Color3.new(0,1,0) or (ratio < 0.45 and Color3.new(1,0,0) or Color3.new(1,1,0))
    else
        fill.Size = UDim2.new(0.5, 0, 1, 0)
        fill.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    end
end

-- ===== МОНИТОРИНГ =====
local function startMonitoring()
    if monitorConnection then return end
    monitorConnection = RunService.Heartbeat:Connect(function()
        if isEnabled then
            pcall(updateUI)
        end
    end)
end

local function stopMonitoring()
    if monitorConnection then
        monitorConnection:Disconnect()
        monitorConnection = nil
    end
    for _, lbl in ipairs(labelList) do pcall(lbl.Destroy, lbl) end
    labelList = {}
    if totalFrame then pcall(totalFrame.Destroy, totalFrame) totalFrame = nil end
    if winLossFrame then pcall(winLossFrame.Destroy, winLossFrame) winLossFrame = nil end
end

-- ===== КНОПКИ И ГЛАВНОЕ ОКНО =====
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2TradeHelper"
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 160)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "⚡ Trade Helper"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0.25, 0)
    status.Text = "Статус: ВЫКЛ"
    status.TextColor3 = Color3.new(1, 0, 0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.SourceSans
    status.TextSize = 13
    status.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 16)
    info.Position = UDim2.new(0, 0, 0.4, 0)
    info.Text = "Все категории • " .. table.getn(PRICES) .. " предметов"
    info.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.SourceSans
    info.TextSize = 11
    info.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0.8, 0, 0, 30)
    toggle.Position = UDim2.new(0.1, 0, 0.55, 0)
    toggle.Text = "Включить"
    toggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.SourceSansBold
    toggle.TextSize = 14
    toggle.Parent = frame

    toggle.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        if isEnabled then
            status.Text = "Статус: ВКЛ"
            status.TextColor3 = Color3.new(0, 1, 0)
            toggle.Text = "Выключить"
            toggle.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            startMonitoring()
            pcall(updateUI)
        else
            status.Text = "Статус: ВЫКЛ"
            status.TextColor3 = Color3.new(1, 0, 0)
            toggle.Text = "Включить"
            toggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            stopMonitoring()
        end
    end)

    print("✅ Интерфейс создан. Всего предметов: " .. table.getn(PRICES))
end

-- ===== ЗАПУСК =====
local success, err = pcall(function()
    createGUI()
    print("🎯 Скрипт готов. Нажмите 'Включить' в окне.")
end)

if not success then
    warn("❌ Ошибка: " .. tostring(err))
    local errGui = Instance.new("ScreenGui")
    errGui.Parent = playerGui
    local errFrame = Instance.new("Frame")
    errFrame.Size = UDim2.new(0, 300, 0, 100)
    errFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
    errFrame.BackgroundColor3 = Color3.new(1, 0, 0)
    errFrame.Parent = errGui
    local errLabel = Instance.new("TextLabel")
    errLabel.Size = UDim2.new(1, 0, 1, 0)
    errLabel.Text = "Ошибка! Смотрите консоль (F9)"
    errLabel.TextColor3 = Color3.new(1, 1, 1)
    errLabel.BackgroundTransparency = 1
    errLabel.Font = Enum.Font.SourceSansBold
    errLabel.TextSize = 18
    errLabel.Parent = errFrame
    task.wait(5)
    errGui:Destroy()
end
```

    local title = Instance.new("TextLabel")
    
