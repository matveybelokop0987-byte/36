-- ============================================================
--  MM2 FULL TRADE HELPER – С АВТООБНОВЛЕНИЕМ КАЖДЫЕ 5 МИНУТ
--  АВТОМАТИЧЕСКИ определяет цены с SupremeValues
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== РАЗРЕШЕННЫЕ КАТЕГОРИИ =====
local ALLOWED_CATEGORIES = {
    "commons",
    "uncommons", 
    "rares",
    "legendaries",
    "godlies",
    "chromas",
    "vintages",
    "ancient"
}

-- ===== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ =====
local itemPrices = {}
local isEnabled = false
local monitorConnection = nil
local createdLabels = {}
local totalDisplayFrame = nil
local winLossFrame = nil
local priceUpdateTimer = nil
local lastUpdateTime = os.time()
local totalItemsLoaded = 0

-- ===== ЗАГРУЗКА ОДНОЙ СТРАНИЦЫ =====
local function fetchCategory(url)
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not success or not response then
        return nil
    end

    local prices = {}
    -- Парсим HTML страницу
    for name, value in string.gmatch(response, "([%w%s%'%-]+)%s*Value%s*%-%s*([%d,]+)") do
        local cleanName = name:gsub("^%s*(.-)%s*$", "%1")
        local cleanValue = tonumber(value:gsub(",", ""))
        if cleanName and cleanValue then
            prices[cleanName] = cleanValue
        end
    end
    return prices
end

-- ===== ЗАГРУЗКА ВСЕХ КАТЕГОРИЙ =====
local function fetchAllPrices()
    print("🔄 Загрузка цен с SupremeValues...")
    local allPrices = {}
    local loaded = 0

    for _, category in ipairs(ALLOWED_CATEGORIES) do
        local url = "https://supremevalues.com/mm2/" .. category
        local prices = fetchCategory(url)
        if prices and next(prices) then
            for k, v in pairs(prices) do
                allPrices[k] = v
            end
            local count = 0
            for _ in pairs(prices) do count = count + 1 end
            loaded = loaded + count
            print("   ✅ " .. category .. " – " .. count .. " предметов")
        else
            warn("   ⚠️ Не удалось загрузить: " .. category)
        end
        task.wait(0.5)
    end

    if next(allPrices) then
        itemPrices = allPrices
        totalItemsLoaded = loaded
        lastUpdateTime = os.time()
        print("✅ Загружено " .. loaded .. " цен!")
        return true
    else
        warn("❌ Не удалось загрузить цены!")
        return false
    end
end

-- ===== ПОИСК GUI ТРЕЙДА =====
local function findTradeGui()
    local possibleNames = {"Trade", "TradeUI", "Trading", "TradeWindow"}
    local function searchIn(parent)
        if not parent then return nil end
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

-- ===== ПОЛУЧЕНИЕ ИМЕНИ ПРЕДМЕТА =====
local function getItemNameFromSlot(slot)
    if not slot then return nil end
    
    -- Ищем TextLabel с именем
    for _, child in ipairs(slot:GetChildren()) do
        if child:IsA("TextLabel") then
            local text = child.Text
            if text and text ~= "" and not tonumber(text) then
                -- Пропускаем служебные надписи
                local skipWords = {"Offer", "Request", "Accept", "Decline", "Ready", 
                                  "Waiting", "Add", "Remove", "Please wait", "before accepting",
                                  "Your offer", "Their offer", "Survival XP"}
                local shouldSkip = false
                for _, word in ipairs(skipWords) do
                    if text:find(word) then
                        shouldSkip = true
                        break
                    end
                end
                if not shouldSkip then
                    return text
                end
            end
        end
    end
    
    -- Проверяем ImageButton (часто имя в свойстве Image)
    for _, child in ipairs(slot:GetChildren()) do
        if child:IsA("ImageButton") then
            local image = child.Image
            if image and image ~= "" then
                -- Пробуем извлечь имя из URL
                local name = image:match("rbxassetid://%d+&name=(.+)&")
                if name then
                    return name
                end
                -- Пробуем другие паттерны
                name = image:match("&name=(.+)&")
                if name then
                    return name
                end
            end
        end
    end
    
    return nil
end

-- ===== ПОИСК ВСЕХ ПРЕДМЕТОВ В КОНТЕЙНЕРЕ =====
local function findItemsInContainer(container)
    local items = {}
    if not container then return items end
    
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("ImageButton") or child:IsA("Frame") then
            local name = getItemNameFromSlot(child)
            if name then
                local price = itemPrices[name]
                if price then
                    items[name] = price
                end
            end
        end
    end
    return items
end

