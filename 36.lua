-- Оптимизированный FE Dropkick скрипт для мобильного экспорта Delta
-- Без визуальных эффектов, минимальная нагрузка

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Настройки дропкика
local DROPKICK_SETTINGS = {
    Range = 6,              -- Дальность удара
    Damage = 25,            -- Урон
    KnockbackForce = 50,    -- Сила отбрасывания
    Cooldown = 1.5,         -- Задержка между ударами
    JumpPower = 30,         -- Сила прыжка при дропкике
    AnimationLength = 0.4,  -- Длина анимации
    Enabled = true          -- Включен ли скрипт
}

-- Переменные состояния
local cooldown = false
local isDropping = false
local debounce = false

-- Создаем удаленный событие (для FE)
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "DropkickEvent"
remoteEvent.Parent = ReplicatedStorage

-- Функция для получения ближайшего игрока
local function getNearestPlayer()
    local nearest = nil
    local minDist = DROPKICK_SETTINGS.Range + 1
    
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player then
            local targetChar = target.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild("Humanoid") then
                local targetHumanoid = targetChar.Humanoid
                if targetHumanoid.Health > 0 then
                    local dist = (rootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        nearest = target
                        minDist = dist
                    end
                end
            end
        end
    end
    
    return nearest
end

-- Выполнение дропкика
local function performDropkick()
    if not DROPKICK_SETTINGS.Enabled then return end
    if cooldown or isDropping or debounce then return end
    if not rootPart or not humanoid then return end
    
    local target = getNearestPlayer()
    if not target then return end
    
    local targetChar = target.Character
    if not targetChar then return end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetChar:FindFirstChild("Humanoid")
    if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then return end
    
    -- Блокировка
    cooldown = true
    isDropping = true
    debounce = true
    
    -- Направление к цели
    local direction = (targetRoot.Position - rootPart.Position).Unit
    local distance = (targetRoot.Position - rootPart.Position).Magnitude
    
    -- Прыжок к цели
    humanoid.JumpPower = DROPKICK_SETTINGS.JumpPower
    humanoid:Jump()
    
    -- Применяем скорость к игроку
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
    bodyVelocity.Velocity = direction * (DROPKICK_SETTINGS.KnockbackForce + 20)
    bodyVelocity.Parent = rootPart
    
    -- Таймер анимации
    task.wait(DROPKICK_SETTINGS.AnimationLength)
    
    -- Нанесение урона и отбрасывание цели
    if targetHumanoid.Health > 0 then
        -- Урон
        targetHumanoid.Health = math.max(0, targetHumanoid.Health - DROPKICK_SETTINGS.Damage)
        
        -- Отбрасывание
        local targetVelocity = Instance.new("BodyVelocity")
        targetVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        targetVelocity.Velocity = direction * DROPKICK_SETTINGS.KnockbackForce + Vector3.new(0, 10, 0)
        targetVelocity.Parent = targetRoot
        
        -- Чистим через 0.5 сек
        task.delay(0.5, function()
            if targetVelocity then targetVelocity:Destroy() end
        end)
        
        -- Отправка события (для синхронизации)
        remoteEvent:FireServer(target)
    end
    
    -- Чистим телоскорость
    task.delay(0.3, function()
        if bodyVelocity then bodyVelocity:Destroy() end
    end)
    
    -- Разблокировка
    task.wait(DROPKICK_SETTINGS.Cooldown - DROPKICK_SETTINGS.AnimationLength)
    cooldown = false
    isDropping = false
    debounce = false
end

-- Обработка ввода (тап)
UserInputService.TouchTapInWorld:Connect(function()
    performDropkick()
end)

-- Для ПК тестирования (можно удалить для мобильной версии)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        performDropkick()
    end
end)

-- Переподключение при респе
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    cooldown = false
    isDropping = false
    debounce = false
end)

-- Очистка памяти
RunService.Heartbeat:Connect(function()
    if rootPart and rootPart:FindFirstChildOfClass("BodyVelocity") then
        local bv = rootPart:FindFirstChildOfClass("BodyVelocity")
        if bv and bv.Velocity.Magnitude < 1 then
            bv:Destroy()
        end
    end
end)

print("FE Dropkick скрипт загружен (Без визуала, оптимизирован для Delta)")
