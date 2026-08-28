-- ============================================================
--  MM2 TRADE HELPER – ТОЛЬКО GODLY И ANCIENT
--  С УЛУЧШЕННЫМ ПОИСКОМ СЛОТОВ
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
local itemPrices = {}
local isEnabled = false
local monitorConnection = nil
local createdLabels = {}
local totalDisplayFrame = nil
local winLossFrame = nil
local priceUpdateTimer = nil
local lastUpdateTime = os.time()
local totalItemsLoaded = 0
local tradeGui = nil

-- ===== ПРАВИЛЬНЫЙ ПАРСЕР ДЛЯ SUPREMEVALUES =====
local function fetchCategory(url)
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not success or not response then
        warn("❌ Не удалось загрузить: " .. url)
        return nil
    end

    local prices = {}
    local currentItem = nil
    local currentValue = nil
    
    for line in response:gmatch("[^\r\n]+") do
        local possibleName = line:match("^%s*([%w%s%'%-%.]+)%s*$")
        if possibleName and not possibleName:match("Value") 
           and not possibleName:match("Range") 
           and not possibleName:match("Stability")
           and not possibleName:match("Demand")
           and not possibleName:match("Change")
           and not possibleName:match("Tier")
           and not possibleName:match("Filter")
           and not possibleName:match("Sort")
           and not possibleName:match("Controls")
           and not possibleName:match("Extra")
           and not possibleName:match("TIP")
           and not possibleName:match("Supreme")
           and not possibleName:match("Join")
           and not possibleName:match("Trade")
           and not possibleName:match("Value Key")
           and not possibleName:match("Theme")
           and not possibleName:match("Mode")
           and not possibleName:match("Style")
           and not possibleName:match("Color")
           and not possibleName:match("Layout")
           and not possibleName:match("Inventory")
           and not possibleName:match("Your Inventory")
           and not possibleName:match("Percentile")
           and not possibleName:match("Changelog")
           and #possibleName > 1 then
            currentItem = possibleName:gsub("^%s*(.-)%s*$", "%1")
        end
        
        local value = line:match("Value%s*%-%s*([%d,]+)")
        if value and currentItem then
            local cleanValue = tonumber(value:gsub(",", ""))
            if cleanValue and cleanValue > 0 then
                prices[currentItem] = cleanValue
                print("   ✔️ " .. currentItem .. " = " .. cleanValue)
                currentItem = nil
            end
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