-- ===== ОПРЕДЕЛЕНИЕ СТОРОН В ТРЕЙДЕ =====
local function findTradeSides(tradeGui)
    local playerContainer = nil
    local otherContainer = nil
    
    -- Ищем по названиям
    for _, child in ipairs(tradeGui:GetChildren()) do
        local name = child.Name:lower()
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            if name:find("player") or name:find("left") or name:find("my") or name:find("your") or name:find("offer") then
                if not playerContainer then
                    playerContainer = child
                end
            elseif name:find("other") or name:find("right") or name:find("target") or name:find("their") or name:find("request") then
                if not otherContainer then
                    otherContainer = child
                end
            end
        end
    end
    
    -- Если не нашли, ищем по позиции
    if not playerContainer or not otherContainer then
        local containers = {}
        local function collectContainers(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                    local hasItems = false
                    for _, item in ipairs(child:GetChildren()) do
                        if item:IsA("ImageButton") and item.Image and item.Image ~= "" then
                            hasItems = true
                            break
                        end
                    end
                    if hasItems then
                        table.insert(containers, child)
                    end
                end
                collectContainers(child)
            end
        end
        collectContainers(tradeGui)
        
        if #containers >= 2 then
            table.sort(containers, function(a, b)
                return a.AbsolutePosition.X < b.AbsolutePosition.X
            end)
            playerContainer = containers[1]
            otherContainer = containers[2]
        elseif #containers == 1 then
            playerContainer = containers[1]
        end
    end
    
    return playerContainer, otherContainer
end

-- ===== ОБНОВЛЕНИЕ ИНТЕРФЕЙСА ТРЕЙДА =====
local function updateTradeUI(tradeGui)
    if not tradeGui then return end
    
    -- Очистка
    for _, label in ipairs(createdLabels) do 
        pcall(function() label:Destroy() end)
    end
    createdLabels = {}
    if totalDisplayFrame then 
        pcall(function() totalDisplayFrame:Destroy() end)
        totalDisplayFrame = nil 
    end
    if winLossFrame then 
        pcall(function() winLossFrame:Destroy() end)
        winLossFrame = nil 
    end
    
    -- Находим стороны
    local playerContainer, otherContainer = findTradeSides(tradeGui)
    
    if not playerContainer and not otherContainer then
        return
    end
    
    -- Собираем предметы
    local playerItems = findItemsInContainer(playerContainer)
    local otherItems = findItemsInContainer(otherContainer)
    
    -- Считаем суммы
    local playerSum = 0
    for _, price in pairs(playerItems) do
        playerSum = playerSum + price
    end
    
    local otherSum = 0
    for _, price in pairs(otherItems) do
        otherSum = otherSum + price
    end
    
    local diff = playerSum - otherSum
    
    -- Вывод в консоль для отладки
    if next(playerItems) or next(otherItems) then
        local playerStr = ""
        for name, price in pairs(playerItems) do
            playerStr = playerStr .. name .. "(" .. price .. ") "
        end
        local otherStr = ""
        for name, price in pairs(otherItems) do
            otherStr = otherStr .. name .. "(" .. price .. ") "
        end
        print("📊 Игрок: " .. playerStr)
        print("📊 Соперник: " .. otherStr)
    end
    
    -- Добавляем ценники на предметы
    local function addPriceLabels(container, items)
        if not container or not items then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ImageButton") or child:IsA("Frame") then
                local name = getItemNameFromSlot(child)
                if name and items[name] then
                    local price = items[name]
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(0, 50, 0, 16)
                    label.Position = UDim2.new(0, -5, -0.4, 0)
                    label.BackgroundTransparency = 1
                    label.Text = tostring(price)
                    label.TextColor3 = Color3.new(0, 1, 0)
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 12
                    label.TextStrokeTransparency = 0.3
                    label.TextStrokeColor3 = Color3.new(0, 0, 0)
                    label.Parent = child
                    table.insert(createdLabels, label)
                end
            end
        end
    end
    
    addPriceLabels(playerContainer, playerItems)
    addPriceLabels(otherContainer, otherItems)
    
    -- Панель суммы
    totalDisplayFrame = Instance.new("Frame")
    totalDisplayFrame.Name = "TotalDisplay"
    totalDisplayFrame.Size = UDim2.new(0.8, 0, 0, 40)
    totalDisplayFrame.Position = UDim2.new(0.1, 0, -0.1, 0)
    totalDisplayFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    totalDisplayFrame.BackgroundTransparency = 0.8
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
    
    -- Шкала WIN/LOSE
    winLossFrame = Instance.new("Frame")
    winLossFrame.Name = "WinLossFrame"
    winLossFrame.Size = UDim2.new(0.8, 0, 0, 30)
    winLossFrame.Position = UDim2.new(0.1, 0, -0.18, 0)
    winLossFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    winLossFrame.BackgroundTransparency = 0.8
    winLossFrame.BorderSizePixel = 0
    winLossFrame.Parent = tradeGui
    
    local diffLabel = Instance.new("TextLabel")
    diffLabel.Size = UDim2.new(1, 0, 1, 0)
    diffLabel.BackgroundTransparency = 1
    diffLabel.Font = Enum.Font.SourceSansBold
    diffLabel.TextSize = 18
    diffLabel.Parent = winLossFrame
    
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
    
    -- Прогресс-бар
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
        if ratio > 0.55 then
            fill.BackgroundColor3 = Color3.new(0, 1, 0)
        elseif ratio < 0.45 then
            fill.BackgroundColor3 = Color3.new(1, 0, 0)
        else
            fill.BackgroundColor3 = Color3.new(1, 1, 0)
        end
    else
        fill.Size = UDim2.new(0.5, 0, 1, 0)
        fill.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    end
end

-- ===== МОНИТОРИНГ =====
local function startMonitoring()
    if monitorConnection then return end
    monitorConnection = RunService.Heartbeat:Connect(function()
        if not isEnabled then return end
        local tradeGui = findTradeGui()
        if tradeGui then
            updateTradeUI(tradeGui)
        end
    end)
    print("🔍 Мониторинг запущен")
end

local function stopMonitoring()
    if monitorConnection then
        monitorConnection:Disconnect()
        monitorConnection = nil
    end
    for _, label in ipairs(createdLabels) do 
        pcall(function() label:Destroy() end)
    end
    createdLabels = {}
    if totalDisplayFrame then 
        pcall(function() totalDisplayFrame:Destroy() end)
        totalDisplayFrame = nil 
    end
    if winLossFrame then 
        pcall(function() winLossFrame:Destroy() end)
        winLossFrame = nil 
    end
    print("⏹ Мониторинг остановлен")
end

-- ===== АВТООБНОВЛЕНИЕ =====
local function startPriceUpdater()
    if priceUpdateTimer then return end
    
    fetchAllPrices()
    
    priceUpdateTimer = RunService.Heartbeat:Connect(function()
        if not isEnabled then return end
        if not priceUpdateTimer._counter then
            priceUpdateTimer._counter = 0
        end
        priceUpdateTimer._counter = priceUpdateTimer._counter + 1
        if priceUpdateTimer._counter >= 18000 then
            priceUpdateTimer._counter = 0
            fetchAllPrices()
            local tradeGui = findTradeGui()
            if tradeGui then
                updateTradeUI(tradeGui)
            end
            updateMainStatus()
        end
    end)
    print("⏳ Автообновление каждые 5 минут")
end

-- ===== ОБНОВЛЕНИЕ СТАТУСА =====
local function updateMainStatus()
    local mainGui = playerGui:FindFirstChild("MM2TradeHelper")
    if not mainGui then return end
    local statusText = mainGui:FindFirstChild("MainFrame"):FindFirstChild("StatusText")
    if statusText then
        local timeStr = os.date("%H:%M:%S", lastUpdateTime)
        statusText.Text = "Статус: ВКЛ | Цен: " .. totalItemsLoaded .. " | " .. timeStr
    end
end

-- ===== ВКЛ/ВЫКЛ =====
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

-- ===== ГЛАВНОЕ ОКНО =====
local function createMainGUI()
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "MM2TradeHelper"
    mainGui.Parent = playerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 170)
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
    statusText.Position = UDim2.new(0, 0, 0.2, 0)
    statusText.Text = "Статус: ВЫКЛ"
    statusText.TextColor3 = Color3.new(1, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.SourceSans
    statusText.TextSize = 13
    statusText.Parent = mainFrame
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, 0, 0, 16)
    infoText.Position = UDim2.new(0, 0, 0.35, 0)
    infoText.Text = "Commons • Uncommons • Rares • Legendaries"
    infoText.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    infoText.BackgroundTransparency = 1
    infoText.Font = Enum.Font.SourceSans
    infoText.TextSize = 10
    infoText.Parent = mainFrame
    
    local infoText2 = Instance.new("TextLabel")
    infoText2.Size = UDim2.new(1, 0, 0, 16)
    infoText2.Position = UDim2.new(0, 0, 0.42, 0)
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
    
    print("✅ Trade Helper запущен!")
    print("📋 Категории: " .. table.concat(ALLOWED_CATEGORIES, ", "))
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
    print("✅ Скрипт работает! Цены загружаются автоматически с SupremeValues")
end
```
 
