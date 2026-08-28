-- ============================================================
--  MM2 TRADE HELPER – ПРОСТАЯ РАБОЧАЯ ВЕРСИЯ
--  ТОЛЬКО GODLY И ANCIENT
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== ЗАГРУЗКА ЦЕН С САЙТА =====
local itemPrices = {}
local isEnabled = false
local monitorConnection = nil
local priceLabels = {}

-- Простой парсер для supremevalues.com
local function loadPrices()
    print("🔄 Загрузка цен...")
    local newPrices = {}
    
    -- Загружаем Godly
    local success, response = pcall(function()
        return HttpService:GetAsync("https://supremevalues.com/mm2/godlies")
    end)
    
    if success and response then
        -- Ищем все "Название - Value - число"
        for name, value in string.gmatch(response, "([%w%s%'%-%.]+)%s*Value%s*%-%s*([%d,]+)") do
            local cleanName = name:gsub("^%s*(.-)%s*$", "%1")
            local cleanValue = tonumber(value:gsub(",", ""))
            if cleanName and cleanValue and cleanValue > 0 then
                newPrices[cleanName] = cleanValue
            end
        end
        print("   ✅ Загружено Godly: " .. #newPrices)
    end
    
    -- Загружаем Ancient
    success, response = pcall(function()
        return HttpService:GetAsync("https://supremevalues.com/mm2/ancient")
    end)
    
    if success and response then
        for name, value in string.gmatch(response, "([%w%s%'%-%.]+)%s*Value%s*%-%s*([%d,]+)") do
            local cleanName = name:gsub("^%s*(.-)%s*$", "%1")
            local cleanValue = tonumber(value:gsub(",", ""))
            if cleanName and cleanValue and cleanValue > 0 then
                newPrices[cleanName] = cleanValue
            end
        end
        print("   ✅ Загружено Ancient: " .. #newPrices)
    end
    
    -- Обновляем глобальную таблицу
    for k in pairs(itemPrices) do itemPrices[k] = nil end
    for k, v in pairs(newPrices) do itemPrices[k] = v end
    
    print("✅ Всего загружено: " .. #itemPrices)
end

-- ===== ПОИСК ГЛАВНОГО ОКНА ТРЕЙДА =====
local function findTradeWindow()
    -- Ищем в PlayerGui
    for _, child in ipairs(playerGui:GetChildren()) do
        if child.Name:lower():find("trade") or child.Name:lower():find("offer") then
            return child
        end
    end
    
    -- Ищем в CoreGui
    local coreGui = game:GetService("CoreGui")
    for _, child in ipairs(coreGui:GetChildren()) do
        if child.Name:lower():find("trade") or child.Name:lower():find("offer") then
            return child
        end
    end
    
    return nil
end

-- ===== ПОИСК ВСЕХ СЛОТОВ С ПРЕДМЕТАМИ =====
local function findAllSlots(parent)
    local slots = {}
    
    local function search(obj)
        for _, child in ipairs(obj:GetChildren()) do
            -- Проверяем, похож ли элемент на слот с предметом
            if child:IsA("ImageButton") or child:IsA("Frame") then
                -- Проверяем наличие текста с названием
                local hasText = false
                local itemName = ""
                
                for _, grandChild in ipairs(child:GetChildren()) do
                    if grandChild:IsA("TextLabel") or grandChild:IsA("TextButton") then
                        local text = grandChild.Text
                        if text and text ~= "" and not tonumber(text) and #text > 1 then
                            -- Проверяем, что это не служебный текст
                            if not text:lower():find("value") and 
                               not text:lower():find("price") and
                               not text:lower():find("total") and
                               not text:lower():find("win") and
                               not text:lower():find("lose") then
                                hasText = true
                                itemName = text
                                break
                            end
                        end
                    end
                end
                
                if hasText and itemName ~= "" then
                    table.insert(slots, {slot = child, name = itemName})
                end
            end
            search(child)
        end
    end
    
    search(parent)
    return slots
end

-- ===== ПОКАЗ ЦЕН НА СЛОТАХ =====
local function showPrices(tradeWindow)
    if not tradeWindow then return end
    
    -- Удаляем старые метки
    for _, label in ipairs(priceLabels) do
        pcall(function() label:Destroy() end)
    end
    priceLabels = {}
    
    -- Находим все слоты
    local slots = findAllSlots(tradeWindow)
    
    for _, slotData in ipairs(slots) do
        local slot = slotData.slot
        local itemName = slotData.name
        
        -- Проверяем цену
        local price = itemPrices[itemName] or 0
        
        if price > 0 then
            -- Создаем метку с ценой
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 60, 0, 18)
            label.Position = UDim2.new(0, -5, -0.3, 0)
            label.BackgroundTransparency = 1
            label.Text = tostring(price)
            label.TextColor3 = Color3.new(0, 1, 0)
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.TextStrokeTransparency = 0.3
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = slot
            table.insert(priceLabels, label)
        end
    end
end

-- ===== МОНИТОРИНГ ТРЕЙДА =====
local function startMonitoring()
    if monitorConnection then return end
    
    monitorConnection = RunService.Heartbeat:Connect(function()
        if not isEnabled then return end
        
        local tradeWindow = findTradeWindow()
        if tradeWindow then
            showPrices(tradeWindow)
        end
    end)
end

local function stopMonitoring()
    if monitorConnection then
        monitorConnection:Disconnect()
        monitorConnection = nil
    end
    
    for _, label in ipairs(priceLabels) do
        pcall(function() label:Destroy() end)
    end
    priceLabels = {}
end

-- ===== ВКЛЮЧЕНИЕ/ВЫКЛЮЧЕНИЕ =====
local function toggleHelper()
    isEnabled = not isEnabled
    
    if isEnabled then
        startMonitoring()
        print("✅ Помощник включен")
    else
        stopMonitoring()
        print("❌ Помощник выключен")
    end
end

-- ===== ГЛАВНОЕ ОКНО =====
local function createGUI()
    -- Загружаем цены
    loadPrices()
    
    -- Создаем главное окно
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "TradeHelper"
    mainGui.Parent = playerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 100)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Text = "⚡ Trade Helper"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = mainFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0.3, 0)
    statusLabel.Text = "Статус: ВЫКЛ"
    statusLabel.TextColor3 = Color3.new(1, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 12
    statusLabel.Parent = mainFrame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.8, 0, 0, 30)
    toggleBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
    toggleBtn.Text = "Включить"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = mainFrame
    
    toggleBtn.MouseButton1Click:Connect(function()
        toggleHelper()
        
        if isEnabled then
            statusLabel.Text = "Статус: ВКЛ"
            statusLabel.TextColor3 = Color3.new(0, 1, 0)
            toggleBtn.Text = "Выключить"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        else
            statusLabel.Text = "Статус: ВЫКЛ"
            statusLabel.TextColor3 = Color3.new(1, 0, 0)
            toggleBtn.Text = "Включить"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end)
    
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0.4, 0, 0, 18)
    refreshBtn.Position = UDim2.new(0.3, 0, 0.82, 0)
    refreshBtn.Text = "Обновить"
    refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.SourceSans
    refreshBtn.TextSize = 11
    refreshBtn.Parent = mainFrame
    
    refreshBtn.MouseButton1Click:Connect(function()
        loadPrices()
        if isEnabled then
            local tradeWindow = findTradeWindow()
            if tradeWindow then
                showPrices(tradeWindow)
            end
        end
    end)
    
    print("✅ Интерфейс создан")
end

-- ===== ЗАПУСК =====
pcall(function()
    createGUI()
    print("✅ Скрипт запущен")
end)