-- ===== ПОИСК GUI ТРЕЙДА (УЛУЧШЕННЫЙ) =====
local function findTradeGui()
    -- Проверяем все возможные места
    local guis = {
        playerGui,
        game:GetService("CoreGui"),
        game:GetService("StarterGui")
    }
    
    for _, gui in ipairs(guis) do
        local function searchRecursive(parent)
            if not parent then return nil end
            for _, child in ipairs(parent:GetChildren()) do
                -- Проверяем по имени
                if child.Name and (
                    string.lower(child.Name):find("trade") or 
                    string.lower(child.Name):find("trading") or
                    string.lower(child.Name):find("offer") or
                    string.lower(child.Name):find("exchange")
                ) then
                    print("✅ Найден GUI трейда: " .. child.Name)
                    return child
                end
                -- Проверяем дочерние элементы
                local found = searchRecursive(child)
                if found then return found end
            end
            return nil
        end
        local found = searchRecursive(gui)
        if found then return found end
    end
    
    -- Если не нашли, ищем по всем GUI
    for _, gui in ipairs(game:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, child in ipairs(gui:GetChildren()) do
                if child.Name and (
                    string.lower(child.Name):find("trade") or 
                    string.lower(child.Name):find("trading") or
                    string.lower(child.Name):find("offer") or
                    string.lower(child.Name):find("exchange")
                ) then
                    print("✅ Найден GUI трейда (альтернативный): " .. child.Name)
                    return child
                end
            end
        end
    end
    
    return nil
end

-- ===== ПОЛУЧЕНИЕ ИМЕНИ ИЗ СЛОТА (УЛУЧШЕННОЕ) =====
local function getItemNameFromSlot(slot)
    -- Проверяем все текстовые элементы
    local function findText(obj)
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                local text = child.Text
                if text and text ~= "" and not tonumber(text) and string.len(text) > 1 then
                    -- Проверяем, что это не служебный текст
                    if not string.lower(text):find("value") and 
                       not string.lower(text):find("price") and
                       not string.lower(text):find("total") and
                       not string.lower(text):find("sum") then
                        return text
                    end
                end
            end
            local found = findText(child)
            if found then return found end
        end
        return nil
    end
    
    local name = findText(slot)
    if name then return name end
    
    -- Если не нашли, проверяем ImageButton с именем
    if slot:IsA("ImageButton") and slot.Name and slot.Name ~= "" then
        return slot.Name
    end
    
    return slot.Name
end

-- ===== ПОИСК СЛОТОВ ПРЕДМЕТОВ (УЛУЧШЕННЫЙ) =====
local function findItemSlots(parent)
    local slots = {}
    
    local function searchRecursive(obj)
        if not obj then return end
        
        -- Проверяем, является ли объект слотом
        local isSlot = false
        
        -- Проверяем по имени
        if obj.Name and (
            string.lower(obj.Name):find("slot") or
            string.lower(obj.Name):find("item") or
            string.lower(obj.Name):find("weapon") or
            string.lower(obj.Name):find("knife") or
            string.lower(obj.Name):find("gun") or
            string.lower(obj.Name):find("pet")
        ) then
            isSlot = true
        end
        
        -- Проверяем наличие ImageLabel или ImageButton с картинкой предмета
        if obj:IsA("Frame") or obj:IsA("ImageButton") then
            for _, child in ipairs(obj:GetChildren()) do
                if (child:IsA("ImageLabel") or child:IsA("ImageButton")) and child.Image and child.Image ~= "" then
                    isSlot = true
                    break
                end
            end
        end
        
        -- Проверяем наличие текста с названием предмета
        if obj:IsA("Frame") or obj:IsA("ImageButton") then
            local hasItemName = false
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local text = child.Text
                    if text and text ~= "" and not tonumber(text) and string.len(text) > 1 then
                        -- Проверяем, не служебный ли это текст
                        if not string.lower(text):find("value") and 
                           not string.lower(text):find("price") and
                           not string.lower(text):find("total") and
                           not string.lower(text):find("sum") and
                           not string.lower(text):find("win") and
                           not string.lower(text):find("lose") then
                            hasItemName = true
                            break
                        end
                    end
                end
            end
            if hasItemName then
                isSlot = true
            end
        end
        
        if isSlot and obj:IsA("Frame") or obj:IsA("ImageButton") then
            table.insert(slots, obj)
        end
        
        -- Рекурсивно ищем в дочерних элементах
        for _, child in ipairs(obj:GetChildren()) do
            searchRecursive(child)
        end
    end
    
    searchRecursive(parent)
    return slots
end

-- ===== ОБНОВЛЕНИЕ ИНТЕРФЕЙСА ТРЕЙДА =====
local function updateTradeUI(tradeGui)
    if not tradeGui then 
        print("⚠️ GUI трейда не найден")
        return 
    end
    
    print("🔄 Обновление интерфейса трейда...")

    -- Очистка
    for _, label in ipairs(createdLabels) do label:Destroy() end
    createdLabels = {}
    if totalDisplayFrame then totalDisplayFrame:Destroy() totalDisplayFrame = nil end
    if winLossFrame then winLossFrame:Destroy() winLossFrame = nil end

    -- Находим слоты предметов
    local slots = findItemSlots(tradeGui)
    print("   Найдено слотов: " .. #slots)
    
    -- Если слотов мало, пробуем найти все Frame и ImageButton
    if #slots < 5 then
        local function collectAll(obj)
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ImageButton") then
                    if not child:IsA("TextLabel") and child.Name ~= "TotalDisplay" and child.Name ~= "WinLossFrame" then
                        table.insert(slots, child)
                    end
                end
                collectAll(child)
            end
        end
        collectAll(tradeGui)
        print("   Альтернативный сбор: " .. #slots .. " элементов")
    end

    -- Метки цен
    local labeledCount = 0
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
            labeledCount = labeledCount + 1
            print("   💰 " .. itemName .. " = " .. price)
        end
    end
    print("   Отмечено предметов: " .. labeledCount)

    -- Поиск контейнеров сторон
    local playerContainer, otherContainer
    for _, child in ipairs(tradeGui:GetChildren()) do
        if child.Name and (
            string.lower(child.Name):find("player") or 
            string.lower(child.Name):find("left") or 
            string.lower(child.Name):find("my") or
            string.lower(child.Name):find("own")
        ) then
            playerContainer = child
        elseif child.Name and (
            string.lower(child.Name):find("other") or 
            string.lower(child.Name):find("right") or 
            string.lower(child.Name):find("target") or
            string.lower(child.Name):find("their")
        ) then
            otherContainer = child
        end
    end

    local function sumContainer(container)
        local total = 0
        if not container then return total end
        local slotsInContainer = findItemSlots(container)
        for _, slot in ipairs(slotsInContainer) do
            local name = getItemNameFromSlot(slot)
            total = total + (itemPrices[name] or 0)
        end
        return total
    end

    local playerSum = sumContainer(playerContainer)
    local otherSum = sumContainer(otherContainer)
    local diff = playerSum - otherSum

    print("   Ваша сумма: " .. playerSum .. ", Соперник: " .. otherSum)

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
        local currentTradeGui = findTradeGui()
        if currentTradeGui then
            -- Обновляем только если GUI изменился или прошло время
            if tradeGui ~= currentTradeGui then
                tradeGui = currentTradeGui
                updateTradeUI(tradeGui)
            end
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
            if tradeGui then
                updateTradeUI(tradeGui)
            end
            updateMainStatus()
        end
    end)
    print("⏳ Автообновление цен запущено (каждые 5 минут)")
end

-- ===== ОБНОВЛЕНИЕ СТАТУСА =====
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
        tradeGui = findTradeGui()
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
        if tradeGui then updateTradeUI(tradeGui) end
    end)

    print("✅ Главное окно создано")
end
