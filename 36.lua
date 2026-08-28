-- ============================================================
--  MM2 TRADE HELPER – ТОЛЬКО GODLY И ANCIENT
--  БЕЗ ЛОКАЛЬНОЙ БАЗЫ, ТОЛЬКО С САЙТА
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== URL ТОЛЬКО НУЖНЫХ КАТЕГОРИЙ =====
local CATEGORY_URLS = {
    "https://supremevalues.com/mm2/godlies",
    "https://supremevalues.com/mm2/ancient",
}

-- ===== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ =====
local itemPrices = {} -- Пустая база, только с сайта
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
    for name, value in string.gmatch(response, "([%w%s%'%-]+)%s*Value%s*%-%s*([%d,]+)") do
        local cleanName = name:gsub("^%s*(.-)%s*$", "%1")
        local cleanValue = tonumber(value:gsub(",", ""))
        if cleanName and cleanValue then
            prices[cleanName] = cleanValue
        end
    end
    return prices
end

-- ===== ЗАГРУЗКА ТОЛЬКО GODLY И ANCIENT =====
local function fetchAllPrices()
    print("🔄 Обновление цен (только Godly и Ancient)...")
    local allPrices = {}
    local loaded = 0

    for _, url in ipairs(CATEGORY_URLS) do
        local prices = fetchCategory(url)
        if prices and next(prices) then
            for k, v in pairs(prices) do
                allPrices[k] = v
            end
            local count = 0
            for _ in pairs(prices) do count = count + 1 end
            loaded = loaded + count
            print("   ✅ " .. url:match("mm2/(.+)$") .. " – " .. count .. " предметов")
        else
            warn("   ⚠️ Не удалось загрузить: " .. url)
        end
        task.wait(0.5)
    end

    if next(allPrices) then
        -- Очищаем и загружаем новые цены
        for k in pairs(itemPrices) do itemPrices[k] = nil end
        for k, v in pairs(allPrices) do
            itemPrices[k] = v
        end
        totalItemsLoaded = loaded
        lastUpdateTime = os.time()
        print("✅ Цены обновлены! Загружено Godly/Ancient: " .. loaded)
        return true
    else
        warn("❌ Не удалось загрузить цены. Проверьте интернет-соединение.")
        totalItemsLoaded = 0
        return false
    end
end

-- ===== ПОИСК GUI ТРЕЙДА =====
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

-- ===== ПОЛУЧЕНИЕ ИМЕНИ =====
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

-- ===== ОБНОВЛЕНИЕ ИНТЕРФЕЙСА ТРЕЙДА =====
local function updateTradeUI(tradeGui)
    if not tradeGui then return end

    -- Очистка
    for _, label in ipairs(createdLabels) do label:Destroy() end
    createdLabels = {}
    if totalDisplayFrame then totalDisplayFrame:Destroy() totalDisplayFrame = nil end
    if winLossFrame then winLossFrame:Destroy() winLossFrame = nil end

    -- Сбор слотов
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

    -- Метки цен (только для предметов с ценой > 0)
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

    -- Поиск контейнеров сторон
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

    -- Панель суммы
    totalDisplayFrame = Instance.new("Frame")
    totalDisplayFrame.Name = "TotalDisplay"
    totalDisplayFrame.Size = UDim2.new(0.8, 0, 0, 40)
    totalDisplayFrame.Position = UDim2.new(0.1, 0, -0.1, 0)
    totalDisplayFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    totalDisplayFrame.BorderSizePixel = 0
    totalDisplayFrame.Parent = tradeGui

    local leftLabel = Instance.new("TextLabel")
    leftLabel.Size = UDim2.new(0.5, 0, 1, 0)
    leftLabel.Text = "Ваша сумма: " .. tostring(playerSum)
    leftLabel.TextColor3 = Color3.new(0, 1, 0)
    leftLabel.BackgroundTransparency = 1
    leftLabel.Font = Enum.Font.SourceSansBold
    leftLabel.TextSize = 16
    leftLabel.Parent = totalDisplayFrame

    local rightLabel = Instance.new("TextLabel")
    rightLabel.Size = UDim2.new(0.5, 0, 1, 0)
    rightLabel.Position = UDim2.new(0.5, 0, 0, 0)
    rightLabel.Text = "Сумма соперника: " .. tostring(otherSum)
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
            diffLabel.Text = "✅ WIN! Вы в выигрыше на " .. tostring(diff)
            diffLabel.TextColor3 = Color3.new(0, 1, 0)
        elseif diff < 0 then
            diffLabel.Text = "❌ LOSE! Вы в проигрыше на " .. tostring(math.abs(diff))
            diffLabel.TextColor3 = Color3.new(1, 0, 0)
        else
            diffLabel.Text = "⚖️ РАВНО! Одинаковые суммы"
            diffLabel.TextColor3 = Color3.new(1, 1, 0)
        end
    else
        diffLabel.Text = "⚠️ Стороны не определены"
        diffLabel.TextColor3 = Color3.new(1, 1, 1)
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
        fill.BackgroundColor3 = ratio > 0.5 and Color3.new(0,1,0) or (ratio < 0.5 and Color3.new(1,0,0) or Color3.new(1,1,0))
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
    print("🔍 Мониторинг трейда запущен")
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

-- ===== АВТООБНОВЛЕНИЕ КАЖДЫЕ 5 МИНУТ =====
local function startPriceUpdater()
    if priceUpdateTimer then return end

    -- Первая загрузка
    fetchAllPrices()

    priceUpdateTimer = RunService.Heartbeat:Connect(function()
        if not isEnabled then return end
        if not priceUpdateTimer._counter then
            priceUpdateTimer._counter = 0
        end
        priceUpdateTimer._counter = priceUpdateTimer._counter + 1
        -- 5 минут = 18000 тиков (при ~60 Гц)
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
    print("⏳ Автообновление цен запущено (каждые 5 минут)")
end

-- ===== ОБНОВЛЕНИЕ СТАТУСА В ГЛАВНОМ ОКНЕ =====
local function updateMainStatus()
    local mainGui = playerGui:FindFirstChild("MM2TradeHelper")
    if not mainGui then return end
    local statusText = mainGui:FindFirstChild("MainFrame"):FindFirstChild("StatusText")
    if statusText then
        local timeStr = os.date("%H:%M:%S", lastUpdateTime)
        local itemsStr = totalItemsLoaded > 0 and totalItemsLoaded or "0"
        statusText.Text = "Статус: ВКЛ | Godly/Ancient: " .. itemsStr .. " | Обн: " .. timeStr
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
    mainFrame.Size = UDim2.new(0, 280, 0, 140)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "⚡ Trade Helper (Godly/Ancient)"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = mainFrame

    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Position = UDim2.new(0, 0, 0.25, 0)
    statusText.Text = "Статус: ВЫКЛ"
    statusText.TextColor3 = Color3.new(1, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.SourceSans
    statusText.TextSize = 13
    statusText.Parent = mainFrame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0.8, 0, 0, 30)
    toggleButton.Position = UDim2.new(0.1, 0, 0.5, 0)
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

    print("✅ Главное окно создано (только Godly и Ancient)")
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
    print("✅ Скрипт загружен – только Godly/Ancient, автообновление каждые 5 минут!")
end
