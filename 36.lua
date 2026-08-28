--[[
    MM2 Trade Values Helper - Полная версия с поддержкой валюты
    Отображение цен для Godly, Ancient предметов + подсчет валюты
    Обновление с supremevalues.com каждые 5 минут
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Конфигурация
local CONFIG = {
    UPDATE_INTERVAL = 300,
    API_URL = "https://supremevalues.com/api/mm2/values",
    RARITIES = {"Godly", "Ancient", "Corrupt"}
}

-- Глобальные переменные
local ValuesCache = {}
local isEnabled = false
local tradeOverlay = nil
local mainGui = nil
local updateTimer = 0

-- Функция для получения цен
local function fetchValues()
    local success, result = pcall(function()
        return HttpService:GetAsync(CONFIG.API_URL)
    end)
    
    if success and result then
        local data = HttpService:JSONDecode(result)
        if data and data.values then
            ValuesCache = data.values
            print("[MM2 Helper] Цены обновлены: " .. #ValuesCache .. " предметов")
            return true
        end
    end
    print("[MM2 Helper] Ошибка загрузки цен")
    return false
end

-- Получение цены предмета
local function getItemValue(itemName)
    if not ValuesCache or not ValuesCache[itemName] then
        return 0
    end
    return ValuesCache[itemName]
end

-- Проверка редкости
local function isRarityValid(rarity)
    if not rarity then return false end
    for _, validRarity in pairs(CONFIG.RARITIES) do
        if rarity == validRarity then
            return true
        end
    end
    return false
end

-- Парсинг валюты из текста
local function parseCurrency(text)
    if not text or text == "" then return 0 end
    
    -- Убираем пробелы и запятые
    local cleanText = text:gsub("[%s,]", "")
    
    -- Обработка формата "5k", "5K"
    if cleanText:match("^%d+[kK]$") then
        local num = tonumber(cleanText:sub(1, -2))
        return num * 1000
    end
    
    -- Обработка формата "5.5k", "5,5k"
    if cleanText:match("^%d+[.,]%d+[kK]$") then
        local num = tonumber(cleanText:sub(1, -2):gsub(",", "."))
        return math.floor(num * 1000)
    end
    
    -- Обычное число
    local num = tonumber(cleanText)
    if num then
        return num
    end
    
    return 0
end

-- Создание главного меню
local function createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TradeValuesGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 150)
    frame.Position = UDim2.new(0.02, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "💰 MM2 Trade Helper"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- Статус
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0.3, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "⏳ Загрузка цен..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = frame
    
    -- Кнопка вкл/выкл
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0.8, 0, 0, 35)
    toggleButton.Position = UDim2.new(0.1, 0, 0.55, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    toggleButton.Text = "🔴 ВЫКЛ"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = toggleButton
    
    -- Кнопка обновления
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0.3, 0, 0, 25)
    refreshButton.Position = UDim2.new(0.7, 0, 0.85, 0)
    refreshButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    refreshButton.Text = "🔄"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.TextScaled = true
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.Parent = frame
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 5)
    refreshCorner.Parent = refreshButton
    
    -- Обработчик вкл/выкл
    toggleButton.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        toggleButton.Text = isEnabled and "🟢 ВКЛ" or "🔴 ВЫКЛ"
        toggleButton.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(200, 0, 0)
        
        if isEnabled then
            statusLabel.Text = "✅ Готово"
            createTradeOverlay()
        else
            statusLabel.Text = "⛔ Выключено"
            if tradeOverlay then
                tradeOverlay:Destroy()
                tradeOverlay = nil
            end
        end
    end)
    
    -- Обработчик обновления
    refreshButton.MouseButton1Click:Connect(function()
        statusLabel.Text = "⏳ Обновление..."
        task.spawn(function()
            local success = fetchValues()
            statusLabel.Text = success and "✅ Обновлено!" or "❌ Ошибка!"
            if isEnabled then
                createTradeOverlay()
            end
            task.wait(2)
            if isEnabled then
                statusLabel.Text = "✅ Готово"
            else
                statusLabel.Text = "⛔ Выключено"
            end
        end)
    end)
    
    mainGui = screenGui
    return screenGui, toggleButton, statusLabel
end

-- Поиск окна трейда
local function findTradeWindow()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, frame in pairs(gui:GetDescendants()) do
                if frame:IsA("Frame") and frame.Visible then
                    if frame.Name:find("Trade") or frame.Name:find("trading") or frame.Name:find("offer") then
                        local hasItems = false
                        for _, child in pairs(frame:GetDescendants()) do
                            if child:IsA("ImageLabel") and child.Name:find("Item") then
                                hasItems = true
                                break
                            end
                        end
                        if hasItems then
                            return frame
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Получение валюты из стороны трейда
local function getSideCurrency(sideFrame)
    if not sideFrame then return 0 end
    
    -- Поиск текста с валютой
    for _, child in pairs(sideFrame:GetDescendants()) do
        if child:IsA("TextLabel") and child.Visible then
            local text = child.Text
            -- Проверяем, похоже ли на валюту
            if text:match("[%d,.]+[kK]?") then
                -- Проверяем, есть ли рядом иконка монеты
                local parent = child.Parent
                if parent then
                    for _, sibling in pairs(parent:GetChildren()) do
                        if sibling:IsA("ImageLabel") then
                            local imageId = sibling.Image
                            if imageId and (imageId:find("coin") or imageId:find("money") or imageId:find("Currency")) then
                                return parseCurrency(text)
                            end
                        end
                    end
                end
            end
        end
    end
    
    return 0
