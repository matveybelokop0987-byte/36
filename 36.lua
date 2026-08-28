--[[
    Оптимизированный скрипт Godly Handler для Murder Mystery 2 (Delta Mobile)
    Особенности:
    - UI с списком годли из MM2
    - Выдача годли в инвентарь (видимо для всех)
    - Временные годли (пропадают при выходе)
    - Оптимизация под мобильные устройства
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Конфигурация годли MM2 (актуальные ID)
local GODLY_ITEMS = {
    {name = "Chroma Darkbringer", id = "4734157094"},
    {name = "Chroma Lightbringer", id = "4734155276"},
    {name = "Chroma Luger", id = "4734153587"},
    {name = "Chroma Saw", id = "4734151766"},
    {name = "Chroma Shark", id = "4734150439"},
    {name = "Chroma Heat", id = "4734148801"},
    {name = "Chroma Fang", id = "4734147069"},
    {name = "Chroma Gemstone", id = "4734145468"},
    {name = "Chroma Slasher", id = "4734143273"},
    {name = "Chroma Tides", id = "4734141193"},
    {name = "Darkbringer", id = "4734139365"},
    {name = "Lightbringer", id = "4734137662"},
    {name = "Luger", id = "4734135855"},
    {name = "Saw", id = "4734133728"},
    {name = "Shark", id = "4734131521"},
    {name = "Heat", id = "4734129577"},
    {name = "Fang", id = "4734127318"},
    {name = "Gemstone", id = "4734125235"},
    {name = "Slasher", id = "4734123112"},
    {name = "Tides", id = "4734120576"},
}

-- Создаём ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GodlyHandler"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Главное окно
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 500)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Сглаживание углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
titleBar.BackgroundTransparency = 0.1
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔫 MM2 Godly Handler"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleBar

-- Кнопка сворачивания
local minimizeBtn = Instance.new("ImageButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
minimizeBtn.BackgroundTransparency = 0.3
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Image = "rbxassetid://6031090979"
minimizeBtn.Parent = titleBar

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = minimizeBtn

-- Поисковая строка
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 35)
searchBox.Position = UDim2.new(0, 10, 0, 45)
searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
searchBox.BackgroundTransparency = 0.3
searchBox.BorderSizePixel = 1
searchBox.BorderColor3 = Color3.fromRGB(255, 215, 0)
searchBox.PlaceholderText = "🔍 Поиск годли..."
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.TextScaled = true
searchBox.Font = Enum.Font.Gotham
searchBox.Parent = mainFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

-- Список годли
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -100)
listFrame.Position = UDim2.new(0, 10, 0, 90)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.ScrollBarThickness = 4
listFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- Хранилище элементов для поиска
local allItems = {}

-- Функция получения годли в инвентарь MM2
local function giveGodly(itemName, itemId)
    -- Проверяем есть ли уже такой предмет в инвентаре
    local hasItem = false
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name == itemName then
            hasItem = true
            break
        end
    end
    
    if hasItem then
        StarterGui:SetCore("SendNotification", {
            Title = "⚠️ Уже есть",
            Text = "У вас уже есть " .. itemName,
            Duration = 2
        })
        return
    end
    
    -- Создаём инструмент с правильными свойствами для MM2
    local tool = Instance.new("Tool")
    tool.Name = itemName
    tool.RequiresHandle = true
    tool.CanBeDropped = true
    tool.ToolTip = itemName
    
    -- Создаём Handle (меш)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 2)
    handle.Position = Vector3.new(0, 1000, 0) -- Скрываем
    handle.Anchored = true
    handle.CanCollide = false
    handle.Transparency = 1
    handle.Parent = tool
    
    -- Добавляем MeshId для отображения
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://" .. tostring(itemId)
    mesh.Scale = Vector3.new(1, 1, 1)
    mesh.Parent = handle
    
    -- Добавляем тег временного предмета
    local tempTag = Instance.new("BoolValue")
    tempTag.Name = "IsTemporaryGodly"
    tempTag.Value = true
    tempTag.Parent = tool
    
    -- Добавляем в инвентарь
    tool.Parent = player.Backpack
    
    -- Добавляем в руку если можно
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        if not humanoid:FindFirstChild("ActiveTool") then
            humanoid:EquipTool(tool)
        end
    end
    
    -- Уведомление
    StarterGui:SetCore("SendNotification", {
        Title = "✅ Получено!",
        Text = itemName .. " добавлен в инвентарь (временно)",
        Duration = 2
    })
    
    -- Звук получения
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9120383275"
    sound.Volume = 0.5
    sound.Parent = tool
    sound:Play()
    task.delay(0.5, function()
        sound:Destroy()
    end)
end

