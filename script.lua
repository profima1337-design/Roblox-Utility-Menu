-- Защита от дубликатов интерфейса
if game.CoreGui:FindFirstChild("PremiumHub_GUI") then
    game.CoreGui.PremiumHub_GUI:Destroy()
end
if workspace:FindFirstChild("PremiumCheckpoint_Marker") then
    workspace.PremiumCheckpoint_Marker:Destroy()
end

-- Основные сервисы
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Цветовая схема
local BG_COLOR = Color3.fromRGB(12, 15, 18)
local PANEL_COLOR = Color3.fromRGB(18, 22, 26)
local ACCENT_COLOR = Color3.fromRGB(0, 210, 210)
local ACCENT_GLOW = Color3.fromRGB(0, 255, 255)
local OFF_COLOR = Color3.fromRGB(255, 70, 70)
local ON_COLOR = Color3.fromRGB(0, 210, 120)
local TEXT_COLOR = Color3.fromRGB(240, 245, 245)
local MUTED_TEXT = Color3.fromRGB(110, 125, 125)
local BUTTON_COLOR = Color3.fromRGB(24, 30, 36)

-- Настройки меню
local toggleKey = Enum.KeyCode.RightShift
local menuVisible = true
local isTweening = false

-- Глобальный счётчик для соблюдения порядка элементов (LayoutOrder)
local layoutCounter = 0

-- Конфигурация функций
local flyActive = false
local flySpeed = 50
local minSpeed = 10
local maxSpeed = 300
local flyKey = Enum.KeyCode.LeftControl
local bodyVelocity, bodyGyro
local noclipConnection
local savedCFrame = nil
local markerInstance = nil

local speedEnabled = false
local speedValue = 16
local speedKey = Enum.KeyCode.Unknown 

local espEnabled = false
local espTeamCheck = true

-- Конфигурация Аимбота (Фикс наведения)
local aimbotEnabled = false
local aimbotTeamCheck = true
local aimbotSmooth = 4 -- Плавность (чем выше, тем плавнее)
local aimbotKey = Enum.KeyCode.E
local aimbotTarget = "Head"
local isAiming = false
local maxAimDistance = 300
local fovRadius = 120
local fovVisible = false
local fovColor = Color3.fromRGB(0, 255, 255)

-- Инициализация FOV
local fovCircle = nil
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Transparency = 0.7
    end
end)

-- Уведомления
local function showNotification(text)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 260, 0, 42)
    notif.Position = UDim2.new(1, 20, 0, 20)
    notif.BackgroundColor3 = BG_COLOR
    notif.BorderSizePixel = 0
    notif.Parent = screenGui
    
    local nc = Instance.new("UICorner") nc.CornerRadius = UDim.new(0, 8) nc.Parent = notif
    local ns = Instance.new("UIStroke") ns.Color = ACCENT_COLOR ns.Thickness = 1.5 ns.Parent = notif
    
    local nt = Instance.new("TextLabel")
    nt.Size = UDim2.new(1, -15, 1, 0)
    nt.Position = UDim2.new(0, 12, 0, 0)
    nt.BackgroundTransparency = 1
    nt.Text = text
    nt.TextColor3 = TEXT_COLOR
    nt.Font = Enum.Font.GothamMedium
    nt.TextSize = 12
    nt.TextXAlignment = Enum.TextXAlignment.Left
    nt.Parent = notif
    
    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -280, 0, 20)}):Play()
    task.delay(2.5, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 0, 20)}):Play()
            task.wait(0.3) notif:Destroy()
        end
    end)
end

-- Интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PremiumHub_GUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 520, 0, 340)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
mainFrame.BackgroundColor3 = BG_COLOR
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 12) mc.Parent = mainFrame
local ms = Instance.new("UIStroke") ms.Color = ACCENT_COLOR ms.Thickness = 1.5 ms.Parent = mainFrame

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, 0)
sidebar.BackgroundColor3 = PANEL_COLOR
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 12) sc.Parent = sidebar

local sideTitle = Instance.new("TextLabel")
sideTitle.Size = UDim2.new(1, 0, 0, 55)
sideTitle.BackgroundTransparency = 1
sideTitle.Text = "PROFIMA\nPREMIUM"
sideTitle.TextColor3 = ACCENT_GLOW
sideTitle.Font = Enum.Font.GothamBold
sideTitle.TextSize = 13
sideTitle.Parent = sidebar

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -150, 1, -20)
contentContainer.Position = UDim2.new(0, 140, 0, 10)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local tabs = {
    About = Instance.new("Frame"),
    Combat = Instance.new("Frame"),
    Visuals = Instance.new("Frame"),
    SpeedHack = Instance.new("Frame"),
    Misc = Instance.new("Frame")
}