end

-- Создание оверлея
local function createTradeOverlay()
    if tradeOverlay then
        tradeOverlay:Destroy()
        tradeOverlay = nil
    end
    
    local tradeFrame = findTradeWindow()
    if not tradeFrame then
        print("[MM2 Helper] Окно трейда не найдено")
        return
    end
    
    print("[MM2 Helper] Окно трейда найдено, создаю оверлей")
    
    local overlay = Instance.new("Frame")
    overlay.Name = "TradeOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundTransparency = 1
    overlay.ClipsDescendants = false
    overlay.Parent = tradeFrame
    
    -- Отображение цены на предмете
    local function displayPriceOnItem(item)
        if not item or not item.Parent then return end
        
        local rarityLabel = item:FindFirstChild("RarityLabel")
        if not rarityLabel or not rarityLabel:IsA("TextLabel") then return end
        
        local rarity = rarityLabel.Text
        if not isRarityValid(rarity) then return end
        
        local nameLabel = item:FindFirstChild("NameLabel")
        if not nameLabel or not nameLabel:IsA("TextLabel") then return end
        
        local itemName = nameLabel.Text
        local price = getItemValue(itemName)
        
        if price > 0 then
            local priceLabel = item:FindFirstChild("PriceDisplay")
            if not priceLabel then
                priceLabel = Instance.new("TextLabel")
                priceLabel.Name = "PriceDisplay"
                priceLabel.Size = UDim2.new(1, 0, 0, 25)
                priceLabel.Position = UDim2.new(0, 0, -0.3, 0)
                priceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0, 200)
                priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                priceLabel.TextScaled = true
                priceLabel.Font = Enum.Font.GothamBold
                priceLabel.ZIndex = 10
                priceLabel.Parent = item
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 3)
                corner.Parent = priceLabel
            end
            priceLabel.Text = "💰 " .. price
            priceLabel.Visible = true
        end
    end
    
    -- Обновление всех цен
    local function updateAllPrices()
        if not tradeFrame or not tradeFrame.Parent then return end
        
        for _, item in pairs(tradeFrame:GetDescendants()) do
            if item:IsA("Frame") or item:IsA("ImageLabel") then
                if item.Name:find("Item") or item.Name:find("Slot") then
                    displayPriceOnItem(item)
                end
            end
        end
        
        updateTotalValues()
    end
    
    -- Обновление общей стоимости с валютой
    local function updateTotalValues()
        if not tradeFrame or not tradeFrame.Parent then return end
        
        local playerItemsTotal = 0
        local otherItemsTotal = 0
        local playerCurrency = 0
        local otherCurrency = 0
        
        -- Поиск сторон
        local playerSide = nil
        local otherSide = nil
        
        for _, child in pairs(tradeFrame:GetDescendants()) do
            if child:IsA("Frame") then
                if child.Name:find("Player") or child.Name:find("Your") then
                    playerSide = child
                elseif child.Name:find("Other") or child.Name:find("Their") then
                    otherSide = child
                end
            end
        end
        
        if not playerSide or not otherSide then
            local frames = {}
            for _, child in pairs(tradeFrame:GetDescendants()) do
                if child:IsA("Frame") and child:FindFirstChild("NameLabel") then
                    table.insert(frames, child)
                end
            end
            if #frames >= 2 then
                playerSide = frames[1]
                otherSide = frames[2]
            end
        end
        
        -- Подсчет предметов и валюты для игрока
        if playerSide then
            for _, item in pairs(playerSide:GetDescendants()) do
                if (item:IsA("Frame") or item:IsA("ImageLabel")) and item.Name:find("Item") then
                    local nameLabel = item:FindFirstChild("NameLabel")
                    if nameLabel and nameLabel:IsA("TextLabel") then
                        local price = getItemValue(nameLabel.Text)
                        if price > 0 then
                            playerItemsTotal = playerItemsTotal + price
                        end
                    end
                end
            end
            playerCurrency = getSideCurrency(playerSide)
        end
        
        -- Подсчет предметов и валюты для соперника
        if otherSide then
            for _, item in pairs(otherSide:GetDescendants()) do
                if (item:IsA("Frame") or item:IsA("ImageLabel")) and item.Name:find("Item") then
                    local nameLabel = item:FindFirstChild("NameLabel")
                    if nameLabel and nameLabel:IsA("TextLabel") then
                        local price = getItemValue(nameLabel.Text)
                        if price > 0 then
                            otherItemsTotal = otherItemsTotal + price
                        end
                    end
                end
            end
            otherCurrency = getSideCurrency(otherSide)
        end
        
        local playerTotal = playerItemsTotal + playerCurrency
        local otherTotal = otherItemsTotal + otherCurrency
        local diff = playerTotal - otherTotal
        
        -- Создание отображения
        local totalFrame = tradeFrame:FindFirstChild("TotalValuesDisplay")
        if not totalFrame then
            totalFrame = Instance.new("Frame")
            totalFrame.Name = "TotalValuesDisplay"
            totalFrame.Size = UDim2.new(1, 0, 0, 60)
            totalFrame.Position = UDim2.new(0, 0, 0, 0)
            totalFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0, 200)
            totalFrame.ZIndex = 20
            totalFrame.Parent = tradeFrame
        end
        
        local totalLabel = totalFrame:FindFirstChild("TotalLabel")
        if not totalLabel then
            totalLabel = Instance.new("TextLabel")
            totalLabel.Name = "TotalLabel"
            totalLabel.Size = UDim2.new(1, 0, 0.5, 0)
            totalLabel.Position = UDim2.new(0, 0, 0, 0)
            totalLabel.BackgroundTransparency = 1
            totalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            totalLabel.TextScaled = true
            totalLabel.Font = Enum.Font.GothamBold
            totalLabel.Parent = totalFrame
        end
        
        local detailLabel = totalFrame:FindFirstChild("DetailLabel")
        if not detailLabel then
            detailLabel = Instance.new("TextLabel")
            detailLabel.Name = "DetailLabel"
            detailLabel.Size = UDim2.new(1, 0, 0.5, 0)
            detailLabel.Position = UDim2.new(0, 0, 0.5, 0)
            detailLabel.BackgroundTransparency = 1
            detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            detailLabel.TextScaled = true
            detailLabel.Font = Enum.Font.Gotham
            detailLabel.Parent = totalFrame
        end
        
        local diffText = diff > 0 and "✅ +" or diff < 0 and "❌ " or "⚖️ "
        local diffColor = diff > 0 and Color3.fromRGB(0, 255, 0) or diff < 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 0)
        
        totalLabel.Text = string.format("👤 Вы: %d  |  👥 Соперник: %d  |  %s%d", 
            playerTotal, otherTotal, diffText, math.abs(diff))
        totalLabel.TextColor3 = diffColor
        
        detailLabel.Text = string.format("(Предметы: %d + Валюта: %d)  |  (Предметы: %d + Валюта: %d)",
            playerItemsTotal, playerCurrency, otherItemsTotal, otherCurrency)
        
        totalFrame.Visible = true
    end
    
    updateAllPrices()
    
    -- Отслеживание изменений
    local function onTradeUpdate()
        if isEnabled and tradeFrame and tradeFrame.Visible then
            updateAllPrices()
        end
    end
    
    local descConnection = tradeFrame.DescendantAdded:Connect(function(desc)
        if isEnabled and desc:IsA("ImageLabel") and desc.Name:find("Item") then
            task.wait(0.1)
            displayPriceOnItem(desc.Parent)
            updateTotalValues()
        end
    end)
    
    local visibleConnection = tradeFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if tradeFrame.Visible and isEnabled then
            task.wait(0.2)
            updateAllPrices()
        end
    end)
    
    tradeOverlay = overlay
    overlay._connections = {descConnection, visibleConnection}
    
    print("[MM2 Helper] Оверлей создан успешно")
