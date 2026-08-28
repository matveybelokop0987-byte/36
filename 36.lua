--[[
    Оптимизированный скрипт Godly Handler для мобильного Delta
    Особенности:
    - UI с списком годли
    - Сворачивание в квадратик
    - Выдача годли при клике (временная, пропадает при выходе)
    - Оптимизация под мобильные устройства
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Конфигурация годли (добавляй свои)
local GODLY_ITEMS = {
    {name = "Godly Sword", id = "1234567890"},
    {name = "Godly Gun", id = "0987654321"},
    {name = "Godly Shield", id = "1122334455"},
    {name = "Godly Bow", id = "5566778899"},
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
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 255)
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Сглаживание углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Заголовок с кнопкой сворачивания
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "✨ Godly Handler"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleBar

-- Кнопка сворачивания
local minimizeBtn = Instance.new("ImageButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
minimizeBtn.BackgroundTransparency = 0.5
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Image = "rbxassetid://6031090979" -- Иконка свернуть
minimizeBtn.Parent = titleBar

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = minimizeBtn

-- Список годли
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -60)
listFrame.Position = UDim2.new(0, 10, 0, 50)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.ScrollBarThickness = 4
listFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- Создание элементов годли
local function createGodlyItem(data, index)
    local itemFrame = Instance.new("TextButton")
    itemFrame.Size = UDim2.new(1, 0, 0, 50)
    itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    itemFrame.BackgroundTransparency = 0.3
    itemFrame.BorderSizePixel = 1
    itemFrame.BorderColor3 = Color3.fromRGB(150, 150, 255)
    itemFrame.Text = ""
    itemFrame.Parent = listFrame

    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = itemFrame

    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, -20, 1, 0)
    itemLabel.Position = UDim2.new(0, 10, 0, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = data.name .. " (Нажми для получения)"
    itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemLabel.TextScaled = true
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.Parent = itemFrame

    -- Анимация при нажатии
    itemFrame.MouseButton1Click:Connect(function()
        -- Анимация нажатия
        local tween = TweenService:Create(itemFrame, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(80, 80, 120)
        })
        tween:Play()
        tween.Completed:Connect(function()
            TweenService:Create(itemFrame, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            }):Play()
        end)

        -- Выдача годли (временная)
        local tempItem = Instance.new("Tool")
        tempItem.Name = data.name
        tempItem.RequiresHandle = false
        tempItem.Parent = player.Backpack

        -- Добавляем тег временного предмета
        local tempTag = Instance.new("BoolValue")
        tempTag.Name = "IsTemporaryGodly"
        tempTag.Value = true
        tempTag.Parent = tempItem

        -- Уведомление
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 300, 0, 50)
        notif.Position = UDim2.new(0.5, -150, 0.85, 0)
        notif.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        notif.BackgroundTransparency = 0.2
        notif.Text = "✅ Получено: " .. data.name .. " (временно)"
        notif.TextColor3 = Color3.fromRGB(255, 255, 255)
        notif.TextScaled = true
        notif.Font = Enum.Font.GothamBold
        notif.Parent = screenGui

        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notif

        -- Авто-удаление уведомления
        task.delay(2, function()
            TweenService:Create(notif, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
                TextTransparency = 1
            }):Play()
            task.wait(0.5)
            notif:Destroy()
        end)
    end)

    return itemFrame
end

-- Заполнение списка
for i, godly in ipairs(GODLY_ITEMS) do
    createGodlyItem(godly, i)
end

-- Обновление CanvasSize списка
local function updateCanvas()
    listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.wait(0.1)
updateCanvas()

-- Сворачивание в квадратик
local minimizedFrame = Instance.new("Frame")
minimizedFrame.Name = "MinimizedFrame"
minimizedFrame.Size = UDim2.new(0, 60, 0, 60)
minimizedFrame.Position = UDim2.new(0.9, -80, 0.85, 0)
minimizedFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
minimizedFrame.BackgroundTransparency = 0.1
minimizedFrame.BorderSizePixel = 2
minimizedFrame.BorderColor3 = Color3.fromRGB(100, 100, 255)
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
minLabel.Text = "✨"
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
    
    -- Анимация появления квадратика
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
    
    -- Анимация появления окна
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 350, 0, 500),
        Position = UDim2.new(0.5, -175, 0.5, -250)
    }):Play()
end)

-- Обработка выхода игрока (удаление временных годли)
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    -- Удаляем все временные годли при респавне
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("IsTemporaryGodly") then
            item:Destroy()
        end
    end
end)

-- Очистка при выходе
player:GetPropertyChangedSignal("Character"):Connect(function()
    if not player.Character then
        for _, item in pairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("IsTemporaryGodly") then
                item:Destroy()
            end
        end
    end
end)

-- Оптимизация для мобильных устройств
if UserInputService.TouchEnabled then
    -- Увеличиваем размер кнопок для touch
    minimizeBtn.Size = UDim2.new(0, 45, 0, 45)
    minimizeBtn.Position = UDim2.new(1, -55, 0.5, -22.5)
    
    -- Увеличиваем элементы списка
    for _, child in pairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child.Size = UDim2.new(1, 0, 0, 60)
        end
    end
end

print("✅ Godly Handler загружен!")