-- Создание элемента годли
local function createGodlyItem(data)
    local itemFrame = Instance.new("TextButton")
    itemFrame.Size = UDim2.new(1, 0, 0, 55)
    itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    itemFrame.BackgroundTransparency = 0.3
    itemFrame.BorderSizePixel = 1
    itemFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
    itemFrame.Text = ""
    itemFrame.Parent = listFrame

    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame

    -- Иконка годли (изображение)
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 5, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. tostring(data.id)
    icon.Parent = itemFrame

    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, -60, 1, 0)
    itemLabel.Position = UDim2.new(0, 50, 0, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = data.name
    itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemLabel.TextScaled = true
    itemLabel.Font = Enum.Font.GothamBold
    itemLabel.Parent = itemFrame

    -- Кнопка получения
    local getBtn = Instance.new("TextButton")
    getBtn.Size = UDim2.new(0, 80, 0, 35)
    getBtn.Position = UDim2.new(1, -90, 0.5, -17.5)
    getBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    getBtn.BackgroundTransparency = 0.2
    getBtn.BorderSizePixel = 0
    getBtn.Text = "Получить"
    getBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    getBtn.TextScaled = true
    getBtn.Font = Enum.Font.GothamBold
    getBtn.Parent = itemFrame

    local getCorner = Instance.new("UICorner")
    getCorner.CornerRadius = UDim.new(0, 6)
    getCorner.Parent = getBtn

    -- Получение при нажатии
    getBtn.MouseButton1Click:Connect(function()
        giveGodly(data.name, data.id)
        
        -- Анимация кнопки
        TweenService:Create(getBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        }):Play()
        task.wait(0.1)
        TweenService:Create(getBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        }):Play()
    end)

    -- Анимация при наведении
    itemFrame.MouseEnter:Connect(function()
        TweenService:Create(itemFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.1
        }):Play()
    end)

    itemFrame.MouseLeave:Connect(function()
        TweenService:Create(itemFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3
        }):Play()
    end)

    return itemFrame
end

-- Заполнение списка
for _, godly in ipairs(GODLY_ITEMS) do
    local item = createGodlyItem(godly)
    table.insert(allItems, {frame = item, name = godly.name})
end

-- Обновление CanvasSize
local function updateCanvas()
    listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.wait(0.1)
updateCanvas()

-- Поиск годли
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = searchBox.Text:lower()
    for _, item in pairs(allItems) do
        if searchText == "" or item.name:lower():find(searchText) then
            item.frame.Visible = true
        else
            item.frame.Visible = false
        end
    end
    task.wait(0.05)
    updateCanvas()
end)

-- Сворачивание
local minimizedFrame = Instance.new("Frame")
minimizedFrame.Name = "MinimizedFrame"
minimizedFrame.Size = UDim2.new(0, 60, 0, 60)
minimizedFrame.Position = UDim2.new(0.9, -80, 0.85, 0)
minimizedFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
minimizedFrame.BackgroundTransparency = 0.1
minimizedFrame.BorderSizePixel = 2
minimizedFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
minimizedFrame.Visible = false
minimizedFrame.Active = true
minimizedFrame.Draggable = true
minimizedFrame.Parent = screenGui

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 12)
minCorner.Parent = minimizedFrame

local minLabel = Instance.new("TextLabel")
minLabel.Size = UDim2.new(1, 0, 1, 0)
minLabel.BackgroundTransparency = 1
minLabel.Text = "🔫"
minLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
minLabel.TextScaled = true
minLabel.Font = Enum.Font.GothamBold
minLabel.Parent = minimizedFrame

-- Переключение между окнами
local isMinimized = false

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    mainFrame.Visible = not isMinimized
    minimizedFrame.Visible = isMinimized
    
    if isMinimized then
        minimizedFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(minimizedFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 60, 0, 60)
        }):Play()
    end
end)

minimizedFrame.MouseButton1Click:Connect(function()
    isMinimized = false
    mainFrame.Visible = true
    minimizedFrame.Visible = false
    
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 350, 0, 500),
        Position = UDim2.new(0.5, -175, 0.5, -250)
    }):Play()
end)

-- Обработка выхода (удаление временных годли)
local function removeTemporaryGodlies()
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("IsTemporaryGodly") then
            item:Destroy()
        end
    end
end

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    removeTemporaryGodlies()
end)

player:GetPropertyChangedSignal("Character"):Connect(function()
    if not player.Character then
        removeTemporaryGodlies()
    end
end)

-- Оптимизация для мобильных
if UserInputService.TouchEnabled then
    minimizeBtn.Size = UDim2.new(0, 45, 0, 45)
    minimizeBtn.Position = UDim2.new(1, -55, 0.5, -22.5)
    searchBox.Size = UDim2.new(1, -20, 0, 45)
    
    for _, child in pairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child.Size = UDim2.new(1, 0, 0, 65)
            local btn = child:FindFirstChildWhichIsA("TextButton")
            if btn then
                btn.Size = UDim2.new(0, 100, 0, 45)
            end
        end
    end
end

print("✅ MM2 Godly Handler загружен!")
print("📦 Всего годли: " .. #GODLY_ITEMS)