for name, frame in pairs(tabs) do
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (name == "About")
    frame.Parent = contentContainer
end

local function createScrollContent(parentFrame)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = ACCENT_COLOR
    sf.Parent = parentFrame

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder -- Включаем сортировку по LayoutOrder!
    lay.Parent = sf

    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 20)
    end)
    return sf
end

local combatScroll = createScrollContent(tabs.Combat)
local visualsScroll = createScrollContent(tabs.Visuals)
local speedScroll = createScrollContent(tabs.SpeedHack)
local miscScroll = createScrollContent(tabs.Misc)

-- ФУНКЦИИ-КОНСТРУКТОРЫ С АВТО-ПОРЯДКОМ
local function createSectionTitle(text, parent)
    layoutCounter = layoutCounter + 1
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 26)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutCounter
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "[ " .. string.upper(text) .. " ]"
    label.TextColor3 = ACCENT_GLOW
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    return container
end

local function createToggle(text, defaultState, parent, callback)
    layoutCounter = layoutCounter + 1
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 36)
    container.BackgroundColor3 = BUTTON_COLOR
    container.LayoutOrder = layoutCounter
    container.Parent = parent
    local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 6) cc.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 210, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = TEXT_COLOR
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 22)
    btn.Position = UDim2.new(1, -67, 0.5, -11)
    btn.BackgroundColor3 = defaultState and ON_COLOR or OFF_COLOR
    btn.Text = defaultState and "ВКЛ" or "ВЫКЛ"
    btn.TextColor3 = BG_COLOR
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = container
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = btn

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and ON_COLOR or OFF_COLOR
        btn.Text = state and "ВКЛ" or "ВЫКЛ"
        callback(state)
    end)
    return container
end

local function createBindButton(prefix, currentKey, parent, callback)
    layoutCounter = layoutCounter + 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -5, 0, 36)
    btn.BackgroundColor3 = BUTTON_COLOR
    btn.Text = prefix .. "  (" .. currentKey.Name .. ")"
    btn.TextColor3 = TEXT_COLOR
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.LayoutOrder = layoutCounter
    btn.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn

    local isListening = false
    btn.MouseButton1Click:Connect(function()
        if isListening then return end
        isListening = true
        btn.Text = "Нажмите клавишу..."
        btn.TextColor3 = ACCENT_COLOR
        
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                btn.Text = prefix .. "  (" .. input.KeyCode.Name .. ")"
                btn.TextColor3 = TEXT_COLOR
                isListening = false
                conn:Disconnect()
                callback(input.KeyCode)
            end
        end)
    end)
    return btn
end

local function createSlider(text, min, max, default, parent, callback)
    layoutCounter = layoutCounter + 1
    local pnl = Instance.new("Frame")
    pnl.Size = UDim2.new(1, -5, 0, 52)
    pnl.BackgroundTransparency = 1
    pnl.LayoutOrder = layoutCounter
    pnl.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 160, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = TEXT_COLOR
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = pnl

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 50, 0, 18)
    box.Position = UDim2.new(1, -55, 0, 0)
    box.BackgroundColor3 = BUTTON_COLOR
    box.Text = tostring(default)
    box.TextColor3 = ACCENT_COLOR
    box.Font = Enum.Font.GothamBold
    box.TextSize = 11
    box.Parent = pnl
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = box

    local trk = Instance.new("Frame")
    trk.Size = UDim2.new(1, 0, 0, 4)
    trk.Position = UDim2.new(0, 0, 0, 32)
    trk.BackgroundColor3 = BUTTON_COLOR
    trk.Parent = pnl
    local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(1, 0) tc.Parent = trk

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = ACCENT_COLOR
    fill.Parent = trk
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(1, 0) fc.Parent = fill

    local sBtn = Instance.new("TextButton")
    sBtn.Size = UDim2.new(0, 12, 0, 12)
    sBtn.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    sBtn.BackgroundColor3 = TEXT_COLOR
    sBtn.Text = ""
    sBtn.Parent = trk
    local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(1, 0) sbc.Parent = sBtn

    local dragging = false
    local val = default

    local function update(perc)
        perc = math.clamp(perc, 0, 1)
        val = math.round(min + (perc * (max - min)))
        box.Text = tostring(val)
        fill.Size = UDim2.new(perc, 0, 1, 0)
        sBtn.Position = UDim2.new(perc, -6, 0.5, -6)
        callback(val)
    end

    sBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update((i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X)
        end
    end)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then val = math.clamp(math.round(n), min, max) update((val - min) / (max - min)) else box.Text = tostring(val) end
    end)