end

-- Основной цикл обновления
local function startUpdateLoop()
    RunService.Heartbeat:Connect(function(deltaTime)
        if isEnabled then
            updateTimer = updateTimer + deltaTime
            if updateTimer >= CONFIG.UPDATE_INTERVAL then
                updateTimer = 0
                task.spawn(function()
                    local success = fetchValues()
                    if success then
                        if tradeOverlay then
                            createTradeOverlay()
                        end
                    end
                end)
            end
        end
    end)
end

-- Инициализация
local function initialize()
    print("[MM2 Helper] Инициализация...")
    
    task.spawn(function()
        local success = fetchValues()
        if success then
            print("[MM2 Helper] Цены загружены успешно")
        else
            print("[MM2 Helper] Использую кешированные цены")
        end
    end)
    
    createMainGUI()
    startUpdateLoop()
    
    PlayerGui.DescendantAdded:Connect(function(desc)
        if isEnabled and desc:IsA("Frame") and desc.Visible then
            if desc.Name:find("Trade") or desc.Name:find("trading") or desc.Name:find("offer") then
                task.wait(0.5)
                createTradeOverlay()
            end
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        if isEnabled and not tradeOverlay then
            local tradeFrame = findTradeWindow()
            if tradeFrame then
                createTradeOverlay()
            end
        end
    end)
    
    print("[MM2 Helper] Готов к работе!")
end

-- Запуск
initialize()

-- Очистка
Player.PlayerRemoving:Connect(function()
    if mainGui then
        mainGui:Destroy()
    end
    if tradeOverlay then
        tradeOverlay:Destroy()
    end
end)