end

-- ==========================================
-- ЗАПОЛНЕНИЕ НАСТРОЕК (СТРОГИЙ ПОРЯДОК)
-- ==========================================

-- COMBAT (AIMBOT)
layoutCounter = 0
createSectionTitle("Параметры Аимбота", combatScroll)
createToggle("Включить Аимбот", aimbotEnabled, combatScroll, function(v) aimbotEnabled = v end)
createToggle("Аимбот: Проверка команды", aimbotTeamCheck, combatScroll, function(v) aimbotTeamCheck = v end)
createSlider("Скорость наведения (Smooth)", 1, 20, aimbotSmooth, combatScroll, function(v) aimbotSmooth = v end)
createBindButton("Бинд кнопки удержания Аима", aimbotKey, combatScroll, function(k) aimbotKey = k end)
createSectionTitle("Настройка FOV Круга", combatScroll)
createToggle("Отображать круг FOV", fovVisible, combatScroll, function(v) fovVisible = v end)
createSlider("Размер (Радиус) FOV круга", 30, 400, fovRadius, combatScroll, function(v) fovRadius = v end)

-- VISUALS
layoutCounter = 0
createSectionTitle("ESP Модули", visualsScroll)
createToggle("Включить ВХ (Highlight)", espEnabled, visualsScroll, function(v) espEnabled = v end)
createToggle("ESP: Проверка команды", espTeamCheck, visualsScroll, function(v) espTeamCheck = v end)

-- SPEEDHACK
layoutCounter = 0
createSectionTitle("Модули Скорости", speedScroll)
createToggle("Включить Быстрый бег", speedEnabled, speedScroll, function(v) speedEnabled = v end)
createSlider("Скорость бега (Speed)", 16, 300, speedValue, speedScroll, function(v) speedValue = v end)
createBindButton("Бинд активации Спидхака", speedKey, speedScroll, function(k) speedKey = k end)

-- MISC (ИСПРАВЛЕННЫЙ СДВИГ: ЗАГОЛОВОК -> МОДУЛЬ)
layoutCounter = 0

createSectionTitle("Модули Полета", miscScroll)
createToggle("Включить функцию FLY", flyActive, miscScroll, function(v) if flyActive ~= v then toggleFly() end end)
createSlider("Скорость полета", minSpeed, maxSpeed, flySpeed, miscScroll, function(v) flySpeed = v end)
createBindButton("Бинд клавиши полета", flyKey, miscScroll, function(k) flyKey = k end)

createSectionTitle("Функция Чекпоинт", miscScroll)
layoutCounter = layoutCounter + 1
local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -5, 0, 38)
saveBtn.BackgroundColor3 = BUTTON_COLOR
saveBtn.Text = "СОХРАНИТЬ ЧЕКПОИНТ"
saveBtn.TextColor3 = TEXT_COLOR
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 12
saveBtn.LayoutOrder = layoutCounter
saveBtn.Parent = miscScroll
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

layoutCounter = layoutCounter + 1
local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(1, -5, 0, 38)
tpBtn.BackgroundColor3 = BUTTON_COLOR
tpBtn.Text = "ТЕЛЕПОРТИРОВАТЬСЯ К ТОЧКЕ"
tpBtn.TextColor3 = TEXT_COLOR
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 12
tpBtn.LayoutOrder = layoutCounter
tpBtn.Parent = miscScroll
Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

createSectionTitle("Премиум Инструменты", miscScroll)
layoutCounter = layoutCounter + 1
local tptoolBtn = Instance.new("TextButton")
tptoolBtn.Size = UDim2.new(1, -5, 0, 36)
tptoolBtn.BackgroundColor3 = BUTTON_COLOR
tptoolBtn.Text = "Выдать TP Tool"
tptoolBtn.TextColor3 = ACCENT_COLOR
tptoolBtn.Font = Enum.Font.GothamMedium
tptoolBtn.TextSize = 12
tptoolBtn.LayoutOrder = layoutCounter
tptoolBtn.Parent = miscScroll
Instance.new("UICorner", tptoolBtn).CornerRadius = UDim.new(0, 6)

createSectionTitle("Настройки Меню", miscScroll)
createBindButton("Бинд скрытия интерфейса", toggleKey, miscScroll, function(k) toggleKey = k end)

-- ABOUT
local aboutLabel = Instance.new("TextLabel")
aboutLabel.Size = UDim2.new(1, -10, 1, 0)
aboutLabel.Position = UDim2.new(0, 5, 0, 0)
aboutLabel.BackgroundTransparency = 1
aboutLabel.Text = "PROFIMA PREMIUM HUB\n\nИсправления:\n- Полностью восстановлен верный порядок категорий и их функций во вкладке Разное.\n- Переработан алгоритм Аимбота (исправлено наведение камеры по вектору и добавлена проверка прямой видимости Сharacter)."
aboutLabel.TextColor3 = TEXT_COLOR
aboutLabel.Font = Enum.Font.GothamMedium
aboutLabel.TextSize = 13
aboutLabel.TextWrapped = true
aboutLabel.TextYAlignment = Enum.TextYAlignment.Top
aboutLabel.Parent = tabs.About

-- ==========================================
-- ЛОГИКА МОДУЛЕЙ И ИСПРАВЛЕННЫЙ АИМБОТ
-- ==========================================

local function updateFlyButtonUI()
    for _, item in pairs(miscScroll:GetChildren()) do
        if item:IsA("Frame") and item:FindFirstChild("TextLabel") and string.find(item.TextLabel.Text, "FLY") then
            local btn = item:FindFirstChildOfClass("TextButton")
            if btn then
                btn.BackgroundColor3 = flyActive and ON_COLOR or OFF_COLOR
                btn.Text = flyActive and "ВКЛ" or "ВЫКЛ"
            end
        end
    end
end

function toggleFly()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    
    flyActive = not flyActive
    if flyActive then
        hum.PlatformStand = true
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.P = 9e4
        bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.cframe = root.CFrame
        bodyGyro.Parent = root

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.velocity = Vector3.new(0, 0.1, 0)
        bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Parent = root

        task.spawn(function()
            while flyActive and root and hum.Parent do
                local dir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
                
                bodyGyro.cframe = camera.CFrame
                bodyVelocity.velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.new(0, 0, 0)
                task.wait()
            end
        end)

        noclipConnection = RunService.Stepped:Connect(function()
            if char and flyActive then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
        showNotification("FLY: АКТИВИРОВАН")
    else
        if bodyGyro then bodyGyro:Destroy() end
        if bodyVelocity then bodyVelocity:Destroy() end
        if noclipConnection then noclipConnection:Disconnect() end
        hum.PlatformStand = false
        showNotification("FLY: ДЕАКТИВИРОВАН")
    end
end

-- Логика Чекпоинта (Маленькая неоновая сфера)
saveBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        savedCFrame = char.HumanoidRootPart.CFrame
        
        if markerInstance then markerInstance:Destroy() end
        
        markerInstance = Instance.new("Part")
        markerInstance.Name = "PremiumCheckpoint_Marker"
        markerInstance.Shape = Enum.PartType.Ball
        markerInstance.Size = Vector3.new(1.2, 1.2, 1.2)
        markerInstance.Color = Color3.fromRGB(0, 235, 255)
        markerInstance.Material = Enum.Material.Neon
        markerInstance.Anchored = true
        markerInstance.CanCollide = false
        markerInstance.Position = char.HumanoidRootPart.Position - Vector3.new(0, 1, 0)
        markerInstance.Parent = workspace
        
        saveBtn.Text = "✓ СФЕРА СОЗДАНА!"
        task.wait(1)
        saveBtn.Text = "СОХРАНИТЬ ЧЕКПОИНТ"
    end
end)

tpBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if savedCFrame then
            char.HumanoidRootPart.CFrame = savedCFrame
        else
            tpBtn.Text = "❌ НЕТ ТОЧКИ!"
            task.wait(1)
            tpBtn.Text = "ТЕЛЕПОРТИРОВАТЬСЯ К ТОЧКЕ"
        end
    end
end)

tptoolBtn.MouseButton1Click:Connect(function()
    local mouse = player:GetMouse()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "TP Tool"
    tool.Activated:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end)
    tool.Parent = player.Backpack
    showNotification("TP Tool добавлен в инвентарь!")
end)

-- Проверка препятствий (Wall Check) для Аимбота
local function isVisible(targetPart, character)
    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character, character}
    
    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
    return raycastResult == nil
end

-- ПОТОК СЛЕДОВАНИЯ И АИМБОТА (RenderStepped)
RunService.RenderStepped:Connect(function()
    -- Рендеринг FOV
    if fovCircle then
        if fovVisible and not menuVisible and aimbotEnabled then
            fovCircle.Visible = true
            fovCircle.Radius = fovRadius
            fovCircle.Position = UserInputService:GetMouseLocation()
            fovCircle.Color = fovColor
        else
            fovCircle.Visible = false
        end
    end

    -- Логика Аимбота (Фикс наведения камеры)
    if aimbotEnabled and isAiming and not menuVisible then
        local closestTarget = nil
        local maxDistanceFOV = fovVisible and fovRadius or 999992
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild(aimbotTarget) and p.Character:FindFirstChildOfClass("Humanoid") then
                if p.Character.Humanoid.Health > 0 and not (aimbotTeamCheck and p.Team == player.Team) then
                    local part = p.Character[aimbotTarget]
                    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    
                    if myRoot and (myRoot.Position - part.Position).Magnitude <= maxAimDistance then
                        if isVisible(part, p.Character) then
                            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local mouseLocation = UserInputService:GetMouseLocation()
                                local distanceToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
                                
                                if distanceToMouse < maxDistanceFOV then
                                    maxDistanceFOV = distanceToMouse
                                    closestTarget = part
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if closestTarget then
            local targetCFrame = CFrame.new(camera.CFrame.Position, closestTarget.Position)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, 1 / aimbotSmooth)
        end
    end

    -- WalkSpeed
    local myChar = player.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        if speedEnabled then
            myHum.WalkSpeed = speedValue
        else
            if not flyActive and myHum.WalkSpeed == speedValue then
                myHum.WalkSpeed = 16
            end
        end
    end

    -- ESP Highlight
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local high = p.Character:FindFirstChild("PremiumESP")
            if espEnabled then
                if not (espTeamCheck and p.Team == player.Team) then
                    if not high then
                        high = Instance.new("Highlight")
                        high.Name = "PremiumESP"
                        high.FillColor = ACCENT_COLOR
                        high.OutlineColor = ACCENT_GLOW
                        high.FillTransparency = 0.4
                        high.Parent = p.Character
                    end
                else
                    if high then high:Destroy() end
                end
            else
                if high then high:Destroy() end
            end
        end
    end
end)

-- Обработчики клавиш
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == aimbotKey then isAiming = true end
    if input.KeyCode == flyKey then toggleFly() updateFlyButtonUI() end
    
    if input.KeyCode == speedKey and speedKey ~= Enum.KeyCode.Unknown then
        speedEnabled = not speedEnabled
        showNotification("SpeedHack: " .. (speedEnabled and "ВКЛ" or "ВЫКЛ"))
    end
    
    if input.KeyCode == toggleKey and not isTweening then
        isTweening = true
        menuVisible = not menuVisible
        if menuVisible then
            mainFrame.Visible = true
            local t = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 520, 0, 340), BackgroundTransparency = 0})
            t:Play() t.Completed:Wait()
        else
            local t = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 520, 0, 0), BackgroundTransparency = 1})
            t:Play() t.Completed:Wait()
            mainFrame.Visible = false
        end
        isTweening = false
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == aimbotKey then isAiming = false end
end)

-- Сборка сайдбара
local tabOrder = {"About", "Combat", "Visuals", "SpeedHack", "Misc"}
local tabBtnContainer = Instance.new("Frame")
tabBtnContainer.Size = UDim2.new(1, 0, 1, -65)
tabBtnContainer.Position = UDim2.new(0, 0, 0, 60)
tabBtnContainer.BackgroundTransparency = 1
tabBtnContainer.Parent = sidebar

local tabLay = Instance.new("UIListLayout")
tabLay.Padding = UDim.new(0, 6)
tabLay.Parent = tabBtnContainer

local instantiatedButtons = {}

for _, name in ipairs(tabOrder) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 32)
    b.Position = UDim2.new(0, 5, 0, 0)
    b.BackgroundTransparency = 1
    b.Text = name
    b.TextColor3 = (name == "About") and ACCENT_COLOR or MUTED_TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = tabBtnContainer
    
    table.insert(instantiatedButtons, b)
    
    b.MouseButton1Click:Connect(function()
        for tName, tFrame in pairs(tabs) do tFrame.Visible = (tName == name) end
        for _, btn in ipairs(instantiatedButtons) do
            btn.TextColor3 = (btn.Text == name) and ACCENT_COLOR or MUTED_TEXT
        end
    end)
end

updateFlyButtonUI()
showNotification("Hub запущен! Раздел Misc успешно исправлен.")
